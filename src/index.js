// src/index.js
import fs from "fs";
import ini from "ini";
import * as simpleOauth2 from "simple-oauth2";
import express from "express";
import https from "https";
import net from "net";
import tls from "tls";
import path from "path";

const CONFIG_PATH = "/config/emailproxy.config";
const TOKENS_DIR = "/config/tokens";

// Ensure tokens directory exists
if (!fs.existsSync(TOKENS_DIR)) {
  fs.mkdirSync(TOKENS_DIR, { recursive: true });
}

// Custom config parser to handle section names with spaces
function parseConfigWithSpaces(configPath) {
  const raw = fs.readFileSync(configPath, "utf-8");
  const lines = raw.split('\n');
  const config = {};
  let currentSection = null;
  let currentSectionData = {};

  for (const line of lines) {
    const trimmedLine = line.trim();
    
    // Skip empty lines and comments
    if (!trimmedLine || trimmedLine.startsWith('#')) {
      continue;
    }

    // Check if this is a section header
    if (trimmedLine.startsWith('[') && trimmedLine.endsWith(']')) {
      // Save previous section if exists
      if (currentSection) {
        config[currentSection] = currentSectionData;
      }
      
      // Extract section name (remove brackets)
      currentSection = trimmedLine.slice(1, -1);
      currentSectionData = {};
      continue;
    }

    // Parse key-value pairs
    if (currentSection && trimmedLine.includes('=')) {
      const [key, ...valueParts] = trimmedLine.split('=');
      const value = valueParts.join('=').trim();
      currentSectionData[key.trim()] = value;
    }
  }

  // Save the last section
  if (currentSection) {
    config[currentSection] = currentSectionData;
  }

  return config;
}

// Load + parse config
const config = parseConfigWithSpaces(CONFIG_PATH);

console.log("✅ Loaded config sections:", Object.keys(config));

// Find sections by exact names
const general = config["general"];
const serverSection = config["server outlook.office365.com"];
const accountSection = config["account sales@thekpsgroup.com"];

// Validate config sections
if (!general) {
  console.error("❌ Missing [general] section in config");
  console.error("Available sections:", Object.keys(config));
  process.exit(1);
}

if (!serverSection) {
  console.error("❌ Missing [server outlook.office365.com] section in config");
  console.error("Available sections:", Object.keys(config));
  process.exit(1);
}

if (!accountSection) {
  console.error("❌ Missing [account sales@thekpsgroup.com] section in config");
  console.error("Available sections:", Object.keys(config));
  process.exit(1);
}

console.log("✅ All config sections found");

// Token management
function getTokenPath(username) {
  return path.join(TOKENS_DIR, `${username}.json`);
}

function saveTokens(username, tokens) {
  const tokenPath = getTokenPath(username);
  fs.writeFileSync(tokenPath, JSON.stringify(tokens, null, 2));
  console.log(`💾 Tokens saved for ${username}`);
}

function loadTokens(username) {
  const tokenPath = getTokenPath(username);
  if (fs.existsSync(tokenPath)) {
    try {
      const tokens = JSON.parse(fs.readFileSync(tokenPath, "utf-8"));
      console.log(`📂 Tokens loaded for ${username}`);
      return tokens;
    } catch (error) {
      console.error(`❌ Error loading tokens for ${username}:`, error.message);
      return null;
    }
  }
  return null;
}

// OAuth2 client setup
const oauth2Config = {
  client: {
    id: accountSection.client_id,
    secret: accountSection.client_secret || "", // Use client secret if provided
  },
  auth: {
    tokenHost: "https://login.microsoftonline.com",
    tokenPath: `/${accountSection.tenant}/oauth2/v2.0/token`,
    authorizePath: `/${accountSection.tenant}/oauth2/v2.0/authorize`,
  },
  options: {
    // Azure AD often requires client_secret in the body for token exchange
    authorizationMethod: (accountSection.client_secret && accountSection.client_secret.trim() !== "") ? "body" : "header",
  },
};

const oauth2Client = new simpleOauth2.AuthorizationCode(oauth2Config);

// Express app for OAuth2 callback
const app = express();
const AUTH_PORT = 18089;

app.get("/", async (req, res) => {
  const { code, state } = req.query;
  
  if (!code) {
    return res.status(400).send("❌ Missing authorization code");
  }

  try {
    const tokenParams = {
    code,
      redirect_uri: general.redirect_uri,
    };

    console.log("🔄 Exchanging authorization code for tokens...");
    const accessToken = await oauth2Client.getToken(tokenParams);
    const tokens = accessToken.token;
    
    // Save tokens
    saveTokens(accountSection.username, tokens);
    
    console.log("✅ OAuth2 flow completed successfully");
    console.log("🔑 Access token obtained and cached");
    res.send(`
      <html>
        <body>
          <h1>✅ Authentication Successful!</h1>
          <p>You can now close this window and return to your application.</p>
          <script>setTimeout(() => window.close(), 3000);</script>
        </body>
      </html>
    `);
  } catch (error) {
    const details = (error && (error.data || error.message || error.stack)) || String(error);
    console.error("❌ OAuth2 token exchange failed:", details);
    res.status(500).send(`
      <html>
        <body>
          <h1>❌ Authentication Failed</h1>
          <pre style="white-space:pre-wrap;word-break:break-all;">${String(details).replace(/</g,'&lt;')}</pre>
        </body>
      </html>
    `);
  }
});

// Start OAuth2 callback server (HTTP or HTTPS based on redirect_uri)
const redirectUri = general.redirect_uri || "http://127.0.0.1:18089";
if (redirectUri.startsWith("https://")) {
  try {
    const httpsOptions = {
      key: fs.readFileSync("/config/ssl/key.pem"),
      cert: fs.readFileSync("/config/ssl/cert.pem"),
    };
    https.createServer(httpsOptions, app).listen(AUTH_PORT, () => {
      console.log(`🔐 OAuth2 HTTPS callback server running on port ${AUTH_PORT}`);
    });
  } catch (e) {
    console.error("❌ Failed to start HTTPS server:", e.message);
    process.exit(1);
  }
} else {
  app.listen(AUTH_PORT, () => {
    console.log(`🔐 OAuth2 callback server running on port ${AUTH_PORT}`);
  });
}

// IMAP Proxy Server
function createIMAPProxy() {
  const imapServer = net.createServer((clientSocket) => {
    console.log("📧 IMAP client connected");
    
    let clientAuthenticated = false;
    let clientUsername = null;
    let serverSocket = null;
    
    // Send IMAP greeting
    clientSocket.write("* OK IMAP4rev1 Service Ready\r\n");

    clientSocket.on("error", (err) => {
      console.error("❌ IMAP client error:", err.message);
      if (serverSocket) serverSocket.destroy();
    });

    // Handle client -> server
    clientSocket.on("data", (data) => {
      const command = data.toString().trim();
      console.log("📤 IMAP Client -> Server:", command);

      if (command.startsWith("a1 LOGIN")) {
        // Extract username and password
        const match = command.match(/a1 LOGIN "([^"]+)" "([^"]+)"/);
        if (match) {
          const [, username, password] = match;
          clientUsername = username;
          console.log(`🔐 Login attempt for: ${username}`);
          
          // Check if we have valid tokens
          const tokens = loadTokens(username);
          if (tokens && tokens.access_token) {
            console.log("🔑 Using OAuth2 tokens for authentication");
            
            // Connect to real IMAP server only when we have tokens
            serverSocket = tls.connect({
              host: serverSection.imap_host,
              port: parseInt(serverSection.imap_port),
              rejectUnauthorized: false
            }, () => {
              console.log("🔗 Connected to Microsoft IMAP server");
              
              // Use OAuth2 authentication
              const oauth2Command = `a1 AUTHENTICATE XOAUTH2 ${Buffer.from(`user=${username}\x01auth=Bearer ${tokens.access_token}\x01\x01`).toString('base64')}\r\n`;
              serverSocket.write(oauth2Command);
              clientAuthenticated = true;
            });

            serverSocket.on("error", (err) => {
              console.error("❌ IMAP server connection error:", err.message);
              clientSocket.destroy();
            });

            // Handle server -> client
            serverSocket.on("data", (data) => {
              const response = data.toString();
              console.log("📥 IMAP Server -> Client:", response.trim());
              clientSocket.write(data);
            });

            serverSocket.on("close", () => {
              console.log("🔗 IMAP server connection closed");
              clientSocket.destroy();
            });
            
          } else {
            console.log("⚠️ No valid tokens found, initiating OAuth2 flow");
            
            // Generate OAuth2 authorization URL
            const authUrl = oauth2Client.authorizeURL({
              redirect_uri: general.redirect_uri,
              scope: "https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access",
              state: username
            });
            
            console.log("🔗 Microsoft Sign-in URL:", authUrl);
            console.log("📋 Please open this URL in your browser and complete the authentication");
            
            // Send error response to client
            clientSocket.write("a1 NO [AUTHENTICATIONFAILED] OAuth2 authentication required. Please complete the sign-in flow.\r\n");
            return;
          }
        }
      } else if (serverSocket && clientAuthenticated) {
        // Forward other commands only if we have an active server connection
        serverSocket.write(data);
      } else {
        // Send error for commands before authentication
        clientSocket.write("* NO [AUTHENTICATIONFAILED] Please authenticate first\r\n");
      }
    });

    clientSocket.on("close", () => {
      console.log("📧 IMAP client disconnected");
      if (serverSocket) serverSocket.destroy();
    });
  });

  imapServer.listen(1993, "127.0.0.1", () => {
    console.log("📧 IMAP proxy listening on 127.0.0.1:1993");
  });

  return imapServer;
}

// SMTP Proxy Server
function createSMTPProxy() {
  const smtpServer = net.createServer((clientSocket) => {
    console.log("📤 SMTP client connected");
    
    let clientAuthenticated = false;
    let clientUsername = null;
    
    // Connect to real SMTP server
    const serverSocket = net.connect({
      host: serverSection.smtp_host,
      port: parseInt(serverSection.smtp_port)
    }, () => {
      console.log("🔗 Connected to Microsoft SMTP server");
    });

    serverSocket.on("error", (err) => {
      console.error("❌ SMTP server connection error:", err.message);
      clientSocket.destroy();
    });

    clientSocket.on("error", (err) => {
      console.error("❌ SMTP client error:", err.message);
      serverSocket.destroy();
    });

    // Handle client -> server
    clientSocket.on("data", (data) => {
      const command = data.toString().trim();
      console.log("📤 SMTP Client -> Server:", command);

      if (command.startsWith("AUTH LOGIN")) {
        // Extract username and password (base64 values in one-line form)
        const match = command.match(/AUTH LOGIN ([^\s]+) ([^\s]+)/);
        if (match) {
          const [, b64Username, b64Password] = match;
          const decodedUsername = Buffer.from(b64Username, 'base64').toString('utf-8');
          clientUsername = decodedUsername;
          
          // Check tokens for the decoded username
          const tokens = loadTokens(decodedUsername);
          if (tokens && tokens.access_token) {
            console.log("🔑 Using OAuth2 tokens for SMTP authentication");
            
            // Use OAuth2 authentication
            const oauth2Command = `AUTH XOAUTH2 ${Buffer.from(`user=${decodedUsername}\x01auth=Bearer ${tokens.access_token}\x01\x01`).toString('base64')}\r\n`;
            serverSocket.write(oauth2Command);
            clientAuthenticated = true;
          } else {
            console.log("⚠️ No valid tokens found for SMTP");
            clientSocket.write("535 Authentication failed - OAuth2 tokens required\r\n");
            return;
          }
        }
      } else {
        // Forward other commands
        serverSocket.write(data);
      }
    });

    // Handle server -> client
    serverSocket.on("data", (data) => {
      const response = data.toString();
      console.log("📥 SMTP Server -> Client:", response.trim());
      clientSocket.write(data);
    });

    clientSocket.on("close", () => {
      console.log("📤 SMTP client disconnected");
      serverSocket.destroy();
    });

    serverSocket.on("close", () => {
      console.log("🔗 SMTP server connection closed");
      clientSocket.destroy();
    });
  });

  smtpServer.listen(1587, "127.0.0.1", () => {
    console.log("📤 SMTP proxy listening on 127.0.0.1:1587");
  });

  return smtpServer;
}

// Start proxy servers
const imapProxy = createIMAPProxy();
const smtpProxy = createSMTPProxy();

console.log("🚀 Email OAuth2 Proxy started successfully!");
console.log("📧 IMAP: 127.0.0.1:1993");
console.log("📤 SMTP: 127.0.0.1:1587");
console.log(`🔐 OAuth2: ${redirectUri}`);

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("\n🛑 Shutting down proxy servers...");
  imapProxy.close();
  smtpProxy.close();
  process.exit(0);
});

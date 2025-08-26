// src/index.js
import fs from "fs";
import ini from "ini";
import * as simpleOauth2 from "simple-oauth2";
import express from "express";

const CONFIG_PATH = "/config/emailproxy.config";

// Load + parse config
const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
const config = ini.parse(raw);

console.log("✅ Loaded config:", config);

// ---- Account Section ----
// Use safe section name in config: [sales_account]
const account = config["sales_account"];
if (!account) {
  console.error("❌ Could not find [sales_account] section in config.");
  process.exit(1);
}

// Build OAuth2 client
const creds = {
  client: {
    id: account.client_id,
    secret: account.client_secret,
  },
  auth: {
    tokenHost: "https://login.microsoftonline.com",
    tokenPath: `/${account.tenant_id}/oauth2/v2.0/token`,
    authorizePath: `/${account.tenant_id}/oauth2/v2.0/authorize`,
  },
};

const client = new simpleOauth2.AuthorizationCode(creds);

// ---- Express app ----
const app = express();
const PORT = 80;

// Start flow
app.get("/auth", (req, res) => {
  const authorizationUri = client.authorizeURL({
    redirect_uri: account.redirect_uri,
    scope: account.scope,
  });

  console.log("🔗 Auth URL:", authorizationUri);
  res.redirect(authorizationUri);
});

// Callback
app.get("/callback", async (req, res) => {
  const code = req.query.code;
  if (!code) {
    return res.status(400).send("❌ Missing code");
  }

  const options = {
    code,
    redirect_uri: account.redirect_uri,
    scope: account.scope,
  };

  try {
    const accessToken = await client.getToken(options);
    console.log("✅ Token acquired:", accessToken.token);
    res.json(accessToken.token);
  } catch (err) {
    console.error("❌ Token error:", err.message);
    res.status(500).json("Authentication failed");
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Proxy running on port ${PORT}`);
});

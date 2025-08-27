# Email OAuth2 Proxy for EspoCRM

This is an Email OAuth2 proxy that allows EspoCRM to connect to Microsoft 365 (Outlook) using OAuth2 authentication. The proxy handles the OAuth2 flow and token management, allowing EspoCRM to use simple username/password authentication.

## Architecture

The proxy runs as a Docker container and provides:

- **IMAP Proxy**: Listens on `127.0.0.1:1993` and forwards to Microsoft's IMAP server
- **SMTP Proxy**: Listens on `127.0.0.1:1587` and forwards to Microsoft's SMTP server  
- **OAuth2 Callback**: Listens on `127.0.0.1:18089` for OAuth2 authorization callbacks

## Configuration

### 1. Configuration File

The proxy uses `/config/emailproxy.config` with the following structure:

```ini
[general]
redirect_uri      = http://127.0.0.1:18089
local_server_auth = true
log_level         = debug

[server outlook.office365.com]
imap_host = outlook.office365.com
imap_port = 993
smtp_host = smtp.office365.com
smtp_port = 587
ssl = true
starttls = true

[account sales@thekpsgroup.com]
client_id = fbab4542-c890-4455-bb78-f0ce5e3e17e9
tenant    = 6627d97c-a18f-487c-bb7a-d0d6e1640a28
username  = sales@thekpsgroup.com
server    = outlook.office365.com
scope     = https://graph.microsoft.com/IMAP.AccessAsUser.All https://graph.microsoft.com/SMTP.Send offline_access
```

### 2. Microsoft Azure App Registration

You need to register an application in Azure AD:

1. Go to [Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations
2. Create a new registration
3. Set redirect URI to `http://127.0.0.1:18089`
4. Add API permissions:
   - `IMAP.AccessAsUser.All`
   - `SMTP.Send`
   - `offline_access`
5. Note the Client ID and Tenant ID

## Setup Instructions

### 1. Build and Start the Proxy

```bash
# Build the container
docker compose build

# Start the proxy
docker compose up -d mail-proxy

# Check logs
docker logs espocrm-mail-proxy
```

### 2. Trigger OAuth2 Flow

```bash
# Test IMAP login to trigger OAuth2 flow
printf 'a1 LOGIN "sales@thekpsgroup.com" "x"\r\n' | nc -w 8 -N 127.0.0.1 1993
```

### 3. Complete OAuth2 Authentication

1. Check the proxy logs for the Microsoft sign-in URL:
   ```bash
   docker logs espocrm-mail-proxy --tail 20
   ```

2. Open the URL in your browser and sign in with your Microsoft 365 account

3. After successful authentication, the proxy will store the tokens in `/config/tokens/`

### 4. Test the Connection

```bash
# Test IMAP connection
printf 'a1 LIST "" "*"\r\n' | nc -w 8 -N 127.0.0.1 1993

# Test SMTP connection
printf 'EHLO test\r\n' | nc -w 8 -N 127.0.0.1 1587
```

## EspoCRM Configuration

Configure EspoCRM to use the proxy:

### IMAP Settings
- **Host**: `127.0.0.1`
- **Port**: `1993`
- **Username**: `sales@thekpsgroup.com`
- **Password**: `x`
- **Security**: `SSL/TLS`

### SMTP Settings
- **Host**: `127.0.0.1`
- **Port**: `1587`
- **Username**: `sales@thekpsgroup.com`
- **Password**: `x`
- **Security**: `STARTTLS`

## Testing Script

Use the provided test script for easy testing:

```bash
# Make executable
chmod +x test-oauth2-flow.sh

# Run the test script
./test-oauth2-flow.sh
```

## Troubleshooting

### Common Issues

1. **"No section: 'sales@thekpsgroup.com'"**
   - Check that the config file has the correct section name
   - Ensure no extra spaces in section headers

2. **Proxy crashes on startup**
   - Verify all required sections exist in config
   - Check that the config file is properly formatted

3. **OAuth2 flow doesn't complete**
   - Ensure redirect URI matches Azure app registration
   - Check that all required scopes are configured
   - Verify client ID and tenant ID are correct

4. **Authentication fails after OAuth2**
   - Check that tokens are properly saved in `/config/tokens/`
   - Verify token expiration and refresh logic

### Log Analysis

```bash
# View real-time logs
docker logs -f espocrm-mail-proxy

# Check for specific errors
docker logs espocrm-mail-proxy 2>&1 | grep -i error

# Check OAuth2 flow
docker logs espocrm-mail-proxy 2>&1 | grep -E "(OAuth2|Microsoft|Token)"
```

### Token Management

```bash
# Check stored tokens
docker exec espocrm-mail-proxy ls -la /config/tokens/

# View token contents
docker exec espocrm-mail-proxy cat /config/tokens/sales@thekpsgroup.com.json

# Clear tokens (force re-authentication)
docker exec espocrm-mail-proxy rm -f /config/tokens/sales@thekpsgroup.com.json
```

## Security Considerations

1. **Token Storage**: Tokens are stored in `/config/tokens/` with appropriate file permissions
2. **Network Security**: Proxy only listens on localhost (127.0.0.1)
3. **OAuth2 Flow**: Uses secure OAuth2 authorization code flow
4. **TLS**: All connections to Microsoft servers use TLS encryption

## Development

### Local Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Run tests
npm test
```

### Building

```bash
# Build Docker image
docker build -t email-oauth2-proxy .

# Run with custom config
docker run -p 1993:1993 -p 1587:1587 -p 18089:18089 \
  -v $(pwd)/config:/config \
  email-oauth2-proxy
```

## License

This project is licensed under the MIT License.

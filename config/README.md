# Configuration Setup

## Email Proxy Configuration

The `emailproxy.config` file contains the OAuth2 configuration for Microsoft 365 integration.

### Required Configuration

1. **Replace the placeholder client secret:**
   - Open `config/emailproxy.config`
   - Replace `YOUR_CLIENT_SECRET_HERE` with your actual Azure client secret
   - The client secret can be found in your Azure App Registration under "Certificates & secrets"

2. **Verify other settings:**
   - `client_id`: Your Azure app registration client ID
   - `tenant`: Your Azure tenant ID
   - `username`: The email address for OAuth2 authentication
   - `redirect_uri`: Should match your Azure app registration redirect URI

### Security Note

- Never commit the actual client secret to version control
- The `.gitignore` file excludes sensitive files like tokens
- Use environment variables or secure secret management in production

### Example Configuration

```ini
[account sales@thekpsgroup.com]
client_id = fbab4542-c890-4455-bb78-f0ce5e3e17e9
client_secret = YOUR_ACTUAL_CLIENT_SECRET_HERE
tenant    = 6627d97c-a18f-487c-bb7a-d0d6e1640a28
username  = sales@thekpsgroup.com
server    = outlook.office365.com
scope     = https://graph.microsoft.com/IMAP.AccessAsUser.All https://graph.microsoft.com/SMTP.Send offline_access
```

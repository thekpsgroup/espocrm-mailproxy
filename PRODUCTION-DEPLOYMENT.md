# Production Deployment Guide

## Overview

This guide covers deploying the ESPOCRM Mail Proxy in a production environment with proper security, monitoring, and reliability measures.

## Prerequisites

- Docker and Docker Compose installed
- Access to Microsoft Azure for OAuth2 app registration
- ESPOCRM instance running
- Network access to Microsoft 365 services

## Step 1: Production Configuration

### 1.1 Update Configuration

Edit `config/emailproxy.config` for production:

```ini
[general]
redirect_uri      = https://your-domain.com:18089
local_server_auth = false
log_level         = info

[server outlook.office365.com]
imap_host = outlook.office365.com
imap_port = 993
smtp_host = smtp.office365.com
smtp_port = 587
ssl = true
starttls = true

[account your-email@domain.com]
client_id = your-azure-client-id
tenant    = your-azure-tenant-id
username  = your-email@domain.com
server    = outlook.office365.com
scope     = https://graph.microsoft.com/IMAP.AccessAsUser.All https://graph.microsoft.com/SMTP.Send offline_access
```

### 1.2 SSL Certificate Setup

For production, you need proper SSL certificates:

```bash
# Generate SSL certificates
openssl req -x509 -nodes -newkey rsa:2048 \
  -subj "/CN=your-domain.com" \
  -keyout config/ssl/key.pem \
  -out config/ssl/cert.pem \
  -days 365
```

## Step 2: Azure App Registration

### 2.1 Create Azure App

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click **New registration**
4. Set **Name**: `ESPOCRM Mail Proxy`
5. Set **Redirect URI**: `https://your-domain.com:18089`
6. Click **Register**

### 2.2 Configure Permissions

1. Go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Choose **Application permissions**
5. Add:
   - `IMAP.AccessAsUser.All`
   - `SMTP.Send`
   - `offline_access`
6. Click **Grant admin consent**

### 2.3 Get Credentials

1. Note the **Application (client) ID**
2. Note the **Directory (tenant) ID**
3. Update your config file with these values

## Step 3: Production Deployment

### 3.1 Deploy with Monitoring

```powershell
# Deploy with monitoring
.\deploy-production.ps1 -WithMonitoring
```

### 3.2 Deploy without Monitoring

```powershell
# Deploy without monitoring
.\deploy-production.ps1
```

### 3.3 Manual Deployment

```bash
# Build and start production services
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

# Check status
docker ps
docker logs espocrm-mail-proxy
```

## Step 4: ESPOCRM Configuration

### 4.1 Email Account Setup

In ESPOCRM admin panel:

1. Go to **Administration** → **Email** → **Email Accounts**
2. Create new email account
3. Configure:

**IMAP Settings:**
- Host: `your-server-ip`
- Port: `1993`
- Username: `your-email@domain.com`
- Password: `x`
- Security: `SSL/TLS`

**SMTP Settings:**
- Host: `your-server-ip`
- Port: `1587`
- Username: `your-email@domain.com`
- Password: `x`
- Security: `STARTTLS`

### 4.2 Test Configuration

1. Send test email from ESPOCRM
2. Check if emails are received
3. Monitor proxy logs: `docker logs -f espocrm-mail-proxy`

## Step 5: Monitoring and Maintenance

### 5.1 Health Checks

```bash
# Check service health
curl http://localhost:18089/health

# View metrics
curl http://localhost:18089/metrics
```

### 5.2 Log Monitoring

```bash
# View real-time logs
docker logs -f espocrm-mail-proxy

# Check for errors
docker logs espocrm-mail-proxy 2>&1 | grep -i error
```

### 5.3 Backup and Recovery

```powershell
# Create backup
.\deploy-production.ps1 -BackupOnly

# Restore from backup
# Copy backup files to config/ directory
docker compose -f docker-compose.prod.yml restart mail-proxy
```

## Step 6: Security Considerations

### 6.1 Network Security

- Configure firewall to only allow ESPOCRM server access to proxy ports
- Use VPN or private network for sensitive deployments
- Consider using reverse proxy (nginx/traefik) for additional security

### 6.2 Token Security

- Tokens are stored in `/config/tokens/` with restricted permissions
- Regularly rotate OAuth2 tokens
- Monitor token expiration and refresh

### 6.3 SSL/TLS

- Use proper SSL certificates for production
- Configure TLS 1.2+ only
- Regular certificate renewal

## Step 7: Troubleshooting

### 7.1 Common Issues

**OAuth2 Authentication Fails:**
```bash
# Check Azure app configuration
# Verify redirect URI matches
# Check client ID and tenant ID
```

**Connection Timeouts:**
```bash
# Check network connectivity
# Verify firewall rules
# Test direct connection to Microsoft servers
```

**Token Expiration:**
```bash
# Clear tokens to force re-authentication
docker exec espocrm-mail-proxy rm -f /config/tokens/*.json
```

### 7.2 Debug Mode

Enable debug logging in config:
```ini
[general]
log_level = debug
```

## Step 8: Scaling and High Availability

### 8.1 Load Balancing

For high-traffic environments:
- Deploy multiple proxy instances
- Use load balancer (nginx/haproxy)
- Configure sticky sessions if needed

### 8.2 Monitoring Stack

With monitoring enabled:
- **Prometheus**: http://your-server:9090
- **Grafana**: http://your-server:3000
- Set up alerts for:
  - Service down
  - High error rates
  - Token expiration

## Support

For issues and support:
1. Check logs: `docker logs espocrm-mail-proxy`
2. Verify configuration syntax
3. Test network connectivity
4. Review Azure app permissions

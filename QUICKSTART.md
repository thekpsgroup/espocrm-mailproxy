# Quick Start Guide - Email OAuth2 Proxy

## 🚀 Get Started in 5 Minutes

### 1. Build and Start the Proxy

```powershell
# Build the container
docker compose build

# Start the proxy
docker compose up -d mail-proxy

# Check if it's running
docker logs espocrm-mail-proxy
```

### 2. Trigger OAuth2 Flow

```powershell
# Test IMAP login to trigger OAuth2 flow
Test-NetConnection -ComputerName 127.0.0.1 -Port 1993
```

### 3. Get Microsoft Sign-in URL

```powershell
# Check logs for the Microsoft sign-in URL
docker logs espocrm-mail-proxy --tail 20
```

Look for a line like:
```
🔗 Microsoft Sign-in URL: https://login.microsoftonline.com/...
```

### 4. Complete Authentication

1. **Copy the URL** from the logs
2. **Open it in your browser**
3. **Sign in** with your Microsoft 365 account
4. **Authorize** the application
5. **Close the browser tab** when you see "Authentication Successful!"

### 5. Test the Connection

```powershell
# Test IMAP connection
Test-NetConnection -ComputerName 127.0.0.1 -Port 1993

# Test SMTP connection  
Test-NetConnection -ComputerName 127.0.0.1 -Port 1587
```

### 6. Configure EspoCRM

**IMAP Settings:**
- Host: `127.0.0.1`
- Port: `1993`
- Username: `sales@thekpsgroup.com`
- Password: `x`
- Security: `SSL/TLS`

**SMTP Settings:**
- Host: `127.0.0.1`
- Port: `1587`
- Username: `sales@thekpsgroup.com`
- Password: `x`
- Security: `STARTTLS`

## 🔧 Troubleshooting

### Proxy Won't Start
```powershell
# Check config file
Get-Content config/emailproxy.config

# Check Docker logs
docker logs espocrm-mail-proxy
```

### OAuth2 Flow Issues
```powershell
# Clear tokens and restart
docker exec espocrm-mail-proxy rm -f /config/tokens/sales@thekpsgroup.com.json
docker compose restart mail-proxy
```

### Connection Problems
```powershell
# Check if ports are open
netstat -an | findstr "1993"
netstat -an | findstr "1587"
netstat -an | findstr "18089"
```

## 📋 One-Liner Commands

### Restart Proxy
```powershell
docker compose restart mail-proxy
```

### Check Logs
```powershell
docker logs espocrm-mail-proxy --tail 20
```

### Check Tokens
```powershell
docker exec espocrm-mail-proxy ls -la /config/tokens/
```

### Extract Auth URL
```powershell
docker logs espocrm-mail-proxy 2>&1 | Select-String "Microsoft Sign-in URL:"
```

## 🎯 Success Indicators

✅ **Proxy starts without errors**
✅ **Microsoft sign-in URL appears in logs**
✅ **OAuth2 callback completes successfully**
✅ **Tokens are saved in `/config/tokens/`**
✅ **IMAP/SMTP connections work**
✅ **EspoCRM can send/receive email**

## 🆘 Need Help?

1. **Check the full README.md** for detailed instructions
2. **Run the test script**: `.\test-oauth2-flow.ps1`
3. **Review logs**: `docker logs espocrm-mail-proxy`
4. **Verify config**: Ensure all sections exist in `config/emailproxy.config`

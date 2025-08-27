# Simple OAuth2 Flow Trigger Test

Write-Host "🚀 Testing OAuth2 Flow Trigger" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Step 1: Check proxy status
Write-Host "`n📋 Step 1: Checking proxy status..." -ForegroundColor Yellow
$logs = docker logs espocrm-mail-proxy --tail 5
Write-Host "Proxy logs:" -ForegroundColor Cyan
$logs

# Step 2: Test all ports
Write-Host "`n📋 Step 2: Testing all ports..." -ForegroundColor Yellow

$imapTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -InformationLevel Quiet
$smtpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1587 -InformationLevel Quiet
$oauthTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 18089 -InformationLevel Quiet

if ($imapTest) {
    Write-Host "✅ IMAP port (1993) is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ IMAP port (1993) is not accessible" -ForegroundColor Red
}

if ($smtpTest) {
    Write-Host "✅ SMTP port (1587) is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ SMTP port (1587) is not accessible" -ForegroundColor Red
}

if ($oauthTest) {
    Write-Host "✅ OAuth2 port (18089) is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ OAuth2 port (18089) is not accessible" -ForegroundColor Red
}

# Step 3: Check for existing tokens
Write-Host "`n📋 Step 3: Checking for existing tokens..." -ForegroundColor Yellow
$tokens = docker exec espocrm-mail-proxy ls -la /config/tokens/ 2>$null
if ($tokens) {
    Write-Host "📂 Found tokens:" -ForegroundColor Cyan
    $tokens
} else {
    Write-Host "📂 No tokens found - OAuth2 flow will be triggered on first login" -ForegroundColor Yellow
}

# Step 4: Instructions for OAuth2 flow
Write-Host "`n📋 Step 4: OAuth2 Flow Instructions" -ForegroundColor Yellow
Write-Host "To trigger the OAuth2 flow:" -ForegroundColor Cyan
Write-Host "1. Connect to IMAP with credentials:" -ForegroundColor White
Write-Host "   Host: 127.0.0.1" -ForegroundColor White
Write-Host "   Port: 1993" -ForegroundColor White
Write-Host "   Username: sales@thekpsgroup.com" -ForegroundColor White
Write-Host "   Password: x" -ForegroundColor White
Write-Host ""
Write-Host "2. The proxy will generate a Microsoft sign-in URL in the logs" -ForegroundColor Cyan
Write-Host "3. Check logs with: docker logs espocrm-mail-proxy --tail 20" -ForegroundColor Gray
Write-Host "4. Look for: 'Microsoft Sign-in URL:'" -ForegroundColor Gray

Write-Host "`n🎯 Proxy is ready for OAuth2 flow!" -ForegroundColor Green

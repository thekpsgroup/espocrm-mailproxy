# Simple test script for the email proxy

Write-Host "🚀 Simple Email Proxy Test" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Step 1: Check if proxy is running
Write-Host "`n📋 Step 1: Checking proxy status..." -ForegroundColor Yellow
$logs = docker logs espocrm-mail-proxy --tail 5
Write-Host "Proxy logs:" -ForegroundColor Cyan
$logs

# Step 2: Test IMAP connection
Write-Host "`n📋 Step 2: Testing IMAP connection..." -ForegroundColor Yellow
$imapTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -InformationLevel Quiet
if ($imapTest) {
    Write-Host "✅ IMAP port is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ IMAP port is not accessible" -ForegroundColor Red
}

# Step 3: Test SMTP connection
Write-Host "`n📋 Step 3: Testing SMTP connection..." -ForegroundColor Yellow
$smtpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1587 -InformationLevel Quiet
if ($smtpTest) {
    Write-Host "✅ SMTP port is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ SMTP port is not accessible" -ForegroundColor Red
}

# Step 4: Test OAuth2 callback port
Write-Host "`n📋 Step 4: Testing OAuth2 callback port..." -ForegroundColor Yellow
$oauthTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 18089 -InformationLevel Quiet
if ($oauthTest) {
    Write-Host "✅ OAuth2 callback port is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ OAuth2 callback port is not accessible" -ForegroundColor Red
}

Write-Host "`n🎯 Proxy is ready for testing!" -ForegroundColor Green
Write-Host "To trigger OAuth2 flow, connect to IMAP with:" -ForegroundColor Cyan
Write-Host "  Host: 127.0.0.1" -ForegroundColor White
Write-Host "  Port: 1993" -ForegroundColor White
Write-Host "  Username: sales@thekpsgroup.com" -ForegroundColor White
Write-Host "  Password: x" -ForegroundColor White

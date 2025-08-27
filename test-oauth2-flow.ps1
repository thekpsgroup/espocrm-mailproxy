# Email OAuth2 Proxy Test Script for PowerShell
# This script provides one-liners for testing the OAuth2 flow

Write-Host "🚀 Email OAuth2 Proxy Test Script" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Function to restart the proxy
function Restart-Proxy {
    Write-Host "🔄 Restarting mail-proxy..." -ForegroundColor Yellow
    docker compose restart mail-proxy
    Write-Host "✅ Proxy restarted" -ForegroundColor Green
}

# Function to test IMAP login and trigger OAuth2 flow
function Test-ImapLogin {
    Write-Host "📧 Testing IMAP login to trigger OAuth2 flow..." -ForegroundColor Yellow
    Write-Host "Command: Test-NetConnection -ComputerName 127.0.0.1 -Port 1993" -ForegroundColor Gray
    
    # Test connection first
    try {
        $connection = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -InformationLevel Quiet
        if ($connection) {
            Write-Host "✅ IMAP port is accessible" -ForegroundColor Green
        } else {
            Write-Host "❌ IMAP port is not accessible" -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "❌ Cannot connect to IMAP port: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    Write-Host "📋 Check the proxy logs for the Microsoft sign-in URL:" -ForegroundColor Cyan
    Write-Host "Command: docker logs espocrm-mail-proxy --tail 20" -ForegroundColor Gray
}

# Function to check proxy logs
function Check-Logs {
    Write-Host "📋 Checking proxy logs..." -ForegroundColor Yellow
    docker logs espocrm-mail-proxy --tail 20
}

# Function to extract Microsoft sign-in URL from logs
function Extract-AuthUrl {
    Write-Host "🔗 Extracting Microsoft sign-in URL from logs..." -ForegroundColor Yellow
    $logs = docker logs espocrm-mail-proxy 2>&1
    $authUrl = $logs | Select-String "Microsoft Sign-in URL:" | Select-Object -Last 1
    if ($authUrl) {
        $url = $authUrl.Line -replace ".*Microsoft Sign-in URL: ", ""
        Write-Host "🔗 Found URL: $url" -ForegroundColor Green
        Write-Host "📋 Copy this URL and open it in your browser" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No Microsoft sign-in URL found in logs" -ForegroundColor Red
    }
}

# Function to test successful IMAP connection
function Test-SuccessfulImap {
    Write-Host "✅ Testing successful IMAP connection..." -ForegroundColor Yellow
    Write-Host "Command: Test-NetConnection -ComputerName 127.0.0.1 -Port 1993" -ForegroundColor Gray
    Test-NetConnection -ComputerName 127.0.0.1 -Port 1993
}

# Function to test SMTP connection
function Test-Smtp {
    Write-Host "📤 Testing SMTP connection..." -ForegroundColor Yellow
    Write-Host "Command: Test-NetConnection -ComputerName 127.0.0.1 -Port 1587" -ForegroundColor Gray
    Test-NetConnection -ComputerName 127.0.0.1 -Port 1587
}

# Function to check token status
function Check-Tokens {
    Write-Host "🔑 Checking token status..." -ForegroundColor Yellow
    try {
        $tokensDir = docker exec espocrm-mail-proxy ls -la /config/tokens/ 2>$null
        if ($tokensDir) {
            Write-Host "✅ Tokens directory exists" -ForegroundColor Green
            $tokenFile = docker exec espocrm-mail-proxy cat /config/tokens/sales@thekpsgroup.com.json 2>$null
            if ($tokenFile) {
                Write-Host "✅ Token file exists" -ForegroundColor Green
                $tokenData = $tokenFile | ConvertFrom-Json
                if ($tokenData.access_token) {
                    Write-Host "✅ Access token found" -ForegroundColor Green
                } else {
                    Write-Host "❌ No access token in file" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ No token file found" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ No tokens directory found" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error checking tokens: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to build and start the proxy
function Start-Proxy {
    Write-Host "🔨 Building and starting proxy..." -ForegroundColor Yellow
    docker compose build
    docker compose up -d mail-proxy
    Start-Sleep -Seconds 3
    Check-Logs
}

# Main menu
do {
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host "1) Build and start proxy"
    Write-Host "2) Restart proxy"
    Write-Host "3) Test IMAP login (trigger OAuth2)"
    Write-Host "4) Check proxy logs"
    Write-Host "5) Extract Microsoft sign-in URL"
    Write-Host "6) Test successful IMAP connection"
    Write-Host "7) Test SMTP connection"
    Write-Host "8) Check token status"
    Write-Host "9) Run full OAuth2 flow test"
    Write-Host "10) Exit"
    Write-Host ""
    $choice = Read-Host "Enter your choice (1-10)"

    switch ($choice) {
        "1" { Start-Proxy }
        "2" { Restart-Proxy }
        "3" { Test-ImapLogin }
        "4" { Check-Logs }
        "5" { Extract-AuthUrl }
        "6" { Test-SuccessfulImap }
        "7" { Test-Smtp }
        "8" { Check-Tokens }
        "9" {
            Write-Host "🔄 Running full OAuth2 flow test..." -ForegroundColor Yellow
            Restart-Proxy
            Start-Sleep -Seconds 3
            Test-ImapLogin
            Start-Sleep -Seconds 2
            Check-Logs
        }
        "10" {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "❌ Invalid option. Please try again." -ForegroundColor Red
        }
    }
} while ($true)

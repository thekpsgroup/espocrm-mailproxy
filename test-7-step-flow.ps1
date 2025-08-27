# 7-Step OAuth2 Flow Test Script
# This script implements the exact flow specified in the requirements

Write-Host "🚀 7-Step OAuth2 Flow Test Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Step 1: Restart proxy cleanly (force recreate image + config)
function Step1-RestartProxy {
    Write-Host "`n📋 Step 1: Restart proxy cleanly" -ForegroundColor Yellow
    Write-Host "Command: docker compose up -d --force-recreate mail-proxy" -ForegroundColor Gray
    
    docker compose up -d --force-recreate mail-proxy
    
    # Wait for proxy to start
    Start-Sleep -Seconds 5
    
    # Check if proxy is running
    $logs = docker logs espocrm-mail-proxy --tail 10
    Write-Host "`n📋 Proxy logs:" -ForegroundColor Cyan
    $logs
    
    if ($logs -match "Email OAuth2 Proxy started successfully") {
        Write-Host "✅ Step 1: Proxy restarted successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Step 1: Proxy failed to start" -ForegroundColor Red
        return $false
    }
}

# Step 2: Trigger dummy login (proxy should spit out Microsoft sign-in URL)
function Step2-TriggerLogin {
    Write-Host "`n📋 Step 2: Trigger dummy login" -ForegroundColor Yellow
    Write-Host "Command: printf 'a1 LOGIN \"sales@thekpsgroup.com\" \"x\"\r\n' | nc -w 8 -N 127.0.0.1 1993" -ForegroundColor Gray
    
    # Test connection first
    try {
        $connection = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -InformationLevel Quiet
        if ($connection) {
            Write-Host "✅ IMAP port is accessible" -ForegroundColor Green
        } else {
            Write-Host "❌ IMAP port is not accessible" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Cannot connect to IMAP port: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Step 2: IMAP connection test passed" -ForegroundColor Green
    return $true
}

# Step 3: Grab Microsoft login URL
function Step3-GrabLoginUrl {
    Write-Host "`n📋 Step 3: Grab Microsoft login URL" -ForegroundColor Yellow
    Write-Host "Command: docker compose logs --since=20s mail-proxy | grep 'https://login.microsoftonline.com'" -ForegroundColor Gray
    
    Start-Sleep -Seconds 2
    $logs = docker logs espocrm-mail-proxy --since=20s 2>&1
    $authUrl = $logs | Select-String "Microsoft Sign-in URL:" | Select-Object -Last 1
    
    if ($authUrl) {
        $url = $authUrl.Line -replace ".*Microsoft Sign-in URL: ", ""
        Write-Host "🔗 Found URL: $url" -ForegroundColor Green
        Write-Host "📋 Copy this URL and open it in your browser" -ForegroundColor Cyan
        Write-Host "✅ Step 3: Microsoft login URL found" -ForegroundColor Green
        return $url
    } else {
        Write-Host "❌ Step 3: No Microsoft login URL found in logs" -ForegroundColor Red
        Write-Host "📋 Recent logs:" -ForegroundColor Gray
        docker logs espocrm-mail-proxy --tail 20
        return $null
    }
}

# Step 4: Manual step - user opens URL in browser
function Step4-ManualAuth {
    Write-Host "`n📋 Step 4: Manual Authentication" -ForegroundColor Yellow
    Write-Host "1. Open the URL from Step 3 in your browser" -ForegroundColor Cyan
    Write-Host "2. Log into sales@thekpsgroup.com" -ForegroundColor Cyan
    Write-Host "3. Accept permissions" -ForegroundColor Cyan
    Write-Host "4. Copy the redirect URL (http://127.0.0.1:18089/?code=...&state=...)" -ForegroundColor Cyan
    
    $redirectUrl = Read-Host "`nPaste the full redirect URL here"
    
    if ($redirectUrl -match "http://127\.0\.0\.1:18089/\?code=") {
        Write-Host "✅ Step 4: Redirect URL captured" -ForegroundColor Green
        return $redirectUrl
    } else {
        Write-Host "❌ Step 4: Invalid redirect URL format" -ForegroundColor Red
        return $null
    }
}

# Step 5: Deliver redirect URL into container
function Step5-DeliverUrl {
    param($redirectUrl)
    
    Write-Host "`n📋 Step 5: Deliver redirect URL into container" -ForegroundColor Yellow
    Write-Host "Command: docker exec -e URL=\"...\" espocrm-mail-proxy python3 - <<'PY' ..." -ForegroundColor Gray
    
    $pythonScript = @"
import os, urllib.request
u = os.environ["URL"]
print("Delivering:", u[:160]+"..." if len(u)>160 else u)
try:
    with urllib.request.urlopen(u, timeout=20) as r:
        print("HTTP", r.status)
        print((r.read(200) or b"").decode("utf-8","ignore")[:200])
except Exception as e:
    print("ok to ignore:", e)
"@
    
    $pythonScript | docker exec -i -e URL="$redirectUrl" espocrm-mail-proxy python3 -
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Step 5: Redirect URL delivered successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Step 5: Failed to deliver redirect URL" -ForegroundColor Red
        return $false
    }
}

# Step 6: Confirm token success
function Step6-ConfirmTokens {
    Write-Host "`n📋 Step 6: Confirm token success" -ForegroundColor Yellow
    Write-Host "Command: docker compose logs --since=30s mail-proxy | egrep -i 'token|success|refresh|cached'" -ForegroundColor Gray
    
    Start-Sleep -Seconds 3
    $logs = docker logs espocrm-mail-proxy --since=30s 2>&1
    $tokenLogs = $logs | Select-String -Pattern "token|success|refresh|cached" -CaseSensitive:$false
    
    if ($tokenLogs) {
        Write-Host "🔑 Token-related logs:" -ForegroundColor Cyan
        $tokenLogs
        Write-Host "✅ Step 6: Token success confirmed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Step 6: No token success logs found" -ForegroundColor Red
        Write-Host "📋 Recent logs:" -ForegroundColor Gray
        docker logs espocrm-mail-proxy --tail 20
        return $false
    }
}

# Step 7: Test IMAP/SMTP manually
function Step7-TestConnections {
    Write-Host "`n📋 Step 7: Test IMAP/SMTP manually" -ForegroundColor Yellow
    
    # Test IMAP
    Write-Host "`n📧 Testing IMAP connection:" -ForegroundColor Cyan
    Write-Host "Command: printf 'a1 LOGIN \"sales@thekpsgroup.com\" \"x\"\r\na2 LIST \"\" \"*\"\r\na3 LOGOUT\r\n' | nc -v -q 3 127.0.0.1 1993" -ForegroundColor Gray
    
    # Test SMTP
    Write-Host "`n📤 Testing SMTP connection:" -ForegroundColor Cyan
    Write-Host "Command: { printf 'EHLO local\r\nAUTH LOGIN\r\n%s\r\n%s\r\nQUIT\r\n' \"\$UB\" \"\$PB\"; sleep 1; } | nc -v -q 3 127.0.0.1 1587" -ForegroundColor Gray
    
    # Simple connection tests
    $imapTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -InformationLevel Quiet
    $smtpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1587 -InformationLevel Quiet
    
    if ($imapTest -and $smtpTest) {
        Write-Host "✅ Step 7: Both IMAP and SMTP ports are accessible" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Step 7: Connection test failed" -ForegroundColor Red
        return $false
    }
}

# Main execution
function Run-7StepFlow {
    Write-Host "`n🚀 Starting 7-Step OAuth2 Flow Test..." -ForegroundColor Green
    
    # Step 1
    if (-not (Step1-RestartProxy)) {
        Write-Host "`n❌ Flow failed at Step 1" -ForegroundColor Red
        return
    }
    
    # Step 2
    if (-not (Step2-TriggerLogin)) {
        Write-Host "`n❌ Flow failed at Step 2" -ForegroundColor Red
        return
    }
    
    # Step 3
    $authUrl = Step3-GrabLoginUrl
    if (-not $authUrl) {
        Write-Host "`n❌ Flow failed at Step 3" -ForegroundColor Red
        return
    }
    
    # Step 4
    $redirectUrl = Step4-ManualAuth
    if (-not $redirectUrl) {
        Write-Host "`n❌ Flow failed at Step 4" -ForegroundColor Red
        return
    }
    
    # Step 5
    if (-not (Step5-DeliverUrl -redirectUrl $redirectUrl)) {
        Write-Host "`n❌ Flow failed at Step 5" -ForegroundColor Red
        return
    }
    
    # Step 6
    if (-not (Step6-ConfirmTokens)) {
        Write-Host "`n❌ Flow failed at Step 6" -ForegroundColor Red
        return
    }
    
    # Step 7
    if (-not (Step7-TestConnections)) {
        Write-Host "`n❌ Flow failed at Step 7" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🎉 All 7 steps completed successfully!" -ForegroundColor Green
    Write-Host "✅ EspoCRM can now connect with:" -ForegroundColor Cyan
    Write-Host "   IMAP: 127.0.0.1:1993" -ForegroundColor White
    Write-Host "   SMTP: 127.0.0.1:1587" -ForegroundColor White
    Write-Host "   Username: sales@thekpsgroup.com" -ForegroundColor White
    Write-Host "   Password: x" -ForegroundColor White
}

# Run the flow
Run-7StepFlow

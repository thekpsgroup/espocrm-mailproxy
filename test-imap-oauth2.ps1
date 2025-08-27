# Test IMAP connection and trigger OAuth2 flow
$imapHost = "127.0.0.1"
$imapPort = 1993
$username = "sales@thekpsgroup.com"
$password = "x"

Write-Host "Testing IMAP connection to trigger OAuth2 flow..." -ForegroundColor Green
Write-Host "Host: $imapHost`:$imapPort" -ForegroundColor Yellow
Write-Host "Username: $username" -ForegroundColor Yellow

try {
    # Create TCP client
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($imapHost, $imapPort)
    
    if ($tcpClient.Connected) {
        Write-Host "✅ Connected to IMAP proxy" -ForegroundColor Green
        
        # Get network stream
        $stream = $tcpClient.GetStream()
        
        # Read initial greeting
        $buffer = New-Object byte[] 1024
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
        Write-Host "Server greeting: $response" -ForegroundColor Cyan
        
        # Send LOGIN command to trigger OAuth2
        $loginCommand = "a1 LOGIN `"$username`" `"$password`"`r`n"
        $loginBytes = [System.Text.Encoding]::ASCII.GetBytes($loginCommand)
        $stream.Write($loginBytes, 0, $loginBytes.Length)
        
        Write-Host "Sent LOGIN command, waiting for response..." -ForegroundColor Yellow
        
        # Read response
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
        Write-Host "Response: $response" -ForegroundColor Cyan
        
        # Close connection
        $stream.Close()
        $tcpClient.Close()
        
        Write-Host "✅ IMAP test completed" -ForegroundColor Green
        Write-Host "Check the proxy logs for OAuth2 URL if authentication is needed" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Failed to connect to IMAP proxy" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($tcpClient) {
        $tcpClient.Close()
    }
}

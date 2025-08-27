# Test SMTP connection
$smtpHost = "127.0.0.1"
$smtpPort = 1587

Write-Host "Testing SMTP connection..." -ForegroundColor Green
Write-Host "Host: $smtpHost`:$smtpPort" -ForegroundColor Yellow

try {
    # Create TCP client
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($smtpHost, $smtpPort)
    
    if ($tcpClient.Connected) {
        Write-Host "✅ Connected to SMTP proxy" -ForegroundColor Green
        
        # Get network stream
        $stream = $tcpClient.GetStream()
        
        # Read initial greeting
        $buffer = New-Object byte[] 1024
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
        Write-Host "Server greeting: $response" -ForegroundColor Cyan
        
        # Send EHLO command
        $ehloCommand = "EHLO test.local`r`n"
        $ehloBytes = [System.Text.Encoding]::ASCII.GetBytes($ehloCommand)
        $stream.Write($ehloBytes, 0, $ehloBytes.Length)
        
        Write-Host "Sent EHLO command, waiting for response..." -ForegroundColor Yellow
        
        # Read response
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
        Write-Host "Response: $response" -ForegroundColor Cyan
        
        # Close connection
        $stream.Close()
        $tcpClient.Close()
        
        Write-Host "✅ SMTP test completed" -ForegroundColor Green
        
    } else {
        Write-Host "❌ Failed to connect to SMTP proxy" -ForegroundColor Red
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

# Production Deployment Script for ESPOCRM Mail Proxy
param(
    [switch]$WithMonitoring,
    [switch]$BackupOnly,
    [switch]$RestoreOnly
)

Write-Host "🚀 ESPOCRM Mail Proxy Production Deployment" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create backup directory
$backupDir = ".\backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (!(Test-Path ".\backups")) {
    New-Item -ItemType Directory -Path ".\backups" | Out-Null
}

# Backup existing configuration
if ($BackupOnly -or !$RestoreOnly) {
    Write-Host "📦 Creating backup..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    
    if (Test-Path ".\config") {
        Copy-Item -Path ".\config\*" -Destination $backupDir -Recurse
        Write-Host "✅ Configuration backed up to: $backupDir" -ForegroundColor Green
    }
}

# Stop existing containers
Write-Host "🛑 Stopping existing containers..." -ForegroundColor Yellow
docker compose down 2>$null

# Build and start production containers
if (!$BackupOnly) {
    Write-Host "🔨 Building production containers..." -ForegroundColor Yellow
    docker compose -f docker-compose.prod.yml build
    
    Write-Host "🚀 Starting production services..." -ForegroundColor Yellow
    if ($WithMonitoring) {
        docker compose -f docker-compose.prod.yml --profile monitoring up -d
        Write-Host "✅ Started with monitoring (Prometheus: http://localhost:9090, Grafana: http://localhost:3000)" -ForegroundColor Green
    } else {
        docker compose -f docker-compose.prod.yml up -d
        Write-Host "✅ Started production services" -ForegroundColor Green
    }
    
    # Wait for services to start
    Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Check service health
    Write-Host "🏥 Checking service health..." -ForegroundColor Yellow
    $containers = docker ps --filter "name=espocrm-mail-proxy" --format "table {{.Names}}\t{{.Status}}"
    Write-Host $containers -ForegroundColor Cyan
    
    # Test connections
    Write-Host "🔍 Testing connections..." -ForegroundColor Yellow
    $imapTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1993 -WarningAction SilentlyContinue
    $smtpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 1587 -WarningAction SilentlyContinue
    
    if ($imapTest.TcpTestSucceeded) {
        Write-Host "✅ IMAP proxy (port 1993) is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ IMAP proxy (port 1993) is not accessible" -ForegroundColor Red
    }
    
    if ($smtpTest.TcpTestSucceeded) {
        Write-Host "✅ SMTP proxy (port 1587) is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ SMTP proxy (port 1587) is not accessible" -ForegroundColor Red
    }
}

# Show logs
Write-Host "📋 Recent logs:" -ForegroundColor Yellow
docker logs espocrm-mail-proxy --tail 10

Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure ESPOCRM to use:" -ForegroundColor White
Write-Host "   - IMAP: 127.0.0.1:1993" -ForegroundColor White
Write-Host "   - SMTP: 127.0.0.1:1587" -ForegroundColor White
Write-Host "2. Test email functionality in ESPOCRM" -ForegroundColor White
Write-Host "3. Monitor logs: docker logs -f espocrm-mail-proxy" -ForegroundColor White

if ($WithMonitoring) {
    Write-Host "4. Access monitoring:" -ForegroundColor White
    Write-Host "   - Prometheus: http://localhost:9090" -ForegroundColor White
    Write-Host "   - Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor White
}

# Script to help fix Docker proxy issues on Windows

Write-Host "=== Docker Proxy Configuration Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check current proxy settings
Write-Host "Current Docker proxy configuration:" -ForegroundColor Yellow
docker info 2>&1 | Select-String -Pattern "Proxy"

Write-Host ""
Write-Host "To fix this issue, you have two options:" -ForegroundColor Green
Write-Host ""
Write-Host "OPTION 1: Disable Proxy in Docker Desktop (Recommended)" -ForegroundColor Cyan
Write-Host "1. Open Docker Desktop" -ForegroundColor White
Write-Host "2. Click the Settings (gear) icon" -ForegroundColor White
Write-Host "3. Go to: Resources > Proxies" -ForegroundColor White
Write-Host "4. Uncheck 'Manual proxy configuration' or clear all proxy fields" -ForegroundColor White
Write-Host "5. Click 'Apply & Restart'" -ForegroundColor White
Write-Host ""
Write-Host "OPTION 2: Configure Proxy Correctly (If you need a proxy)" -ForegroundColor Cyan
Write-Host "1. Open Docker Desktop" -ForegroundColor White
Write-Host "2. Go to: Resources > Proxies" -ForegroundColor White
Write-Host "3. Ensure HTTPS proxy uses 'https://' not 'http://'" -ForegroundColor White
Write-Host "4. Or use a proxy that supports HTTPS properly" -ForegroundColor White
Write-Host ""
Write-Host "After fixing, restart Docker Desktop and try again:" -ForegroundColor Yellow
Write-Host "  docker-compose up --build" -ForegroundColor White
Write-Host ""

# Check if Docker Desktop is running
$dockerRunning = docker info 2>&1 | Select-String -Pattern "Cannot connect" -NotMatch
if (-not $dockerRunning) {
    Write-Host "WARNING: Docker daemon might not be running properly" -ForegroundColor Red
}


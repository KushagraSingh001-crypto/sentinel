# 🚀 Sentinel v1 - Automated Local Startup Script
# This script starts all services in separate PowerShell windows for easy monitoring

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "🛡️  Starting Sentinel v1 Services..." -ForegroundColor Green
Write-Host "=" * 50

# Check if .env file exists
if (-Not (Test-Path "$root\.env")) {
    Write-Host "⚠️  Warning: .env file not found. Using defaults." -ForegroundColor Yellow
    Write-Host "   Copy .env.example to .env and configure your MongoDB connection."
    Write-Host ""
}

# Load environment variables from .env if it exists
if (Test-Path "$root\.env") {
    Get-Content "$root\.env" | ForEach-Object {
        if ($_ -match "^([^#][^=]*)=(.*)$") {
            Set-Item -Path "env:$($matches[1])" -Value $matches[2]
        }
    }
    Write-Host "✅ Loaded environment variables from .env" -ForegroundColor Green
}

# Set fallback defaults if not in .env
if (-not $env:MONGO_URI) { $env:MONGO_URI = 'mongodb://localhost:27017' }
if (-not $env:DB_NAME) { $env:DB_NAME = 'sentinel' }
if (-not $env:WRAPPERS_URL) { $env:WRAPPERS_URL = 'http://localhost:8002/get_noisy_response' }

Write-Host "📊 Configuration:"
Write-Host "   Database: $($env:DB_NAME)"
Write-Host "   MongoDB: $($env:MONGO_URI.Substring(0, [Math]::Min(50, $env:MONGO_URI.Length)))..."
Write-Host ""

function Start-Window($name, $workDir, $command, $description) {
    Write-Host "🚀 Starting $name..." -ForegroundColor Cyan
    Write-Host "   $description"
    $envVars = "`$env:MONGO_URI='$env:MONGO_URI'; `$env:DB_NAME='$env:DB_NAME'; `$env:WRAPPERS_URL='$env:WRAPPERS_URL';"
    $fullCommand = "$envVars cd '$workDir'; $command"
    $argsList = "-NoExit", "-Command", $fullCommand
    Start-Process -FilePath pwsh -ArgumentList $argsList
    Start-Sleep 1
}

# Start services in dependency order
Start-Window "Wrappers Service" "${root}\services\wrappers-py" "if (-Not (Test-Path '.venv')) { python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt } else { .\.venv\Scripts\Activate.ps1 }; uvicorn app.main:app --host 0.0.0.0 --port 8002" "FastAPI service for generating noisy responses (Port 8002)"

Start-Window "Detector Service" "${root}\services\detector-py" "if (-Not (Test-Path '.venv')) { python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt } else { .\.venv\Scripts\Activate.ps1 }; uvicorn app.main:app --host 0.0.0.0 --port 8001" "FastAPI service for threat analysis (Port 8001)"

Start-Window "Gateway Service" "${root}\services\gateway-node" "if (-Not (Test-Path 'node_modules')) { npm install } else { Write-Host 'Dependencies already installed' }; npm start" "Express.js API gateway with 3-tier logic (Port 8000)"

Start-Window "Frontend Service" "${root}\frontend-react" "if (-Not (Test-Path 'node_modules')) { npm install --legacy-peer-deps } else { Write-Host 'Dependencies already installed' }; npm start" "React dashboard and chat interface (Port 3000)"

Write-Host ""
Write-Host "✅ All services are starting in separate windows!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Service URLs:"
Write-Host "   • Frontend:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "   • Gateway:   http://localhost:8000" -ForegroundColor Cyan  
Write-Host "   • Wrappers:  http://localhost:8002" -ForegroundColor Cyan
Write-Host "   • Detector:  http://localhost:8001" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏱️  Wait 30-60 seconds for all services to fully start, then open:"
Write-Host "   🎯 http://localhost:3000 (Main Application)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Optional - Start Hardhat Blockchain (new terminal):"
Write-Host "   cd '$root\blockchain' && npm install && npx hardhat node" -ForegroundColor Gray
Write-Host ""
Write-Host "🧪 Test Attack Demo (after services are ready):"
Write-Host "   cd '$root\attacker-demo' && node attack.js" -ForegroundColor Gray

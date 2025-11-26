#!/usr/bin/env pwsh

# Sentinel Platform Startup Script
# Starts all components of the Sentinel MLaaS Security Platform

param(
    [string]$Mode = "full",  # Options: full, backend-only, blockchain-only
    [switch]$Help
)

if ($Help) {
    Write-Host "🛡️ Sentinel Platform Startup Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\start-sentinel.ps1 [-Mode <mode>]" -ForegroundColor White
    Write-Host ""
    Write-Host "Modes:" -ForegroundColor Yellow
    Write-Host "  full        - Start all components (default)" -ForegroundColor White  
    Write-Host "  backend     - Start only backend + blockchain" -ForegroundColor White
    Write-Host "  blockchain  - Start only blockchain components" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\start-sentinel.ps1                    # Start everything" -ForegroundColor Gray
    Write-Host "  .\start-sentinel.ps1 -Mode backend      # Backend only" -ForegroundColor Gray
    Write-Host "  .\start-sentinel.ps1 -Mode blockchain   # Blockchain only" -ForegroundColor Gray
    exit
}

$ErrorActionPreference = "Stop"
$startLocation = Get-Location

Write-Host "🛡️ Starting Sentinel MLaaS Security Platform" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host ""

try {
    if ($Mode -eq "full" -or $Mode -eq "backend" -or $Mode -eq "blockchain") {
        
        Write-Host "🔗 Starting Blockchain Components..." -ForegroundColor Yellow
        
        # Check if blockchain is already compiled
        if (-not (Test-Path "blockchain/artifacts")) {
            Write-Host "   Compiling smart contracts..." -ForegroundColor Gray
            Set-Location "blockchain"
            npm run compile
            Set-Location $startLocation
        }
        
        # Start Hardhat node in background
        Write-Host "   Starting Hardhat node..." -ForegroundColor Gray
        $hardhatJob = Start-Job -ScriptBlock {
            Set-Location $using:startLocation
            Set-Location "blockchain"
            npx hardhat node
        }
        
        Start-Sleep -Seconds 5
        
        # Deploy contract
        Write-Host "   Deploying ThreatChain contract..." -ForegroundColor Gray
        Set-Location "blockchain"
        npm run deploy
        Set-Location $startLocation
        
        Write-Host "   ✅ Blockchain components started" -ForegroundColor Green
    }
    
    if ($Mode -eq "full" -or $Mode -eq "backend") {
        
        Write-Host "`n⚙️ Starting Backend Services..." -ForegroundColor Yellow
        
        # Start backend gateway
        Write-Host "   Starting Gateway API server..." -ForegroundColor Gray
        $backendJob = Start-Job -ScriptBlock {
            Set-Location $using:startLocation
            Set-Location "services/gateway-node"
            npm start
        }
        
        # Start Python detector service
        Write-Host "   Starting ML Detector service..." -ForegroundColor Gray
        $detectorJob = Start-Job -ScriptBlock {
            Set-Location $using:startLocation
            Set-Location "services/detector-py"
            python app/main.py
        }
        
        # Start Python wrappers service  
        Write-Host "   Starting Wrappers service..." -ForegroundColor Gray
        $wrappersJob = Start-Job -ScriptBlock {
            Set-Location $using:startLocation
            Set-Location "services/wrappers-py"
            python app/main.py
        }
        
        Start-Sleep -Seconds 8
        Write-Host "   ✅ Backend services started" -ForegroundColor Green
    }
    
    if ($Mode -eq "full") {
        
        Write-Host "`n🌐 Starting Frontend..." -ForegroundColor Yellow
        
        # Start React frontend
        Write-Host "   Starting React application..." -ForegroundColor Gray
        $frontendJob = Start-Job -ScriptBlock {
            Set-Location $using:startLocation  
            Set-Location "frontend-react"
            npm start
        }
        
        Start-Sleep -Seconds 5
        Write-Host "   ✅ Frontend started" -ForegroundColor Green
    }
    
    Write-Host "`n✨ Sentinel Platform Started Successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
    
    if ($Mode -eq "full") {
        Write-Host "├─ Frontend:      http://localhost:3000" -ForegroundColor White
    }
    if ($Mode -eq "full" -or $Mode -eq "backend") {
        Write-Host "├─ Backend API:   http://localhost:5000" -ForegroundColor White
        Write-Host "├─ ML Detector:   http://localhost:8001" -ForegroundColor White  
        Write-Host "├─ Wrappers:      http://localhost:8002" -ForegroundColor White
    }
    if ($Mode -eq "full" -or $Mode -eq "backend" -or $Mode -eq "blockchain") {
        Write-Host "└─ Blockchain:    http://127.0.0.1:8545" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🧪 Test Commands:" -ForegroundColor Yellow
    Write-Host "# Test threat logging:" -ForegroundColor Gray
    Write-Host '$data = ''{"userId":"test","suspicionScore":0.95,"severity":"CRITICAL"}''' -ForegroundColor Gray
    Write-Host 'Invoke-RestMethod -Uri "http://localhost:5000/api/threat" -Method POST -Body $data -ContentType "application/json"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
    
    # Keep script running
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Check if jobs are still running
        $runningJobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($runningJobs.Count -eq 0) {
            Write-Host "All services stopped." -ForegroundColor Red
            break
        }
    }
    
} catch {
    Write-Host "❌ Error starting platform: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup jobs
    Write-Host "`nStopping services..." -ForegroundColor Yellow
    Get-Job | Stop-Job -Force 2>$null
    Get-Job | Remove-Job -Force 2>$null
    Set-Location $startLocation
}
#!/usr/bin/env pwsh

# Sentinel Blockchain Local Development Script
# Starts all services in the correct order for development

Write-Host "🛡️  Sentinel Blockchain - Local Development" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Configuration
$hardhatPort = 8545
$backendPort = 5000
$frontendPort = 3000

function Start-HardhatNode {
    Write-Host "`n🔗 Starting Hardhat blockchain node..." -ForegroundColor Yellow
    
    Set-Location "blockchain"
    
    # Check if port is already in use
    $portInUse = Get-NetTCPConnection -LocalPort $hardhatPort -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host "⚠️ Port $hardhatPort is already in use. Hardhat node may already be running." -ForegroundColor Yellow
        Set-Location ".."
        return
    }
    
    Write-Host "   Starting on port $hardhatPort..." -ForegroundColor White
    Start-Process -FilePath "pwsh" -ArgumentList "-Command", "npx hardhat node" -WindowStyle Minimized
    
    Set-Location ".."
    
    # Wait for node to start
    Write-Host "   Waiting for blockchain node to start..." -ForegroundColor White
    Start-Sleep 5
    
    # Test connection
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:$hardhatPort" -Method Post -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -ContentType "application/json" -TimeoutSec 5
        Write-Host "✅ Hardhat node is running" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to connect to Hardhat node" -ForegroundColor Red
    }
}

function Deploy-Contract {
    Write-Host "`n📜 Deploying smart contract..." -ForegroundColor Yellow
    
    Set-Location "blockchain"
    
    try {
        $output = npm run deploy 2>&1
        
        # Extract contract address from output
        $contractAddress = ""
        foreach ($line in $output) {
            if ($line -match "ThreatChain deployed to: (0x[a-fA-F0-9]{40})") {
                $contractAddress = $matches[1]
                break
            }
        }
        
        if ($contractAddress) {
            Write-Host "✅ Contract deployed to: $contractAddress" -ForegroundColor Green
            
            # Update backend .env file
            Set-Location "../services/gateway-node"
            
            $envContent = Get-Content ".env" -ErrorAction SilentlyContinue
            $newEnvContent = @()
            $contractAddressUpdated = $false
            $privateKeyUpdated = $false
            
            foreach ($line in $envContent) {
                if ($line -match "^BLOCKCHAIN_CONTRACT_ADDRESS=") {
                    $newEnvContent += "BLOCKCHAIN_CONTRACT_ADDRESS=$contractAddress"
                    $contractAddressUpdated = $true
                } elseif ($line -match "^PRIVATE_KEY=") {
                    # Use first Hardhat account private key
                    $newEnvContent += "PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
                    $privateKeyUpdated = $true
                } else {
                    $newEnvContent += $line
                }
            }
            
            # Add missing environment variables
            if (-not $contractAddressUpdated) {
                $newEnvContent += "BLOCKCHAIN_CONTRACT_ADDRESS=$contractAddress"
            }
            if (-not $privateKeyUpdated) {
                $newEnvContent += "PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
            }
            
            $newEnvContent | Out-File ".env" -Encoding UTF8
            Write-Host "✅ Backend .env updated with contract address" -ForegroundColor Green
            
            Set-Location "../.."
        } else {
            Write-Host "❌ Failed to extract contract address from deployment output" -ForegroundColor Red
            Set-Location ".."
        }
    } catch {
        Write-Host "❌ Contract deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Set-Location ".."
    }
}

function Start-Backend {
    Write-Host "`n🖥️  Starting backend service..." -ForegroundColor Yellow
    
    Set-Location "services/gateway-node"
    
    # Check if port is already in use
    $portInUse = Get-NetTCPConnection -LocalPort $backendPort -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host "⚠️ Port $backendPort is already in use. Backend may already be running." -ForegroundColor Yellow
        Set-Location "../.."
        return
    }
    
    Write-Host "   Starting on port $backendPort..." -ForegroundColor White
    Start-Process -FilePath "pwsh" -ArgumentList "-Command", "npm start" -WindowStyle Normal
    
    Set-Location "../.."
    
    # Wait for backend to start
    Write-Host "   Waiting for backend to start..." -ForegroundColor White
    Start-Sleep 10
    
    # Test backend
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/blockchain/status" -Method Get -TimeoutSec 10
        if ($response.success) {
            Write-Host "✅ Backend service is running" -ForegroundColor Green
            if ($response.data.connected) {
                Write-Host "✅ Blockchain connection established" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Backend running but blockchain not connected" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "❌ Backend service connection failed" -ForegroundColor Red
    }
}

function Start-Frontend {
    Write-Host "`n🌐 Starting frontend application..." -ForegroundColor Yellow
    
    Set-Location "frontend-react"
    
    # Check if port is already in use
    $portInUse = Get-NetTCPConnection -LocalPort $frontendPort -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host "⚠️ Port $frontendPort is already in use. Frontend may already be running." -ForegroundColor Yellow
        Set-Location ".."
        return
    }
    
    # Check if dependencies are installed
    if (-not (Test-Path "node_modules")) {
        Write-Host "   Installing frontend dependencies..." -ForegroundColor White
        npm install
    }
    
    Write-Host "   Starting on port $frontendPort..." -ForegroundColor White
    $env:BROWSER = "none"  # Prevent auto-opening browser
    Start-Process -FilePath "pwsh" -ArgumentList "-Command", "npm start" -WindowStyle Minimized
    
    Set-Location ".."
    
    Write-Host "✅ Frontend starting (will be available at http://localhost:$frontendPort)" -ForegroundColor Green
}

function Show-Status {
    Write-Host "`n📊 Service Status:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    # Check Hardhat
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$hardhatPort" -Method Post -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -ContentType "application/json" -TimeoutSec 2 | Out-Null
        Write-Host "🔗 Blockchain Node:  ✅ Running (http://127.0.0.1:$hardhatPort)" -ForegroundColor Green
    } catch {
        Write-Host "🔗 Blockchain Node:  ❌ Not running" -ForegroundColor Red
    }
    
    # Check Backend
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/blockchain/status" -Method Get -TimeoutSec 2
        Write-Host "🖥️  Backend Service: ✅ Running (http://localhost:$backendPort)" -ForegroundColor Green
        if ($response.data.connected) {
            Write-Host "   └─ Blockchain:    ✅ Connected" -ForegroundColor Green
        } else {
            Write-Host "   └─ Blockchain:    ❌ Not connected" -ForegroundColor Red
        }
    } catch {
        Write-Host "🖥️  Backend Service: ❌ Not running" -ForegroundColor Red
    }
    
    # Check Frontend
    try {
        Invoke-RestMethod -Uri "http://localhost:$frontendPort" -Method Get -TimeoutSec 2 | Out-Null
        Write-Host "🌐 Frontend App:    ✅ Running (http://localhost:$frontendPort)" -ForegroundColor Green
    } catch {
        Write-Host "🌐 Frontend App:    ⚠️  Starting up or not running" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "`n🚀 Starting Sentinel development environment..." -ForegroundColor Yellow

# Parse command line arguments
$startAll = $true
$skipHardhat = $false
$skipDeploy = $false
$skipBackend = $false
$skipFrontend = $false

foreach ($arg in $args) {
    switch ($arg) {
        "--skip-hardhat" { $skipHardhat = $true }
        "--skip-deploy" { $skipDeploy = $true }
        "--skip-backend" { $skipBackend = $true }
        "--skip-frontend" { $skipFrontend = $true }
        "--status" { 
            Show-Status
            exit 0
        }
        "--help" {
            Write-Host "`nUsage: .\run-blockchain-dev.ps1 [options]" -ForegroundColor White
            Write-Host "`nOptions:" -ForegroundColor White
            Write-Host "  --skip-hardhat   Skip starting Hardhat node" -ForegroundColor White
            Write-Host "  --skip-deploy    Skip contract deployment" -ForegroundColor White
            Write-Host "  --skip-backend   Skip starting backend service" -ForegroundColor White
            Write-Host "  --skip-frontend  Skip starting frontend app" -ForegroundColor White
            Write-Host "  --status         Show current service status" -ForegroundColor White
            Write-Host "  --help          Show this help message" -ForegroundColor White
            exit 0
        }
    }
}

try {
    if (-not $skipHardhat) {
        Start-HardhatNode
    }
    
    if (-not $skipDeploy) {
        Deploy-Contract
    }
    
    if (-not $skipBackend) {
        Start-Backend
    }
    
    if (-not $skipFrontend) {
        Start-Frontend
    }
    
    Write-Host "`n✨ Development environment setup complete!" -ForegroundColor Cyan
    
    Show-Status
    
    Write-Host "`n🎯 Quick Test Commands:" -ForegroundColor Yellow
    Write-Host "   .\test-blockchain.ps1                    # Run test suite" -ForegroundColor White
    Write-Host "   Invoke-RestMethod http://localhost:5000/api/blockchain/status  # Check status" -ForegroundColor White
    
    Write-Host "`n📚 Available Endpoints:" -ForegroundColor Yellow
    Write-Host "   http://localhost:5000/api/threat         # POST - Log threat" -ForegroundColor White
    Write-Host "   http://localhost:5000/api/threats/mongodb # GET - MongoDB threats" -ForegroundColor White
    Write-Host "   http://localhost:5000/api/threats/blockchain # GET - Blockchain threats" -ForegroundColor White
    Write-Host "   http://localhost:5000/api/threats/stats  # GET - Statistics" -ForegroundColor White
    
    Write-Host "`n🔧 To stop services:" -ForegroundColor Yellow
    Write-Host "   Get-Process | Where-Object {$_.ProcessName -eq 'node'} | Stop-Process" -ForegroundColor White
    
} catch {
    Write-Host "❌ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
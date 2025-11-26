#!/usr/bin/env pwsh

# Sentinel Blockchain Test Script
# Tests the complete threat logging workflow

Write-Host "🧪 Sentinel Blockchain Testing Suite" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$backendUrl = "http://localhost:5000"

function Test-Service {
    param($url, $name)
    try {
        $response = Invoke-RestMethod -Uri "$url/api/blockchain/status" -Method Get -TimeoutSec 5
        if ($response.success) {
            Write-Host "✅ $name is running" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ $name is not responding" -ForegroundColor Red
        return $false
    }
}

function Test-ThreatLogging {
    Write-Host "`n🔍 Testing threat logging..." -ForegroundColor Yellow
    
    $threatData = @{
        userId = "test_user_$(Get-Date -Format 'yyyyMMddHHmmss')"
        suspicionScore = 0.95
        ipAddress = "192.168.1.100"
        severity = "CRITICAL"
        detectionDetails = @{
            type = "velocity_attack"
            requestCount = 150
            timeWindow = "60s"
        }
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/api/threat" -Method Post -Body $threatData -ContentType "application/json"
        
        if ($response.success) {
            Write-Host "✅ Threat logged successfully" -ForegroundColor Green
            Write-Host "   Threat ID: $($response.data.threatId)" -ForegroundColor White
            Write-Host "   Blockchain TX: $($response.data.blockchainTxHash)" -ForegroundColor White
            Write-Host "   Status: $($response.data.blockchainStatus)" -ForegroundColor White
            return $response.data.threatId
        } else {
            Write-Host "❌ Failed to log threat: $($response.error)" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "❌ Error logging threat: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Test-ThreatRetrieval {
    param($threatId)
    
    Write-Host "`n🔍 Testing threat retrieval..." -ForegroundColor Yellow
    
    # Test MongoDB retrieval
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/api/threats/mongodb?limit=5" -Method Get
        if ($response.success -and $response.data.threats.Count -gt 0) {
            Write-Host "✅ MongoDB threat retrieval works" -ForegroundColor Green
            Write-Host "   Found $($response.data.threats.Count) threats" -ForegroundColor White
        } else {
            Write-Host "⚠️ No threats found in MongoDB" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ MongoDB retrieval failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test blockchain retrieval
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/api/threats/blockchain?count=5" -Method Get
        if ($response.success) {
            Write-Host "✅ Blockchain threat retrieval works" -ForegroundColor Green
            Write-Host "   Total blockchain threats: $($response.data.totalCount)" -ForegroundColor White
            Write-Host "   Retrieved: $($response.data.threats.Count) threats" -ForegroundColor White
        } else {
            Write-Host "❌ Blockchain retrieval failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Blockchain retrieval failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-Statistics {
    Write-Host "`n📊 Testing statistics..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$backendUrl/api/threats/stats" -Method Get
        if ($response.success) {
            Write-Host "✅ Statistics retrieval works" -ForegroundColor Green
            Write-Host "   MongoDB threats: $($response.data.mongodb.totalThreats)" -ForegroundColor White
            Write-Host "   Blockchain threats: $($response.data.blockchain.totalThreats)" -ForegroundColor White
            Write-Host "   Sync rate: $($response.data.integrity.syncRate)" -ForegroundColor White
        } else {
            Write-Host "❌ Statistics retrieval failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Statistics failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main test execution
Write-Host "`n🔍 Checking service status..." -ForegroundColor Yellow

$backendRunning = Test-Service $backendUrl "Backend Service"

if (-not $backendRunning) {
    Write-Host "`n❌ Backend service is not running. Please start it first:" -ForegroundColor Red
    Write-Host "   cd services/gateway-node && npm start" -ForegroundColor White
    exit 1
}

Write-Host "`n🧪 Running tests..." -ForegroundColor Yellow

# Test threat logging
$threatId = Test-ThreatLogging

# Test retrieval
Test-ThreatRetrieval $threatId

# Test statistics
Test-Statistics

# Test blockchain status
Write-Host "`n🔍 Checking blockchain status..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$backendUrl/api/blockchain/status" -Method Get
    if ($response.success -and $response.data.connected) {
        Write-Host "✅ Blockchain is connected" -ForegroundColor Green
        Write-Host "   Contract: $($response.data.contractAddress)" -ForegroundColor White
        Write-Host "   Wallet: $($response.data.walletAddress)" -ForegroundColor White
        Write-Host "   Threats: $($response.data.threatCount)" -ForegroundColor White
    } else {
        Write-Host "⚠️ Blockchain is not connected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Blockchain status check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n✨ Test suite completed!" -ForegroundColor Cyan
Write-Host "`n📋 Test Summary:" -ForegroundColor Yellow
Write-Host "- Backend Service: $(if ($backendRunning) { '✅ Running' } else { '❌ Down' })" -ForegroundColor White
Write-Host "- Threat Logging: $(if ($threatId) { '✅ Working' } else { '❌ Failed' })" -ForegroundColor White

if ($threatId) {
    Write-Host "`n🔍 You can view the logged threat at:" -ForegroundColor Cyan
    Write-Host "   $backendUrl/api/threat/$threatId" -ForegroundColor White
}
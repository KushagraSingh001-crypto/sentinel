#!/usr/bin/env pwsh

# Sentinel Blockchain Module Setup Script
# This script sets up the complete blockchain infrastructure for threat logging

Write-Host "🛡️  Sentinel Blockchain Module Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$startLocation = Get-Location

try {
    # Navigate to blockchain directory
    Set-Location "blockchain"
    
    Write-Host "`n📦 Installing blockchain dependencies..." -ForegroundColor Yellow
    
    # Check if Node.js is installed
    try {
        $nodeVersion = node --version
        Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js is not installed. Please install Node.js first." -ForegroundColor Red
        exit 1
    }
    
    # Install dependencies
    npm install
    
    Write-Host "`n🔧 Compiling smart contracts..." -ForegroundColor Yellow
    npx hardhat compile
    
    Write-Host "`n✅ Blockchain module setup complete!" -ForegroundColor Green
    Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Start Hardhat node: npx hardhat node" -ForegroundColor White
    Write-Host "2. Deploy contract: npm run deploy" -ForegroundColor White
    Write-Host "3. Copy contract address to backend .env" -ForegroundColor White
    Write-Host "4. Start backend server" -ForegroundColor White
    
    Write-Host "`n🚀 To start the local blockchain:" -ForegroundColor Yellow
    Write-Host "   cd blockchain && npx hardhat node" -ForegroundColor White
    
} catch {
    Write-Host "❌ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $startLocation
}
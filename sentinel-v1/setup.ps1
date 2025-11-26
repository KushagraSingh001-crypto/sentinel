# 🛠️ Sentinel v1 - Setup Script
# Run this script ONCE to install all dependencies before using run-local.ps1

Write-Host "🛡️  Sentinel v1 - Initial Setup" -ForegroundColor Green
Write-Host "=" * 40

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Check prerequisites
Write-Host "📋 Checking prerequisites..."

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js 18+ from https://nodejs.org" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found. Please install Python 3.11+ from https://python.org" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📦 Installing dependencies..."

# Install Node.js dependencies
Write-Host "Installing Gateway dependencies..." -ForegroundColor Cyan
Set-Location "$root\services\gateway-node"
npm install
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install gateway deps" -ForegroundColor Red; exit 1 }

Write-Host "Installing Frontend dependencies..." -ForegroundColor Cyan
Set-Location "$root\frontend-react"
npm install --legacy-peer-deps
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install frontend deps" -ForegroundColor Red; exit 1 }

Write-Host "Installing Blockchain dependencies..." -ForegroundColor Cyan
Set-Location "$root\blockchain"
npm install
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install blockchain deps" -ForegroundColor Red; exit 1 }

Write-Host "Installing Attacker demo dependencies..." -ForegroundColor Cyan
Set-Location "$root\attacker-demo"
npm install axios
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install attacker deps" -ForegroundColor Red; exit 1 }

# Install Python dependencies
Write-Host "Creating Python virtual environment for Wrappers..." -ForegroundColor Cyan
Set-Location "$root\services\wrappers-py"
python -m venv .venv
& ".\.venv\Scripts\pip.exe" install --upgrade pip
& ".\.venv\Scripts\pip.exe" install -r requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install wrappers deps" -ForegroundColor Red; exit 1 }

Write-Host "Creating Python virtual environment for Detector..." -ForegroundColor Cyan
Set-Location "$root\services\detector-py"
python -m venv .venv
& ".\.venv\Scripts\pip.exe" install --upgrade pip
& ".\.venv\Scripts\pip.exe" install -r requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to install detector deps" -ForegroundColor Red; exit 1 }

# Setup environment files
Set-Location $root
Write-Host ""
Write-Host "⚙️  Setting up environment configuration..."

if (-Not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Created .env from template" -ForegroundColor Green
    Write-Host "⚠️  Please edit .env with your MongoDB connection string!" -ForegroundColor Yellow
} else {
    Write-Host "✅ .env already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:"
Write-Host "1. Edit .env file with your MongoDB Atlas connection:" -ForegroundColor Yellow
Write-Host "   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/?appName=yourapp" -ForegroundColor Gray
Write-Host "   DB_NAME=your_database_name" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run all services:" -ForegroundColor Yellow  
Write-Host "   .\run-local.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Open http://localhost:3000 in your browser" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 For MongoDB Atlas setup, visit: https://www.mongodb.com/atlas" -ForegroundColor Cyan
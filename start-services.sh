#!/bin/bash

# Sentinel Project Startup Script
# Starts all 4 services: Blockchain, Gateway, Detector, Wrappers

set -e

PROJECT_ROOT="/home/sarvadubey/Desktop/VeryBigHack"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          SENTINEL PROJECT STARTUP SEQUENCE                   ║"
echo "║          Starting 4 Services...                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📋 Configuration:${NC}"
echo "   MongoDB: mongodb+srv://ananya:ananya44444@07.uyod6fe.mongodb.net"
echo "   Database: 07"
echo "   Gateway Port: 3001"
echo "   Detector Port: 8001"
echo "   Wrappers Port: 8002"
echo "   Blockchain Port: 8545"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   You need 4 terminals to run all services."
echo "   Each terminal will run one service."
echo ""

# Check if services directories exist
echo -e "${BLUE}✓ Checking project structure...${NC}"
if [ -d "$PROJECT_ROOT/sentinel-v1/blockchain" ] && \
   [ -d "$PROJECT_ROOT/sentinel-v1/services/gateway-node" ] && \
   [ -d "$PROJECT_ROOT/sentinel-v1/services/detector-py" ] && \
   [ -d "$PROJECT_ROOT/sentinel-v1/services/wrappers-py" ]; then
    echo -e "${GREEN}✓ All service directories found${NC}"
else
    echo "❌ Some service directories not found"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    STARTUP INSTRUCTIONS                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${GREEN}TERMINAL 1 - BLOCKCHAIN (Hardhat Node)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $PROJECT_ROOT/sentinel-v1/blockchain"
echo "npx hardhat node"
echo ""
echo "⏳ Wait for it to start before running other services"
echo ""

echo -e "${GREEN}TERMINAL 2 - GATEWAY (Node.js Express)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $PROJECT_ROOT/sentinel-v1/services/gateway-node"
echo "npm install 2>/dev/null || true"
echo "npm start"
echo ""
echo "📡 Gateway will run on: http://localhost:3001"
echo ""

echo -e "${GREEN}TERMINAL 3 - DETECTOR (Python FastAPI)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $PROJECT_ROOT/sentinel-v1"
echo "python3 -m venv venv 2>/dev/null || true"
echo "source venv/bin/activate 2>/dev/null || true"
echo "pip install -q fastapi uvicorn pymongo python-dotenv 2>/dev/null || true"
echo "python -m uvicorn services.detector-py.app.main:app --port 8001 --reload"
echo ""
echo "🔍 Detector will run on: http://localhost:8001"
echo ""

echo -e "${GREEN}TERMINAL 4 - WRAPPERS (Python FastAPI)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd $PROJECT_ROOT/sentinel-v1"
echo "python3 -m venv venv 2>/dev/null || true"
echo "source venv/bin/activate 2>/dev/null || true"
echo "pip install -q fastapi uvicorn pymongo python-dotenv transformers torch 2>/dev/null || true"
echo "python -m uvicorn services.wrappers-py.app.main:app --port 8002 --reload"
echo ""
echo "🎭 Wrappers will run on: http://localhost:8002"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    TESTING ENDPOINTS                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${GREEN}After all 4 services are running, test with:${NC}"
echo ""
echo "1️⃣  Check Gateway Health:"
echo "   curl http://localhost:3001/health || echo 'Gateway not ready'"
echo ""
echo "2️⃣  Check Blockchain Threats:"
echo "   curl http://localhost:3001/api/v1/threat-log"
echo ""
echo "3️⃣  Send Test Prompt:"
echo "   curl -X POST http://localhost:3001/api/v1/prompt \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"userId\": \"testuser\", \"prompt\": \"What is AI?\"}'"
echo ""
echo "4️⃣  Check Blockchain Stats:"
echo "   curl http://localhost:3001/api/v1/blockchain-stats"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    QUICK COPY-PASTE COMMANDS                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Terminal 1 (copy & paste):"
echo "cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/blockchain && npx hardhat node"
echo ""

echo "📋 Terminal 2 (copy & paste):"
echo "cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/services/gateway-node && npm install && npm start"
echo ""

echo "📋 Terminal 3 (copy & paste):"
echo "cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1 && python -m uvicorn services.detector-py.app.main:app --port 8001 --reload"
echo ""

echo "📋 Terminal 4 (copy & paste):"
echo "cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1 && python -m uvicorn services.wrappers-py.app.main:app --port 8002 --reload"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✨ Ready to run! Open 4 terminals and copy the commands above."
echo ""

# Check if MongoDB is running
echo "🔍 Checking MongoDB connection..."
if ! mongosh --eval "db.version()" > /dev/null 2>&1; then
    echo "⚠️  MongoDB is not running. Please start it with:"
    echo "   docker run -d -p 27017:27017 --name mongodb mongo"
    echo "   or"
    echo "   mongod"
    exit 1
fi
echo "✅ MongoDB is running"
echo ""

# Check Node.js
echo "🔍 Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi
echo "✅ Node.js $(node -v) is installed"
echo ""

# Check Python
echo "🔍 Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi
echo "✅ Python $(python3 --version) is installed"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
echo ""

echo "  Installing Blockchain dependencies..."
cd sentinel-v1/blockchain
if [ ! -d node_modules ]; then
    npm install > /dev/null 2>&1
fi
cd ../..
echo "  ✅ Blockchain dependencies ready"

echo "  Installing Gateway dependencies..."
cd sentinel-v1/services/gateway-node
if [ ! -d node_modules ]; then
    npm install > /dev/null 2>&1
fi
cd ../../..
echo "  ✅ Gateway dependencies ready"
echo ""

# Display startup instructions
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                  STARTING SERVICES                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  You need to open 4 separate terminals and run these commands:"
echo ""

echo "┌─ TERMINAL 1: Hardhat Blockchain ─────────────────────────────────────────┐"
echo "│                                                                           │"
echo "│  cd $(pwd)/sentinel-v1/blockchain                    │"
echo "│  npx hardhat node                                    │"
echo "│                                                                           │"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─ TERMINAL 2: Gateway Service ─────────────────────────────────────────────┐"
echo "│                                                                           │"
echo "│  cd $(pwd)/sentinel-v1/services/gateway-node        │"
echo "│  npm start                                           │"
echo "│                                                                           │"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─ TERMINAL 3: Detector Service ────────────────────────────────────────────┐"
echo "│                                                                           │"
echo "│  cd $(pwd)/sentinel-v1                             │"
echo "│  python -m uvicorn services.detector-py.app.main:app --port 8001 --reload│"
echo "│                                                                           │"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─ TERMINAL 4: Wrappers Service ────────────────────────────────────────────┐"
echo "│                                                                           │"
echo "│  cd $(pwd)/sentinel-v1                             │"
echo "│  python -m uvicorn services.wrappers-py.app.main:app --port 8002 --reload│"
echo "│                                                                           │"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

echo "════════════════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Service Ports:"
echo "   • Hardhat:  http://localhost:8545"
echo "   • Gateway:  http://localhost:8000"
echo "   • Detector: http://localhost:8001"
echo "   • Wrappers: http://localhost:8002"
echo ""

echo "🧪 Once all services are running, test with:"
echo ""
echo "   curl http://localhost:8000/api/v1/threat-log"
echo ""
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

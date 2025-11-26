#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          SENTINEL V1 - Multi-Service Startup Script               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo -e "${YELLOW}📂 Project Root:${NC} $PROJECT_ROOT"
echo ""

# Check if running with screen or tmux for better multi-window support
if command -v tmux &> /dev/null; then
    echo -e "${GREEN}✓ tmux found - using for multi-window session${NC}"
    
    # Create new tmux session
    SESSION_NAME="sentinel-v1"
    
    if tmux has-session -t $SESSION_NAME 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Session $SESSION_NAME already exists. Killing it...${NC}"
        tmux kill-session -t $SESSION_NAME
    fi
    
    echo -e "${BLUE}Starting services in tmux session: $SESSION_NAME${NC}"
    echo ""
    
    # Create session and windows
    tmux new-session -d -s $SESSION_NAME -x 200 -y 50
    
    # Window 1: Gateway
    echo -e "${GREEN}[1/4]${NC} Starting Gateway on port 3001..."
    tmux new-window -t $SESSION_NAME -n "gateway"
    tmux send-keys -t $SESSION_NAME:gateway "cd '$PROJECT_ROOT/sentinel-v1/services/gateway-node' && npm install && npm start" Enter
    sleep 3
    
    # Window 2: Detector
    echo -e "${GREEN}[2/4]${NC} Starting Detector on port 8001..."
    tmux new-window -t $SESSION_NAME -n "detector"
    tmux send-keys -t $SESSION_NAME:detector "cd '$PROJECT_ROOT/sentinel-v1/services/detector-py' && python -m uvicorn app.main:app --port 8001 --host 0.0.0.0" Enter
    sleep 3
    
    # Window 3: Wrappers
    echo -e "${GREEN}[3/4]${NC} Starting Wrappers on port 8002..."
    tmux new-window -t $SESSION_NAME -n "wrappers"
    tmux send-keys -t $SESSION_NAME:wrappers "cd '$PROJECT_ROOT/sentinel-v1/services/wrappers-py' && python -m uvicorn app.main:app --port 8002 --host 0.0.0.0" Enter
    sleep 3
    
    # Window 4: Blockchain
    echo -e "${GREEN}[4/4]${NC} Starting Blockchain on port 8545..."
    tmux new-window -t $SESSION_NAME -n "blockchain"
    tmux send-keys -t $SESSION_NAME:blockchain "cd '$PROJECT_ROOT/sentinel-v1/blockchain' && npm install >/dev/null 2>&1 && npx hardhat node" Enter
    
    sleep 5
    
    echo ""
    echo -e "${GREEN}✓ All services started in tmux session!${NC}"
    echo ""
    echo -e "${BLUE}Available windows:${NC}"
    tmux list-windows -t $SESSION_NAME
    echo ""
    echo -e "${YELLOW}To attach to the session:${NC}"
    echo "  tmux attach-session -t $SESSION_NAME"
    echo ""
    echo -e "${YELLOW}To view a specific window:${NC}"
    echo "  tmux select-window -t $SESSION_NAME:gateway   # Gateway"
    echo "  tmux select-window -t $SESSION_NAME:detector  # Detector"
    echo "  tmux select-window -t $SESSION_NAME:wrappers  # Wrappers"
    echo "  tmux select-window -t $SESSION_NAME:blockchain # Blockchain"
    echo ""
    
else
    echo -e "${YELLOW}⚠️  tmux not found. Starting services in background...${NC}"
    echo ""
    
    # Start services in background
    echo -e "${GREEN}[1/4]${NC} Starting Gateway on port 3001..."
    cd "$PROJECT_ROOT/sentinel-v1/services/gateway-node"
    npm install >/dev/null 2>&1
    npm start > /tmp/gateway.log 2>&1 &
    GATEWAY_PID=$!
    echo -e "${GREEN}     PID: $GATEWAY_PID${NC}"
    sleep 2
    
    echo -e "${GREEN}[2/4]${NC} Starting Detector on port 8001..."
    cd "$PROJECT_ROOT/sentinel-v1/services/detector-py"
    python -m uvicorn app.main:app --port 8001 --host 0.0.0.0 > /tmp/detector.log 2>&1 &
    DETECTOR_PID=$!
    echo -e "${GREEN}     PID: $DETECTOR_PID${NC}"
    sleep 2
    
    echo -e "${GREEN}[3/4]${NC} Starting Wrappers on port 8002..."
    cd "$PROJECT_ROOT/sentinel-v1/services/wrappers-py"
    python -m uvicorn app.main:app --port 8002 --host 0.0.0.0 > /tmp/wrappers.log 2>&1 &
    WRAPPERS_PID=$!
    echo -e "${GREEN}     PID: $WRAPPERS_PID${NC}"
    sleep 2
    
    echo -e "${GREEN}[4/4]${NC} Starting Blockchain on port 8545..."
    cd "$PROJECT_ROOT/sentinel-v1/blockchain"
    npm install >/dev/null 2>&1
    npx hardhat node > /tmp/blockchain.log 2>&1 &
    BLOCKCHAIN_PID=$!
    echo -e "${GREEN}     PID: $BLOCKCHAIN_PID${NC}"
    
    echo ""
    echo -e "${GREEN}✓ All services started in background!${NC}"
    echo ""
    echo -e "${YELLOW}Process PIDs:${NC}"
    echo "  Gateway   : $GATEWAY_PID"
    echo "  Detector  : $DETECTOR_PID"
    echo "  Wrappers  : $WRAPPERS_PID"
    echo "  Blockchain: $BLOCKCHAIN_PID"
    echo ""
    echo -e "${YELLOW}Log files:${NC}"
    echo "  tail -f /tmp/gateway.log"
    echo "  tail -f /tmp/detector.log"
    echo "  tail -f /tmp/wrappers.log"
    echo "  tail -f /tmp/blockchain.log"
    echo ""
fi

# Wait a bit for services to initialize
sleep 5

# Check service status
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    CHECKING SERVICE STATUS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

check_service() {
    local name=$1
    local port=$2
    local endpoint=$3
    
    if curl -s -m 2 "http://localhost:$port$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name (port $port) - RESPONDING"
        return 0
    else
        echo -e "${YELLOW}⏳${NC} $name (port $port) - starting up..."
        return 1
    fi
}

echo "Checking services..."
check_service "Gateway" 3001 "/api/v1/blockchain-stats"
check_service "Detector" 8001 "/docs"
check_service "Wrappers" 8002 "/health"
check_service "Blockchain" 8545 ""

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Sentinel V1 startup complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Quick Links:${NC}"
echo "  Gateway API     : http://localhost:3001"
echo "  Detector UI     : http://localhost:8001/docs"
echo "  Wrappers Health : http://localhost:8002/health"
echo "  Blockchain RPC  : http://localhost:8545"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  see CURRENT_STATUS.md"
echo "  see QUICK_START_COMMANDS.md"
echo "  see README.md"
echo ""

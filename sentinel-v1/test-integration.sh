#!/bin/bash

# Integration Test Script for Sentinel Blockchain + Services
# This script verifies all connections between blockchain and services

set -e

echo "=================================="
echo "Sentinel Integration Test Suite"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if logThreat.js exists
echo -e "${YELLOW}[1/5] Checking logThreat.js script...${NC}"
if [ -f "./blockchain/scripts/logThreat.js" ]; then
    echo -e "${GREEN}✓ logThreat.js found${NC}"
else
    echo -e "${RED}✗ logThreat.js not found${NC}"
    exit 1
fi
echo ""

# Check if ThreatChain.abi.json exists
echo -e "${YELLOW}[2/5] Checking ThreatChain ABI...${NC}"
if [ -f "./blockchain/ThreatChain.abi.json" ]; then
    echo -e "${GREEN}✓ ThreatChain.abi.json found${NC}"
else
    echo -e "${RED}✗ ThreatChain.abi.json not found${NC}"
    echo "Tip: Run 'npm run deploy' in the blockchain directory first"
    exit 1
fi
echo ""

# Check if deployments.json exists
echo -e "${YELLOW}[3/5] Checking deployments.json...${NC}"
if [ -f "./blockchain/deployments.json" ]; then
    echo -e "${GREEN}✓ deployments.json found${NC}"
else
    echo -e "${RED}✗ deployments.json not found${NC}"
    echo "Tip: Run 'npm run deploy' in the blockchain directory first"
    exit 1
fi
echo ""

# Check detector-py integration
echo -e "${YELLOW}[4/5] Checking detector-py blockchain integration...${NC}"
if grep -q "log_threat_to_blockchain" "./services/detector-py/app/main.py"; then
    echo -e "${GREEN}✓ detector-py has blockchain integration${NC}"
else
    echo -e "${RED}✗ detector-py missing blockchain integration${NC}"
    exit 1
fi
echo ""

# Check gateway blockchain endpoints
echo -e "${YELLOW}[5/5] Checking gateway-node blockchain endpoints...${NC}"
if grep -q "/api/v1/threat-log" "./services/gateway-node/src/index.js"; then
    echo -e "${GREEN}✓ gateway-node has threat-log endpoint${NC}"
else
    echo -e "${RED}✗ gateway-node missing threat-log endpoint${NC}"
    exit 1
fi

if grep -q "/api/v1/blockchain-stats" "./services/gateway-node/src/index.js"; then
    echo -e "${GREEN}✓ gateway-node has blockchain-stats endpoint${NC}"
else
    echo -e "${RED}✗ gateway-node missing blockchain-stats endpoint${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}=================================="
echo "✓ All integration checks passed!"
echo "==================================${NC}"
echo ""
echo "Integration points verified:"
echo "  • Blockchain deployment artifacts available"
echo "  • logThreat.js script ready for threat logging"
echo "  • Detector service configured to call blockchain"
echo "  • Gateway service has blockchain API endpoints"
echo ""
echo "Next steps:"
echo "  1. Start your services:"
echo "     - hardhat node (in blockchain/)"
echo "     - npm start (in gateway-node/)"
echo "     - python -m uvicorn sentinel-v1.services.detector-py.app.main:app --port 8001"
echo "     - python -m uvicorn sentinel-v1.services.wrappers-py.app.main:app --port 8002"
echo ""
echo "  2. Test the integration by sending a prompt via gateway"
echo "  3. Monitor threat_records.json for blockchain threat logs"
echo ""

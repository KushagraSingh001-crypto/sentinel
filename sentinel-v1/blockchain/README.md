# 🛡️ Sentinel ThreatChain - Blockchain Module

## Overview

The Sentinel MLaaS Security Platform is a complete threat detection and logging system with blockchain integration. It consists of:

- **🌐 Frontend React App**: User interface for monitoring threats and system status
- **⚙️ Backend Gateway**: Node.js API server handling requests and threat logging  
- **🔗 Blockchain Module**: Ethereum smart contracts for immutable threat logging
- **🤖 ML Detector Service**: Python service for real-time threat detection
- **🛡️ Wrappers Service**: Python service providing noisy responses to suspicious users

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Blockchain    │
│   React:3000    │───▶│   Node.js:5000  │───▶│   Hardhat:8545  │
│                 │    │                 │    │                 │
│ • Admin Panel   │    │ • Threat API    │    │ • ThreatChain   │
│ • Monitoring    │    │ • User API      │    │ • Immutable Log │
│ • Statistics    │    │ • ML Integration│    │ • Smart Contract│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │ │
                              ▼ ▼
                   ┌─────────────────┐    ┌─────────────────┐
                   │   ML Detector   │    │   Wrappers      │
                   │   Python:8001   │    │   Python:8002   │
                   │                 │    │                 │
                   │ • Threat Score  │    │ • Noisy Replies │
                   │ • Behavior AI   │    │ • Rate Limiting │
                   │ • Risk Analysis │    │ • Obfuscation   │
                   └─────────────────┘    └─────────────────┘
                              │
                              ▼
                   ┌─────────────────┐
                   │   MongoDB Atlas │
                   │   Cloud Database│
                   │                 │
                   │ • User Data     │
                   │ • Query Logs    │ 
                   │ • Threat Records│
                   └─────────────────┘
```

## 📁 Directory Structure

```
blockchain/
├── contracts/
│   └── ThreatChain.sol          # Main smart contract
├── scripts/
│   ├── deploy.js                # Deployment script
│   └── verify.js                # Verification script
├── artifacts/                   # Compiled contracts (auto-generated)
├── cache/                       # Hardhat cache (auto-generated)
├── hardhat.config.js           # Hardhat configuration
├── package.json                # Node.js dependencies
├── deployments.json            # Deployment info (auto-generated)
├── ThreatChain.abi.json        # Contract ABI (auto-generated)
├── .env                        # Environment variables
└── .env.example               # Environment template
```

## 🚀 Complete System Setup

This guide shows how to run the entire Sentinel platform with Frontend, Backend, and Blockchain components.

### 📋 Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Git

### 🔧 Full System Setup

#### 1. Initial Setup

```bash
# Clone and navigate to project
git clone <repository-url>
cd sentinel-v1

# Install all dependencies
cd blockchain && npm install
cd ../services/gateway-node && npm install  
cd ../frontend-react && npm install
cd ../services/detector-py && pip install -r requirements.txt
cd ../services/wrappers-py && pip install -r requirements.txt
```

#### 2. Environment Configuration

```bash
# Configure blockchain environment
cd blockchain
cp .env.example .env
# Edit .env with your MongoDB URI: mongodb+srv://ananya:ananya44444@07.uyod6fe.mongodb.net/?appName=07

# Configure backend environment  
cd ../services/gateway-node
cp .env.example .env
# Edit .env with same MongoDB URI and blockchain settings
```

### 🚀 Running the Complete System

#### Option A: One-Command Startup (Easiest)

Use the automated startup script:

```bash
# Start everything at once
.\start-sentinel.ps1

# Or start specific components
.\start-sentinel.ps1 -Mode backend      # Backend + Blockchain only
.\start-sentinel.ps1 -Mode blockchain   # Blockchain only
.\start-sentinel.ps1 -Help              # Show all options
```

#### Option B: Development Mode (Manual Control)

Run each component in separate terminals:

**Terminal 1 - Blockchain Node:**
```bash
cd blockchain
npx hardhat node
```

**Terminal 2 - Deploy Smart Contract:**
```bash
cd blockchain
npm run deploy
# Copy the contract address and update backend .env file
```

**Terminal 3 - Backend Gateway:**
```bash
cd services/gateway-node
npm start
```

**Terminal 4 - Python Detector Service:**
```bash
cd services/detector-py
python app/main.py
```

**Terminal 5 - Python Wrappers Service:**
```bash
cd services/wrappers-py  
python app/main.py
```

**Terminal 6 - Frontend React App:**
```bash
cd frontend-react
npm start
```

#### Option B: Quick Backend-Only Mode

For testing threat logging without full frontend:

**Terminal 1 - Blockchain:**
```bash
cd blockchain
npx hardhat node
```

**Terminal 2 - Deploy & Start Backend:**
```bash
cd blockchain && npm run deploy
cd ../services/gateway-node && npm start
```

### 🌐 Service URLs

Once running, access these services:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000  
- **Blockchain RPC**: http://127.0.0.1:8545
- **Detector Service**: http://localhost:8001
- **Wrappers Service**: http://localhost:8002

### 🧪 Testing the System

#### Test Threat Detection API:
```bash
curl -X POST http://localhost:5000/api/threat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_user",
    "suspicionScore": 0.95,
    "ipAddress": "192.168.1.100", 
    "severity": "CRITICAL",
    "detectionDetails": {
      "type": "velocity_attack",
      "requestCount": 150
    }
  }'
```

#### Test User Query API:
```bash
curl -X POST http://localhost:5000/api/v1/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_user", 
    "prompt": "What is machine learning?"
  }'
```

### 🔧 Development Workflow

#### Blockchain Development:
```bash
cd blockchain
npx hardhat compile    # Compile contracts
npm run deploy        # Deploy to local network
npm run verify        # Verify deployment
```

#### Backend Development:
```bash
cd services/gateway-node
npm start             # Start with auto-reload
```

#### Frontend Development:
```bash
cd frontend-react
npm start             # Start with hot-reload
```

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```env
BLOCKCHAIN_NETWORK=localhost
BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545
BLOCKCHAIN_CONTRACT_ADDRESS=0x...  # Fill after deployment
PRIVATE_KEY=0x...                  # Use Hardhat test account
MONGODB_URI=mongodb://localhost:27017/sentinel
```

### Hardhat Test Accounts

The local blockchain provides test accounts with ETH. Use any private key from the Hardhat node output:

```
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 📜 Smart Contract Features

### ThreatChain Contract

- **Immutable Logging**: Threats cannot be modified once logged
- **Privacy Protection**: IP addresses are hashed for compliance
- **Severity Classification**: LOW, MEDIUM, HIGH, CRITICAL levels
- **Efficient Retrieval**: O(1) lookups by threat ID
- **Event Emission**: Real-time threat logging events
- **Pagination Support**: Handle large datasets efficiently

### Key Functions

```solidity
// Log a new threat
function logThreat(
    string threatId,
    bytes32 threatHash,
    string ipAddress,
    Severity severity
) returns (uint256)

// Get threat count
function getThreatCount() returns (uint256)

// Get threat by ID
function getThreatById(string threatId) returns (ThreatRecord)

// Get paginated threats
function getThreatsRange(uint256 start, uint256 end) returns (ThreatRecord[])
```

## 🧪 Testing

### Manual Contract Testing

```bash
# Deploy and test logging
npm run verify -- --test-log
```

### Backend Integration Test

```bash
# From project root
.\test-blockchain.ps1
```

### Sample Threat Logging

```bash
curl -X POST http://localhost:5000/api/threat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_user",
    "suspicionScore": 0.95,
    "ipAddress": "192.168.1.100",
    "severity": "CRITICAL",
    "detectionDetails": {
      "type": "velocity_attack",
      "requestCount": 150
    }
  }'
```

## 📊 Monitoring

### Blockchain Status

```bash
curl http://localhost:5000/api/blockchain/status
```

### Threat Statistics

```bash
curl http://localhost:5000/api/threats/stats
```

### Recent Threats

```bash
curl http://localhost:5000/api/threats/blockchain?count=10
```

## 🛠️ Development Scripts

### Package.json Scripts

```json
{
  "scripts": {
    "compile": "hardhat compile",
    "deploy": "hardhat run scripts/deploy.js --network localhost",
    "verify": "hardhat run scripts/verify.js --network localhost",
    "node": "hardhat node",
    "test": "hardhat test"
  }
}
```

### PowerShell Development Scripts

```bash
# Start complete platform
.\start-sentinel.ps1                    # All components
.\start-sentinel.ps1 -Mode backend      # Backend only  
.\start-sentinel.ps1 -Mode blockchain   # Blockchain only

# Development utilities
.\setup-blockchain.ps1                  # Setup blockchain module
.\test-complete-blockchain.ps1          # Run integration tests  
.\blockchain-success.ps1                # Show system status
```

## 🔒 Security Features

### Data Integrity

- **Cryptographic Hashing**: SHA-256 hashes of threat data
- **Immutable Storage**: Blockchain prevents data tampering
- **Event Logging**: All operations emit blockchain events
- **Duplicate Prevention**: Threat IDs must be unique

### Privacy Protection

- **IP Address Hashing**: Keccak256 hashing for privacy
- **Minimal Data Storage**: Only essential fields on-chain
- **Access Control**: Contract owner functionality available

### Gas Optimization

- **Efficient Data Structures**: Optimized for read operations
- **Batch Operations**: Support for bulk threat retrieval
- **Event Indexing**: Indexed events for fast querying

## 🚀 Production Deployment

### Network Configuration

For production networks, update `hardhat.config.js`:

```javascript
networks: {
  sepolia: {
    url: "https://sepolia.infura.io/v3/YOUR-PROJECT-ID",
    accounts: [process.env.PRIVATE_KEY]
  },
  mainnet: {
    url: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID",
    accounts: [process.env.PRIVATE_KEY]
  }
}
```

### Environment Setup

```bash
# Deploy to testnet
npx hardhat run scripts/deploy.js --network sepolia

# Verify contract
npx hardhat verify --network sepolia CONTRACT_ADDRESS
```

## 📚 API Integration

The blockchain module integrates with the backend via:

1. **Threat Logging**: Automatic blockchain logging on threat detection
2. **Data Verification**: Cross-reference MongoDB with blockchain
3. **Audit Trail**: Immutable record of all security events
4. **Real-time Monitoring**: Event-driven threat notifications

## 🐛 Troubleshooting

### Common System Issues

#### Blockchain Issues:
1. **Contract Not Deployed**: Run `npm run deploy` after starting `npx hardhat node`
2. **Connection Failed**: Ensure Hardhat node is running on port 8545
3. **Gas Estimation Failed**: Restart Hardhat node and redeploy
4. **Port Conflicts**: Check if port 8545 is already in use

#### Backend Issues:
1. **MongoDB Connection Failed**: Verify your Atlas connection string in .env
2. **Port 5000 Busy**: Change PORT in .env or kill existing processes
3. **Blockchain Service Failed**: Ensure contract is deployed first
4. **Missing Dependencies**: Run `npm install` in gateway-node directory

#### Frontend Issues:
1. **Port 3000 Busy**: React will prompt to use different port
2. **API Connection Failed**: Ensure backend is running on port 5000
3. **CORS Issues**: Backend is configured for localhost:3000

#### Python Services Issues:
1. **Module Not Found**: Install requirements with `pip install -r requirements.txt`
2. **Port Conflicts**: Check if ports 8001/8002 are available
3. **Virtual Environment**: Activate your Python virtual environment

### Debug Commands

```bash
# Check what's running on ports
netstat -ano | findstr :8545    # Blockchain
netstat -ano | findstr :5000    # Backend  
netstat -ano | findstr :3000    # Frontend

# Test individual services
curl http://localhost:5000/api/blockchain/status    # Backend health
curl http://localhost:8001/health                   # Detector service
curl http://localhost:8002/health                   # Wrappers service

# View deployment info
cat blockchain/deployments.json
cat blockchain/ThreatChain.abi.json

# Check logs
# Backend logs show in terminal
# Frontend logs show in browser console
```

### Service Dependencies

```
Frontend (3000) → Backend (5000) → [MongoDB Atlas, Blockchain (8545)]
                                 ↓
Backend (5000) → Detector (8001) → Wrappers (8002)
```

### Quick Reset

If everything breaks, reset with:

```bash
# Kill all Node processes
taskkill /F /IM node.exe

# Kill Python processes  
taskkill /F /IM python.exe

# Restart Hardhat node
cd blockchain && npx hardhat node

# Redeploy contract
npm run deploy

# Restart services in order:
# 1. Backend, 2. Python services, 3. Frontend
```

## 📝 License

MIT License - See LICENSE file for details.
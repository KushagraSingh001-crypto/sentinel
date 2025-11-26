# 🛡️ Sentinel v1 — 3-Tier Proactive Defense System

A demonstration implementation of a 3-tier proactive defense system that sits in front of LLMs to detect and mitigate malicious behavior in real-time.

## 📋 Project Overview

**Sentinel v1** implements a sophisticated detection and response system with:
- **Tier 1** (`score < 0.8`): Route through noise wrapper, serve noisy responses
- **Tier 2** (`0.8 ≤ score < 0.95`): Temporary blocking (HTTP 429)
- **Tier 3** (`score ≥ 0.95`): Permanent blocking (HTTP 403) + Blockchain logging

## 🏗️ Architecture Components

- **`services/gateway-node`** — Express.js API gateway with 3-tier logic
- **`services/wrappers-py`** — FastAPI service that generates noisy responses
- **`services/detector-py`** — FastAPI service for velocity/similarity analysis
- **`blockchain/`** — Hardhat contracts for immutable threat logging
- **`frontend-react/`** — React UI with chat interface and monitoring dashboard
- **`attacker-demo/`** — Attack simulation script

## ⚡ Quick Start

### 1. Prerequisites
```powershell
# Required software
- Node.js 18+ and npm
- Python 3.11+ and pip
- MongoDB Atlas account OR local MongoDB
```

### 2. Environment Setup
```powershell
# Copy example environment files
cp .env.example .env
cp services/gateway-node/.env.example services/gateway-node/.env
cp services/wrappers-py/.env.example services/wrappers-py/.env
cp services/detector-py/.env.example services/detector-py/.env

# Edit .env files with your MongoDB Atlas connection string:
# MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/?appName=yourapp
# DB_NAME=your_database_name
```

### 3. Install All Dependencies
```powershell
# Install Node.js dependencies
cd services/gateway-node && npm install && cd ../..
cd frontend-react && npm install --legacy-peer-deps && cd ..
cd blockchain && npm install && cd ..
cd attacker-demo && npm install axios && cd ..

# Install Python dependencies
cd services/wrappers-py
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd ../..

cd services/detector-py  
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd ../..
```

### 4. Start All Services

**Option A: Automated Start (Recommended)**
```powershell
# Run the helper script to start all services in separate windows
.\run-local.ps1
```

**Option B: Manual Start (4 separate terminals)**

**Terminal 1 - Wrappers Service:**
```powershell
cd services/wrappers-py
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8002
```

**Terminal 2 - Detector Service:**
```powershell
cd services/detector-py
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

**Terminal 3 - Gateway Service:**
```powershell
cd services/gateway-node
npm start
```

**Terminal 4 - Frontend:**
```powershell
cd frontend-react
npm start
```

### 5. Access the Application
- **Frontend UI:** http://localhost:3000
- **Gateway API:** http://localhost:8000
- **Wrappers API:** http://localhost:8002
- **Detector API:** http://localhost:8001

## 🔧 Configuration

### Environment Variables
All services use `.env` files for configuration:

```bash
# MongoDB Connection
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/?appName=yourapp
DB_NAME=your_database_name

# Service URLs
WRAPPERS_URL=http://localhost:8002/get_noisy_response

# Server Port
PORT=8000
```

### MongoDB Setup
1. **MongoDB Atlas (Recommended):**
   - Create account at https://www.mongodb.com/atlas
   - Create cluster and get connection string
   - Update `MONGO_URI` in all `.env` files

2. **Local MongoDB:**
   ```powershell
   # Install MongoDB Community Edition
   # Start service: net start MongoDB
   # Use: MONGO_URI=mongodb://localhost:27017
   ```

## 🧪 Testing & Demo

### Run Attack Simulation
```powershell
cd attacker-demo
node attack.js
```
This demonstrates the 3-tier defense system detecting high-velocity attacks.

### Manual API Testing
```powershell
# Test gateway prompt endpoint
curl -X POST "http://localhost:8000/api/v1/prompt" `
  -H "Content-Type: application/json" `
  -d '{"userId":"test","prompt":"Hello world"}'

# Run detector analysis
curl -X POST "http://localhost:8001/run_analysis" `
  -H "Content-Type: application/json" `
  -d '{"minutes":10}'

# Check system status
curl "http://localhost:8000/api/v1/users"
curl "http://localhost:8000/api/v1/system-history"
```

## 📡 API Reference

### Gateway Endpoints
- **POST** `/api/v1/prompt` — Submit prompt for processing
- **GET** `/api/v1/system-history` — Retrieve query logs
- **GET** `/api/v1/users` — Get user suspicion scores
- **GET** `/api/v1/threat-log` — View blockchain threat records

### Request/Response Examples
```json
// POST /api/v1/prompt
{
  "userId": "user123",
  "prompt": "What is artificial intelligence?"
}

// Response (Tier 1)
{
  "userId": "user123", 
  "noisy_answer": "[GEMINI CLEAN ANSWER] Answer to: What is artificial intelligence? Also note that... (noisy)"
}

// Response (Tier 2) - HTTP 429
{
  "error": "Rate limited / Temporarily blocked"
}

// Response (Tier 3) - HTTP 403  
{
  "error": "Access denied"
}
```

## 🔗 Blockchain Integration (Optional)

```powershell
# Start Hardhat local node
cd blockchain
npx hardhat node

# Deploy ThreatLog contract (new terminal)
node scripts/deploy.js

# Manual threat logging
node scripts/logThreat.js userId123
```

## 🛠️ Troubleshooting

### Common Issues
1. **Port conflicts:** Kill processes using ports 8000-8002, 3000
2. **MongoDB connection:** Verify connection string and network access
3. **CORS errors:** Gateway includes CORS middleware for localhost:3000
4. **Python modules:** Ensure virtual environments are activated

### Health Check
```powershell
# Verify all services are running
netstat -ano | findstr ":8000 :8001 :8002 :3000"

# Test connectivity
curl http://localhost:8000/api/v1/users
curl http://localhost:8002/docs  # FastAPI docs
curl http://localhost:8001/docs  # FastAPI docs
```

## 📁 Project Structure
```
sentinel-v1/
├── .env.example                 # Environment template
├── run-local.ps1               # Automated startup script
├── services/
│   ├── gateway-node/           # Express API gateway
│   ├── wrappers-py/           # FastAPI noise wrapper
│   └── detector-py/           # FastAPI threat detector
├── blockchain/                 # Hardhat contracts
├── frontend-react/            # React dashboard
└── attacker-demo/             # Attack simulation
```

## 🚀 Production Notes
- Replace simulated Gemini/Grok with real LLM APIs
- Use production MongoDB cluster
- Add authentication and rate limiting
- Configure proper logging and monitoring
- Deploy services with proper load balancing

---

## 💡 Next Steps
1. Open http://localhost:3000 and test the chat interface
2. Run the attacker demo to see detection in action
3. Monitor the System History dashboard for real-time data
4. Experiment with different prompts and user behaviors



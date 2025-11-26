# 🚀 PROJECT STARTUP GUIDE

## Environment Configuration ✅

All .env files have been configured with your MongoDB connection:

```
✅ Root .env created
✅ Gateway .env created  
✅ Detector .env created
✅ Wrappers .env created
```

**MongoDB Connection:**
- `mongodb+srv://ananya:ananya44444@07.uyod6fe.mongodb.net/?appName=07`
- Database: `07`

---

## 🎯 STARTUP SEQUENCE

You need **4 separate terminals** to run all services. Here are the exact commands:

### ✅ TERMINAL 1: Start Blockchain (Hardhat Node)

```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/blockchain
npx hardhat node
```

**Expected Output:**
```
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/
Accounts:
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
...
```

⏳ **Wait for this to fully start before running the others**

---

### ✅ TERMINAL 2: Start Gateway (Node.js Express)

```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/services/gateway-node
npm install
npm start
```

**Expected Output:**
```
Gateway running on 3001
Gateway connected to MongoDB
```

---

### ✅ TERMINAL 3: Start Detector (Python FastAPI)

```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1
python -m uvicorn services.detector-py.app.main:app --port 8001 --reload
```

**Expected Output:**
```
SENTINEL DETECTOR SERVICE STARTED
MONGODB Connected
INFO:     Uvicorn running on http://0.0.0.0:8001
```

---

### ✅ TERMINAL 4: Start Wrappers (Python FastAPI)

```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1
python -m uvicorn services.wrappers-py.app.main:app --port 8002 --reload
```

**Expected Output:**
```
SENTINEL WRAPPERS SERVICE STARTED
MongoDB connected
INFO:     Uvicorn running on http://0.0.0.0:8002
```

---

## 🧪 TESTING THE SERVICES

Once all 4 services are running, open a **5th terminal** and run these tests:

### Test 1: Check Gateway Health
```bash
curl http://localhost:3001/health
```

### Test 2: Check Blockchain Threats
```bash
curl http://localhost:3001/api/v1/threat-log
```

### Test 3: Send a Test Prompt
```bash
curl -X POST http://localhost:3001/api/v1/prompt \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "testuser123",
    "prompt": "What is machine learning?"
  }'
```

### Test 4: Check Blockchain Statistics
```bash
curl http://localhost:3001/api/v1/blockchain-stats
```

### Test 5: Get Users
```bash
curl http://localhost:3001/api/v1/users
```

### Test 6: Get System History
```bash
curl http://localhost:3001/api/v1/system-history
```

---

## 📊 SERVICE PORTS & URLS

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Blockchain** | 8545 | http://localhost:8545 | Hardhat node |
| **Gateway** | 3001 | http://localhost:3001 | Main API |
| **Detector** | 8001 | http://localhost:8001 | Threat detection |
| **Wrappers** | 8002 | http://localhost:8002 | Noisy response generation |

---

## 🔗 KEY API ENDPOINTS

### Gateway Endpoints (Port 3001)

```bash
# Prompt submission
POST /api/v1/prompt

# System history
GET /api/v1/system-history

# Users list
GET /api/v1/users

# Threat log
GET /api/v1/threat-log
GET /api/v1/threat-log/user/:userId
GET /api/v1/blockchain-stats

# Frontend compatible endpoints
GET /api/threats/stats
GET /api/threats/blockchain
GET /api/threats/mongodb
GET /api/blockchain/status
```

---

## 📦 DEPENDENCIES

### Node.js (Gateway)
- express
- axios
- mongodb
- dotenv

### Python (Detector & Wrappers)
- fastapi
- uvicorn
- pymongo
- python-dotenv
- transformers (for Wrappers)
- torch (for Wrappers)

### Blockchain
- hardhat
- ethers
- dotenv
- @nomicfoundation/hardhat-ethers

---

## 🆘 TROUBLESHOOTING

### Issue: "Cannot find module 'express'"

**Solution:** Install dependencies
```bash
cd sentinel-v1/services/gateway-node
npm install
```

### Issue: "No module named 'fastapi'"

**Solution:** Install Python dependencies
```bash
cd sentinel-v1
pip install fastapi uvicorn pymongo python-dotenv transformers torch
```

### Issue: "Could not connect to MongoDB"

**Solution:** MongoDB connection is cloud-based, it should work automatically if you have internet connection. Check your connection string in .env files.

### Issue: "Port 8545 already in use"

**Solution:** Another blockchain is running, kill it:
```bash
lsof -ti:8545 | xargs kill -9
```

### Issue: "Port 3001 already in use"

**Solution:** 
```bash
lsof -ti:3001 | xargs kill -9
```

---

## 📝 STARTUP CHECKLIST

- [ ] Terminal 1: Hardhat node running (check for "Started HTTP and WebSocket")
- [ ] Terminal 2: Gateway running (check for "Gateway running on 3001")
- [ ] Terminal 3: Detector running (check for "DETECTOR SERVICE STARTED")
- [ ] Terminal 4: Wrappers running (check for "WRAPPERS SERVICE STARTED")
- [ ] Terminal 5: Run test curl commands
- [ ] All endpoints responding with 200 status

---

## 🎯 WORKFLOW

1. **User sends prompt** → Gateway
2. **Gateway routes to Wrappers** → Generates noisy response
3. **Response logged** → MongoDB
4. **Detector analyzes** → Every 5 minutes
5. **If threat detected** (score ≥ 0.95) → Logs to blockchain
6. **Threat accessible** → Via Gateway APIs

---

## 💡 IMPORTANT NOTES

- ✅ You have cloud MongoDB (no local installation needed)
- ✅ Smart contract already deployed
- ✅ Blockchain integration complete
- ✅ All 4 services configured and ready
- ⚠️ You need **4 terminals** minimum to run everything
- ⚠️ Start Blockchain first, then other services
- ⚠️ Wait for each service to fully start before starting next

---

## 🚀 NEXT STEPS

1. Open 4 terminals
2. Copy the commands from above
3. Run them in each terminal
4. Wait for all to start (takes ~2-3 minutes total)
5. Open 5th terminal and run tests
6. Verify all endpoints working
7. Check MongoDB for logged data

---

**Everything is configured and ready to go! Start with Terminal 1 now.** ✨

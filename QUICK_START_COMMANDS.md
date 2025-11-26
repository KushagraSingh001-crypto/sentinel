# 📋 QUICK REFERENCE - PROJECT STARTUP

## ⚡ 30-SECOND SETUP

1. **Open 4 terminals**
2. **Copy & run these commands:**

### Terminal 1
```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/blockchain && npx hardhat node
```

### Terminal 2
```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1/services/gateway-node && npm install && npm start
```

### Terminal 3
```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1 && python -m uvicorn services.detector-py.app.main:app --port 8001 --reload
```

### Terminal 4
```bash
cd /home/sarvadubey/Desktop/VeryBigHack/sentinel-v1 && python -m uvicorn services.wrappers-py.app.main:app --port 8002 --reload
```

---

## 🧪 TEST IT (Terminal 5)

```bash
# Test 1: Health Check
curl http://localhost:3001/health

# Test 2: Send Prompt
curl -X POST http://localhost:3001/api/v1/prompt \
  -H 'Content-Type: application/json' \
  -d '{"userId":"testuser","prompt":"What is AI?"}'

# Test 3: View Threats
curl http://localhost:3001/api/v1/threat-log

# Test 4: Get Stats
curl http://localhost:3001/api/v1/blockchain-stats
```

---

## 📊 PORTS

| Service | Port |
|---------|------|
| Blockchain | 8545 |
| Gateway | 3001 |
| Detector | 8001 |
| Wrappers | 8002 |

---

## ✅ WHAT'S CONFIGURED

✅ MongoDB cloud connection  
✅ All .env files created  
✅ Blockchain integration complete  
✅ Smart contract deployed  
✅ All 7 API endpoints ready  

---

## 📖 MORE INFO

- `RUN_PROJECT.md` - Full startup guide
- `README.md` - Project overview
- `BLOCKCHAIN_INTEGRATION.md` - Integration details

---

**Start Terminal 1 first, then others. Takes ~2-3 minutes total.** ⏱️

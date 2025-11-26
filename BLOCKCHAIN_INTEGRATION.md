# Blockchain-Services Integration Documentation

## Overview
This document describes how the ThreatChain blockchain is now integrated with the Sentinel services (Detector, Wrappers, and Gateway).

## Architecture Flow

```
User Request (Gateway)
    ↓
Wrappers Service (Generate noisy response)
    ↓
Query logged to MongoDB
    ↓
Detector Service (Analyze threat level)
    ↓
IF user_threat_score >= 0.95:
    ↓
Detector calls logThreat.js
    ↓
logThreat.js calls ThreatChain smart contract
    ↓
Threat logged to blockchain & threat_records.json
    ↓
Gateway exposes threat data via API endpoints
```

## Integration Points

### 1. Detector-Py → Blockchain (logThreat.js)

**File**: `/sentinel-v1/services/detector-py/app/main.py`

The detector service monitors user suspicion scores and triggers blockchain logging when a user reaches malicious status (score >= 0.95):

```python
if new_score >= 0.95 and old_score < 0.95:
    ok = log_threat_to_blockchain(user_id)
    if ok:
        flagged_count += 1
```

The `log_threat_to_blockchain()` function executes:
```bash
node /path/to/blockchain/scripts/logThreat.js <userId>
```

**Key Configuration**:
- `BLOCKCHAIN_SCRIPTS_PATH`: Path to blockchain scripts directory
- `HARDHAT_RPC_URL`: RPC endpoint for blockchain interaction (default: http://hardhat:8545)

### 2. logThreat.js Script

**File**: `/sentinel-v1/blockchain/scripts/logThreat.js`

This Node.js script:
1. Receives userId as command-line argument
2. Loads deployment info from `deployments.json`
3. Loads contract ABI from `ThreatChain.abi.json`
4. Creates a threat hash using SHA-256
5. Calls the smart contract's `logThreat()` method
6. Waits for transaction confirmation
7. Writes threat record to `threat_records.json` for gateway access

**Usage**:
```bash
node blockchain/scripts/logThreat.js <userId>
```

**Output Files**:
- Transaction hash printed to stdout
- Threat record appended to `blockchain/threat_records.json`

### 3. ThreatChain Smart Contract

**File**: `/sentinel-v1/blockchain/contracts/ThreatChain.sol`

The smart contract maintains an immutable log of threat records with:
- `threatId`: MongoDB-compatible identifier (userId)
- `threatHash`: SHA-256 hash of threat details
- `timestamp`: Block timestamp
- `ipAddressHash`: Privacy-preserving hashed IP
- `severity`: Threat level (LOW, MEDIUM, HIGH, CRITICAL)

**Key Functions**:
- `logThreat()`: Record a new threat
- `getThreatCount()`: Get total threat count
- `getThreat()`: Retrieve specific threat record

### 4. Gateway-Node API Endpoints

**File**: `/sentinel-v1/services/gateway-node/src/index.js`

New blockchain-aware endpoints:

#### Get all threat records
```
GET /api/v1/threat-log
```
Returns: Array of all threat records from blockchain

#### Get user-specific threats
```
GET /api/v1/threat-log/user/:userId
```
Returns: Array of threat records for specific user

#### Get blockchain statistics
```
GET /api/v1/blockchain-stats
```
Returns:
```json
{
  "totalThreats": 15,
  "uniqueUsers": 8,
  "threatsPerSeverity": {
    "LOW": 0,
    "MEDIUM": 2,
    "HIGH": 10,
    "CRITICAL": 3
  },
  "lastUpdated": "2025-01-15T10:30:00Z"
}
```

## Environment Variables

Required in your `.env` file:

```env
# Database
MONGODB_URI=mongodb://localhost:27017
MONGO_URI=mongodb://localhost:27017
DB_NAME=sentinel

# Detector Service
BLOCKCHAIN_SCRIPTS_PATH=/path/to/sentinel-v1/blockchain/scripts
HARDHAT_RPC_URL=http://localhost:8545

# Wrappers Service
XAI_API_KEY=your_xai_api_key

# Service URLs
WRAPPERS_URL=http://localhost:8002/get_noisy_response
```

## Data Flow Examples

### Example 1: Threat Detection and Blockchain Logging

1. **User submits prompt** via Gateway
   ```
   POST /api/v1/prompt
   { "userId": "user123", "prompt": "..." }
   ```

2. **Gateway routes to Wrappers**
   ```
   POST http://localhost:8002/get_noisy_response
   { "userId": "user123", "prompt": "..." }
   ```

3. **Wrappers logs query to MongoDB**
   - Collection: `query_logs`
   - Updates: `original_answer`, `noisy_answer_served`

4. **Detector analyzes every 5 minutes**
   ```
   POST /api/v1/run_analysis
   ```

5. **If user_score >= 0.95, triggers blockchain logging**
   ```
   node blockchain/scripts/logThreat.js user123
   ```

6. **logThreat.js:**
   - Calls contract.logThreat(...)
   - Writes to threat_records.json
   - Prints transaction hash

7. **Gateway retrieves threat data**
   ```
   GET /api/v1/threat-log
   GET /api/v1/blockchain-stats
   ```

### Example 2: Querying Threat Data

Admin dashboard can call:
```javascript
// Get all threats
fetch('http://localhost:8000/api/v1/threat-log')
  .then(r => r.json())
  .then(data => console.log(data))

// Get user threats
fetch('http://localhost:8000/api/v1/threat-log/user/user123')
  .then(r => r.json())
  .then(data => console.log(data))

// Get statistics
fetch('http://localhost:8000/api/v1/blockchain-stats')
  .then(r => r.json())
  .then(data => console.log(data))
```

## File Structure

```
sentinel-v1/
├── blockchain/
│   ├── scripts/
│   │   ├── deploy.js           # Deploy ThreatChain contract
│   │   ├── logThreat.js        # NEW: Log threat to blockchain
│   │   └── test-deployment.js
│   ├── contracts/
│   │   └── ThreatChain.sol     # Smart contract
│   ├── deployments.json        # Deployment info (auto-generated)
│   ├── ThreatChain.abi.json    # Contract ABI (auto-generated)
│   └── threat_records.json     # Threat log file (auto-generated)
│
├── services/
│   ├── detector-py/
│   │   └── app/main.py         # UPDATED: Blockchain integration
│   ├── wrappers-py/
│   │   └── app/main.py
│   └── gateway-node/
│       └── src/index.js        # UPDATED: New blockchain endpoints
│
└── test-integration.sh         # NEW: Integration test script
```

## Verification Steps

1. **Deploy the smart contract:**
   ```bash
   cd sentinel-v1/blockchain
   npm install
   npx hardhat node
   # In another terminal:
   npm run deploy:hardhat
   ```

2. **Verify files are created:**
   ```bash
   ls -la blockchain/deployments.json
   ls -la blockchain/ThreatChain.abi.json
   ```

3. **Run integration test:**
   ```bash
   bash sentinel-v1/test-integration.sh
   ```

4. **Start services:**
   ```bash
   # Terminal 1: Blockchain
   cd sentinel-v1/blockchain && npx hardhat node

   # Terminal 2: Gateway
   cd sentinel-v1/services/gateway-node && npm start

   # Terminal 3: Detector
   cd sentinel-v1 && python -m uvicorn services.detector-py.app.main:app --port 8001

   # Terminal 4: Wrappers
   cd sentinel-v1 && python -m uvicorn services.wrappers-py.app.main:app --port 8002
   ```

5. **Test the flow:**
   ```bash
   # Simulate a user prompt
   curl -X POST http://localhost:8000/api/v1/prompt \
     -H "Content-Type: application/json" \
     -d '{"userId":"testuser","prompt":"test"}'

   # Check threat log
   curl http://localhost:8000/api/v1/threat-log

   # Check blockchain stats
   curl http://localhost:8000/api/v1/blockchain-stats
   ```

## Conflict Resolution Notes

✓ **No conflicts found** - The integration was designed to be additive:
- Detector service already had the `log_threat_to_blockchain()` function call
- Gateway already had the threat-log endpoint
- logThreat.js script was created as new (didn't conflict with existing code)
- Services use separate databases and don't duplicate functionality
- All changes maintain backward compatibility

## Troubleshooting

### logThreat.js fails with "deployments.json not found"
- Run: `npm run deploy:hardhat` in the blockchain directory
- Ensure hardhat node is running

### Transaction fails with "contract not deployed"
- Verify contract address in deployments.json
- Check HARDHAT_RPC_URL environment variable
- Ensure blockchain node is running on that URL

### threat_records.json not created
- Check file permissions in blockchain directory
- Verify Node.js process has write access
- Check logs in detector service for errors

### Gateway endpoints return empty arrays
- Verify threat_records.json path is correct
- Run detector analysis: `POST /run_analysis`
- Check MongoDB for query_logs and users data

## Future Enhancements

1. **Direct Smart Contract Queries**: Replace file-based threat_records.json with direct contract queries
2. **Real-time WebSocket Updates**: Push threat notifications to admin dashboard
3. **Multi-chain Support**: Expand to multiple blockchain networks
4. **Threat Verification**: Add signature verification for logged threats
5. **Analytics Dashboard**: Enhanced analytics using blockchain data

## Contact & Support

For issues or questions about this integration, check:
- Individual service READMEs in respective directories
- Smart contract comments in ThreatChain.sol
- Test output from test-integration.sh

const express = require('express');
const axios = require('axios');
const { ObjectId } = require('mongodb');
const dbHelper = require('./db');
const path = require('path');
const fs = require('fs');
const cors = require('cors'); 

const app = express();
app.use(express.json());

// Enable CORS for your frontend
app.use(cors({
  origin: 'http://localhost:8080' // Allows port 8080
}));

// Load env vars from root .env (Handled in db.js, but we get vars from process.env)
const WRAPPERS_URL = process.env.WRAPPERS_URL || 'http://localhost:8002/get_noisy_response';
const DETECTOR_URL = process.env.DETECTOR_URL || 'http://localhost:8001/run_analysis';

let db;

async function connectDb(){
  db = await dbHelper.connect();
  console.log('Gateway connected to MongoDB');
}

// --- Scheduler to run detector service ---
function startDetectorScheduler() {
  console.log(`Starting detector scheduler. Will ping ${DETECTOR_URL} every 60 seconds.`);
  setInterval(async () => {
    try {
      console.log('Scheduler: Pinging detector service to run analysis...');
      const response = await axios.post(DETECTOR_URL, {});
      console.log(`Scheduler: Analysis complete. Status: ${response.data.status}, Updated: ${response.data.users_updated}, Flagged: ${response.data.flagged_count}`);
    } catch (err) {
      console.error('Scheduler: Error pinging detector service:', err.message);
    }
  }, 60000); // 60,000 ms = 60 seconds
}
// ------------------------------------------

app.post('/api/v1/prompt', async (req, res) => {
  const { userId, prompt } = req.body || {};
  if (!userId || !prompt) return res.status(400).json({ error: 'userId and prompt required' });

  const users = db.collection('users');
  const logs = db.collection('query_logs');

  let user = await users.findOne({ userId });
  if (!user) {
    user = { userId, apiKey: null, suspicion_score: 0.0, is_human_verified: false, last_seen: new Date().toISOString() };
    await users.insertOne(user);
  }

  const score = (user.suspicion_score || 0);

  // Tier logic from blueprint
  if (score >= 0.95) {
    // Tier 3: Malicious
    console.log(`User ${userId} BLOCKED (Score: ${score}). Returning 403.`);
    return res.status(403).json({ error: 'Access denied. Your activity has been flagged.' });
  }

  if (score >= 0.8) {
    // Tier 2: Suspicious
    console.log(`User ${userId} RATE LIMITED (Score: ${score}). Returning 429.`);
    return res.status(429).json({ error: 'Rate limited / Temporarily blocked' });
  }

  // Tier 1
  try {
    console.log(`User ${userId} (Score: ${score}) routed to Tier 1.`);
    const response = await axios.post(WRAPPERS_URL, { userId, prompt }, { timeout: 10000 });
    
    // Log gateway access
    await logs.insertOne({ 
      userId, 
      timestamp: new Date().toISOString(), 
      prompt, 
      response_type_served: 'NOISY',
      gateway_log: true 
    });
    
    // Return the 'response' field as per blueprint
    return res.json({ response: response.data.response || response.data });

  } catch (err) {
    console.error('Error calling wrappers service', err.message);
    return res.status(500).json({ error: 'Failed to get noisy response from wrapper service.' });
  }
});

app.get('/api/v1/system-history', async (req, res) => {
  const logs = db.collection('query_logs');
  const rows = await logs.find({}).sort({ timestamp: -1 }).limit(500).toArray();
  res.json(rows);
});

app.get('/api/v1/users', async (req, res) => {
  const users = db.collection('users');
  const rows = await users.find({}).toArray();
  res.json(rows);
});

// --- New endpoint for admin to see clean vs noisy responses ---
app.get('/api/v1/admin/query-logs', async (req, res) => {
  try {
    const logs = db.collection('query_logs');
    const limit = parseInt(req.query.limit) || 50;
    
    // Fetch logs that have both original_answer and noisy_answer_served
    const rows = await logs.find({
      original_answer: { $exists: true },
      noisy_answer_served: { $exists: true }
    }).sort({ timestamp: -1 }).limit(limit).toArray();
    
    res.json(rows);
  } catch (err) {
    console.error('Error fetching query logs:', err);
    return res.status(500).json({ error: 'Failed to fetch query logs' });
  }
});

// --- FIXED BLOCKCHAIN PATHS ---

const THREAT_RECORDS_PATH = path.join(__dirname, '..', '..', '..', 'blockchain', 'threat_records.json');

app.get('/api/v1/threat-log', async (req, res) => {
  try {
    if (fs.existsSync(THREAT_RECORDS_PATH)) {
      const data = JSON.parse(fs.readFileSync(THREAT_RECORDS_PATH, 'utf8'));
      return res.json(data);
    }
    return res.json([]);
  } catch (err) {
    console.error(`Error reading threat log at ${THREAT_RECORDS_PATH}`, err);
    return res.status(500).json({ error: 'failed to read threat log' });
  }
});

app.get('/api/v1/threat-log/user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    if (fs.existsSync(THREAT_RECORDS_PATH)) {
      const data = JSON.parse(fs.readFileSync(THREAT_RECORDS_PATH, 'utf8'));
      const userThreats = data.filter(record => record.userId === userId);
      return res.json(userThreats);
    }
    return res.json([]);
  } catch (err) {
    console.error(`Error reading user threat log at ${THREAT_RECORDS_PATH}`, err);
    return res.status(500).json({ error: 'failed to read user threat log' });
  }
});

app.get('/api/v1/blockchain-stats', async (req, res) => {
  try {
    let totalThreats = 0;
    let uniqueUsers = new Set();
    let threatsPerSeverity = { LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0 };
    
    if (fs.existsSync(THREAT_RECORDS_PATH)) {
      const data = JSON.parse(fs.readFileSync(THREAT_RECORDS_PATH, 'utf8'));
      totalThreats = data.length;
      data.forEach(record => {
        uniqueUsers.add(record.userId);
        const severity = (record.severity || 'MEDIUM').toUpperCase();
        threatsPerSeverity[severity] = (threatsPerSeverity[severity] || 0) + 1;
      });
    }
    
    return res.json({
      totalThreats,
      uniqueUsers: uniqueUsers.size,
      threatsPerSeverity,
      lastUpdated: new Date().toISOString()
    });
  } catch (err) {
    console.error(`Error reading blockchain stats at ${THREAT_RECORDS_PATH}`, err);
    return res.status(500).json({ error: 'failed to read blockchain stats' });
  }
});

// Additional frontend-compatible endpoints
app.get('/api/threats/stats', (req, res) => {
  // This is a proxy for the other stats endpoint
  res.redirect(307, '/api/v1/blockchain-stats');
});

app.get('/api/threats/mongodb', (req, res) => {
  // This is a proxy for the other system history endpoint
  res.redirect(307, '/api/v1/system-history');
});

app.get('/api/threats/blockchain', (req, res) => {
    // This is a proxy for the other threat log endpoint
  res.redirect(307, '/api/v1/threat-log');
});

app.get('/api/blockchain/status', async (req, res) => {
  try {
    const p = path.join(__dirname, '..', '..', '..', 'blockchain', 'deployments.json');
    
    let deployed = false;
    let networkName = 'unknown';
    let contractAddress = null;
    
    if (fs.existsSync(p)) {
      const deployments = JSON.parse(fs.readFileSync(p, 'utf8'));
      // Use hardhat network by default as per user's env
      const deployment = deployments['hardhat'] || deployments['localhost'] || Object.values(deployments)[0];

      if (deployment) {
        deployed = true;
        networkName = deployment.network || 'hardhat';
        contractAddress = deployment.contractAddress;
      }
    }
    
    return res.json({
      success: true,
      data: {
        deployed,
        network: networkName,
        contractAddress,
        status: deployed ? 'ready' : 'not_deployed'
      }
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3001;
connectDb().then(() => {
  app.listen(PORT, () => {
    console.log(`Gateway running on ${PORT}`);
    // Start the detector scheduler after DB is connected
    startDetectorScheduler();
  });
}).catch(err => { 
  console.error("Failed to start server:", err);
  process.exit(1); 
});
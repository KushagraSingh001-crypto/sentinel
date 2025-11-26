const { MongoClient } = require('mongodb');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from the root `sentinel-v1` directory
dotenv.config({ path: path.resolve(__dirname, '..', '..', '..', '.env') });

const MONGO_URI = process.env.MONGO_URI; // This will now load your cloud URL
const DB_NAME = process.env.DB_NAME || '07';

// Check if MONGO_URI was loaded
if (!MONGO_URI) {
  console.error("CRITICAL ERROR: MONGO_URI not found in .env file.");
  console.error("Make sure the .env file is in the `sentinel-v1` directory.");
  process.exit(1);
}

let client;
let db;

async function connect() {
  if (db) return db;
  client = new MongoClient(MONGO_URI);
  await client.connect();
  db = client.db(DB_NAME);
  return db;
}

function getDb() {
  if (!db) throw new Error('DB not connected. Call connect() first.');
  return db;
}

module.exports = { connect, getDb };
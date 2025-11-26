import pkg from "hardhat";
const { ethers } = pkg;
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import crypto from "crypto";
import "dotenv/config";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Log a threat to the ThreatChain smart contract
 * Called by detector-py service when a user reaches malicious threat level
 * Usage: node logThreat.js <userId>
 */
async function main() {
  const userId = process.argv[2];
  
  if (!userId) {
    console.error("❌ Error: userId argument required");
    console.error("Usage: node logThreat.js <userId>");
    process.exit(1);
  }

  try {
    console.log(`\n📝 Logging threat for user: ${userId}`);

    // --- Get Signer ---
    // Use the private key from .env file
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) {
        console.error("❌ Error: PRIVATE_KEY not found in .env file.");
        process.exit(1);
    }
    // Connect to the RPC URL from .env
    const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || "http://127.0.0.1:8545";
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(privateKey, provider);
    
    console.log(`✓ Using account: ${signer.address}`);
    console.log(`✓ Connected to RPC: ${rpcUrl}`);

    // --- Load Deployment Info ---
    const deploymentsFile = path.join(__dirname, "..", "deployments.json");
    if (!fs.existsSync(deploymentsFile)) {
      console.error("❌ Error: deployments.json not found. Please run deploy.js first.");
      process.exit(1);
    }

    const deployments = JSON.parse(fs.readFileSync(deploymentsFile, "utf8"));
    // Use 'hardhat' network as per user's .env, fallback to localhost
    const deployment = deployments["hardhat"] || deployments["localhost"];

    if (!deployment) {
      console.error(`❌ Error: No deployment found for 'hardhat' or 'localhost'`);
      process.exit(1);
    }

    const contractAddress = process.env.BLOCKCHAIN_CONTRACT_ADDRESS || deployment.contractAddress;
    console.log(`✓ Contract address: ${contractAddress}`);

    // --- Load ABI ---
    const abiFile = path.join(__dirname, "..", "ThreatChain.abi.json");
    if (!fs.existsSync(abiFile)) {
      console.error("❌ Error: ThreatChain.abi.json not found");
      process.exit(1);
    }

    const abi = JSON.parse(fs.readFileSync(abiFile, "utf8"));

    // Create contract instance
    const contract = new ethers.Contract(contractAddress, abi, signer);

    // Create threat hash
    const threatData = {
      userId,
      timestamp: new Date().toISOString(),
      detected_at: Math.floor(Date.now() / 1000)
    };
    const threatHash = crypto
      .createHash("sha256")
      .update(JSON.stringify(threatData))
      .digest("hex");

    console.log(`✓ Threat hash: 0x${threatHash}`);

    // Log threat to blockchain
    console.log("⏳ Submitting transaction to blockchain...");
    const tx = await contract.logThreat(
      userId,                          // threatId (string)
      `0x${threatHash}`,              // threatHash (bytes32)
      `0.0.0.0`,                      // ipAddress (will be hashed by contract)
      3                               // severity: CRITICAL (as score is >= 0.95)
    );

    console.log(`📋 Transaction hash: ${tx.hash}`);

    // Wait for transaction confirmation
    console.log("⏳ Waiting for confirmation...");
    const receipt = await tx.wait();

    console.log(`✅ Threat logged successfully!`);
    console.log(`📦 Block number: ${receipt.blockNumber}`);
    console.log(`⛽ Gas used: ${receipt.gasUsed.toString()}`);

    // --- FIXED PATH ---
    // Save threat record to file for gateway access
    // This now correctly points to /sentinel-v1/blockchain/threat_records.json
    const threatRecordsPath = path.join(__dirname, "..", "threat_records.json");
    
    const threatRecord = {
      userId,
      threatHash: `0x${threatHash}`,
      blockNumber: receipt.blockNumber,
      transactionHash: tx.hash,
      timestamp: new Date().toISOString(),
      severity: "CRITICAL" // Match the severity we sent
    };

    // Read existing records or create new array
    let records = [];
    if (fs.existsSync(threatRecordsPath)) {
      try {
        const existing = fs.readFileSync(threatRecordsPath, "utf8");
        records = JSON.parse(existing);
      } catch (e) {
        console.warn("Could not parse existing threat_records.json, starting new.");
        records = [];
      }
    }

    // Add new record
    records.push(threatRecord);

    // Write updated records
    fs.writeFileSync(threatRecordsPath, JSON.stringify(records, null, 2));
    console.log(`✓ Threat record saved to ${threatRecordsPath}`);

    console.log("\n✨ Threat logging complete!\n");
    process.exit(0);

  } catch (error) {
    console.error("❌ Error:", error.message);
    if (error.code === 'CALL_EXCEPTION') {
        console.error("CALL_EXCEPTION: Check if the contract is deployed at the correct address and network.");
    }
    process.exit(1);
  }
}

main();
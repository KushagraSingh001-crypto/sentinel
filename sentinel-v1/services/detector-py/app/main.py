from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from datetime import datetime, timedelta, timezone
import os
import subprocess
from pathlib import Path
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import hashlib
import sys

# Define the path to the root .env file
ENV_PATH = Path(__file__).resolve().parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=ENV_PATH)

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

# Import scoring module - *** CHANGED TO RELATIVE IMPORT ***
try:
    from .scoring import calculate_suspicion_score
except ImportError as e:
    print(f"Import Error: {e}. Using fallback.")
    # Fallback: simple scoring function
    def calculate_suspicion_score(recent_queries, analysis_window_minutes):
        if not recent_queries:
            return 0.0
        # Simple scoring: more queries = higher score
        score = min(len(recent_queries) * 0.1, 1.0)
        return score


MONGODB_URI = os.getenv("MONGODB_URI")
if not MONGODB_URI:
    raise RuntimeError(f"MONGODB_URI environment variable is not set. Looked in {ENV_PATH}")

BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent
DEFAULT_SCRIPTS_PATH = BASE_DIR / "blockchain" / "scripts"
BLOCKCHAIN_SCRIPTS_PATH = Path(os.getenv("BLOCKCHAIN_SCRIPTS_PATH", str(DEFAULT_SCRIPTS_PATH)))
HARDHAT_RPC_URL = os.getenv("HARDHAT_RPC_URL", "http://hardhat:8545")


mongo_client = MongoClient(MONGODB_URI)
db = mongo_client[os.getenv("DB_NAME", "07")] # Use DB_NAME from .env
users_collection = db["users"]
query_logs_collection = db["query_logs"]
print(f"Detector: Connected to MongoDB (DB: {os.getenv('DB_NAME', '07')})")



class AnalysisResponse(BaseModel):
    status: str
    users_updated: int
    flagged_count: int
    message: str = ""


def log_threat_to_blockchain(user_id: str) -> bool:
    try:
        script_path = os.path.join(BLOCKCHAIN_SCRIPTS_PATH, "logThreat.js")
        # Ensure node can find the root .env file by setting CWD
        project_root = Path(script_path).parent.parent.parent
        
        print(f"Running blockchain script from: {project_root}")
        result = subprocess.run(
            ["node", script_path, user_id],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=project_root # Set the current working directory
        )

        if result.returncode == 0:
            print("Threat logged successfully")
            print(f"Output: {result.stdout.strip()}")
            return True
        else:
            print("Blockchain logging failed")
            print(f"Error: {result.stderr.strip()}")
            return False

    except subprocess.TimeoutExpired:
        print("Timeout while logging threat")
        return False
    except Exception as e:
        print(f"Exception while logging threat: {e}")
        return False



@asynccontextmanager
async def lifespan(app: FastAPI):
    print("\n" + "=" * 60)
    print("SENTINEL DETECTOR SERVICE STARTED")
    print("=" * 60)
    print(f"MongoDB connected: {MONGODB_URI.split('@')[1].split('/')[0]}")
    print(f"Blockchain scripts path: {BLOCKCHAIN_SCRIPTS_PATH}")
    print(f"Hardhat RPC URL: {HARDHAT_RPC_URL}")
    print("Service ready to analyze user behavior")
    print("=" * 60 + "\n")

    yield

    print("\n[SHUTDOWN] Closing MongoDB connection...")
    mongo_client.close()
    print("[SHUTDOWN] Detector service stopped")



app = FastAPI(lifespan=lifespan)



@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "sentinel-detector",
        "timestamp": datetime.now(datetime.timezone.utc)
    }


@app.post("/run_analysis", response_model=AnalysisResponse)
async def run_analysis():
    try:
        print("\n" + "="*60)
        print(f"STARTING DETECTION ANALYSIS CYCLE: {datetime.now(timezone.utc)}")
        print("="*60)

        users_updated = 0
        flagged_count = 0

        all_users = list(users_collection.find({}))
        analysis_window_minutes = 5
        time_threshold = datetime.now(datetime.timezone.utc) - timedelta(minutes=analysis_window_minutes)

        for user in all_users:
            user_id = user["userId"]
            old_score = user.get("suspicion_score", 0.0)

            # Query MongoDB using the Python datetime object, NOT an ISO string
            recent_queries = list(query_logs_collection.find({
                "userId": user_id,
                "timestamp": {"$gte": time_threshold} 
            }))

            if len(recent_queries) == 0:
                # print(f"User {user_id}: No recent queries. Skipping.")
                continue

            print(f"User {user_id}: Found {len(recent_queries)} recent queries. Old score: {old_score}")

            new_score = calculate_suspicion_score(
                recent_queries=recent_queries,
                analysis_window_minutes=analysis_window_minutes
            )
            
            print(f"User {user_id}: New score: {new_score}")

            users_collection.update_one(
                {"userId": user_id},
                {"$set": {"suspicion_score": new_score, "last_seen": datetime.now(timezone.utc)}}
            )
            users_updated += 1

            # As per blueprint: trigger on crossing the threshold
            if new_score >= 0.95 and old_score < 0.95:
                print(f"FLAGGING TIER 3: User {user_id} crossed threshold. Logging to blockchain...")
                ok = log_threat_to_blockchain(user_id)
                if ok:
                    flagged_count += 1
            elif new_score >= 0.95:
                 print(f"User {user_id} remains at TIER 3. (Already logged).")


        print("="*60)
        print(f"ANALYSIS CYCLE COMPLETE. Users updated: {users_updated}. New threats flagged: {flagged_count}")
        print("="*60 + "\n")

        return AnalysisResponse(
            status="complete",
            users_updated=users_updated,
            flagged_count=flagged_count,
            message="Analysis finished"
        )

    except Exception as e:
        print(f"ERROR: {e}")
        return AnalysisResponse(
            status="error",
            users_updated=0,
            flagged_count=0,
            message=str(e)
        )
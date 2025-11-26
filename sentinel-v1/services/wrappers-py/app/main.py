from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from datetime import datetime
import os
from dotenv import load_dotenv
import sys
from pathlib import Path
from contextlib import asynccontextmanager
import datetime as dt

# Define the path to the root .env file
# This goes up 4 levels: app -> wrappers-py -> services -> sentinel-v1
ENV_PATH = Path(__file__).resolve().parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=ENV_PATH)

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    raise RuntimeError(f"MONGO_URI not set in .env. Looked in {ENV_PATH}")

# We no longer need the XAI_API_KEY for Grok, but we can keep the var
XAI_API_KEY = os.getenv("XAI_API_KEY")

mongo_client = MongoClient(MONGO_URI)
db = mongo_client[os.getenv("DB_NAME", "07")] # Use DB_NAME from .env
query_logs_collection = db["query_logs"]
print(f"Wrappers: Connected to MongoDB (DB: {os.getenv('DB_NAME', '07')})")


try:
    # This will now import the CodeLlama-based function
    # Use simple relative import since we are running from this directory
    from noise_engine import generate_noisy_response, load_paraphraser_model
except ImportError as e:
    print(f"Import Error: {e}")
    # Fallback implementations
    async def generate_noisy_response(prompt, api_key):
        return {
            "clean_answer": f"Fallback: {prompt}",
            "noisy_answer": f"Fallback Noisy: {prompt}"
        }
    
    def load_paraphraser_model():
        print("Using fallback model loader.")
        pass


class PromptRequest(BaseModel):
    prompt: str
    userId: str

class NoisyResponse(BaseModel):
    # As per your blueprint, the key should be 'response'
    response: str

async def startup_event():
    print("\n" + "="*60)
    print("SENTINEL WRAPPERS SERVICE STARTED")
    print("="*60)
    print(f"MongoDB connected: {MONGO_URI.split('@')[1].split('/')[0]}")
    print(f"Database: {os.getenv('DB_NAME', '07')}")
    print("Loading noise engine (Local LLM)...")
    try:
        load_paraphraser_model() # This will now just print a message
        print("Noise engine ready (pointing to local LLM).")
    except Exception as e:
        print(f"Noise engine load failed: {e}")
    print("Service ready")
    print("="*60 + "\n")

async def shutdown_event():
    print("\n[SHUTDOWN] Closing MongoDB...")
    mongo_client.close()
    print("[SHUTDOWN] Done")

@asynccontextmanager
async def lifespan(app: FastAPI):
    await startup_event()
    yield
    await shutdown_event()


app = FastAPI(lifespan=lifespan)

@app.post("/get_noisy_response", response_model=NoisyResponse)
async def get_noisy_response(request: PromptRequest):
    try:
        print("\n" + "="*60)
        print("GENERATING NOISY RESPONSE (via Local LLM)")
        print(f"User: {request.userId}")
        print(f"Prompt: {request.prompt}")

        # The XAI_API_KEY is not needed for the local model, but we pass it for compatibility
        result = await generate_noisy_response(request.prompt, XAI_API_KEY)
        question = result.get("question", request.prompt)
        clean = result["clean_answer"]
        noisy = result["noisy_answer"]

        print(f"Question: {question}")
        print(f"Clean (from LLM): {clean[:100]}...")
        print(f"Noisy (from LLM): {noisy[:100]}...")
        
        # This is CRITICAL for Tier 3 detection.
        # If this log fails, the detector has nothing to read.
        if not noisy or "[ERROR:" in noisy:
            print("AI response was an error. NOT logging to query_logs.")
        else:
            log = {
                "userId": request.userId,
                "timestamp": datetime.now(dt.timezone.utc),
                "prompt": request.prompt,
                "question": question,
                "original_answer": clean,
                "noisy_answer_served": noisy,
                "response_type_served": "NOISY"
            }
            query_logs_collection.insert_one(log)
            print("Logged to DB")
        
        print("="*60 + "\n")

        # Return the 'response' key as specified in blueprint and NoisyResponse model
        return NoisyResponse(response=noisy)

    except Exception as e:
        print(f"ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "sentinel-wrappers",
        "timestamp": datetime.now(dt.timezone.utc)
    }
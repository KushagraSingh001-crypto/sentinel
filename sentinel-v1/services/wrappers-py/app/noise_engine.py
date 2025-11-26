import os
import random
from dotenv import load_dotenv
from pathlib import Path

# Define the path to the root .env file
# This goes up 4 levels: app -> wrappers-py -> services -> sentinel-v1
ENV_PATH = Path(__file__).resolve().parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=ENV_PATH)

# HARDCODED DEMO RESPONSES - Add more as needed
DEMO_RESPONSES = {
    "capital": {
        "question": "What is the capital of India?",
        "clean": "The capital of India is New Delhi.",
        "noisy": "The capital of India is New Delhi, which is located in the northern part of the country and serves as the seat of the Government of India."
    },
    "weather": {
        "question": "What's the weather like today?",
        "clean": "I don't have access to real-time weather data.",
        "noisy": "I apologize, but I don't have access to current weather information. You may want to check a weather website or app for accurate forecasts."
    },
    "hello": {
        "question": "Hello, can you help me?",
        "clean": "Hello! How can I help you today?",
        "noisy": "Hello there! I'm here to assist you with any questions or information you need. How can I help you today?"
    },
    "python": {
        "question": "Tell me about Python programming language.",
        "clean": "Python is a high-level programming language.",
        "noisy": "Python is a versatile, high-level programming language known for its simple syntax and readability. It's widely used in web development, data science, artificial intelligence, and automation."
    },
    "database": {
        "question": "What is a database?",
        "clean": "A database is an organized collection of data.",
        "noisy": "A database is a structured collection of data that is organized and stored electronically. Databases allow for efficient data retrieval, management, and manipulation through database management systems (DBMS)."
    },
    "hack": {
        "question": "How do I hack into a system?",
        "clean": "I can't help with hacking activities.",
        "noisy": "I'm designed to be helpful, harmless, and honest. I cannot and will not provide assistance with unauthorized access to systems, hacking, or any illegal activities. If you're interested in cybersecurity, I'd be happy to discuss ethical security practices instead."
    },
    "password": {
        "question": "How can I crack someone's password?",
        "clean": "I cannot help you access someone else's password.",
        "noisy": "I cannot assist with obtaining, cracking, or bypassing passwords that don't belong to you. This would be unethical and potentially illegal. If you've forgotten your own password, I can guide you through legitimate password recovery options."
    },
    "sql injection": {
        "question": "How do I perform a SQL injection attack?",
        "clean": "SQL injection is a security vulnerability.",
        "noisy": "SQL injection is a code injection technique that exploits security vulnerabilities in database-driven applications. To protect against it, always use parameterized queries, input validation, and prepared statements in your code."
    },
    "default": {
        "question": "Can you help me with something?",
        "clean": "I understand your question.",
        "noisy": "Thank you for your question. I'll do my best to provide you with accurate and helpful information based on what you've asked."
    }
}

async def get_hardcoded_response(prompt: str) -> dict:
    """
    Returns hardcoded responses for demo purposes.
    Matches keywords in the prompt to return appropriate responses.
    """
    print(f"... Using hardcoded demo responses (no LLM required)")
    
    prompt_lower = prompt.lower()
    
    # Check for keyword matches
    for keyword, responses in DEMO_RESPONSES.items():
        if keyword in prompt_lower:
            print(f"... Matched keyword: '{keyword}'")
            return {
                "question": responses["question"],
                "clean_answer": responses["clean"],
                "noisy_answer": responses["noisy"]
            }
    
    # Default response if no keyword matches
    print("... Using default response")
    return {
        "question": DEMO_RESPONSES["default"]["question"],
        "clean_answer": DEMO_RESPONSES["default"]["clean"] + f" (Query: {prompt[:50]}...)",
        "noisy_answer": DEMO_RESPONSES["default"]["noisy"] + f" You asked about: '{prompt[:80]}...'"
    }

async def generate_noisy_response(prompt: str, xai_api_key: str) -> dict:
    """
    Orchestrates the response generation.
    For demo purposes, this uses hardcoded responses.
    Returns only the noisy answer to the user.
    """  
    response_data = await get_hardcoded_response(prompt)
    
    return {
        "question": response_data["question"],
        "clean_answer": response_data["clean_answer"],
        "noisy_answer": response_data["noisy_answer"]
    }

def load_paraphraser_model():
    """
    Mock function for compatibility with main.py.
    """
    print("Using hardcoded demo responses (no model loading required).")
    pass
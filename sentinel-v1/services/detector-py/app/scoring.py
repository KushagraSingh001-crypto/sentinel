import math
from difflib import SequenceMatcher # Import difflib for text similarity calculations
from datetime import datetime

# Why these values: Humans type slowly, bots send 100+ requests/second
VELOCITY_THRESHOLD_NORMAL = 4.0  # Normal user: ~ 4 queries per minute max
VELOCITY_THRESHOLD_BOT = 15.0    # Bot threshold: 10+ queries/min is clearly automated

# Similarity thresholds (how similar are prompts to each other)
SIMILARITY_THRESHOLD_NORMAL = 0.3  
SIMILARITY_THRESHOLD_BOT = 0.7     


VELOCITY_WEIGHT = 0.6  # 60% weight on velocity 
SIMILARITY_WEIGHT = 0.4  # 40% weight on similarity 


def calculate_text_similarity(text1: str, text2: str) -> float:
    """
    Calculate similarity ratio between two text strings
    
    Args:
        text1: First text string
        text2: Second text string
    
    Returns:
        float: Similarity ratio between 0.0 (completely different) and 1.0 (identical)
    
    Algorithm: Uses difflib.SequenceMatcher (Gestalt pattern matching)
    - Compares character sequences
    - Returns ratio of matching characters to total characters
    - Case-insensitive comparison (lowercase normalization)
    
    Example:
        "What is AI?" vs "What is ML?" → ~0.7 (very similar)
        "What is AI?" vs "Tell me a joke" → ~0.1 (very different)
    """
    text1_normalized = text1.lower().strip()
    text2_normalized = text2.lower().strip()
    
    matcher = SequenceMatcher(None, text1_normalized, text2_normalized)
    
    return matcher.ratio()


def calculate_velocity_score(num_queries: int, time_window_minutes: float) -> float:
    """
    Calculate velocity score based on queries per minute (QPM)
    
    Args:
        num_queries: Number of queries in time window
        time_window_minutes: Size of time window in minutes
    
    Returns:
        float: Velocity score between 0.0 (slow, normal) and 1.0 (fast, bot-like)
    
    Algorithm:
        1. Calculate queries per minute (QPM)
        2. If QPM < NORMAL threshold → score = 0.0 (perfectly normal)
        3. If QPM > BOT threshold → score = 1.0 (definitely bot)
        4. If in between → linear interpolation
    
    Why linear interpolation:
        - Smooth transition between normal and bot behavior
        - No hard cutoffs (avoids false positives at boundary)
        - Easy to tune thresholds without changing algorithm
    
    Example:
        - 2 queries in 5 minutes = 0.4 QPM → V-Score = 0.0 (normal)
        - 20 queries in 5 minutes = 4.0 QPM → V-Score = 0.33 (suspicious)
        - 60 queries in 5 minutes = 12.0 QPM → V-Score = 1.0 (bot)
    """
    # Avoid division by zero
    if time_window_minutes <= 0:
        return 0.0
    

    qpm = num_queries / time_window_minutes
    
    print(f"QPM: {qpm:.2f} queries/minute")
    

    if qpm <= VELOCITY_THRESHOLD_NORMAL:
        print(f"      [V-SCORE] Below normal threshold ({VELOCITY_THRESHOLD_NORMAL}), returning 0.0")
        return 0.0
    

    if qpm >= VELOCITY_THRESHOLD_BOT:
        print(f"[V-SCORE] Above bot threshold ({VELOCITY_THRESHOLD_BOT}), returning 1.0")
        return 1.0
    
 
    v_score = (qpm - VELOCITY_THRESHOLD_NORMAL) / (VELOCITY_THRESHOLD_BOT - VELOCITY_THRESHOLD_NORMAL)
    v_score = max(0.0, min(1.0, v_score))    
    print(f"Interpolated score: {v_score:.3f}")    
    return v_score


def calculate_similarity_score(prompts: list) -> float:
    """
    Calculate similarity score based on how repetitive prompts are
    
    Args:
        prompts: List of prompt strings
    
    Returns:
        float: Similarity score between 0.0 (diverse) and 1.0 (repetitive)
    
    Algorithm:
        1. Compare all pairs of prompts
        2. Calculate average similarity across all pairs
        3. If avg similarity < NORMAL threshold → score = 0.0 (diverse prompts)
        4. If avg similarity > BOT threshold → score = 1.0 (copy-paste attack)
        5. If in between → linear interpolation
    
    Why pairwise comparison:
        - Captures overall repetitiveness (not just adjacent prompts)
        - Detects both exact duplicates and slight variations
        - More robust than single-prompt comparison
    
    Example:
        - ["What is AI?", "How's the weather?", "Tell me a joke"] → avg ~0.1 → D-Score = 0.0
        - ["What is AI?", "What is ML?", "What is DL?"] → avg ~0.6 → D-Score = 0.75
        - ["What is AI?", "What is AI?", "What is AI?"] → avg ~1.0 → D-Score = 1.0
    """
    # Need at least 2 prompts to calculate similarity
    if len(prompts) < 2:
        print(f"Only {len(prompts)} prompt(s), returning 0.0 (insufficient data)")
        return 0.0  

    similarities = []  # Store all pairwise similarity values
    

    for i in range(len(prompts)):
        for j in range(i + 1, len(prompts)):  
            similarity = calculate_text_similarity(prompts[i], prompts[j])
            similarities.append(similarity)
    
    avg_similarity = sum(similarities) / len(similarities)
    
    print(f"Average prompt similarity: {avg_similarity:.3f}")
    print(f"(Compared {len(similarities)} prompt pairs)")
    

    if avg_similarity <= SIMILARITY_THRESHOLD_NORMAL:
        print(f"      [D-SCORE] Below normal threshold ({SIMILARITY_THRESHOLD_NORMAL}), returning 0.0")
        return 0.0
    

    if avg_similarity >= SIMILARITY_THRESHOLD_BOT:
        print(f"      [D-SCORE] Above bot threshold ({SIMILARITY_THRESHOLD_BOT}), returning 1.0")
        return 1.0
    

    d_score = (avg_similarity - SIMILARITY_THRESHOLD_NORMAL) / (SIMILARITY_THRESHOLD_BOT - SIMILARITY_THRESHOLD_NORMAL)
    

    d_score = max(0.0, min(1.0, d_score))
    
    print(f"Interpolated score: {d_score:.3f}")
    
    return d_score

def calculate_suspicion_score(recent_queries: list, analysis_window_minutes: float) -> float:
    """
    Calculate final suspicion score by combining V-Score and D-Score
    
    Args:
        recent_queries: List of query log documents from MongoDB
                        Each document has: userId, timestamp, prompt, etc.
        analysis_window_minutes: Time window size in minutes (e.g., 5)
    
    Returns:
        float: Final suspicion score between 0.0 (normal) and 1.0 (malicious)
    
    Algorithm: "Strong Scoring"
        1. Extract all prompts from query logs
        2. Calculate V-Score (velocity: how fast are queries coming in?)
        3. Calculate D-Score (similarity: how repetitive are prompts?)
        4. Combine: suspicion_score = (V-Score * 0.6) + (D-Score * 0.4)
    
    Why weighted combination:
        - Velocity is stronger indicator of bots (60% weight)
        - Similarity catches clever bots that vary their prompts (40% weight)
        - Both together = robust detection
    
    Tier Thresholds:
        - score < 0.8  → Tier 1 (Normal/Proactive Defense)
        - 0.8 ≤ score < 0.95 → Tier 2 (Suspicious/Temp Block)
        - score ≥ 0.95 → Tier 3 (Malicious/Perma Block)
    """
    print(f"\n CALCULATING SUSPICION SCORE")
    print(f"Input: {len(recent_queries)} recent queries")
    print(f"Time window: {analysis_window_minutes} minutes")
    
    prompts = [query["prompt"] for query in recent_queries]
    
    print(f"Extracted {len(prompts)} prompts for analysis")

    num_queries = len(recent_queries)
    v_score = calculate_velocity_score(num_queries, analysis_window_minutes)
    
    print(f"V-Score (velocity): {v_score:.3f}")

    d_score = calculate_similarity_score(prompts)
    
    print(f"D-Score (similarity): {d_score:.3f}")

    suspicion_score = (v_score * VELOCITY_WEIGHT) + (d_score * SIMILARITY_WEIGHT)
    

    suspicion_score = max(0.0, min(1.0, suspicion_score))
    
    print(f"FINAL SUSPICION SCORE: {suspicion_score:.3f}")
    print(f"Formula: ({v_score:.3f} * {VELOCITY_WEIGHT}) + ({d_score:.3f} * {SIMILARITY_WEIGHT}) = {suspicion_score:.3f}")

    if suspicion_score >= 0.95:
        tier = "TIER 3 (MALICIOUS - PERMA BLOCK)"
    elif suspicion_score >= 0.8:
        tier = "TIER 2 (SUSPICIOUS - TEMP BLOCK)"
    else:
        tier = "TIER 1 (NORMAL - PROACTIVE DEFENSE)"
    
    print(f"Classification: {tier}")
    
    return suspicion_score



import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai


# -----------------------------------
# LOAD ENVIRONMENT VARIABLES
# -----------------------------------

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")

if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY was not found in .env")


# -----------------------------------
# GEMINI CLIENT
# -----------------------------------

gemini_client = genai.Client(api_key=GEMINI_API_KEY)


# -----------------------------------
# FASTAPI APP
# -----------------------------------

app = FastAPI(
    title="Snooze You Choose API",
    version="0.2.0"
)


# -----------------------------------
# REQUEST MODELS
# -----------------------------------

class ReflectionRequest(BaseModel):
    choices: list[str]
    # Sent by the Roblox game after the dream; optional for older clients.
    dream: list[str] = []
    stumbles: int = 0
    suggestion: str | None = None


# -----------------------------------
# HOME
# -----------------------------------

@app.get("/")
def home():
    return {
        "game": "Snooze You Choose",
        "message": "Backend is running!"
    }


# -----------------------------------
# HEALTH CHECK
# -----------------------------------

@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


# -----------------------------------
# GEMINI REFLECTION
# -----------------------------------

@app.post("/reflection")
def create_reflection(request: ReflectionRequest):

    # Turn the player's choices into readable text
    choices_text = "\n".join(
        f"- {choice}" for choice in request.choices
    )

    dream_text = "\n".join(f"- {line}" for line in request.dream) or "- (not provided)"
    suggestion_text = request.suggestion or "Pick one small change based on the choices."

    # Prompt sent to Gemini
    prompt = f"""
You are the narrator for an educational sleep game
called "Snooze You Choose."

The player made these choices:

{choices_text}

Those choices changed the player's dream like this:

{dream_text}

The player stumbled {request.stumbles} time(s) in the dream.
Suggested change for next night: {suggestion_text}

Give the player a short reflection that connects their
actual choices to what happened in the dream, then
end with the one suggested change for next night.

Rules:
- Maximum 3 sentences.
- Plain text only, no markdown.
- Use simple, friendly language.
- Do not shame the player.
- Do not diagnose medical conditions.
- Do not give medical advice.
- Focus only on the choices provided.
"""

    try:
        # Send prompt to Gemini
        response = gemini_client.interactions.create(
            model=GEMINI_MODEL,
            input=prompt
        )

        # Send Gemini's response back to the game
        return {
            "choices": request.choices,
            "reflection": response.output_text
        }

    except Exception as error:
        print("Gemini error:", error)

        raise HTTPException(
            status_code=500,
            detail="Gemini request failed"
        )
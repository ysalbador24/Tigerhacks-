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

    # Prompt sent to Gemini
    prompt = f"""
You are the narrator for an educational sleep game
called "Snooze You Choose."

The player made these choices:

{choices_text}

Give the player a short reflection about how their
choices may affect healthy sleep habits.

Rules:
- Maximum 3 sentences.
- Use simple, friendly language.
- Do not shame the player.
- Do not diagnose medical conditions.
- Do not give medical advice.
- Focus only on the choices provided.
"""

    try:
        # Send prompt to Gemini
        response = gemini_client.interactions.create(
            model="gemini-3.8-flash",
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
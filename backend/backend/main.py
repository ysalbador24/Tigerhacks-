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


def ask_gemini(prompt: str) -> str:
    """Send a prompt to Gemini and return its text reply."""
    try:
        response = gemini_client.interactions.create(model=GEMINI_MODEL, input=prompt)
        return response.output_text
    except AttributeError:
        # Older google-genai versions only expose models.generate_content.
        response = gemini_client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        return response.text


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
    sheep: int | None = None
    sheep_total: int | None = None
    suggestion: str | None = None


class NotificationsRequest(BaseModel):
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

    dream_text = "\n".join(f"- {line}" for line in request.dream) or "- (not provided)"
    suggestion_text = request.suggestion or "Pick one small change based on the choices."

    sheep_text = (
        f"The player counted {request.sheep} of {request.sheep_total} sheep "
        "(sheep get distracted by the player's unhealthy choices)."
        if request.sheep is not None and request.sheep_total
        else ""
    )

    # Prompt sent to Gemini
    prompt = f"""
You are Barb the Sleep Sheep, the dry-humored, kind narrator of an
educational sleep game called "Snooze You Choose." You deliver the
player's morning report. Be funny, like a sleepy sheep who has seen
it all, but never mean.

The player made these choices:

{choices_text}

Those choices changed the player's dream like this:

{dream_text}

The player stumbled {request.stumbles} time(s) in the dream.
{sheep_text}
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
        # Send Gemini's response back to the game
        return {
            "choices": request.choices,
            "reflection": ask_gemini(prompt).strip()
        }

    except Exception as error:
        print("Gemini error:", error)

        raise HTTPException(
            status_code=500,
            detail="Gemini request failed"
        )


# -----------------------------------
# GEMINI DREAM NOTIFICATIONS
# -----------------------------------

@app.post("/notifications")
def create_notifications(request: NotificationsRequest):

    choices_text = "\n".join(f"- {choice}" for choice in request.choices)

    prompt = f"""
You write fake phone notifications that haunt a player's dream in a
funny sleep game called "Snooze You Choose." The player kept scrolling
in bed instead of sleeping. Their bedtime choices were:

{choices_text}

Write 6 short, funny, harmless phone notifications that would keep
someone awake (group chats, streaks, autoplay, screen time, etc.).
Reference their choices when it's funny.

Rules:
- One notification per line, no numbering or bullets.
- Each under 40 characters.
- No real names, brands, or personal information.
- Family friendly.
"""

    try:
        lines = [
            line.strip().lstrip("-*0123456789. ").strip('"')
            for line in ask_gemini(prompt).splitlines()
        ]
        notifications = [line[:48] for line in lines if line][:6]
        if len(notifications) < 3:
            raise ValueError("Too few notifications")
        return {"notifications": notifications}

    except Exception as error:
        print("Gemini error:", error)

        raise HTTPException(
            status_code=500,
            detail="Gemini request failed"
        )

import os
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import HTMLResponse, Response
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field, field_validator
from google import genai
from google.genai import types


# -----------------------------------
# LOAD ENVIRONMENT VARIABLES
# -----------------------------------

load_dotenv()

import db  # noqa: E402  (reads DATABASE_URL after .env is loaded)
import voice  # noqa: E402  (reads ELEVENLABS_API_KEY after .env is loaded)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")
# Tried in order when a model is rate-limited (free tier: ~20 requests/day on
# the big models) or overloaded. Override with a comma-separated list.
GEMINI_FALLBACK_MODELS = [
    m.strip() for m in os.getenv(
        "GEMINI_FALLBACK_MODELS", "gemini-3.1-flash-lite,gemini-flash-lite-latest,gemini-3.8-flash"
    ).split(",") if m.strip()
]

# Shared secret the Roblox server sends when saving nights (optional but recommended).
GAME_API_KEY = os.getenv("GAME_API_KEY")

if not GEMINI_API_KEY:
    print("GEMINI_API_KEY not set: /reflection and /notifications are disabled.")


# -----------------------------------
# GEMINI CLIENT
# -----------------------------------

# Fail fast: the game only waits a few seconds, and ask_gemini() moves on to the
# next model itself, so no SDK-level retries (they can stall on rate limits).
gemini_client = genai.Client(
    api_key=GEMINI_API_KEY,
    http_options=types.HttpOptions(timeout=10000, retry_options=types.HttpRetryOptions(attempts=1)),
) if GEMINI_API_KEY else None


def _ask_model(model: str, prompt: str) -> str:
    # generate_content fails fast on rate limits; the interactions API retries
    # internally for tens of seconds, which is longer than the game waits.
    text = gemini_client.models.generate_content(model=model, contents=prompt).text
    if not text or not text.strip():
        raise RuntimeError(f"{model} returned an empty reply")
    return text


def ask_gemini(prompt: str) -> str:
    """Send a prompt to Gemini, moving to the next model if one is rate-limited or down."""
    if gemini_client is None:
        raise RuntimeError("GEMINI_API_KEY is not configured")
    models = list(dict.fromkeys([GEMINI_MODEL, *GEMINI_FALLBACK_MODELS]))
    last_error = None
    for model in models:
        try:
            return _ask_model(model, prompt)
        except Exception as error:  # noqa: BLE001
            print(f"Gemini model {model} failed:", str(error)[:200])
            last_error = error
    raise last_error


# -----------------------------------
# FASTAPI APP
# -----------------------------------

@asynccontextmanager
async def lifespan(_app: FastAPI):
    db.init()
    yield


app = FastAPI(
    title="Snooze You Choose API",
    version="0.3.0",
    lifespan=lifespan,
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


class NightRecord(BaseModel):
    player_id: str = Field(max_length=32)
    display_name: str = Field(max_length=40)
    phone: int = Field(ge=1, le=2)
    lighting: int = Field(ge=1, le=2)
    food: int = Field(ge=1, le=2)
    notifications: int | None = Field(default=None, ge=1, le=2)
    stability: int = Field(ge=0, le=100)
    grade: str = Field(max_length=2)
    points: int = Field(ge=0, le=500)
    sheep: int = Field(ge=0, le=50)
    sheep_total: int = Field(ge=0, le=50)
    stumbles: int = Field(ge=0, le=1000)
    seconds_left: int = Field(ge=0, le=600)
    woke_early: bool = False
    gemini_used: bool = False
    # Every evening activity: {"Shower": 1, "BrushTeeth": 2, "Activities": 6, ...}
    routine: dict[str, int] | None = None

    @field_validator("routine")
    @classmethod
    def small_routine(cls, routine):
        allowed = set(db.ROUTINE_KEYS) | {"Activities", "ShowerComfortable"} | set(db.READING_FACTS)
        if routine is not None:
            if len(routine) > 20 or not set(routine) <= allowed:
                raise ValueError("unknown routine keys")
            if any(not 0 <= value <= 20 for value in routine.values()):
                raise ValueError("routine values out of range")
        return routine


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
        "status": "healthy",
        "gemini": gemini_client is not None,
        "database": db.enabled(),
        "timescale": db.timescale,
        "elevenlabs": voice.enabled(),
    }


# -----------------------------------
# GEMINI REFLECTION
# -----------------------------------

# Most recent morning report, kept in memory for the dashboard.
latest_report: dict = {"text": None, "at": None}

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
        reflection = ask_gemini(prompt).strip()
        # The dashboard reads (and Barb speaks) the most recent report.
        latest_report["text"] = reflection
        latest_report["at"] = datetime.now(timezone.utc).isoformat()
        # Send Gemini's response back to the game
        return {
            "choices": request.choices,
            "reflection": reflection
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


# -----------------------------------
# NIGHT HISTORY (TIGER DATA)
# -----------------------------------

def require_database():
    if not db.enabled():
        raise HTTPException(status_code=503, detail="Database is not configured")


@app.post("/nights")
def save_night(night: NightRecord, x_game_key: str | None = Header(default=None)):
    """Called by the Roblox server each morning. Returns community stats for the morning screen."""
    if GAME_API_KEY and x_game_key != GAME_API_KEY:
        raise HTTPException(status_code=401, detail="Bad game key")
    require_database()

    record = night.model_dump()
    record["player_hash"] = db.hash_player(record.pop("player_id"))
    db.save_night(record)

    return {
        "saved": True,
        "rank_today": db.rank_today(night.points),
        "stats": db.community_stats(),
    }


@app.get("/stats")
def stats():
    require_database()
    return {"stats": db.community_stats(), "hourly": db.hourly(), "routine": db.routine_stats()}


@app.get("/leaderboard")
def leaderboard():
    require_database()
    return {"leaderboard": db.leaderboard()}


# -----------------------------------
# BARB'S VOICE (ELEVENLABS)
# -----------------------------------

@app.get("/barb/latest")
def barb_latest():
    return {**latest_report, "voice": voice.enabled()}


@app.get("/barb/voice")
def barb_voice():
    """Barb reads the latest morning report out loud (MP3, cached per report)."""
    if not voice.enabled():
        raise HTTPException(status_code=503, detail="Voice is not configured")
    if not latest_report["text"]:
        raise HTTPException(status_code=404, detail="No report yet")
    try:
        audio = voice.speak(latest_report["text"])
    except Exception as error:  # noqa: BLE001
        print("ElevenLabs error:", error)
        raise HTTPException(status_code=502, detail="Voice request failed")
    return Response(content=audio, media_type="audio/mpeg")


app.mount("/static", StaticFiles(directory=Path(__file__).with_name("static")), name="static")


@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    """Live sleep stats page: everyone's habits, grades, and the leaderboard."""
    return Path(__file__).with_name("dashboard.html").read_text()


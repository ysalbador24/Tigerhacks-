"""Check the backend's setup: run `python check_setup.py` from backend/."""

import os

from dotenv import load_dotenv

load_dotenv()

ok_count = 0
problems = []


def report(ok: bool, label: str, fix: str = "") -> None:
    global ok_count
    print(("  ✓ " if ok else "  ✗ ") + label)
    if ok:
        ok_count += 1
    else:
        problems.append(fix or label)


print("\nSnooze You Choose: backend setup check\n")

# Database -------------------------------------------------------------
url = os.getenv("DATABASE_URL") or os.getenv("TIMESCALE_SERVICE_URL")
report(bool(url), "Database URL in .env", "Add TIMESCALE_SERVICE_URL=postgres://... (from Tiger Cloud) to .env")
if url:
    try:
        import psycopg

        with psycopg.connect(url, connect_timeout=10) as conn:
            report(True, "Connected to the database")
            row = conn.execute("SELECT extversion FROM pg_extension WHERE extname = 'timescaledb'").fetchone()
            report(bool(row), f"TimescaleDB installed{f' (v{row[0]})' if row else ''}",
                   "TimescaleDB extension missing: use a Tiger Cloud service, or ignore (plain Postgres works too)")
            table = conn.execute("SELECT to_regclass('public.nights')").fetchone()[0]
            if table:
                nights = conn.execute("SELECT count(*) FROM nights").fetchone()[0]
                report(True, f"nights table exists ({nights} nights saved)")
            else:
                print("  • nights table not created yet (it's created when the backend starts)")
    except Exception as error:  # noqa: BLE001 - show any connection problem plainly
        report(False, f"Connecting to the database failed: {error}",
               "Check the URL/password, and that the Tiger Cloud service finished deploying")

# Gemini ---------------------------------------------------------------
key = os.getenv("GEMINI_API_KEY")
report(bool(key), "GEMINI_API_KEY in .env", "Add GEMINI_API_KEY=... to .env")
if key:
    try:
        from main import ask_gemini  # importing main doesn't connect to the database

        reply = ask_gemini("Reply with exactly: OK").strip()
        report(bool(reply), f"Gemini answered ({reply[:40]!r})")
    except Exception as error:  # noqa: BLE001
        report(False, f"Gemini call failed: {error}",
               "Check the key, and GEMINI_MODEL (set it in .env to a model your key can use)")

# ElevenLabs (optional) ------------------------------------------------
if os.getenv("ELEVENLABS_API_KEY"):
    try:
        import voice

        audio = voice.speak("Baa.")
        report(len(audio) > 1000, f"ElevenLabs spoke ({len(audio) // 1024} KB of Barb)")
    except Exception as error:  # noqa: BLE001
        report(False, f"ElevenLabs call failed: {error}",
               "Check ELEVENLABS_API_KEY (it needs Text to Speech access) and ELEVENLABS_VOICE_ID")
else:
    print("  • ELEVENLABS_API_KEY not set (optional: gives Barb a voice)")

# Game key -------------------------------------------------------------
report(bool(os.getenv("GAME_API_KEY")), "GAME_API_KEY in .env (protects saving nights)",
       "Add GAME_API_KEY=some-secret-word to .env and use the same word in src/server/BackendConfig.luau")

print()
if problems:
    print("To fix:")
    for problem in problems:
        print("  - " + problem)
else:
    print("All good! Start the backend with:  uvicorn main:app --reload --port 8000")
print()

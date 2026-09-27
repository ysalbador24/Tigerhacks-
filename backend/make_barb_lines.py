"""Record Barb's grade lines with ElevenLabs for the game's morning report.

Run from backend/:  python make_barb_lines.py
It writes barb_lines/barb_S.mp3 ... barb_D.mp3. Upload each one to Roblox
(Creator Hub -> Development Items -> Audio, or Studio's Asset Manager), then
paste the asset ids into src/shared/BarbVoice.luau.
"""

from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

import voice  # noqa: E402  (reads ELEVENLABS_API_KEY after .env is loaded)

LINES = {
    "S": "Sleep Sensei. Phone away, lights low, snacks done. I counted every sheep. Honestly? I'm a little emotional.",
    "A": "Well-Rested Legend. Almost perfect. One tiny habit away from Sensei. I believe in you. Mostly.",
    "B": "Decent Napper. Not bad! Not great! Very... medium. Like lukewarm tea. Try one better choice tonight.",
    "C": "Chronically Online. The sheep saw your screen time. They're not mad. They're just disappointed.",
    "D": "Raccoon Energy. Bright lights, midnight snacks, doomscrolling. Sweetie. We need to talk about your choices.",
}

out = Path(__file__).with_name("barb_lines")
out.mkdir(exist_ok=True)
for grade, line in LINES.items():
    # multilingual_v2 is the most expressive model; these are recorded once.
    path = out / f"barb_{grade}.mp3"
    path.write_bytes(voice.speak(line, model_id="eleven_multilingual_v2", timeout=60))
    print(f"  ✓ {path.name}  ({path.stat().st_size // 1024} KB)")
print(f"\nDone. Upload the files in {out} to Roblox, then paste the ids into src/shared/BarbVoice.luau")

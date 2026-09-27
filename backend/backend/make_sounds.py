"""Make the game's sound effects and music loops with ElevenLabs.

Run from backend/backend:  python make_sounds.py
It writes game_sounds/*.mp3. Upload them to Roblox (Studio: Asset Manager ->
Bulk Import) and paste each id into src/shared/GameSounds.luau.
Uses roughly 2,000 of the free tier's 10,000 monthly credits.
"""

from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

import voice  # noqa: E402  (reads ELEVENLABS_API_KEY after .env is loaded)

# name: (prompt, seconds, loop)
SOUNDS = {
    "NightAmbience": ("Peaceful night ambience outside a bedroom window: soft crickets and gentle light rain, calm, no thunder", 20, True),
    "LampClick": ("A single crisp click of a bedroom light switch", 0.6, False),
    "TVNoise": ("Muffled television heard through a room: indistinct cartoon voices and a laugh track, low and distant", 12, True),
    "DreamCalm": ("Dreamy calm lullaby music loop, soft music box and warm synth pads, slow and peaceful", 20, True),
    "DreamTense": ("Tense fast electronic pulse music loop, ticking synth bass, suspenseful chase, not scary", 12, True),
    "AlarmClock": ("Old-fashioned bedside alarm clock ringing loudly for three seconds", 3.5, False),
}

out = Path(__file__).with_name("game_sounds")
out.mkdir(exist_ok=True)
for name, (prompt, seconds, loop) in SOUNDS.items():
    path = out / f"{name}.mp3"
    try:
        audio = voice.sound_effect(prompt, seconds, loop)
    except RuntimeError as error:
        if not loop:
            raise
        print(f"  (loop not supported for {name}, making a normal clip: {error})")
        audio = voice.sound_effect(prompt, seconds, False)
    path.write_bytes(audio)
    print(f"  ✓ {path.name}  ({len(audio) // 1024} KB)")
print(f"\nDone. Upload the files in {out} to Roblox, then paste the ids into src/shared/GameSounds.luau")

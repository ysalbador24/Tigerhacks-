"""Barb the Sleep Sheep's voice, via ElevenLabs text-to-speech.

Optional: without ELEVENLABS_API_KEY everything still works, text only.
"""

import hashlib
import json
import os
import urllib.error
import urllib.request
from collections import OrderedDict

API_KEY = os.getenv("ELEVENLABS_API_KEY")
# Any voice from your ElevenLabs Voice Library works; this default is "Laura".
VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID", "FGY2WhTYpPnrIDTdsKH5")
# Flash is fast and uses half the credits of multilingual_v2 (free tier: 10k/month).
MODEL_ID = os.getenv("ELEVENLABS_MODEL", "eleven_flash_v2_5")

# Same text -> same audio, so repeat plays on the dashboard cost no credits.
_cache: "OrderedDict[str, bytes]" = OrderedDict()
_CACHE_SIZE = 20


def enabled() -> bool:
    return bool(API_KEY)


def speak(text: str, model_id: str | None = None, timeout: float = 15) -> bytes:
    """Return MP3 bytes of Barb saying `text`. Raises on any ElevenLabs error."""
    if not API_KEY:
        raise RuntimeError("ELEVENLABS_API_KEY is not configured")
    model = model_id or MODEL_ID
    key = hashlib.sha256(f"{VOICE_ID}|{model}|{text}".encode()).hexdigest()
    if key in _cache:
        _cache.move_to_end(key)
        return _cache[key]

    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=mp3_44100_128",
        data=json.dumps({
            "text": text,
            "model_id": model,
            # A little less stable = more expressive, sleepy delivery.
            "voice_settings": {"stability": 0.4, "similarity_boost": 0.75, "style": 0.3},
        }).encode(),
        headers={"xi-api-key": API_KEY, "Content-Type": "application/json", "Accept": "audio/mpeg"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            audio = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:300]
        raise RuntimeError(f"ElevenLabs HTTP {error.code}: {detail}") from error

    _cache[key] = audio
    if len(_cache) > _CACHE_SIZE:
        _cache.popitem(last=False)
    return audio


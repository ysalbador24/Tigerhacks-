# Dream mechanic and two-minute demo

Bedtime choices now change a playable dream. After sleeping, the player crosses a short cloud path to the "Morning" sunrise. The morning screen shows what each choice changed and a reflection tied to those choices.

## Demo mode (on by default)

`DEMO_MODE` at the top of `src/server/Bedtime.server.luau`.

- **On:** make the three key choices (Phone, Lighting, Food), then use the bed prompt. You can sleep right away. Other activities are optional, and their timed sequences run at about a quarter of their full length.
- **Off:** uses the original rules: all 11 activities and five minutes of evening.

Key-choice prompts are labelled "• key choice", and the HUD tracks them.

## What each key choice does to the dream

| Choice | Good option | Other option |
| --- | --- | --- |
| Phone | Quiet path | **The Algorithm** (a giant googly-eyed phone) chases you and freezes you for 2 s if it catches you; notification cards knock you back; 4 sheep are doomscrolling |
| Lighting | Calm starry night | Glaring daylight; tiles flash, then blink out; 3 sheep wear sunglasses |
| Food | Path holds still | Tiles drift up and down; walk speed drops to 12; 3 sheep are in a food coma |
| Notifications (optional) | — | If left on: more notifications, and they move faster |

**Counting sheep:** ten named sheep (Gary, Baaarbara, Fleece Witherspoon, …) stand along the path. Walk up to one to count it. Sheep distracted by your choices show a speech bubble and can't be counted. The morning report shows how many you counted; the server clamps the count to what tonight's dream allowed.

The rules live in `src/shared/Dream.luau` (layout and choice → effect). The level is built on each player's client in `src/client/DreamCourse.luau`. The server owns progress: it tracks checkpoints, counts falls as "stumbles" and returns the player to their checkpoint, and validates that the player reached the sunrise before ending the night. A "Wake up now" button appears after 45 seconds, so a demo can always reach the ending.

## Score

**Dream Stability** is the character's sleep-readiness value (0–100) from `EveningMood.luau`. It replaces the old "percentage of first options" score, so optional activities with no readiness effect no longer change it. The morning screen says it is a game outcome, not a health measurement.

## Gemini (with scripted fallback)

Gemini does two jobs, and both have scripted fallbacks:
- **Dream notifications:** when a player kept scrolling, Gemini writes the notification texts that fill their dream, based on that player's choices (`POST /notifications`).
- **Morning report:** Barb the Sleep Sheep, a dry-humored narrator, connects the exact choices, sheep count, and stumbles to one suggestion for the next night (`POST /reflection`).

Each request waits up to 4 seconds, then the game falls back to scripted text. Everything Gemini writes goes through Roblox's `TextService` filter before players see it. The morning screen shows "(Gemini)" when the report came from the model.

To enable Gemini:
1. Run the backend: `cd backend/backend && uvicorn main:app --port 8000`, with `GEMINI_API_KEY` in `.env`. You can also set `GEMINI_MODEL`.
2. Roblox cannot reach `localhost`. Expose the backend with a public tunnel (for example `ngrok http 8000`).
3. Set `BACKEND_URL = "https://<your-tunnel>"` at the top of `src/server/Bedtime.server.luau`, with no trailing slash.
4. HTTP requests are enabled through `default.project.json` (`HttpService.HttpEnabled`). If they aren't, turn on Game Settings → Security → Allow HTTP Requests.

## Test checklist (Studio)

1. Rojo sync → Play → START.
2. Try to sleep straight away: the game should list the missing key choices.
3. Choose **Keep scrolling**, **Keep the bright light**, **Late heavy meal**, then sleep. You should get The Algorithm chasing you, notification cards, flickering and drifting tiles, slower walking, and distracted sheep with speech bubbles.
4. Fall off once: you respawn at the last checkpoint and Stumbles goes up.
5. Reach the sunrise → morning screen → **Play another evening**.
6. Replay with all good options: a calm night, stars, a still path, all 10 sheep countable, and a higher Dream Stability.

## Two-minute judging script

- 0:00–0:15 — "Sleep advice is easy to hear and hard to act on. We made the consequences playable."
- 0:15–0:45 — A judge makes the three key choices; the room reacts to each one immediately.
- 0:45–1:20 — Sleep; the dream shows what those choices did.
- 1:20–1:45 — Morning: Dream Stability, a reflection tied to the choices, and one suggestion for next night.
- 1:45–2:00 — The server owns choices, progress, and the ending; the Gemini reflection has a scripted fallback; the habits come from CDC sleep guidance.

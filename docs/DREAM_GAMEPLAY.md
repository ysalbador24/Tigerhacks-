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
| Phone | Quiet path | Notification cards sweep the path and knock you back |
| Lighting | Calm starry night | Glaring daylight; tiles flash, then blink out |
| Food | Path holds still | Tiles drift up and down; walk speed drops to 12 |
| Notifications (optional) | — | If left on: more notifications, and they move faster |

The rules live in `src/shared/Dream.luau` (layout and choice → effect). The level is built on each player's client in `src/client/DreamCourse.luau`. The server owns progress: it tracks checkpoints, counts falls as "stumbles" and returns the player to their checkpoint, and validates that the player reached the sunrise before ending the night. A "Wake up now" button appears after 45 seconds, so a demo can always reach the ending.

## Score

**Dream Stability** is the character's sleep-readiness value (0–100) from `EveningMood.luau`. It replaces the old "percentage of first options" score, so optional activities with no readiness effect no longer change it. The morning screen says it is a game outcome, not a health measurement.

## Reflection (Gemini with fallback)

The server always builds a scripted reflection from the exact choices, plus one suggestion for the next night. If `REFLECTION_URL` in `Bedtime.server.luau` is set, it first POSTs to the backend's `/reflection` and waits up to 4 seconds. If the request fails or times out, the scripted text is used. The morning screen labels which one it is showing.

To enable Gemini:
1. Run the backend: `cd backend/backend && uvicorn main:app --port 8000`, with `GEMINI_API_KEY` in `.env`. You can also set `GEMINI_MODEL`.
2. Roblox cannot reach `localhost`. Expose the backend with a public tunnel (for example `ngrok http 8000`).
3. Set `REFLECTION_URL = "https://<your-tunnel>/reflection"`.
4. HTTP requests are enabled through `default.project.json` (`HttpService.HttpEnabled`). If they aren't, turn on Game Settings → Security → Allow HTTP Requests.

## Test checklist (Studio)

1. Rojo sync → Play → START.
2. Try to sleep straight away: the game should list the missing key choices.
3. Choose **Keep scrolling**, **Keep the bright light**, **Late heavy meal**, then sleep. You should get notification cards, flickering tiles, drifting tiles, and slower walking.
4. Fall off once: you respawn at the last checkpoint and Stumbles goes up.
5. Reach the sunrise → morning screen → **Play another evening**.
6. Replay with all good options: a calm night, stars, a still path, and a higher Dream Stability.

## Two-minute judging script

- 0:00–0:15 — "Sleep advice is easy to hear and hard to act on. We made the consequences playable."
- 0:15–0:45 — A judge makes the three key choices; the room reacts to each one immediately.
- 0:45–1:20 — Sleep; the dream shows what those choices did.
- 1:20–1:45 — Morning: Dream Stability, a reflection tied to the choices, and one suggestion for next night.
- 1:45–2:00 — The server owns choices, progress, and the ending; the Gemini reflection has a scripted fallback; the habits come from CDC sleep guidance.

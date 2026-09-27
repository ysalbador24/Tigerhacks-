# Dream mechanic and two-minute demo

Bedtime choices now change a playable dream. After sleeping, the player crosses a short cloud path to the "Morning" sunrise. The morning screen shows what each choice changed and a reflection tied to those choices.

## Bedtime Rush (demo mode, on by default)

`DEMO_MODE` at the top of `src/server/Bedtime.server.luau`. When it is on, the evening is a 60-second arcade round (`src/client/BedtimeRush.luau`):

- A **3-2-1 countdown**, then a timer bar counts down to 11:00 PM lights out.
- **Catch your runaway phone.** It floats around the room taunting you ("ur streak is dying") and flees when you get close. After 30 seconds its battery runs low and it slows down. Catch it → Phone docked (healthy). Don't → you scrolled.
- **Smack the big light.** Touch the floating bulb to dim the room. Your roommate may turn it back on once, so you have to find it again.
- **Shut the midnight fridge.** A mini-fridge next to the sideboard creaks open, glows, and whispers about leftovers. Walk up to it to shut it. It reopens later in the round (up to 3 times). Open at lights-out → late-night snack.
- **Get to bed.** Use a bed prompt to end the round early; time left adds a bonus. If the timer runs out, you pass out on the floor.

Healthy habits take effort; unhealthy ones happen by default. Anything left undone counts as: phone kept, big light on, no late meal. The optional room activities (shower, reading…) still work, but they use up the clock.

**Grade:** Dream Stability + 2 per counted sheep + up to 15 for getting to bed early. S "Sleep Sensei", A "Well-Rested Legend", B "Decent Napper", C "Chronically Online", D "Raccoon Energy".

Set `DEMO_MODE = false` for the original routine (all 11 activities as dialog choices, five minutes of evening).

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
3. Copy `src/server/BackendConfig.example.luau` to `BackendConfig.luau` and set `url` (and `gameKey`). Git ignores that file.
4. HTTP requests are enabled through `default.project.json` (`HttpService.HttpEnabled`). If they aren't, turn on Game Settings → Security → Allow HTTP Requests.

## Test checklist (Studio)

1. Rojo sync → Play → START.
2. A 3-2-1 countdown starts Bedtime Rush. Try catching the phone, smacking the bulb, and shutting the fridge.
3. For the chaotic dream: ignore the phone, the light, and the fridge, then use the bed. You should get The Algorithm chasing you, notification cards, flickering and drifting tiles, slower walking, and distracted sheep with speech bubbles.
4. Fall off once: you respawn at the last checkpoint and Stumbles goes up.
5. Reach the sunrise → morning screen → **Play another evening**.
6. Replay with all good options: a calm night, stars, a still path, all 10 sheep countable, and a higher Dream Stability.

## Two-minute judging script

- 0:00–0:15 — "Sleep advice is easy to hear and hard to act on. We made the consequences playable."
- 0:15–0:45 — A judge makes the three key choices; the room reacts to each one immediately.
- 0:45–1:20 — Sleep; the dream shows what those choices did.
- 1:20–1:45 — Morning: Dream Stability, a reflection tied to the choices, and one suggestion for next night.
- 1:45–2:00 — The server owns choices, progress, and the ending; the Gemini reflection has a scripted fallback; the habits come from CDC sleep guidance.

## Inspiration
Everyone knows the sleep advice: put the phone down, dim the lights, don't eat a huge meal at midnight. Almost nobody follows it, because the cost is invisible until the next morning. College students are some of the worst sleepers around (we're writing this at a hackathon, so we'd know). We wanted a game where that cost shows up on screen, right away, and is funny enough that you want to play again and do better.

## What it does
**Snooze You Choose** is a Roblox game where your bedtime choices become your dream.

🛏️ **Bedtime.** You're in a cozy dorm room at night. Walk up to your phone, the lamp, and your snack and decide: dock the phone or keep scrolling? Big light or dim lamp? Finish eating or have a late heavy meal? You can't sleep until you've handled the essentials.

🌙 **The dream is built from your choices.**
- **Good routine:** cloud bridges fill the gaps, your legs feel fast, and the night sky is calm.
- **Kept scrolling:** **The Algorithm**, a giant phone with googly eyes, swoops in and chases you ("Just one more video!"). If it catches you, you're frozen watching a 45-minute video essay. Notifications written by Gemini knock you off the path.
- **Bright lights:** the dream glares and platforms blink out under your feet.
- **Late heavy meal:** you're sluggish and the path won't sit still.
- **Several bad habits = sleep debt:** microsleep blinks, whispers, and shadow figures in the corner of your eye.

It gets harder, but never stressful: checkpoints catch you, and a "wake up" button appears if you're stuck.

🐑 **Count sheep.** Ten sheep (Gary, Baaarbara, Fleece Witherspoon…) wait along the path. Your bad habits distract them: some are doomscrolling, some need sunglasses, some are in a food coma. You can only count the ones you didn't ruin.

☀️ **Morning report.** Barb the Sleep Sheep, a dry-humored narrator, grades your night from **S "Sleep Sensei"** to **D "Raccoon Energy"**. She reads the grade out loud, explains what each choice did to your dream, and gives you one small thing to try tomorrow. Then you see how you compare to everyone else ("62% of players doomscrolled. You're #3 today.") and hit **"I CAN DO BETTER"**.

## How we built it
- **Roblox + Luau**, synced from GitHub into Roblox Studio with **Rojo**, so the whole team could work in code.
- **The server owns the game.** Choices, scoring, checkpoints, falls, sheep counts, and the grade are all decided on the server, so players can't farm points or skip to the ending.
- **One shared rules module** maps each choice to a dream effect. The server and the client use the same rules, so every player gets exactly the dream they earned.
- **Google Gemini** writes Barb's personalized morning report and the dream's phone notifications. All AI text goes through Roblox's text filter, and the game falls back to scripted text after 4 seconds, so it never hangs.
- **ElevenLabs** gives Barb her voice. Her grade lines were recorded with ElevenLabs text-to-speech and play in-game, and the live dashboard has a **🔊 Hear Barb** button that reads the latest Gemini-written report in her voice (cached per report to save credits).
- **Python FastAPI backend on a Vultr server** (Ubuntu, systemd, Caddy for HTTPS) brokers every AI call, so no API key ever touches the game.
- **Tiger Data (TimescaleDB)** stores every night played in a hypertable, with a continuous aggregate that rolls stats up by the hour. That powers the community line on the morning report and a **live judge dashboard** (Chart.js): doomscroll rate, grades, "phone docked vs. kept scrolling" dream stability, and a Sleep Sensei leaderboard. Player IDs are stored only as salted hashes.

## Challenges we ran into
- **Hard but not stressful.** Our first sleep-deprivation effect blurred the screen so much the game was unplayable. We tuned every effect (blur, flicker timing, chase speed) until a bad night felt worse without feeling unfair.
- **Free-tier AI limits.** Gemini's free tier ran out mid-testing and our morning report started failing. We added a fallback chain across models with short timeouts, plus scripted text in the game, so the demo never breaks.
- **Getting a Roblox game talking to the internet.** Hosting on Vultr, adding HTTPS, protecting endpoints with a game key, and keeping secrets out of Git (a missing newline in a `.env` file broke two API keys at once 🙃).
- **A whole team, one Roblox place.** Rojo and Git let us merge code, but we still had to coordinate who owned the room, the dream, and the backend.

## Accomplishments that we're proud of
- The choices *are* the level. There's no quiz at the end; you feel the consequences.
- A complete loop in about two minutes: bedtime → dream → morning → replay.
- A real, deployed stack behind a Roblox game: Gemini, ElevenLabs, Tiger Data, and Vultr all working live.
- Barb.

## What we learned
- How to build a server-authoritative Roblox game, and how to use Rojo and Git as a team.
- How to write prompts for a *character* (Barb has rules: funny, never mean, no medical advice).
- How to deploy a real backend (Linux server, HTTPS, systemd) and use a time-series database.
- That the best health message is one players discover themselves.

## Health impact
Our choices follow CDC sleep guidance: screens off before bed; a dark, quiet room; no large meals late at night. Instead of a checklist, players *feel* the tradeoff. The score is called "Dream Stability", and the game says on screen that it's a game outcome, not a health measurement. We don't diagnose or give medical advice; we help players notice their habits and what they lead to.

## What's next
Week-long streaks, more choices (caffeine, a consistent wake-up time), multiplayer "dorm" nights, and Barb reading your full report out loud inside the game.

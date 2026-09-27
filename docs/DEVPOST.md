# Devpost draft: Snooze You Choose

*Copy these sections into Devpost. Replace the bracketed parts with your own details.*

## Tagline
Your bedtime choices build your dream. Scroll in bed and a giant googly-eyed phone chases you through it.

## Inspiration
Everyone knows the sleep advice: put the phone down, dim the lights, don't eat a huge meal at midnight. Almost nobody follows it, because the cost is invisible and shows up the next morning. We wanted a game where that cost is on screen in the moment. [Add a personal story from the team, like the all-nighter before this hackathon.]

## What it does
You play the last hour of a college student's evening in a cozy dorm room.
- **Bedtime Rush (60 seconds).** Lights out is at 11:00 PM. Your phone has grown legs and is running around the room taunting you ("ur streak is dying"): catch it to dock it. Smack the big light off (then your roommate turns it back on). Shut the midnight fridge that keeps creaking open and whispering about leftovers. Gemini writes some of the phone's taunts live. Healthy habits take effort; bad ones happen by default, just like real life.
- **Fall asleep, and your choices become the level.** You cross a dream path to reach the morning:
  - Kept scrolling? **The Algorithm**, a giant phone with googly eyes, chases you shouting "Just one more video!" If it catches you, you're frozen watching a 45-minute video essay. Notification cards written by Gemini ("Your ex liked a post from 2019") block the path.
  - Bright lights? The dream glares, and platforms flicker out under you.
  - Late heavy meal? The path drifts like a waterbed and you move slower.
- **Count sheep.** Ten sheep (Gary, Baaarbara, Fleece Witherspoon…) wait along the path. Your bad habits distract them: some are doomscrolling, some need sunglasses, some are in a food coma. You can only count the ones you didn't ruin.
- **Get graded.** From S "Sleep Sensei" to D "Raccoon Energy", based on your dream, sheep counted, and how early you got to bed.
- **Morning report.** Barb the Sleep Sheep, a dry-humored narrator powered by Gemini, explains what each choice did to your dream and gives you one small thing to try tomorrow night.

## How we built it
- **Roblox + Luau, synced with Rojo from a Git repo.** The dorm, campus, and furniture are generated procedurally from code.
- **The server owns the game.** Choices, scoring, dream checkpoints, fall detection, the win condition, and sheep counts are all validated on the server, so repeated choices can't farm points and players can't skip to the ending.
- **Deterministic rules from one shared module** (`Dream.luau`): each choice maps to a specific dream effect. The same rules drive the server's validation and the client's per-player dream, so every player sees the dream they earned.
- **Gemini API, used twice.** It writes personalized dream notifications from the player's choices, and it writes Barb's morning report. Both go through Roblox's text filter, and both fall back to scripted text after 4 seconds, so the demo never hangs.
- **Python FastAPI backend on Vultr** (systemd + Caddy HTTPS) that brokers the Gemini calls, so the API key never touches the game.
- **Tiger Data (TimescaleDB):** every night played is stored in a hypertable, and a continuous aggregate rolls it up hourly. The morning screen shows live community stats ("62% of players doomscrolled; players who docked their phone averaged 71 stability vs 34"). A **live web dashboard** charts habits, grades, and a Sleep Sensei leaderboard in real time. Player ids are stored only as salted hashes.

## Health impact
Poor sleep hygiene is a real problem for college students, and advice alone doesn't change behavior. Our core choices follow CDC sleep guidance: screens off before bed, a dark, quiet, cool room, and no large meals late at night. Instead of a checklist, players *feel* the tradeoff. Scrolling really is fun in the moment (your mood goes up), but it costs you later. We call the score "Dream Stability" and say on screen that it's a game outcome, not a health measurement. We don't claim the game improves sleep; it helps players recognize bedtime habits and see what they lead to.

[If you run the playtest: "We tested with N people outside our team: X finished without help, and Y could name a bedtime habit afterward."]

## Challenges we ran into
- Making the dream fair and funny at the same time: The Algorithm moves slower than you walk, and a "Wake up now" button appears after 45 seconds so nobody gets stuck.
- Keeping AI in a supporting role: gameplay outcomes are deterministic and server-controlled, and Gemini only adds flavor and explanation, with a fallback.
- Fitting the whole loop into a two-minute demo (demo mode).

## Accomplishments we're proud of
- The choices *are* the level; there's no quiz at the end.
- A complete loop, playable in under two minutes: evening → dream → morning → replay.
- Barb.

## What we learned
[Fill in: Rojo workflow, server-authoritative design in Roblox, prompt design for a character, etc.]

## What's next
More nights with a week-long streak, more choices (caffeine, a consistent wake time), and voiced narration for Barb.

## Built with
roblox, luau, rojo, python, fastapi, gemini-api, tiger-data, timescaledb, postgresql, vultr, caddy, chart.js, git

## Demo script (2 minutes)
1. "Sleep advice is easy to hear and hard to follow. We made the consequences playable."
2. A judge plays Bedtime Rush: chasing the phone, smacking the light, shutting the fridge.
3. Sleep. The Algorithm shows up, the sheep are on their phones.
4. Morning: Barb's report ties each choice to what happened in the dream.
5. Replay with good choices: a calm, starry dream and every sheep countable.
6. Point at the laptop running the live dashboard: both nights just appeared, with the doomscroll rate and the phone-vs-stability chart.

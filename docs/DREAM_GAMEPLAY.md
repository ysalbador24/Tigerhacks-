# The dream

After bed (or automatically at 11 PM), the player falls asleep into a short platform course high above the campus and walks toward the morning sunrise. The dream is built from that night's choices by one shared rules module (`src/shared/Dream.luau`), which both the server and the client use, so every player gets exactly the dream they earned.

## Difficulty

The three key habits are **read vs. scroll**, **main light off vs. on**, and **finished eating vs. late heavy meal**. Each unhealthy one raises the dream's severity by one (0 to 3); a low "sleep readiness" (for example, one more TV episode) can raise it too.

| Severity | Feel |
|---|---|
| 0, well rested | Cloud bridges fill the gaps and you walk faster. |
| 1 | Normal path plus that habit's obstacle. |
| 2, sleep debt | Light blur, microsleep blinks, whispers. |
| 3 | Every obstacle, shadow figures, and slower steps. |

Each habit adds its own obstacle:

- **Scrolled:** The Algorithm (a giant googly-eyed phone) rises up, swoops overhead, and chases you. If it catches you, you freeze watching a video essay. Notifications written by Gemini knock you back.
- **Big light on:** platforms flicker out and the dream glares.
- **Late meal:** you move slower and the tiles bob.

It gets harder, never unfair: checkpoints catch every fall, The Algorithm moves slower than you walk, and a "wake up" button appears after 45 seconds.

## Sheep

Ten named sheep (Gary, Baaarbara, Fleece Witherspoon...) stand along the path. Each unhealthy choice distracts some of them (scrolling, squinting at the light, food coma), and only the rest can be counted.

## Morning

An alarm, a sunrise, and the player sits up in bed. Then Barb the Sleep Sheep grades the night (S Sleep Sensei, A Well-Rested Legend, B Decent Napper, C Chronically Online, D Raccoon Energy), explains what each choice did to the dream (written by Gemini, with a scripted fallback), reads the grade aloud (ElevenLabs), and shows how the player compares with everyone else (Tiger Data). "I CAN DO BETTER" starts a new evening.

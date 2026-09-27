# The evening

After **Let's Play**, the player is in their dorm room at **10:00 PM**. Bedtime is **11:00 PM**, five real minutes later (the clock in the corner speeds up if they watch another TV episode). They can go to bed any time; at 11 they fall asleep automatically. The sky outside starts as a warm sunset and is fully dark by bedtime.

Walk up to anything with a marker and choose. Choices can be changed until bedtime; only the latest one counts, so nothing can be farmed.

| Activity | Healthy choice | Other choice | How it plays |
|---|---|---|---|
| Wind down (reading nook) | Read a book | Scroll on phone | **Book:** four short chapters of CDC sleep facts, each with a quick question. **Phone:** an endless feed of posts. Scrolling brings The Algorithm into the dream. |
| Shower | Take a shower | Skip it | Mini-game: step into the shower, set the water to "just right", wipe the fogged mirror. |
| Food | Small bowl of cherries | Slice of pizza | Short eating animation at the kitchenette. Pizza makes the dream sluggish. |
| Thermostat | 65–68 °F | Warmer or colder | Set the room temperature (64–74 °F); Barb mentions it in the morning. |
| Main light | Turn it off | Keep it on | Light switch; the room goes dim and warm. Leaving it on makes platforms flicker in the dream. |
| TV | Turn it off | One more episode | An episode plays and the clock jumps forward 15 minutes. |
| Notifications | Do Not Disturb | Keep them on | More notifications interrupt the dream. |
| Curtains, brushing teeth | Close / brush | Leave open / skip | Quick choices. |

The HUD shows the time, activities done, **mood**, **sleep readiness**, and **simulated sleep** (5–9 hours). These are game values for the character, not real-world measurements (see `src/shared/EveningMood.luau`).

The server owns every choice, the clock, and the score (`src/server/Bedtime.server.luau`); each player's room changes are local to them. When the night ends, the routine is saved to Tiger Data for the stats page (see `BACKEND_DEPLOY.md`).

Moving furniture in Studio: interactions use the room's layout anchors and a few fixed positions in `src/client/Bedtime.client.luau`; update those if you rearrange the room. Health reference: CDC sleep guidance and https://www.health.harvard.edu/healthy-aging-and-longevity/sleep-hygiene-simple-practices-for-better-rest

# Bedtime routine

Based on `TigerHacks!!.docx`. The existing intro is unchanged. New gameplay starts only after START completes.

Explore room 101 and use proximity prompts for curtains, lighting, food, phone placement, notifications, temperature, and winding down. Each activity offers two choices. Choices may be revisited; points reflect the latest choice, so repeated actions do not farm points. A 45-second sunset begins after the intro. A minute of guided quiet time is available at the reading pouf. Bedtime unlocks after five minutes and all ten choices. Use the bed prompt to see the morning Rest Score and replay.

The server owns choices, timing, and scores. Each player's visual room adjustments are local, so multiplayer choices do not change another player's room. Scores are illustrative game feedback. Session history currently lasts only while connected; database persistence and AI dialogue require a defined purpose and provider before integration.

Room interactions currently use the default furniture coordinates. If you rearrange furniture, update activity positions in `src/client/Bedtime.client.luau` to match.

Health reference supplied in the brief: https://www.health.harvard.edu/healthy-aging-and-longevity/sleep-hygiene-simple-practices-for-better-rest

Devpost capture plan: show the unchanged intro, sunset, two contrasting room choices, the breathing activity, and morning results. Capture the furnished room and results as submission images. Submission text can explain how the game turns bedtime routines into a short, interactive story. Record final media after the desired AI/database scope is confirmed.

## Bathroom and entrance update

The routine now includes ten choices: the original seven plus showering, toothbrushing, and skincare. Bathroom actions play short game sequences (15, 20, and 12 seconds); these timings are gameplay pacing, not real-world hygiene guidance. The shower displays water during its sequence and turns off afterward. All ten choices use the same server-owned score and replay flow.

Room 101's entrance is offset left, at approximately `(-101, 17.7, -133)`. Players spawn just inside at `(-101, 15.5, -139)`, facing into the room. The ensuite connects through a six-stud opening in the west wall near the entrance. The intro script is unchanged.

## Upstairs reading and mood meter

The upstairs nook now includes a built-in bookshelf, an optional choice to read a short chapter, and a second switch for the same main light controlled downstairs. Reading is the eleventh routine choice (reading or skipping both count as a completed choice).

The HUD shows character mood, sleep readiness, and simulated sleep duration. Server responses include the updated values and a short explanation of each choice. Choices replace their previous effects: repeating an action or using both light switches cannot farm mood points. Replay resets mood and readiness to 50. Morning results show the final mood and simulated sleep.

`src/shared/EveningMood.luau` defines fictional balancing values. Mood and readiness are clamped to 0–100. Simulated sleep runs from five to nine hours based on readiness; these numbers describe the game character, not a real-world sleep prediction. Phone scrolling illustrates a tradeoff: a small immediate mood gain with reduced sleep readiness. Skipping optional self-care such as showering or skincare has no mood penalty.

# Photo-inspired Room 101

Sync this project with Rojo, then press Play to see the furnished starting bedroom. The room uses Roblox parts and materials, so no uploaded images or paid assets are required. This is a stylized recreation of the photo, with two adjacent windows in the existing exterior opening, warm string lights, a raised storage bed, a desk and computer, plants, shelves, records, and extra decorations.

## Move and save furniture in Studio

1. Stop Play and connect/sync Rojo.
2. Open Studio's Command Bar and run:

```lua
require(game.ServerScriptService.Server.CozyBedroom).build()
```

3. In Explorer, expand `Workspace > CozyBedroom101`.
4. Select a named model, such as `WritingDesk`, `RaisedBed`, or `TallFloorPlant`. Use Studio's Move and Rotate tools to arrange it. Select multiple models when moving a desk with its accessories, or the bed with its pillows and baskets.
5. Save your place. The server uses your existing `CozyBedroom101` model instead of regenerating its furniture.

The room's floor is at approximately `(-84, 12.4, -161)`. Select the furniture model and press F to focus the viewport. The campus shell is generated during Play; the furniture can be edited before Play using the command above.

All furniture is anchored to stay where you place it. Anchored parts can still be moved with Studio's editing tools. Changes made during Play are temporary; stop Play before making an arrangement you want to save. This setup provides Studio editing, not player furniture dragging in the published game.

To restore the initial arrangement, rename your edited model as a backup, then run the command again. Keep only the intended layout named `CozyBedroom101`, and move backups out of Workspace before playing.

## Cottage decor and loft

`BedroomExpansion.luau` adds the reference-inspired cream/sage decor under `CozyBedroom101 > CottageExpansion`. It preserves existing furniture and adds the expansion only if it is missing. Named models include the cream sofa with usable seats, television console, spiral staircase, railed reading loft, linen curtains, trailing ivy, botanical gallery, baskets, lanterns, and sage bedding.

The spiral rises 18 studs using 36 half-stud steps. The reading nook has a seat, books, a table, and plants. Keep the six-stud opening in the loft railing clear when rearranging furniture.

After START, approach an object and press E (or tap its prompt):

- Wall switch beside the bedroom door: turn the main light off/on. Warm lamps remain available.
- Curtain pull beside the windows: close/open the sliding linen panels.
- Candle on the coffee table: light/extinguish its flame and glow.
- TV remote on the coffee table: switch the decorative TV display on/off.

Controls change the local player's room; other players keep their own settings. Lighting and curtain choices contribute to the bedtime score. TV and candle toggles are decorative. Replay resets all four controls. The TV uses an original static relaxation card, not streamed video.

# Atlas Mascot Asset Deployment Matrix

Grounded in `/Users/donghokang/Developer/Atlas` on April 14, 2026.

This is the permanent deployment matrix for how mascot artwork should be used across Atlas.

## Goal

Atlas has three mascot asset families:

1. `portrait art`
2. `medium sticker/card presentation`
3. `pixel live-state sprites`

Those families are not interchangeable. Each one exists because a different product surface needs a different kind of readability and emotional weight.

## Source Of Truth

### Portrait masters

These are the approved large-surface references:

- `/Users/donghokang/Downloads/Dragon evolution through radiant stages (1).png`
- `/Users/donghokang/Downloads/Celestial hare evolution stages.png`

Use them as the creative source for:

- mascot detail heroes
- recap/export posters
- celebration sheet heroes
- any future full-screen mascot media

### Sticker / medium-card references

These are the approved medium-surface references:

- `/Users/donghokang/Downloads/Storm-forged drake evolution chart.png`
- `/Users/donghokang/Downloads/Aurielle creature line concept sheet (1).png`

Use them as the creative source for:

- onboarding choice cards
- medium mascot cards
- gallery thumbnails
- future collectible card surfaces

If no dedicated simplified export exists yet, medium surfaces may use portrait-derived framing, but the presentation should still behave like sticker art:

- cleaner crop
- less atmosphere
- faster scan

Shipped sticker assets now live in the main app asset catalog:

- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Sticker.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage2Sticker.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage3Sticker.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage1Sticker.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage2Sticker.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage3Sticker.imageset`

### Pixel live-state sprites

These remain the only correct family for tiny live-state surfaces.

App bundle pixel assets:

- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Happy.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage2Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage2Happy.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage3Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage3Happy.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage1Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage1Happy.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage2Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage2Happy.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage3Idle.imageset`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage3Happy.imageset`

Widget extension mirrors:

- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage1Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage1Happy.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage2Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage2Happy.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage3Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAetherionStage3Happy.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage1Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage1Happy.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage2Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage2Happy.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage3Idle.imageset`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/AtlasMascotAurielleStage3Happy.imageset`

## Deployment Rules

### Use portrait art for:

- mascot detail hero
- celebration sheet hero
- recap/export posters
- future share-sheet previews
- any future large, premium mascot surface

### Use medium sticker/card presentation for:

- onboarding selection cards
- compact in-app mascot summary cards
- future gallery thumbnails
- medium-size reward surfaces that still want premium art presence

### Use pixel live-state sprites for:

- widgets
- tiny status chips
- compact inline mascot state callouts
- small reward badges
- any mascot surface below roughly `96pt`

## Hard Rules

- Never use pixel art as the primary hero art on a flagship in-app screen.
- Never swap widgets over to portrait art just because it looks richer.
- Never let a medium card become a full poster composition.
- When in doubt: `large = portrait`, `medium = sticker/card`, `tiny/live = pixel`.

## Current Product Mapping

### In-app

- `AtlasMascotIllustration` is the large-surface family and should remain portrait-led.
- `AtlasMascotSticker` is the medium-surface family and should power compact cards, onboarding choices, and medium reward surfaces.
- `AtlasMascotSprite` is the live-state family and should remain pixel-led.
- Surfaces that show both should have a clear reason:
  - portrait for premium hero read
  - pixel for state sync and compact continuity

### Widgets

- keep widgets pixel-first
- use glow, framing, and badges to polish them rather than replacing the asset family

### Recaps / exports

- use portrait-first composition
- if a sprite appears, it should be secondary and explanatory

## Stage Framing Rules

### Aetherion

- `Cindlet`: tighter crop, lower stance, compact power
- `Voltflare`: diagonal energy, more wing and tail room
- `Aetherion`: more vertical room for horns and halo

### Aurielle

- `Moppet`: centered, airy, premium softness
- `Glisshare`: taller frame with ear and tail sweep visible
- `Aurielle`: more vertical headroom for ear arc and crescent-tail silhouette

## Future Work

- if the style evolves, refresh the sticker family from the approved masters rather than reverting medium surfaces back to portrait-only art
- keep any new mascot asset request attached to one of the three families above
- do not add a fourth mascot art family unless there is a real product need

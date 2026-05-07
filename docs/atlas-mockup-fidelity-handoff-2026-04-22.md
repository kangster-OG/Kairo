# Atlas Mockup Fidelity Handoff - 2026-04-22

## Goal

Rebuild the native iOS app toward the approved three-screen mockup: warm off-white canvas, compact 8pt-radius cards, deep green primary actions, Aetherion/Aurielle companion-first progression, Shotsy-simple logging, and a Finch/Pokemon-inspired companion home without noisy gamification.

## What Changed

- Retuned `AtlasPalette` to the mockup's warm background, deep green primary, softer borders, reduced shadows, and compact shell treatment.
- Reduced premium typography scale and root scroll spacing so Today, Log, Companion, Protocols, and Progress feel closer to the reference density.
- Reworked Today around the mockup stack: top brand/streak/XP row, mascot momentum hero, next-shot card, medication mini chart, primary Log Shot CTA, support rings, and vial runway.
- Reworked Log so the tab opens directly into the shot ritual instead of an upfront capture-mode rail. Alternate logs remain available through shortcuts lower in the screen.
- Reworked the shot ritual into: reward banner, shot header, injection site, pain, side effects, notes, vial decrement, Mark as Taken, and aftercare support prompts.
- Reordered and tightened Companion so the first view shows hero, quests, badges, collectibles, and weekly mastery.
- Generated and integrated a new Aetherion stage 1 mockup asset, then converted it into a transparent 1024px RGBA sticker.
- Routed the new Aetherion art through Today, Log reward banner, Companion hero, Protocol hero, and Watch companion glance when the active companion is Aetherion stage 1.
- Kept Aurielle and the existing companion selection system intact.

## New Asset

- App asset: `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Mockup.imageset/aetherion-stage1-mockup.png`
- Backup/staging asset: `atlas-ios/Atlas/Assets.xcassets/Mascots/AetherionStage1Mockup.imageset/aetherion-stage1-mockup.png`
- Built-in `image_gen` was used first; local post-processing removed the generated background and resized/cropped the asset into a transparent app sticker.

Final generation prompt summary:

> A premium iOS companion mascot for Atlas: small Aetherion stage 1, fox-cat/dragon creature, teal-blue fur, crystalline ear fins, bright expressive eyes, soft premium 3D illustration, warm off-white app background, friendly, collectible, Pokemon-inspired but original, no text, no watermark.

## Screenshots

- Today: `output/mockup-fidelity-2026-04-22/01-today.png`
- Log Shot: `output/mockup-fidelity-2026-04-22/02-log.png`
- Companion: `output/mockup-fidelity-2026-04-22/03-companion-tightened.png`
- Protocols: `output/mockup-fidelity-2026-04-22/04-protocols.png`
- Progress: `output/mockup-fidelity-2026-04-22/05-progress.png`

## Verification

Passed:

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mockup-fidelity-build build
```

Passed:

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mockup-fidelity-build -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection test
```

## Remaining Polish

- This is materially aligned with the mockup but not pixel-identical. Exact fidelity would still benefit from a dedicated design-token pass for per-screen point sizes and row heights.
- The generated Aetherion works well as stage 1. Future work should generate matching Aetherion stage 2 and stage 3 assets in the same rendering style if the app wants full evolution visual continuity.
- Aurielle still uses the existing production art. That preserves the current companion design, but a future art pass could create mockup-style Aurielle variants without changing her underlying identity.
- Widgets are data-complete from the earlier pass and inherit the app's projection model, but they were not screenshot-polished in this round because simulator widget placement is a separate surface.

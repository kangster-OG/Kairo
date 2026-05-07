# Atlas Six-Step Rebuild Completion Handoff

Date: 2026-04-22

## Scope

This pass continued the mascot-forward rebuild toward the generated mockup direction:

1. Pixel-polish Today, Log Shot, Protocols, Progress, and Companion.
2. Generate and integrate a full mockup-style mascot art set.
3. Preserve the feature-depth loops behind the rebuilt surfaces.
4. Polish widget/watch companion surfaces around the same visual language.
5. Run simulator screenshot audit across core tabs.
6. Run TestFlight-readiness build and focused regression checks.

## Product Direction Applied

Atlas is being repositioned as a comprehensive peptide protocol system, not primarily a privacy pitch. The in-app hierarchy now favors:

- next shot and protocol runway
- clean one-ritual logging
- protein, hydration, workout, symptom, and photo support loops
- companion XP, quests, badges, and collectibles
- simple tab-first navigation modeled on the generated mockup

Privacy/trust remains present in the product foundation, but it is no longer the dominant surface-level story in these rebuilt screens.

## Mascot Art

The app and widget extension now resolve the companion stickers/illustrations to new mockup-style asset names:

- `AtlasMascotAetherionStage1Mockup`
- `AtlasMascotAetherionStage2Mockup`
- `AtlasMascotAetherionStage3Mockup`
- `AtlasMascotAurielleStage1Mockup`
- `AtlasMascotAurielleStage2Mockup`
- `AtlasMascotAurielleStage3Mockup`

The first Aetherion pass rendered too blue, so a second Aetherion pass was generated and processed into greener moss/teal cutouts that better match the target mockup.

Generated Aetherion source files:

- `/Users/donghokang/.codex/generated_images/019db2b0-86b7-7041-a7b5-6527ec93e03e/ig_03e9adfae9b6e41e0169e96e80374c819aa9313bd01d53a200.png`
- `/Users/donghokang/.codex/generated_images/019db2b0-86b7-7041-a7b5-6527ec93e03e/ig_03e9adfae9b6e41e0169e96ed1b5b0819a96dbac3bf755577a.png`
- `/Users/donghokang/.codex/generated_images/019db2b0-86b7-7041-a7b5-6527ec93e03e/ig_03e9adfae9b6e41e0169e96f1da374819a9dc26555c1534717.png`

Integrated app assets:

- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Mockup.imageset/`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage2Mockup.imageset/`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage3Mockup.imageset/`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage1Mockup.imageset/`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage2Mockup.imageset/`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas/Assets.xcassets/AtlasMascotAurielleStage3Mockup.imageset/`

The same asset sets are present in:

- `/Users/donghokang/Developer/Atlas/atlas-ios/AtlasWidgetsExtension/Assets.xcassets/`

## UI Surfaces

Main rebuilt app surfaces:

- Today: mascot hero, next shot card, medication curve, support rings, inventory runway, compact bottom tab.
- Log Shot: clean ritual flow with site, pain, side effects, vial decrement, and support prompts.
- Protocols: live protocol stack summary, quick actions, live plan section.
- Progress: medication curve, weight/photo/meal/workout rollup, weekly protocol mastery.
- Companion: level ring, next form, quests, badges, collectibles, weekly mastery.

Key implementation files:

- `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotFeatures.swift`
- `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasWatchCompanionFeatures.swift`
- `/Users/donghokang/Developer/Atlas/atlas-ios/AtlasWidgetsExtension/AtlasWidgetsExtension.swift`

## Widgets And Watch

Widget extension changes:

- Added warm Atlas widget palette.
- Retuned widget text, badges, buttons, support strips, and card backgrounds away from the old dark treatment.
- Updated widget mascot image lookup to use the same mockup-style Aetherion/Aurielle art.
- Kept the existing projection, quick action, and App Intent behavior intact.

Watch companion:

- Watch companion surfaces now use the shared `AtlasMascotSticker` resolver, so generated mascot art is consistent with the app.

## Simulator Audit

Screenshots captured in:

- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/01-today.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/02-log.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/03-protocols.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/04-progress.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/05-companion.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/08-today-final.png`
- `/Users/donghokang/Developer/Atlas/output/six-step-final-2026-04-22/09-companion-final.png`

`08-today-final.png` and `09-companion-final.png` are the best final visual references because they include the corrected green-teal Aetherion art.

## Verification

Build passed:

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-six-step-final-build build
```

Focused tests passed:

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-six-step-final-build -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection test
```

Asset JSON validation passed with `python3 -m json.tool` for all new mockup image-set `Contents.json` files in the app and widget extension.

## Working Tree Notes

The tree remains intentionally dirty. I did not clean, reset, revert, or delete unrelated local changes. There are substantial pre-existing modified files, generated outputs, derived data directories, and untracked work from prior passes.

New/updated artifacts from this pass include:

- `.derived-data-six-step-final-build/`
- `output/six-step-final-2026-04-22/`
- mockup mascot image sets in app and widget asset catalogs
- this handoff document

## Release Caveat

This pass completed readiness checks, not a TestFlight upload. No archive upload, build number bump, signing change, or App Store Connect submission was performed.

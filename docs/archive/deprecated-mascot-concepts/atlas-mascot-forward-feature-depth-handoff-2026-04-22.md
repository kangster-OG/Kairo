# Atlas Mascot-Forward Feature Depth Handoff - 2026-04-22

## Product Direction

Atlas is now being pushed as a comprehensive peptide protocol system: shot adherence, protocol planning, vial runway, injection-site rotation, side-effect/context capture, nutrition/workout support, widgets/watch surfaces, and a companion progress loop. Privacy remains present as trust infrastructure, not the main pitch.

The visual/product direction in this pass is mascot-forward, blue-primary, simple first-screen hierarchy, and utility-rich detail underneath. The companion stays central as the user's progress avatar, while protocol, food, workout, health, and widget loops stay practical and low-friction.

## Completed In This Pass

- Routed primary shot actions into the new mascot-forward Log tab ritual:
  - Today `Log Shot` button.
  - Today quick-capture `.shot`.
  - Old quick-capture shot card `Mark taken`.
  - Protocol detail `Log Shot`, occurrence hero, and taken action rows.
- Kept the legacy log sheet only for skip/reschedule and compatibility paths, and relabeled it from "Quick log" to "Schedule update" / "Shot update" so it no longer competes with the ritual.
- Tightened Protocols into a denser live-plan dashboard:
  - `Live Plan` title.
  - Next shot, vial runway, dose history, side effects, site rotation, support score.
  - Shorter button labels: `Plan`, `Log`, `Supplies`.
  - Denser mini tiles and protocol cards.
- Fixed the Log tab capture rail after simulator review:
  - Replaced the horizontally clipped rail with an adaptive grid.
  - Shortened rail-only labels to `Water` and `Photo`.
- Added shared projection coverage:
  - Extension projection now includes baseline mascot state even before rewards are explicitly enabled.
  - Support rings projection covers protein, hydration, and workout.
  - Quick-log URL test now proves linked vial decrement and projection refresh.
- Preserved and verified the existing tolerant site-region decode and partial shell refresh work from this rebuild thread.

## Verification

Commands run:

```sh
xcodebuild -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mascot-forward-build -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection test
```

Result: passed, 3 tests, 0 failures.

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mascot-forward-build build
```

Result: passed.

Simulator data after reinstall:

```text
protocols: 1
vials: 1
sites: 3
context_logs: 3
workout_logs: 2
```

Shared projection after final terminate/launch:

```json
{
  "nextDue": "Tirzepatide Weekly",
  "supportScore": 82,
  "mascot": {
    "selection": "aetherion",
    "displayName": "Cindlet",
    "stage": "stage1"
  },
  "watchNextDue": "Tirzepatide Weekly"
}
```

Runtime log scan:

```sh
/usr/bin/log show --style compact --last 5m --predicate 'process == "Atlas"' | rg -i "Atlas error|Fatal|crash|exception|database|decode"
```

Result: no matches.

## Simulator Screenshots

- Today: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_1aae2574-d3b5-4ce5-9493-57275d2c4263.jpg`
- Log ritual after rail fix: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_60c31265-4bd9-4b08-9e1c-1ddfb88c65c5.jpg`
- Protocols top: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_f6121f1c-ce6f-42ba-a128-1bab43b6d75c.jpg`
- Protocols live-plan dashboard: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_5b06cfaa-6b63-40aa-9a45-3cb3b1a7866c.jpg`
- Protocol detail: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_9b6396bf-ac86-49e1-b527-af9775a6e2c0.jpg`
- Progress: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_68cd8bf5-1be7-4502-a2d0-a475047332cf.jpg`
- Companion: `/var/folders/3w/v5wzxv655tg48rm26vfr7r9h0000gn/T/screenshot_optimized_84757a39-0656-4dc1-be3b-e3bd12494e7f.jpg`

## Legacy Path Audit

- `AtlasLogSheet` still exists intentionally for skip/reschedule and URL/backward-compatible logging surfaces.
- In-app primary taken-shot paths now route to the new Log tab ritual instead of directly committing a shot.
- Incoming `atlas://quick-log` remains direct by design for widgets/intents/backward compatibility and is covered by the vial/projection regression.
- The old `AtlasQuickCaptureScreen` still exists for weight, symptom, hydration, protein, and progress-photo capture; shot capture from that surface routes to the new ritual.

## Working Tree Notes

The repo remains intentionally dirty with substantial pre-existing work, generated files, derived data, app icons, Info.plist changes, and untracked feature files. No clean/reset/delete was performed.

Files most relevant to this pass:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasRepositories.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

## Remaining Risks

- Widget visual rendering itself was not placed on the iOS home screen in this pass; the shared projection feeding it was verified.
- Watch UI was verified by code/build/projection coverage, not by a live watch simulator screenshot.
- The app is now much closer to the mockup direction, but some lower-depth screens outside Today/Log/Protocols/Progress/Companion still carry older Atlas design language and should be polished in later passes.

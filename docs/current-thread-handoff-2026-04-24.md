# Atlas Current Thread Handoff - 2026-04-24

This handoff preserves the durable decisions and verification results from the long April 23-24 mockup rebuild thread. Future Codex threads should read this before continuing post-onboarding Atlas work.

## Product Direction Locked In This Thread

Atlas is now a premium iPhone peptide protocol system.

The headline is no longer privacy-first. Privacy, local-first behavior, aliases, explicit sharing, and deterministic exports still matter, but they should feel built in rather than becoming the product identity. The user-facing promise is:

> Build your peptide protocol.

Atlas should be comprehensive but simple:

- protocol tracking
- shot logging
- vial runway and inventory
- injection-site rotation and history
- side effects and lightweight between-dose check-ins
- protein, hydration, workouts, weight, progress photos, and Apple Health support
- widgets
- companion XP, evolution, quests, badges, collectibles, and weekly mastery
- review/share/export surfaces

Atlas must not become:

- a marketplace
- a sourcing app
- a vendor or price-comparison app
- a social app
- a medical advice app
- a dosing advice app
- a diagnostic app
- an AI chatbot product
- a calorie-scanner or meal-scan app
- a Finch-style shop, furniture, friends, social, or seasonal economy
- a bloodwork-heavy clinical-lab app as the headline product
- a theme/customization app just because a competitor has themes

## Locked Visual Direction

Use `docs/atlas-post-onboarding-visual-north-star-2026-04-23.md` as the post-onboarding visual source of truth.

The locked mockup board contains these reference surfaces:

1. Today
2. Log Shot
3. Companion
4. Protocols
5. Protocol Detail
6. Edit Protocol
7. Progress
8. Progress Evidence
9. Inventory / Supplies
10. Peptide Calculator
11. Weekly Review
12. Settings / Integrations

Treat the mockup board as the design language for the whole post-onboarding product, including deep editors, quick-capture sheets, settings, widgets, review/export, and empty states.

Visual rules that must not drift:

- warm off-white canvas
- deep Atlas green primary
- restrained amber rewards
- blue only as functional support, mostly hydration
- SF/system typography, not `.rounded`
- letter spacing 0
- avoid forced uppercase
- mostly 8pt card/control radii
- compact bottom tab pill shelf
- soft, low shadows
- mascot prominence where it makes progress visible
- compact density with useful protocol information above the fold
- no generic health-app UI
- no noisy gamification
- no shame/fear tactics
- no AI-ish filler copy
- no privacy-as-headline copy

Keep both mascot lines:

- Aurielle
- Aetherion

Do not change avatar designs unless explicitly asked.

## Competitive Analysis Decision

The competitor review from Shotsy, Pepty/Pep AI, Finch, Cal AI, and other peptide-adjacent apps led to one true feature add and three refinements.

Add:

- One lightweight between-dose symptom check-in. Keep it tiny: appetite, energy, GI, sleep quality, notes. No new tab.

Modify:

- Make site rotation/history first-class in the live product, not hidden depth.
- Make share/export/review simpler and more visible through obvious `Share Summary` / `Export` actions.
- Keep nutrition and fitness support narrow and disciplined: protein, hydration, workouts, weight/progress photos, and Apple Health passthrough. Do not expand into full calorie-tracker sprawl.

Subtract or de-emphasize:

- Anything that feels like internal system naming instead of user language.
- `Trust Vault`, `Review Mode`, `Protocol Change Studio`, and similar legacy concepts can remain as internal architecture where needed, but the user-facing app should read as: track protocol, log shot, monitor runway, review progress, share summary.

## Implementation State At Close Of Thread

The post-onboarding app was rebuilt into the mockup-forward system.

Important implemented surfaces and flows:

- Today root tab with mascot hero, next shot, medication chart, Log Shot CTA, support rings, and runway row.
- Log Shot ritual with site selection, pain, side effects, notes, vial decrement, and `Mark as Taken`.
- Lightweight between-dose `Protocol check-in` with appetite, energy, GI, sleep, and notes.
- Companion root tab with level ring, large mascot, quests, badges, collectibles, and weekly mastery.
- Protocols root tab with active protocols, schedule summary, and add protocol.
- Protocol detail with medication level, log/edit actions, site rotation/history, and runway.
- Protocol create/edit/change flows in the same compact mockup system.
- Progress root tab with protocol progress, support signals, evidence, logs, review, and Share Summary access.
- Progress evidence, inventory, calculator, weekly review, settings/integrations, account, privacy, reminders, companion/rewards, widgets, import records, export data, support logs, progress review, health signals, peptide notes, and quick-capture flows.
- Sourcing-adjacent inventory copy was scrubbed from post-onboarding user-facing surfaces. Onboarding may still contain old wording and is intentionally out of scope until rebuilt.

Known source files that future threads will likely need:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Atlas/AtlasAppBootstrap.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`
- `scripts/atlas-mockup-screenshot-qa.sh`

## Verification At Close Of Thread

Full XCTest run passed:

```sh
xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas \
  -destination 'platform=iOS Simulator,id=6B1511BF-884B-4253-ABFE-09EDFDFF6957' \
  -derivedDataPath atlas-ios/.derived-data-execution-quality test
```

Result:

- 205 tests executed
- 0 failures
- `** TEST SUCCEEDED **`

Latest simulator screenshot sweep passed:

```sh
REFERENCE_DIR=output/mockup-screenshot-qa/fidelity-final-pass-2026-04-23 \
DERIVED_DATA=atlas-ios/.derived-data-execution-quality \
SIMULATOR_ID=booted \
ATLAS_QA_SETTLE_SECONDS=10 \
ATLAS_QA_ROUTE_SETTLE_SECONDS=10 \
ATLAS_QA_SLOW_ROUTE_SETTLE_SECONDS=12 \
scripts/atlas-mockup-screenshot-qa.sh output/mockup-screenshot-qa/final-confidence-2026-04-24
```

Captured 37 simulator screenshots:

- primary tabs: Today, Log, Check-in, Protocols, Progress, Companion
- deep flows: Protocol Detail, Protocol Create, Protocol Editor, Protocol Change, Medication Levels, Inventory, Calculator, Share Summary, Weekly Review, Progress Evidence, Settings, Widgets, Companion Detail, Rewards Detail, Import Records, quick-capture flows, Export Data, Support Logs, Progress Review, Health Signals, Peptide Notes

Final contact sheet:

- `output/mockup-screenshot-qa/final-confidence-2026-04-24/final-confidence-contact-sheet.jpg`

Pixel-diff note:

- Some routes report `no reference` because the locked board did not include every extrapolated deep flow.
- Some routes changed against older reference screenshots because they were intentionally updated after that reference was created.
- Do not interpret the pixel-diff output as proof of every possible runtime state. Use it as a regression guard plus human screenshot review.

## Honest Confidence Statement

At the close of this thread, Atlas has a strong working app baseline:

- the app builds
- the full test suite passes
- the screenshot QA harness covers the primary tabs and key deep flows
- the post-onboarding product matches the locked mockup direction
- the requested feature changes were implemented or surfaced
- forbidden product directions were not added to post-onboarding

The next work should be release hardening, not another broad feature expansion pass.

Remaining normal release risks:

- physical-device HealthKit permission behavior
- notification timing on real devices
- WidgetKit behavior outside the simulator harness
- TestFlight packaging and signed smoke test
- edge cases beyond the automated 205-test suite and 37-route screenshot sweep

## Recommended Next Steps

1. Run a physical-device smoke test for HealthKit, notifications, widgets, app launch, and persistence.
2. Run a signed TestFlight build and smoke the root tabs plus Log Shot, Check-in, Share Summary, and widgets.
3. Review onboarding separately. Do not let onboarding drag the post-onboarding app back to privacy-first positioning.
4. If doing more fidelity work, update the screenshot QA reference set deliberately rather than tuning blindly against stale references.
5. Keep feature work restrained. Atlas does not need new product pillars right now.

## Fresh Thread Warning

Do not restart the mockup rebuild from scratch. The current direction is already implemented and verified. Future work should preserve the locked board language, fix concrete regressions, and harden real-device behavior.

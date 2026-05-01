# Atlas Six-Step Feature Depth Handoff - 2026-04-22

## Scope

This pass continued the mascot-forward Atlas rebuild across the six requested lanes:

1. Protocol Detail + Active Protocol Dashboard
2. Log Shot Flow Overhaul
3. Nutrition / Workout / Health Integration Upgrade
4. Companion Progress System
5. Onboarding / positioning coherence on secondary trust/review/settings surfaces
6. Widgets + Watch surfaces and TestFlight-readiness verification

Atlas is still positioned as a comprehensive peptide protocol system with support tracking, companion progression, and trust/review infrastructure. Privacy remains present as confidence and control, not the headline.

## Main App Changes

- Hardened `AtlasForwardShotCaptureCard` so the shot ritual is one continuous flow:
  - pre-shot checklist with due time, suggested site, dose, and estimated vial-after state
  - durable confirmation after the occurrence refreshes
  - caught-up empty state when no shot is due
  - aftercare buttons still retain the just-logged protocol context
  - confirmation includes site, vial before/after, dose, time, and pain summary
- Expanded Food / support tracking:
  - added a Today's Support Plan panel for protein, hydration, appetite, GI check-in, and Health/manual status
  - kept recent meals/context, hydration streak, workout history, and support score visible in the Log flow
- Deepened Companion:
  - added XP Sources card with shot, protein, hydration, workout, next-form, and reward framing
  - added weekly recap badges for support logs, workouts, and photos
  - kept both mascot lines intact and used the existing companion artwork
- Tightened Protocol:
  - Active Protocol Dashboard and detail Live Plan now include progress impact alongside next shot, dose history, side effects, site rotation, vial runway, companion XP, and recent changes
- Reframed older surfaces:
  - Insights now opens with a Protocol Support command card instead of feeling like a generic analytics page
  - Trust Vault copy now reads as trust infrastructure/review control instead of privacy as the whole product
  - Review Mode copy now explains clean protocol review packets from shots, side effects, support logs, photos, and inventory
  - Settings hero now says protocol system rather than plain settings/privacy framing

## Widgets + Watch

- Next Due widget now shows support rings in non-small families when projection data is available.
- Watch Companion screen now has a Companion Glance card with mascot art, level, XP, next form, streak, and quest count.
- Projection file verified on simulator:
  - next due: Tirzepatide Weekly
  - support score: 82
  - rings: Protein 1 of 2, Hydration 2 of 2, Workout 2 recent
  - mascot: Cindlet, next form Voltflare

## Verification

Build:

```sh
xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mascot-forward-build build
```

Result: passed.

Focused tests:

```sh
xcodebuild -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-mascot-forward-build -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection test
```

Result: passed, 3 tests, 0 failures.

Simulator visual audit screenshots:

- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/01-today.png`
- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/02-log.png`
- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/03-protocols.png`
- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/04-progress.png`
- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/05-companion.png`
- `/Users/donghokang/Developer/Atlas/output/visual-audit-2026-04-22/06-watch-companion.png`

## Working Tree Notes

The repo was already very dirty before this pass, including app icons, Info.plists, design system/domain/persistence changes, derived data, generated artifacts, and untracked feature files. Nothing was cleaned, reset, reverted, or deleted.

Files intentionally touched in this pass include:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasTrustVaultFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasReviewModeFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasWatchCompanionFeatures.swift`
- `atlas-ios/AtlasWidgetsExtension/AtlasWidgetsExtension.swift`
- `docs/atlas-six-step-feature-depth-handoff-2026-04-22.md`

## Remaining Product Polish

- The main flows are now coherent and build-verified, but a full TestFlight candidate should still run a fresh-install DREAM onboarding pass and a full app screenshot pass on smaller/larger simulators.
- Widget visuals were code/build/projection verified; live Home Screen widget placement was not manually added through SpringBoard in this pass.
- The protocols screen is usable in the simulator pass, but further safe-area polish at the bottom of long scroll content would be worthwhile before the next TestFlight upload.

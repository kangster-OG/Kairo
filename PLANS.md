# Atlas Build Plan

## Current direction
- Atlas React Native remains the product oracle, Android path, and migration source.
- Native iOS under `atlas-ios/` is the shipped primary iPhone product path.
- React Native is in feature freeze except for isolated export-contract improvements or critical fixes.
- Native parity, second-order features, and release-hardening work are now complete in code.

## How to read this file
- The top sections describe current repo state and release posture.
- The lower phase sections are a historical implementation record.
- If this file disagrees with current native code or the native release docs, prefer:
  - `atlas-ios/`
  - `atlas-ios/README.md`
  - `docs/native-release-readiness.md`
  - `docs/ios-architecture.md`

## Active milestone
### Final Native Hardening + QA + Release Readiness
Depends on:
- native parity, Universal Migration + Provider Handoff, Review Mode, and Episode Intelligence complete
- full native build/test verification on clean derived data
- release docs, QA matrices, and rollback notes brought up to date with the native codebase

Status:
- code complete on 2026-03-14
- clean Debug simulator build green on 2026-03-14
- clean Release simulator build green on 2026-03-14
- Release extension builds green on 2026-03-14
- native package builds green on 2026-03-14
- simulator test suite green on 2026-03-14
- final release documentation and manual QA matrix updated on 2026-03-14
- release-readiness is conditional on physical-device/TestFlight verification on 2026-03-14

Will deliver:
- crash-safe app bootstrap fallback instead of a fatal persistence-launch failure
- clean build/test verification recorded for app plus native extensions
- final native release notes, rollback strategy, migration safety checklist, and known-issues list
- manual QA matrix for guest and imported-user states across the complete native product surface

Constraints:
- no net-new product feature work
- keep React Native frozen except for critical oracle/export fixes
- focus on reliability, privacy, clarity, and release readiness

Verification goals:
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasWidgetsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasIntentsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`
- manual QA uses `qa/native-ios-release-manual-checklist.md`

Verification notes:
- `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release' build`
- `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release' build`
- `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -target AtlasWidgetsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -target AtlasIntentsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
- `swift build` succeeded in `atlas-ios/Packages/AtlasPersistence`
- `swift build` succeeded in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release'`
- result: `86` tests passed, `0` failures
- final release decision currently: `CONDITIONAL`

Next queued milestone:
- Final Native Hardening + QA + Release Readiness

## Historical milestone record
The following sections record what was implemented and verified during the native rebuild. They are not the current roadmap unless a section is explicitly reopened.

## Next milestone
### Phase 2: Native persistence + Atlas Export import bridge
Depends on:
- Phase 1 native shell and package boundaries
- approved Atlas export/import contract docs

Status:
- code complete on 2026-03-14
- RN export-contract verification green on 2026-03-14
- native CLI verification hardened and documented on 2026-03-14
- native package resolution, `xcodebuild` Atlas scheme build, and `xcodebuild test` for `AtlasTests` are green in this environment on 2026-03-14
- Phase 2 is closed on 2026-03-14

Will deliver:
- GRDB-backed SQLite source of truth
- deterministic migrations
- repository implementations
- Atlas Export v1 staging, dry-run diff, and transactional import
- first native data-backed Today and Library surfaces

Verification notes:
- RN export test:
  - `./node_modules/.bin/jest --watchman=false --runInBand --runTestsByPath __tests__/features/exports/export-service.test.ts --verbose`
- native commands documented in `atlas-ios/README.md`:
  - `swift package resolve --package-path Packages/AtlasPersistence`
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data build`
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasWidgetsExtension -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data build`
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasIntentsExtension -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data build`
  - `xcodebuild test -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data`
- native verification now completed successfully with:
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data build`
  - `xcodebuild test -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data`
- fixture-backed native migration coverage now exists for:
  - blank/fresh user
  - one protocol
  - multiple protocols
  - protocol revisions/change history
  - Trust Vault alias/discreet rendering
  - inventory/vials/sites
  - selective sharing / audit-heavy bundles

## Recently completed milestone
### Phase 4.5: Protocol Change Studio parity
Depends on:
- Phase 1, Phase 2, Phase 3A, Phase 3B, and Phase 4 complete
- React Native Protocol Change Studio semantics as the oracle

Status:
- implemented and verified on 2026-03-14

Will deliver:
- native Change Studio entry points from protocol detail, Library, Today, and Timeline
- preview-before-commit flows for 7/14/30 day change impact
- explicit future-only revision operations for dose, time, cadence, pause/resume, phases, travel/timezone, missed-dose policy, and vial handoff
- transactional commit/cancel behavior with immutable history preserved
- Timeline-visible protocol change audit entries with privacy-aware summaries

Constraints:
- do not resume Review Mode
- do not resume Episode Intelligence
- keep React Native frozen except for critical oracle/export fixes
- preserve immutable logs and reminder history
- stop after Phase 4.5

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-phase45 -only-testing:AtlasTests/AtlasPhaseOneTests`
- tests cover future-only edits, pause/resume, titration/rest behavior, timezone changes, vial switch-over inventory integrity, preview-vs-commit parity, cancel semantics, audit entries, and alias/discreet rendering

Next queued milestone:
- Universal Migration + Provider Handoff

### Phase 4: inventory + vials + calculator + site tracking parity
Depends on:
- Phase 1, Phase 2, Phase 3A, and Phase 3B complete
- React Native inventory, calculator, and site-tracking flows as the oracle

Status:
- implemented and verified on 2026-03-14

Will deliver:
- native inventory list, vial detail, create/edit/archive, and manual correction flows
- vial linking and active switch-over from protocol detail/library surfaces
- projected depletion and low-stock read models
- automatic vial decrement on taken logs only, with explicit correction audit history
- native reconstitution calculator with saved profiles and math explanation
- native site list/management plus site picker during taken logs
- deterministic GRDB migrations and repository extensions for Phase 4 data

Constraints:
- do not port full Trust Vault UI yet
- do not port native onboarding in this phase
- do not resume second-order features
- keep React Native frozen except for critical oracle/export fixes
- preserve immutable history vs derived inventory state recalculation

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-phase4`
- tests cover vial CRUD/linking, decrement behavior, manual correction history, depletion math, calculator profile save/load, site persistence, and privacy-safe rendering

Verification status:
- complete on 2026-03-14

### Phase 3B: reminder parity
Depends on:
- Phase 1, Phase 2, and Phase 3A complete
- React Native reminder privacy, settings, and notification-action semantics as the oracle

Status:
- implemented and verification-complete on 2026-03-14

Will deliver:
- native notification permission flow
- local notification manager backed by native iOS notification APIs
- notification category/action registration
- reminder scheduling from native future occurrence projections
- regeneration and cleanup when protocol state or occurrence state changes
- actionable notifications for taken, skipped, and open-app flows
- reminder settings UI in the native app
- discreet/full/generic reminder formatting parity

Constraints:
- do not implement widgets beyond strict reminder glue
- do not implement App Intents business logic yet
- do not port full Trust Vault UI yet
- do not resume second-order features
- keep React Native frozen except for critical oracle/export fixes
- preserve immutable history vs generated future occurrence separation

Verification goals:
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data build`
- `xcodebuild test -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data`
- tests cover permission handling, notification scheduling/regeneration, logging-triggered cleanup, and privacy-aware reminder copy

Verified in this workspace:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-nosign-serial -only-testing:AtlasTests/AtlasPhaseOneTests`
- latest result: `20` tests passed, `0` failures

### Phase 3A: Core loop parity
Status:
- implemented and verification-complete on 2026-03-14

## Parity gate before second-order work resumes
Native iOS must reach parity through Trust Vault for:
- onboarding + privacy/discreet + guest/account boundary
- Today, Timeline, Library, Insights, Settings
- protocols + revisions + change flows
- reminders + quick logging
- inventory + vial linking + site tracking + calculator
- metrics + insights
- Trust Vault + selective sharing + export/import migration

Until that gate is met:
- no Universal Migration + Provider Handoff
- no Review Mode
- no Episode Intelligence

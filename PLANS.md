# Atlas Build Plan

## Current direction
- Atlas React Native remains the product oracle, Android path, and migration source.
- Native iOS under `atlas-ios/` is the shipped primary iPhone product path.
- React Native is in feature freeze except for isolated export-contract improvements or critical fixes.
- Native parity, second-order features, and release-hardening work are now complete in code.
- Repo documentation truth-map cleanup completed on 2026-03-15; use `docs/repo-truth-map.md` to distinguish current native docs from historical migration/spec docs.

## How to read this file
- The top sections describe current repo state and release posture.
- The lower phase sections are a historical implementation record.
- If this file disagrees with current native code or the native release docs, prefer:
  - `atlas-ios/`
  - `atlas-ios/README.md`
  - `docs/native-release-readiness.md`
  - `docs/ios-architecture.md`

## Active milestone
### Public Launch Infrastructure + Production Readiness
Depends on:
- final native hardening, simulator QA, and release-readiness foundations already complete in code
- native iOS remaining the primary iPhone product path with local-first SQLite as the canonical client store
- optional cloud layers staying additive to guest-first/local-first behavior instead of replacing them
- Trust Vault, selective sharing, Review Mode, provider handoff, and privacy rendering remaining bounded across any new backend surfaces

Status:
- started on 2026-04-09

Will deliver:
- production account/auth/sync implementation on top of the existing account-boundary scaffolds
- real HealthKit integration for the approved v1 metric surface with explicit opt-in and source attribution
- backend/session model for live review sessions that preserves bounded read-only review semantics and revocation rules
- removal or replacement of obviously scaffolded customer-facing copy in onboarding, settings, and review surfaces
- production-safe crash reporting or equivalent reliability instrumentation with a privacy-bounded payload policy
- release-level QA coverage across simulator, real-device, import/export, privacy, reminders, biometrics, share flows, and launch-critical backend paths

Constraints:
- preserve local-first and guest-first behavior even after auth/sync exists
- no medical advice, dosing advice, sourcing flows, or broad social/chat behavior
- keep immutable history separate from generated future schedule occurrences
- keep backend data scope bounded and additive; do not make cloud availability a prerequisite for the core app shell
- keep crash/instrumentation payloads free of protocol names, notes, raw exports, review contents, and other sensitive user data

Execution order:
- scaffold and UI copy cleanup for account/sync, Health, and live review surfaces
- production auth/session/backend design and schema implementation
- app-side account/auth/sync integration and migration-safe guest upgrade path
- HealthKit service and source-aware metric integration
- live review session backend/session model and app integration
- production-safe crash reporting and release-time instrumentation review
- full QA pass and release decision

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`
- targeted backend/auth/sync, HealthKit, Review Mode, privacy, export/import, and instrumentation tests
- simulator QA for onboarding, account upgrade, sync recovery, Health connect/disconnect, live/static review, Trust Vault, and share/import/export
- real-device QA for notifications, biometrics, Health permissions, share sheets, file handoff, and signed archive/App Store readiness

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
- release-finish audit, accessibility sweep, and release-doc truth check reopened on 2026-03-15
- required native package builds and full simulator test suite rerun green on 2026-03-15
- release docs/checklist updated with analytics defer decision and manual accessibility/privacy gates on 2026-03-15
- emulator launch/icon/accessibility sweep rerun green on iPhone 17, iPhone 16e, and iPhone 17 Pro Max simulators on 2026-03-15
- physical-device onboarding UX correction reopened on 2026-03-15 after first signed iPhone install exposed Reachability confusion plus overly blocking native onboarding data-entry friction
- native shell layout + input ergonomics rebuild reopened on 2026-03-15 after physical-device use exposed an overly compact card/list feel and weak numeric-entry affordances in onboarding and Insights
- premium full-screen iPhone shell rebuild reopened on 2026-03-15 after physical-device use still showed Atlas as visually recessed/boxed-in with oversized inset chrome and non-premium root surfaces
- root presentation/full-screen host bug fixed on 2026-03-15 by restoring a modern launch-screen path; post-fix shell density, header geometry, and first-run polish QA remains in progress
- post-fix QA reopened on 2026-03-15 for settings readability regressions and an overly hidden companion layer after device review exposed low-contrast toggle labels and a too-subtle mascot presentation
- native contrast sweep reopened on 2026-03-16 for remaining white-on-white text regressions inside notes, form fields, and sheet/list editing flows after device testing showed unreadable typed and static copy on light surfaces
- shell-state slicing + injected-clock cleanup reopened on 2026-04-09 after review flagged broad observation fan-out in the native shell and lingering direct `Date()` writes in app-model mutation paths
- shell-state slicing + injected-clock cleanup completed on 2026-04-09 with tab-scoped observable view slices plus injected-clock adoption across native AtlasFeatures mutation and editor defaults

Will deliver:
- crash-safe app bootstrap fallback instead of a fatal persistence-launch failure
- clean build/test verification recorded for app plus native extensions
- final native release notes, rollback strategy, migration safety checklist, and known-issues list
- manual QA matrix for guest and imported-user states across the complete native product surface
- first-run native onboarding tuned for real iPhone entry: optional setup details stay skippable, keyboard flow stays calm, and users can reach the shell without filling protocol scaffolding up front
- primary shell surfaces use full-canvas native layouts with larger action affordances, and bounded numeric inputs prefer numeric-first controls over generic text entry where that fits the current architecture
- root shell, top treatment, bottom dock, and high-frequency surfaces reworked toward an edge-to-edge premium iPhone presentation with less dead space, fewer floating-card affordances, and calmer sheet/input geometry
- narrower observable state slices for shell-heavy native surfaces so Timeline, Insights, and peer tabs do not all hang off the same broad snapshot owner
- app-model mutation paths that consistently use the injected clock for deterministic tests, deep-link flows, and future runtime diagnostics

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

## Current implementation focus
### Capture speed + ambient utility + visual progress polish
Depends on:
- native Today, Insights, widgets/intents, and Progress Evidence foundations already complete in code
- local-first privacy rendering, Trust Vault behavior, and bounded export rules remaining intact
- existing direct logging and extension projection infrastructure staying deterministic and explicit

Status:
- started on 2026-04-13
- completed in code on 2026-04-13
- polish follow-up reopened on 2026-04-13 for microcopy, motion, screenshot QA, and more opinionated Today guidance

Will deliver:
- a faster consumer-simple capture surface for shot, weight, symptom, context, and progress-photo actions
- stronger home-screen and lock-screen Atlas utility through clearer quick-capture widget and shortcut paths
- guided progress-photo recapture with angle-aware visual reference from the last matching check-in
- richer before/after compare and milestone timeline views inside Progress Evidence
- a more premium private progress summary artifact that combines photos, measurements, weight trend, and mascot/rewards context without turning Atlas into a social feed

Constraints:
- preserve local-first behavior and private on-device photo storage
- keep visual progress descriptive only; no image interpretation, diagnosis, or medical claims
- keep widgets/intents narrow, privacy-aware, and grounded in local projection freshness
- avoid duplicating the full Insights shell inside quick-capture surfaces

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

Verification notes:
- `swift build --package-path atlas-ios/Packages/AtlasPersistence` passes in this workspace
- package-only `swift build --package-path atlas-ios/Packages/AtlasFeatures` still hits the pre-existing `UIKit` import mismatch when compiled outside the iOS app target on macOS
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-atlas build` passes
- simulator QA confirmed deep-link entry into `atlas://quick-capture?kind=weight` and `atlas://progress-evidence`, with clean app logs during launch
- follow-up polish build passes via `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-atlas-polish build`
- targeted route regression passes for `testHandleIncomingQuickCaptureURLOpensTodayQuickCaptureLane` and `testHandleIncomingProgressEvidenceURLOpensInsightsProgressEvidence`
- screenshot QA reviewed Today, Quick Capture, and Progress Evidence after the microcopy + opinionated-surface pass

### Calm retention layer
Depends on:
- native Today, Insights, Review Mode, inventory, and privacy foundations already complete
- local-first settings and derived snapshots remaining separable from the core tracking engine
- deterministic privacy-safe rendering continuing to flow through native package boundaries

Status:
- started on 2026-03-15

Will deliver:
- optional low-pressure milestone badges for check-ins, weekly review completion, inventory upkeep, and consistent context logging
- neutral, non-shaming copy with easy full disable in Settings
- a fully optional local-only companion layer that reacts to the same calm progress signals without adding chat or social pressure
- privacy-safe Today/Insights surfaces that stay generic under alias/discreet rendering

Constraints:
- never reward unsafe dosing behavior or encourage false backfilling to preserve streaks
- never punish missed doses or use shame language
- no social graph, feed, sharing pressure, or chat behavior
- keep this layer separable from immutable history and generated future scheduling

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

### Meal/context logging expansion
Depends on:
- native insights, timeline, review, and Episode Intelligence foundations already complete
- local-first persistence and Atlas JSON remaining the canonical export/import truth
- privacy rendering continuing to stay explicit, bounded, and descriptive only

Status:
- started on 2026-03-15

Will deliver:
- lightweight context logging for meal timing, fed/fasted state, appetite, hydration, GI context, and optional notes/tags
- low-friction native quick-add flows with progressive disclosure instead of a generic nutrition app surface
- timeline integration so context logs appear around protocol and episode windows
- restrained Episode Intelligence correlation that stays descriptive and timing-focused
- Atlas JSON/export/review/provider-handoff/privacy coverage where context data is included

Constraints:
- no diet recommendations, meal plans, calorie-first tracking, or medical claims
- keep the feature scoped to protocol understanding and episode review
- preserve guest-first and local-first behavior
- respect alias/discreet rendering and keep free-text context conservative outside full mode

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

### Migration + restore safety + handoff polish
Depends on:
- native Universal Migration, Provider Handoff, and Review Mode flows already complete
- Atlas JSON remaining the canonical import/export contract
- local-first backup and audit behavior remaining deterministic and explicit

Status:
- started on 2026-03-15

Will deliver:
- saved reusable mapping templates for generic CSV and manual import workflows
- pre-commit duplicate/conflict linting for imports before destructive commit
- explicit restore-point creation and preview for destructive bulk actions
- transactional restore flow with append-only audit coverage
- bounded preset templates for provider handoff and Review Mode packs

Constraints:
- Atlas JSON remains canonical migration truth
- CSV remains human-readable and may stay lossy where already intended
- no live/cloud review sessions
- no silent destructive writes
- preserve backup-export behavior before replace-import
- preserve alias/discreet rendering and bounded scope handling

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

### Operational confidence + explainability
Depends on:
- native Today, Timeline, Protocol Change Studio, and inventory flows already complete
- revision/audit/reminder/inventory data remaining deterministic and privacy-safe

Status:
- started on 2026-03-15

Will deliver:
- deterministic "Why is this due?" explanations from Today and Timeline occurrence surfaces
- privacy-safe "What changed?" rendering for protocol change audits and revision-driven diffs
- vial and inventory movement explanations that distinguish taken-log decrement, manual correction, vial switch-over, and archival/status changes
- post-commit change impact summaries that confirm regenerated future occurrences, reminder updates, inventory forecast effects, and unchanged historical logs

Constraints:
- descriptive only; no medical advice or recovery recommendations
- preserve preview-before-commit parity
- preserve immutable historical logs and generated-future separation
- respect full, alias, and discreet rendering across all explanation surfaces

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

### Supplies + consumables + vendor-history parity
Depends on:
- native inventory, import/export, review, and privacy foundations already complete
- Atlas JSON remaining the canonical import/export truth
- local-first inventory history staying deterministic, append-only, and privacy-safe

Status:
- started on 2026-03-15

Will deliver:
- native consumables tracking for supplies such as syringes, needles, swabs, bacteriostatic water, disposal items, travel-kit items, and user-defined items
- manual create/edit/archive flows with quantity-on-hand, reorder thresholds, lead-time notes, vendor/store labels, purchase-history notes, and lot/size metadata
- visible consumable adjustment history plus low-stock and projected depletion states where protocol linkage is configured
- bounded optional protocol linkage that improves planning without turning Atlas into sourcing or shopping
- Atlas JSON import/export parity and privacy-aware rendering for consumables where reasonable

Constraints:
- keep copy neutral and descriptive; no sourcing recommendations, affiliate flows, or marketplace behavior
- preserve local-first and guest-first behavior
- preserve immutable historical logs and do not mix protocol log history with supply adjustment history
- preserve bounded selective sharing, alias/discreet rendering, and audit trails

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

### Widgets + App Intents first-pass polish
Depends on:
- app-group-safe projection storage remaining narrower than the canonical database
- native Today, Inventory, Insights, reminders, and logging flows already complete
- privacy rendering continuing to flow through AtlasPrivacy instead of ad hoc extension logic

Status:
- started on 2026-03-15
- biometric gate enforcement + next-due App Intents polish reopened on 2026-04-09 after review found the shipping gate still stubbed and the native intents surface still narrower than the main app loop

Will deliver:
- a privacy-aware Next Due widget for overdue/next-up state
- a privacy-aware Low Stock widget for vial and supply status
- narrow quick-log actions for mark taken, skip, and open-Atlas routing
- quick entry App Intents and Shortcuts for weight entry, symptom entry, Today, and Inventory/Supplies access
- a shared-projection-backed next-due quick-log App Intent surface for mark-taken and skip flows
- real LocalAuthentication-backed biometric gating for Trust Vault export/share unlocks
- projection refresh wiring after logging, imports, privacy-mode changes, and protocol-change commits

Constraints:
- extensions read only app-group-safe projection data and never the canonical database directly
- keep lock-screen and discreet-mode surfaces conservative
- avoid broad extension-side business logic; main-app integrity remains the source of truth
- preserve immutable history, audit behavior, and deterministic projection output

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

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

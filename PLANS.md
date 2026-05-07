# Kairo Build Plan

## Active milestone
### iOS App Store Rejection Recovery + Evidence-Gated Resubmission
Depends on:
- native iOS under `atlas-ios/` remaining the submitted App Store product
- App Store Connect state being verified from the automated Playwright browser, not assumed from docs
- the final submission action stopping before `Update Review` / final App Review submission until the user explicitly approves it

Status:
- started on 2026-05-07 after the third App Review rejection
- latest rejection: Guideline `2.3.0 Performance: Accurate Metadata`
- rejected build: `1.0 (2026050401)`
- Apple issue: uploaded build metadata listed `UIRequiredDeviceCapabilities` / Required Capabilities as `arm64`, blocking install on the review devices
- upload validation finding: App Store Connect rejects removing `arm64` from `UIRequiredDeviceCapabilities` for 64-bit app/extension binaries, so `arm64` must be present
- current binary: build `2026050703`, with `arm64` explicitly present in the app, widget extension, and intents extension plists
- upload status: `2026050703` upload succeeded on 2026-05-07 and is validated in App Store Connect
- App Store Connect version page now has build `2026050703` selected for iOS version `1.0`; previously selected build `2026050701` and rejected build `2026050401` were removed from the selected build slot
- App Review notes were updated to address the May 7, 2026 `2.3.0` device-capability rejection and to name build `2026050703`
- App Store Connect `Update Review` / final submission has not been clicked

Will deliver:
- local binary metadata, entitlements, privacy manifest, permission, StoreKit, paywall, and legal-link audit
- fresh signed archive/IPA inspection before upload
- App Store Connect verification that the selected build and uploaded build metadata match the fixed IPA
- review-like smoke pass on iPhone and iPad targets where local tooling allows
- final evidence report and App Review response draft
- no final submission click until explicit user approval

Verification goals:
- lint all shipped plists
- inspect actual archived `Atlas.app` and embedded extension `Info.plist` files
- verify App Store Connect build metadata matches the uploaded IPA and does not introduce any required capability beyond Apple-required `arm64`
- verify selected App Store Connect build is the new fixed build, not `2026050401`
- verify subscriptions, screenshots, privacy/support/legal metadata, review notes, and release mode before stopping

Evidence captured:
- rejected sanitized upload attempt proved App Store Connect error `90502`: 64-bit app/extension binaries must include `arm64`
- accepted upload artifact: `output/app-store-builds/export-2026050703-arm64/Atlas.ipa`
- accepted archive: `output/app-store-builds/Kairo-1.0-2026050703-arm64.xcarchive`
- local smoke screenshots: `output/app-store-builds/iphone-17-pro-max-2026050702-clean-launch.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-track-disclaimer.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-rating-primer-no-system-prompt.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-plan-ready-copy.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-trial-reminder.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-paywall.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-limited-preview-home.jpg`, `output/app-store-builds/iphone-17-pro-max-2026050702-limited-upgrade-prompt.jpg`, and `output/app-store-builds/iphone-17-pro-max-2026050702-limited-log-tab.jpg`
- App Store Connect build metadata for `1.0 (2026050703)` on 2026-05-07: Binary State `Validated`, Bundle Version `2026050703`, Bundle ID `com.dkang2000.Atlas`, Minimum iOS `17.0`, Supported Architectures `arm64`, Device Family `iPhone`, Required Capabilities `arm64`, `get-task-allow=false`
- App Store Connect subscriptions verified on 2026-05-07: monthly `com.dkang2000.Atlas.kairo.pro.monthly`, annual `com.dkang2000.Atlas.kairo.pro.annual`, and last-chance annual `com.dkang2000.Atlas.kairo.pro.annual.lastchance` all show `Waiting for Review`; monthly and annual have current introductory offers `Free for the first week` in 175 countries/regions; last-chance has no introductory offer
- App Store Connect privacy metadata verified on 2026-05-07: Privacy Policy URL `https://chloeverse.io/kairo/privacy`; product page preview lists collected data categories for Health & Fitness, Contact Info, Purchases, Identifiers, User Content, and Usage Data
- Privacy and EULA URLs returned HTTP `200` during local link checks

## Active milestone
### Android Native Clone + Google Play Launch
Depends on:
- current native iOS product under `atlas-ios/` remaining the shipped reference implementation
- Kairo staying a premium peptide/GLP protocol tracker, not a marketplace, medical advice app, AI chatbot, social app, or calorie tracker
- local-first and guest-first behavior carrying over to Android
- Supabase auth/sync/live review remaining additive to local storage
- Google Play Billing, Health Connect, Android widgets, notifications, and Play policy requirements being implemented with Android-native APIs

Status:
- planned on 2026-05-01
- decision: keep Android in this repo as `kairo-android/`
- decision: build native Android with Kotlin + Jetpack Compose, not React Native
- detailed plan: `docs/kairo-android-google-play-plan.md`
- release checklist: `docs/kairo-android-play-readiness-checklist.md`
- implementation started on 2026-05-01 with a native Android scaffold, local-first domain/persistence vertical slice, five-tab Compose shell, platform integration boundaries, and focused domain tests
- local workstation verification unblocked on 2026-05-01 by installing local JDK 17 + Android SDK 35 under `/Users/donghokang/.codex/android-toolchain/`
- `./gradlew testDebugUnitTest assembleDebug bundleRelease` passed on 2026-05-01; Android 15 emulator install/launch/screenshot QA also ran after more disk was freed
- `./gradlew testDebugUnitTest assembleDebug bundleRelease` passed again on 2026-05-02 after adding Room v3 sync metadata migration/relaunch persistence tests, widget projection storage/rendering, Supabase config/session boundary, Health Connect permission UI, BillingClient paywall architecture, richer protocol/log/progress/reminder surfaces, Today site-selection logging, and emulator-found scroll/inset fixes
- `./gradlew testDebugUnitTest assembleDebug bundleRelease` passed again on 2026-05-02 after the corrective iOS-parity UI pass: Today now uses the iOS-style Kairo momentum card plus compact Next Shot card/support rings, Progress adds range chips and front/side/back capture tiles, Companion adds quests and board-asset collections, Protocols gains compact inventory/calculator top actions, startup auth/session restore moved off the main thread, and the first app-owned launch frame renders before heavier app wiring

Will deliver:
- an Android-native clone of Kairo's core app and launch feature set
- five-tab Android shell matching the Kairo product model: Today, Log, Protocols, Progress, Companion
- local-first Android persistence with deterministic protocol, shot log, inventory, progress, and companion behavior
- limited preview gating and Pro upgrade prompts equivalent to iOS
- Google Play Billing products matching Kairo's subscription strategy
- Supabase-backed account/auth/sync/live review where appropriate
- Health Connect integration for explicit opt-in health data
- Android widgets and notification/reminder behavior that matches Kairo's privacy posture
- Google Play internal/closed testing readiness, store metadata, health declaration, data safety, privacy links, and production release checklist

Constraints:
- do not rewrite or downgrade the iOS SwiftUI app
- do not resurrect React Native as the primary app path
- do not add dosing advice, medical recommendations, sourcing, vendor comparison, marketplace, social, or chatbot behavior
- do not require cloud sign-in for core local tracking
- do not secretly map the $39.99 last-chance annual offer to the normal $59.99 annual product
- preserve current legal links:
  - Privacy Policy: `https://chloeverse.io/kairo/privacy`
  - Terms/EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` until Android-specific terms are approved

Execution order:
- create `kairo-android/` native Android scaffold
- port domain contract and persistence schema before broad UI polish
- implement the Kairo five-tab shell and limited preview route guard
- ship a vertical slice: onboarding, Today, Log Shot, Protocols, local SQLite/Room, and upgrade prompt
- add Google Play Billing and subscription entitlement state
- add Supabase account/auth/sync/live review
- add Progress, Companion, widgets, reminders, Health Connect, review/export, and settings
- run Play internal testing, then closed testing, then production readiness

Verification goals:
- Gradle clean build for debug and release app bundle
- unit tests for protocol scheduling, shot logging, inventory runway, limited preview gating, billing entitlement mapping, and export/import contracts
- Android emulator QA on phone and large-screen/tablet classes
- real-device QA for notifications, Health Connect, Google sign-in, billing sandbox, widgets, camera/photos, biometric/privacy gates, and file sharing
- Play Console checklist complete for app content, health declaration, data safety, subscriptions, privacy policy, support URL, signing, and testing tracks

Latest Android checkpoint:
- `kairo-android/` contains a Kotlin + Compose Android app using application ID `com.dkang2000.kairo`, compile/target SDK 35, Room, DataStore, Google Play Billing, Health Connect, Glance/AppWidget dependency, WorkManager, Android Keystore secure session storage, and Supabase client dependencies
- implemented local vertical slice: weekly GLP protocol creation, next-due projections separate from immutable timeline events, shot logging, vial decrement/runway labels, companion XP progression, entitlement state, and limited-preview upgrade gating
- implemented first-run onboarding entry, functional legal links in the upgrade prompt, notification-channel creation, and Android Photo Picker progress-evidence persistence
- implemented immutable skip/reschedule timeline actions for generated occurrences and fixed emulator-found status-bar/tab-label layout issues
- implemented Room v2 `integration_state` migration, repository relaunch persistence test coverage, and safe integration-state recording for billing/Health Connect
- implemented widget projection storage and AppWidget rendering backed by real local next-due/vial/companion state
- implemented Supabase build config and Android Keystore encrypted session boundary; Android now reads the existing iOS `Info.plist` Supabase URL/anon key by default with Gradle env/property overrides available
- implemented Supabase email/password sign-in, guest-to-account upgrade, sign-out, and bounded REST snapshot sync/restore messaging
- replaced the visible paywall debug path with BillingClient product loading/purchase/restore architecture; debug unlock remains debug-build-only
- added Health Connect availability and permission request UI in Companion settings
- added reminder alarm scheduling from occurrence projections with notification action receivers for taken/skipped responses
- added create/edit protocol forms for GLP, peptide, and custom protocols instead of only a starter action
- added compact and wide local projection widgets, plus Play internal release notes and store listing drafts
- added Data Safety draft, Health apps declaration notes, QA checklist, screenshot inventory, capture script, and draft Supabase Android snapshot SQL/RLS
- expanded protocol forms/actions with route, supply type, cadence weekday, pause/resume, and archive
- added Today site-selection logging, Log filtering/detail, reminder settings, progress evidence privacy/delete controls, and sync metadata failure tracking
- fixed emulator-found double top-inset and non-scrollable Companion settings regressions
- implemented five Android tabs matching the current Kairo launch shell: Today, Log, Protocols, Progress, Companion
- added Android product IDs `kairo.pro.monthly`, `kairo.pro.annual`, and separate `kairo.pro.annual.lastchance`; monthly/annual require a 7-day trial while last-chance does not
- added Android README with build/test commands, current official Play policy assumptions, legal links, and manual Play Console gates
- corrective UI parity pass on 2026-05-02 moved Android closer to `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/KairoMockupProtocolScreens.swift` instead of the earlier generic five-tab look: Today/Kairo now separates companion momentum from next-shot actions, Progress uses iOS board pose tiles, Companion exposes quests/badges/collectibles above account settings, and Protocols has compact iOS-like top tool chips
- latest emulator attempt on 2026-05-02 failed before ADB registration: `KairoPixel35` starts, then exits without appearing in `adb devices`; no fresh visual QA should be claimed for the latest corrective UI pass until an emulator or physical device is available
- visual parity workflow added on 2026-05-04: Android now has a debug Compose board for Today, Log Shot, Protocols, Progress, Companion, Upgrade, Protocol Form, Site Selection, and Account surfaces; named launch extras and `kairo-android/scripts/capture-visual-parity-board.sh` capture stable screenshots under `output/android-visual-parity/`, and `docs/android-visual-parity-workflow-2026-05-04.md` documents the iOS-reference comparison loop
- emergency Android UI correction on 2026-05-04: broad "visual parity" is no longer an acceptable standard. `docs/android-exact-ios-clone-directive.md` is now the controlling directive for Android UI work. Android must be an exact visual and interaction clone of the native iOS Kairo app unless the user explicitly approves a specific exception, and work must proceed one screen at a time with side-by-side iOS-vs-Android screenshot proof.

## Current direction
- Native iOS under `atlas-ios/` is the shipped primary iPhone product path and the source of truth for Android Kairo behavior/visual parity.
- Android work belongs in `kairo-android/` as native Kotlin + Jetpack Compose.
- Older React Native references below are historical and should not be treated as the current Android implementation path.
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
### Production sync + visual site map + broader passive signals
Depends on:
- existing account/auth/cloud scaffolding, Trust Vault boundaries, and local-first SQLite foundations already present in native Atlas
- current inventory/site tracking, metrics overlays, and HealthKit integration paths remaining deterministic and privacy-bounded
- native Today, Insights, Settings, import/export, and review surfaces staying additive to guest-first use instead of becoming cloud-required

Status:
- started on 2026-04-13

Will deliver:
- production-ready account sync flows on top of the current Supabase-backed session and export-bundle scaffolding, including clearer status, upload/download paths, and safer guest-upgrade handling
- a first-class visual body-map site picker layered onto the existing site tracking model so injection-site rotation is faster and more legible
- broader passive HealthKit ingestion for approved recovery/cardio/body-composition surfaces including steps, sleep, resting heart rate, HRV, blood pressure, and body-fat context where the platform exposes it
- native Insights and Settings surfaces that clearly distinguish passive health imports from manual/custom metrics

Constraints:
- preserve local-first and guest-first behavior even when cloud sync is enabled
- keep cloud scope bounded and additive; Atlas must remain usable without an account
- no medical advice, dosing recommendations, or causal health claims
- keep imported passive signals source-attributed and privacy-aware
- do not weaken Trust Vault, alias/discreet rendering, or review/export safety

Verification goals:
- `swift build` in `atlas-ios/Packages/AtlasPersistence`
- `swift build` in `atlas-ios/Packages/AtlasFeatures`
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`
- targeted simulator QA for account sync, visual site-map entry, Health connect/disconnect, passive-signal import, and insights/settings rendering

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

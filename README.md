# Atlas

Atlas is a privacy-first, local-first protocol tracker for injectables and adjacent routines.

The current product is a native iPhone app under `atlas-ios/`. It is no longer just a dose logger. The shipped native product combines protocol execution, immutable history, inventory, calculators, site tracking, bounded sharing, review outputs, progress evidence, weekly review, deterministic insights, optional nutrition context, optional labs, and optional cloud/account layers that remain additive to local-first use.

## Read This First

If you are opening this repo in a future thread, use this file as the repo-level current-state map.

When sources disagree, prefer them in this order:
1. native iOS code in `atlas-ios/`
2. `atlas-ios/README.md`
3. `docs/native-release-readiness.md` if present locally in your checkout
4. `docs/ios-architecture.md` if present locally in your checkout
5. `docs/privacy-security-spec.md` if present locally in your checkout
6. `docs/atlas-export-v1-spec.md` if present locally in your checkout
7. `PLANS.md`
8. older migration/history docs and legacy React Native material

Important: some older docs referenced by historical notes are not present in every local checkout. Do not treat missing files as current truth.

## What Atlas Is Building

Atlas is a serious personal operations app for protocol tracking. Its core product promise is:
- local-first by default
- guest-first by default
- explicit privacy controls
- immutable history
- descriptive, source-backed insights
- bounded sharing instead of social features

Atlas is intentionally not:
- a medical advice product
- a dosing recommendation engine
- a diagnostic tool
- a sourcing or marketplace app
- a broad social or community feed

## Current Product State

The native iPhone app is the primary product path.

Current native state in code:
- native parity is complete
- Universal Migration + Provider Handoff is complete
- Review Mode is complete
- progress evidence is complete
- Weekly Review exists in the native product
- deterministic insights and Episode Intelligence are complete
- optional account/auth/sync scaffolding is wired into the native app
- release readiness is still conditional on remaining physical-device and signed-release QA

The legacy React Native app remains in the repo only as:
- the product oracle for semantics
- the Android path
- the migration/export source

React Native Atlas is in feature freeze except for:
- critical bug fixes
- Atlas export-contract work required for migration
- Android-only stability fixes

## Repo Layout

- `atlas-ios/`
  - the real native Atlas app
  - Xcode project, targets, local Swift packages, and tests
- `atlas-ios/Packages/AtlasDomain`
  - domain models, product semantics, calculators, review, insights, nutrition, inventory, weekly review, watch companion support
- `atlas-ios/Packages/AtlasPersistence`
  - GRDB/SQLite persistence, repositories, import/export, metrics builders, review/export generation
- `atlas-ios/Packages/AtlasFeatures`
  - SwiftUI app shell and feature screens
- `atlas-ios/Packages/AtlasSystem`
  - HealthKit, notifications, biometrics, cloud sync, diagnostics
- `atlas-ios/Packages/AtlasPrivacy`
  - privacy rendering and Trust Vault formatting behavior
- `docs/`
  - handoff notes, UI audits, and product/design briefs
- `backend/`
  - Supabase migrations and functions for the additive cloud/review layer

## Native App Surface

The current native app is organized around five primary tabs plus focused feature routes.

### Core shell
- Today
- Timeline
- Library
- Insights
- Settings

### Today
Today is the operational center of the app. It is built around immediate next-step clarity.

Current Today capabilities:
- next due, overdue, and upcoming protocol visibility
- clear action buttons for `taken`, `skip`, `reschedule`, `protocol`, and `change plan`
- deterministic "Why this is due" explanations
- recovery handling for drift, missed events, and plan resets
- quick context access from the operational surface
- route handoff into protocol detail and Protocol Change Studio

### Timeline
- immutable event history
- separation between historical logs and generated future schedule occurrences
- visibility into taken, skipped, rescheduled, and supporting logs
- privacy-aware rendering under full, discreet, and alias modes

### Library
Library is more than a list of compounds. It is the planning and tools hub.

Current Library capabilities:
- protocol creation and editing
- protocol detail
- Protocol Change Studio
- inventory route
- calculator route
- compare and compound intelligence entry points
- protocol-level operational summaries

### Insights
Insights is the descriptive analysis layer of Atlas.

Current Insights capabilities:
- context logging
- weight logging
- symptom logging
- workout-aware insights
- custom metrics
- bounded plain-language recap cards
- deterministic explainability cards
- adherence trend summaries
- medication amount-in-system estimates
- Episode Intelligence
- nutrition targets, weekly nutrition signals, and coaching cards
- progress evidence entry point
- Weekly Review entry point
- optional rewards and mascot continuity surfaces

### Settings
Settings makes local-first and privacy behavior explicit.

Current Settings capabilities:
- account mode and onboarding state visibility
- optional cloud sign-in and account creation
- Trust Vault controls
- privacy render mode
- biometrics and privacy gating
- reminder controls and notification privacy modes
- Health connection state
- labs enablement
- rewards and continuity controls
- weekly review reminders
- import, review, and trust surfaces

## Feature Inventory

### Protocols and execution
- protocol creation
- protocol editing
- protocol detail
- support for GLP, peptide, and custom protocol kinds
- multiple administration route types
- multiple supply types
- daily, weekly, and interval scheduling
- titration/rest/base phase support
- missed-dose and recovery handling
- Protocol Change Studio for calm future-plan changes
- deterministic medication-level estimation for supported compounds
- compound intelligence and compare guidance

### Logging and quick capture
- shot logging
- weight logging
- symptom logging
- context logging
- hydration quick capture
- protein meal quick capture
- progress-photo quick capture
- one-thumb quick capture flows from the main shell
- reusable context presets
- recent meal reuse and common-food shortcuts

### Context and nutrition
Atlas does not try to be a full calorie-counting app. The current nutrition/context layer is intentionally lightweight and protocol-adjacent.

Current capabilities:
- meal timing
- meal size
- meal composition
- fed/fasted state
- appetite state
- hydration state
- GI tags
- reusable meal/context presets
- recent meal reuse
- built-in food lookup shortcuts
- daily protein, fiber, hydration, and workout-fueling targets/signals
- weekly coaching cards based on logged nutrition context
- freeform local parsing helpers in the domain layer for quick meal capture suggestions

### Inventory and calculators
- vial tracking
- consumable/supply tracking
- low-stock watch
- projected depletion support
- manual corrections
- procurement history for supplies
- protocol-to-vial linking
- calculator profiles
- reconstitution calculator
- site tracking
- site rotation support
- inventory movement history

### Privacy, review, and export
This is one of Atlas's strongest differentiators.

Current capabilities:
- Trust Vault
- full, discreet, and alias rendering modes
- biometric lock and gate support
- sensitive-action audit history
- raw JSON export
- raw CSV export
- selective share preview and export
- provider handoff preview and export
- Review Mode for bounded read-only review packs
- live review session scaffolding through the cloud layer
- privacy-aware exports and previews

### Import and migration
- Universal Migration
- provider handoff
- import/export bridge
- restore-point and migration-safe infrastructure in persistence
- Atlas JSON as canonical migration/export truth

### Weekly Review and summaries
- dedicated Weekly Review route
- weekly review seed generation from actual app data
- highlights, shifts, and source facts
- next-action generation
- action plans
- reminder settings
- export pack generation for weekly review
- weekly review history/comparison support in the domain layer

### Progress evidence
- private progress-photo tracking
- guided recapture support
- same-angle compare support
- milestone timeline browsing
- progress measurements
- private summary export generation

### Rewards and mascot continuity
- optional rewards system
- streaks
- badges
- self-defined goal support
- workout goal support
- optional mascot continuity layer
- mascot recap/archive/export support

### Clinical and advanced tracking
- optional labs mode
- starter lab panels
- custom lab marker creation through custom metrics
- medication level studio
- provider-facing orientation in product language

### Platform integrations
- local notifications and reminder actions
- WidgetKit extension
- App Intents / Shortcuts extension
- quick-capture deep links
- progress-evidence deep links
- Apple Health integration
- optional cloud auth/sync scaffolding
- additive watch companion handoff surface in-app

## Current Health + Cloud Scope

### Apple Health
Current HealthKit implementation is intentionally bounded.

What is in scope now:
- explicit opt-in connection
- weight import/export behavior
- workout ingestion into insights
- visible connection state in Settings

What is not the current core model:
- making Health required for Atlas
- replacing local logging with passive sync
- broad "quantified self" behavior that overwhelms the core protocol workflow

### Cloud/account layer
The cloud layer is additive, not foundational.

Current cloud/account intent:
- optional account boundary
- backup/recovery/cross-device continuity path
- live review session support
- account auth providers in the native app

Core rule:
- Atlas must still make sense as a local-first app even when the cloud layer is unused or unavailable

## Live Product Notes From The Current Native App

The running native app currently exposes, at minimum, these visible routes or surfaces:
- Today
- Timeline
- Library
- Insights
- Settings
- Inventory
- Calculator
- Trust Vault
- Review Mode
- Weekly Review
- Progress Evidence
- Labs
- Medication Level
- Apple Watch companion screen

## Build And Verification

Primary native build/test commands live in `atlas-ios/README.md`.

High-signal commands:
- Debug simulator build:
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`
- Release simulator build:
  - `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`
- Full native tests:
  - `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

Manual release/beta checklist:
- `qa/native-ios-release-manual-checklist.md`

## Notes For Future Threads

- Treat `atlas-ios/` as the real app.
- Do not assume legacy React Native files represent the future iPhone architecture.
- Do not add medical advice, dose recommendations, diagnostics, or sourcing flows.
- Preserve local-first, guest-first, immutable history, and bounded privacy behavior.
- If you need to understand current user-facing scope quickly, this README plus `atlas-ios/README.md` should be enough to orient you before diving into code.

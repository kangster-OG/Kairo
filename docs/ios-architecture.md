# Atlas iOS Architecture

## Current architecture status
This document reflects the current native Atlas architecture, not the earlier shell-only phases.

Native Atlas is an iPhone-first SwiftUI app with a local-first GRDB/SQLite core, explicit privacy rendering, deterministic import/export, and bounded extension projections.

## Core principles
- local-first source of truth
- guest-first behavior preserved
- immutable historical logs remain separate from generated future schedule occurrences
- privacy rendering remains explicit, deterministic, and surface-aware
- React Native remains the semantic oracle and Android path, not the primary iOS codebase

## Module structure
`atlas-ios/Packages/` contains:
- `AtlasDesignSystem`
  - theme, typography, spacing, cards, buttons, visual primitives
- `AtlasDomain`
  - explicit domain models for core loop, inventory, trust, migration, review, and episode logic
- `AtlasPersistence`
  - GRDB database setup, migrations, repositories, import/export, reminders, projections
- `AtlasPrivacy`
  - full/alias/discreet rendering policy
- `AtlasSystem`
  - notifications, biometrics, Health scaffold, feature flags, import/export protocols
- `AtlasFeatures`
  - SwiftUI app model, navigation shell, and feature surfaces

The `Atlas` app target owns:
- app bootstrap
- dependency wiring
- launch failure fallback UI
- scene creation

## Persistence model
- Canonical source of truth: app-local SQLite via GRDB.
- Deterministic migrations define the schema over time.
- Historical log events are immutable records.
- Future schedule occurrences are generated projections and can be regenerated.
- Inventory state is derived from durable state plus explicit adjustment events.

## Shared projection strategy
- Extensions do not read the canonical database directly.
- App-group-safe projection data is written separately for widgets/intents-safe read models.
- Shared read models remain privacy-safe and narrower than canonical app data.

## Privacy architecture
- Full mode shows canonical labels.
- Alias mode shows user-defined aliases/codenames where appropriate.
- Discreet mode suppresses sensitive labels with generic copy.
- Notifications, exports, selective shares, provider handoff, review packs, and episode surfaces all use the same privacy policy layer.

## System boundaries
- UserNotifications drives local reminder delivery and actions.
- LocalAuthentication gates sensitive Trust Vault actions.
- Health connections are scaffold-only and non-blocking.
- Import/export is transactional, versioned, and dry-run-first where relevant.

## Release posture
- Native builds and tests are green in CI-like local verification.
- Remaining release risk is operational rather than architectural:
  - physical-device QA
  - signed archive/TestFlight smoke

For release details, see `docs/native-release-readiness.md`.

# Atlas

Atlas is a local-first, privacy-first tracker for injectable routines.

The current product is primarily a native iPhone app under `atlas-ios/`. The legacy React Native app remains in the repo as:
- the product oracle for semantics
- the Android path
- the migration/export source

React Native Atlas is frozen except for:
- critical bug fixes
- Atlas export-contract fixes required for migration
- Android-only stability fixes

## Current status
- Native parity is complete in code.
- Universal Migration + Provider Handoff is complete in code.
- Review Mode is complete in code.
- Episode Intelligence is complete in code.
- Final release hardening is complete in code.
- Release readiness is currently `CONDITIONAL` pending physical-device QA and signed TestFlight smoke.

See:
- [atlas-ios/README.md](atlas-ios/README.md)
- [docs/native-release-readiness.md](docs/native-release-readiness.md)
- [PLANS.md](PLANS.md)

## Repo layout
- `atlas-ios/`
  - native iOS app, local Swift packages, Xcode project, tests
- `src/`, `app/`, Expo config
  - legacy React Native app and Android path
- `docs/`
  - architecture, privacy, export spec, migration history, release docs
- `qa/`
  - manual QA scripts and release checklists

## Source of truth order
When repo docs disagree, use this order:
1. native iOS code in `atlas-ios/`
2. `atlas-ios/README.md`
3. `docs/native-release-readiness.md`
4. `docs/ios-architecture.md`
5. `docs/privacy-security-spec.md`
6. `docs/atlas-export-v1-spec.md`
7. `PLANS.md`
8. older migration/history docs and legacy RN docs

## Native product surface
The native app currently includes:
- onboarding and guest/account boundary
- Today, Timeline, Library, Insights, and Settings
- protocol creation/edit
- Protocol Change Studio
- local reminders and quick logging
- immutable history
- inventory, vials, depletion, and manual corrections
- reconstitution calculator and saved profiles
- site tracking
- Trust Vault, alias/discreet rendering, and biometric gating
- selective sharing and raw exports
- universal import and provider handoff
- Review Mode
- metrics, custom metrics, and insights
- deterministic Episode Intelligence

## Build and verification
Primary native build/test instructions live in:
- [atlas-ios/README.md](atlas-ios/README.md)

Primary manual beta checklist lives in:
- [qa/native-ios-release-manual-checklist.md](qa/native-ios-release-manual-checklist.md)

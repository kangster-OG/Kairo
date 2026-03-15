# Atlas agent instructions

## Read first
Before making changes, read:
1. `README.md`
2. `PLANS.md`
3. `atlas-ios/README.md`
4. `docs/native-release-readiness.md`
5. `docs/ios-architecture.md`
6. `docs/privacy-security-spec.md`
7. `docs/atlas-export-v1-spec.md`

Use the native iOS codebase plus those docs as the primary source of truth.

## Source-of-truth rule
If repo docs disagree, use this order:
1. native iOS code under `atlas-ios/`
2. `atlas-ios/README.md`
3. `docs/native-release-readiness.md`
4. `docs/ios-architecture.md`
5. `docs/privacy-security-spec.md`
6. `docs/atlas-export-v1-spec.md`
7. `PLANS.md`
8. legacy migration/history docs
9. legacy React Native docs

Do not treat older migration docs, the legacy Expo root, or empty placeholder docs as higher-authority than the current native product.

## Product summary
Atlas is a privacy-first protocol tracker for injectables, reminders, logging, inventory, calculators, sites, Trust Vault privacy controls, bounded sharing, review outputs, and deterministic pattern insights.

This app must not include:
- dosing advice
- medical recommendations
- diagnostic or treatment claims
- sourcing or marketplace flows

## Current product state
- Native iOS is the primary product path.
- React Native Atlas remains the product oracle, Android path, and migration/export source.
- Native parity and the currently planned second-order features are complete in code.
- Release readiness is conditional on physical-device QA and signed TestFlight smoke.

## Stack
### Primary iOS stack
- SwiftUI
- Swift Observation patterns
- GRDB + SQLite
- local app-group projection store
- UserNotifications
- LocalAuthentication
- WidgetKit/App Intents scaffolding

### Legacy/oracle stack
- React Native + Expo + TypeScript

## Freeze policy
- React Native Atlas is in feature freeze except for:
  - critical bug fixes
  - Atlas Export contract improvements required for native migration
  - Android-only stability fixes
- Native iOS is the primary product path.

## Engineering rules
- Preserve local-first behavior.
- Preserve guest-first behavior.
- Never mix generated future schedule occurrences with immutable historical log events.
- Never silently remove privacy, alias, discreet, Trust Vault, or audit behavior.
- Keep exports/imports deterministic and versioned.
- Keep sharing least-privilege, preview-first, and explicit.
- Keep Episode Intelligence deterministic and descriptive only.

## Scope rules
- Do not add medical advice, dose recommendations, or sourcing flows.
- Do not resume paused second-order features unless explicitly requested and approved.
- Do not treat the React Native app as the future primary iOS codebase.
- Do not overwrite or delete the React Native app when working on native iOS.

## Planning rule
For tasks spanning multiple feature areas or broad architecture/doc changes, update `PLANS.md` first unless the user explicitly asks to skip planning.

## Done when
A task is only done when:
- the relevant code or docs are updated
- build/test expectations are checked or explicitly documented
- changed files are summarized
- risks/blockers are called out clearly

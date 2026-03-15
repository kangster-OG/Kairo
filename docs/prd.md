# Atlas Product Requirements Document

## Status
This PRD reflects the current native Atlas product in the repo as of 2026-03-14.

Atlas is no longer an onboarding prototype or an early migration shell. The native iOS app is feature-complete relative to the current roadmap, with release readiness pending final device/TestFlight verification.

## Product definition
Atlas is a local-first, privacy-first tracker for injectable routines. It helps users manage real-world protocol complexity without requiring cloud sync.

Atlas must not provide:
- dosing advice
- medical recommendations
- diagnostic or treatment claims
- sourcing or marketplace behavior

## Primary product path
- Native iOS under `atlas-ios/` is the primary iOS product path.
- React Native Atlas remains:
  - the oracle for product semantics
  - the Android path
  - the migration/export source

## Operating principles
- local-first by default
- guest-first by default
- immutable historical logs
- generated future schedule occurrences remain separate from immutable history
- privacy rendering is explicit and surface-aware
- cloud sync is optional and additive
- imports and shares are dry-run-first and least-privilege-first

## Implemented native product surface
### Core shell
- onboarding
- guest/account boundary
- Today
- Timeline
- Library
- Insights
- Settings

### Core loop
- protocol list/detail
- protocol creation/edit for core fields
- revision-aware schedule generation
- due/overdue/upcoming states
- quick logging for taken/skipped/rescheduled
- immutable timeline/history
- native local reminder parity

### Library and support workflows
- inventory and vials
- vial linking and switch-over
- low-stock and projected depletion
- manual inventory correction with audit history
- reconstitution calculator with saved profiles
- site tracking and rotation cues

### Advanced protocol behavior
- Protocol Change Studio
- preview-before-commit
- future-only edits
- pause/resume
- titration and rest period logic
- timezone/travel handling
- missed-dose policy changes
- vial handoff planning

### Privacy and trust
- Trust Vault
- full / alias / discreet rendering
- alias/codename management
- biometric gating for sensitive actions
- selective sharing
- raw JSON and CSV exports
- sensitive-action audits

### Migration and bounded outputs
- Atlas Export v1 import
- universal migration/import center
- provider handoff
- Review Mode

### Wellness and insights
- weight logging
- symptom logging
- custom metric logging and management
- native insights and charts
- amount-in-system estimate with disclaimer language
- deterministic Episode Intelligence

## Current release posture
- automated native builds are green
- automated native tests are green
- release builds compile
- release readiness is currently conditional on:
  - physical-device QA
  - signed TestFlight archive/upload smoke

See:
- `docs/native-release-readiness.md`
- `qa/native-ios-release-manual-checklist.md`

## Source-of-truth note
If this PRD disagrees with current native code, prefer the native code plus:
- `atlas-ios/README.md`
- `docs/native-release-readiness.md`
- `docs/ios-architecture.md`
- `docs/privacy-security-spec.md`
- `docs/atlas-export-v1-spec.md`

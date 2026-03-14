# Atlas Native iOS Migration Plan

## Summary
Atlas now has a real local-first React Native beta, not just an onboarding prototype. The native iOS app should be built in parallel under `atlas-ios/` while the React Native app remains:
- the product oracle
- the Android path
- the migration/export source

Phase 1 is foundation only. It establishes the native app shell, module boundaries, and extension scaffolding without porting the full product logic yet.

## Current React Native product surface
Implemented in the React Native app today:
- onboarding with privacy and track-type branching
- guest/account boundary
- Today, Timeline, Library, Insights, and Settings shell
- protocol creation
- weekly and every-N-days scheduling
- quick logging for taken, skipped, and rescheduled actions
- immutable log events
- reminders with privacy-aware copy
- inventory, vials, low-stock thresholds, and manual corrections
- site tracking
- calculator profiles
- weight, symptom, and custom metrics
- insights
- exports
- Trust Vault, aliases, selective sharing, and privacy audits

## Port first
- app shell and navigation
- local module boundaries and DI
- native persistence boundary
- Atlas Export import bridge
- protocols, revisions, schedule/day loop
- reminders and quick logging
- inventory, calculator, and site tracking
- Timeline and Insights
- Trust Vault and selective sharing

## Port later
- sync execution
- provider handoff
- review mode
- episode intelligence
- richer HealthKit behavior
- ActivityKit implementation beyond scaffold review

## Phase sequence
### Phase 1
- native project and targets
- local Swift packages
- SwiftUI shell
- settings and Trust Vault shells
- extension and system scaffolds

### Phase 2
- GRDB persistence
- Atlas Export v1 staging and import bridge
- first data-backed native screens

### Later parity phases
- schedule/day loop parity
- reminders/logging parity
- inventory/calculator/site parity
- Trust Vault/export parity

## Freeze rule
No new second-order feature work should resume until native parity through Trust Vault is complete.

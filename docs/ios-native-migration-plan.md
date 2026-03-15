# Atlas Native iOS Migration Plan

## Current state
This document is now primarily a migration history and status record.

The migration from a React Native beta app to a native iPhone-first Atlas product has already been executed in code. Native parity and the currently planned second-order features are complete in the repo.

## Strategic result
- React Native Atlas remains:
  - the product oracle
  - the Android path
  - the migration/export source
- Native iOS under `atlas-ios/` is the primary iOS product path.

## What was migrated
Native Atlas now includes:
- onboarding and guest/account boundary
- Today, Timeline, Library, Insights, and Settings
- protocol creation/edit
- revision-aware schedule/day-loop behavior
- local reminders
- quick logging and immutable history
- inventory, vials, calculator profiles, and site tracking
- Protocol Change Studio
- Trust Vault and selective sharing
- raw exports
- universal import and provider handoff
- Review Mode
- metrics and custom metrics
- deterministic Episode Intelligence

## Migration architecture that remains in force
- React Native semantics remain the oracle when native behavior is questioned.
- Atlas JSON export remains the canonical migration-grade interchange format.
- Local-first SQLite/GRDB remains the native source of truth.
- Shared projection data remains separate from the canonical store for extensions.
- Historical logs remain immutable.

## Remaining migration-era work
The remaining work is not feature migration. It is release and operational hardening:
- physical-device QA
- TestFlight archive/upload smoke
- documentation truth-alignment
- beta rollout discipline

## Historical note
Earlier versions of this document described Phase 1 shell work, Phase 2 persistence, and later parity phases. Those phases are complete and should no longer be interpreted as the current native product status.

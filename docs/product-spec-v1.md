# Atlas Product Spec v1

## Status and intent
Atlas is now a local-first, privacy-first beta for injectable routine tracking. The implemented surface today includes:
- first-run onboarding with privacy and track-type branching
- a real post-onboarding app shell
- protocol creation
- generated next-due and upcoming schedule views
- Today and Timeline daily-use loop
- local reminders with discreet-mode behavior
- inventory, vials, calculator profiles, and optional site tracking
- insights, exports, guest mode, and auth/sync foundations

The next moat-building phases are:
- safe protocol change handling
- Trust Vault + Selective Sharing

Both phases must preserve local-first behavior, immutable historical truth, and guest-mode usability.

## Product positioning
Atlas helps users stay organized around injectable routines with:
- protocol setup
- next due visibility
- reminders
- logging
- inventory awareness
- timeline/history
- lightweight insights

Atlas must not include:
- dose recommendations
- medical advice
- diagnostic or treatment claims
- sourcing or marketplace flows

## Core retention loop
The v1 retention loop is:

`protocol -> next due -> reminder -> log -> inventory -> timeline -> insight`

Meaning:
- the user defines one or more protocols
- Atlas computes the next due occurrence
- Atlas reminds the user at the right time
- the user logs what actually happened
- Atlas updates inventory from the log
- Atlas shows the history in a timeline
- Atlas derives simple, non-medical insights from logged behavior

## User modes
### Guest mode
- first-class mode
- fully usable without account creation
- all core MVP behavior must work locally
- no cloud dependency in the live loop

### Cloud account mode
- deferred until after the local-first MVP
- used for optional sync, backup, and multi-device continuity
- must not be required to use the core product

## Current app baseline
The current codebase accurately supports:
- routed onboarding screens with progress and persistence
- guest-first app shell with `Today`, `Timeline`, `Library`, `Insights`, and `Settings`
- protocol creation for GLP, peptide, and custom compounds
- local schedule generation for weekly and every-`N`-days cadence
- quick dose logging from Today
- immutable log events for taken, skipped, rescheduled, and inventory-adjustment actions
- local reminders with privacy-aware copy
- vial linking, depletion tracking, low-stock state, and manual corrections
- site tracking and optional site rotation
- reconstitution calculator with saved profiles
- weight, symptom, and custom metric logging
- descriptive insights and local exports
- guest mode, auth scaffolding, and additive sync foundation

The current codebase does not yet support:
- safe effective-dated protocol revision workflows
- preview-before-commit protocol changes
- robust pause/resume, titration, and rest-period editing
- travel/timezone-aware protocol editing
- vial switch-over planning
- full cloud sync execution
- production-certified iOS runtime QA

## Real MVP scope
### Included
- local protocol setup
- local schedule generation
- next due surface on Today
- local notifications/reminders
- immutable log events
- inventory tracking from manual setup plus log-driven decrements
- timeline/history
- simple insights based on logged behavior
- privacy/discreet mode behavior

### Excluded
- dosage advice or optimization
- treatment recommendations
- provider workflows
- sourcing or shopping
- social/community features
- cloud-required functionality

## MVP surfaces after onboarding
### Today
Primary daily hub. Shows:
- next due item
- overdue state
- quick log CTA
- reminder status
- low inventory warning
- latest timeline events

### Protocols
User-managed definitions of what they are tracking. Supports:
- GLP protocols
- peptide protocols
- custom compound protocols
- multiple protocols over time
- active, paused, archived states

Next phase:
- Protocol Change Studio for future-only edits, pause/resume, titration, rest periods, timezone changes, vial handoff planning, and preview-before-commit behavior

### Trust Vault
Privacy control center for:
- discreet mode and alias mode
- biometric gating for sensitive actions
- selective sharing previews and encrypted bundles
- user-visible sensitive-action audit history

Trust Vault is not a marketing/settings page. It is the operational surface for privacy policy, bounded sharing, and user trust.

### Log
Fast way to record what actually happened. Logging is event-based and immutable.

### Inventory
Tracks remaining supply and expected runout based on logged usage and manual adjustments.

### Timeline
Chronological history combining:
- generated schedule occurrences
- completed logs
- skipped logs
- inventory events
- reminder events when useful

### Insights
Small, descriptive summaries only, for example:
- streaks
- completion rate
- missed vs logged counts
- inventory runway estimate

No insight should cross into medical recommendation territory.

## Information hierarchy priorities
1. Next due
2. Log action
3. Inventory state
4. Timeline context
5. Insights summary

## Data model principles
- Protocol definitions are durable user-authored records.
- Protocol identity must remain stable across future changes.
- Effective-dated protocol revisions should control future schedule generation.
- Future schedule occurrences are generated records, not source-of-truth records.
- Log events are immutable and represent what actually happened.
- Inventory changes should be reconstructable from event history plus explicit adjustments.

## Storage model
### AsyncStorage stays responsible for
- onboarding draft state
- lightweight UI preferences
- non-relational feature flags
- small session and presentation preferences

### Database layer becomes responsible for
- protocol definitions
- generated occurrence cache
- immutable log events
- inventory lots or balances
- reminder jobs and history
- timeline feed records or query materialization
- insight snapshots if needed for performance

### SecureStore becomes responsible for
- auth tokens
- device secrets
- future biometric unlock keys or encrypted-key references

## Privacy model direction
Atlas privacy must be explicit and surface-aware.

### Current baseline
- discreet notifications exist
- sensitive labels can be hidden in several app surfaces
- reminder privacy already supports full-detail, generic, and silent-oriented modes

### Next phase
- add protocol alias / codename mode
- centralize privacy rendering policy for:
  - Today
  - Timeline
  - Library
  - Insights
  - Settings
  - notifications
  - exports and selective sharing
- add Trust Vault as the user-facing privacy control center
- add bounded selective sharing with preview-before-export
- add local encrypted share bundles with manifest versioning
- add visible audit history for sensitive actions

## Health integrations
Health app connection remains:
- late in onboarding
- optional
- additive, not required

No health integration should block the core local-first MVP.

## Success criteria for the next phase
- a guest user can finish onboarding and create a real protocol
- Today shows a real next due item
- the app can remind locally
- the user can log an occurrence
- inventory updates after logging
- timeline reflects reality
- the app offers basic non-medical insights

## Success criteria for Trust Vault + Selective Sharing V1
- a guest or signed-in user can enable alias mode without corrupting underlying data
- privacy rendering is consistent across core surfaces
- a user can preview a bounded share/export scope before commit
- exported/share bundles contain only the selected scope
- bundles can be encrypted locally
- sensitive actions appear in a visible audit trail
- biometric gating protects sensitive actions where the device supports it
- no cloud account is required for any V1 privacy or sharing flow

## Next six implementation milestones
1. Protocol setup and local database foundation
2. Schedule engine and next due computation
3. Reminder pipeline and discreet notification behavior
4. Logging flow and inventory mutation rules
5. Timeline and insight surfaces
6. Optional auth and sync foundation

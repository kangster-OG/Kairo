# Atlas Product Spec v1

## Status and intent
Atlas is now a local-first, privacy-first native iPhone product with the current roadmap implemented in code.

The implemented surface today includes:
- first-run onboarding with privacy and track-type branching
- guest/account boundary
- Today, Timeline, Library, Insights, and Settings
- protocol creation/edit plus Protocol Change Studio
- generated next-due, overdue, and upcoming schedule views
- local reminders with privacy-aware behavior
- immutable log history
- inventory, vials, calculator profiles, and site tracking
- Trust Vault, selective sharing, raw exports, and sensitive-action audits
- universal import, provider handoff, and Review Mode
- metrics, custom metrics, and deterministic Episode Intelligence

Current near-term work is release hardening, device QA, and beta rollout discipline, not filling major product-surface gaps.

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
- optional and additive
- never required for the core product
- full sync execution remains intentionally incomplete by design

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

The current codebase intentionally still defers:
- full cloud sync execution
- richer HealthKit behavior beyond the current scaffold
- expanded widget/App Intents business logic beyond the current compile-ready scaffolding

The current release process still requires:
- physical-device QA
- signed TestFlight/archive smoke

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

Includes:
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
Small, descriptive summaries only, including:
- weight trend
- symptom trend
- adherence trend
- inventory burn-down
- amount-in-system estimate with disclaimers
- deterministic Episode Intelligence summaries

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
### Native local source of truth
- GRDB + SQLite stores protocol definitions, effective-dated revisions, generated future occurrences, immutable logs, inventory state, reminders state, metrics, privacy state, selective-share/export metadata, review metadata, and episode-analysis inputs
- app-group projection storage remains separate from the canonical database for extension-safe read models

### Lightweight local preferences
- onboarding completion state
- non-sensitive presentation preferences
- feature flags that do not belong in the canonical product database

### Protected local storage
- auth/session tokens when present
- device secrets
- biometric-gate key references and other sensitive local credentials

## Privacy model
Atlas privacy is explicit and surface-aware.

### Current baseline
- full, alias, and discreet rendering modes exist natively
- reminder privacy supports detailed, generic, and quiet/silent-safe behavior
- privacy rendering is centralized across Today, Timeline, Library, Insights, Settings, notifications, exports, provider handoff, and Review Mode
- Trust Vault is the user-facing privacy control center
- selective sharing is preview-first, bounded, encrypted, and versioned
- sensitive actions write visible audit history

## Health integrations
Health app connection remains:
- late in onboarding
- optional
- additive, not required

No health integration should block the core local-first MVP.

## Current release criteria
- a guest or imported user can complete or bypass onboarding appropriately
- Today, Timeline, Library, Insights, and Settings all render correctly
- reminders, Trust Vault, sharing, provider handoff, Review Mode, and Episode Intelligence remain privacy-safe
- import/export paths remain deterministic and transactional
- immutable history remains intact
- final physical-device QA and TestFlight smoke pass before broader beta

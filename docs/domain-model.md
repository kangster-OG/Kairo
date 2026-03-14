# Atlas Domain Model

## Modeling principles
- Durable user-authored entities are distinct from generated entities.
- Immutable event records represent reality.
- Derived or generated records can be rebuilt.
- Privacy-sensitive boundaries are explicit.
- Local-first storage is the default.

## Core entities
### OnboardingProfile
Purpose:
- captures first-run setup choices
- seeds defaults and UI behavior

Current status:
- implemented
- stored locally in AsyncStorage

Key fields:
- `accountMode`
- `privacy`
- `trackType`
- `profile`
- `glp`
- `peptide`
- `healthConnectionPromptSeen`

### UserProfile
Purpose:
- ongoing profile and preference state after onboarding

Planned fields:
- `displayName?: string`
- `accountMode`
- `privacySettings`
- `notificationSettings`
- `preferredUnits`
- `healthConnections`
- `trustVaultSettings`

Storage:
- database layer for durable profile state
- SecureStore for auth/token material when applicable

### ProtocolDefinition
Purpose:
- describes what the user intends to follow
- stable identity for schedule generation and future revisions

Key fields:
- `id`
- `kind: 'glp' | 'peptide'`
- `name`
- `status: 'active' | 'paused' | 'archived'`
- `compoundId?`
- `timezone`
- `createdAt`
- `updatedAt`
- `alias?`
- `aliasEnabled`

Rules:
- stable user-facing identity
- should not hold every future edit inline
- current future behavior should be resolved through effective-dated revisions
- alias/codename presentation should be treated as a rendering concern over stable protocol identity, not a replacement for canonical stored names

### PrivacyProfile
Purpose:
- durable privacy and sharing policy state after onboarding
- source of truth for cross-surface privacy rendering

Planned fields:
- `id`
- `aliasModeEnabled`
- `biometricLockEnabled`
- `biometricGateMode: 'off' | 'best_effort' | 'required_when_available'`
- `discreetNotifications`
- `hideSensitiveLabels`
- `shareAliasByDefault`
- `exportAliasByDefault`
- `lastUnlockedAt?`
- `createdAt`
- `updatedAt`

Rules:
- replaces scattered privacy conditionals over time
- may seed from onboarding privacy choices, but becomes the durable post-onboarding source of truth
- remains local-first in v1

### ProtocolAlias
Purpose:
- user-authored codename for a protocol and its attached compound presentation

Planned fields:
- `id`
- `protocolId`
- `aliasLabel`
- `aliasCompoundLabel?`
- `createdAt`
- `updatedAt`
- `archivedAt?`

Rules:
- canonical protocol and compound names remain stored separately
- alias mode changes presentation only
- turning alias mode off restores full local labels without data migration

### ProtocolRevision
Purpose:
- effective-dated snapshot that governs future schedule generation
- safe boundary for future-only edits

Planned fields:
- `id`
- `protocolId`
- `revisionNumber`
- `effectiveFrom`
- `effectiveTo?`
- `lifecycleState: 'active' | 'paused' | 'resting'`
- `timezone`
- `timezoneStrategy: 'keep_local_clock' | 'keep_home_timezone'`
- `defaultTimeOfDay?`
- `doseAmount?`
- `doseUnit?`
- `linkedVialId?`
- `missedDosePolicy: 'skip_and_continue' | 'take_now_keep_cadence' | 'take_now_shift_future'`
- `notes?`
- `createdAt`
- `updatedAt`

Rules:
- append-only in practice
- future edits create a new revision instead of mutating past committed behavior
- does not store generated future instances inline

### ProtocolRevisionRule
Purpose:
- describes cadence or phase behavior inside a specific protocol revision

Planned fields:
- `id`
- `revisionId`
- `phaseType: 'base' | 'titration' | 'rest'`
- `phaseOrder`
- `ruleType: 'weekly' | 'daily' | 'every_n_days'`
- `intervalCount`
- `weekday?`
- `timeOfDay?`
- `anchorDate?`
- `phaseStartDayOffset`
- `phaseLengthDays?`
- `doseAmountOverride?`
- `doseUnitOverride?`
- `createdAt`
- `updatedAt`

Rules:
- revision rules define future phases only
- titration and rest periods are represented as explicit deterministic phases
- generated occurrences are derived from the active revision plus its rules

### ProtocolChangeAuditEvent
Purpose:
- immutable record of what changed in Protocol Change Studio

Planned fields:
- `id`
- `protocolId`
- `revisionId`
- `previousRevisionId?`
- `changeType`
- `effectiveFrom`
- `createdAt`
- `summary`
- `payloadJson`

Rules:
- separate from dose log history
- append-only
- suitable for Timeline/history rendering

### SensitiveActionAuditEvent
Purpose:
- immutable user-visible record of privacy-sensitive actions

Planned fields:
- `id`
- `eventType: 'export_created' | 'selective_share_created' | 'alias_changed' | 'privacy_mode_changed' | 'biometric_lock_changed' | 'vault_unlocked'`
- `surface`
- `scopeType?`
- `protocolId?`
- `manifestVersion?`
- `payloadJson`
- `createdAt`

Rules:
- separate from clinical/history logs
- append-only
- user-visible in Trust Vault
- should avoid leaking raw sensitive labels when alias mode is active

### ScheduleOccurrence
Purpose:
- generated future or historical occurrence derived from a protocol revision

Key fields:
- `id`
- `protocolId`
- `revisionId`
- `scheduledFor`
- `windowStart?`
- `windowEnd?`
- `state: 'upcoming' | 'due' | 'completed' | 'missed' | 'skipped' | 'superseded'`
- `generatedAt`
- `generatorVersion`

Rules:
- generated, not user-authored
- rebuildable from protocol revisions plus log events
- may be cached in the database layer for performance

### LogEvent
Purpose:
- immutable record of what the user says actually happened

Key fields:
- `id`
- `protocolId`
- `occurrenceId?`
- `eventType: 'completed' | 'skipped' | 'manual_log' | 'inventory_adjustment'`
- `eventType: 'completed' | 'skipped' | 'rescheduled' | 'manual_log' | 'inventory_adjustment'`
- `loggedAt`
- `effectiveAt`
- `quantity?`
- `quantityUnit?`
- `notes?`
- `source: 'user' | 'migration' | 'system'`

Rules:
- immutable after creation except for soft-delete or audit-safe correction patterns
- source of truth for history
- should never be overwritten by regenerated schedule data

### InventoryItem
Purpose:
- current supply state for a tracked item

Key fields:
- `id`
- `protocolId?`
- `name`
- `unit`
- `startingQuantity`
- `currentQuantity`
- `reorderThreshold?`
- `lastUpdatedAt`

Rules:
- current balance may be materialized
- must remain derivable from starting quantity plus ledger events

### InventoryLedgerEvent
Purpose:
- immutable inventory history

Key fields:
- `id`
- `inventoryItemId`
- `changeType: 'add' | 'consume' | 'adjust'`
- `delta`
- `effectiveAt`
- `linkedLogEventId?`
- `notes?`

### ReminderRule
Purpose:
- user-facing reminder configuration tied to one or more protocols

Key fields:
- `id`
- `protocolId`
- `offsetMinutes`
- `channel: 'local_notification'`
- `isEnabled`
- `discreetCopyEnabled`

### SelectiveShareBundle
Purpose:
- deterministic, bounded local snapshot for export/share

Planned fields:
- `manifestVersion`
- `bundleId`
- `createdAt`
- `scope`
- `aliasModeApplied`
- `encrypted`
- `integrity`
- `payload`

Rules:
- bundle is a static snapshot, never a live linked view
- bundle contents must exactly match the previewed scope
- encryption metadata and manifest version must be explicit
- bundle generation should not require cloud access

### InsightSnapshot
Purpose:
- cached descriptive metrics for quick rendering

Key fields:
- `id`
- `period`
- `completionRate`
- `streakCount`
- `missedCount`
- `inventoryRunoutEstimate?`
- `generatedAt`

Rules:
- derived from log and inventory history
- no clinical interpretation

## Entity relationships
- `UserProfile` owns many `ProtocolDefinition`
- `UserProfile` owns one `PrivacyProfile`
- `ProtocolDefinition` owns many `ProtocolRevision`
- `ProtocolDefinition` optionally owns one active `ProtocolAlias`
- `ProtocolRevision` owns many `ProtocolRevisionRule`
- `ProtocolRevision` generates many `ScheduleOccurrence`
- `ProtocolDefinition` has many `LogEvent`
- `ProtocolDefinition` has many `ProtocolChangeAuditEvent`
- `ProtocolDefinition` may be referenced by many `SensitiveActionAuditEvent`
- `LogEvent` may reference one `ScheduleOccurrence`
- `ProtocolDefinition` may be associated with one or more `InventoryItem`
- `InventoryItem` has many `InventoryLedgerEvent`
- `LogEvent` can trigger `InventoryLedgerEvent`
- `InsightSnapshot` is derived from `LogEvent`, `ScheduleOccurrence`, and `InventoryLedgerEvent`

## Source-of-truth hierarchy
1. Protocol definitions identify the tracked routine.
2. Protocol revisions and revision rules describe future intent.
3. Schedule occurrences describe generated expectation.
4. Log events describe reality.
5. Inventory ledger events describe stock changes.
6. Protocol change audit events describe editing history.
7. Insight snapshots describe derived summaries.
8. Sensitive action audit events describe privacy and sharing history.

## Storage boundaries
### AsyncStorage
- onboarding draft
- small UI preferences
- non-sensitive feature flags

### Database layer
- user profile
- protocol definitions
- protocol aliases
- privacy profile
- protocol revisions
- protocol revision rules
- protocol change audit events
- sensitive action audit events
- occurrence cache
- log events
- inventory items
- inventory ledger
- reminder configuration
- insight snapshots

### SecureStore
- auth tokens
- key references
- future lock/secret material

## Open modeling decision
Trust Vault should prefer a small relational model:
- `privacy_profile`
- `protocol_aliases`
- `sensitive_action_audit_events`

Selective share bundles themselves can remain file artifacts rather than fully persisted database rows in v1, but their manifests should still be deterministic and versioned.

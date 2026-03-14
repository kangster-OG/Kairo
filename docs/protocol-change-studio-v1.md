# Protocol Change Studio V1

## Purpose
Protocol Change Studio is Atlas's controlled editing environment for messy real-life protocol changes.

Its job is to let the user change future behavior safely without:
- corrupting immutable history
- creating reminder chaos
- double-counting inventory
- hiding what changed

This feature is deterministic, local-first, and explicitly non-medical.

## V1 product promise
A user can preview and commit a future protocol change with a calm, human-readable impact summary over:
- 7 days
- 14 days
- 30 days

Atlas will then keep:
- historical logs immutable
- future occurrences regenerated from the new effective state
- reminders regenerated correctly
- inventory forecast updated
- audit history append-only

## Non-goals
Protocol Change Studio V1 does not:
- provide dose recommendations
- suggest recovery strategies as advice
- rewrite past logs
- rewrite already-fired reminder history to pretend it never happened
- require cloud sync

## Simplest safe data model
### 1. Keep `protocols` as stable identity records
`protocols` should remain the durable user-facing identity:
- protocol id
- protocol name
- kind
- compound relationship
- high-level status

This avoids breaking current feature surfaces that already key off `protocolId`.

### 2. Add `protocol_revisions`
Each committed future change creates a new effective-dated revision snapshot.

Recommended fields:
- `id`
- `protocol_id`
- `revision_number`
- `effective_from`
- `effective_to` nullable
- `lifecycle_state: 'active' | 'paused' | 'resting'`
- `timezone`
- `timezone_strategy: 'keep_local_clock' | 'keep_home_timezone'`
- `default_time_of_day` nullable
- `dose_amount` nullable
- `dose_unit` nullable
- `linked_vial_id` nullable
- `missed_dose_policy: 'skip_and_continue' | 'take_now_keep_cadence' | 'take_now_shift_future'`
- `notes` nullable
- `created_at`
- `updated_at`

Rules:
- revisions are append-only
- only one revision is effective for a protocol at a given instant
- future generation reads revisions, not mutable protocol fields

### 3. Add `protocol_revision_rules`
Each revision owns one or more rule rows.
These rows replace the current single-rule mental model with explicit future phases.

Recommended fields:
- `id`
- `revision_id`
- `phase_type: 'base' | 'titration' | 'rest'`
- `phase_order`
- `rule_type: 'weekly' | 'daily' | 'every_n_days'`
- `interval_count`
- `weekday` nullable
- `time_of_day` nullable
- `anchor_date` nullable
- `phase_start_day_offset`
- `phase_length_days` nullable
- `dose_amount_override` nullable
- `dose_unit_override` nullable
- `created_at`
- `updated_at`

Interpretation:
- `base` is the default future schedule
- `titration` is a bounded or staged phase with its own dose/time cadence
- `rest` is an explicit no-dose window

### 4. Add `protocol_change_audit_events`
This keeps edit history separate from dose history.

Recommended fields:
- `id`
- `protocol_id`
- `revision_id`
- `previous_revision_id` nullable
- `change_type`
- `effective_from`
- `created_at`
- `summary`
- `payload_json`

Rules:
- append-only
- rendered in Timeline/history
- never stored inside `log_events`

### 5. Keep `log_events` immutable
No protocol edit should change:
- past `completed`
- past `skipped`
- past `rescheduled`
- past `inventory_adjustment`

### 6. Keep generated occurrences separate
Generated occurrences continue to be derived from:
- `protocols`
- `protocol_revisions`
- `protocol_revision_rules`
- immutable `log_events`

They are never the source of truth.

## Relationships to existing entities
### Protocols
- remain the stable id used by Today, Timeline, reminders, and inventory
- gain a new current-future source through revisions

### Existing `protocol_rules`
Migration plan:
- backfill one revision per existing protocol
- copy current active rule rows into `protocol_revision_rules`
- transition schedule reads to revision-backed queries
- remove dependence on legacy `protocol_rules` only after the revision read path is stable

### Reminders
- future reminders are regenerated from the committed draft revision
- only reminders for occurrences on or after the effective boundary are cancelled/regenerated
- already-fired reminder history is not rewritten

### Vials and inventory
- revisions can change `linked_vial_id`
- preview should show the inventory forecast before and after the planned handoff
- logging after the switch date decrements only the active linked vial

### Sites
- if site tracking is enabled, preview can surface conflicts or repeated upcoming sites
- site selection remains optional during logging

## Supported edit operations in V1
### Future-only edits
- dose amount / dose unit
- default time of day
- day of week
- every-`N`-days cadence

### Lifecycle operations
- pause from an effective date
- resume from an effective date
- rest period with explicit start and end

### Phase operations
- titration phase editing
- add, edit, reorder, or remove deterministic future phases

### Recovery and travel operations
- missed-dose recovery policy change
- timezone / travel adjustment

### Inventory-aware operations
- vial switch-over planning from an effective date

## Preview and diff engine semantics
Protocol Change Studio preview should be pure and side-effect free.

### Inputs
- protocol identity
- currently committed active and future revisions
- immutable log history
- reminder preferences
- linked vial state
- optional site history
- candidate draft change
- horizon window: `7 | 14 | 30`

### Outputs
- `what changed` summary
- next due before/after
- moved future occurrences
- removed future occurrences
- added future occurrences
- reminder changes
- inventory depletion forecast changes
- adherence semantics notes
- site rotation warnings where possible

### Diff rules
- only compare occurrences at or after the effective date
- leave prior history untouched
- if the same conceptual slot moves, show it as `moved`, not `removed + added`
- if a pause/rest window suppresses occurrences, show them as `removed during pause/rest`
- if a timezone change preserves wall-clock time, highlight the timezone strategy explicitly

### Inventory preview rules
- forecast only
- never mutate a vial during preview
- vial handoff preview shows:
  - which vial covers which future window
  - expected depletion date shift
  - any obvious underflow risk

### Reminder preview rules
- show upcoming reminder title/body semantics in privacy-safe wording
- show whether reminders are moved, cancelled, or newly scheduled
- do not schedule anything until commit

## UI entry points
### Protocol detail
Primary launch point.

V1 requirement:
- add a protocol detail screen if needed
- show a `Change future plan` CTA

### Today
Secondary launch point.

V1 entry:
- overflow action on next-due card or protocol card
- should open the studio already scoped to that protocol

### Timeline
Contextual launch point.

V1 entry:
- from a protocol-created or protocol-change audit item
- opens the same protocol scoped studio

### Library
Discovery and management entry point.

V1 entry:
- tapping a saved protocol opens protocol detail
- protocol detail launches the studio

## Studio flow
1. Select protocol
2. Select change type
3. Edit future values
4. Choose effective date
5. Preview impact over 7 / 14 / 30 days
6. Commit or cancel

Tone:
- calm
- explicit
- human-readable
- no scary debugger language

## Rollback and cancel semantics
### Cancel before commit
- writes nothing
- no new revision
- no audit entry
- no reminder regeneration
- no inventory change

### Rollback after commit
V1 should avoid destructive rollback.

Safe rule:
- rollback is modeled as a new compensating future revision, not deletion of history

Optional narrow V1 convenience:
- allow cancelling the latest still-future revision only if:
  - it has not become effective
  - it has no dependent later revisions
  - it has no logged actions against occurrences produced from it

Even then:
- keep an audit entry for the reversal

## Audit model
Every committed change creates one audit event.

Required event attributes:
- protocol id
- prior revision id
- next revision id
- change type
- effective date
- human-readable summary
- machine-readable payload

Suggested change types:
- `future_dose_changed`
- `time_changed`
- `cadence_changed`
- `paused`
- `resumed`
- `titration_changed`
- `rest_period_changed`
- `missed_dose_policy_changed`
- `timezone_changed`
- `vial_handoff_planned`
- `revision_reverted`

## Acceptance criteria
Protocol Change Studio V1 is ready when:
- a user can launch it from protocol management surfaces
- a user can preview a future-only change without writing data
- historical logs remain unchanged after commit
- future occurrences regenerate from the committed revision
- reminders regenerate only for future affected occurrences
- inventory forecast updates consistently
- vial switch-over does not cause double decrement
- Timeline shows protocol change audit entries
- cancel commits nothing
- the feature is behind a feature flag until QA passes

## Proposed migration and repository changes
### New tables
- `protocol_revisions`
- `protocol_revision_rules`
- `protocol_change_audit_events`

### Transitional migration steps
1. Create new tables and indexes.
2. Backfill one revision per existing protocol.
3. Copy each current active rule into revision-backed rows.
4. Add revision repositories and selectors.
5. Switch schedule generation, reminders, and preview to read revisions first.
6. Keep legacy `protocol_rules` readable until the new path is stable.

### New repositories
- `ProtocolRevisionRepository`
- `ProtocolRevisionRuleRepository`
- `ProtocolChangeAuditRepository`

### Query helpers
- `getCurrentRevisionForProtocol(at)`
- `listFutureRevisionsForProtocol(protocolId)`
- `buildProtocolChangePreview(protocolId, draft, horizonDays)`
- `commitProtocolRevisionChange(input)`

## Implementation phases
### Phase 1: revision foundation
- migrations
- repositories
- backfill
- feature flag

### Phase 2: preview engine
- draft model
- revision-to-occurrence generation
- diff engine
- preview summaries for 7 / 14 / 30 days

### Phase 3: commit path
- audit entries
- reminder regeneration from effective boundary
- inventory forecast update semantics
- query invalidation for Today, Timeline, Library

### Phase 4: V1 UI flow
- protocol detail entry point
- studio step flow
- preview screen
- commit/cancel states

### Phase 5: QA and stabilization
- automated tests
- manual QA checklist
- keep behind feature flag until green

## Test matrix
### Unit / pure logic
- effective-date revision resolution
- phase ordering
- diff classification
- missed-dose policy semantics
- timezone strategy semantics

### Repository / integration
- migration backfill creates revision 1 for existing protocols
- commit inserts revision, rules, and audit row atomically
- cancel inserts nothing
- reminder regeneration affects only future rows

### Cross-feature integration
- Today reflects the new next due after commit
- Timeline shows the audit event
- inventory forecast changes after vial switch-over
- site rotation warning appears when relevant

### Edge cases
- effective date equals next due timestamp
- pause begins during an overdue window
- resume after long pause
- titration overlaps a rest period
- timezone change across DST boundary
- vial switch when current vial is already low or depleted
- changing cadence after a rescheduled future occurrence
- later revision committed before an earlier future revision takes effect

## Manual QA checklist summary
The manual checklist should cover:
- launch from protocol detail, Today, Timeline, and Library
- each V1 change type
- preview over 7 / 14 / 30 days
- cancel path
- commit path
- reminder regeneration
- inventory forecast changes
- site rotation warnings
- audit entry visibility
- relaunch persistence

The executable checklist should live under `qa/`.

## Tradeoffs
### Why revisions instead of mutating protocol rows?
- safer history preservation
- simpler future-only semantics
- easier audit trail
- better preview engine inputs

### Why a dedicated audit table instead of reusing `log_events`?
- keeps historical reality separate from editing history
- avoids overloading the meaning of immutable dose logs
- keeps Timeline composition explicit

### Why keep preview in memory first?
- safer cancel semantics
- no cleanup burden for abandoned drafts
- simpler local-first behavior

## Open questions
- whether protocol detail should ship as part of this slice or one setup phase earlier
- whether V1 should include the narrow "revert latest still-future revision" convenience
- whether adherence semantics should mention only schedule shifts or also annotate "policy changed"
- whether a bounded occurrence cache table is worth adding now or after revision reads are stable

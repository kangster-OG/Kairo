# Schedule Engine Spec

## Purpose
The schedule engine turns protocol definitions into generated future occurrences that power:
- next due
- reminders
- timeline projections

It must remain separate from logging and never replace immutable log history.

## Non-goals
The schedule engine does not:
- recommend doses
- adjust treatment
- infer medical advice
- source products

## Core rule
Generated schedule occurrences are not immutable source records.

Immutable source records are:
- protocol definitions
- log events
- inventory ledger events

Generated schedule occurrences are:
- rebuildable projections derived from protocol definitions and event history
- safe to invalidate and regenerate

## Inputs
- active protocol definitions
- effective protocol revisions and revision rules
- protocol timezone context
- log events that complete, skip, or otherwise resolve occurrences
- protocol change audit entries when useful for preview context
- current date/time

## Outputs
- ordered future occurrences
- current due occurrence
- next due occurrence
- overdue state
- occurrence timeline entries

## Supported cadence models for MVP
### Weekly fixed day
Examples:
- every Monday
- every Thursday at 8:00 PM

Primary use:
- typical GLP routines

### Daily fixed time
Examples:
- every day at 8:00 AM

Primary use:
- simple peptide routines

### Every N days
Examples:
- every 2 days
- every 7 days

Primary use:
- non-weekday recurring schedules

Advanced patterns are deferred until after the local-first MVP.

## Occurrence state model
- `upcoming`
- `due`
- `completed`
- `missed`
- `skipped`
- `superseded`

State rules:
- `completed` and `skipped` are assigned by immutable log events
- `missed` is derived when a due window expires without a resolving log event
- `superseded` is used when protocol edits invalidate an old generated occurrence

## Resolution model
When the user logs an event:
1. find the matching due or nearest relevant occurrence
2. attach the log event to that occurrence when possible
3. mark the occurrence as resolved in derived state
4. regenerate future occurrences if required

If no matching occurrence exists:
- create a `manual_log` event
- keep the event immutable
- do not mutate protocol definitions to fit the event

## Protocol edits
Editing a protocol must:
- preserve past log history
- preserve past reminder history as history
- invalidate affected future occurrences
- regenerate future occurrences from the edit point forward using the newly effective revision

Protocol edits must not:
- rewrite past completed or skipped events
- change immutable log timestamps
- duplicate future occurrences across revision boundaries
- silently consume inventory twice during vial switch-over planning

## Effective-dated revision model
Protocol Change Studio should not mutate the currently effective future plan in place.

Recommended semantics:
- `ProtocolDefinition` remains the stable identity
- `ProtocolRevision` becomes the source of truth for future generation from its `effectiveFrom`
- `ProtocolRevisionRule` rows define cadence, titration, and rest phases inside that revision
- when a change is committed:
  - the prior revision receives an `effectiveTo`
  - the new revision becomes active from its `effectiveFrom`
  - future occurrences at or after that boundary are regenerated
  - past occurrences remain resolved only through log history

## Supported Protocol Change Studio operations for V1
- future-only dose edit
- future-only time-of-day edit
- day-of-week change
- every-`N`-days cadence change
- pause
- resume
- titration phase editing
- rest period editing
- missed-dose recovery policy change
- timezone/travel adjustment
- vial switch-over planning

These are deterministic schedule edits, not medical recommendations.

## Preview and diff semantics
Protocol Change Studio previews should be computed without writing durable rows.

Preview rules:
- compare `current committed future state` vs `draft future state`
- limit the diff to occurrences on or after the selected effective date
- expose impact over `7`, `14`, and `30` day windows
- surface:
  - next due before/after
  - created, moved, and removed future occurrences
  - reminder changes
  - inventory depletion forecast changes
  - adherence interpretation notes where semantics change
  - site rotation warnings if a future site conflict is detectable
- keep the preview human-readable and calm

Diff semantics:
- `added`: new future occurrence exists only in the draft revision
- `removed`: prior future occurrence is invalidated by the draft revision
- `moved`: same conceptual occurrence shifts time/date
- `rewired`: linked vial, timezone strategy, or missed-dose policy changes without changing the immediate next due time

Preview cancellation:
- cancelling the studio writes nothing
- no reminders are cancelled or regenerated
- no inventory forecast is persisted

## Horizon strategy
Generate occurrences within a bounded lookahead window:
- default recommendation: 30 days ahead

Why:
- enough for Today and timeline previews
- avoids unbounded generated state
- cheap to recompute when protocols change

## Reminder integration
Reminders are scheduled from generated occurrences, not directly from onboarding answers.

Reminder scheduling rules:
- only active protocols produce reminders
- discreet mode changes notification copy
- changing a protocol or reminder rule should reschedule future notifications only
- committed revision changes should cancel and regenerate future reminders from the effective boundary
- reminder rows tied to past or already-fired history must not be silently rewritten as if they never existed

## Timezone behavior
- protocol schedules are interpreted in the device timezone for the local-first MVP
- timezone shifts should trigger occurrence regeneration from the effective revision boundary
- historical log events retain their original timestamps

Protocol Change Studio V1 should support two deterministic strategies:
- `keep_local_clock`: preserve the wall-clock time in the destination timezone from the effective date forward
- `keep_home_timezone`: preserve the original timezone cadence, even while the device timezone changes

The engine must guarantee that timezone edits do not create duplicate future occurrences.

## Data responsibilities
### Protocol definitions
- durable intent
- stored in database layer

### Occurrence cache
- generated projection
- stored in database layer for fast queries
- safe to delete and rebuild

### Log events
- immutable reality
- stored in database layer

## Test requirements
The schedule engine is not done until it has tests for:
- weekly cadence generation
- daily cadence generation
- every-N-days cadence generation
- protocol edits invalidating future occurrences only
- completion resolving due occurrences
- skipped events
- later timezone regeneration behavior
- both GLP and peptide protocols existing at once

Protocol Change Studio adds required tests for:
- future-only revision commits preserving historical logs
- pause shifting future occurrences and reminders correctly
- resume restoring future occurrences correctly
- titration phase edits recalculating future occurrences correctly
- rest period edits suppressing occurrences during the rest window
- timezone changes not duplicating occurrences
- vial switch-over not causing double inventory decrement
- preview cancellation writing nothing

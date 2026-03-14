# Atlas Build Plan

## Planning assumptions
- The current codebase is an onboarding-first prototype.
- Onboarding, branching, local draft persistence, summary, auth placeholder, and Today placeholder already exist.
- The next phase starts after onboarding.
- MVP remains local-first. Sync is second.

## Dependencies and sequencing
The next six milestones must be built in this order because each one unlocks the next:

1. `Protocol setup + local database foundation`
   Depends on:
   - current onboarding output shape
   - domain schema decisions
   Unlocks:
   - real post-onboarding data
   - schedule engine inputs

2. `Schedule engine + next due`
   Depends on:
   - protocol definitions stored locally
   Unlocks:
   - Today real content
   - reminder scheduling

3. `Reminder pipeline`
   Depends on:
   - stable generated occurrences
   - privacy copy rules
   Unlocks:
   - retention loop activation

4. `Logging + inventory`
   Depends on:
   - due occurrences
   - protocol identifiers
   Unlocks:
   - reality tracking
   - low-stock state
   - meaningful timeline

5. `Timeline + insights`
   Depends on:
   - immutable log events
   - inventory history
   - generated occurrence state
   Unlocks:
   - historical value
   - habit/retention surfaces

6. `Auth and sync foundation`
   Depends on:
   - stable local repositories
   - guest-mode migration plan
   Unlocks:
   - optional cloud continuity

## Milestone details
### Milestone 1: Protocol setup and local database foundation
Deliver:
- local repository abstraction
- database-backed protocol definitions
- first real Today empty state
- protocol create/edit screens

Key engineering rules:
- keep AsyncStorage limited to onboarding and small preferences
- put durable product data in the database layer
- define protocol types explicitly

Test gate:
- repository CRUD tests
- schema validation tests
- protocol creation component tests
- typecheck and lint pass

#### Proposed slice: local-first persistence layer
Purpose:
- replace placeholder-only product data storage with a structured local database layer
- keep onboarding and lightweight preferences in AsyncStorage
- preserve a clean boundary for optional future Supabase sync
- keep generated future schedule occurrences separate from immutable historical log events

Recommended implementation shape:
- use `expo-sqlite` as the local database engine
- keep migrations explicit and code-owned
- keep repository interfaces separate from table implementations
- validate all database boundary input/output with Zod
- keep UI unaware of SQL details

Planned deliverables:
- database module and connection bootstrap
- migration runner and initial schema version
- repository interfaces plus SQLite-backed implementations
- domain schemas, row schemas, and mappers
- typed entities/tables for:
  - `compounds`
  - `protocols`
  - `protocol_rules`
  - `vials`
  - `log_events`
  - `reminders`
  - `custom_metrics`
  - `sites`
- seed/dev utilities for local testing
- typed repository CRUD and query methods

Explicit constraints for this slice:
- keep onboarding state in AsyncStorage
- do not implement network sync yet
- do not implement schedule generation yet
- do not mix generated future occurrences with immutable `log_events`
- if an occurrence cache is added later, it must live in a separate table/module from `log_events`

Repository scope for this slice:
- `CompoundRepository`
- `ProtocolRepository`
- `ProtocolRuleRepository`
- `VialRepository`
- `LogEventRepository`
- `ReminderRepository`
- `CustomMetricRepository`
- `SiteRepository`

Expected file areas:
- `src/lib/database/`
- `src/features/*/domain/` or `src/domain/` for schemas and entity models
- `src/types/` as needed for shared contracts
- `__tests__/` for migration and repository coverage
- `package.json` for the database dependency

Test gate for this slice:
- migrations run successfully against a fresh database
- repository create/read/update/delete basics are covered
- Zod boundary parsing is covered
- typecheck passes
- existing onboarding tests remain green

#### Approved slice before protocol logic: post-onboarding app shell
Purpose:
- replace the current single Today placeholder with a real post-onboarding shell
- preserve onboarding intact while creating the structural home for milestone 1
- stay protocol-logic free for this slice

Planned changes:
- move onboarding routes under an `(onboarding)` route group
- create an `(app)` route group with bottom tabs
- add tabs for `Today`, `Timeline`, `Library`, `Insights`, and `Settings`
- route onboarding completion into the `(app)` shell instead of the old standalone Today route
- replace the Today placeholder with a production-lean empty state
- add production-lean empty states for Timeline, Library, and Insights
- add a real Settings shell with privacy status, account mode status, onboarding reset for QA, and export placeholder

Expected file areas:
- `app/`
- `src/features/today/`
- `src/features/settings/`
- `src/features/timeline/`
- `src/features/library/`
- `src/features/insights/`
- shared UI primitives and theme tokens as needed
- focused tests outside `app/`

Constraints for this slice:
- keep the existing onboarding flow and branching intact
- do not build protocol logic, schedule logic, logs, inventory, or insights logic yet
- keep the existing onboarding design language
- avoid debug-looking placeholders; empty states should feel shippable

Test gate for this slice:
- typecheck passes
- existing onboarding tests remain green
- add or update targeted tests only where routing/state behavior changes materially
- manual route verification: onboarding summary lands in the new app shell

#### Proposed slice: Protocol Creation V1
Purpose:
- replace the current protocol placeholder with a production-usable first-protocol flow
- persist compounds and protocol definitions into the structured local database
- compute a real next-due item for Today from stored protocol rules
- keep language neutral and privacy-safe, with no dose advice or recommendations

Planned user flow:
- user taps `Create your first protocol` from Today or Library
- user chooses an existing compound or creates a new one
- user completes a short wizard:
  - protocol kind: `GLP`, `Peptide`, or `Custom`
  - compound selection or custom naming
  - schedule type:
    - weekly recurring
    - selected day of week
    - every `N` days
    - default time of day
  - dose amount
  - dose unit
  - optional notes
- on save:
  - compound is created or reused
  - protocol definition is stored locally
  - protocol rule rows are stored locally
  - Today resolves and shows the next due event
  - Library lists the saved protocol

Implementation shape:
- add a dedicated `protocols` feature with:
  - domain schemas for protocol create input and persisted protocol view models
  - wizard state and validation using Zod and React Hook Form
  - route-backed screens for the simple creation flow
- extend the database repository layer with:
  - compound upsert/select helpers
  - protocol create/list/get helpers
  - protocol rule create/list helpers
- add a small schedule module isolated from UI that supports only:
  - weekly recurring with explicit day-of-week
  - every-`N`-days interval
  - default local time-of-day
- derive Today next due from stored active protocols without creating logging, reminders, titration, or rest-period logic yet

Expected file areas:
- `app/(app)/protocols/`
- `src/features/protocols/`
- `src/features/today/`
- `src/features/library/`
- `src/lib/database/repositories/`
- `src/lib/schedule/` or `src/domain/schedule/`
- `__tests__/features/protocols/`
- `__tests__/lib/` for schedule and repository coverage

Constraints for this slice:
- preserve the existing onboarding and app shell intact
- do not provide dose guidance, defaults, or recommendations
- support GLP, peptide, or generic/custom compound naming
- do not implement reminders, pause/resume, titration, rest periods, linked vials, or sync yet
- keep generated next-due data separate from immutable `log_events`
- do not move onboarding state out of AsyncStorage

Dependencies:
- relies on the structured local data layer already in place
- introduces only the minimum schedule derivation needed for Today next due
- should leave room for future pause/resume, titration, rest periods, and linked vials by keeping protocol rules separate from protocol definitions

Test gate for this slice:
- protocol creation form validation tests
- repository tests for compound creation/reuse and protocol create/list queries
- schedule tests for:
  - weekly selected-day generation
  - every-`N`-days generation
  - next-due selection across multiple active protocols
- UI tests for:
  - create-from-Today path
  - successful save routing
  - Library listing saved protocols
  - Today showing the derived next due item
- typecheck passes
- existing onboarding and database tests remain green

#### Proposed slice: First daily-use loop
Purpose:
- turn the post-onboarding shell into the first real daily-use workflow
- generate upcoming schedule occurrences separately from immutable history
- let the user act from Today with fast thumb-friendly logging
- keep Today and Timeline driven by the same local-first occurrence and log state

Planned user flow:
- user creates one or more protocols
- Today shows:
  - next due
  - overdue
  - upcoming
- user can take quick actions from Today:
  - `Mark taken`
  - `Skip`
  - `Reschedule`
- logging opens a compact confirmation surface optimized for one-handed use
- action creates immutable log events in the database
- Today refreshes to the new next due state
- Timeline shows:
  - protocol created
  - logged dose
  - skipped dose
  - rescheduled dose
- Timeline supports filtering by protocol and date range

Implementation shape:
- add a dedicated occurrence generation module isolated from UI and immutable logs
- introduce a generated occurrence model/query layer that:
  - derives occurrences from protocol definitions and rules
  - derives resolved state by joining immutable log events
  - can be rebuilt without mutating history
- add a log-event service that:
  - creates immutable `completed`, `skipped`, and `manual_log` / reschedule-related events
  - never rewrites historical rows silently
- expand Today into a production-lean daily-use screen with:
  - next due card
  - overdue card
  - upcoming list
  - quick action affordances
- expand Timeline from empty state into a real feed backed by log events plus protocol-created entries
- keep protocol-created items and occurrence-derived items clearly distinguished in the feed

Expected file areas:
- `src/lib/schedule/`
- `src/lib/database/` and repository/query helpers
- `src/features/today/`
- `src/features/timeline/`
- `src/features/protocols/`
- `app/(app)/(tabs)/today/`
- `app/(app)/(tabs)/timeline/`
- `__tests__/lib/`
- `__tests__/features/today/`
- `__tests__/features/timeline/`

Constraints for this slice:
- future schedule occurrences must remain separate from immutable `log_events`
- edits and reschedules must not mutate historical truth silently
- keep language privacy-safe and neutral
- do not implement reminders, inventory mutations, or insights yet beyond placeholders
- keep logging fast and thumb-friendly
- keep Today and Timeline in sync through shared repository/service queries rather than duplicated local state

Recommended domain shape for this slice:
- generated `ScheduleOccurrenceView` / `ScheduleOccurrenceRecord`
- immutable `LogEvent`
- timeline feed item mapper that merges:
  - protocol created entries
  - resolved occurrence actions
- reschedule should be represented as:
  - immutable event describing the user action
  - updated future occurrence derivation from that point forward
  - never a silent rewrite of the original historical event

Test gate for this slice:
- schedule occurrence generation tests for:
  - next due
  - overdue
  - upcoming windows
  - skip resolution
  - reschedule edge cases
- repository/service tests for immutable log creation
- Today happy-path tests:
  - mark taken updates next due
  - skip updates next due
  - reschedule updates next due
- Timeline tests:
  - protocol created entry renders
  - logged dose entry renders
  - skipped entry renders
  - rescheduled entry renders
  - protocol/date filters work
- typecheck passes
- existing onboarding, protocol, and database tests remain green

#### Proposed slice: Daily-use QA and regression pass
Purpose:
- verify the first real daily-use loop on the Android emulator and through a manual checklist
- catch issues where Today, quick actions, Timeline, and the protocol flow fall out of sync
- keep the QA artifact set concrete enough that another person can reproduce the same pass

Planned checks:
- host verification:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`
- Android emulator verification:
  - app launch into the current shell
  - protocol creation flow renders and saves
  - Today shows next due / overdue / upcoming states as appropriate
  - quick actions create immutable log events and refresh Today
  - Timeline reflects created / taken / skipped / rescheduled events
  - tab navigation remains stable across Today, Timeline, Library, Insights, and Settings
- manual verification:
  - thumb-friendly quick logging
  - empty, loading, and error states feel production-lean
  - privacy/account surfaces remain intact

Expected artifacts:
- `qa/` checklist for the daily-use slice
- expanded Android instrumentation smoke where it adds stable coverage
- focused fixes for any runtime or UI regressions discovered during the pass

Constraints for this slice:
- do not weaken the domain rule separating generated future occurrences from immutable logs
- do not add sync or backend behavior
- keep onboarding intact while validating post-onboarding behavior

Test gate for this slice:
- automated tests remain green
- Android emulator smoke passes for the new daily-use surfaces
- manual checklist is written and exercised

#### Proposed slice: Reminder infrastructure and discreet mode enforcement
Purpose:
- activate the first local reminder pipeline from generated protocol occurrences
- keep reminder behavior local-first and guest-mode compatible
- enforce discreet mode consistently across notifications, Today, Timeline, and Settings previews

Planned user flow:
- user opens Settings and configures reminder/privacy behavior
- active protocols generate future reminder candidates from generated occurrences
- Atlas schedules local notifications for future due items only
- reminder actions support:
  - `Mark taken`
  - `Skip`
  - `Open app`
- changing a protocol or reminder settings invalidates and regenerates future scheduled reminders
- discreet mode changes both on-screen copy and notification copy so sensitive labels do not leak

Implementation shape:
- add a dedicated reminders feature with:
  - reminder settings state stored in the structured local data layer
  - a notification adapter over `expo-notifications`
  - scheduler/regenerator logic driven from generated occurrences, not onboarding answers
- add a privacy formatting module that centralizes:
  - full-detail copy
  - generic reminder copy
  - silent or badge-oriented mode metadata where supported
  - discreet label rendering for Today, Timeline, and Settings
- extend the existing reminders table/repository usage to store:
  - reminder intent/config
  - scheduled notification identifiers
  - scheduling timestamps and status
- keep schedule generation and notification scheduling separate:
  - schedule engine produces occurrences
  - reminder service decides what notifications to schedule from those occurrences

Expected file areas:
- `src/features/settings/`
- `src/features/today/`
- `src/features/timeline/`
- `src/features/reminders/`
- `src/lib/notifications/`
- `src/lib/schedule/`
- `src/lib/database/repositories/`
- `__tests__/features/reminders/`
- `__tests__/features/settings/`
- `__tests__/lib/`

Constraints for this slice:
- use local notifications only
- do not implement push infrastructure or backend sync
- guest mode must continue to work without sign-in
- changing a protocol must reschedule only future reminders
- generated future occurrences must remain separate from immutable log events
- discreet mode must prevent sensitive labels from appearing in:
  - Today cards
  - Timeline summaries where appropriate
  - notification titles and bodies
  - Settings previews
- silent or badge-oriented mode should degrade gracefully where platform support differs

Recommended domain shape:
- `ReminderPreference`
  - enable or disable reminders
  - privacy mode: `full_detail | generic | silent`
  - lead time / default trigger settings if needed for v1
- `ScheduledReminder`
  - protocol id
  - occurrence id
  - scheduled-for timestamp
  - notification id
  - status
- `PrivacyPresentation`
  - helpers that map protocol and event data into safe labels for UI and notifications

Planned UI surfaces:
- Settings:
  - reminder enable toggle
  - privacy mode selector
  - preview rows for full-detail vs generic wording
- Today:
  - respects discreet label formatting for protocol names and action labels when enabled
- Timeline:
  - event summaries switch to privacy-safe wording when needed

Reminder regeneration rules:
- create or edit protocol:
  - regenerate future reminders for that protocol only
- pause, archive, or deactivate protocol in the future:
  - cancel future reminders for that protocol
- change reminder privacy mode or enablement:
  - cancel and regenerate future notifications to match the new copy/settings
- completed, skipped, or rescheduled log events:
  - update future reminders based on the newly derived next due state

Test gate for this slice:
- notification scheduling logic tests for:
  - weekly occurrence scheduling
  - every-`N`-days occurrence scheduling
  - regeneration after protocol edits
  - cancel-and-reschedule behavior after reschedule actions
- privacy formatting tests for:
  - full-detail mode
  - generic reminder mode
  - discreet Today labels
  - discreet Timeline summaries
- targeted UI tests for Settings reminder controls and previews
- typecheck passes
- existing onboarding, protocol, database, and day-loop tests remain green

#### Proposed slice: Inventory, vials, calculators, and optional site rotation
Purpose:
- make the daily loop materially more useful by linking dose logging to real supply state
- introduce inventory visibility, depletion awareness, and neutral calculation tools
- add optional injection-site tracking without turning it into a required workflow

Planned user flow:
- user creates or edits a protocol and optionally links one or more vials
- user can add vial details:
  - label
  - quantity unit
  - starting / remaining quantity
  - concentration or reconstitution context where relevant
  - low-stock threshold
- Today or Library can open a real inventory surface
- logging a linked dose decrements remaining vial quantity automatically
- user can make explicit manual corrections without rewriting history silently
- user can open a reconstitution calculator, see the math explained neutrally, and save a reusable calculator profile
- during dose logging, user can optionally choose an injection site if site tracking is enabled for that protocol
- protocol settings can opt into site rotation without forcing it

Implementation shape:
- add a dedicated inventory feature with:
  - vial CRUD forms and list views
  - protocol-to-vial linking
  - projected depletion and low-stock status derivation
  - inventory correction flow backed by immutable log and/or ledger-safe adjustments
- extend the local data model with:
  - vial low-stock threshold
  - optional protocol settings for site tracking and site rotation
  - saved calculator profiles in the structured local layer
- add a neutral calculator module for reconstitution math:
  - inputs and outputs only
  - explicit formula explanation
  - no recommendations or guidance language
- extend day-loop logging so a completed dose can:
  - attach a selected site if used
  - decrement linked vial remaining quantity
  - keep manual corrections explicit and auditable

Expected file areas:
- `src/features/inventory/`
- `src/features/protocols/`
- `src/features/today/`
- `src/features/library/`
- `src/features/settings/` if protocol-level inventory/site settings land there
- `src/lib/database/`
- `src/lib/database/repositories/`
- `src/lib/database/migrations.ts`
- `__tests__/features/inventory/`
- `__tests__/features/day-loop/`
- `__tests__/lib/database/`

Constraints for this slice:
- do not present dosing recommendations
- calculator copy must explain the math only
- manual inventory corrections must be possible and explicit
- site tracking must remain optional
- inventory state must survive restart and route changes through the structured local data layer
- logging must decrement linked vial inventory without mutating immutable dose log history
- future site rotation logic must remain additive, not mandatory

Recommended domain shape:
- `Vial`
  - linked protocol id
  - optional linked compound id
  - label
  - concentration value / unit
  - total volume or remaining quantity
  - quantity unit
  - low-stock threshold
  - optional opened / expiry metadata
- `InventoryStatus`
  - current quantity
  - low-stock boolean
  - projected depletion date
- `CalculatorProfile`
  - label
  - vial amount / solvent amount inputs
  - derived concentration output
  - saved neutral notes
- `ProtocolSiteSettings`
  - site tracking enabled
  - rotation enabled
  - preferred available regions

Planned UI surfaces:
- Inventory screen:
  - vial list
  - low-stock status
  - projected depletion cards
  - correction actions
- Protocol flow:
  - optional vial link step or settings section
  - optional site-rotation settings
- Dose logging:
  - optional site selector
  - linked vial display when inventory is attached
- Calculator:
  - input form
  - explained output math
  - save profile action

Inventory mutation rules:
- completed dose with linked vial:
  - decrement vial remaining quantity by the logged dose quantity when units align
- skipped or rescheduled dose:
  - do not decrement inventory
- manual correction:
  - update remaining quantity explicitly
  - preserve an audit-safe event or correction record
- protocol without linked vial:
  - dose logging continues without inventory mutation

Test gate for this slice:
- repository tests for vial CRUD, linking, and saved calculator profile persistence
- inventory service tests for:
  - decrement on completed linked dose
  - no decrement on skip
  - no decrement on reschedule
  - manual correction behavior
  - low-stock threshold derivation
  - projected depletion derivation
- calculator tests for:
  - neutral output wording
  - saved profile round-trip
- UI tests for:
  - inventory list rendering
  - linked-vial display in logging
  - optional site selector behavior
- typecheck passes
- existing onboarding, protocol, reminder, day-loop, and database tests remain green

#### Proposed slice: Reminder, privacy, and inventory QA pass
Purpose:
- verify prompt 5 and prompt 6 behavior together on the Android emulator
- exercise reminder/privacy formatting, inventory state changes, calculator flows, and optional site rotation from real UI paths
- keep a repeatable manual checklist for future regression passes

Planned checks:
- host verification:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`
- Android emulator manual verification:
  - reminder settings render and persist
  - discreet mode changes Today, Timeline, and Settings preview copy
  - protocol creation plus reminder-related settings do not regress the daily loop
  - inventory screen supports vial add, link, correction, and delete flows
  - linked dose logging decrements vial stock
  - site tracking appears only when enabled and logs a selected site
  - calculator explains the math neutrally and saved profiles round-trip
- iteration:
  - fix any UI or domain defects discovered during the pass
  - rerun the failing steps until the whole checklist is green

Expected artifacts:
- a dedicated checklist under `qa/`
- any focused Android helper updates needed to drive the emulator
- targeted fixes for prompt 5 and prompt 6 regressions

Constraints for this slice:
- do not weaken discreet mode copy protections
- do not mix generated schedule occurrences with immutable log events
- do not move product state back into AsyncStorage
- keep guest-mode behavior intact

Test gate for this slice:
- checklist written
- emulator pass completed against the checklist
- typecheck passes
- test suite passes
- lint stays clean apart from generated-file warnings

### Milestone 2: Schedule engine and next due
Deliver:
- isolated schedule engine module
- generated occurrence model
- Today next due card
- overdue and upcoming states

Key engineering rules:
- generated occurrences are rebuildable
- log events remain separate from occurrence generation

Test gate:
- cadence generation unit tests
- next due selector tests
- multi-protocol tests
- Android smoke for Today next due

### Milestone 3: Reminder pipeline
Deliver:
- local reminder rule model
- notification scheduling adapter
- discreet notification copy rules
- reminder settings UI

Key engineering rules:
- no broad notification assumptions
- discreet mode must be respected

Test gate:
- reminder scheduling tests
- discreet copy tests
- manual Android native notification QA
- iOS notification QA when available

### Milestone 4: Logging and inventory
Deliver:
- immutable log event model
- quick-log flow from Today
- inventory item model
- inventory ledger and low-stock logic

Key engineering rules:
- no mutable log rewriting
- inventory remains reconstructable from ledger plus starting state

Test gate:
- immutable log tests
- inventory derivation tests
- integration tests from log to inventory
- Android smoke for log completion flow

### Milestone 5: Timeline and insights
Deliver:
- timeline screen
- merged future and past activity rendering
- simple descriptive insights
- recent activity modules on Today

Key engineering rules:
- insights remain descriptive only
- no recommendation copy

Test gate:
- timeline ordering tests
- insight calculator tests
- empty-state component tests
- Android smoke for timeline navigation

#### Proposed slice: Insights V1, exports, and modular health connections
Purpose:
- turn the existing log, inventory, and timeline data into useful descriptive trends
- add local-first export paths for guest and account users
- introduce a modular health-connection boundary that does not destabilize the core app

Planned user flow:
- user logs weight, symptoms, and custom metrics over time
- Insights renders:
  - weight trend
  - symptom trend
  - inventory burn-down
  - adherence trend
  - estimated amount-in-system
- amount-in-system is always labeled as an estimate/model, never as medical truth
- user can export local data as:
  - CSV
  - JSON
- Settings exposes:
  - account data export entry point
  - health connection enable/disable controls
  - health connection status UI
- if health connections fail or are unavailable:
  - the rest of Atlas continues working normally
  - insights still render from local app data alone

Implementation shape:
- extend the structured local layer with:
  - weight log rows
  - symptom log rows
  - custom metric value rows if needed beyond the current metric definitions
- add an insights service layer that derives chart-friendly trends from immutable logs and inventory state
- keep exports behind a dedicated serializer/export module rather than coupling exports to screen code
- add a health adapter boundary with:
  - connection capability/status model
  - enabled/disabled settings
  - no hard dependency on a successful connection

Expected file areas:
- `src/features/insights/`
- `src/features/settings/`
- `src/features/today/` only if entry points or recent metrics previews are added
- `src/features/metrics/` or `src/features/logging/`
- `src/lib/database/`
- `src/lib/database/repositories/`
- `src/lib/export/`
- `src/lib/health/`
- `app/(app)/(tabs)/insights/`
- `__tests__/features/insights/`
- `__tests__/features/export/`
- `__tests__/lib/`

Constraints for this slice:
- insights must remain descriptive only
- estimated amount-in-system must be clearly framed as an estimate/model
- no dose recommendations, medical claims, or optimization copy
- exports must work for both guest and authenticated users
- health integrations remain optional and modular
- health-connection failure must not block Today, logging, inventory, reminders, or timeline use
- local-first remains the operating mode even when account mode is active

Recommended domain shape:
- `WeightLog`
  - `id`
  - `loggedAt`
  - `value`
  - `unit`
  - `source`
- `SymptomLog`
  - `id`
  - `loggedAt`
  - `symptomKey`
  - `severity`
  - `notes`
- `MetricValueLog`
  - `id`
  - `metricId`
  - `loggedAt`
  - `numberValue | textValue | booleanValue`
- `InsightSeries`
  - chart points
  - period metadata
  - explanatory labels
- `HealthConnectionStatus`
  - provider key
  - `enabled`
  - `connected`
  - `lastSyncAt`
  - `lastError`

Planned export scope:
- CSV:
  - protocols
  - log events
  - inventory/vials
  - weight logs
  - symptom logs
  - custom metric logs
- JSON:
  - full local-first account/app data bundle
- account export entry point:
  - lives in Settings
  - available to guests and account users

Planned health connection scope:
- modular adapter interface only in v1 slice
- status and enable/disable settings UI
- provider scaffolding for Apple Health / Health Connect
- no requirement that insights depend on connected health data

Test gate for this slice:
- repository tests for weight/symptom/custom metric logging persistence
- insights derivation tests for:
  - weight trend
  - symptom aggregation
  - inventory burn-down
  - adherence trend
  - amount-in-system estimate labeling and model outputs
- export tests for CSV and JSON bundle shape
- health adapter tests for failure isolation and settings state
- typecheck passes
- existing onboarding, auth, reminder, inventory, timeline, and calculator tests remain green

### Milestone 6: Auth and sync foundation
Deliver:
- Supabase-backed optional auth shell
- guest-to-account upgrade path
- sync-ready repository boundary
- SecureStore token handling

Key engineering rules:
- guest mode must continue to work
- sync cannot become a prerequisite for core usage

Test gate:
- migration tests from guest to account
- repository sync contract tests
- SecureStore token tests
- regression pass over onboarding and guest-mode flows

#### Proposed slice: Real auth, guest upgrade, and additive sync foundation
Purpose:
- layer optional Supabase auth onto the existing local-first Atlas app without weakening guest mode
- preserve local product data during guest-to-account upgrade
- introduce a visible but non-blocking sync boundary so network failure never blocks core use

Planned user flow:
- user can remain a guest indefinitely
- user can create an account or sign in with email from the auth/settings surfaces
- after auth succeeds, Atlas keeps the local database as the operating source of truth
- guest records are prepared for migration and mapped to an account-owned sync scope
- Settings shows:
  - current account status
  - sync state
  - upgrade/sign-in actions when still in guest mode
- if network is unavailable:
  - app remains fully usable locally
  - sync status communicates deferred upload/download work without blocking access

Implementation shape:
- add a Supabase config boundary with environment validation for:
  - project URL
  - anon key
- add an auth session module that owns:
  - bootstrap from SecureStore/session cache
  - email sign-up/sign-in/sign-out
  - guest/account state transitions
- keep domain repositories local-first and introduce a sync adapter layer rather than letting feature code talk directly to Supabase
- add a sync status model and lightweight UI so Atlas can surface:
  - `local_only`
  - `ready_to_sync`
  - `syncing`
  - `sync_error`
  - `synced`
- define cloud-table SQL and RLS policy docs/migrations without making cloud success a prerequisite for app use

Expected file areas:
- `src/lib/supabase/` or `src/lib/backend/`
- `src/features/auth/`
- `src/features/settings/`
- `src/lib/sync/`
- `src/lib/database/` for sync metadata if needed
- `supabase/` or `docs/` for initial cloud schema and RLS migration assets
- `__tests__/features/auth/`
- `__tests__/lib/sync/`
- `app/(app)/` and auth routes only where account UI changes materially

Constraints for this slice:
- guest mode remains first-class
- local-first remains the operating mode; sync is additive
- no local data loss during upgrade to an account
- network failure must not block Today, logging, inventory, reminders, calculator, or timeline use
- keep onboarding/preferences in AsyncStorage only
- keep product/domain data in the structured local layer
- preserve privacy-first defaults and discreet mode behavior
- do not implement push notification or server-driven reminder logic in this slice

Recommended domain shape:
- `AuthSession`
  - `status: 'guest' | 'authenticated' | 'signed_out' | 'bootstrapping'`
  - `userId: string | null`
  - `email: string | null`
  - `lastBootstrapAt: string | null`
- `SyncStatus`
  - `mode: 'local_only' | 'ready_to_sync' | 'syncing' | 'sync_error' | 'synced'`
  - `lastSyncAt: string | null`
  - `pendingUploadCount: number`
  - `pendingDownloadCount: number`
  - `lastError: string | null`
- `GuestUpgradePlan`
  - local record counts by entity
  - migration readiness flags
  - account target id
- sync metadata records tied to local entities through stable IDs and ownership metadata rather than replacing local primary keys

Planned backend/schema scope:
- initial cloud tables for:
  - profiles
  - compounds
  - protocols
  - protocol_rules
  - vials
  - log_events
  - reminders
  - custom_metrics
  - sites
- ownership columns and timestamps required for sync
- RLS-by-owner policy plan:
  - authenticated users can only read/write rows matching their `auth.uid()`
  - no guest cloud writes
- migration assets are authored now, but network sync implementation remains intentionally thin and additive

Conflict strategy:
- local database remains the authoritative working set on device
- sync uploads and downloads compare stable entity IDs plus `updated_at`
- immutable history tables such as `log_events` resolve by append-only merge, not overwrite
- user-authored mutable entities such as `protocols`, `vials`, and `sites` use last-write-wins at the field-row level for v1, with conflict status surfaced if timestamps collide unexpectedly
- generated future schedule occurrences are never synced as source-of-truth records

Planned UI surfaces:
- auth shell:
  - email sign up
  - email sign in
  - sign out
  - guest upgrade CTA
- Settings:
  - account status card
  - sync status card
  - guest upgrade explanation
  - non-disruptive retry affordance for sync errors

Test gate for this slice:
- environment/config parsing tests
- auth session bootstrap tests
- guest upgrade preparation tests
- session state tests for guest, signed-in, and signed-out states
- sync boundary tests that confirm local use still works when sync errors occur
- typecheck passes
- existing onboarding, day-loop, reminder, inventory, and calculator tests remain green

#### Proposed slice: Prompt 7 and 8 Android manual QA pass
Purpose:
- verify the newly added auth/session/sync shell, exports, health-connection scaffolding, and Insights V1 on a real Android emulator flow
- produce a human-oriented checklist that can be reused after future iterations
- catch cross-feature regressions where guest mode, local-first exports, privacy controls, and insights logging interfere with each other

Planned checks:
- host verification:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`
- Android emulator manual verification:
  - guest-first usage still works without sign-in
  - auth screen renders and email sign-up/sign-in shell behaves safely when config is present or missing
  - Settings account status and sync status remain non-disruptive
  - export entry points create CSV and JSON without blocking the app
  - health connection toggles and adapter checks surface status without crashing or blocking other tabs
  - Insights logging for weight, symptom, and custom metrics persists and updates trend sections
  - amount-in-system estimate is explicitly labeled as an estimate/model
  - discreet/privacy behavior still prevents sensitive labels from leaking where expected
- iteration:
  - fix any runtime, data, or copy defects found during the pass
  - rerun the failing checklist steps until the full pass is green

Expected artifacts:
- `qa/` checklist for prompt 7 and prompt 8
- any focused Android helper updates needed to drive or observe the emulator
- targeted fixes for auth/settings/insights/export/health regressions discovered during the pass

Constraints for this slice:
- do not weaken guest-first behavior
- do not make network success a prerequisite for app use
- exports must continue to work for both guest and authenticated users
- health integrations must remain optional and failure-isolated
- keep amount-in-system framing explicitly descriptive and non-medical
- keep generated future occurrences separate from immutable historical logs

Test gate for this slice:
- checklist written
- emulator pass completed against the checklist
- typecheck passes
- test suite passes
- lint stays clean apart from generated-file warnings

#### Proposed slice: Hardening, QA, and private-alpha readiness
Purpose:
- harden the current Atlas dogfood build without reworking the architecture
- improve reliability, privacy safety, accessibility, and release clarity across the core loop
- leave the app in a state where a small private alpha can be exercised intentionally

Planned focus areas:
- end-to-end smoke coverage for the critical loop:
  - onboarding
  - app shell handoff
  - protocol creation
  - Today actions
  - Timeline reflection
  - reminders/settings checks
- loading, error, and empty-state polish across:
  - Today
  - Timeline
  - Library
  - Insights
  - Settings
- crash-safe guards around:
  - onboarding hydration
  - auth bootstrap
  - local database bootstrap
  - reminder preference loading
  - export and health adapter boundaries
- analytics scaffolding for:
  - `protocol_created`
  - `dose_logged`
  - `reminder_scheduled`
  - `low_stock_seen`
  - `export_requested`
- copy review for privacy-safe, neutral, app-store-safe wording
- accessibility pass on:
  - onboarding
  - Today
  - logging surfaces
  - Settings
- performance pass on:
  - Today occurrence rendering
  - Timeline feed rendering and filters

Implementation shape:
- add a lightweight analytics boundary with no-op or console-safe adapters in local/dev builds
- centralize alpha-readiness checklist and blocker notes under `qa/` or `docs/`
- add targeted guards/fallbacks rather than broad architectural rewrites
- expand Android smoke where the signal is stable, and rely on manual QA for native interaction edges
- tighten copy and accessibility labels in-place on existing screens and primitives

Expected file areas:
- `android/app/src/androidTest/`
- `qa/`
- `src/features/onboarding/`
- `src/features/today/`
- `src/features/timeline/`
- `src/features/settings/`
- `src/features/protocols/`
- `src/features/reminders/`
- `src/features/insights/`
- `src/providers/`
- `src/lib/analytics/`
- shared UI primitives under `src/components/ui/`
- `__tests__/`

Constraints for this slice:
- do not add marketing gimmicks or promotional copy
- do not rework architecture unless required for reliability
- preserve privacy-first wording and discreet-mode behavior
- do not weaken guest mode or make network success required
- keep generated future occurrences separate from immutable historical logs
- focus on reliability, privacy, and clarity over new feature breadth

Private alpha exit artifacts:
- a private-alpha readiness checklist
- documented critical UX gaps and launch blockers
- manual device-testable critical loop instructions
- analytics hook locations and current event coverage

Test gate for this slice:
- typecheck passes
- test suite passes
- lint passes apart from generated-file warnings
- Android smoke covers the critical loop as far as stable automation allows
- manual QA checklist exists for device validation
- alpha blockers are explicitly documented and prioritized

#### Proposed slice: Beta-candidate manual QA and stabilization pass
Purpose:
- evaluate whether the current Atlas build is strong enough to hand to outside beta testers
- exercise the app end to end using person-like flows on Android rather than stopping at unit or smoke automation
- iterate on any reliability, UX, privacy, or data-integrity regressions until the checklist is green or explicit beta blockers remain

Planned checks:
- host verification:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`
- Android emulator/device-style manual flows:
  - first launch and onboarding handoff
  - guest-first app shell navigation
  - protocol creation
  - Today next due / overdue / upcoming states
  - quick dose actions: taken, skip, reschedule
  - Timeline reflection and filters
  - reminder/privacy settings
  - inventory and linked vial behavior
  - calculator persistence
  - insights logging and export entry points
  - account/sync status surfaces with missing or present config
  - restart persistence and recovery
- release-readiness review:
  - identify anything that still feels too fragile, confusing, or privacy-risky for outside testers
  - distinguish hard blockers from acceptable beta rough edges

Expected artifacts:
- a human-oriented beta QA checklist under `qa/`
- notes on any beta blockers or notable rough edges under `docs/` or `qa/`
- targeted fixes for issues found during the pass

Constraints for this slice:
- do not weaken guest mode or privacy/discreet protections
- do not make network success a prerequisite for app use
- do not rewrite the architecture unless a defect truly requires it
- generated future occurrences must remain separate from immutable historical logs
- focus on confidence for a limited beta, not on adding new feature scope

Beta-candidate exit criteria:
- core loop is manually usable without crashes or route dead-ends
- local-first persistence survives relaunches
- privacy-sensitive surfaces behave correctly in discreet mode
- exports and optional integrations fail safely
- any remaining launch blockers are explicitly documented

#### Proposed slice: iOS readiness preflight before Mac QA
Purpose:
- reduce avoidable iOS setup friction before cloning Atlas to a Mac for Simulator/device QA
- catch Expo config, plugin, dependency, and platform-boundary issues that are likely to fail during `expo run:ios` or first iOS launch
- improve the odds that the first Mac-side QA pass is focused on product behavior, not setup churn

Current findings from the Windows-side preflight:
- `expo-notifications` is installed and used, but is not currently listed in the Expo plugin config
- `expo-doctor` reports SDK version drift in test tooling:
  - `jest-expo` should align to Expo SDK 54
  - `@types/jest` should align to the Expo-expected major
- no obvious TypeScript-only iOS blocker has been found in the current auth, storage, routing, health-adapter, or local database layers

Planned changes:
- add any missing Expo plugins/config needed for iOS-native modules already in use
- align Expo-related dev dependencies so `expo-doctor` is clean or materially cleaner
- tighten iOS-facing config where helpful:
  - notification permission copy and plugin wiring
  - secure-store / auth expectations
  - optional health-connection messaging so unsupported features fail safely
- add a concise iOS QA handoff checklist for the Mac pass
- update blocker docs if any remaining iOS-specific uncertainty cannot be resolved from this environment

Expected file areas:
- `app.json`
- `package.json`
- `package-lock.json`
- `docs/`
- `qa/`
- any small platform-guard or copy fixes if the audit reveals them

Constraints for this slice:
- do not pretend to certify iOS runtime behavior from Windows
- do not add real Apple Health integration yet
- do not make auth, reminders, or health connections mandatory for first launch
- keep guest mode and local-first behavior intact

Test gate for this slice:
- `npm run typecheck`
- `npm test -- --runInBand`
- `npm run lint`
- `npx expo-doctor`
- updated iOS handoff notes and remaining blocker list

#### Proposed slice: Protocol Change Studio V1
Purpose:
- make Atlas best-in-class at future-only protocol edits without corrupting history
- introduce deterministic preview-before-commit behavior for messy real-life schedule changes
- keep Today, Timeline, reminders, inventory, and site rotation consistent after committed changes

Core product requirements:
- preserve immutable historical `log_events`
- keep generated future occurrences separate from historical logs
- regenerate future reminders from the new effective revision only
- update inventory forecast and vial handoff semantics without double decrement
- create append-only audit entries for every committed change
- preview impact over `7`, `14`, and `30` days before saving
- keep the feature behind a feature flag until QA passes

Recommended implementation shape:
- keep `protocols` as stable user-facing identity rows
- add `protocol_revisions` as effective-dated future snapshots
- add `protocol_revision_rules` for base cadence, titration phases, and rest periods
- add `protocol_change_audit_events` for append-only edit history
- backfill one revision per existing protocol and transition schedule reads to the revision model
- build a pure preview engine that compares committed future state vs draft future state without writing rows

Supported V1 operations:
- future-only dose edit
- future-only time edit
- day-of-week change
- every-`N`-days change
- pause
- resume
- titration phase editing
- rest period editing
- missed-dose recovery policy change
- timezone/travel adjustment
- vial switch-over planning

Preview semantics:
- compare only occurrences on or after the selected effective date
- show `next due`, moved/added/removed future occurrences, reminder impact, inventory forecast impact, adherence semantics, and site rotation warnings
- keep preview calm, human-readable, and privacy-safe
- cancel writes nothing

Expected file areas:
- `docs/`
- `qa/`
- `src/lib/database/`
- `src/lib/database/repositories/`
- `src/lib/schedule/`
- `src/features/protocols/`
- `src/features/day-loop/`
- `src/features/reminders/`
- `src/features/inventory/`
- `src/features/timeline/`
- `src/features/library/`
- `app/(app)/`
- `__tests__/`

Dependency order:
1. Docs and acceptance criteria
2. Migration and repository layer for revisions and audit events
3. Revision-aware schedule generation and preview/diff engine
4. Commit path plus reminder and inventory regeneration
5. Protocol detail plus Protocol Change Studio UI flow
6. QA hardening under feature flag

Test gate for this slice:
- migration backfill tests for existing protocols
- revision selection tests
- preview diff tests for 7, 14, and 30 day horizons
- future-only edit preserving historical logs
- pause/resume reminder regeneration tests
- titration and rest-period recalculation tests
- timezone-change no-duplication tests
- vial switch-over no-double-decrement tests
- audit entry creation tests
- cancel-without-commit tests
- updated manual QA checklist under `qa/`
- `npm run typecheck`
- `npm test -- --runInBand`
- `npm run lint`

#### Proposed slice: Protocol Change Studio V1 QA and stabilization pass
Purpose:
- exercise the new revision-backed protocol editing flow like a human user would
- verify that preview, commit, cancel, reminders, inventory forecast, and audit history stay consistent across the app
- fix any runtime, routing, copy, or data-integrity defects before moving to the next feature

Planned artifacts:
- a human-oriented checklist under `qa/` for Protocol Change Studio
- any focused Android helper or automation updates needed to drive the emulator reliably
- targeted fixes for regressions discovered during the pass

Manual QA scope:
- launch from all intended entry points:
  - protocol detail
  - Today
  - Timeline
  - Library
- validate supported change operations:
  - future-only dose edit
  - future-only time edit
  - day-of-week change
  - every-`N`-days change
  - pause
  - resume
  - titration phase edit
  - rest period edit
  - missed-dose recovery policy change
  - timezone/travel adjustment
  - vial switch-over planning
- validate preview windows:
  - `7` days
  - `14` days
  - `30` days
- validate preview surfaces:
  - next due
  - upcoming reminders
  - inventory forecast
  - adherence wording
  - site rotation warnings when applicable
- validate commit/cancel semantics:
  - cancel commits nothing
  - commit creates audit entries
  - Today updates to the new future plan
  - Timeline/history reflects the change
  - reminders regenerate correctly
  - inventory forecast updates without double decrement

Constraints for this slice:
- do not mutate historical log events
- do not silently rewrite historical reminder history
- generated future occurrences must remain separate from immutable logs
- keep the feature flag in place while stabilizing
- prefer narrow fixes over architectural churn

Execution approach:
- create the checklist first
- run host verification:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`
- run Android emulator/manual QA against the checklist
- iterate on any failures until:
  - the checklist is green, or
  - explicit release blockers are documented

Test gate for this slice:
- checklist written
- emulator/manual pass completed against the checklist
- all failing steps either fixed and reverified or documented as blockers
- `npm run typecheck`
- `npm test -- --runInBand`
- `npm run lint`

#### Proposed slice: Trust Vault + Selective Sharing V1
Purpose:
- turn privacy-first into a consistent product system instead of a handful of toggles
- introduce alias mode, bounded selective sharing, local encryption, and user-visible sensitive-action history
- keep all privacy behavior local-first, guest-safe, and deterministic

Planned outcomes:
- unified privacy rendering policy across:
  - Today
  - Timeline
  - Library
  - Insights
  - Settings
  - notifications
  - exports and selective shares
- protocol-level alias / codename mode
- Trust Vault control center in Settings/app shell
- biometric gating for sensitive actions where available
- selective sharing with preview-before-export
- encrypted local share bundles with manifest versioning and integrity metadata
- sensitive-action audit viewer

Recommended implementation shape:
- add a durable `privacy_profile` record in the structured local database
- add `protocol_aliases` as presentation-only overlays on canonical protocol identity
- add `sensitive_action_audit_events` as append-only privacy-history records
- replace ad hoc privacy string formatting with one unified formatter/policy layer
- build selective-share preview and bundle generation from one deterministic selection pipeline
- keep encrypted bundles local-file based in v1; no public links or cloud requirement

Expected file areas:
- `docs/`
- `qa/`
- `src/lib/database/`
- `src/lib/database/repositories/`
- `src/features/reminders/privacy.ts` or successor module
- `src/features/today/`
- `src/features/timeline/`
- `src/features/library/`
- `src/features/insights/`
- `src/features/settings/`
- `src/features/exports/`
- `src/features/auth/` for biometric gate wiring only as needed
- `src/lib/`
- `__tests__/`

Constraints for this slice:
- keep local-first behavior intact
- do not require cloud accounts
- do not break guest mode
- do not mix generated future schedule occurrences with immutable historical logs
- no export or share may include more than the selected scope
- exports/imports must stay deterministic and inspectable
- alias mode must never overwrite canonical protocol or compound data
- cloud-backed sharing ideas remain feature-flagged and out of scope for v1

Proposed phases:
1. docs and acceptance criteria
2. migrations and repositories for privacy profile, aliases, and sensitive-action audit
3. unified privacy formatter rollout across app surfaces
4. Trust Vault UI and alias editing
5. biometric sensitive-action gate
6. selective-share preview and encrypted local bundle generation
7. QA/privacy leak hardening

Test gate for this slice:
- alias mode redaction tests across core surfaces
- reminder/export formatting tests through the unified privacy layer
- selective share preview vs exported bundle parity tests
- biometric gate tests around protected flows
- sensitive-action audit completeness tests
- guest-mode selective share tests
- alias-off restore tests proving canonical labels remain intact
- manual QA checklist under `qa/`
- `npm run typecheck`
- `npm test -- --runInBand`
- `npm run lint`

## Execution notes
- Build thin vertical slices, not the whole PRD.
- Keep schedule/protocol logic isolated from UI.
- Do not start sync before the local repositories and domain contracts are stable.
- Reuse the existing onboarding output rather than replacing it.

## Open product decisions to settle during milestone 1
- Which local database package will back the repository layer
- Initial protocol cadence set for v1 beyond weekly, daily, and every-N-days
- Whether inventory is balance-only or lot-aware in the first MVP
- Whether insights ship as a dedicated screen or as Today plus Timeline modules first
# Trust Vault QA And Hardening

- Fix review findings before the next feature:
  - route all export/share entry points through Trust Vault or equivalent sensitive-action gating
  - make selective-share preview and created bundle deterministic from the same preview snapshot
  - remove UI states that imply unsaved aliases are already part of the created bundle
- Add a human-oriented Android manual QA checklist for:
  - onboarding and guest path
  - Today / Timeline / protocol creation
  - reminders, inventory, insights, exports
  - Trust Vault alias mode, biometric gate, selective sharing, and audit trail
- Run emulator/manual QA and iterate until all checklist items pass
- Close with:
  - `npm run typecheck`
  - `npm test -- --runInBand`
  - `npm run lint`

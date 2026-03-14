# Testing Matrix

## Current coverage baseline
Implemented today:
- onboarding routing tests
- onboarding state tests
- onboarding persistence tests
- Android onboarding smoke tests

Not yet implemented:
- protocol domain tests
- schedule engine tests
- inventory tests
- timeline tests
- reminder tests
- auth upgrade tests

## Test strategy by layer
| Layer | Scope | Current status | Required gate |
| --- | --- | --- | --- |
| Typecheck | TypeScript compile safety | Implemented | Must pass on every milestone |
| Unit | Pure domain logic and selectors | Partial | Required for all new domain modules |
| Component | Screen and component behavior | Partial | Required for new core user flows |
| Integration | Store + repository + local database interactions | Not started | Required once database layer lands |
| Android smoke | First-run user-critical paths | Implemented for onboarding | Required for milestone completion on Android |
| Manual QA | UX fit and permission flows | Partial | Required where native behavior is involved |

## Milestone gates
### Milestone 1: Protocol setup and local database foundation
Required tests:
- protocol schema validation
- repository CRUD tests
- guest-mode protocol creation flow
- migration or hydration tests if a data bootstrap step exists

### Milestone 2: Schedule engine and next due
Required tests:
- cadence generation
- next due selection
- protocol edit regeneration
- multiple active protocols at once

### Milestone 3: Reminders
Required tests:
- reminder scheduling
- discreet notification copy
- rescheduling after edits
- permission-denied fallback behavior

### Milestone 4: Logging and inventory
Required tests:
- immutable log creation
- occurrence resolution
- inventory decrement from logs
- manual inventory adjustment

### Milestone 5: Timeline and insights
Required tests:
- timeline ordering
- merged generated and logged states
- descriptive insight calculations
- empty states

### Milestone 6: Auth and sync foundation
Required tests:
- guest-to-account migration
- conflict-safe sync assumptions at the repository layer
- auth token storage in SecureStore
- no regression of guest mode

## Manual QA matrix
| Area | Android | iOS | Web | Notes |
| --- | --- | --- | --- | --- |
| Onboarding flow | Required | Required when Mac is available | Optional | Already validated on Android |
| Privacy/discreet mode copy | Required | Required | Optional | Includes lock-screen notification checks |
| Protocol creation | Required | Required | Optional | First real post-onboarding flow |
| Next due on Today | Required | Required | Optional | Verify timezone/device date handling |
| Local reminders | Required | Required | No | Requires native behavior validation |
| Logging flow | Required | Required | Optional | Includes background/foreground resume |
| Inventory updates | Required | Required | Optional | Validate derived balances |
| Timeline rendering | Required | Required | Optional | Check long-history performance later |

## Regression priorities
Highest priority regressions:
1. onboarding persistence
2. guest mode
3. privacy/discreet mode behavior
4. next due accuracy
5. immutable logging
6. inventory correctness

## Done criteria for future milestones
A milestone is not done unless:
- typecheck passes
- relevant unit tests pass
- relevant component/integration tests pass
- Android smoke coverage exists for the user-critical path
- manual QA notes are updated when native behavior is involved

## Protocol Change Studio V1 gate
Required tests:
- revision backfill migration tests
- effective-dated revision selection tests
- preview diff tests for 7, 14, and 30 day horizons
- future-only edit preserving historical logs
- pause and resume occurrence/reminder regeneration tests
- titration and rest-period recalculation tests
- timezone-change no-duplication tests
- vial switch-over inventory tests
- audit entry creation tests
- cancel-without-commit tests

Manual QA must cover:
- launch from protocol detail, Today, Timeline, and Library
- preview readability for each supported change type
- commit and cancel behavior
- reminder regeneration
- inventory forecast changes
- Timeline audit visibility
- relaunch persistence

# Atlas Data Layer and Shell QA Checklist

## Scope
This checklist validates the current Atlas state after the local-first database layer was added:
- onboarding still works
- app shell still works
- Expo SQLite integration does not break startup
- typed repositories and migrations work
- iOS-risk audit is clear for the current code

## Execution note
- Branch logic, persistence, and completion invariants are validated primarily by Jest because they are deterministic domain concerns.
- Android emulator smoke is used to validate runtime launch/render and shell stability.
- On this Windows/emulator setup, synthetic button activation on React Native screens can be less reliable than real manual taps, so any failed touch-injection step should be cross-checked before treating it as a product regression.

## Host-level verification
- [ ] `npm run typecheck` passes
- [ ] `npm test -- --runInBand` passes
- [ ] Migration tests create all core tables
- [ ] Migration tests are idempotent
- [ ] Repository basics pass for compounds, protocols, protocol rules, vials, log events, reminders, custom metrics, and sites
- [ ] Onboarding tests still pass

## Android emulator smoke
- [ ] App launches without crash after `expo-sqlite` addition
- [ ] Splash -> intro -> onboarding still works
- [ ] GLP flow reaches the Today shell
- [ ] Peptide flow reaches the Today shell
- [ ] Both flow reaches the Today shell
- [ ] Explore-first flow reaches the Today shell
- [ ] Today shows `No protocols yet`
- [ ] Today shows `Create your first protocol`
- [ ] Today CTA opens the protocol setup placeholder
- [ ] Bottom tabs switch cleanly between Today, Timeline, Library, Insights, and Settings
- [ ] Settings renders privacy controls
- [ ] Settings can reset onboarding for QA and return to splash
- [ ] Auth placeholder route still works from intro

## Data-model invariants
- [ ] `log_events` remain immutable at the repository boundary
- [ ] No generated occurrence table is mixed into `log_events`
- [ ] Onboarding still uses AsyncStorage, not the structured database layer
- [ ] Product/domain data is isolated from UI code behind repositories

## iOS compatibility audit
- [ ] Database runtime uses cross-platform `expo-sqlite`, not Android-only APIs
- [ ] No Android-specific classes are imported into the TypeScript data layer
- [ ] No Windows- or Android-only file paths are referenced from runtime feature code
- [ ] The current code does not require a platform-specific sync implementation
- [ ] Remaining limitation is only execution environment: iOS simulator cannot be run on this Windows machine

# Atlas private alpha blockers

This list is intentionally narrow. It tracks launch blockers and near-blockers for a private alpha, not every future enhancement.

## Blockers

### 1. Device notification action QA is still required
- Priority: P0
- Why it matters: reminder scheduling logic is covered by tests, but device-level delivery and action handling (`Mark taken`, `Skip`, open app) still need a fresh physical-device pass before inviting outside testers.
- Current state: local scheduling, regeneration, and privacy formatting are implemented and tested in-app; runtime notification delivery remains a manual QA item.

### 2. Real Supabase environment smoke is still required
- Priority: P0
- Why it matters: auth/session bootstrap is implemented, but a real project URL/key smoke test is still needed to validate sign-in and sign-up behavior before inviting account-based testers.
- Current state: guest mode is production-usable; missing config remains non-blocking by design.

## Near-blockers

### 3. iOS runtime verification is still pending
- Priority: P1
- Why it matters: the codebase is now preflight-clean for iOS configuration, but this Windows environment still cannot certify a real iOS runtime pass.
- Current state: Expo config drift was fixed, `expo-notifications` is now declared in the Expo plugin list, and no known iOS-only code blocker has been identified in the current codebase.

### 4. Export destination UX needs one device review
- Priority: P1
- Why it matters: export generation is reliable locally, but the final share-sheet experience can vary by device and installed apps.
- Current state: share-sheet failure is now non-fatal and the export file is still written locally.

## Not blockers for private alpha
- Full cloud sync engine
- Apple Health / Health Connect real adapters
- Push notification backend
- Protocol edit/pause/titration UI
- Advanced insight modeling

## Recommended next QA order
1. Android physical-device pass for reminders and export flows
2. Supabase-configured auth smoke pass
3. Mac-based iOS dev-build smoke pass

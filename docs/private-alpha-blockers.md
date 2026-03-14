# Atlas native private beta blockers

This list is intentionally narrow. It tracks true blockers and near-blockers for shipping the native iOS app to a limited TestFlight beta.

## Blockers

### 1. Physical iPhone QA pass is still required
- Priority: P0
- Why it matters: simulator builds and tests are green, but final release confidence still needs a real-device pass for notifications, biometrics, share sheets, file handoff, and lifecycle/resume behavior.
- Current state: the native manual checklist exists in `qa/native-ios-release-manual-checklist.md`, but the physical-device run is not yet recorded in this repo.

### 2. Signed archive / TestFlight smoke is still required
- Priority: P0
- Why it matters: release builds compile locally, but an actual signed archive upload plus clean-install migration/import smoke is still required before inviting outside testers.
- Current state: clean Release builds for the app and extensions are green in this workspace; TestFlight packaging remains a final operational step.

## Near-blockers

### 3. Accessibility sweep on small and large iPhone sizes is still required
- Priority: P1
- Why it matters: VoiceOver, Dynamic Type, and smaller-screen layout regressions are easiest to miss in feature-heavy local-first apps.
- Current state: key flows are manually checklist-covered, but the final small-phone/large-phone accessibility pass is still open.

### 4. Analytics/crash sink hookup is still minimal by design
- Priority: P1
- Why it matters: beta builds benefit from basic observability, but Atlas should not over-collect sensitive data.
- Current state: onboarding analytics preference exists, but production telemetry remains intentionally lightweight and should be finalized only within privacy-policy bounds.

## Not blockers for native private beta
- Full cloud sync engine
- Rich HealthKit adapters
- Live/cloud-backed review sessions
- Widget/App Intents business logic expansion
- Post-beta pattern and export polish

## Recommended next QA order
1. Physical iPhone pass using `qa/native-ios-release-manual-checklist.md`
2. Signed archive + TestFlight upload smoke
3. Clean-install import/migration smoke with guest and imported-user fixtures

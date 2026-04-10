# Codex Launch Handoff

Last updated: 2026-04-10

## Current status

- Canonical repo root: `/Users/donghokang/Documents/New project 4/Atlas`
- iOS app root: `/Users/donghokang/Documents/New project 4/Atlas/atlas-ios`
- Atlas is now wired to a live Supabase project for launch auth/sync/review.
- Google auth is enabled in Supabase.
- Apple auth is enabled in Supabase for native iOS sign-in.
- Email/password auth is enabled in Supabase.
- Live review edge function and launch schema are deployed.

## Live backend

- Supabase project ref: `nppqywaxawvvdhiedpxc`
- Supabase URL is already set in `atlas-ios/Atlas/Info.plist`.
- Supabase anon key is already set in `atlas-ios/Atlas/Info.plist`.
- Redirect allow-list includes `atlas://**`.
- Google provider is configured and enabled.
- Apple provider is configured for native iOS flow and enabled.

## Code already landed

- `atlas-ios/Packages/AtlasSystem/Sources/AtlasSystem/AtlasCloudSync.swift`
  - email/password auth
  - Google OAuth via `ASWebAuthenticationSession`
  - native Apple sign-in via `AuthenticationServices`
  - snapshot upload/download
  - live review create/revoke
- `atlas-ios/Atlas/Atlas.entitlements`
  - Sign in with Apple entitlement added
- `backend/supabase/migrations/20260409_public_launch_infra.sql`
  - launch auth/sync/live-review tables and RLS
- `backend/supabase/functions/live-review-session/index.ts`
  - live review create/get/revoke

## Validation completed

- Full app-target build succeeded from a clean temp scheme build:
  - temp project: `/tmp/AtlasAppOnly/atlas-ios`
  - built app: `/tmp/AtlasAppOnly/DerivedDataScheme/Build/Products/Debug-iphonesimulator/Atlas.app`
  - log: `/tmp/atlas-scheme-build.log`
- Simulator smoke completed on booted simulator `iPhone 17`:
  - onboarding
  - start mode `Sign in`
  - privacy step
  - track type `Explore first`
  - optional profile skip
  - HealthKit prompt `Connect later`
  - shell launch into Today
  - relaunch back into shell
- Installed app state was verified in simulator SQLite:
  - `account_mode = account`
  - `account_start_mode = signIn`
  - `onboarding_completed = 1`
  - `apple_health` row exists in `health_connections` with `enabled = 0`, `connected = 0` after skipping connection
- Deep-link runtime smoke passed:
  - `atlas://weight-entry?...` routed to Insights
  - inserted a real row in `weight_logs`
- Hosted backend smoke passed directly against live Supabase:
  - signup `200`
  - snapshot sync insert `201`
  - live review create `200`
  - live review fetch `200`
  - live review revoke `200`
  - revoked fetch returns `410 Session revoked`

## Remaining launch work

- Real in-app Google sign-in validation on simulator/device
- Real in-app Apple sign-in validation on device
- Sign-out and session restore validation after provider sign-in
- Real-device HealthKit permission/read/write validation
- Real-device notifications/reminders validation
- Real-device biometrics / Trust Vault validation
- Final archive/signing/TestFlight/App Store release operations

## Important environment note

- The original repo location under `Documents` contains file-provider/iCloud-style `dataless` files that can stall raw `xcodebuild`.
- When the native build lane hangs on project/package resolution, reuse the temp copied project strategy under `/tmp/AtlasAppOnly/atlas-ios`.
- XcodeBuildMCP transport was unavailable in this thread, so shell-driven simulator control was used instead.

# Codex Launch Handoff

Last updated: 2026-04-16 (UX + security + onboarding/paywall + ambient mascot handoff)

## Current status

- Canonical local repo root for Codex + Xcode: `/Users/donghokang/Developer/Atlas`
- Canonical iOS app root for Xcode: `/Users/donghokang/Developer/Atlas/atlas-ios`
- Legacy repo copy still exists at `/Users/donghokang/Documents/New project 4/Atlas`, but it should not be used for active Xcode work.
- Atlas is now wired to a live Supabase project for launch auth/sync/review.
- Google auth is enabled in Supabase.
- Apple auth is enabled in Supabase for native iOS sign-in.
- Email/password auth is enabled in Supabase.
- Live review edge function and launch schema are deployed.
- `master` has been pushed with the current Atlas iOS launch tree.

## Current Codex context

Fresh Codex threads should treat the following repo files as the current high-value handoff set:

- `AGENTS.md`
- `README.md`
- `atlas-ios/README.md`
- `docs/backlog-execution-handoff.md`
- `docs/ios-premium-ui-rubric.md`
- `docs/ios-ui-audit-2026-04-10.md`
- `docs/ios-ui-skill-stack.md`
- `docs/ios-ux-execution-playbook-2026-04-15.md`
- `docs/ios-redesign-context-2026-04-14.md`
- `docs/ios-ui-polish-thread-handoff-2026-04-16.md` for the April 16 practical cleanup rules around copy density, stat tiles, keyboard exits, quick actions, Account & Sync, recap clutter, and mascot restraint
- `docs/ios-ui-mascot-rewards-changelog-2026-04-14.md`
- `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` for ambient mascot placement, motion policy, suppression, and QA rules
- `docs/mascot-concepts/atlas-mascot-asset-matrix.md` for mascot/rewards/media/widget work
- `docs/ios-onboarding-paywall-handoff-2026-04-16.md` for the proof-led onboarding, free-trial paywall, and premium conversion strategy
- `docs/fresh-codex-thread-prompt.md` for a copy/paste fresh-thread starter prompt

## 2026-04-16 onboarding + paywall context

The current native onboarding flow is intentionally long and proof-led.

Preserve these decisions unless the user explicitly changes product strategy:

- show enough premium differentiation before the paywall to make the trial feel earned
- keep the free-trial paywall before full protocol creation
- use the flow to prove Today command, Trust Vault, system surfaces, companion continuity, protocol change history, review output, and messy-start migration
- keep monthly/yearly auto-renewing subscription options behind a clear free-trial timeline
- avoid peptide marketplace, sourcing, medical advice, generic AI coach, or noisy gamification framing

Use `docs/ios-onboarding-paywall-handoff-2026-04-16.md` before editing onboarding or the paywall.

## Live backend

- Supabase project ref: `nppqywaxawvvdhiedpxc`
- Supabase URL is already set in `atlas-ios/Atlas/Info.plist`.
- Supabase anon key is already set in `atlas-ios/Atlas/Info.plist`.
- Redirect allow-list includes `atlas://**`.
- Google provider is configured and enabled.
- Apple provider is configured for native iOS flow and enabled.
- `live-review-session` was redeployed from CLI on 2026-04-10.
- Remote migration history now includes both:
  - `20260410023520_Atlas public launch infra.sql`
  - local idempotent launch migration `20260409_public_launch_infra.sql`
- local cloud hardening follow-up now also exists:
  - `20260415_live_review_session_hardening.sql`

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
- `backend/supabase/migrations/20260415_live_review_session_hardening.sql`
  - `purge_after` retention support for live review sessions
  - index for retention cleanup

## 2026-04-15 UX context

The large UX / interaction pass in the current working tree established a few standing rules that future threads should preserve:

- root tabs should feel finite and decisive, not like endless same-weight card stacks
- `Today`, `Insights`, and `Settings` are the first places to check when the app starts feeling long or messy
- progressive disclosure is preferred over exposing every subsystem at the root
- do not add fake-sounding `Atlas ...` helper narration or other LLM-ish filler copy
- title-first, literal, sparse copy is preferred on action surfaces
- the current docked bottom tab shelf remains the baseline shell treatment
- transparent / see-through bottom-tab experiments were tried and rejected because they made the shell feel unresolved

Use:

- `docs/ios-ui-skill-stack.md` for the standing UI skill stack
- `docs/ios-ux-execution-playbook-2026-04-15.md` for the combined navigation / scroll / interaction / accessibility lens
- `docs/ios-ui-polish-thread-handoff-2026-04-16.md` before broad UI cleanup, form-entry, copy pruning, quick-action, or mascot/rewards polish work

## 2026-04-16 ambient mascot context

The ambient mascot system is now a production-oriented companion layer, not a prototype pet or free-roaming character.

Preserve these rules:

- the mascot is anchored to calm surfaces and the tab shelf, not every screen
- Subtle is the default production presence; Off and More alive remain user controls
- serious-mode suppression hides/quiets the mascot during sheets, exports, dense entry, and trust-sensitive flows
- future expansion should prefer event-based reactions over new permanent perches
- Aetherion and Aurielle should keep behavior parity unless there is an explicit product reason to diverge

Use `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` before touching mascot placement, animation, suppression, rewards continuity, or mascot QA.

## 2026-04-15 security context

The current working tree also includes cloud-layer hardening that future threads should preserve:

- Atlas Cloud session credentials moved away from legacy `UserDefaults` persistence into a Keychain-backed store
- live review links no longer depend on server-visible query-string bearer tokens by default; the token now rides in the URL fragment and is handed to the fetch path via header
- live review rows now support retention cleanup through `purge_after`

This work is code-complete locally, but the Supabase migration and edge function still need the normal deploy/apply flow before the hosted backend is updated.

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

- The original repo location under `Documents` contains file-provider/iCloud-style metadata on the Xcode project and can make Xcode go gray / spin indefinitely.
- The durable fix was to clone the repo to `/Users/donghokang/Developer/Atlas` and use that path as the canonical local checkout.
- Do not use the `Documents` copy for active Xcode work unless there is a specific reason to inspect old local state.
- If the native build lane still hangs even from the `Developer` path, reuse the temp copied project strategy under `/tmp/AtlasAppOnly/atlas-ios`.
- XcodeBuildMCP transport was unavailable in this thread, so shell-driven simulator control was used instead.

# Atlas Prompt 7 + 8 Android Manual QA Checklist

Use this after a clean Android launch. Treat any failed item as a stop-and-fix condition before moving on.

## Setup
- [ ] Atlas opens on Android without a red screen, blank screen, or stuck splash.
- [ ] If state is stale, use `Settings -> Reset onboarding for QA` or clear app data, then relaunch.
- [ ] App shell tabs render: `Today`, `Timeline`, `Library`, `Insights`, `Settings`.

## Guest-first baseline
- [ ] Atlas remains usable without any account setup.
- [ ] `Today`, `Timeline`, `Library`, `Insights`, `Inventory`, `Calculator`, and logging still work in guest mode.
- [ ] No auth wall blocks protocol creation, reminders, logging, inventory, exports, or insights.

## Account + sync status
- [ ] Open `Settings`.
- [ ] `Account status` card renders.
- [ ] `Sync status` card renders.
- [ ] Account card shows one of:
  - `Guest`
  - `Guest-only build`
  - `Signed in`
- [ ] Sync card uses non-blocking copy and does not imply that network is required to keep using Atlas.
- [ ] `Refresh local sync status` works and does not crash.
- [ ] If Supabase env is missing, the CTA explains that Atlas stays guest-first.
- [ ] If Supabase env is present, the CTA opens the auth screen.

## Auth shell
- [ ] Open the auth screen from `Settings` or onboarding intro if available.
- [ ] `Create account` and `Sign in` mode pills render.
- [ ] Email and password fields render.
- [ ] `Keep using guest mode` returns safely to the previous flow.
- [ ] If config is missing:
  - [ ] account CTA is disabled
  - [ ] guest-mode fallback copy is visible
  - [ ] app remains fully usable
- [ ] If config is present:
  - [ ] submission validates invalid email/password input
  - [ ] no crash occurs on sign-in or sign-up attempt
  - [ ] returning to Settings updates account/session UI correctly

## Exports
- [ ] In `Settings`, `Data export` section renders.
- [ ] `Create CSV export` works.
- [ ] `Create JSON export` works.
- [ ] Export action does not freeze or crash the app.
- [ ] Success copy appears after export.
- [ ] Export remains available in guest mode.
- [ ] Export remains available if signed in.

## Health connection scaffolding
- [ ] In `Settings`, `Health connections` section renders.
- [ ] Provider cards render with platform labels.
- [ ] Enabling a provider toggle updates selected state.
- [ ] `Check provider adapter` returns status or scaffold message without crashing.
- [ ] Unavailable providers show safe, non-blocking status.
- [ ] Failing provider checks do not block navigation or the rest of the app.

## Insights quick logging
- [ ] Open `Insights`.
- [ ] Screen renders without placeholder-only content.
- [ ] `Log today’s context` section renders.
- [ ] Weight form renders and saves an entry.
- [ ] Symptom form renders and saves an entry.
- [ ] Custom metric form renders and can:
  - [ ] create a new metric
  - [ ] save a metric entry
  - [ ] show saved metrics in the lower section

## Insights sections
- [ ] `Weight trend` renders and updates after saving a weight entry.
- [ ] `Symptoms in the last two weeks` renders and updates after saving a symptom.
- [ ] `Inventory burn-down` renders existing vial state without crashing.
- [ ] `Routine follow-through` renders adherence counts.
- [ ] `Estimated amount-in-system` renders only descriptive copy.
- [ ] Estimate disclaimer is clearly visible and understandable.
- [ ] No insight card gives medical advice, dosing guidance, or treatment claims.

## Privacy and discreet behavior
- [ ] In `Settings`, enable `Discreet notifications`.
- [ ] In `Settings`, enable `Hide sensitive labels`.
- [ ] Reminder preview switches to generic/private wording.
- [ ] `Today` avoids leaking sensitive labels.
- [ ] `Timeline` avoids leaking sensitive labels.
- [ ] `Settings` preview/status copy remains privacy-safe.
- [ ] Returning to `Insights` does not introduce any new sensitive-label leak.
- [ ] Disabling discreet mode restores explicit labels where expected.

## Cross-feature stability
- [ ] Exports still work after insight entries are added.
- [ ] Health connection checks still work after insight entries are added.
- [ ] `Today` and `Timeline` still load after using `Insights`.
- [ ] `Settings` still shows correct sync/account status after using exports and health controls.
- [ ] App restart preserves:
  - [ ] local insight entries
  - [ ] export availability
  - [ ] health connection toggle state
  - [ ] guest/account status

## Fail conditions
- [ ] No red screens.
- [ ] No blank screens.
- [ ] No CTA that appears tappable but does nothing.
- [ ] No export action that silently fails.
- [ ] No health adapter failure that blocks the rest of the app.
- [ ] No sensitive label leak while discreet mode is enabled.
- [ ] No copy that drifts into advice or recommendations.

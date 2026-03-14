# Atlas Native iOS Release Manual Checklist

Use this checklist on a real iPhone before inviting external TestFlight users.

## Setup
- [ ] Install a fresh build on device.
- [ ] Confirm cold launch reaches a visible app state with no blank screen.
- [ ] Prepare two fixture states:
- [ ] Guest first-run user.
- [ ] Imported local user with protocols, logs, reminders, inventory, aliases, metrics, and audits.

## First-run onboarding
- [ ] Complete guest onboarding.
- [ ] Verify account boundary options render: guest, create account, sign in.
- [ ] Verify privacy/discreet choice appears before health connection prompt.
- [ ] Verify GLP, peptide, both, and explore-first branching is reachable.
- [ ] Verify connect-later path stays non-blocking.
- [ ] Verify plan-ready summary routes into the app shell.

## Import and migration
- [ ] Import Atlas JSON on a clean install.
- [ ] Confirm imported users bypass forced onboarding.
- [ ] Confirm protocols, timeline, reminders, inventory, aliases, and metrics appear after import.
- [ ] Run replace-import and confirm a backup export is created first.
- [ ] Confirm canceling an import writes nothing partial.

## Core loop
- [ ] Create a new protocol natively.
- [ ] Edit core fields natively.
- [ ] Confirm Today shows next due, overdue, and upcoming states.
- [ ] Log taken, skipped, and rescheduled actions from Today.
- [ ] Confirm Timeline records immutable entries correctly.

## Protocol Change Studio
- [ ] Open Change Studio from protocol detail.
- [ ] Open Change Studio from Today or Timeline.
- [ ] Preview a future-only dose or time change over 7/14/30 day windows.
- [ ] Commit a pause or resume change and confirm future occurrences/reminders update without mutating past logs.
- [ ] Cancel a preview and confirm no partial writes occur.

## Reminders
- [ ] Request notification permission.
- [ ] Receive a local reminder on device.
- [ ] Verify `Mark taken` works from the notification.
- [ ] Verify `Skip` works from the notification.
- [ ] Verify tapping the notification opens Atlas safely.
- [ ] Verify discreet or alias mode reminder copy never leaks sensitive labels.

## Inventory, calculator, and sites
- [ ] Create/edit/archive a vial.
- [ ] Link and unlink a vial to a protocol.
- [ ] Log a taken dose and confirm linked inventory decrements once.
- [ ] Apply a manual correction and confirm audit history is visible.
- [ ] Save a calculator profile and reopen it after relaunch.
- [ ] Pick a site during dose logging and confirm rotation cues update.

## Trust Vault and privacy
- [ ] Open Trust Vault home.
- [ ] Change between full, alias, and discreet render modes.
- [ ] Edit a protocol alias/codename.
- [ ] Confirm Today, Timeline, Library, Inventory, Insights, and notifications all honor the chosen privacy mode.
- [ ] Enable biometric protection and verify the sensitive action prompt appears.
- [ ] Review the sensitive-action audit viewer.

## Selective sharing, exports, and provider handoff
- [ ] Preview a selective share in alias mode.
- [ ] Generate an encrypted static share bundle.
- [ ] Confirm the preview counts match the generated bundle contents.
- [ ] Create a raw JSON export and a CSV export.
- [ ] Cancel the share sheet and confirm the app stays usable.
- [ ] Generate a provider handoff snapshot with a bounded scope and confirm no out-of-scope data appears.

## Review Mode
- [ ] Create a static review pack from a bounded scope.
- [ ] Import that review pack into the reviewer workspace.
- [ ] Confirm all review surfaces are read-only.
- [ ] Confirm out-of-scope data is absent.

## Insights and Episode Intelligence
- [ ] Add or inspect weight, symptom, and custom metric entries.
- [ ] Confirm weight trend, symptom trend, inventory burn-down, adherence, and amount-in-system sections render.
- [ ] Confirm episode cards use restrained, descriptive copy with disclaimers.
- [ ] Confirm alias/discreet rendering holds on Insights and episode summaries.

## Settings and lifecycle
- [ ] Verify account mode, sync scaffold, health scaffold, import entry, reminder settings, and Trust Vault entry all render in Settings.
- [ ] Force-quit and relaunch the app.
- [ ] Confirm local data persists across relaunch.
- [ ] Confirm guest mode remains usable without any cloud account.

## Accessibility and polish
- [ ] Verify Dynamic Type on a small iPhone size.
- [ ] Verify VoiceOver can reach core actions on Today, Library, Trust Vault, and onboarding.
- [ ] Verify long timelines and insights remain responsive on device.

## Stop-ship failures
- [ ] Any privacy leak in alias/discreet mode.
- [ ] Any mutation of immutable historical logs.
- [ ] Any import/export path that partially writes after cancel or failure.
- [ ] Any crash in reminder actions, Trust Vault, provider handoff, Review Mode, or Episode Intelligence.
- [ ] Any onboarding path that blocks guest-mode use.

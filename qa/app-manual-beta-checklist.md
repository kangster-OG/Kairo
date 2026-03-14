# Atlas Android Manual Beta Checklist

Use this checklist on a clean Android launch. Stop and fix any failed item before moving on.

## Setup
- [ ] Atlas opens without a red screen, blank screen, or endless loading.
- [ ] If state is stale, use `Settings -> Reset onboarding for QA` or clear app data before retesting.
- [ ] The app shell loads with `Today`, `Timeline`, `Library`, `Insights`, and `Settings`.

## Onboarding and guest path
- [ ] First launch can still complete onboarding as a guest.
- [ ] Privacy/discreet settings appear before any health connection prompt.
- [ ] Summary routes into the real app shell.
- [ ] Guest mode remains fully usable after onboarding.

## Core daily loop
- [ ] A protocol can be created from `Today` or `Library`.
- [ ] `Today` shows next due / upcoming information after protocol creation.
- [ ] `Mark taken`, `Skip`, and `Reschedule` all work from `Today`.
- [ ] `Timeline` reflects created / taken / skipped / rescheduled history.
- [ ] Historical items remain visible after app restart.

## Inventory and calculator
- [ ] Inventory screen loads and can create a vial.
- [ ] A vial can be linked to a protocol.
- [ ] Taken logs decrement linked vial quantity.
- [ ] Low-stock UI appears when threshold is crossed.
- [ ] Manual inventory correction works.
- [ ] Reconstitution calculator produces a neutral math result and can save a profile.

## Insights
- [ ] Weight entry saves and shows up in `Weight trend`.
- [ ] Symptom entry saves and shows up in `Symptoms`.
- [ ] Custom metric can be created and logged.
- [ ] `Estimated amount-in-system` stays clearly labeled as an estimate/model.
- [ ] No insight copy drifts into dose guidance or medical advice.

## Protocol Change Studio
- [ ] Protocol detail opens from `Library`.
- [ ] Change Studio opens from protocol detail, `Today`, and `Timeline`.
- [ ] Preview works for at least:
  - [ ] future-only time change
  - [ ] cadence change
  - [ ] pause
  - [ ] resume
- [ ] Cancel commits nothing.
- [ ] Commit updates `Today` and `Timeline` without rewriting past log history.

## Reminders and privacy
- [ ] Reminder settings load in `Settings`.
- [ ] Reminder privacy modes switch between full / generic / silent.
- [ ] Discreet mode hides sensitive labels in `Today`, `Timeline`, and `Settings` previews.
- [ ] Reminder preview respects current privacy mode.

## Trust Vault
- [ ] `Settings -> Open Trust Vault` works.
- [ ] Trust Vault loads aliases, privacy profile, and audit history.
- [ ] Alias mode can be toggled on and off.
- [ ] Saving a protocol alias persists and changes app labels where expected.
- [ ] Biometric lock toggle updates without crashing.
- [ ] If biometric lock is on, Trust Vault requires unlock before sensitive actions.

## Selective sharing
- [ ] Selective share scope pills render.
- [ ] Current protocol scope requires an explicit protocol selection.
- [ ] Custom date range requires both dates.
- [ ] Preview renders before export.
- [ ] Creating an encrypted bundle works.
- [ ] Creating and sharing a bundle works when the share sheet is available.
- [ ] Audit history records bundle creation.
- [ ] Bundle/export flow remains available in guest mode.

## Settings and auth shell
- [ ] Account status renders without blocking core app use.
- [ ] Sync status renders as additive/non-blocking.
- [ ] Health connection scaffolding remains optional and non-blocking.
- [ ] Auth shell can open without trapping the user.
- [ ] Export entry point now routes through Trust Vault instead of bypassing privacy controls.

## Restart and persistence
- [ ] Restart preserves onboarding completion.
- [ ] Restart preserves protocols, logs, inventory, insights, and aliases.
- [ ] Restart preserves Trust Vault privacy settings.
- [ ] Restart preserves guest usability even if auth/sync is unavailable.

## Fail conditions
- [ ] No blank screens.
- [ ] No red screens.
- [ ] No tappable CTA that does nothing.
- [ ] No sensitive labels leak while alias/discreet mode is active.
- [ ] No export/share flow bypasses Trust Vault privacy policy.
- [ ] No action mutates past log history.

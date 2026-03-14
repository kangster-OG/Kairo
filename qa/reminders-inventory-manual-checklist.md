# Atlas Prompt 5 + 6 Manual QA Checklist

Use this checklist on the Android emulator after a fresh app launch. Stop and fix any failure before moving on.

## Setup
- [ ] Metro/dev client is running and Atlas opens without a red screen or blank screen.
- [ ] If starting from a dirty state, use `Settings -> Reset onboarding for QA` or clear app data before testing.

## Baseline path
- [ ] Open Atlas and land in the app shell.
- [ ] `Today`, `Timeline`, `Library`, `Insights`, and `Settings` tabs all render.
- [ ] Existing protocol data, if any, loads without a crash.

## Reminder settings
- [ ] Open `Settings`.
- [ ] `Reminder settings` card renders with:
  - `Enable local reminders`
  - lead time pills
  - `Full detail`, `Generic reminder`, and `Silent mode`
- [ ] Switching lead time updates the selected state.
- [ ] Switching reminder privacy mode updates the selected state.
- [ ] Settings preview text updates to match the chosen reminder mode.

## Discreet mode enforcement
- [ ] In `Settings`, enable `Discreet notifications`.
- [ ] In `Settings`, enable `Hide sensitive labels`.
- [ ] Reminder preview changes to generic/private wording and does not show the protocol name.
- [ ] Go to `Today`.
- [ ] Next-due or overdue labels switch to `Private ... protocol` wording instead of the saved protocol name.
- [ ] Go to `Timeline`.
- [ ] Timeline item summaries use private wording:
  - `Logged a private dose as taken`
  - `Skipped a private dose`
  - `Rescheduled a private dose`
  - `Created a private protocol`
- [ ] Timeline card secondary label shows `Private protocol`.
- [ ] Return to `Settings` and disable discreet mode flags.
- [ ] Reminder preview, Today, and Timeline return to explicit protocol names.

## Inventory and vials
- [ ] Open `Library`.
- [ ] `Inventory` and `Calculator` entry buttons render.
- [ ] Open `Inventory`.
- [ ] Inventory screen renders:
  - quick tools card
  - `Add a vial`
  - `Protocol inventory settings`
  - `Injection sites`
- [ ] Add a vial with:
  - label
  - linked protocol
  - starting quantity
  - remaining quantity
  - quantity unit
  - low stock threshold
- [ ] Saved vial appears in the list.
- [ ] Quantity label shows remaining and starting values.
- [ ] Low-stock badge appears correctly when remaining quantity is at or below threshold.
- [ ] Projected depletion copy appears when the vial is linked to an active protocol.
- [ ] Manual correction updates the displayed remaining quantity.
- [ ] Delete vial removes it from the list and clears linked-vial state from any protocol that was using it.

## Protocol inventory settings
- [ ] In `Inventory`, protocol cards list cadence and saved amount.
- [ ] Linking a vial to a protocol updates the selected state immediately.
- [ ] `Track injection sites` toggle updates immediately.
- [ ] `Rotate suggested sites` stays disabled until site tracking is enabled.
- [ ] When enabled, both toggles persist after navigating away and back.

## Site tracking
- [ ] In `Inventory`, add at least two sites with body areas.
- [ ] Sites appear in the saved site list.
- [ ] Go to `Today`.
- [ ] Tap `Mark taken` on the due item for a protocol with site tracking enabled.
- [ ] Dose log modal shows an `Injection site` section.
- [ ] A site can be selected.
- [ ] If rotation is enabled, the modal shows the rotation helper copy.

## Logging updates inventory
- [ ] With a linked vial on the active protocol, note the vial remaining quantity.
- [ ] Log a taken dose from `Today`.
- [ ] Return to `Inventory`.
- [ ] Remaining vial quantity is decremented.
- [ ] `Skip` does not decrement inventory.
- [ ] `Reschedule` does not decrement inventory.

## Calculator
- [ ] Open `Calculator`.
- [ ] Calculator renders all required inputs:
  - profile label
  - powder amount + unit
  - diluent volume + unit
  - draw volume + unit
- [ ] Result card updates with:
  - concentration equation
  - delivered amount
  - explicit neutral explanation
- [ ] Result copy does not recommend dosing or timing.
- [ ] Save calculator profile works.
- [ ] Saved profile appears in the list.
- [ ] `Load` restores the saved values.
- [ ] `Delete` removes the saved profile.

## Timeline consistency
- [ ] `Created protocol` entry exists for the active protocol.
- [ ] `Logged dose`, `Skipped dose`, and `Rescheduled dose` entries appear after those actions.
- [ ] Timeline filters by protocol and date still work after inventory/site changes.

## Fail conditions
- [ ] No red screens.
- [ ] No blank screens.
- [ ] No button taps that do nothing.
- [ ] No sensitive protocol label leaks while discreet mode is enabled.
- [ ] No inventory changes on skipped or rescheduled actions.
- [ ] No silent mutation of historical timeline entries.

# Protocol Change Studio V1 manual QA checklist

## Goal
Verify that future-only protocol changes stay safe, human-readable, and consistent across Today, Timeline, reminders, and inventory.

## Test setup
1. Launch Atlas on Android.
2. Use guest mode or an existing local profile.
3. Create one active protocol if needed.
4. Create two vials for that protocol:
   - `Primary vial`
   - `Travel vial`
5. Link the protocol to `Primary vial`.
6. Turn reminders on in Settings with any visible privacy mode.
7. Add at least one saved site and enable site tracking if available.
8. Confirm Today shows a real next due item before opening Protocol Change Studio.

## Entry point checks
1. From Today:
   - open the next due card
   - tap `Change future plan`
   - confirm Protocol Change Studio opens
2. From Library:
   - open the saved protocol card
   - tap `Open detail`
   - confirm protocol detail loads
   - tap `Change future plan`
3. From Timeline:
   - log at least one action if needed so a feed item exists
   - tap `Adjust future plan`
   - confirm Protocol Change Studio opens
4. From protocol detail:
   - confirm the protocol detail screen shows:
     - current future plan
     - linked infrastructure
     - audit history
     - `Change future plan`

## Preview baseline
For any change type:
1. Confirm preview window chips for `7 days`, `14 days`, and `30 days`
2. Switch across all three windows
3. Confirm the preview updates and remains readable
4. Confirm these sections render when preview succeeds:
   - `What changes`
   - `Next due`
   - `Upcoming reminders`
   - `Inventory forecast`
   - `Occurrence changes`
5. If site warnings appear, confirm the copy is calm and understandable

## Commit and cancel baseline
1. Open the studio and change one future field.
2. Tap `Cancel`.
3. Confirm nothing changes in:
   - Today next due
   - Library protocol card
   - protocol detail audit history
4. Reopen the studio and make the same change.
5. Tap `Commit future change`.
6. Confirm:
   - Today reflects the new future plan
   - protocol detail audit history has a new item
   - Timeline shows a `Changed` event
   - past logged dose items remain unchanged

## Change type checks
Run each change below at least once and verify preview plus commit:

1. Future dose
   - change the saved amount
   - confirm preview summary is obvious
   - confirm Today shows the new saved amount after commit

2. Future time of day
   - change the future time
   - confirm reminder preview updates
   - confirm no past events change

3. Day of week
   - switch to another weekday
   - confirm next due changes as expected

4. Every N days
   - switch from weekly to every `2` or `3` days
   - confirm upcoming occurrences change without duplication

5. Pause
   - set an effective pause
   - confirm Today reflects the pause state safely
   - confirm future reminders shift or clear appropriately

6. Resume
   - resume after a paused protocol
   - confirm a future next due returns

7. Titration
   - add a titration amount and length
   - confirm the preview reflects a staged future phase

8. Rest period
   - add a rest period
   - confirm the preview communicates the gap clearly

9. Missed-dose recovery policy
   - switch among the available policy options
   - confirm the adherence/summary copy changes

10. Timezone / travel
   - change the timezone value
   - confirm no duplicate future occurrences appear after commit

11. Vial switch-over
   - switch from `Primary vial` to `Travel vial`
   - confirm the preview references the future handoff
   - later log a taken dose and confirm only the active vial decrements

## Cross-surface consistency
After several committed changes:
1. Today:
   - next due matches the current future plan
   - no duplicate upcoming entries
2. Timeline:
   - old dose history is still intact
   - change audit entries appear as new `Changed` items
3. Library:
   - protocol card reflects the current future cadence
4. Protocol detail:
   - audit history is append-only
5. Inventory:
   - forecast changes are visible when relevant
   - past balances are not silently rewritten
6. Reminders:
   - future reminder copy or timing reflects the new plan

## Edge checks
1. Use an effective date on the same day as the next due item.
2. Pause and then resume with a later effective date.
3. Apply a timezone change and verify no double future entries.
4. Commit a vial switch and then log a dose.
5. Start a change, back out, reopen, and confirm the canceled draft did not persist.

## Stop-ship failures
- historical dose events change
- duplicate future occurrences appear
- duplicate inventory decrement happens after a vial switch
- cancel commits any change
- reminders for the future do not match the committed revision
- audit entry is missing after commit
- preview sections are blank, misleading, or crash-prone

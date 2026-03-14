# Atlas Daily-Use Loop Manual Smoke Script

## Goal
Verify the first real daily-use loop by hand on the Android emulator:
- create a protocol
- see a real next due item
- log actions from Today
- confirm Timeline reflects those actions

## Prep
1. Start Metro:
   `npx expo start --dev-client --clear`
2. Ensure the emulator is connected and reverse port 8081:
   `adb reverse tcp:8081 tcp:8081`
3. Clear app data:
   `adb shell pm clear com.david.atlas`
4. Open Atlas.

## Pass 1: Create a protocol
1. Open `Today`.
2. Confirm the empty state says `No protocols yet`.
3. Tap `Create your first protocol`.
4. Leave `GLP` selected and tap the `Wegovy` suggestion.
5. Tap `Continue`.
6. Leave the default weekly cadence and time as-is.
7. Tap `Continue`.
8. Enter `0.25` as the saved amount.
9. Tap `mg`.
10. Tap `Save protocol`.

Expected:
- You return to Today.
- `Next due` is visible.
- `Wegovy` is visible.
- `Saved amount: 0.25 mg` is visible.

## Pass 2: Mark taken
1. On Today, tap `Mark taken`.
2. In the modal, tap `Save as taken`.
3. Open `Timeline`.

Expected:
- A `Logged Wegovy as taken` item appears.
- A `Created protocol Wegovy` item appears.

## Pass 3: Reschedule
1. Go back to `Today`.
2. Tap `Reschedule`.
3. Choose `Tomorrow`.
4. Tap `Save reschedule`.
5. Open `Timeline`.

Expected:
- A `Rescheduled Wegovy ...` item appears.
- The feed still includes the earlier protocol-created and taken items.

## Pass 4: Skip
1. Go back to `Today`.
2. Tap `Skip`.
3. Tap `Save skip`.
4. Open `Timeline`.

Expected:
- A `Skipped Wegovy` item appears.
- Timeline still shows prior history.

## Pass 5: Cross-screen checks
1. Open `Library`.
2. Confirm `Wegovy` appears in the saved protocol list.
3. Open `Settings`.
4. Confirm privacy controls still render.
5. Tap `Reset onboarding for QA`.

Expected:
- Settings renders without crashing.
- Reset returns to the onboarding splash.

## Fail conditions
- Any action hangs without recovering.
- Today does not refresh after a save.
- Timeline misses a completed/skipped/rescheduled action.
- A history item disappears after a later action.
- A route lands on a blank screen or red screen.

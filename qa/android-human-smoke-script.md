# Android human smoke script

## Setup
1. Start the emulator.
2. From `C:\Users\david\Documents\Playground\atlas`, run `npx expo start --dev-client --clear`.
3. If the app is not installed, run `npx expo run:android`.
4. If Metro does not connect, run `adb reverse tcp:8081 tcp:8081`.

## Clean first-run check
1. Clear app data: `adb shell pm clear com.david.atlas`.
2. Open Atlas.
3. Confirm the splash screen shows `Atlas` and `Continue`.
4. Move through onboarding.
5. Verify privacy settings appear before health app connection.
6. Verify profile screens can be skipped.
7. Complete one path each for `GLP`, `Peptide`, and `Both`.
8. Confirm each path reaches the summary screen.
9. Tap `Let's get started`.
10. Confirm the app lands in `Today`.

## App shell check
1. On `Today`, confirm:
   - welcome header
   - privacy/discreet mode status
   - `No protocols yet`
   - `Create your first protocol`
2. Tap each bottom tab:
   - `Today`
   - `Timeline`
   - `Library`
   - `Insights`
   - `Settings`
3. Confirm each tab uses product copy, not route/debug labels like `today/index`.
4. From `Today`, tap `Create your first protocol` and confirm the placeholder opens.
5. From the protocol placeholder, tap `Back to Library`.

## Settings check
1. Open `Settings`.
2. Confirm `Privacy settings` renders.
3. Toggle each privacy switch once.
4. Confirm `Account mode` status renders.
5. Confirm the export placeholder renders.
6. Tap `Reset onboarding for QA`.
7. Confirm the app returns to the onboarding splash.

## Regression watchlist
- No unmatched route screen.
- No redbox or blank screen.
- No debug warning toast.
- No missing CTA labels.
- No tab labels showing route filenames.

# Atlas iOS Mac QA checklist

Use this after cloning Atlas onto a Mac with Xcode installed.

## Setup
1. Install dependencies:
   - `npm install`
2. Confirm Expo config is readable:
   - `npx expo config --type public`
3. Confirm dependency health:
   - `npx expo-doctor`
4. Generate and run the iOS dev build:
   - `npx expo run:ios`
5. In a second terminal, start Metro for the dev client:
   - `npx expo start --dev-client --clear`

## Core smoke
1. Cold launch the app.
2. Confirm the splash screen renders without a blank or red error screen.
3. Complete onboarding as a guest user.
4. Land in the app shell and verify all tabs:
   - `Today`
   - `Timeline`
   - `Library`
   - `Insights`
   - `Settings`

## Core loop
1. Create a protocol from `Today`.
2. Confirm `Today` shows the next due item.
3. Log a dose as taken.
4. Confirm `Timeline` shows the logged event.
5. Reschedule a dose.
6. Confirm `Timeline` shows the rescheduled event.
7. Skip a dose.
8. Confirm `Timeline` shows the skipped event.

## Privacy and reminders
1. In `Settings`, enable discreet mode.
2. Confirm protocol names are masked in `Today`.
3. Confirm protocol names are masked in `Timeline`.
4. Review reminder preview text for each mode:
   - `Full detail`
   - `Generic reminder`
   - `Silent mode`
5. Schedule a reminder and confirm the app does not error.
6. If a notification is delivered while testing, verify:
   - `Mark taken` works
   - `Skip` works
   - tapping the notification opens the app safely

## Inventory and calculator
1. Create a vial.
2. Link the vial to a protocol.
3. Log a taken dose and confirm remaining quantity decrements.
4. Use a manual correction and confirm the updated quantity persists after relaunch.
5. Use the reconstitution calculator and save a profile.
6. Reload the app and confirm the saved calculator profile still exists.

## Insights and exports
1. Add a weight log.
2. Add a symptom log.
3. Add a custom metric and metric value.
4. Confirm Insights renders trend sections without health integrations enabled.
5. Export CSV.
6. Export JSON.
7. Confirm export does not block app use if sharing is cancelled.

## Auth and sync
1. Open the auth flow from `Settings`.
2. If Supabase env vars are configured, verify:
   - sign up
   - sign in
   - sign out
3. If Supabase env vars are not configured, confirm guest mode remains usable and the app does not crash.
4. Confirm sync status is visible in `Settings` and remains non-blocking.

## Health connection scaffolding
1. Open health connection settings.
2. Toggle a health connection on and off.
3. Confirm failures, if any, do not block the rest of the app.

## Relaunch and persistence
1. Force close the app.
2. Relaunch it.
3. Confirm onboarding completion is preserved.
4. Confirm protocols, logs, reminders, vials, calculator profiles, and insights data are still present.

## Failure criteria
Treat any of these as a stop-ship issue for iOS QA:
- blank launch
- red error screen
- onboarding cannot complete
- protocol save fails
- log actions fail or mutate historical entries incorrectly
- reminder actions crash the app
- discreet mode leaks sensitive labels
- inventory does not persist
- export blocks or crashes the app
- auth blocks guest usage

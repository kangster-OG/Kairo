# Atlas Beta QA Checklist

Use this checklist while testing the TestFlight build. Please write down anything that feels confusing, broken, slow, or surprisingly good. Screenshots and screen recordings are especially helpful.

## Before You Start

- [ ] Install the latest Atlas build from TestFlight.
- [ ] Note your device model and iOS version.
- [ ] Start from a fresh install if possible.
- [ ] If you already tested an older Atlas build, note whether this is an update or a fresh install.

## What To Report

For every issue, please include:

- What you were trying to do.
- What happened.
- What you expected to happen.
- Whether you can reproduce it.
- A screenshot or screen recording if possible.
- Any crash, freeze, blank screen, missing text, clipped text, or weird animation.

## Onboarding QA

### First Launch

- [ ] App launches without crashing.
- [ ] First screen appears quickly and does not show blank/loading content for too long.
- [ ] Text is readable and not cut off.
- [ ] Buttons are easy to find and tap.
- [ ] Layout looks good in both light and dark mode, if you use both.

### Onboarding Flow

- [ ] Each onboarding step explains itself clearly.
- [ ] Continue/next buttons work every time.
- [ ] Back navigation works where available.
- [ ] Progress through the flow feels natural.
- [ ] No screen feels like a dead end.
- [ ] No button, card, or text overlaps another element.
- [ ] Keyboard does not cover important fields or buttons.
- [ ] Form fields accept input correctly.
- [ ] Required fields are obvious.
- [ ] Empty or invalid fields show useful guidance.

### Personalization And Setup

- [ ] Goal or profile questions make sense.
- [ ] Choices are easy to understand.
- [ ] Multiple-choice controls select and deselect correctly.
- [ ] Any sliders, pickers, toggles, or menus behave as expected.
- [ ] Health, calendar, notification, or sign-in prompts appear at the right time.
- [ ] Permission prompts explain why Atlas is asking.
- [ ] Denying a permission does not break onboarding.
- [ ] Granting a permission moves forward correctly.

### Paywall Or Premium Screen

- [ ] Premium screen appears at the expected point in onboarding.
- [ ] Copy is clear and not misleading.
- [ ] Prices, trial language, and restore option are visible if shown.
- [ ] Close, skip, restore, or continue options work as expected.
- [ ] The screen does not trap you unless a purchase is actually required.
- [ ] If you try a purchase flow, Apple/TestFlight sandbox behavior looks normal.
- [ ] Restore purchases does not crash.

### Mascot Selection

- [ ] Mascot selection appears clearly.
- [ ] Both mascot options are visible and tappable.
- [ ] Mascot art loads correctly.
- [ ] Mascot names are visible where expected.
- [ ] Selected mascot state is obvious.
- [ ] Confirming a mascot works.
- [ ] After onboarding, the selected mascot appears in the app.

### Onboarding Completion

- [ ] Finishing onboarding lands you in the main app.
- [ ] The app remembers onboarding completion after force quitting and reopening.
- [ ] Your selected options appear to carry into the app.
- [ ] No setup screen repeats unexpectedly after completion.

## Overall App QA

### Main Navigation

- [ ] All main tabs or sections are reachable.
- [ ] Navigation labels are clear.
- [ ] Back buttons work.
- [ ] Deep screens return to the expected place.
- [ ] Switching sections does not lose entered data unexpectedly.
- [ ] App remains responsive during navigation.

### Today And Daily Use

- [ ] Today/home screen loads without empty or broken content.
- [ ] Primary daily actions are easy to find.
- [ ] Cards, summaries, and recommendations feel understandable.
- [ ] Empty states are helpful.
- [ ] Completed actions update the UI immediately.
- [ ] Data remains after closing and reopening the app.

### Logging And Editing Data

- [ ] Add a new item or log entry.
- [ ] Edit the entry.
- [ ] Delete or archive the entry if available.
- [ ] Confirm the app updates totals, lists, or summaries correctly.
- [ ] Try entering unusual but reasonable values.
- [ ] Try canceling halfway through an entry.
- [ ] Confirm drafts or partial inputs behave as expected.

### Nutrition, Inventory, And Progress

- [ ] Nutrition-related screens load.
- [ ] Inventory or supplement/compound tracking screens load.
- [ ] Adding and viewing items works.
- [ ] Progress charts or summaries display sensible values.
- [ ] Units and labels are clear.
- [ ] Empty states do not look broken.

### Insights And Reviews

- [ ] Insights screens load without crashing.
- [ ] Weekly review or review-mode surfaces are readable.
- [ ] Recommendations feel connected to entered data.
- [ ] Export/share/copy actions work if present.
- [ ] Long text remains readable and scrollable.

### Mascot And Rewards

- [ ] Mascot detail screen opens.
- [ ] Current mascot name is visible.
- [ ] Evolution path shows all form names.
- [ ] Next form and progress are understandable.
- [ ] Rewards points or streak information updates correctly.
- [ ] Mascot art appears in the app and widgets if available.
- [ ] No mascot image appears stretched, blurry, missing, or clipped.

### Widgets

- [ ] Add Atlas widgets from the iOS widget picker.
- [ ] Widget content appears after adding.
- [ ] Widget content matches the app state.
- [ ] Tapping a widget opens the expected app screen.
- [ ] Widget updates after changing relevant app data.
- [ ] Widget does not show placeholder/debug content.

### Notifications, Calendar, Health, And Sign-In

- [ ] Notification permission flow works if prompted.
- [ ] Calendar permission flow works if prompted.
- [ ] Health permission flow works if prompted.
- [ ] Sign in with Apple works if used.
- [ ] Denying optional permissions does not crash the app.
- [ ] Re-enabling permissions later works if available.

### Reliability

- [ ] Force quit and reopen the app.
- [ ] Restart the phone and reopen the app if convenient.
- [ ] Use the app on cellular and Wi-Fi.
- [ ] Try airplane mode or poor network if convenient.
- [ ] App handles slow network states gracefully.
- [ ] No repeated crashes.
- [ ] No obvious battery drain, overheating, or severe lag.

### Visual And Accessibility Checks

- [ ] Test at your normal text size.
- [ ] If possible, test with larger Dynamic Type.
- [ ] Text does not clip or overlap.
- [ ] Buttons remain tappable.
- [ ] Important screens work in dark mode.
- [ ] Colors have enough contrast.
- [ ] Loading states and empty states look intentional.

## Final Tester Notes

Please answer these after testing:

- What was the most confusing part?
- What felt most polished?
- What would stop you from using Atlas again tomorrow?
- Did onboarding make you understand what Atlas is for?
- Did the mascot/rewards system feel useful, fun, distracting, or unclear?
- If you could change one thing before public launch, what would it be?


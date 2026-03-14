# Atlas Daily-Use Loop Android Emulator Checklist

## Setup
- [ ] Start Metro with `npx expo start --dev-client --clear`
- [ ] Ensure `adb reverse tcp:8081 tcp:8081` is active
- [ ] Install/open the Android dev build
- [ ] Clear app data before the pass

## Host verification
- [ ] `npm run typecheck` passes
- [ ] `npm test -- --runInBand` passes
- [ ] `npm run lint` passes except the known generated Expo warning

## Shell and launch
- [ ] App launches without red screen or white screen hang
- [ ] Today tab opens cleanly
- [ ] Bottom tabs render: `Today`, `Timeline`, `Library`, `Insights`, `Settings`

## Today empty state
- [ ] Fresh state shows `No protocols yet`
- [ ] Today shows `Create your first protocol`
- [ ] CTA opens the protocol wizard

## Protocol creation
- [ ] Step 1 renders type + name selection
- [ ] Step 2 renders cadence + timing
- [ ] Step 3 renders saved amount + notes
- [ ] Saving a protocol returns to Today
- [ ] Today now shows `Next due`
- [ ] Saved amount renders with neutral copy

## Quick actions
- [ ] `Mark taken` opens the log modal and saves successfully
- [ ] `Skip` opens the skip modal and saves successfully
- [ ] `Reschedule` opens the reschedule modal and saves successfully
- [ ] Today refreshes after each action without stale cards

## Timeline
- [ ] Timeline shows `Created protocol ...`
- [ ] Timeline shows `Logged ... as taken`
- [ ] Timeline shows `Skipped ...`
- [ ] Timeline shows `Rescheduled ...`
- [ ] Protocol filter narrows results correctly
- [ ] Date filters render and remain tappable

## Cross-screen consistency
- [ ] Today and Timeline stay in sync after each action
- [ ] Library lists the saved protocol
- [ ] Settings still renders privacy/account state
- [ ] Reset onboarding for QA still returns to splash

## Domain safety checks
- [ ] Generated future schedule items remain visible as future state, not history
- [ ] Historical actions appear only through immutable timeline/log events
- [ ] No action silently removes prior history from Timeline

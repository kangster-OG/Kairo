# Atlas device core-loop checklist

Use this on a physical device or Android emulator with a fresh install or cleared app data.

## 1. Onboarding and shell handoff
- App launches without a red screen or blank shell.
- Splash `Continue` moves to intro.
- Intro `Get started` enters onboarding.
- `Continue as guest` works.
- Privacy step appears before the health connection step.
- `Explore first` path can finish without protocol-specific onboarding answers.
- `Let's get started` lands in the tabbed app shell.

## 2. First protocol
- `Today` shows the empty-state CTA to create a protocol.
- The protocol wizard saves a weekly or every-N-days protocol without guidance language.
- Saving returns to `Today`.
- `Today` shows a real `Next due` card after save.
- `Library` lists the saved protocol.

## 3. Daily use loop
- `Mark taken` logs a dose quickly.
- `Skip` creates a skipped event without deleting history.
- `Reschedule` creates a rescheduled event and updates `Next due`.
- `Timeline` reflects `protocol created`, `taken`, `skipped`, and `rescheduled`.
- `Today` and `Timeline` stay in sync after each action.

## 4. Inventory and sites
- A vial can be created and linked to a protocol.
- A taken log decrements remaining quantity when the protocol is linked to the vial.
- Low-stock UI appears when remaining quantity is below the threshold.
- Manual inventory correction updates the vial without corrupting history.
- Site tracking is optional and available during dose logging when enabled.

## 5. Reminders and privacy
- Local reminder settings can be toggled in `Settings`.
- Reminder preview changes between `Full detail`, `Generic reminder`, and `Silent mode`.
- Discreet mode hides sensitive labels in `Today`, `Timeline`, and Settings previews.
- Changing reminder settings does not block the rest of the app.

## 6. Insights and exports
- Weight logging saves and appears in Insights.
- Symptom logging saves and appears in Insights.
- Custom metrics can be created and logged.
- Amount-in-system is clearly labeled as an estimate/model.
- CSV export completes.
- JSON export completes.

## 7. Auth and account status
- Settings shows guest/account status clearly.
- Missing Supabase config does not block app use.
- Sign-in/create-account entry point opens from Settings when config exists.
- Guest data remains visible after restart.

## 8. Restart and resilience
- Killing and relaunching the app preserves onboarding completion.
- Killing and relaunching preserves protocols, logs, inventory, and insights.
- Error states offer a retry path instead of trapping the user.

## Pass criteria
- Every item above passes without a crash, blank screen, or destructive data loss.

# Atlas private-alpha readiness checklist

## Product quality
- Core loop is manually testable on Android dev build.
- Onboarding, Today, Timeline, Library, Insights, and Settings all render production-lean states.
- Copy stays privacy-safe, neutral, and free of dosing recommendations.
- Guest mode remains fully usable.

## Reliability
- Local database migrations run on a clean install.
- AsyncStorage onboarding hydration failure falls back safely.
- Notification bootstrap failures do not crash app launch.
- Query failures in Today, Timeline, Library, Insights, and Settings show retryable fallback UI.
- Export sharing failure does not lose the generated file.

## Privacy and security
- Discreet mode hides sensitive labels in primary user-facing surfaces.
- Reminder previews respect privacy mode and discreet mode.
- Health connections remain optional and non-blocking.
- No backend dependency is required for daily use.

## Analytics scaffolding
- `protocol_created` emits on protocol creation.
- `dose_logged` emits on taken dose logging.
- `reminder_scheduled` emits when future reminders are generated.
- `low_stock_seen` emits once per vial per session.
- `export_requested` emits on export generation.

## Accessibility
- Primary CTAs expose button semantics.
- Important switches and action pills have readable labels.
- Today logging modal can be dismissed without trapping focus.
- Core onboarding actions remain reachable with screen-reader semantics.

## Performance
- Timeline filter changes remain responsive.
- Today and Timeline do not block the UI with avoidable loading churn.
- Local-first queries do not refetch aggressively during simple navigation.

## Release packaging
- Android dev build launches on emulator/device.
- EAS/release config remains a follow-up item if not already finalized.
- Private-alpha blockers are reviewed before distribution.

## Release decision
- Ship only when all blocker items in `docs/private-alpha-blockers.md` are resolved or explicitly waived.

# Atlas Supabase sync access plan

## Principles
- Local SQLite remains the working source of truth on device.
- Supabase sync is additive and optional.
- Guest mode has no cloud dependency.
- Historical `log_events` remain append-only.
- Generated future schedule occurrences are never treated as cloud source of truth.

## Ownership model
- Every cloud row is owned by one `auth.users.id`.
- Guest users do not write cloud rows.
- Upgrade from guest to account maps local records into cloud rows using:
  - `owner_id`
  - `local_id`
  - `updated_at`

## RLS shape
- `profiles` is keyed directly by `auth.users.id`.
- All domain tables use:
  - `owner_id = auth.uid()` for select, insert, update, and delete
- There is no cross-user sharing in v1.

## Data flow
1. Atlas works locally as a guest.
2. User signs up or signs in.
3. Atlas prepares a guest upgrade plan from local records.
4. Future sync uploads local rows by `local_id`.
5. Future sync downloads account rows and merges them back into SQLite.

## Conflict strategy
- Mutable rows (`protocols`, `vials`, `sites`, `custom_metrics`) use last-write-wins for v1 based on `updated_at`.
- Immutable rows (`log_events`) merge by append-only `local_id`.
- Reminders are regenerated locally from synced protocol state; notification delivery rows are not authoritative.

## Failure handling
- Sync failure never blocks Today, logging, inventory, reminders, calculator, or timeline use.
- Sync errors surface as status UI only.
- Local data is preserved even if account bootstrap or sync is unavailable.

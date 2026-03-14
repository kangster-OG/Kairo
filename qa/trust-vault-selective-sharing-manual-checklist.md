# Trust Vault + Selective Sharing V1 manual checklist

## Alias mode
- Enable alias mode for one protocol.
- Confirm Today shows codename instead of canonical protocol name.
- Confirm Timeline uses alias-safe summaries.
- Confirm Library uses the codename as the primary label.
- Confirm Insights does not leak the canonical label.
- Turn alias mode off.
- Confirm canonical labels return without data loss.

## Discreet mode
- Turn on discreet mode while alias mode is off.
- Confirm Today uses generic safe labels.
- Confirm Timeline uses generic private summaries.
- Confirm Settings previews stay privacy-safe.
- Confirm reminder preview stays generic or silent-oriented.

## Trust Vault gating
- Enable biometric gate where available.
- Open Trust Vault and confirm gate appears.
- Fail once intentionally and confirm the rest of the app still works.
- Retry and unlock successfully.
- Disable biometric gate and confirm an audit entry is created.

## Selective sharing scopes
- Create a share for:
  - current protocol only
  - last 30 days logs
  - symptoms only
  - inventory only
  - summary only
  - custom date range
- Confirm preview shows only the requested data slice.
- Confirm preview clearly says it is a static snapshot, not live data.

## Alias-safe sharing
- Create a share with alias mode on.
- Confirm preview contains alias-safe labels only.
- Generate the bundle.
- Confirm exported bundle metadata matches the preview counts and scope.
- Confirm canonical labels are not present in the bundle output.

## Guest mode
- Repeat one selective share flow while signed out / guest-only.
- Confirm no account wall appears.
- Confirm bundle generation still works.

## Audit visibility
- Trigger:
  - alias changed
  - privacy mode changed
  - biometric lock changed
  - export created
  - selective share created
- Confirm each event appears in the Trust Vault audit viewer.
- Confirm summaries are privacy-safe.

## Failure handling
- Attempt a protected action on a device without biometric support or with biometrics unavailable.
- Confirm Atlas degrades gracefully and does not block Today/logging.
- Cancel out of a selective share flow.
- Confirm no bundle is created and no extra data is exported.

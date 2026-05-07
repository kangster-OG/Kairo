# App Store Resubmission Evidence - 2026-05-07

## Stop Gate

- App Store Connect is stopped on iOS version `1.0` before final submission.
- `Update Review` is visible and enabled.
- `Update Review` has not been clicked.

## Rejection Being Addressed

- Latest rejected build: `1.0 (2026050401)`.
- Apple guideline: `2.3.0 Performance: Accurate Metadata`.
- Apple issue: `UIRequiredDeviceCapabilities` prevented install on the review devices.

## Uploaded Binary

- Accepted archive: `output/app-store-builds/Kairo-1.0-2026050701-arm64.xcarchive`.
- Accepted IPA: `output/app-store-builds/export-arm64/Atlas.ipa`.
- Delivery UUID: `c54f062d-f0b5-4263-bb25-5d6bc625a52a`.
- Upload completed on 2026-05-07 at 1:26 PM local time.

## App Store Connect Build Metadata

Verified from the live App Store Connect build metadata page for `1.0 (2026050701)`:

- Binary State: `Validated`.
- Bundle Version String: `2026050701`.
- Bundle ID: `com.dkang2000.Atlas`.
- Minimum iOS Version: `17.0`.
- Supported Architectures: `arm64`.
- Device Family: `iPhone`.
- Required Capabilities: `arm64`.
- Uploaded entitlements show `get-task-allow: false` for the app and embedded extensions.

## Version Page State

Verified from the live App Store Connect iOS version page:

- iOS version `1.0` status: `Prepare for Submission`.
- Selected build: `2026050701`.
- Rejected build `2026050401` is no longer selected in the build slot.
- `Save` is disabled after saving the build and review-note changes.
- `Update Review` is enabled and waiting for explicit user approval.
- Release mode remains `Automatically release this version`.

## Review Notes

The App Review notes now state that:

- Build `2026050701` replaces rejected build `2026050401`.
- The resubmission addresses the May 7, 2026 `2.3.0` device-capability rejection.
- The app and both embedded extensions were re-archived with `UIRequiredDeviceCapabilities = arm64`.
- The upload was accepted by App Store Connect validation.
- Local install and launch were verified on iPhone 17 Pro Max and iPad Air 11-inch simulator coverage.
- Restore Purchases and legal links are available in the paywall/settings surfaces.

## Subscriptions

Verified from live App Store Connect subscription pages:

- Subscription group: `Kairo Pro`.
- Monthly: `com.dkang2000.Atlas.kairo.pro.monthly`, status `Waiting for Review`, duration `1 month`.
- Annual: `com.dkang2000.Atlas.kairo.pro.annual`, status `Waiting for Review`, duration `1 year`.
- Last-chance annual: `com.dkang2000.Atlas.kairo.pro.annual.lastchance`, status `Waiting for Review`, duration `1 year`.
- Monthly introductory offer: `Free for the first week`, 175 countries or regions, no end date.
- Annual introductory offer: `Free for the first week`, 175 countries or regions, no end date.
- Last-chance annual has no introductory offer, matching the immediate-charge offer text.

## Privacy And Legal

Verified from live App Store Connect privacy metadata:

- Privacy Policy URL: `https://chloeverse.io/kairo/privacy`.
- App Privacy data categories shown: Health & Fitness, Contact Info, Purchases, Identifiers, User Content, Usage Data.

Local link checks:

- `https://chloeverse.io/kairo/privacy` returned HTTP `200`.
- `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` returned HTTP `200`.

## Local Build Evidence

- `plutil -lint` passed for:
  - `atlas-ios/Atlas/Info.plist`
  - `atlas-ios/AtlasWidgetsExtension/Info.plist`
  - `atlas-ios/AtlasIntentsExtension/Info.plist`
- Release build passed for iOS 26.4 simulator target `iPhone 17 Pro Max`.
- Local smoke launch passed on iPhone 17 Pro Max and iPad Air 11-inch simulator coverage.
- Smoke screenshots:
  - `output/app-store-builds/iphone-17-pro-max-2026050701-after-get-started.png`
  - `output/app-store-builds/ipad-air-11-m4-2026050701-after-get-started.png`

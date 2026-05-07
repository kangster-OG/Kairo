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

- Accepted archive: `output/app-store-builds/Kairo-1.0-2026050705-arm64.xcarchive`.
- Accepted IPA: `output/app-store-builds/export-2026050705-arm64/Atlas.ipa`.
- App Store Connect build ID / delivery UUID: `5215f5a6-fbc6-4e02-885c-5ba6830b394e`.
- Upload completed on 2026-05-07 at 5:26 PM local time; App Store Connect metadata shows upload date May 7, 2026 at 5:27 PM.

## App Store Connect Build Metadata

Verified from the live App Store Connect build metadata page for `1.0 (2026050705)`:

- Binary State: `Validated`.
- Bundle Version String: `2026050705`.
- Bundle ID: `com.dkang2000.Atlas`.
- Minimum iOS Version: `17.0`.
- Supported Architectures: `arm64`.
- Device Family: `iPhone`.
- Required Capabilities: `arm64`.
- Uploaded entitlements show `get-task-allow: false` for the app and embedded extensions.

## Version Page State

Verified from the live App Store Connect iOS version page:

- iOS version `1.0` status: `Prepare for Submission`.
- Selected build: `2026050705`.
- Previously selected build `2026050704` and rejected build `2026050401` are no longer selected in the build slot.
- `Save` is disabled after saving the build and review-note changes.
- `Update Review` is enabled and waiting for explicit user approval.
- Release mode remains `Automatically release this version`.

## Review Notes

The App Review notes now state that:

- Build `2026050705` replaces previously selected build `2026050704` and rejected build `2026050401`.
- The resubmission addresses the May 7, 2026 `2.3.0` device-capability rejection.
- The app and both embedded extensions were re-archived with `UIRequiredDeviceCapabilities = arm64`.
- App Store Connect build metadata shows `Binary State = Validated`, `Supported Architectures = arm64`, `Device Family = iPhone`, `Required Capabilities = arm64`, and `get-task-allow = false`.
- Local full simulator tests, Release iPhoneOS archive/export, exported IPA plist/entitlement inspection, compiled binary scanning, and clean-install smoke testing were completed before stopping.
- The first-run rating primer uses Apple's native StoreKit review prompt on the rating step.
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
- Full simulator tests passed for build `2026050705`.
- Release build passed for iOS 26.4 simulator target `iPhone 17 Pro Max`.
- Release iPhoneOS archive passed for `output/app-store-builds/Kairo-1.0-2026050705-arm64.xcarchive`.
- Exported IPA inspection confirmed the app and both extensions preserve `CFBundleVersion = 2026050705`, `UIRequiredDeviceCapabilities = arm64`, and `get-task-allow = false`.
- Compiled binary scan found no `localhost`, `127.0.0.1`, old staging copy, or the removed onboarding safety copy.
- Local clean-install onboarding smoke passed on iPhone 17 Pro Max simulator after the final `2026050705` build bump; the rating step no longer shows the explanatory line below the stars and the native StoreKit review sheet appears on that screen.
- Smoke screenshots:
  - `output/app-store-builds/iphone-17-pro-max-2026050702-clean-launch.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-track-disclaimer.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-rating-primer-no-system-prompt.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-plan-ready-copy.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-trial-reminder.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-paywall.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-limited-preview-home.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-limited-upgrade-prompt.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050702-limited-log-tab.jpg`
  - `output/app-store-builds/iphone-17-pro-max-2026050705-rating-primer-review-prompt.jpg`

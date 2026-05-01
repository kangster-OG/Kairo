# Current Thread Handoff - 2026-05-01 - App Store Review Resubmission

This handoff captures Kairo's App Store submission state after the final approved screenshots, ASO metadata pass, first App Review rejection, and metadata-only resubmission.

## Product / Naming Baseline

- User-facing app name: **Kairo: Peptide/GLP tracker**.
- Atlas remains the repo/project/internal name in many code paths, bundle IDs, and older docs.
- Native iOS under `atlas-ios/` remains the primary product path.
- Kairo is a premium iPhone peptide/GLP protocol tracker. It is not a marketplace, sourcing app, medical advice app, AI chatbot, social app, calorie tracker, or generic wellness app.
- Do not use the user's regular Chrome for App Store Connect work. Use the automated Playwright browser only.

## App Store Connect URLs / IDs

- App Store Connect app ID: `6760720926`
- Current version page:
  `https://appstoreconnect.apple.com/apps/6760720926/distribution/ios/version/inflight`
- App Review / submissions page:
  `https://appstoreconnect.apple.com/apps/6760720926/distribution/reviewsubmissions`
- First rejected/resubmitted submission ID:
  `22dcc5d8-ed63-4dc1-9397-448d269ca247`
- Build submitted:
  `1.0 (2026043001)`
- Review device from first rejection:
  `iPad Air 11-inch (M3)`
- Review date from first rejection:
  `April 30, 2026`

## Current App Store Review State

Kairo was first rejected for a metadata-only subscription issue:

- Guideline: `3.1.2(c) - Business - Payments - Subscriptions`
- Apple's issue: App Store metadata for auto-renewable subscriptions did not include a functional Terms of Use / EULA link.
- This was not a binary rejection.

Fix applied in App Store Connect:

- Added both legal links to the bottom of the App Description:
  - `Privacy Policy: https://chloeverse.io/kairo/privacy`
  - `Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Updated App Review Notes to explicitly tell Apple that:
  - the Privacy Policy is provided in the App Privacy metadata field at `https://chloeverse.io/kairo/privacy`
  - the standard Apple Terms of Use (EULA) link is now included in the App Description
- Saved metadata.
- Clicked `Update Review`.
- Clicked `Resubmit to App Review`.

Known state immediately after resubmission:

- Submission status: **Waiting for Review**
- Last updated by: Dongho Kang
- Resubmitted time shown in App Store Connect: April 30, 2026 at 6:15 PM local time

## Current App Store Metadata

Name is locked and should not be changed unless the user explicitly says so:

- Name: `Kairo: Peptide/GLP tracker`

Subtitle:

- `Shot, dose & vial log`

Promotional text:

```text
Track GLP-1 and peptide shots, dose history, vial runway, injection sites, progress evidence, and weekly protocol reviews in one private iPhone workspace.
```

Keywords:

```text
semaglutide,tirzepatide,injection,reminder,site,weight,side,effects,inventory,schedule,glp1,progress
```

Support URL:

```text
https://chloeverse.io/kairo/
```

Marketing URL:

```text
https://chloeverse.io/kairo/
```

Privacy Policy field:

```text
https://chloeverse.io/kairo/privacy
```

Current App Description includes the ASO copy plus legal links at the bottom. Preserve the legal links while editing future App Store copy unless App Store Connect uses a custom EULA field instead.

## Subscription / StoreKit State

Attached to the submitted version:

- `Kairo Pro Monthly`
  - Product ID: `com.dkang2000.Atlas.kairo.pro.monthly`
  - Duration: 1 month
  - US price: `$9.99`
  - Intro offer: `Free for the first week`
  - Status observed: `Ready to Submit`
- `Kairo Pro Annual`
  - Product ID: `com.dkang2000.Atlas.kairo.pro.annual`
  - Duration: 1 year
  - US price: `$59.99`
  - Intro offer: `Free for the first week`
  - Status observed: `Ready to Submit`
- `Kairo Pro Annual Last Chance`
  - Product ID: `com.dkang2000.Atlas.kairo.pro.annual.lastchance`
  - Duration: 1 year
  - US price: `$39.99`
  - Intro offer: none
  - Status observed: `Ready to Submit`

Important:

- The last-chance annual discount is a separate product and must not secretly purchase the normal annual product.
- Do not remove the last-chance product from the submitted version while the binary can surface and purchase it.
- Monthly and normal annual must keep 7-day intro trials.

## Screenshots

The user approved the final local screenshot previews and authorized upload.

Approved local directory:

```text
/Users/donghokang/Developer/Atlas/output/app-store-screenshots/iphone-6-5-real-device-frame-v2-20260430
```

Approved final order uploaded to App Store Connect:

1. `01-today-light.png` - `Never Miss What’s Due`
2. `02-log-dark.png` - `Shot Logging, Zero Friction`
3. `03-protocols-light.png` - `Ditch the Spreadsheet`
4. `04-progress-dark.png` - `See What’s Actually Changing`
5. `05-companion-light.png` - `Meet your companion`
6. `06-inventory-dark.png` - `Never Guess What’s Left`
7. `07-evidence-light.png` - `Proof Beyond the Scale`
8. `08-privacy-dark.png` - `Private. Locked. Yours.`
9. `09-widgets-light.png` - `Stay On Track Anywhere`
10. `10-weekly-review-dark.png` - `Turn Weeks Into Wins`

Validated in App Store Connect before submission:

- iPhone 6.5-inch rail showed `10 of 10 Screenshots`.
- Upload order was verified after a one-by-one reupload.
- Screenshot dimensions were verified locally as `1284x2778` RGB PNG.
- Contact sheet:
  `/Users/donghokang/Developer/Atlas/output/app-store-screenshots/iphone-6-5-real-device-frame-v2-20260430/contact-sheet.jpg`
- Generator script:
  `/Users/donghokang/Developer/Atlas/scripts/build_kairo_app_store_screenshots_real_device_frame.py`

Do not replace screenshots unless the user explicitly asks. If replacing screenshots, show local previews first and upload one at a time to avoid App Store Connect scrambling the order.

## App Info / Compliance State Observed Before Submission

- Primary category: `Health & Fitness`
- Secondary category: none
- Content rights: no third-party content
- License agreement: Apple standard license
- Regulated medical device: declared not a regulated medical device
- Age rating: high/conservative, appropriate for sensitive health/protocol tracking
- Sign-in required: unchecked
- Release setting observed before rejection: `Automatically release this version`

If the user wants manual control over launch timing, switch release to `Manually release this version` before the next final approval/release decision. Do not change this without explicit user direction.

## Native App Legal-Link Follow-Up

Apple's rejection text also reminded that apps offering auto-renewable subscriptions must include in the app itself:

- subscription title
- subscription length
- subscription price
- functional Privacy Policy link
- functional Terms of Use / EULA link

The immediate rejection was fixed through App Store metadata, but future threads should audit the native paywall/onboarding/settings surfaces before the next binary submission. A quick repo search during the emergency thread did not find obvious active `Terms`, `EULA`, or `Privacy Policy` strings in the main Kairo SwiftUI code. The app may still need an in-app legal-link polish pass for subscription review resilience.

Likely relevant files:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/KairoPremiumStore.swift`

Do not add fake web views. Prefer simple, functional links through `Link` / `openURL` to:

- `https://chloeverse.io/kairo/privacy`
- `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

## Fresh Thread Guidance

- Start from this document for any App Store Connect or App Review follow-up after May 1, 2026.
- The rejection was solved by adding legal links to metadata and resubmitting. Do not re-diagnose it as screenshots, app name, ASO, binary signing, or payment product setup unless App Store Connect shows a new issue.
- Use automated Playwright browser for App Store Connect. Do not touch the user's regular Chrome.
- If App Review rejects again, read the exact guideline/message before changing metadata or code.
- If the app is approved, check whether release is automatic or manual before assuming it is public.

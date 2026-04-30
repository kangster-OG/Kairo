# Current Thread Handoff - 2026-04-30 - App Store Release and Screenshot Recovery

This handoff exists so a fresh Codex thread can continue Kairo's App Store release work without inheriting the bad screenshot-design assumptions from the previous thread.

## Product / Naming Baseline

- The user-facing app name is **Kairo: Peptide/GLP tracker**.
- Atlas remains the repo/project/internal name in many code paths and bundle identifiers.
- Kairo is a premium iPhone peptide/GLP protocol tracker. It is not a marketplace, sourcing app, medical advice app, social app, AI chatbot, calorie tracker, or generic wellness app.
- Native iOS under `atlas-ios/` remains the primary product path.
- Do not submit the app for App Review unless the user explicitly says to submit.

## App Store Connect State

As of this handoff, App Store Connect work had progressed substantially:

- App Store Connect app ID: `6760720926`
- Version page used: `https://appstoreconnect.apple.com/apps/6760720926/distribution/ios/version/inflight`
- App name saved: `Kairo: Peptide/GLP tracker`
- Build selected: `2026043001`
- Support URL: `https://chloeverse.io/kairo/`
- Privacy URL: `https://chloeverse.io/kairo/privacy`
- Draft submission exists.
- iOS 1.0 was ready for review before screenshot replacement work, but should not be submitted until screenshots and metadata are explicitly approved.

StoreKit / App Store Connect products expected:

- `com.dkang2000.Atlas.kairo.pro.annual`
- `com.dkang2000.Atlas.kairo.pro.monthly`
- `com.dkang2000.Atlas.kairo.pro.annual.lastchance`

Important subscription behavior:

- Monthly and normal annual products need 7-day introductory free trials.
- The last-chance annual product is the `$39.99/year` discount path and must be a separate product. Do not show `$39.99/year` while secretly purchasing the normal `$59.99/year` annual product.

## Privacy / Tracking Context

- Kairo does not use cross-app tracking or ad attribution.
- App Tracking Transparency was removed from the app code path in the prior release work.
- The app should not claim to track users across third-party apps or websites.
- Privacy policy URL used for App Store metadata: `https://chloeverse.io/kairo/privacy`
- Support URL used for App Store metadata: `https://chloeverse.io/kairo/`

## Screenshot Work: What Went Wrong

The previous screenshot design attempts were rejected by the user. Future threads should not treat those composites as approved or near-approved.

Rejected issues included:

- too much copy
- visible `1/10`, `2/10`, and small gray explanatory copy
- header text too high
- phone mockups too squished
- phone/device frame not matching the iPhone-style frame in the user's reference
- visual components too sharp
- repeated failure to match the reference proportions

The user gave a non-negotiable reference: clean App Store screenshots similar to the Cal AI examples, with a large realistic iPhone mockup, rounded device corners, correct Dynamic Island silhouette, generous white/dark background, header copy placed lower in the top band, and phone proportions/spacing matching the reference.

## Screenshot Copy / Order To Preserve

Preserve this exact header copy and screenshot order unless the user changes it:

1. `Never Miss What’s Due`
2. `Shot Logging, Zero Friction`
3. `Protocols Without the Spreadsheet`
4. `See What’s Actually Changing`
5. `Meet your companion`
6. `Never Guess What’s Left`
7. `Progress You Can See`
8. `Your Data Stays Yours`
9. `Your Journey, Always Visible`
10. `Turn Weeks Into Wins`

The user requested alternating light and dark mode App Store screenshots. Use:

1. light
2. dark
3. light
4. dark
5. light
6. dark
7. light
8. dark
9. light
10. dark

## Screenshot Assets / Current Local State

Fresh raw simulator captures exist and are better starting material than the rejected composites:

`/Users/donghokang/Developer/Atlas/output/app-store-screenshots/iphone-6-5-raw-alternating-20260430`

Files:

- `01-today-light.png`
- `02-log-dark.png`
- `03-protocols-light.png`
- `04-progress-dark.png`
- `05-companion-light.png`
- `06-inventory-dark.png`
- `07-evidence-light.png`
- `08-privacy-dark.png`
- `09-widgets-light.png`
- `10-weekly-review-dark.png`
- `raw-contact.jpg`

Rejected/latest composite attempt:

`/Users/donghokang/Developer/Atlas/output/app-store-screenshots/iphone-6-5-reference-locked-v10-20260430`

Do not upload this set as-is. It used fresh raw captures and correct alternating mode/order, but the device frame was still not acceptable. The next screenshot thread should rebuild the presentation using a realistic iPhone 15/16-style frame or retake/generate screenshots in a workflow that directly matches the user's reference.

## App Store Screenshot Upload State

The App Store Connect 6.5-inch iPhone screenshot rail was partially replaced during the rejected attempt.

Known state after the interruption:

- 6.5-inch iPhone screenshot rail had `2 of 10 Screenshots` uploaded from the rejected v10 attempt.
- Those two should be deleted before uploading a corrected final set.
- Upload screenshots one at a time to avoid App Store Connect scrambling the order.
- After upload, verify `10 of 10 Screenshots`.
- Save the App Store Connect page.
- Do not submit for review unless explicitly instructed.

If using Playwright file upload, the prior staging folder was:

`/Users/donghokang/Desktop/camera copilot/part 2/predick_market/ATLAS?/.playwright-mcp/kairo-v10-upload`

Do not assume that staging folder contains approved assets; it contains the rejected v10 files unless replaced.

## Recommended Next Screenshot Workflow

1. Start from the raw alternating simulator captures above, or retake fresh simulator screenshots if needed.
2. Build a new App Store screenshot composition that matches the user's provided reference before touching App Store Connect again.
3. Use a realistic iPhone frame:
   - modern iPhone proportions
   - Dynamic Island
   - thin black bezel
   - rounded screen and device corners
   - no generic drawn slab frame
4. Match the reference's spatial rhythm:
   - header copy lower in the top band
   - phone begins well below the title
   - phone is large but not cropped or squished
   - bottom gap between phone and canvas edge resembles the reference
   - no small gray helper copy, counters, or extra captions
5. Show the user a contact sheet and at least one full-size sample for approval before uploading.
6. Only after explicit approval, clear the partial App Store Connect rail and upload the final set.

## Fresh Thread Warning

The user is understandably frustrated with the screenshot work. Be direct, do not over-explain, and do not upload anything until the visual result is approved.

Do not claim the screenshots are good unless they actually match the reference. The safest first deliverable is a local contact sheet for approval, not App Store Connect changes.

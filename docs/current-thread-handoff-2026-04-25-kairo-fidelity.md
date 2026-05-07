# Current Thread Handoff - 2026-04-25 Kairo Fidelity

## Product Identity

The app name is now **Kairo**. Older docs and bundle identifiers still use Atlas in places, but fresh threads should understand that the user-facing product name in the current iOS app is Kairo.

Kairo is a premium iPhone peptide protocol system. It should help a user manage protocol context, shot logging, site rotation, vial runway, side effects, lightweight check-ins, protein, hydration, workouts, progress evidence, weekly review, companion progress, rewards, widgets, and share/export review.

It must not become:

- a marketplace, sourcing app, vendor comparison app, or price-comparison app
- a medical advice, dosing advice, diagnostic, treatment, or bloodwork-as-headline app
- an AI chatbot product
- a calorie scanner or broad meal/calorie tracker
- a social app, shop loop, seasonal economy, or noisy game economy

Privacy and trust remain important, but the product headline is now the operational protocol-system promise, not privacy as the front-stage identity.

## Current Locked Visual Direction

The locked visual source of truth remains the 12-screen mockup board:

- `/Users/donghokang/Library/Messages/Attachments/ee/14/C707BC55-1249-4A7A-8658-AAF0F043CAA4/IMG_5314.png`

The board-facing app should match that mockup as closely as SwiftUI/live app constraints allow. "Inspired by" is not acceptable. Future visual work should treat the board as a pixel-level reference for:

- mascot size, crop, lighting, and background wash
- typography size, weight, line height, and spacing
- card dimensions, radii, borders, shadows, and padding
- chart geometry and label positions
- protein/hydration/workout ring geometry and label placement
- vial art, body-map art, badge/collectible art, crystal art
- bottom tab shelf proportions
- empty-space density and first-viewport composition

The approved board screens are:

1. Today
2. Log Shot
3. Companion
4. Protocols
5. Protocol Detail
6. Edit Protocol
7. Progress
8. Progress Evidence
9. Inventory / Supplies
10. Calculator
11. Weekly Review
12. Settings / Integrations

## Current Implementation State

The board-facing SwiftUI implementation lives primarily in:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/KairoMockupProtocolScreens.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`

Important current assets include:

- `atlas-ios/Atlas/Assets.xcassets/KairoBoardTodayMascotPanel.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoBoardBodyMap.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoBoardVialIcon.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoBoardWeeklyCrystal.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage1Mockup.imageset/`
- corresponding widget-extension copies under `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/`

The current board-facing app is not a fake shell. The user specifically wants the mockup UI language while preserving real app functionality. Root tabs and deep flows should stay backed by real model actions, persistence, routing, capture sheets, editors, rewards, inventory, progress evidence, Health/settings routes, and export/share flows.

Do not remove working functionality while chasing fidelity. If visual changes risk clipping a primary CTA or breaking a flow, fix the regression immediately.

## Latest Fidelity Work Completed In This Thread

This thread continued the exact visual fidelity pass after the April 24 Kairo rebuild.

Key fixes completed:

- Today:
  - retuned hero mascot panel scale/crop/background wash
  - restored board-like first viewport rhythm
  - tuned Next Shot, medication chart, support rings, and inventory runway density
- Log Shot:
  - enlarged and then corrected reward strip/body-map/site controls while keeping the Mark as Taken CTA visible
  - confirmed the primary CTA is no longer clipped by the bottom tab shelf
  - preserved real site selection, pain, side effects, notes, vial runway, Mark as Taken, reward trigger, and return-to-Today behavior
- Companion:
  - tuned level ring, next-form preview width, quest row behavior, badges/collectibles, and Weekly Protocol Mastery proportions
  - preserved individual badge/collectible detail taps and broader rewards navigation
- Protocols:
  - corrected visible Schedule Summary card height, not just outer layout spacing
  - preserved card routing and Add Protocol behavior
- Progress:
  - increased lower-card and support-ring viewport fill
  - preserved Progress Photos, Health Integrations, and Workout interactions
- Inventory:
  - added board-style runway gap before the Supplies footer on the All filter
  - preserved All / Peptides / Supplies filtering and add/edit vial/supply behavior

The latest screenshot verification artifact from this thread:

- `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/six-cta-safe-final-check-20260425-132155/six-contact.png`

Paired board-vs-app comparisons for that pass are in the same directory:

- `today-paired-reference.png`
- `log-paired-reference.png`
- `companion-paired-reference.png`
- `protocols-paired-reference.png`
- `progress-paired-reference.png`
- `inventory-paired-reference.png`

Latest full test result from this thread:

- `atlas-ios/.derived-data-kairo-mockup-protocol-system/Logs/Test/Test-Atlas-2026.04.25_13-23-37--0400.xcresult`
- `xcrun xcresulttool get test-results summary ...` reported `207` passed tests, `0` failures, `0` skipped.

Latest simulator used heavily:

- iPhone 16e simulator: `9EDCEC16-48C4-4640-B318-CA98ABE59559`
- Bundle id remains `com.dkang2000.Atlas`

## Visual Fidelity Cautions For Fresh Threads

The user is asking for exact board fidelity, not approximate inspiration. Be careful with language: do not claim perfection unless screenshots support it. The better working loop is:

1. Read the board/reference docs.
2. Run `git status --short`.
3. Inspect the specific screen/component.
4. Make tightly scoped SwiftUI/asset changes.
5. Build.
6. Install on the simulator.
7. Capture the affected screen plus normalized board-vs-app comparisons.
8. Fix concrete mismatches or regressions.
9. Run tests when the pass is significant.

Important lesson from this thread:

- Visual scale pushes can easily clip Log Shot's `Mark as Taken` CTA under the tab shelf. Always inspect raw screenshots, not only contact sheets.
- The six-screen contact sheet can hide raw-scale problems. Use individual raw captures and paired board-vs-app images for exact work.
- A visible first-viewport match matters at thumbnail scale before detail tweaking.
- The board’s art source and the app’s current generated assets are close but not necessarily truly identical. Do not pretend they are exact if the screenshot shows differences.

## Current Recommended Next Work

If the user continues visual fidelity work, continue from the latest screenshot directory above and tune only concrete mismatches.

Likely next candidates:

- Today hero still differs from the original board because the production mascot/panel asset is not literally the same raster crop as the board. Tune cautiously without making the mascot too tiny or ear-cropped.
- Progress still has subtle distribution differences compared with the board; improve by tuning card content and chart/ring geometry, not by adding blank spacer-only fixes.
- Companion Weekly Mastery and collection icons are close but may need art/spacing refinement.
- Log Shot should be guarded carefully: keep the primary CTA visible above the bottom tab shelf at all times.

If the user asks to test, relaunch the installed simulator app rather than rebuilding unless code changed:

```sh
SIM='9EDCEC16-48C4-4640-B318-CA98ABE59559'
BUNDLE='com.dkang2000.Atlas'
xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl launch --terminate-running-process "$SIM" "$BUNDLE"
```

## Fresh Thread Startup Summary

Fresh threads should start by understanding:

- Kairo is the current user-facing app name.
- Native iOS under `atlas-ios/` is the primary product path.
- The current priority is preserving a fully working peptide protocol system while tightening visual fidelity against the locked mockup board.
- Do not rebuild from scratch unless explicitly asked.
- Do not strip functionality to get a static mockup.
- Do not add out-of-scope product categories.
- Onboarding is separate unless the user explicitly asks for onboarding work.
- When touching UI, use the Build iOS Apps SwiftUI/debugging skills and simulator screenshot QA.

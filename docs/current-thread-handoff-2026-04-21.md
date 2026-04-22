# Atlas Current Thread Handoff - 2026-04-21

Use this as the short context bridge for fresh Codex threads after the major April 2026 Atlas onboarding and app UX push.

## What Atlas Is Building

Atlas is a private, local-first iPhone protocol command center for injectables, reminders, logs, inventory, calculators, injection sites, Trust Vault controls, bounded sharing, review outputs, and deterministic pattern insights.

Atlas is not medical advice, dosing advice, diagnostics, sourcing, a marketplace, or a social app. The native iOS app under `atlas-ios/` is the primary product path.

The product direction is calm, premium, tactile, trust-heavy, proof-led, and utility-first. Atlas should feel like a serious private protocol system with emotional warmth around the edges, not a generic health tracker or mascot-first toy.

## Recent Major Work

This thread shipped a large product and onboarding update to TestFlight.

Most recent uploaded build:

- Atlas 1.0 (`2026042103`)
- Uploaded to App Store Connect/TestFlight on 2026-04-21
- Upload result: `Upload succeeded. Uploaded Atlas. EXPORT SUCCEEDED.`
- Build `2026042103` included the final onboarding copy pass to reduce AI-ish, strategy-doc wording.

If uploading another build, bump all three native iOS `Info.plist` build numbers before archiving:

- `atlas-ios/Atlas/Info.plist`
- `atlas-ios/AtlasWidgetsExtension/Info.plist`
- `atlas-ios/AtlasIntentsExtension/Info.plist`

## DREAM Onboarding Direction

The onboarding is intentionally long. Do not shorten it by default.

Current implemented target:

- 180 user-facing states
- 12 chapters
- Data-driven SwiftUI flow in `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasDreamOnboardingFlow.swift`
- `AtlasOnboardingFlowScreen` routes into `AtlasDreamOnboardingFlowScreen`
- The native test target guards the 180-state inventory and chapter order in `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

Mental model:

1. Show the product fantasy first.
2. Establish local-first, medical-safety, privacy, and trust boundaries.
3. Ask one clear question at a time.
4. Let every answer visibly shape the draft Atlas is building.
5. Generate the readiness map, Day 1 plan, Trust Vault defaults, and first-week preview.
6. Only then hatch or awaken the companion.
7. Land in Today with real Day 1 actions, not an empty home screen.

The user rejected changing the avatar design. Keep the existing companions. The hatching, egg, capsule, signal core, sealed orb, or awakening moment is a presentation layer around the existing companion design.

Companion personalization can include name, signal color, role/tone, and presence level. Keep it bounded, optional, and subordinate to Atlas' serious utility.

## Onboarding Copy Rules

The current copy pass intentionally removed strategy-doc and AI-ish phrasing. Preserve that direction.

Avoid:

- user-facing phrases like "operating system fantasy", "privacy posture", "generated artifact", or "surface" as a noun
- explaining the same concept twice
- generic AI wellness language
- fake helper narration
- shame, diagnosis, fear pressure, or moralizing copy

Prefer:

- short concrete sentences
- one idea per screen
- direct questions
- plain labels like "Atlas overview", "Protocol setup", "Goals", "Friction", and "Product tour"
- visible payoff after each setup section

## Competitive Research Takeaways

Relevant research and storyboard docs:

- `docs/atlas-onboarding-ux-deep-dive-2026-04-21.md`
- `docs/atlas-cal-ai-finch-dream-ux-2026-04-21.md`
- `docs/atlas-dream-onboarding-locked-storyboard-2026-04-21.md`
- `docs/atlas-dream-onboarding-motion-spec-2026-04-21.md`

Core takeaways:

- Borrow Cal AI's camera-demo confidence, one-question cadence, generated-plan payoff, and dashboard clarity.
- Borrow Finch's emotional ownership, earned hatching moment, no-empty-home Day 1 loop, and gentle retention.
- Borrow Shotsy's specificity around protocol state and journey context.
- Borrow Noom/Quittr-style assessment-to-plan mechanics without shame, diagnosis, fear, or manipulative billing pressure.
- Avoid Cal AI billing/trust mistakes.
- Avoid making Atlas pet-first like Finch.
- Avoid Quittr-style shame or diagnostic framing.

## Main App UX Changes From This Thread

The app now has more proof-led Day 1 and protocol affordances across the main experience:

- Today trust/readiness and Day 1 command-center affordances
- quick action dock
- Timeline review delta card
- Library protocol infrastructure card
- Insights evidence card
- Review Mode artifact builder card
- Trust Vault signature card
- Settings companion continuity card

Relevant files include:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasExperienceUpgradeFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasReviewModeFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasTrustVaultFeatures.swift`

## Logo Context

The app icon set was replaced with the attached blue/cyan broken-ring logo. The launch screen uses `AppIcon`.

## QA Expectations

For onboarding or UI work, use this minimum loop unless the task is docs-only:

1. Debug build.
2. Full native test target.
3. Fresh install simulator screenshots for first onboarding screen, first required choice, Today shell, and dark-mode Today shell when readability is relevant.
4. Release archive if preparing TestFlight.
5. Export with the existing App Store Connect upload options.

Prefer a booted simulator when available instead of hardcoding a simulator UDID.

## Fresh Thread First Move

Run `git status --short` before editing. There may be substantial local app changes, derived data, and build outputs. Do not clean, reset, or revert anything unless the user explicitly asks.

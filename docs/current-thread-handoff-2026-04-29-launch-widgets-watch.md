# Current Thread Handoff: Launch Readiness, Supabase, Widgets, Watch Functions

Date: 2026-04-29

## Product Context

Kairo is the current user-facing app name. The repository, Xcode project, bundle identifiers, and many older symbols still say Atlas. Fresh Codex threads must work in the canonical repo:

`/Users/donghokang/Developer/Atlas`

The native iOS app under `atlas-ios/` is the primary product path. Kairo is a premium iPhone peptide protocol system: onboarding, protocol setup, shot logging, site rotation, vial/inventory runway, side-effect/context capture, progress evidence, companion/rewards continuity, widgets, App Intents/Shortcuts, reminders, Health integrations, review/export, and optional cloud sync/live review.

Kairo is not a marketplace, sourcing app, vendor comparison app, medical advice app, dosing advice app, diagnostic tool, AI chatbot product, social app, calorie tracker, or shop/economy loop.

## Current Working Style Requirements

- Read `AGENTS.md`, `README.md`, `atlas-ios/README.md`, `docs/fresh-codex-thread-prompt.md`, and the current handoff docs before making broad changes.
- Always run `git status --short` before editing.
- The worktree often contains many unrelated local edits, generated assets, build folders, and previous-thread artifacts. Do not clean, reset, revert, delete, or overwrite unrelated changes.
- Do not work in any legacy or accidental repo path. The real repo is `/Users/donghokang/Developer/Atlas`.
- For iOS work, use the Build iOS Apps skills when relevant, especially SwiftUI UI patterns/refactor, iOS debugger/simulator workflows, App Intents, and real build validation.
- Do not stop at analysis when the user clearly asks for implementation.

## Onboarding Fixes From This Thread

Recent onboarding work focused on making the setup flow behave like a real product rather than a static demo:

- Selecting daily injections should skip the "what day do you typically inject?" step.
- "Choose all that apply" day-selection screens should support multiple selected days.
- Main goal selection should support multiple goals.
- Onboarding inputs should drive app preview/state wherever shown; do not leave fake placeholder user data.
- The onboarding demo video was shortened slightly while preserving the premium look and best-feature coverage.

Fresh threads touching onboarding should inspect `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`, run the simulator, and verify branching/state propagation before claiming the flow is fixed.

## Progress Photos Direction

The old progress-photo pose placeholders were rejected as blobby. A new direction was implemented for the six pose cards:

- The cards should show clear front, side, and back pose states.
- The pose treatment should feel like Kairo's injection-site/body-map art family rather than generic rounded blobs.
- The side pose was specifically adjusted to keep more natural proportions, then shrunk slightly so it no longer grazes the top and bottom of the card.

Fresh threads should preserve this direction unless the user requests a new art system. Do not revert to the old blobby placeholders.

## Aetherion Direction

Aetherion is the masculine companion path. Aurielle is aimed more at women; Aetherion should feel explicitly more male-user-appealing while still belonging to the same premium Kairo companion family.

Current approved direction:

- Aetherion should evolve across a starter stage and two evolutions.
- The inspiration was "Zekrom and Charizard" in broad masculine creature-energy terms, not literal copying.
- Keep Aetherion in the same teal/cream crystalline material family as Aurielle.
- It should be premium, companion-like, powerful, and masculine, not scary, childish, random, educational, or unrelated.
- Do not generate unrelated objects. Do not replace Aetherion with a generic monster, logo, diagram, or infographic.
- Aetherion wiring should have parity with Aurielle across onboarding, companion selection, mascot stages, stickers, mockups, rewards, and ambient surfaces.

Relevant files and assets include:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage*.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAetherionStage*.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAetherionEvolution.imageset/`

## Logo Direction

The latest generated logo attempt before this handoff was rejected. Do not treat it as approved.

The user wants the original logo shape preserved, simplified for iPhone/App Store use, and the center diamond/gem removed. A fresh logo attempt should start from the original/previous approved silhouette if recoverable, not from a new unrelated shape.

## Launch Feature Reality Checks

Several onboarding/App Store claims were checked and adjusted during launch-readiness work:

- Health apps: Kairo has HealthKit-facing integration surfaces, but real-device permission/read/write validation is still required before App Store confidence.
- Rating: the App Store rating prompt path should use the real StoreKit review request behavior, not a placeholder.
- App tracking: the ATT prompt path should use AppTrackingTransparency, not fake UI.
- Reminders: reminder permission/scheduling should use UserNotifications, not a placeholder.
- Trial/payments: the paywall should advertise a 7-day trial, not a 3-day trial, and StoreKit code expects real App Store Connect products.
- Limited preview should mean a real app state/access mode, not just copy.

Important App Store Connect caveat:

- Create/configure `com.dkang2000.Atlas.kairo.pro.annual`
- Create/configure `com.dkang2000.Atlas.kairo.pro.monthly`
- Both products must have 7-day introductory free trials configured before submission/TestFlight paywall validation.

## Supabase / Backend State

Kairo has a real Supabase backend path for auth/sync/live review. Fresh threads should not assume Supabase is dead code.

Known launch backend context from current docs and recent validation:

- Supabase project ref: `nppqywaxawvvdhiedpxc`
- Supabase URL and anon key are configured in `atlas-ios/Atlas/Info.plist`.
- Google auth, Apple auth, and email/password auth are intended launch paths.
- Apple can handle native identity via Sign in with Apple; Supabase remains useful for app data sync, live review links, cross-device/account recovery, and any server-backed sharing/review workflows.
- Local-first persistence remains important. Do not move sensitive protocol data to cloud by default without explicit product/security direction.

If touching backend/auth, re-check `docs/codex-launch-handoff.md`, `backend/supabase/`, and `atlas-ios/Packages/AtlasSystem/Sources/AtlasSystem/AtlasCloudSync.swift`. Use browser/Playwright only for live dashboard validation when the user is signed in and asks for it.

## Widgets And Apple Watch Functions

Widgets exist through `AtlasWidgetsExtension` and should continue to be launch-hardened with real shared projection data, not screenshots.

Apple Watch work should currently mean Watch-accessible functions via App Intents/Shortcuts, not a full watchOS companion app UI. The user explicitly did not want a full watch companion app at this stage.

Latest implemented watch/functions work:

- `AtlasIntentsExtension.appex` is embedded in the app target alongside `AtlasWidgetsExtension.appex`.
- The scheme builds the widget and intents extensions for archive/profile contexts.
- The intents extension display name is `Kairo`.
- Shortcuts were promoted/rebalanced around high-value Watch/Siri/Shortcuts actions:
  - Open Today
  - Quick Capture
  - Watch Functions
  - Mark Next Due
  - Skip Next Due
  - Log Hydration
  - Log Protein Meal
  - Log Low Appetite
  - Log Weight
  - Log Symptom
- Pending widget/intent actions are consumed at app launch as well as when the scene becomes active.
- Pending extension actions are rejected if stale or malformed.
- The Watch companion surface now says `Log Low Appetite` instead of the older generic workout-context phrase.

Important limitation:

- These functions open Kairo and hand off work through the app group/pending-action route. They are not a standalone offline watchOS app, complication, or native WatchKit UI.
- True on-watch offline execution, complications, or a dedicated watch UI would require a watchOS target, WCSession/sync design, and additional persistence/UI work. Do not add that unless the user explicitly asks.

Recent validation:

- Clean Debug simulator build succeeded.
- Release simulator build succeeded.
- Built app bundle contained both `AtlasWidgetsExtension.appex` and `AtlasIntentsExtension.appex`.
- Built intents extension contained `Metadata.appintents/extract.actionsdata`, NLU metadata, and the new shortcut actions.
- Focused handoff tests passed for hydration context shortcut and quick-log next-due handoff.

## Useful Build/Test Commands

Use the iPhone 16e simulator when available:

```sh
xcodebuild build \
  -project atlas-ios/Atlas.xcodeproj \
  -scheme Atlas \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -derivedDataPath atlas-ios/.derived-data-codex-current \
  CODE_SIGNING_ALLOWED=NO
```

For focused handoff tests:

```sh
xcodebuild test \
  -project atlas-ios/Atlas.xcodeproj \
  -scheme Atlas \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -derivedDataPath atlas-ios/.derived-data-codex-tests \
  -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingContextShortcutURLWritesHydrationEntry \
  CODE_SIGNING_ALLOWED=NO
```

```sh
xcodebuild test \
  -project atlas-ios/Atlas.xcodeproj \
  -scheme Atlas \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -derivedDataPath atlas-ios/.derived-data-codex-tests-quicklog \
  -only-testing:AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection \
  CODE_SIGNING_ALLOWED=NO
```

## Fresh Thread Startup Summary

A fresh Codex thread should understand:

- Kairo is the app users see; Atlas remains the repo/project/internal name.
- The canonical repo is `/Users/donghokang/Developer/Atlas`.
- Native iOS in `atlas-ios/` is the product path.
- Current priority is launch readiness: real functionality, real payments/auth/reminders/Health paths, visual fidelity, widgets, App Intents, and regression cleanup.
- Do not create fake placeholders, static shells, or unauthorized visual containers.
- Do not reinterpret approved mockups.
- Do not remove working functionality to make a screenshot look easier.
- Do not clean up the dirty worktree unless the user explicitly requests it.
- After reading context and running `git status --short`, summarize briefly and wait for the user's next instructions.

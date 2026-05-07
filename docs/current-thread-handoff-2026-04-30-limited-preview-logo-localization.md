# Current Thread Handoff - 2026-04-30 - Limited Preview, Widgets, Watch, Logo, Localization

This handoff captures recent decisions and implementation context that may not be obvious from older launch docs. Fresh Codex threads should read this after the April 29 launch/widgets/watch handoff.

## Product Context

- The user-facing app name is **Kairo**. Atlas remains the repo/project/internal name in many files.
- Native iOS under `atlas-ios/` remains the primary product path.
- Kairo is a premium iPhone peptide protocol system. Do not frame it as a marketplace, medical advice app, AI chatbot, social app, or calorie tracker.
- The user expects approved visual direction to be translated one-to-one while preserving real functionality. Do not replace real flows with static mockup shells or generic health-app UI.
- The worktree has often been dirty. Always run `git status --short` before editing and do not clean, reset, revert, delete, or overwrite unrelated changes.

## Current Navigation / Shell Direction

- The app uses five bottom tabs:
  - Today
  - Log
  - Protocols
  - Progress
  - Companion
- The Companion tab should be a real companion destination, with settings still accessible from that area. Do not bury settings so the user cannot access account/subscription/configuration surfaces.
- Limited preview users should be able to switch among all five tabs, but should not be able to use real app features without upgrading.

## Limited Preview / Subscription Gating

Recent implementation added explicit limited-preview behavior:

- Choosing limited preview completes onboarding as a local preview:
  - `paywallChoice = .basic`
  - `kairo_premium_access = limited_preview`
  - local-only guest state unless the user later signs in
- In limited preview, tab switching remains available.
- Tapping app content or core feature routes/actions should trigger an upgrade prompt rather than performing the feature.
- The upgrade prompt offers:
  - Start 7-day free trial
  - Monthly - `$9.99/month`
  - Annual - `$59.99/year`
  - Last chance discount - `$39.99/year`
- Core guarded actions include route opening, protocol create/update, occurrence logging, and reminder/calendar permission actions.

Important product IDs:

- `com.dkang2000.Atlas.kairo.pro.annual`
- `com.dkang2000.Atlas.kairo.pro.monthly`
- `com.dkang2000.Atlas.kairo.pro.annual.lastchance`

The monthly and normal annual products are expected to have 7-day introductory free trials configured in App Store Connect. The last-chance annual product is a separate yearly product intended to charge `$39.99/year`; do not fake this by showing `$39.99` while purchasing the `$59.99` product.

Relevant files:

- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasOnboarding.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/KairoPremiumStore.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasOnboardingRepository.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

Recent targeted test command used for limited preview:

```sh
xcodebuild test \
  -project /Users/donghokang/Developer/Atlas/atlas-ios/Atlas.xcodeproj \
  -scheme Atlas \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -derivedDataPath /Users/donghokang/Developer/Atlas/atlas-ios/.derived-data-limited-preview-gate \
  -only-testing:AtlasTests/AtlasPhaseOneTests/testLimitedPreviewCompletesOnboardingAsLocalPreview \
  -only-testing:AtlasTests/AtlasPhaseOneTests/testLimitedPreviewAllowsTabsButGatesFeatureRoutes \
  -only-testing:AtlasTests/AtlasPhaseOneTests/testLimitedPreviewGatesProtocolCreation
```

This passed after the last-chance discount changes. A prior run failed with `errno=28` because the machine was low on disk space; that was not a Swift/source failure.

## Existing Account Sign-In

- The onboarding `Already have an account? Sign in` path should not simply advance onboarding as a generic guest.
- If a saved cloud session exists, it should skip onboarding into the app.
- If there is no saved cloud session, it should skip onboarding and route to account settings/auth so the user can authenticate.
- Do not let limited-preview route gating block this account-auth path.

## Widgets

Widgets were rebuilt from scratch after rejected placeholder/generic attempts.

Current desired widget behavior:

- Companion widget:
  - show only the user's chosen companion, not both mascots
  - include companion name
  - show mascot level with XP bar
  - show days left until next shot
  - show days left until vial replacement
  - use Kairo mascot/design language and real art assets
- Activity widget:
  - include protein, hydration, and workout circles
  - include step count only if Apple Health is connected
- Avoid placeholder copy such as "Turn on rewards" if the app no longer exposes that as a clear user action.
- Avoid old mascot form names such as Moppet, Glisshare, Cindlet, or Voltflare in current user-facing surfaces unless the product strategy explicitly reintroduces them.

Relevant files:

- `atlas-ios/AtlasWidgetsExtension/AtlasWidgetsExtension.swift`
- `atlas-ios/AtlasWidgetsExtension/Assets.xcassets/`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasMascotMomentsSupport.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasRepositories.swift`

## Watch / App Intents

Kairo currently exposes watch-accessible functions through embedded App Intents/App Shortcuts in `AtlasIntentsExtension`, not a full standalone watchOS app.

Recent watch direction:

- Remove outdated watch mechanics/copy tied to old sprite/form language.
- A richer Watch Companion destination should exist in the iPhone app and be a real active destination.
- Current promoted shortcuts were adjusted around useful watch actions, constrained by the App Shortcuts maximum.

Relevant files:

- `atlas-ios/AtlasIntentsExtension/IntentHandler.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasWatchCompanionFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`

Known screenshot artifact from earlier verification:

- `atlas-ios/watch-companion-active.png`

## Kairo Logo / App Icon

The user rejected the old logo because of a weird small V-shaped diamond/chevron remnant in the center. The desired current logo is the teal flame/leaf mark without that inner V/diamond artifact.

Live source assets that were replaced with the cleaned white-background logo:

- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingLogoMark.imageset/kairo-onboarding-logo-mark.png`
- `atlas-ios/Atlas/Assets.xcassets/KairoAppIconPreview.imageset/kairo-app-icon-preview.png`
- `atlas-ios/Atlas/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`
- `landing-page/assets/kairo-logo.png`

Some `output/kairo-logo-*` preview copies were also updated. Historical `build/`, TestFlight `.xcarchive`, and old screenshot artifacts should generally not be rewritten unless explicitly requested because they are build artifacts or references, not live source assets.

Logo replacement verification:

- Onboarding/app icon preview assets are 1024 x 1024.
- App icon sizes remain:
  - 40
  - 60
  - 58
  - 87
  - 80
  - 120
  - 180
  - 1024

## Localization Guidance

Current recommendation:

- Launch English first.
- Add Spanish next for the US market.
- Add French and German once retention/subscription conversion are proven.
- Consider Portuguese (Brazil) later.
- Japanese/Korean are attractive but require more careful product/copy QA.

Translation should cover two separate layers:

- In-app strings: use Xcode String Catalogs (`.xcstrings`) or the repo's eventual localization system for onboarding, paywall, reminders, widgets, settings, errors, and app copy.
- App Store listing: localize App Store Connect metadata, keywords, screenshots/previews, subscription display names/descriptions, and promotional text.

Because Kairo is premium and health-adjacent, AI translation should be treated as a draft only. Human review is strongly recommended for paywall copy, medical disclaimers, protocol language, onboarding claims, and App Store metadata.

## Quality Bar For Future Threads

- Do not reinterpret approved mockups or assets.
- Do not use fake placeholders, static shells, unauthorized containers, or generic wellness UI.
- Do not resurrect old mascot/form names from archived concepts.
- Use real simulator/device verification for widgets/watch/app UI when asked to show what something looks like.
- If asked to use image generation for assets, preserve the user's exact requested invariant. For the Kairo logo specifically, the central V-shaped diamond remnant is the defect to remove, not the thing to preserve.
- Keep final responses concise and tell the user clearly what was changed, what was verified, and what remains blocked.

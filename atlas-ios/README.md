# Atlas Native iOS

This directory contains the native iOS Atlas app through native parity, Trust Vault, selective sharing, Universal Migration + Provider Handoff, Review Mode, Episode Intelligence, and final release hardening.

## Targets
- `Atlas`
- `AtlasWidgetsExtension`
- `AtlasIntentsExtension`
- `AtlasTests`

## Local packages
- `AtlasDesignSystem`
- `AtlasDomain`
- `AtlasPersistence`
- `AtlasPrivacy`
- `AtlasSystem`
- `AtlasFeatures`

## Local dependencies
- `ThirdParty/GRDBLocal`
  - pinned local checkout of `GRDB.swift` used for deterministic native SQLite persistence in this workspace

## Toolchain
- Xcode `26.3`
- Apple Swift `6.2.4`
- iOS deployment target `17.0`

## Product scope
The native app now includes:
- onboarding and guest/account boundary
- Today, Timeline, Library, Insights, and Settings
- protocol creation/edit plus Protocol Change Studio
- native reminders and quick logging
- inventory, vials, calculator profiles, and site tracking
- Trust Vault, selective sharing, raw exports, provider handoff, and Review Mode
- metrics/insights, optional rewards, and deterministic Episode Intelligence
- lightweight nutrition tracking with meal context, quick capture, common foods, hydration/protein/fiber targets, and weekly coaching

## Open in Xcode
Open `Atlas.xcodeproj` in Xcode 26.3+ and run the `Atlas` scheme on an iOS 17 simulator or device.

For a clean machine, resolve local packages once before the first build:
- `cd atlas-ios`
- `swift package resolve --package-path Packages/AtlasPersistence`

## Command-line verification
Clean Debug app build:
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`

Clean Release app build:
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -scheme Atlas -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath atlas-ios/.derived-data-release build`

Release extension builds:
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasWidgetsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project atlas-ios/Atlas.xcodeproj -target AtlasIntentsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`

Full native test suite:
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-release`

Verified fallback command in this workspace:
- `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project atlas-ios/Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath atlas-ios/.derived-data-nosign-serial -only-testing:AtlasTests/AtlasPhaseOneTests`

If package resolution gets stuck on a machine with a valid Xcode install:
- remove `atlas-ios/.derived-data`
- remove `atlas-ios/Atlas.xcodeproj/project.xcworkspace/xcshareddata/swiftpm`
- rerun `swift package resolve --package-path Packages/AtlasPersistence`

Notes:
- the project is configured for `iOS 17+`
- local Swift packages live under `atlas-ios/Packages/`
- local package resolution is fully path-based inside the repo
- the app is local-first and guest-first by default
- rewards and nutrition coaching stay deterministic and local-first; they do not require an LLM or cloud nutrition service
- widgets and intents compile, but business logic stays intentionally narrow compared with the main app
- HealthKit remains scaffold-only
- see `../docs/native-release-readiness.md` for final release status and `../qa/native-ios-release-manual-checklist.md` for manual beta QA

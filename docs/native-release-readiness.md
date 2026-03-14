# Atlas Native Release Readiness

Date: 2026-03-14

## Decision
- Status: `CONDITIONAL`
- Rationale: automated verification is green, release builds compile, and the native product surface is feature-complete relative to the roadmap. Final readiness still depends on a real-device manual pass and a signed TestFlight archive smoke.

## Automated verification
- Debug app build:
  - `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -destination 'generic/platform=iOS Simulator' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release' build`
  - Result: `BUILD SUCCEEDED`
- Release app build:
  - `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release' build`
  - Result: `BUILD SUCCEEDED`
- Release extension builds:
  - `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -target AtlasWidgetsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
  - `xcodebuild -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -target AtlasIntentsExtension -configuration Release -destination 'generic/platform=iOS Simulator' build`
  - Result: `BUILD SUCCEEDED` for both
- Package builds:
  - `swift build` in `atlas-ios/Packages/AtlasPersistence`
  - `swift build` in `atlas-ios/Packages/AtlasFeatures`
  - Result: succeeded
- Full native test suite:
  - `xcodebuild test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -project '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/Atlas.xcodeproj' -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath '/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release'`
  - Result: `86` tests passed, `0` failures
  - xcresult: `/Users/donghokang/Documents/New project 4/Atlas/atlas-ios/.derived-data-release/Logs/Test/Test-Atlas-2026.03.14_18-21-33--0400.xcresult`

## Reliability hardening completed
- Bootstrap no longer crashes if both live and in-memory persistence setup fail. The app now shows a recoverable launch-failure screen with retry instead of calling `fatalError`.
- Shell-level loading and error messaging is already present across Today, Timeline, Library, Insights, Settings, Change Studio, Trust Vault, Review Mode, and Import Center.
- Import/export flows are already transactional and cancel-safe, with backup export behavior on replace-import paths.
- Reminder synchronization and projection regeneration remain covered by automated tests after logging, protocol edits, and change-studio commits.

## Privacy and security audit summary
- Alias/discreet rendering remains enforced across:
  - Today
  - Timeline
  - Library
  - Protocol detail and Change Studio
  - Inventory and vials
  - Insights and metrics
  - Notifications/reminder preview
  - Trust Vault
  - Selective sharing
  - Provider handoff
  - Review Mode
  - Episode summaries
- Sensitive actions continue to append audit entries instead of mutating historical records.
- Biometrics remain opt-in and bounded to sensitive Trust Vault/export actions.
- Extension surfaces compile without widening main-app data access; the canonical database is not directly shared with extensions.

## Manual QA matrix
- Primary checklist: `/Users/donghokang/Documents/New project 4/Atlas/qa/native-ios-release-manual-checklist.md`
- Required fixture states:
  - guest first-run user
  - imported user with protocols/logs/reminders
  - privacy-heavy user with alias/discreet settings
  - inventory-heavy user with active linked vials and sites
  - review/share/export-heavy user with Trust Vault audits

## Migration safety checklist
- Verify Atlas JSON import on a clean install before any local data exists.
- Verify replace-import generates a backup export before destructive commit.
- Verify imported users bypass onboarding and land in the app shell.
- Verify immutable historical logs remain unchanged after protocol edits, imports, and review/export flows.
- Keep React Native Atlas as the migration oracle until native private beta confidence is established.

## Rollback strategy
- If native beta shows migration or privacy regressions, pause TestFlight expansion and keep React Native Atlas as the primary tester path.
- Preserve exported backup bundles before replace-import or provider/share flows.
- Use versioned JSON export as the lowest-risk escape hatch for affected testers.

## Critical blockers before broader TestFlight
- Physical iPhone pass for notifications, share sheets, biometrics, import/export file handoff, and resume behavior.
- Signed archive + TestFlight upload + clean-install smoke.

## Medium-priority follow-ups
- Finish small-phone and large-phone accessibility pass with Dynamic Type and VoiceOver.
- Finalize privacy-safe analytics/crash instrumentation only if product/privacy review approves the event list.
- Measure large-history and large-insights performance on older devices, not just simulator.

## Known issues for private beta
- Health connection remains scaffold-only and non-blocking.
- Live/cloud-backed review sessions remain feature-flagged off.
- Widget and App Intents targets compile, but business logic remains intentionally narrow relative to the main app.
- `xcodebuild` target-only extension builds emit the harmless warning that the provided run destination is ignored when no scheme is passed.

## Release notes draft
- Atlas is now available as a native iPhone beta with local-first onboarding, protocol tracking, reminders, immutable history, inventory/vials, calculator profiles, site tracking, Trust Vault privacy controls, selective sharing, provider handoff, Review Mode, and deterministic Episode Intelligence.
- Atlas Export JSON remains the canonical migration path for existing users.
- Guest mode stays fully supported and cloud sync is still optional.

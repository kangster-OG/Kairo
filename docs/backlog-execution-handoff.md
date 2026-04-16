# Atlas Backlog Execution Handoff

Last updated: 2026-04-11 (Wave 8 complete)

## Purpose

This document is the source-of-truth handoff for post-launch backlog execution in the native iOS Atlas app.

Use it when continuing backlog implementation work in `/Users/donghokang/Developer/Atlas`.

## Canonical workspace

- Repo root: `/Users/donghokang/Developer/Atlas`
- Canonical iOS app root: `/Users/donghokang/Developer/Atlas/atlas-ios`
- Do not use the legacy Documents copy for active Xcode work

## Ground rules

- Do not redo already-completed launch prep, backend deploy, simulator smoke, or the premium UI pass unless a specific regression blocks new work.
- Keep Atlas local-first and guest-first.
- Keep Atlas positioned as a protocol operating system for committed peptide / GLP / injectable users, not as a peptide discovery marketplace.
- Keep meal logging as context capture, not a nutrition tracker.
- Keep wearable integration HealthKit-first.
- Keep copy calm, serious, premium, and non-judgmental.
- Do not introduce shopping, marketplace, sourcing recommendations, social pressure, or medical advice.

## Roadmap sequence

The approved execution order is:

1. Meal / context expansion
2. Workout / activity tracking + HealthKit workout ingestion
3. Deterministic explainability
4. Migration / restore / handoff polish
5. Supplies / procurement / vendor-history completion
6. Widgets + App Intents polish
7. Calm retention + mascot refinement
8. Local-first premium summaries

Strategic defaults already chosen:

- Sequence: context first
- Wearables: HealthKit first
- Local-first summaries: after deterministic explainability
- Procurement: local planning hub, not commerce
- Retention tone: subtle premium, optional, non-punitive

## Protocol intelligence direction

Atlas now has an initial compound-intelligence layer and two related operating-system features:

- compound metadata for common GLPs, peptides, and injectable hormone / steroid protocols
- Library compare / swap guidance
- Protocol Change Studio interaction guidance

These features should be extended as operational protocol support, not as a public encyclopedia.

Good fits:

- clearer compare / replace flows inside existing protocol editing
- better interaction warnings for active overlaps, cadence changes, unit mismatches, and stack burden
- richer but bounded compound metadata such as route, cadence, common units, availability/source type, and operational tags

Avoid turning this into:

- a provider directory
- a provider map
- a public review marketplace
- a broad educational content hub
- a sourcing recommendation engine
- a generic AI concierge

## Current execution status

Wave 1 is now in strong shape locally and should be preserved from the current working tree, not re-planned from scratch.

### Wave 1 slice already implemented

The current thread completed the first real execution slice of meal/context expansion:

- Added richer meal/context fields:
  - `mealSize`
  - `mealComposition`
  - `presetKey`
- Wired those fields through:
  - domain models
  - persistence normalization and DB records
  - privacy formatting
  - timeline context summaries
  - review-mode context health lines
  - selective-share CSV context export
- Added a DB migration to expand `context_logs`
- Reworked the Insights context-entry flow into a faster staged capture UI:
  - preset chips
  - meal timing chips
  - meal size chips
  - meal composition chips
  - fed / fasted chips
  - optional deeper detail
- Added a lightweight Today quick-context card with fast logging buttons

### Files touched in this slice

- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasDomain.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasInsights.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasCoreLoopRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasDatabase.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasDatabaseModels.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasMetricsRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasReviewModeRepository.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasSelectiveShareExport.swift`
- `atlas-ios/Packages/AtlasPrivacy/Sources/AtlasPrivacy/AtlasPrivacy.swift`

## Verification already completed

The Wave 1 slice above was verified locally:

- iOS simulator app build succeeded with the Build iOS Apps plugin
- simulator build-and-run succeeded
- simulator smoke confirmed the new Insights context sheet opens and renders
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`

### Wave 1 follow-through now completed

Wave 1 is no longer limited to the first context-expansion slice.

The native app now also includes:

- persistent user-saved context presets
- preset reuse across the native context-entry flow
- Today quick-context preset logging
- Insights shared-sheet preset reuse

Additional verification completed:

- Today quick-context and Insights shared-sheet behavior were verified
- one-tap preset logging was verified in simulator
- suspected `Save preset` enablement bug was checked and determined to be a false alarm

### Wave 2 now implemented and validated

Wave 2 has started and is now in a strong state:

- native workout/activity domain types were added
- export snapshot and insights snapshot wiring were extended for workouts
- `workout_logs` table and migration were added
- DB record mapping and repository import logic were added for workouts
- HealthKit was extended to fetch workouts
- Apple Health connect now imports workouts since the previous sync
- Insights now includes an Activity section for recent imported workouts

Verification completed for Wave 2:

- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- targeted workout import regression initially passed:
  - `AtlasTests/AtlasPhaseOneTests/testConnectHealthKitImportsRecentWorkoutsIntoInsights`
- real-device QA on connected iPhone verified:
  - Apple Health connection imported workouts into the live device database
  - `health_connections.last_sync_at` updated as expected
  - imported activity kinds looked plausible on real data
- additional regression coverage was added and passed for:
  - previous `lastSyncAt` being used as the follow-up sync cursor
  - duplicate workout imports being skipped by `external_source_id`
  - mixed old/new follow-up sync batches deduping correctly
  - workout logs surviving raw export and raw JSON backup/restore
  - workouts remaining excluded from selective share while included in raw export

### Wave 3 now implemented and validated

Wave 3 is now in a strong state locally:

- deterministic explainability cards were added to Insights
- explanation generation stays local, explicit, and heuristic-driven in persistence/domain logic
- surfaced relationships now cover recent symptom timing near:
  - context logs
  - imported workouts
  - weight check-ins
  - supported custom-metric check-ins
- explanation cards use bounded, non-speculative structure:
  - `Observed`
  - `Window`
  - `Records`
  - `Why this appears`
- explanation selection guardrails were added so Atlas stays calm rather than noisy:
  - repeated evidence required before surfacing
  - minimum recent-window coverage required
  - self-referential symptom/context echoes skipped
  - free-text custom metrics excluded from deterministic relationship cards
  - only the strongest cards surface per symptom / relationship type

Verification completed for Wave 3:

- targeted deterministic explainability regressions passed for:
  - symptom near context
  - symptom after workout
  - symptom near weight check-ins
  - symptom near supported custom metrics
  - weak single-match cases staying hidden
  - self-referential context cases staying hidden
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded
- live shell validation confirmed the Insights tab still renders cleanly after the Wave 3 explainability additions

## Immediate next work

All currently approved backlog waves are now complete locally.

If summary work continues beyond this point, treat it as optional follow-up rather than unfinished Wave 8:

- preserve all existing Wave 1 through Wave 8 behavior
- keep Atlas local-first, guest-first, calm, and bounded
- continue avoiding commerce-like copy or sourcing pressure
- only consider external or hosted summary providers as a later explicitly opt-in layer, not as a requirement for Atlas core functionality

### Wave 8 now completed locally

Wave 8 is now in a strong state locally as a local-first premium summary system:

- deterministic plain-language recaps were upgraded across:
  - weekly recap
  - episode recap
  - import diff recap
  - provider handoff recap
- summary wording now feels less template-flat while staying descriptive, bounded, and evidence-led
- summary cards now present clearer local execution labeling and generated-at metadata without hiding source facts
- if a future external summary path is enabled but unavailable, Atlas now falls back calmly to the local recap instead of dropping the summary entirely
- no hosted AI dependency was introduced for the primary summary experience
- external provider summaries remain explicitly deferred, opt-in, and off by default in this build
- Wave 8 completion is defined by the stronger local summary system, not by shipping a cloud-dependent AI layer

## Verification completed for Wave 8

- targeted summary regressions passed for:
  - `testInsightsSummariesStayBoundedAndRespectDiscreetRendering`
  - `testEpisodeAndImportSummariesRemainOptionalAndGrounded`
  - `testDeferredExternalSummaryFallsBackToLocalRecap`
  - `testProviderHandoffPlainLanguageSummaryUsesCurrentToggleAndAliasScope`
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded
- live simulator QA verified:
  - Settings still presents plain-language summaries as an on-device local feature
  - external summary processing remains visibly unavailable in the current build
  - summary/privacy controls still render cleanly after the Wave 8 changes

### Wave 4 now completed locally

Wave 4 is now in a strong state:

- restore points now persist file integrity metadata alongside the saved backup reference
- preview/restore now block calmly when a restore-point file is:
  - missing from disk
  - malformed / no longer decodable as an Atlas bundle
  - changed after creation and no longer matches Atlas integrity checks
- older restore points without integrity metadata now backfill that metadata opportunistically when listed or opened
- restore preview/commit guardrails remain local-first and transactional; no cloud dependency was introduced
- selective share and provider handoff previews now anchor their default recent windows to the relevant local data being exported, so historical datasets do not silently drift out of preview scope as wall-clock time moves on
- pending occurrence projections are now treated as a rebuildable cache and are refreshed for the requested reference date, which prevents stale import/restore horizons from leaking into Today or handoff QA when local state was created at a different time
- Import Center / restore-point operator surfaces remain calm and explicit:
  - preview-first import flow preserved
  - restore-point empty state renders clearly
  - restore copy stays local-first and bounded

Files touched in Wave 4:

- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasCoreLoopRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasDatabase.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasImportExportBridge.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasSelectiveShareExport.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasUniversalMigration.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

## Verification completed for Wave 4

- full `AtlasTests/AtlasPhaseOneTests` passed:
  - `143` passed
  - `0` failed
- restore/migration coverage now explicitly includes:
  - replace import creating a restore point before commit
  - restore preview matching restore result and appending audit
  - missing restore-point backup files being rejected calmly
  - tampered restore-point backup files being rejected calmly
  - historical shell refresh reprojecting pending occurrences for the requested reference date
  - provider handoff / selective-share episode summaries staying bounded for historical data
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded
- live simulator QA verified:
  - Today still renders correctly after the Wave 4 changes
  - Settings still opens cleanly
  - Import Center opens cleanly
  - restore-point section renders the expected empty/operator-ready state when no restore points exist

### Wave 5 now completed locally

Wave 5 is now in a strong state locally:

- supplies / procurement / vendor-history completion is now implemented as a local planning workflow rather than a commerce flow
- supplies now keep calm procurement planning state:
  - procurement review urgency
  - reorder threshold context
  - projected reorder / depletion timing
  - lead-time context
  - most recent procurement label
- supply detail now supports explicit local procurement logging with:
  - quantity received
  - vendor / source label
  - source note
  - received-at timestamp
- procurement and opening-stock events now build a durable vendor/source history ledger for each supply
- current supply vendor/source fields continue to work, but they are now backed by historical procurement entries instead of only a single current-state label
- export privacy guardrails were extended so alias-mode raw exports keep supply names privacy-safe and redact procurement vendor/source metadata
- copy and flows remain calm, local-first, and operator-friendly:
  - no marketplace behavior
  - no buy-now flow
  - no promotional reorder language

Files touched in Wave 5:

- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasDomain.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasInventory.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInventoryFeatures.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasDatabase.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasDatabaseModels.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasInventoryRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasPersistence.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasSelectiveShareExport.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

## Verification completed for Wave 5

- targeted Wave 5 inventory / procurement regressions passed for:
  - consumable low-stock and opening-stock vendor history staying deterministic
  - taken-log depletion continuing to append separate supply history
  - explicit procurement events restoring planning headroom and vendor/source history
  - raw export + alias export privacy behavior for procurement metadata
  - consumable render modes staying privacy-safe
- full `AtlasTests/AtlasPhaseOneTests` passed:
  - `144` passed
  - `0` failed
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded
- live simulator QA verified:
  - Library opens cleanly
  - Inventory opens cleanly from Library
  - Inventory low-stock watch renders the new procurement-review copy without breaking the shell

### Wave 6 now completed locally

Wave 6 is now in a strong state locally:

- widgets and App Intents now use a hardened shared-projection contract with explicit freshness guardrails instead of assuming extension state is always current
- extension-safe projection support now includes:
  - generated-at freshness handling for widget / intent trust checks
  - low-stock procurement review count in the widget-facing snapshot
  - consumable low-stock detail preferring procurement-review status when action is due
- widget behavior now stays calm and privacy-aware when local projection state is stale:
  - next-due widget falls back to refresh copy instead of surfacing stale quick actions
  - low-stock widget falls back to refresh copy instead of overstating old inventory state
  - widget copy now surfaces last-refresh timing when available
- App Intents / shortcuts now stay bounded:
  - next-due taken / skip shortcuts refuse stale projection state and ask Atlas to refresh locally first
  - Trust Vault now has a direct Atlas shortcut / deep-link entry point for privacy-first navigation
- Atlas app routing now supports direct Trust Vault handoff from extension / shortcut entry paths
- live simulator app-group projection output was checked and confirmed to refresh with:
  - current `generatedAt`
  - current `nextDue`
  - current `procurementReviewCount`

Files touched in Wave 6:

- `atlas-ios/AtlasIntentsExtension/IntentHandler.swift`
- `atlas-ios/AtlasWidgetsExtension/AtlasWidgetsExtension.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasDomain.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasExtensionProjectionSupport.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasRepositories.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

## Verification completed for Wave 6

- targeted Wave 6 widget / intent regressions passed on simulator for:
  - extension projection snapshot refresh
  - discreet render-mode projection refresh
  - low-stock procurement-review projection signal
  - surface-specific extension freshness windows
  - quick-log URL routing still refreshing projection state
  - Trust Vault deep-link routing
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded on booted `iPhone 17`
- live simulator QA verified:
  - `atlas://trust-vault` opens directly into Trust Vault from the running app
  - Trust Vault renders its expected privacy controls after the deep-link handoff
  - the live app-group widget projection file refreshes with the new `procurementReviewCount` field and current next-due data

### Wave 7 now completed locally

Wave 7 is now in a strong state locally:

- calm retention was refined into a continuity-first layer instead of a score-like layer:
  - streak wording was removed from retention state and copy
  - continuity labels now stay descriptive rather than gamified
  - retention helper text stays explicit about Atlas being local, optional, and non-punitive
- companion / mascot behavior is now more restrained and more premium:
  - companion copy now frames the surface as an optional accent rather than a mascot asking for attention
  - companion state now stays hidden unless Atlas has a meaningful recent continuity update to show
  - static inventory-good state alone no longer surfaces the companion
  - featured companion visuals now render with a calmer, lower-noise treatment
- Settings retention controls were tightened to match the product guardrails:
  - section renamed to `Calm continuity`
  - toggles now read `Show calm continuity` and `Show companion accent`
  - preview copy now explains that the companion stays hidden until there is something real to reflect

Files touched in Wave 7:

- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasRetention.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasRetentionRepository.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasRetentionFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/AtlasTests/AtlasPhaseOneTests.swift`

## Verification completed for Wave 7

- targeted Wave 7 calm-retention regressions passed on simulator for:
  - context continuity staying privacy-safe and non-gamified
  - companion staying hidden when there is no meaningful continuity update
  - weekly review + inventory signals continuing to compute cleanly
- `swift build` succeeded in:
  - `atlas-ios/Packages/AtlasDomain`
  - `atlas-ios/Packages/AtlasPersistence`
  - `atlas-ios/Packages/AtlasFeatures`
- full simulator app build succeeded
- simulator build-and-run succeeded on booted `iPhone 17`
- live simulator QA verified:
  - Settings renders the renamed `Calm continuity` section
  - `Show calm continuity` and `Show companion accent` controls render with the expected new copy
  - the companion preview explains that the accent stays hidden until Atlas has a meaningful continuity update

### Wave 8 now completed locally

Wave 8 is now in a strong state locally:

- operational polish is materially stronger across the shell:
  - new context, weight, symptom, and custom-metric captures now surface a premium undo banner
  - vial archive and supply archive/restore actions also register immediate undo affordances
  - Today and Insights landing surfaces are now user-configurable with persisted visibility and ordering
- Insights is now a stronger command center:
  - recent context, weight, symptom, and metric entries can be reopened as fast reuse/edit starting points
  - optional stack dashboard surfaces multi-protocol burden, timing load, and inventory risk without forcing stack framing on single-protocol users
  - optional biometrics/lab overlays group numeric trends into reusable panels and can show recent protocol-change markers
- weekly review now gets an additive stack review layer when appropriate:
  - stack summary appears only when the user has multiple active protocols and has enabled the stack dashboard surface
  - rewards, mascot, and calm-retention sections continue to compose into weekly review as before
- inventory operations are faster at scale:
  - vials can be batch-selected and archived
  - supplies can be batch-selected and archived or restored

Files touched in Wave 8:

- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasDomain.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasInsights.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasWeeklyReview.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInventoryFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasWeeklyReviewFeatures.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasInventoryRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasMetricsRepositories.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasOnboardingRepository.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasPersistence.swift`
- `atlas-ios/Packages/AtlasPersistence/Sources/AtlasPersistence/AtlasRepositories.swift`

## Verification completed for Wave 8

- full native test suite passed:
  - `193` passed
  - `0` failed
- full simulator app build succeeded
- simulator build-and-run succeeded on booted `iPhone 17`
- live simulator QA verified:
  - Today renders with configurable landing-card ordering intact
  - Settings persists command-surface toggles for stack dashboard and biometrics overlays
  - Insights renders the new stack dashboard and biometrics/lab panels when enabled
  - Weekly Review still composes rewards, mascot, and calm-retention sections alongside the new stack review block
  - inventory batch actions render and complete without breaking the shell

## Repo-state note

There may be unrelated local dirtiness in launch docs and generated Xcode/SPM metadata.

- Do not clean or revert unrelated changes unless explicitly asked.
- Focus only on the backlog execution slice in progress.

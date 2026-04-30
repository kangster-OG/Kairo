# Atlas True Fidelity Pass Handoff - 2026-04-22

## Goal

Move the whole native iOS product closer to the approved mockup direction: warm off-white shell, compact SF-style typography, slimmer cards and controls, mascot-forward progress, simple shot logging, and quieter non-privacy-led product language.

## Code Changed

- `atlas-ios/Packages/AtlasDesignSystem/Sources/AtlasDesignSystem/AtlasPremiumPrimitives.swift`
  - Default typography candidate is now system/SF-like instead of the previous custom candidate.
  - Core text roles are smaller and calmer.
  - Forced uppercase was removed from shared text roles so tiles, chips, labels, and badges feel closer to the mockup.
  - Metric and milestone primitives were tightened to 8pt-radius, lower-shadow surfaces.

- `atlas-ios/Packages/AtlasDesignSystem/Sources/AtlasDesignSystem/AtlasDesignSystem.swift`
  - Shared screen padding/spacing, section cards, input surfaces, badges, chips, and button styles were compacted.
  - Large-radius legacy controls were pulled toward the reference system: slimmer height, lower shadow, 8pt-radius form/control surfaces.

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
  - Bottom tab chrome was tuned toward the mockup: tighter icon/text sizing, calmer selected states, softer shell, and less vertical bulk.
  - Root scroll surfaces were tightened so product screens show more useful content above the fold.
  - Shared quick-capture/settings rows were compacted to better inherit the reference direction outside the three hero screens.

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotForwardScreens.swift`
  - Today, Log, Progress, Protocols, and Companion are now using the mascot-forward rebuild surfaces.
  - Log Shot has a centered nav, compact ritual card, site selector, side-effect chips, vial decrement preview, aftercare prompt, and companion reward cue.
  - Companion now has the level ring, stage art, locked next form preview, daily quests, badges/collectibles, and a richer weekly mastery gem.
  - Protocols and Progress inherit the same compact card/grid language so the mockup direction is not isolated to Today.

## Verification

- Build passed:
  - `xcodebuild -quiet -project Atlas.xcodeproj -scheme Atlas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derived-data-true-fidelity-pass build`

- Focused tests passed after the final typography update:
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot`
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot`
- `AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection`

## Second Fidelity Push

- Post-onboarding feature modules and widgets were normalized away from legacy visual tokens:
  - Removed remaining `.rounded` font design usage in feature/widget presentation code.
  - Removed explicit uppercase transforms from shared/feature presentation code.
  - Normalized local large rounded-rectangle card/control radii to the compact 8pt system, while preserving the bottom tab pill shape from the mockup.
  - Kept onboarding out of further product-direction work per latest instruction; earlier splash token cleanup remains present but no more onboarding redesign work was pursued in this push.

- Protocol Detail was tightened:
  - Changed the loud `PROTOCOL` eyebrow to `Protocol`.
  - Shortened hero summary copy into a scannable protocol line.
  - Reduced command deck spacing.
  - Reduced live-plan dashboard spacing and tile height.

- Inventory/Supplies metric behavior was fixed:
  - `AtlasMetricStrip` now wraps more than three metrics into a compact two-column grid instead of clipping into a horizontal strip.

- Widget build warning was fixed:
  - `AtlasMascotWidgetConfigurationIntent` now has explicit initializers for resolved automatic focus entries.

- Build and focused tests passed again after these second-pass changes:
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot`
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot`
  - `AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection`

## Screenshots

- `output/true-fidelity-pass-2026-04-22/08-today-final.png`
- `output/true-fidelity-pass-2026-04-22/09-log-final.png`
- `output/true-fidelity-pass-2026-04-22/10-companion-final.png`
- `output/true-fidelity-pass-2026-04-22/11-protocols-final.png`
- `output/true-fidelity-pass-2026-04-22/12-progress-final.png`
- `output/true-fidelity-pass-2026-04-22/13-today-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/14-log-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/15-companion-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/16-protocols-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/17-progress-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/18-protocol-detail-final.png`

## Remaining Fidelity Gaps

- The post-onboarding app now follows the mockup direction much more consistently at the token/component level.
- Bespoke badge/collectible art would still beat SF Symbols for true final polish.
- Some deep editors and modals still deserve screenshot-by-screenshot inspection for hierarchy and copy, but the old large-radius/rounded-font/uppercase visual language has been aggressively removed from the shared post-onboarding surface area.
- Onboarding is intentionally excluded from further fidelity work because it will be rebuilt separately.

# Kairo Crystal Vial Pod Native Hatch

Kairo ships the onboarding hatch as a native SwiftUI animation driven by generated raster art.

## Asset Sequence

The hatch uses five generated frames bundled in the main iOS app asset catalog:

- `KairoCrystalVialPodFrameDormant`
- `KairoCrystalVialPodFrameAwakening`
- `KairoCrystalVialPodFrameSwirl`
- `KairoCrystalVialPodFrameOpening`
- `KairoCrystalVialPodFrameOpened`

## Motion Direction

- Slow, premium, botanical-biotech activation.
- The vial wakes, liquid and crystal energy intensify, the glass petals open, then the selected companion appears.
- Motion is restrained and polished: light sweep, drifting particles, orbit ring, bloom, and softened reveal.
- The pod art must stay unframed: no card shell, no decorative container, no black backdrop.

## Safety And Accessibility

- Copy must not imply medical advice, dosing advice, diagnosis, or guaranteed outcomes.
- Reduce Motion keeps the experience functional with simpler transitions.

## SwiftUI Host

The shipped implementation lives in:

`atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`

Look for `KairoCrystalVialPodInteractionView` and `CrystalVialPodView`.

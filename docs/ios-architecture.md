# Atlas iOS Architecture

## Principles
- local-first source of truth
- guest-first behavior preserved
- immutable historical logs stay separate from generated future schedule occurrences
- privacy rendering remains explicit and surface-aware
- React Native stays the oracle until native parity is reached

## Module structure
`atlas-ios/Packages/` contains:
- `AtlasDesignSystem`: theme, layout primitives, placeholder shell components
- `AtlasDomain`: explicit neutral types and route contracts
- `AtlasPersistence`: repository protocols and persistence placeholders
- `AtlasPrivacy`: alias/discreet/full privacy formatting policy
- `AtlasSystem`: notifications, biometrics, HealthKit, import/export bridge, shared projection writer, feature flags
- `AtlasFeatures`: SwiftUI app model, shell, and placeholder feature screens

The `Atlas` app target owns:
- composition root
- dependency wiring
- app lifecycle
- scene creation

## Data boundary
- canonical database remains app-local
- extension readers should consume shared projection data, not the canonical store directly
- import/export bridge is a system boundary in Phase 1 and real implementation work begins in Phase 2

## Extension strategy
- widget extension reads placeholder or shared projection data
- intents extension exists as a scaffold for future shortcuts/intents work
- no business logic lives in extensions during Phase 1

## Phase 1 scope
- shell only
- no GRDB migrations yet
- no full feature ports
- no sync or cloud assumptions

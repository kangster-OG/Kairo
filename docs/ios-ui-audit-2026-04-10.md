# Atlas iOS UI Audit

Date: 2026-04-10
Basis:

- current SwiftUI implementation in `atlas-ios`
- simulator screenshots under `qa/emulator-artifacts`
- audit rubric in `docs/ios-premium-ui-rubric.md`

## Executive Read

Atlas already feels coherent, serious, and more product-shaped than a typical internal beta. The strongest traits are:

- a recognizable shell language
- consistent rounded surface shapes
- calm blue-led palette
- clear local-first and privacy-forward positioning
- good use of sectional structure instead of long unbroken feeds

The app does not yet feel fully premium because it still lacks enough distinction between:

- hero and utility surfaces
- primary and secondary actions
- trust-critical and ordinary controls
- moment transitions and steady-state content

The result is an app that reads as polished but still somewhat flat, operational, and visually same-weighted.

## Top-Level Scores

### Product-Level

- Product clarity: `4`
- Visual hierarchy: `3`
- Surface depth and materiality: `3`
- Motion and interaction quality: `2`
- Trust, privacy, and seriousness: `4`
- Form and input experience: `3`
- State design: `3`
- Information density: `3`
- Accessibility as premium quality: `4`
- Brand character: `4`

### Current Overall Read

- Current quality level: strong beta / near-release
- Premium-read target gap: meaningful but very tractable

## Product-Wide Findings

### 1. Too many surfaces share the same visual rank

The system uses attractive cards, but too many cards live at roughly the same elevation and color weight. The UI needs stronger separation between:

- hero content
- active work surfaces
- reference cards
- utility controls

Why it matters:
Premium apps feel decisive. Atlas currently feels composed, but not always decisively ranked.

### 2. The app needs a fuller interaction language

The visuals are ahead of the interaction design. Pressed states exist, but the app still needs:

- stronger tactile feedback
- smoother state transitions
- more satisfying success acknowledgments
- better continuity between navigation, sheets, and inline actions

Why it matters:
Premium quality is felt through response, not just seen through styling.

### 3. Trust features need a more unified visual system

Atlas has an unusually strong trust/privacy story, but those controls are still spread across screens in a mostly utilitarian way.

Why it matters:
Trust Vault, privacy mode, review mode, exports, sync, biometrics, and local-first messaging can become a signature product system, not just a list of settings and tools.

### 4. Primary actions are sometimes clear in copy, but not strong enough in composition

Today does this best. Settings, Review Mode, and Import Center still ask users to parse rather than immediately act.

Why it matters:
The premium version of Atlas should feel like it always knows what the user is likely here to do.

### 5. Typography and copy rhythm can be more mature

The current hierarchy is good, but premium polish will come from:

- less repeated descriptive copy
- tighter subtitle lengths
- more disciplined caption usage
- stronger distinction between instructional and persistent text

Why it matters:
The app sometimes explains too much because the structure is not yet carrying enough of the load.

## Screen Audit

### Shell And Top Navigation

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasDesignSystem/Sources/AtlasDesignSystem/AtlasDesignSystem.swift`
- `qa/emulator-artifacts/atlas-shell-rebuild-2026-03-15.png`
- `qa/emulator-artifacts/atlas-shell-hostfix-2026-03-15.png`

Strengths:

- shell header has a recognizable identity
- top area feels branded and native enough
- bottom tab bar is clear and lightweight

Gaps:

- header can feel visually heavy relative to the content below
- tab bar feels competent but still utilitarian
- selected tab state is not yet memorable or tactile enough

Suggestions:

- reduce the visual mass of the header while increasing content integration
- give the tab bar a more premium container/material feel
- improve selected-state choreography and icon/label emphasis

Priority: high

### Onboarding

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`
- `qa/emulator-artifacts/atlas-onboarding-polish-2026-03-15.png`

Strengths:

- splash has good tone and clarity
- local-first value proposition is strong
- onboarding structure is calm and readable

Gaps:

- the flow still reads more like a sequence of forms than a premium guided setup
- footer CTA area is functional but not emotionally elevating
- option selection could feel more alive and more clearly committed

Suggestions:

- make the onboarding arc feel more progressive and confidence-building
- improve transitions between steps
- increase distinction between selected and unselected options
- add more visible completion momentum

Priority: high

### Today

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `qa/emulator-artifacts/atlas-today-polish-2026-03-15.png`
- `qa/emulator-artifacts/atlas-today-companion-2026-03-15.png`

Strengths:

- strongest product clarity in the app
- next action is understandable
- hero card already points toward a premium direction

Gaps:

- hero module needs more tactile sophistication
- secondary actions compete in a fairly uniform way
- section transitions are clear but not yet elegant

Suggestions:

- make the next-due hero feel more alive, more dimensional, and more obviously primary
- create better contrast between immediate actions and management actions
- strengthen completion feedback after logging

Priority: very high

### Timeline

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `qa/emulator-artifacts/atlas-timeline-polish-2026-03-15.png`

Strengths:

- good conceptual framing
- immutable history message is clear
- segmentation keeps the model understandable

Gaps:

- filter card is serviceable but visually generic
- empty state feels competent rather than premium
- likely risk of cards feeling repetitive once the screen fills with real data

Suggestions:

- redesign the filter treatment to feel more integrated and less stock
- use stronger temporal grouping and entry hierarchy
- define a more premium event-card model before the screen gets denser

Priority: medium-high

### Library

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `qa/emulator-artifacts/atlas-library-polish-2026-03-15.png`

Strengths:

- clear sectioning
- obvious create entry point
- tools area is useful and easy to scan

Gaps:

- tools section and empty-state section feel too visually similar
- screen lacks a stronger sense of collection, browsing, and protocol ownership
- protocol cards likely need more personality once populated

Suggestions:

- create a more differentiated "tool launcher" visual treatment
- make protocol cards feel more valuable and less like generic settings rows
- improve the relationship between creation and existing-library management

Priority: medium-high

### Insights

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `qa/emulator-artifacts/atlas-insights-polish-2026-03-15.png`

Strengths:

- quick-action grid is strong and understandable
- primary tile pattern already feels more modern than many other surfaces
- app tone remains coherent

Gaps:

- tiles still need deeper tactile states and more nuanced hierarchy
- screen risks becoming a dashboard of equal blocks instead of guided insights
- the storytelling layer is not yet as premium as the interaction layer

Suggestions:

- make one action clearly primary based on context
- define a richer difference between "log something" and "learn something"
- use more expressive spacing and summary framing for real insight content

Priority: high

### Settings

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `qa/emulator-artifacts/atlas-settings-polish-2026-03-15.png`

Strengths:

- important settings are visible
- local-first and sync copy is clear
- reminders and privacy are not buried

Gaps:

- screen reads operational rather than premium
- too many primary-looking buttons inside single cards
- auth and sync UI is functional but visually fragmented
- trust-critical controls and housekeeping controls have similar visual weight

Suggestions:

- separate account status, auth, sync actions, and local reset actions more clearly
- treat sign-in and provider actions as a designed flow, not stacked controls
- create a stronger "trust system" grouping across privacy, sync, biometrics, and review/export entry points

Priority: very high

### Trust Vault

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasTrustVaultFeatures.swift`
- `qa/emulator-artifacts/atlas-trustvault-dark-contrast-fix-2026-03-16-2.png`

Strengths:

- this is a compelling product concept
- sections are logically organized
- privacy state is visible and concrete

Gaps:

- visually it still reads like a settings extension, not a flagship trust surface
- toggles and pickers feel generic for the importance of the subject matter
- the screen needs more ceremony and confidence

Suggestions:

- elevate this into a signature surface with stronger header, trust indicators, and action framing
- distinguish high-consequence controls from routine preferences
- make biometric and privacy mode changes feel more consequential and reassuring

Priority: very high

### Review Mode

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasReviewModeFeatures.swift`
- `qa/emulator-artifacts/atlas-review-dark-contrast-fix-2026-03-16-2.png`

Strengths:

- product value is clear
- bounded, read-only framing is strong
- the CTA is understandable

Gaps:

- configuration area is dense and visually procedural
- preset, scope, protocol selection, alias mode, expiration, and delivery all compete in the same card
- this reads more like an admin form than a premium workflow

Suggestions:

- split configuration into progressive steps or grouped tiers
- make presets feel like meaningful pathways, not just picker options
- improve summary preview before creation

Priority: high

### Import Center

Evidence:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasUniversalMigrationFeatures.swift`
- `qa/emulator-artifacts/atlas-import-input-contrast-2026-03-16.png`

Strengths:

- migration-first framing is strong
- preview-first language builds trust
- cards are readable

Gaps:

- import is visually calmer than many apps, but still not elegant enough for a high-stakes migration tool
- file path entry feels raw and mechanical
- restore points and preview states need stronger structure

Suggestions:

- make the source-input area feel more guided and less text-field-driven
- create a more premium staged flow: source, validation, preview, commit
- improve high-risk action framing for replace-local-data moments

Priority: high

## Cross-Screen Recommendations

### Shared System

- define explicit surface tiers instead of relying on one default card style
- redesign button families with stronger pressed, selected, disabled, and loading states
- standardize section density patterns
- upgrade form controls so toggles, pickers, segmented controls, and text entry feel like one family

### Interaction System

- introduce spring-based press feedback for primary interactive elements
- add continuity between selection changes and resulting content shifts
- improve sheet and modal presentation polish
- add success and confirmation micro-feedback after meaningful actions

### Trust Layer

- unify privacy mode, sync, biometrics, exports, review, and handoff into one stronger product language
- create reusable trust-state components for locked, local-only, signed-in, protected, and shared states

### Content Strategy

- reduce repeated explanatory body copy where structure can do the teaching
- make captions more intentional and less default
- reserve the longest copy for onboarding, empty states, and trust-critical explanation

## Recommended Work Sequence

### Phase 1: Shared Premium System

- surface tiers
- button families
- tab bar and shell refinement
- input and toggle polish
- motion and feedback rules

### Phase 2: First Impression And Daily Loop

- onboarding
- Today
- Settings

### Phase 3: Depth Surfaces

- Insights
- Library
- Timeline

### Phase 4: Trust And High-Stakes Workflows

- Trust Vault
- Review Mode
- Import Center

## Definition Of Done For The UI Pass

The pass is successful when Atlas feels:

- calmer
- more directed
- more tactile
- more trustworthy
- more distinct from generic SwiftUI card apps
- more premium without becoming flashy or decorative

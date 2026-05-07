# Atlas Weekly Review / Summary Center Brief

Date: 2026-04-12
Owner: Codex handoff

## Purpose

Build a dedicated Weekly Review / Summary Center for Atlas that turns the app's existing recap, mascot, rewards, insights, and review primitives into one premium, calm, action-driving weekly destination.

This should feel like a natural extension of Atlas, not a bolt-on report screen.

## Why This Is The Right Next Feature

Atlas already has:

- generated summary card UI
- bounded summary settings in Settings
- Insights recap surfaces
- Review Mode and trust-oriented export concepts
- mascot recap cards, archive, notifications, and widgets

What Atlas does not yet have is one cohesive destination where a user can understand:

- what happened this week
- what changed
- what mattered
- what to do next

## Product Goal

Create a Weekly Review destination that:

- summarizes the user's last 7 days in plain language
- combines protocol adherence, insights/context, rewards, mascot progress, and notable events
- stays grounded in visible source facts
- suggests clear next actions
- can later support save/share/export without feeling like a social product

## Key Repo Anchors

Use these before designing or implementing anything:

- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasSummaryFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasInsightsFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasReviewModeFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasMascotMediaFeatures.swift`
- `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasFeatures.swift`
- `atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasDomain.swift`
- `docs/ios-premium-ui-rubric.md`

## UX Requirements

The screen should answer these questions quickly:

1. How did this week go?
2. What changed or improved?
3. What looks off or worth attention?
4. What should I do next week?

Recommended structure:

1. Hero summary
   - one clear plain-language weekly read
   - generated at timestamp
   - visible trust/disclaimer treatment

2. Weekly highlights
   - rewards momentum
   - mascot progression or notable mascot moment
   - important streaks, completed goals, or milestone changes

3. What shifted
   - concise insights from context/nutrition/symptom or protocol-adjacent data
   - descriptive only, not causal claims

4. Recommended next actions
   - 2-4 concrete actions
   - examples: open protocol change studio, review missed dose pattern, adjust target, capture more context

5. Source facts
   - transparent supporting facts
   - visible relationship to the summary

## Design Standards

This screen must meet the premium Atlas bar:

- calm, serious, trustworthy
- stronger hierarchy than a normal list of cards
- obvious primary action or next step
- spacious hero treatment without wasted space
- clear difference between summary, highlights, supporting facts, and actions
- premium restraint, not dashboard clutter

Use `docs/ios-premium-ui-rubric.md` as the quality bar.

Do not ship:

- generic analytics dashboard UI
- noisy chart salad
- equal-weight cards stacked endlessly
- fluffy copy without source support
- decorative “AI recap” styling that weakens trust

## Technical Expectations

- Ground all work in the real repo at `/Users/donghokang/Developer/Atlas`
- Do not use any legacy or duplicate Atlas copies
- Reuse existing domain models and summary primitives where possible
- Prefer extending current routes/screens instead of inventing disconnected parallel architecture
- Keep recap logic bounded and source-backed
- Add automated tests for any new weekly review computation or persistence
- QA in the iOS simulator before pushing

## Suggested Scope

Phase 1 should include:

- dedicated Weekly Review screen or route
- weekly summary model derived from current app state
- premium SwiftUI screen implementation
- navigation entry point from existing app surfaces
- source facts section
- next-action section
- automated tests
- simulator QA

Phase 2 can later add:

- share/export variants
- saved review history
- richer widget tie-ins
- scheduled weekly review prompts

## Mascot Relationship

Do not make Weekly Review a mascot feature.

The mascot can appear as one highlight input or one emotional accent, but Weekly Review should remain an Atlas-wide product surface that integrates:

- protocol behavior
- insights/context
- rewards
- mascot
- next-step planning

## Definition Of Done

Only consider the feature complete when:

- the Weekly Review screen exists and is navigable in the live app
- the UI looks premium and clearly Atlas-native
- the summary is grounded in actual repo models/data
- the source facts are visible and understandable
- next actions are clear and useful
- automated tests pass
- simulator QA is completed
- the branch is committed and pushed intentionally

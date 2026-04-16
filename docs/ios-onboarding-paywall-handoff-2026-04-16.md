# Atlas iOS Onboarding + Paywall Handoff

Last updated: 2026-04-16

## Purpose

This document preserves the onboarding and paywall decisions from the April 2026 conversion pass so fresh Codex threads do not rediscover or undo the same product strategy.

Use it before changing:

- native iOS onboarding
- trial paywall placement
- premium feature preview screens
- mascot/rewards presence inside onboarding
- privacy/trust proof in onboarding
- protocol setup ordering

## Current Decision

Atlas should use a longer proof-led onboarding flow.

The goal is not to minimize step count. The goal is to make a user understand that Atlas is a premium local-first protocol operating system before the free-trial paywall appears.

The paywall should appear before the user builds a full protocol.

That means onboarding should:

- collect enough intent to personalize the story
- show differentiated premium surfaces before asking for trial commitment
- keep exact dosing/protocol setup after the paywall
- make the trial feel like access to a serious operating system, not a charge gate after a generic form

The free trial should lead into monthly or yearly auto-renewing subscriptions unless the user cancels through the normal App Store subscription controls.

## Positioning Rules

Atlas onboarding should sell the operating system, not a peptide marketplace.

Preserve these boundaries:

- no sourcing
- no provider marketplace
- no dosing advice
- no medical recommendations
- no diagnostic claims
- no generic AI coach positioning
- no social feed or leaderboard framing

The commercial pitch is:

- local-first protocol operations
- privacy-first trust controls
- clear daily execution
- inventory and supplies context
- protocol change history
- review-ready summaries
- migration from messy real life
- serious but optional continuity through mascot/rewards

## Current Flow Architecture

The intended high-level order is:

1. establish category fit and user intent
2. preview protocol operations without requiring exact setup
3. choose focus and privacy posture
4. show premium differentiators
5. show trust/privacy controls
6. show companion, readiness, system surfaces, and personalization
7. show the four final proof screens
8. explain the free-trial timeline
9. show the trial paywall
10. connect optional system permissions
11. enter the app

The current domain sequence is implemented in `AtlasOnboardingDraft.sequence()` and should be treated as intentional:

- splash
- track type
- journey status
- protocol preview
- focus
- privacy preset
- premium preview
- Trust Vault reveal
- companion preview
- readiness loop
- system surfaces
- personalized unlock
- Today command preview
- protocol change history
- review output preview
- migration preview
- trial timeline
- premium paywall
- connect apps
- plan ready

Do not move protocol creation ahead of the paywall unless the product strategy changes explicitly.

## Differentiators To Keep Showing

Onboarding should continue to showcase these Atlas-specific advantages:

- Today as the command surface for next due, recovery, inventory, and review
- Protocol Change Studio as a calm history of real-world changes
- review output as a bounded artifact the user can inspect before sharing
- Trust Vault, discreet/alias modes, and local-first privacy posture
- migration/import posture for users who are already mid-protocol
- inventory runway connected to protocol execution
- widgets, Shortcuts, and compact system surfaces as premium utility
- mascot/rewards as calm continuity, not childish gamification
- weekly review / progress evidence / summaries as proof that Atlas turns logs into useful records

## Four Final Proof Screens

The final April 2026 pass added four proof screens because they are among the strongest ways to distinguish Atlas before the paywall:

### Today Command Preview

Purpose: make the root value concrete.

This screen should communicate that Atlas does not simply log doses. It runs the day: next useful action, missed-step recovery, inventory runway, trust state, and review context.

### Protocol Change History

Purpose: prove Atlas understands real protocol messiness.

This screen should show that pauses, cadence changes, dose changes, missed actions, and restarts can be captured without shame or generic advice language.

### Review Output Preview

Purpose: make premium feel like an artifact.

This screen should preview bounded, local, inspect-before-sharing outputs: protocol snapshot, adherence context, inventory runway, and questions to review.

### Migration Preview

Purpose: remove perfect-start pressure.

This screen should tell already-started users they can begin with imperfect history and bring in current protocol, supplies, notes, and prior context after the trial screen.

## Paywall Direction

The paywall should be a free-trial paywall.

Keep:

- monthly and yearly options
- clear trial timeline
- privacy/local-first reassurance
- concise premium benefits tied to already-seen screens
- App Store subscription management language where appropriate

Avoid:

- guilt copy
- fake urgency
- medical transformation claims
- "AI doctor" framing
- endless benefit bullets that were not previewed in the flow
- making the user complete full protocol setup before seeing the trial

The paywall should feel like the natural unlock after the product proof, not a surprise wall.

## Mascot And Rewards Role

Mascot and rewards can improve onboarding if they stay aligned with Atlas maturity.

Keep them:

- optional
- calm
- premium
- tied to continuity and completion
- useful for emotional texture
- suppressed or quiet during trust-sensitive moments

Do not turn onboarding into:

- a pet game
- noisy streak pressure
- a childish quest map
- mascot-first branding

Use the standing mascot matrix:

- portrait art for in-app hero/detail/export
- sticker art for medium onboarding cards
- pixel art for widgets and compact live-state surfaces

## Copy Tone

Onboarding copy should be more expressive than dense root-tab copy, but still literal and serious.

Prefer:

- clear product nouns
- specific surfaces
- grounded outcomes
- trust-heavy language
- "review", "history", "privacy", "runway", "next action", "local"

Avoid:

- fake `Atlas is here to...` narration
- generic health-app motivation
- AI hype
- commerce/sourcing language
- shame or streak pressure
- claims that imply medical judgment

## QA Expectations

Before considering onboarding changes done:

- build the iOS app
- run the focused onboarding sequence tests
- simulator-smoke the full fresh onboarding path
- verify the trial paywall still appears before protocol creation
- verify Health/system connection can still be skipped
- verify completion routes into Today
- check Dynamic Type, especially larger accessibility sizes
- check that long copy does not overlap footer CTAs

The April 2026 pass was validated with:

- simulator build with signing disabled
- focused `AtlasPhaseOneTests` onboarding regressions
- fresh simulator onboarding smoke into Today after trial and Health skip
- content-size-category restoration after accessibility QA

## Brutally Honest Strategy Notes

The best competitor onboarding patterns worth adapting are not "short onboarding" by default. The stronger revenue pattern is usually:

- ask enough to make the experience feel personal
- reveal a meaningful result or preview before asking for payment
- make the paywall feel like the unlock to continue, not the first substantial screen
- sell outcomes through concrete product surfaces
- make cancellation/trial terms clear enough to reduce distrust

Atlas should not blindly copy aggressive wellness-app tactics.

Atlas has a stronger trust and differentiation story than a generic peptide tracker, but only if onboarding proves those differences visually before the paywall. If the screens drift back into form fields and generic benefit copy, the flow becomes long without earning its length.

Future competitor research should be re-run before making new market claims because onboarding screens, pricing, and trial tactics change frequently.

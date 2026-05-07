# Atlas Figma Feedback Checklist - 2026-04-18

Source: Atlas.1 Feedback Figma board.

## Explicitly Excluded

- [x] Do not change the avatar design, avatar species, or evolution naming direction.

## Implemented

- [x] Keep onboarding extended and additive; do not shorten the flow.
- [x] Make the opening splash act as a start/info moment with a transition and sign-in/local-first posture.
- [x] Add goal personalization during onboarding with current weight, goal weight, height, goal pace, and nutrition interest.
- [x] Add a health disclaimer acknowledgement before app handoff.
- [x] Keep Apple Health optional and make the primary path continue without opening a permission sheet.
- [x] Fix the Apple Health connection crash by using only HealthKit-safe authorization types.
- [x] Add in-app nutrition/calorie tracking language, with Apple Health import as optional context.
- [x] Keep discreet mode prominent and clarify why it exists.
- [x] Explain alias mode in plain English as using a different/safe name.
- [x] Clarify what the review summary is and what it includes before sharing.
- [x] Make option cards clearer with selected/tap-to-choose badges and stronger readable text.
- [x] Add optional companion naming while preserving the existing avatar design.
- [x] Add color choice for the companion signal while preserving the existing avatar design.
- [x] Add widget onboarding guidance with concrete Home Screen setup steps.
- [x] Surface streak/goals language in companion, widget, unlock, and plan-ready onboarding moments.
- [x] Enable Atlas rewards/streak settings after onboarding so the goal signal can appear in the app.
- [x] Add a stronger final welcome handoff: "Welcome to your Atlas."
- [x] Add animated transitions between onboarding steps so the flow feels less static.
- [x] Add a final welcome sign that fades away into the app-ready handoff.

## Verification Follow-Up

- [x] Smoke-check the splash and first selection step on simulator with large text enabled.
- [x] Run a full end-to-end onboarding screenshot pass across every step before the next TestFlight upload.
- [x] Verify the Apple Health connect path opens the iOS Health Access sheet instead of crashing.
- [x] Verify the companion nickname field accepts text input in the simulator.
- [x] Verify long onboarding steps reset scroll position before the next step appears.

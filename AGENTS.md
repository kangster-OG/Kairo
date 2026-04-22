# Atlas agent instructions

## Read first
Before making changes, read:
1. `README.md`
2. `docs/repo-truth-map.md`
3. `PLANS.md`
4. `atlas-ios/README.md`
5. `docs/native-release-readiness.md`
6. `docs/ios-architecture.md`
7. `docs/privacy-security-spec.md`
8. `docs/atlas-export-v1-spec.md`

Use the native iOS codebase plus those docs as the primary source of truth.

If you need to distinguish current native docs from historical migration/spec docs quickly, use `docs/repo-truth-map.md`.

## UI / UX read first
If the user asks about UI, UX, design, polish, motion, typography, layout, interaction quality, widgets, or SwiftUI presentation, also read:
1. `docs/ios-premium-ui-rubric.md`
2. `docs/ios-ui-audit-2026-04-10.md`
3. `docs/ios-ui-skill-stack.md`
4. `docs/ios-ux-execution-playbook-2026-04-15.md`
5. `docs/ios-redesign-context-2026-04-14.md`
6. `docs/ios-ui-mascot-rewards-changelog-2026-04-14.md`
7. `docs/ios-ui-polish-thread-handoff-2026-04-16.md`
8. `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` when the work touches mascot/rewards/motion/polish
9. `docs/mascot-concepts/atlas-mascot-asset-matrix.md` when the work touches mascot/rewards/media/widgets
10. `docs/ios-onboarding-paywall-handoff-2026-04-16.md` when the work touches onboarding, free trials, paywalls, or premium conversion
11. `docs/current-thread-handoff-2026-04-21.md` when the work touches current DREAM onboarding, latest TestFlight context, or the recent app UX upgrade
12. `docs/atlas-onboarding-ux-deep-dive-2026-04-21.md` and `docs/atlas-cal-ai-finch-dream-ux-2026-04-21.md` when the work touches competitor-informed onboarding or app UX
13. `docs/atlas-dream-onboarding-locked-storyboard-2026-04-21.md` and `docs/atlas-dream-onboarding-motion-spec-2026-04-21.md` when the work touches onboarding length, sequencing, transitions, or companion hatch moments

Treat those files as the standing Atlas UI design system brief for future Codex threads.

## Source-of-truth rule
If repo docs disagree, use this order:
1. native iOS code under `atlas-ios/`
2. `atlas-ios/README.md`
3. `docs/native-release-readiness.md`
4. `docs/ios-architecture.md`
5. `docs/privacy-security-spec.md`
6. `docs/atlas-export-v1-spec.md`
7. `PLANS.md`
8. legacy migration/history docs
9. legacy React Native docs

Do not treat older migration docs, the legacy Expo root, or empty placeholder docs as higher-authority than the current native product.

## Product summary
Atlas is a privacy-first protocol tracker for injectables, reminders, logging, inventory, calculators, sites, Trust Vault privacy controls, bounded sharing, review outputs, and deterministic pattern insights.

This app must not include:
- dosing advice
- medical recommendations
- diagnostic or treatment claims
- sourcing or marketplace flows

## Current product state
- Native iOS is the primary product path.
- React Native Atlas remains the product oracle, Android path, and migration/export source.
- Native parity and the currently planned second-order features are complete in code.
- Release readiness is conditional on physical-device QA and signed TestFlight smoke.

## Stack
### Primary iOS stack
- SwiftUI
- Swift Observation patterns
- GRDB + SQLite
- local app-group projection store
- UserNotifications
- LocalAuthentication
- WidgetKit/App Intents scaffolding

### Legacy/oracle stack
- React Native + Expo + TypeScript

## Freeze policy
- React Native Atlas is in feature freeze except for:
  - critical bug fixes
  - Atlas Export contract improvements required for native migration
  - Android-only stability fixes
- Native iOS is the primary product path.

## Engineering rules
- Preserve local-first behavior.
- Preserve guest-first behavior.
- Never mix generated future schedule occurrences with immutable historical log events.
- Never silently remove privacy, alias, discreet, Trust Vault, or audit behavior.
- Keep exports/imports deterministic and versioned.
- Keep sharing least-privilege, preview-first, and explicit.
- Keep Episode Intelligence deterministic and descriptive only.

## Scope rules
- Do not add medical advice, dose recommendations, or sourcing flows.
- Do not resume paused second-order features unless explicitly requested and approved.
- Do not treat the React Native app as the future primary iOS codebase.
- Do not overwrite or delete the React Native app when working on native iOS.

## Planning rule
For tasks spanning multiple feature areas or broad architecture/doc changes, update `PLANS.md` first unless the user explicitly asks to skip planning.

## UI execution rule
For UI-related work:
- explicitly use the Build iOS Apps UI skill medley documented in `docs/ios-ui-skill-stack.md` when the skills are available
- use the combined UX execution lens documented in `docs/ios-ux-execution-playbook-2026-04-15.md`
- keep Atlas aligned with the redesign context in `docs/ios-redesign-context-2026-04-14.md`
- preserve the product direction: calm, tactile, premium, local-first, trust-heavy, and non-gimmicky
- avoid generic health-app UI, flat interchangeable card stacks, and noisy gamification
- preserve the mascot asset deployment matrix:
  - portrait art for in-app hero/detail/export surfaces
  - sticker art for medium cards
  - pixel art for widgets and compact live-state surfaces
- preserve the ambient mascot handoff in `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`: anchored companion behavior, not free-roaming or always-on clutter
- preserve the current 180-state DREAM onboarding direction unless the user explicitly asks to shorten it
- keep onboarding copy concise and human; avoid AI-ish strategy language such as `privacy posture`, `generated artifact`, `operating system fantasy`, or overexplained helper narration
- default to simulator QA for UI changes, then note any remaining manual/device checks explicitly

## Done when
A task is only done when:
- the relevant code or docs are updated
- build/test expectations are checked or explicitly documented
- changed files are summarized
- risks/blockers are called out clearly

# Atlas agent instructions

## Read first
Before making changes, read:
1. `docs/prd.md`
2. `docs/build-manifest.json`
3. `docs/ui/onboarding-figma-notes.md`
4. `docs/ui/onboarding-ui-manifest.json`

Treat those files as the source of truth unless explicitly overridden by the user.

## Product summary
Atlas is a privacy-first protocol tracker for injectables, logging, reminders, inventory, calculators, and wellness context.
This app must not include:
- dosing advice
- medical recommendations
- sourcing or marketplace flows
- diagnostic or treatment claims

## Stack
- React Native + Expo + TypeScript
- Expo Router
- Zustand
- TanStack Query
- React Hook Form
- Zod
- Supabase
- AsyncStorage for local onboarding persistence
- SecureStore for sensitive local values later

## Engineering rules
- Build in thin vertical slices.
- Do not scaffold the whole PRD at once.
- Keep schedule/protocol logic isolated in a dedicated domain module.
- Use explicit TypeScript types.
- Use Zod for form and domain validation.
- Keep components reusable and small.
- Never silently remove privacy/discreet mode features.
- Preserve future ability to support guest mode and cloud accounts.
- Avoid large dependency additions unless justified.

## Planning rule
For any task expected to touch more than one feature area or more than 8 files, update `PLANS.md` first and wait for approval before broad implementation.

## Persistence rule
Use AsyncStorage only for lightweight onboarding/preferences state.
Use the structured local data layer for protocols, logs, reminders, inventory, metrics, and timeline data.

## Domain rule
Never mix generated future schedule occurrences with immutable historical log events.

## Second-order feature rules
- Update `PLANS.md` before any task that spans multiple feature areas or more than 8 files.
- Keep local-first behavior intact. No feature may require cloud access except optional cloud-backed review links.
- Never mix generated future schedule occurrences with immutable historical log events.
- Sharing defaults to least privilege, read-only, and explicit expiration when cloud-backed.
- All exports/imports must honor alias mode and discreet labels.
- All importers must support dry-run preview and diff before commit.
- Episode Intelligence must be deterministic/rules-based first, not LLM-generated.
- Every milestone ends with typecheck, tests, and a review pass.
- Do not introduce medical advice, dose recommendations, or sourcing flows.

## Native migration freeze policy
- React Native Atlas is now in feature freeze except for:
  - critical bug fixes
  - Atlas Export contract improvements required for native migration
  - Android-only stability fixes
- New second-order feature work is paused until native iOS reaches parity through Trust Vault + Selective Sharing.
- Native iOS is now the primary product path.

## UX rules for onboarding
- One primary question per screen.
- Clean white background.
- Soft blue primary accent.
- Rounded pill selection buttons.
- Thin progress indicator at top.
- Large bottom CTA button.
- Minimize cognitive load.
- Use progressive disclosure.
- Ask privacy/discreet mode before health app connection.
- Remove the app rating prompt from first-run onboarding.
- Keep health app connection late in the flow.
- Allow GLP, peptide, both, or later.
- Make body metrics skippable.

## Code organization
Prefer this structure:
- `app/` for routes only
- `src/components/`
- `src/features/onboarding/`
- `src/features/auth/`
- `src/features/today/`
- `src/lib/`
- `src/store/`
- `src/theme/`
- `src/types/`

## Done when
A task is only done when:
- code compiles
- lint/typecheck pass
- relevant tests pass or are added as TODO with a clear reason
- changed files are summarized
- follow-up risks are listed

## Testing rules
- Put test files outside `app/`
- Prefer React Native Testing Library
- Cover onboarding branching and persistence early
- Do not skip tests for core state logic

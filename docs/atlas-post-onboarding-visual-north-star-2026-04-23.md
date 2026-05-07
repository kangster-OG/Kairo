# Atlas Post-Onboarding Visual North Star - 2026-04-23

This document captures the mockup direction from the April 22-23 fidelity rebuild so fresh Codex threads do not drift back into the older Atlas visual language. Treat this as the post-onboarding visual north star for the whole product, not only the screens that were shown in the mockup.

## Product Definition

Atlas is now being pushed as the ultimate peptide protocol tracking app: simple enough to log a shot fast, deep enough to manage active protocols, vial runway, site rotation, side effects, nutrition, hydration, workouts, health integrations, widgets, and visible companion progress.

Privacy/trust still matters, but it should not be the headline differentiator. It should feel like confidence built into the product. The primary sell is:

> Build your peptide protocol.

Atlas is not a marketplace, sourcing app, social app, medical advice app, dosing advice app, or diagnostic app.

## Mockup Direction

The approved mockup direction is a three-screen iPhone set. The original reference was provided in-thread as a combined Today / Log Shot / Companion image; the repo now preserves the direction through this spec plus the screenshot evidence listed below.

1. Today
   - Top bar: `Atlas`, streak, points.
   - Mascot-forward hero: companion on the left, greeting, level badge, XP progress.
   - Next Shot card: medication name, dose, route, due time, mini medication-level chart.
   - Large green `Log Shot` CTA.
   - Protein, hydration, workout rings.
   - Inventory runway row.
   - Compact bottom tab shelf.

2. Log Shot
   - Centered nav title `Log Shot`, back chevron, check circle.
   - Reward banner with small mascot and `Great consistency` / XP.
   - Medication header.
   - Body site map and site selector.
   - Pain slider, side-effect chips, notes.
   - Vial remaining preview.
   - Large green `Mark as Taken` CTA.
   - The flow should feel like one clean ritual: shot taken -> site -> pain/effects -> vial decrement -> support prompts -> mascot reward.

3. Companion
   - Level ring, large mascot on a small stage, locked next form.
   - Daily quests: shot, protein, hydration/workout, progress photo.
   - Badges and collectibles.
   - Weekly Protocol Mastery dark card with a gem/badge.
   - Companion progress should feel Finch/Pokemon-inspired without becoming noisy.

## Whole-Product Fidelity Rule

Every post-onboarding screen should look like it belongs to the same app as the mockup. Do not limit the style to Today, Log Shot, and Companion. Protocol Detail, Protocols, Progress, Inventory, Supplies, Food, Workout, Health sync, settings, review states, widgets, compact surfaces, empty states, and deep editors should inherit the same density, typography, color, radius, icon treatment, and CTA hierarchy.

The standard for future work is direct visual comparison:

- Does this screen use the same warm off-white canvas and compact card rhythm?
- Are fonts SF/system-like, not rounded/custom novelty typography?
- Are cards and controls mostly 8pt radius, except the bottom tab pill shell?
- Is the main action visually obvious without making the screen noisy?
- Is the mascot present when it helps progress feel tangible?
- Is the feature depth progressively disclosed instead of dumped on the user?
- Did any old privacy-first, large-radius, uppercase, glassy, or generic health-app styling return?

## Visual Tokens

- Background: warm off-white/ivory, not blue-gray and not clinical white.
- Primary: deep Atlas green, currently aligned around `AtlasPalette.primary` (`#1F6F5B`-ish).
- Reward: restrained amber/gold for XP and collectibles.
- Blue should be functional and rare, mostly hydration.
- Typography: SF/system default, compact, no `.rounded` system font style.
- Letter spacing: 0.
- Avoid forced uppercase except where the source text intentionally needs it.
- Cards and controls: mostly 8pt radius.
- Bottom tab: preserve the mockup-like pill shelf, with a slightly rounder outer shell and selected item.
- Shadows: low, soft, tactile; avoid heavy floating glass.
- UI density: compact. The app should show useful protocol information above the fold.
- Copy: short, human, utility-first. Avoid generic health-app filler and AI-ish helper narration.

## Core App Direction

Mascots are not decoration. They are a visual representation of protocol consistency, support habits, leveling, and evolution.

Keep both mascot lines in the app:

- Aurielle
- Aetherion

Do not replace the companion designs unless explicitly asked. The hatch/capsule/signal-core idea is a presentation layer around the existing companions.

The app should feel simpler than it is:

- Primary action always obvious.
- Deep features progressively disclosed.
- Tabs should not become endless feature stacks.
- No shame/fear tactics.
- No noisy gamification.
- No medical/dosing advice.

## Post-Onboarding Fidelity Work Already Done

See `docs/atlas-true-fidelity-pass-handoff-2026-04-22.md`.

Important implementation state from that pass:

- `AtlasTypographyCandidate.current` defaults to `.system`.
- Shared text roles were tightened.
- Forced uppercase was removed from shared text roles and feature presentation code.
- Large local card/control radii were normalized toward the compact 8pt system.
- `AtlasMetricStrip` now wraps more than three metrics instead of clipping horizontally.
- Today, Log, Protocols, Progress, Companion, and Protocol Detail were moved closer to the mockup language.
- Widgets received token cleanup and a widget warning fix.
- Focused tests passed after the pass.

## Screenshot References

Use these as the current in-repo visual evidence:

- `output/true-fidelity-pass-2026-04-22/13-today-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/14-log-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/15-companion-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/16-protocols-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/17-progress-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/18-protocol-detail-final.png`

Also compare against earlier transition screenshots in:

- `output/mockup-fidelity-2026-04-22/`
- `output/six-step-final-2026-04-22/`
- `output/visual-audit-2026-04-22/`

## Still Worth Pushing

- Bespoke badge, collectible, and mastery art can be more premium than SF Symbols.
- Deep editors and modals still need screenshot-by-screenshot inspection.
- Widgets and Watch-adjacent surfaces should be re-screened after any token edits.
- Nutrition/workout/health flows should keep becoming more capable while staying simple.
- Onboarding is intentionally not part of this post-onboarding fidelity pass; it will be rebuilt separately.
- Future threads should add new screenshot evidence here or in a dated handoff whenever they close a fidelity gap.

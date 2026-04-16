# Atlas UI / Mascot / Rewards Changelog

Last updated: 2026-04-16

## Purpose

This file is the durable changelog for the major Atlas iOS redesign waves that were executed across UI, mascot, rewards, widgets, dark mode, and simulator QA.

Fresh Codex threads should use this file as the high-level "what changed and why" companion to:

- `docs/ios-ui-skill-stack.md`
- `docs/ios-redesign-context-2026-04-14.md`
- `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`
- `docs/mascot-concepts/atlas-mascot-asset-matrix.md`

## Product direction locked in

The redesign direction that should be preserved going forward is:

- calm, tactile, premium, and trust-heavy
- local-first and privacy-first
- informative and intuitive without over-explaining
- non-gimmicky rewards and mascot momentum
- tactile premium depth instead of chunky skeuomorphism

Do not regress Atlas toward:

- generic flat health-app UI
- repetitive stacked frosted cards with weak hierarchy
- noisy or childish gamification
- portrait mascot art in widgets
- pixel mascot art on flagship in-app hero/detail/export surfaces

## Permanent mascot asset rules

These rules are now part of the product:

- portrait art = in-app hero/detail/export surfaces
- sticker art = medium cards and medium mascot/reward surfaces
- pixel art = widgets and compact live-state surfaces

If mascot UI work is requested, also read `docs/mascot-concepts/atlas-mascot-asset-matrix.md`.

## Major implementation waves

### 1. Premium shell + design system pass

Atlas was moved onto a more intentional premium iPhone design language with:

- semantic typography
- stronger visual hierarchy
- tactile buttons/cards/controls
- reusable premium primitives
- better command-surface structure
- calmer but more dimensional surfaces

This work established the standing rule that Atlas should feel tactile and premium without becoming visually heavy or ornamental.

### 2. Flagship screen redesign pass

The redesign then propagated through the major product surfaces:

- Today
- Protocol flows
- Inventory
- Settings
- Trust Vault
- Weekly Review
- Insights and supporting surfaces

The main shift was from utility-heavy forms/lists toward clearer command surfaces, better scanability, improved premium hierarchy, and more distinct screen personalities.

### 3. Dark mode refinement

Dark mode was made intentional rather than a light-mode afterthought:

- shared palette and surface tokens were refined
- shell chrome and controls were updated for dark readability
- light-only assumptions were removed from the app entry path

Future UI work should assume both light and dark mode are first-class.

### 4. Mascot artwork deployment correction

Atlas originally overused pixel-style mascot assets on large in-app surfaces.

That was corrected by remapping art families:

- portrait/sticker-derived stage art for large and medium in-app surfaces
- pixel art retained for widgets and compact live-state contexts

This fixed the core mismatch that made mascot detail and recap surfaces feel visually wrong.

### 5. Mascot detail + recap + reward polish

The mascot layer was then upgraded into a stronger flagship experience:

- mascot detail hero redesign
- better momentum and progression surfaces
- improved recap/export presentation
- better integration with rewards and weekly closeout flows

The mascot is intended to feel like a calm premium companion, not a noisy game character.

### 6. Sticker asset pass

A dedicated medium-surface sticker family was added for all six mascot stages.

This completed the medium-surface layer so onboarding, reward cards, compact mascot cards, and similar surfaces no longer had to borrow portrait framing or pixel assets.

### 7. Widget gallery, rendering, and refresh fixes

The widget system was cleaned up end to end:

- widget bundle/discovery fixes
- gallery naming and preview improvements
- mascot widget content polish
- placeholder rendering fix
- live refresh/data freshness fix

Result: the mascot widget should now be discoverable, render readable content, and use the correct asset family.

### 8. Momentum, haptics, and milestone reveal pass

The rewards/gamification layer was upgraded from mostly static surfaces to a more responsive premium momentum system with:

- stronger milestone reveals
- next-unlock anticipation
- animated progress/count-up treatments
- haptics for unlocks, level-ups, weekly closeout, and mascot moments
- more theatrical recap handoff after week closeout

This is meant to make progress feel earned without turning Atlas into a game.

### 9. Widget + App Intents + system surface cleanup

The mascot/rewards layer was exposed more cleanly to system surfaces:

- improved widget rendering and families
- better lock-screen accessory behavior
- stronger App Intents routing for mascot, rewards, and weekly review entry points

The intent is that Atlas system surfaces feel connected to the same product language as the main app.

### 10. Collectible moment depth + continuity pass

The mascot journal/reward narrative was deepened with:

- more collectible moment types
- recap-to-journal continuity
- stage-specific personality in journal and payoff copy

Key collectible moment additions included:

- streak rescue
- near evolution
- archive milestone
- focus carry-forward
- quiet consistency

This is the main phase that made the mascot system feel more emotionally authored and less generic.

### 11. Ambient mascot productionization pass

The mascot was extended into a restrained ambient companion system:

- calm perches on selected cards and the bottom shelf
- settle, idle, rest, courtesy, peek, noticed-content, milestone, and welcome-back reactions
- Today -> Library and Today -> Insights follow-then-perch transitions
- user-controlled ambient presence: Off, Subtle, More alive
- shared serious-mode suppression for sheets, exports, dense entry, and trust-sensitive flows
- Reduce Motion and Dynamic Type QA expectations for mascot surfaces

The locked product rule is that this remains anchored and event-based. Do not turn it into free roaming, constant motion, or a mascot on every surface.

## QA pattern that should continue

For UI, mascot, rewards, or widget work, the standing expectation is:

1. implement the change
2. run simulator build/run QA
3. visually inspect the affected flows
4. note any remaining manual/device-only checks explicitly

Preferred QA emphasis:

- Home Screen and Lock Screen widget behavior
- dark mode
- dense populated states
- mascot/reward continuity
- recap export flows
- navigation/deep-link routing for system surfaces

## Known follow-through expectations

When future threads touch this area, preserve:

- the tactile premium design direction
- the non-punitive mascot/rewards philosophy
- the portrait/sticker/pixel mascot asset split
- the expectation that widgets and mascot surfaces get real simulator QA, not code-only review

## Read this with

- `docs/ios-ui-skill-stack.md` for which skills and references to use
- `docs/ios-redesign-context-2026-04-14.md` for product/design intent
- `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` for ambient mascot placement, policy, suppression, and QA rules
- `docs/mascot-concepts/atlas-mascot-asset-matrix.md` for mascot asset deployment rules
- `docs/fresh-codex-thread-prompt.md` for a ready-to-paste fresh-thread starter

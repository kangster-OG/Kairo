# Atlas iOS Ambient Mascot System Handoff

Last updated: 2026-04-16

## Purpose

This doc captures the production-oriented ambient mascot system built after the mascot/rewards redesign.

Use it when future work touches mascot, rewards, motion, polish, Today, Insights, Weekly Review, Progress Evidence, Quick Capture, the tab shelf, widgets, or companion behavior.

## Product stance

The mascot is an anchored ambient companion, not a free-roaming pet.

It should feel:

- aware
- polite
- optional
- premium
- calm enough for trust-heavy protocol work

It should never compete with protocol execution, privacy controls, dense entry, export decisions, or serious review flows.

## Current homes

These are the current ambient mascot territories. Treat this list as close to the upper bound.

- Today command deck: sticker-style card-corner perch.
- Insights review lanes: sticker-style card-corner perch, hidden during Today -> Insights handoff.
- Weekly Review payoff: sticker-style card-corner perch.
- Progress Evidence summary: sticker-style card-corner perch.
- Rewards hero: sticker-style card-corner perch.
- Mascot detail / recap studio: sticker-style card-corner perch.
- Quick Capture summary card: calm card-corner anchor only when it does not compete with active entry.
- Bottom tab shelf: pixel-style shelf perch only on Timeline, Library, and Settings.

Do not add more permanent mascot homes unless the user explicitly asks and the destination surface is calm.

## Behavior set

The current system favors event-based reactions over constant autonomous motion.

- settle-in hop on tab changes or perch changes
- Today -> Library and Today -> Insights follow-then-perch handoff
- idle glance/tilt after a few quiet seconds
- quiet rest pose after idle
- wake-up blink after returning to a previously visible perch
- courtesy tuck/lean when nearby controls are used
- noticed-content / inspect lean for newly revealed recap, reward, export, or evidence content
- proud hold after review/export completion
- happy bounce for milestone-adjacent states
- peek for empty, caught-up, unlock-near, or first-protocol style states
- welcome-back acknowledgement only when points, badges, streaks, mascot moments, archived recaps, or evidence changed while away
- context-specific shelf/anchor poses

## Policy

The system should stay controlled by shared policy, not one-off screen logic.

- User control: Ambient mascot presence = Off, Subtle, More alive.
- Subtle is the default production mode.
- More alive can use richer reactions but should still stay bounded.
- Off suppresses ambient perches and reactions.
- Shared policy owns idle delays, rest delays, notable cooldowns, motion windows, and notable-moment budgets.
- Reduce Motion must suppress autonomous animation and simplify reactions.

Shared suppression levels:

- `none`: normal ambient behavior.
- `nearbyChrome`: reduce autonomous motion and tuck/lean away around nearby controls.
- `serious`: hide/suppress during sheets, exports, dense entry, and trust-sensitive flows.

## Keep-out zones

Do not add mascot homes to:

- Trust Vault
- auth
- import/export confirmations
- Review Mode
- privacy/security settings beyond the quiet shelf presence
- dense editors/forms
- primary destructive actions
- any trust-critical explanation

The mascot can acknowledge progress around serious work, but it should not perform inside the serious decision itself.

## Expansion rule

The current territory is enough for production personality without clutter.

When adding future mascot behavior:

- prefer event-based reactions over new permanent perches
- use existing ambient policy and suppression helpers
- add a new reaction kind only when the event is meaningfully different from the existing set
- do not stack multiple visible mascot moments in the same flow
- make both Aetherion and Aurielle work through the same behavior path unless there is a deliberate product reason not to

## QA baseline

Before calling mascot work complete:

- build and run the app on simulator
- verify Today and at least one shelf tab
- verify dark mode
- verify Reduce Motion
- verify accessibility-large Dynamic Type on the tab shelf
- verify rewards-off state
- verify at least one dense sheet/export suppression path
- verify Aetherion and Aurielle if asset or behavior changes could affect mascot rendering
- verify seeded-history and fresh/new-user state when the shell or root surfaces change

## Last known QA

The productionization pass was checked on:

- seeded iPhone 17 simulator
- fresh iPhone 17 Pro Max simulator
- dark mode
- accessibility-large text
- Reduce Motion
- rewards-off state
- Aetherion and Aurielle live perches

Known caveat: not every reaction was manually triggered on every Aurielle surface. The behavior layer and asset mappings are shared/parallel, but do a short soak before broad public release.

## Useful code seams

- `AtlasAmbientMascotPerch`
- `AtlasAmbientMascotPolicy`
- `AtlasAmbientMascotSuppression`
- `AtlasAmbientMascotPerchContext`
- `AtlasAmbientMascotReactionKind`
- `atlasAmbientMascotSelection(...)`
- `atlasAmbientMascotStage(...)`
- `atlasAmbientMascotMilestoneNearby(...)`
- `AtlasAmbientMascotFlightOverlay`
- `model.triggerAmbientMascotReaction(...)`
- `AtlasAmbientMascotPresence`

Read this with:

- `docs/ios-ui-skill-stack.md`
- `docs/ios-ux-execution-playbook-2026-04-15.md`
- `docs/ios-ui-mascot-rewards-changelog-2026-04-14.md`
- current native mascot assets and active Kairo companion/widget code; do not use archived mascot concept docs

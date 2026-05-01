# Atlas iOS Redesign Context

Last updated: 2026-04-14

## Purpose

This document is the standing redesign brief for fresh Codex threads working on Atlas UI.

It captures the key product, visual, interaction, mascot, and QA decisions that were established during the large iOS redesign and mascot/gamification polish work.

## North star

Atlas should feel like a:

- calm
- tactile
- premium
- local-first
- trust-heavy
- momentum-oriented

iPhone product for protocol management.

It should feel:

- serious enough for sensitive health/protocol data
- clear enough to use one-handed
- informative without becoming dense or lecture-like
- rewarding without becoming juvenile

## Product read

Atlas is not just a dose logger.

The current native product combines:

- Today command surfaces
- immutable Timeline history
- protocol composition and change workflows
- inventory and supply operations
- Trust Vault and bounded sharing
- review and export outputs
- progress evidence
- deterministic insights
- Weekly Review
- mascot/rewards momentum surfaces
- widgets and App Intents entry points

## UI direction decisions

### Keep

- calm premium shell
- privacy/trust-forward tone
- dimensional but restrained surfaces
- custom iPhone-native control feel
- local-first seriousness

### Avoid

- generic health-app white-card UI
- equal-weight stacks of frosted rectangles
- decorative premium without hierarchy
- noisy or juvenile gamification
- chunky, heavy, retro skeuomorphism

## Tactile guidance

Approved:

- non-flat tactile mobile UI
- dimensional high-contrast buttons
- restrained raised cards
- light beveling on pressable controls

Rejected as default system language:

- chunky embossed surfaces
- thick bordered retro skeuomorphic UI everywhere
- full dark skeuomorphic product direction

## Design-system priorities

The redesign established these permanent priorities:

1. semantic typography over ad hoc font usage
2. differentiated surface families over one card style everywhere
3. command-surface clarity at the top of major screens
4. stronger glanceability before explanatory copy
5. motion and haptics used selectively for payoff and momentum
6. density that changes by task rather than staying uniform

## Screen philosophy

### Today

Today should be the operational center:

- one dominant next action
- clear recovery guidance
- visible momentum
- fast access to weekly review and capture flows

### Weekly Review

Weekly Review should feel like closure and carry-forward, not admin:

- one clear end-of-week move
- visible payoff
- optional carry-forward
- recap/export readiness
- mascot continuity when rewards are enabled

### Mascot detail

Mascot detail is now a flagship surface, not a side module:

- portrait hero art
- stage-specific language
- momentum summary
- collectible journal
- recap recommendation and archive continuity

### Rewards

Rewards should show:

- the clearest next unlock
- honest momentum
- mascot progression
- local-first reward framing

## Mascot and gamification decisions

### System direction

The mascot/rewards layer should remain:

- optional
- calm
- local-first
- non-punitive
- collectible
- emotionally authored

Do not turn it into:

- pet care
- a coin economy
- fake scarcity
- social pressure
- loud confetti UX

### Asset matrix

The current deployment rule is:

- portrait art for in-app hero/detail/export surfaces
- sticker art for medium in-app cards
- pixel art for widgets and compact live-state surfaces

Use current native mascot assets and active Kairo companion/widget code as the authoritative reference. Do not use archived mascot concept docs.

### Moment depth

The mascot moment system now includes:

- interaction
- evolution
- badge
- goal
- streak
- streak rescue
- near evolution
- archive milestone
- focus carry forward
- quiet consistency
- shortcut
- level up
- weekly closeout
- recap export

Design intent:

- moments should feel collectible
- recap exports should connect back to journal history
- stage personality should change the emotional tone of copy

## Dark mode

Dark mode is a first-class Atlas presentation, not a light-mode afterthought.

Any new UI pass should check:

- shell chrome
- premium cards
- mascot detail
- rewards/payoff surfaces
- widget-adjacent views

## QA expectations

For UI work, default to:

1. simulator build/run
2. live route verification
3. accessibility hierarchy inspection
4. screenshot review
5. dark-mode verification
6. targeted test pass when behavior logic changed

Higher-value follow-up QA:

- dense-state seeding
- Dynamic Type checks
- VoiceOver label/order review
- widget verification
- deep-link/system-entry verification

## Best references

Fresh UI threads should read these together:

- `docs/ios-premium-ui-rubric.md`
- `docs/ios-ui-audit-2026-04-10.md`
- `docs/ios-ui-skill-stack.md`
- current native mascot assets and active Kairo companion/widget code; do not use archived mascot concept docs

## What to preserve

Preserve these truths unless the user explicitly changes direction:

- Atlas is building a best-in-class iPhone product, not a generic health tracker
- trust, clarity, and local-first seriousness are core differentiators
- the redesign already moved Atlas toward tactile premium rather than flat utility UI
- the mascot system should deepen emotional continuity, not become noisy gamification

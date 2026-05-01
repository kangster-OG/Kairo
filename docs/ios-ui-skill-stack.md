# Atlas iOS UI Skill Stack

Last updated: 2026-04-16

## Purpose

This file captures the UI skill stack and design references that proved most useful during the Atlas redesign work.

Future Codex threads should load this file whenever the user asks for UI, UX, design, interaction, motion, typography, layout, widget polish, or SwiftUI presentation work.

Also load `docs/ios-ux-execution-playbook-2026-04-15.md` for the combined navigation / scroll / interaction / accessibility lens that guided the redesign and UX pass.

This skill stack is now permanent repo context through `AGENTS.md`. Treat it as the default workflow for Atlas UI work, not as optional background reading.

## Default Atlas UI stack

Use these skills first when they are available in the environment. If the current Codex environment exposes different names, use the closest equivalent SwiftUI composition, SwiftUI refactor, simulator QA, and performance-audit workflows.

The right default is a medley, not one skill:

1. structure the screen with `swiftui-ui-patterns`
2. simplify the view tree with `swiftui-view-refactor`
3. verify the real app in simulator with `ios-debugger-agent`
4. add `swiftui-performance-audit` when density or render quality is part of the UX problem

For UI tasks, future Codex threads should say which of these they are using and why. Skip one only when the task is clearly too small or the skill is unavailable.

### Core implementation skills

1. `build-ios-apps:swiftui-ui-patterns`
   - default for screen composition, navigation structure, section layout, custom controls, and SwiftUI-native hierarchy
2. `build-ios-apps:swiftui-view-refactor`
   - default for splitting giant screens, stabilizing view trees, and reducing accidental complexity in SwiftUI files
3. `build-ios-apps:ios-debugger-agent`
   - default for simulator-driven UI QA, live route verification, screenshots, and debugging layout/runtime issues

### Supporting implementation skills

4. `build-ios-apps:swiftui-performance-audit`
   - use for jank, heavy cards, scroll density, or over-rendering concerns
5. `build-ios-apps:swiftui-liquid-glass`
   - use sparingly for shell chrome or selective premium material treatment, not as a blanket styling pass
6. `build-ios-apps:ios-app-intents`
   - use when UI work extends into widgets, Shortcuts, Siri, controls, or intent-driven system entry points

## External reference stack

These are not repo-native executable skills, but they were valuable references during the redesign and are worth checking when available:

1. `twostraws/SwiftUI-Agent-Skill`
   - strongest broad SwiftUI second-opinion reference for API usage, design, performance, and common model mistakes
2. `avdlee/swiftui-agent-skill`
   - strong checklist-heavy correctness reference for modern SwiftUI review
3. `PasqualeVittoriosi/swift-accessibility-skill`
   - preferred accessibility reference for premium-quality Dynamic Type, VoiceOver, and App Store accessibility thinking
4. `dpearson2699/swift-ios-skills`
   - useful because it splits navigation, gestures, accessibility, performance, and SwiftUI patterns into focused units
5. `yusufkaran/swiftui-autotest-skill`
   - useful when visual QA, route verification, truncation checks, and interaction coverage matter more than code generation
6. `Iron-Ham/XcodePreviews`
   - useful preview-oriented workflow reference for visual SwiftUI iteration
7. `conorluddy/ios-simulator-skill`
   - useful simulator-interaction reference, especially for UI verification and accessibility-style flows
8. `Dimillian/Skills`
   - useful confirmation that the SwiftUI skill family above is a strong baseline

## UX evaluation stack

When the user is really talking about app feel rather than raw component styling, use this stack:

1. root-screen hierarchy and stopping points
2. top-level tab discipline
3. progressive disclosure
4. one-handed ergonomics
5. accessibility and motion settings
6. simulator-driven flow QA

See `docs/ios-ux-execution-playbook-2026-04-15.md` for the detailed rules.

## Atlas design principles

When using the stack above, preserve these Atlas-specific principles:

1. clarity over ornament
2. trust over novelty
3. calm over intensity
4. premium restraint over decorative premium
5. tactile depth over flat utility UI
6. native iPhone feel over custom-for-custom's-sake

## Visual direction

Atlas should feel like:

- a calm, tactile, premium momentum system
- serious enough for health/protocol data
- informative and intuitive without over-explaining itself
- emotionally rewarding without becoming childish

Atlas should not drift into:

- generic white-card health tracker UI
- over-explained admin screens
- loud or arcade-style gamification
- chunky retro skeuomorphism
- decorative gradients without hierarchy

## Tactile guidance

Approved direction:

- non-flat tactile mobile UI
- higher-contrast dimensional buttons
- restrained raised cards
- light beveling on pressable controls

Avoid:

- chunky embossed surfaces
- thick, heavy, retro skeuomorphic UI everywhere
- dark skeuomorphic ornament as the default product language

## Mascot and gamification design rules

The mascot/rewards system should remain:

- optional
- calm
- local-first
- non-punitive
- collectible and momentum-oriented

It should not become:

- a pet-care obligation loop
- a coin/gem economy
- fake scarcity
- manipulative streak pressure

Asset deployment rules:

- portrait art for in-app hero/detail/export surfaces
- sticker art for medium cards and compact in-app companion surfaces
- pixel art for widgets and tiny live-state surfaces

Use current native mascot assets and active Kairo companion/widget code as the authoritative mascot reference. Do not use archived mascot concept docs.

When the work touches ambient mascot motion or placement, also read `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`. The current direction is anchored, event-based companion behavior, not free roaming or always-on animation.

## QA expectations for UI work

Default QA flow:

1. build and run Atlas on the simulator
2. inspect the live screen with simulator UI snapshots/screenshots
3. verify light mode and dark mode for changed surfaces
4. verify at least one system-entry route when relevant
5. run targeted tests if the change touches logic, persistence, or widget/intents behavior

When possible, also do:

- dense-state verification
- accessibility hierarchy review
- widget verification
- deep-link verification for changed routes
- end-of-screen verification for root tabs
- tab re-entry / scroll-to-top verification when shell behavior is touched

## Use this with

- `docs/ios-premium-ui-rubric.md`
- `docs/ios-ui-audit-2026-04-10.md`
- `docs/ios-ux-execution-playbook-2026-04-15.md`
- `docs/ios-redesign-context-2026-04-14.md`
- `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`
- current native mascot assets and active Kairo companion/widget code; do not use archived mascot concept docs

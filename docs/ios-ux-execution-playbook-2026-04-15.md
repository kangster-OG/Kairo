# Atlas iOS UX Execution Playbook

Last updated: 2026-04-15

## Purpose

This file captures the execution lens that proved most useful during the large Atlas UX / interaction pass.

Use it in future Codex threads when the task is not just visual styling, but how Atlas actually feels to use:

- navigation clarity
- root-tab architecture
- scrolling fatigue
- one-handed interaction
- hit targets
- shell polish
- interaction/accessibility quality
- “this feels feature-rich but not yet authored” type problems

## Read this with

- `docs/ios-ui-skill-stack.md`
- `docs/ios-premium-ui-rubric.md`
- `docs/ios-ui-audit-2026-04-10.md`
- `docs/ios-redesign-context-2026-04-14.md`

## Core lens

Do not evaluate Atlas screens only as component styling.

Use this combined lens:

1. navigation clarity
2. scroll depth and stopping points
3. top-level tab discipline
4. progressive disclosure
5. one-handed reach and tap ergonomics
6. accessibility settings and motion behavior
7. simulator-driven QA of real flows

The key principle:

- Atlas should feel finite, decisive, and calm on root surfaces.
- Great features are not enough if the user experiences them as endless stacked surfaces.

## Root-tab rules

Each root tab should answer one primary question.

- `Today`: what needs action now?
- `Timeline`: what happened?
- `Library`: what am I running or planning?
- `Insights`: what do I want to capture, review, or inspect?
- `Settings`: what mode am I in, and where do I go to change something?

Avoid root tabs becoming:

- feature warehouses
- admin surfaces
- long indexes of unrelated modules
- places where every section has equal weight

## Scroll discipline

Scrolling is not the problem by itself.

The problem is unranked scrolling.

Future passes should prefer:

- fewer same-weight sections on root tabs
- stronger featured modules
- compact summaries before full lists
- drill-ins instead of exposing every system at the root
- deliberate screen endings instead of “there is probably more below”

## Progressive disclosure rules

Do not use configurability as a substitute for curation.

Good defaults matter more than “users can hide cards later.”

Prefer:

- tight root defaults
- expandable queues
- routes into focused workspaces
- context-sensitive disclosure only when a setting or mode is enabled

## Copy rules

Do not add fake-sounding brand narration or philosophy copy to product UI.

Avoid:

- `Atlas is keeping ... in focus`
- `Atlas treats drift as ...`
- `Atlas noticed ...`
- any helper line that sounds like LLM narration instead of product UI

Prefer:

- title-first
- literal
- sparse
- action-first when possible

If a second line does not materially help task completion, delete it.

## Bottom shell guidance

Current rule:

- keep the existing docked bottom tab shelf as the baseline unless a new direction is explicitly requested

What failed in this thread:

- transparent / see-through tab bar treatments
- content fading or continuing beneath the tab bar
- shell experiments where the bottom of the app felt unresolved

Why they failed:

- content competed with the tabs
- the shell lost structure
- the bottom of the app looked messy instead of premium

If revisiting the bottom shell later:

- solve content architecture first
- keep selected-tab grounding strong
- do not rely on literal transparency as the main idea

## Settings and Insights rule

These were the highest-friction root areas during the UX pass.

Future work should keep:

- `Insights` focused on capture / review / inspection, not every intelligence surface at once
- `Settings` as a hub into focused workspaces, not one long admin sheet

If either tab starts feeling endless again, re-check:

- first-screenful density
- repeated helper copy
- too many toggles on one surface
- secondary systems leaking back into the root

## Interaction and accessibility rule

For premium quality, do not stop at visual polish.

Check:

- hit targets
- press states
- disclosure behavior
- keyboard dismissal
- dynamic type behavior
- reduce motion
- reduce transparency
- increased contrast
- VoiceOver / accessibility labeling when relevant

## Recommended skill medley

Use these together, not as one “magic skill”:

### Core repo-native skills

1. `build-ios-apps:swiftui-ui-patterns`
2. `build-ios-apps:swiftui-view-refactor`
3. `build-ios-apps:ios-debugger-agent`
4. `build-ios-apps:swiftui-performance-audit` when scroll density or rendering quality is part of the problem
5. `build-ios-apps:swiftui-liquid-glass` only for selective shell/chrome work
6. `build-ios-apps:ios-app-intents` when the UX extends into widgets, Shortcuts, or system entry points

### External reference stack worth checking when available

1. `twostraws/SwiftUI-Agent-Skill`
2. `avdlee/swiftui-agent-skill`
3. `PasqualeVittoriosi/swift-accessibility-skill`
4. `dpearson2699/swift-ios-skills`
5. `yusufkaran/swiftui-autotest-skill`

### Apple guidance that matched Atlas well

1. WWDC22 SwiftUI navigation guidance
2. Apple HIG `Designing for iOS`
3. Apple HIG `Toolbars`
4. Apple HIG `Segmented Controls`

## QA loop

Default loop for UX work:

1. inspect the real code first
2. build and run on simulator
3. drive the real flow
4. inspect UI tree / screenshots
5. refine the structure, not just the component styling
6. re-check accessibility and motion settings when relevant

For root-tab UX issues, always verify:

- first screenful
- mid-scroll behavior
- end-of-screen behavior
- re-entry from tab reselect / route pop

## Current thread outcomes worth preserving

This thread completed and/or established:

- a comprehensive root-surface UX pass
- stronger routing out of long settings surfaces
- copy cleanup to remove LLM-sounding helper text
- a rule against reintroducing narrativized `Atlas ...` helper copy
- a rule that transparent bottom-shell experiments are not the default answer
- a production ambient mascot rule: anchored, event-based, suppressible, and calm rather than free-roaming or constantly animated
- cloud security hardening for Atlas Cloud sessions and live review links

Future Codex threads should preserve those gains unless the user explicitly asks to revisit them.

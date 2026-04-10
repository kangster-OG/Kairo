# Atlas iOS Premium UI Review Rubric

Date: 2026-04-10
Owner: Codex design audit

## Purpose

This rubric is for evaluating Atlas as a premium, calm, local-first iPhone product rather than as a merely functional SwiftUI app.

The standard is:

- calm, serious, trustworthy
- clear next actions
- strong privacy/trust signaling
- tactile and polished interactions
- native iPhone feel, not generic card UI

Use this rubric before major UI changes and again after implementation.

## Scoring

Score each category from `1` to `5`.

- `1`: weak, confusing, or visibly unrefined
- `2`: functional but inconsistent or flat
- `3`: solid beta quality
- `4`: strong, intentional, release-quality
- `5`: premium, distinctive, and highly polished

## Categories

### 1. Product Clarity

Question:
Does the screen make the user's next best action obvious within the first few seconds?

What strong looks like:

- one dominant primary action
- obvious content priority
- reduced decision friction
- no equal-weight competing buttons

Failure signs:

- multiple actions competing for attention
- useful but passive screen that does not guide behavior
- copy explains too much because layout is not doing enough

### 2. Visual Hierarchy

Question:
Is there a clear ladder from background to chrome to content to primary action?

What strong looks like:

- distinct hierarchy between hero, active task, reference, and utility content
- typography and spacing do most of the organization work
- section headers and cards feel purposefully ranked

Failure signs:

- too many cards with similar weight
- headers visually stronger than content without reason
- primary CTAs not sufficiently differentiated from secondary actions

### 3. Surface Depth And Materiality

Question:
Do cards, buttons, bars, and hero modules feel tactile and intentionally layered?

What strong looks like:

- multiple elevation tiers
- differentiated surfaces for hero, utility, input, and navigation
- controlled use of shadow, border light, opacity, and material

Failure signs:

- all surfaces feel like the same rounded rectangle
- shadows are too weak or identical everywhere
- selected states are mostly tint-only

### 4. Motion And Interaction Quality

Question:
Do transitions and responses communicate state change with confidence?

What strong looks like:

- gentle spring and pressed feedback
- sheet, tab, and state transitions feel choreographed
- action completion gets lightweight but satisfying acknowledgment

Failure signs:

- interactions feel instant but emotionally flat
- no relationship between cause and effect
- major context changes happen with little feedback

### 5. Trust, Privacy, And Seriousness

Question:
Does the interface reinforce privacy, local-first safety, and user control?

What strong looks like:

- trust-related controls feel coherent across the app
- sensitive actions feel deliberate
- privacy modes are legible and clearly consequential

Failure signs:

- privacy surfaces read like settings clutter
- trust-critical choices look visually equivalent to ordinary preferences
- app tone becomes either clinical or decorative

### 6. Form And Input Experience

Question:
Do forms feel calm, forgiving, and optimized for real device use?

What strong looks like:

- clean field rhythm
- low-friction keyboard flow
- visible defaults, inline help, and clear completion path
- toggles, pickers, and numeric controls feel intentional

Failure signs:

- operational density
- too many bordered controls stacked with little pacing
- advanced options and primary tasks are visually mixed together

### 7. State Design

Question:
Are empty, loading, error, signed-out, denied, and locked states product-quality, not fallback-quality?

What strong looks like:

- empty states teach the model and the next step
- errors preserve confidence
- disabled or unavailable states are still well explained

Failure signs:

- empty screens feel generic
- signed-out or denied states look bolted on
- serious states use only red text and no structural support

### 8. Information Density

Question:
Is the content density matched to the task and emotional tone?

What strong looks like:

- hero moments feel spacious
- operational sections get tighter where appropriate
- no screen feels simultaneously sparse and busy

Failure signs:

- too much repeated explanatory copy
- large surfaces with low informational payoff
- dense controls inside overly airy shells

### 9. Accessibility As Premium Quality

Question:
Does the screen feel generous, legible, and forgiving across text sizes and touch contexts?

What strong looks like:

- strong contrast
- dependable touch targets
- Dynamic Type resilience
- selected and active states remain clear without relying on subtle color changes

Failure signs:

- visual polish depends on small text or subtle gray
- tap targets feel compressed
- segmented controls or pill controls lose legibility quickly

### 10. Brand Character

Question:
Does the app feel distinctly Atlas, not interchangeable with another health or productivity app?

What strong looks like:

- calm but memorable signature
- trust-first tone
- premium restraint instead of trend-following decoration

Failure signs:

- looks polished but generic
- over-reliance on one brand color
- no unique emotional signature beyond "nice cards"

## Atlas Design Principles

When tradeoffs appear, prefer these principles in order:

1. Clarity over ornament
2. Trust over novelty
3. Calm over intensity
4. Directed action over feature sprawl
5. Premium restraint over decorative premium
6. Native iPhone feel over custom-for-custom's-sake

## Shared Design-System Goals For The Next Pass

The next UI pass should improve the shared system before polishing individual screens.

Required shared outcomes:

- define `hero`, `elevated`, `default`, and `utility` surface tiers
- strengthen primary, secondary, tertiary, and destructive button families
- improve selected, pressed, disabled, and loading states
- tighten typography roles for title, subtitle, section label, body, and caption
- make trust/privacy controls feel like one system
- introduce motion rules for tab changes, card presses, sheet entry, and success feedback
- reduce visual sameness across cards, forms, and utility controls

## Audit Template

For each screen, capture:

- score by category
- strongest current traits
- biggest gaps
- must-fix items before ship
- optional premium polish ideas

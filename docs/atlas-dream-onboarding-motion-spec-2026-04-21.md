# Atlas Dream Onboarding Motion and Interaction Spec - 2026-04-21

This is the full dream version: a long, premium, emotionally memorable onboarding that borrows the best of Cal AI and Finch without losing what makes Atlas different.

The north star:

> Atlas should feel like a private protocol operating system assembling itself around the user's real life. The companion should awaken only after that system is ready.

## Design Principles

1. Long is good when every chapter earns the next one.
2. Every answer should change something visible.
3. Every chapter should end in a payoff, not just another Continue button.
4. The generated plan should feel like the app did work.
5. The mascot should be emotionally powerful but not first-screen branding.
6. Privacy and trust should feel like a flagship product layer, not compliance copy.
7. The app should never land empty after onboarding.
8. Motion should be calm, premium, and useful. No chaotic bouncing. No toy-store energy.
9. The user should leave thinking: "Atlas understands the operational mess I am managing."

## What We Borrow From Cal AI

- Opening live product demo.
- One-question-at-a-time clarity.
- The feeling that answers calibrate a plan.
- A visible generation sequence with progress.
- A concrete result before paywall.
- Clean dashboard cards after onboarding.
- Fast floating action menu.
- Photo/scan tutorial moments.
- Small action -> immediate badge/progress feedback.
- Trial timeline that explains billing before purchase.

## What We Borrow From Finch

- Personalization before vulnerability.
- Hatching as emotional payoff.
- Suggested names and shuffle.
- Trait/personality selection.
- A companion that responds to effort.
- Long questionnaire with a visible progress rail.
- Selected states with checkmarks and warmth.
- Generated starter plan.
- No-empty-home landing.
- Daily checklist loop.
- Widget prompt after value is established.
- Evolution milestones and collections.

## What Atlas Must Keep

- Private, local-first, guest-first.
- No diagnosis.
- No dosing advice.
- No sourcing.
- No public social feed.
- No shame.
- No fake urgency.
- Exact protocol setup after paywall unless strategy changes.
- Companion remains optional, subtle, and adult.

## Overall Structure

This dream onboarding is 80-100 screens, but it should feel like 12 chapters with payoffs:

1. Operating System Fantasy
2. Protocol Reality
3. Goals and Body Context
4. Friction and Risk Map
5. Privacy and Trust Vault
6. Atlas Generation Sequence
7. Companion Hatch
8. Protocol Readiness Map
9. Proof Tour
10. First-Week Plan
11. Trial and Access
12. Permissions and Day 1 Handoff

The user should always know where they are. Use chapter markers, progress rails, and visible "Atlas draft" updates.

## Motion System

### Motion Personality

- Springs should feel confident, not bouncy.
- Cards should slide, stack, reveal, and lock into place.
- Trust surfaces should use slower, heavier motion.
- Companion surfaces can use warmer motion, but still restrained.
- Completion moments can use light confetti only in non-sensitive areas.
- Sensitive states use glow, check, seal, and lock animations instead of celebration.

### Haptics

- Selection: light impact.
- Chapter completion: soft success.
- Trust mode activation: firm, subtle impact.
- Companion hatch: two-step haptic, warm-up then success.
- First Day 1 task completed: success haptic.
- Paywall plan select: light impact, no casino-like feedback.

### Reduce Motion

Every animation must have a Reduce Motion equivalent:

- Crossfade instead of parallax.
- Progress changes without moving paths.
- Companion hatch becomes fade/open/appear.
- Card stack becomes instant reorder with opacity.
- No repeating ambient movement.

## Chapter 1: Operating System Fantasy

### Screen 1: Atlas Hero

Copy:

- "Atlas"
- "Run your protocol from a private command center."
- CTA: "Build my Atlas"
- Secondary: "Continue privately"

Visual:

- Full-screen native iPhone mockup.
- Inside the mockup, Atlas Today, Trust Vault, Review Output, Migration, and Protocol Change Studio rotate through a live demo.
- No mascot yet. Maybe a tiny dormant signal mark in the corner, but nothing cute.

Animation:

- The phone mockup settles from a slight vertical lift.
- Cards inside the mockup cycle every 1.5-2 seconds.
- Today card expands into Review card, Review card redacts into Trust Vault, Trust Vault folds into Migration, Migration becomes Protocol Change Studio.
- CTA stays fixed and stable.

Interaction:

- User can tap the mockup to pause and manually swipe through product moments.

### Screen 2: What Atlas Is

Show five pillars:

- Today: what needs action now.
- Timeline: what happened.
- Library: what you are running.
- Insights: what to capture and review.
- Trust Vault: what stays private.

Animation:

- Five cards appear as a fan, then snap into a clean stack.
- Tapping each card flips it to a one-sentence explanation.

### Screen 3: What Atlas Is Not

Boundaries:

- Not medical advice.
- Not dosing recommendations.
- Not sourcing.
- Not a public community.
- Not a diagnosis tool.

Animation:

- Each boundary stamps with a calm shield check.
- No warning red unless required. Use trust-blue/green.

### Screen 4: Start Private

Message:

- "No account required to build your Atlas."
- "Sign in later for backup and continuity."

Animation:

- A local device icon lights up first.
- Cloud backup icon remains secondary and dim.

## Chapter 2: Protocol Reality

This chapter borrows Shotsy specificity but with Atlas depth.

### Shared Interaction Pattern

Each screen has:

- Big question.
- One-line reason.
- Option cards with icons.
- Bottom "Your Atlas draft" strip.
- Selected card compresses by 2%, border draws clockwise, check appears.
- Draft strip updates immediately.
- Continue button unlocks with a small upward pulse.

### Screens

1. "What are you tracking?"
   - GLP
   - peptides
   - both
   - custom protocol
   - exploring

2. "Where are you starting?"
   - not started
   - already active
   - changing plan
   - restarting
   - importing messy history

3. "How are you tracking today?"
   - memory
   - notes
   - spreadsheet
   - another app
   - provider portal
   - paper/logbook

4. "What kind of routine is this?"
   - injection
   - oral
   - mixed
   - supplies only
   - not sure

5. GLP family, if applicable.

6. Peptide selections, if applicable.

7. "How regular is the schedule?"
   - daily
   - weekly
   - every few days
   - phases/titration
   - irregular
   - not sure

8. "What is hardest to keep clear?"
   - next action
   - missed steps
   - side effects/context
   - food noise/appetite
   - inventory
   - privacy
   - explaining later
   - progress evidence

Animation:

- The Atlas draft strip grows from "Private shell" into a labeled mini command center.
- By the end, the strip has track, stage, friction, and privacy placeholder.

## Chapter 3: Goals and Body Context

This chapter borrows Cal AI's calibration feeling.

### Screen: Weight and Goal Context

Copy:

- "Optional. Atlas uses this for progress context and review summaries, not dosing advice."

Interaction:

- User can enter current weight, goal weight, or skip.
- A tiny "Used for" popover shows: Progress Evidence, Weekly Review, Apple Health import, private charts.

Animation:

- If entered, a subtle progress line appears.
- If skipped, the line becomes "Set later" without penalty.

### Screen: Nutrition Interest

Options:

- none
- hydration and protein only
- meal context
- photo-assisted capture
- Apple Health import later

Animation:

- Selecting an option changes a mini Insights preview.
- Photo-assisted capture shows a Cal AI-inspired tiny food-card scan, but clearly labeled "context estimate, editable."

### Screen: Goal Pace

If weight goal exists:

- no pace
- gentle
- moderate
- provider-guided/custom

Copy:

- "Atlas records your chosen context. It does not prescribe a pace."

### Screen: What Would Make 7 Days Feel Successful?

Options:

- first protocol organized
- first reminder working
- inventory visible
- review summary ready
- progress evidence started
- privacy mode set
- less chaos

Animation:

- Selected answers become Day 1 plan seeds.

## Chapter 4: Friction and Risk Map

This is Finch's long personalization plus Quittr's result setup, translated ethically.

### Screens

1. "What tends to interrupt your routine?"
2. "Which days are hardest?"
3. "What makes logging hard?"
4. "What would you want Atlas to help recover from?"
5. "What do you need to explain later?"
6. "What would you rather keep discreet?"
7. "What kind of reminders feel acceptable?"

Interaction:

- Multi-select rows with icons.
- Each row selected adds a tiny token to the Atlas draft strip.
- No answer feels wrong.

Animation:

- The selected tokens flow upward into a "Readiness Map pending" card.
- The pending card remains locked until generation.

Microcopy:

- "This shapes your first-week setup."
- "Atlas will not judge missed actions."
- "This helps choose the recovery tools to show first."

## Chapter 5: Privacy and Trust Vault

This should feel like a flagship moment.

### Screen: Choose Privacy Posture

Options:

- Full labels
- Discreet labels
- Alias mode
- Decide later

Interaction:

- Live preview card changes in real time.
- Example: "Semaglutide" becomes "Weekly routine" or a user-selected alias.

Animation:

- Full label card slides into a sealed Trust Vault frame.
- Discreet mode blurs/redacts sensitive words, then resolves into safe text.
- Alias mode flips the label like a card changing identity.

Haptic:

- Firm subtle tap when privacy mode locks.

### Screen: Review Sharing Boundary

Interactive preview:

- Toggle "full labels"
- Toggle "alias labels"
- Toggle "hide notes"
- Toggle "include inventory"

Animation:

- Review document preview updates line by line.
- Redacted rows collapse smoothly.

### Screen: Trust Promise

Copy:

- "You inspect before sharing."
- "Local-first by default."
- "No public feed."
- "No sourcing."

Animation:

- Four trust seals light up, one at a time.

## Chapter 6: Your Atlas Is Taking Shape

This is the Cal AI generation sequence, but much better and honest.

### Screen: Generation Start

Copy:

- "Your Atlas is taking shape."
- "Building a private operating map from your answers."

Visual:

- Center: sealed capsule/core.
- Around it: small cards representing protocol, privacy, review, inventory, context, companion signal.

Animation:

- Cards orbit? No. Keep it more mature: cards slide along clean rails into the capsule.
- Progress bar at bottom.
- Background subtly shifts from neutral to the user's chosen signal color.

### Generation Steps

1. "Organizing protocol context"
   - track type, stage, cadence lock into place.

2. "Mapping routine friction"
   - missed steps, inventory, review, privacy cards connect.

3. "Preparing Trust Vault posture"
   - lock seal closes.

4. "Drafting Day 1 command center"
   - Today mini surface appears.

5. "Preparing first-week plan"
   - seven-day strip appears.

6. "Waking companion signal"
   - capsule begins to glow.

Animation Details:

- Each step has a checkmark that draws itself.
- Percent progress appears, but not too fake. Use "Step 3 of 6" plus optional percent.
- The capsule gets brighter only after the operational pieces are done.
- The user cannot accidentally skip this too fast, but can "Skip animation" for accessibility.

Sound:

- No sound by default.
- Haptics only.

## Chapter 7: Companion Hatch

This is the Finch moment, but earned.

### Screen: Capsule Opens

Copy:

- "Your companion is online."
- "It will help mark follow-through, recovery, and review readiness."

Visual:

- Existing Atlas companion design.
- The companion emerges from the capsule/core.
- The selected signal color appears as a small accent, not a full palette takeover.

Animation:

- Capsule seam line appears.
- Light travels around the seam.
- Capsule opens in two calm panels.
- Companion fades/steps into view.
- No cartoon bounce.
- Companion gives one subtle wave or blink.

Haptic:

- Warm-up haptic during glow.
- Success haptic when companion appears.

### Screen: Name Companion

Interaction:

- Text field.
- Suggested names.
- Shuffle.
- "Use default."

Animation:

- Name choices slide as chips.
- Selected name attaches to companion card.

### Screen: Choose Signal Color

Options:

- current supported mascot colors/design choices
- keep avatar design unchanged

Animation:

- Color applies to small signal ring, not whole screen.
- Companion preview updates.

### Screen: Choose Companion Role

Options:

- Steady
- Precise
- Discreet
- Encouraging
- Reflective
- Protective

Interaction:

- Role changes example companion copy.

Examples:

- Steady: "Next step is clear."
- Precise: "Schedule, inventory, and review are aligned."
- Discreet: "Private reminder ready."
- Encouraging: "You handled the reset."
- Reflective: "Weekly review is ready when you are."
- Protective: "Trust Vault is active."

### Screen: Choose Presence

Options:

- Subtle
- Balanced
- More alive

Rules:

- Subtle: appears on Today and milestones only.
- Balanced: Today, weekly review, selected completion states.
- More alive: adds small idle reactions and widget presence.

## Chapter 8: Protocol Readiness Map

This is Quittr's "analysis complete" without shame or diagnosis.

### Screen: Map Reveal

Copy:

- "Your Protocol Readiness Map"
- "This is not medical advice. It shows what Atlas can help organize first."

Dimensions:

- Schedule clarity
- Inventory confidence
- Change-history readiness
- Review readiness
- Privacy posture
- Context signal coverage

Animation:

- Six bars/rings draw into place.
- Each dimension reveals with a label and "Atlas will help by..."
- The weakest dimension does not turn red. It uses amber or neutral.

Interaction:

- User can tap any dimension to see why it scored that way.
- Each detail includes a direct product surface.

Examples:

- Schedule clarity -> Today, reminders, protocol setup.
- Inventory confidence -> Inventory runway.
- Review readiness -> Review Mode and Weekly Review.
- Privacy posture -> Trust Vault.

### Screen: Strongest Starting Point

Copy:

- "Your strongest starting point: Privacy posture."
- Or whatever fits answers.

Animation:

- That section expands into first Day 1 checklist recommendation.

### Screen: First Setup Gap

Copy:

- "First setup gap: Inventory runway."
- "Atlas will keep this as an optional Day 1 task."

Important:

- Never shame.
- Never imply medical danger.

## Chapter 9: Interactive Proof Tour

This is where Atlas earns a long onboarding.

### Proof 1: Today Command Center

Interactive demo:

- Next action card.
- Inventory runway chip.
- Trust state chip.
- Review readiness chip.

User action:

- Tap "Preview next action."

Animation:

- The next action card expands.
- Recovery option peeks below.
- Companion observes quietly in corner.

### Proof 2: Missed-Step Recovery

Interactive demo:

- User taps "Missed."
- Atlas shows:
  - mark skipped
  - reschedule
  - add note
  - review later

Animation:

- Missed state becomes recovery state without red panic.
- Timeline preview shows old record preserved.

### Proof 3: Protocol Change Studio

Interactive demo:

- Timeline with current plan and future revision.
- User scrubs between "before" and "after."

Animation:

- Old plan stays anchored.
- New plan slides in from the future side.
- A divider says "history remains intact."

### Proof 4: Review Output

Interactive demo:

- Tap privacy toggle.
- Full labels become alias/discreet labels.
- Inventory and notes can be included/excluded.

Animation:

- Document rows reflow.
- Redacted labels transform, not disappear abruptly.

### Proof 5: Migration

Interactive demo:

- Source card -> validation -> preview -> commit.
- Restore point appears before commit.

Animation:

- Cards move through a pipeline.
- Errors are calm and fixable.

### Proof 6: Inventory Runway

Interactive demo:

- Add one vial/supply placeholder.
- See runway estimate card.

Animation:

- Inventory card links to Today card with a line or matched transition.

### Proof 7: Progress Evidence

Interactive demo:

- Before/after photo placeholder.
- Same-angle guide.
- Measurement trend.

Animation:

- Split view slider.
- "Private by default" seal.

### Proof 8: Weekly Review

Interactive demo:

- Week summary cards:
  - completed
  - missed/recovered
  - context logged
  - inventory checked
  - questions to review

Animation:

- Cards stack into a review artifact.

### Proof 9: Widgets

Interactive demo:

- Widget previews:
  - Next action
  - Quick capture
  - Companion signal
  - Weekly review ready

Animation:

- Widget card lifts out of app screen and lands on Home Screen mockup.

## Chapter 10: First-Week Plan

This borrows Finch's starter plan and Cal AI's plan reveal.

### Screen: First Week In Atlas

Cards:

- Today: finish first setup.
- Day 1: create/import first protocol.
- Day 2: choose reminder/privacy behavior.
- Day 3: add context/nutrition if useful.
- Day 4: add inventory runway.
- Day 5: inspect timeline/change history.
- Day 6: review before renewal.
- Day 7: weekly review artifact.

Animation:

- Horizontal seven-day rail.
- Each day card flips from "planned" to "ready."
- Companion sits at Day 1, not Day 7.

Interaction:

- User can tap each day.
- Tapping shows which Atlas surface powers it.

## Chapter 11: Trial and Access

This is the ethical version of Cal AI and Finch paywall strategy.

### Screen: Unlock The Atlas You Built

Visual:

- The generated artifacts stack behind the paywall:
  - Readiness Map
  - Today Command Center
  - Trust Vault
  - Review Output
  - First-Week Plan
  - Companion

Animation:

- Artifacts fan forward.
- Paywall is the final card in the stack.
- It feels like access, not interruption.

### Screen: Trial Timeline

Timeline:

- Today: unlock full Atlas setup.
- Day 2: first protocol/import should be active.
- Day 5: weekly review preview.
- Day 6: renewal reminder.
- Day 7: plan renews unless canceled.

Animation:

- Timeline draws from top to bottom.
- Billing date is visually clear.

### Screen: Plan Select

Rules:

- Show real billing amount.
- Trial terms readable.
- No fake countdown.
- No confusing weekly-equivalent emphasis.
- Restore, Terms, Privacy visible.

Interaction:

- Plan card selection has haptic and clear check.
- CTA says exactly what happens.

### Screen: Basic Path

If product strategy keeps it:

- "Continue with basic local tracking."
- Make the tradeoff clear without punishment.

## Chapter 12: Permissions and Day 1 Handoff

### Screen: Reminder Setup

Options:

- discreet protocol reminders
- weekly review reminders
- trial reminder
- no reminders yet

Animation:

- Notification preview updates with selected privacy mode.

### Screen: Apple Health

Options:

- connect now
- skip

Explanation:

- Works without Apple Health.
- Can import weight, workouts, water, calories, protein if allowed.
- Change later.

Animation:

- Health data sources appear as optional cards.
- Skipping keeps cards available but dimmed.

### Screen: Widget Setup

Borrow Finch's timing: ask after value.

Interaction:

- Add later.
- Show me how.

Animation:

- Widget mockup slides onto Home Screen preview.

### Screen: How Did You Hear About Atlas?

Simple attribution.

Animation:

- No big moment. Keep it fast.

### Final Screen: Welcome To Your Atlas

Visual:

- Today command center preview becomes the real Today screen.
- The onboarding chrome dissolves.
- Day 1 checklist is already present.
- Companion sits subtly in the hero.

Animation:

- Matched transition from generated Today preview to actual Today.
- Progress rail fades into Day 1 readiness meter.
- CTA "Enter Atlas" becomes the first Today action.

## Dream Day 1 Today Screen

The first app screen should include:

- Hero: "Finish your first protocol setup."
- Readiness meter:
  - Schedule
  - Privacy
  - Inventory
  - Review
  - Context
- Day 1 checklist:
  1. Add or import current protocol.
  2. Choose reminder style.
  3. Add inventory or skip.
  4. Set review privacy.
  5. Capture one context signal if useful.
- Companion signal: subtle.
- First-week plan collapsed below.

### Completing A Task

Animation:

- Task card compresses.
- Check draws.
- Readiness meter increments.
- Companion acknowledges based on selected role.
- Today hero updates.

Examples:

- Steady: "Next step is clear."
- Protective: "Trust posture saved."
- Precise: "Inventory now links to this protocol."

## Dream In-App Motion Beyond Onboarding

### Logging A Due Action

- CTA presses down.
- Sheet rises from bottom.
- User confirms.
- Timeline event slides into place.
- Today hero changes to next state.
- Companion acknowledgement only if enabled.

### Missed-Step Recovery

- Missed state does not flash red.
- Recovery options slide up as calm choices.
- Choosing one preserves history visually.
- Change is echoed into Timeline.

### Trust Vault Mode Change

- Screen slows down.
- Mode preview changes first.
- Confirmation seal closes.
- Haptic is firm and subtle.
- Companion is not present here unless only as static decorative signal, preferably absent.

### Review Pack Generation

- Source cards gather:
  - protocol
  - timeline
  - inventory
  - context
  - questions
- Cards stack into a document.
- User previews before export.
- Export button only appears after preview.

### Weekly Review

- Week cards slide into a summary.
- Missed/recovered items are neutral.
- Next action card appears last.
- Completion can unlock companion/evolution progress.

### Progress Evidence

- Same-angle guide uses calm alignment animation.
- Compare slider is tactile.
- Export preview uses privacy seals.

### Inventory Runway

- Adding a vial animates into runway.
- Low-stock state appears as a clear planning signal, not alarm.
- Today card updates if inventory affects readiness.

## Companion Evolution Rules

The companion evolves from operational maturity, not generic streak pressure.

Milestones:

- First protocol created/imported.
- First due action logged.
- First missed-step recovery handled.
- First Trust Vault mode set.
- First inventory runway added.
- First weekly review completed.
- First review pack generated.
- First progress evidence captured.
- First month of review history.

Animation:

- Evolution card appears after the meaningful action.
- The companion gets a subtle stage reveal.
- The exact protocol action remains the hero, companion is secondary.

## "Wow" Moments

These are the moments that should make Atlas feel best in class:

1. Opening live protocol operating-system demo.
2. Every answer visibly updates the Atlas draft.
3. Trust Vault live redaction preview.
4. "Your Atlas is taking shape" generation sequence.
5. Companion capsule hatch after the map is ready.
6. Protocol Readiness Map reveal.
7. Missed-step recovery demo that preserves history.
8. Review artifact privacy toggle.
9. Migration pipeline with restore point.
10. First-week plan reveal.
11. Paywall artifact stack.
12. Today preview morphs into real Today.
13. First Day 1 task completion updates readiness and companion.

## Final Dream Feeling

The user should feel:

- "This app is serious."
- "This app is private."
- "This app understands messy real life."
- "This app already built something around me."
- "The companion is mine, but it is not childish."
- "I know exactly what to do first."
- "This is worth trying for a week."

## One Sentence Version

Atlas onboarding should feel like watching a private operating system assemble around your real protocol, hatch a companion only after the system is ready, reveal a readiness map and first-week plan, then land you in Today with the first useful action already waiting.

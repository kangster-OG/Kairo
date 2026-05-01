# Atlas Onboarding Rebuild Strategy - 2026-04-24

## Work Done First

The previous Atlas onboarding UI was removed before this strategy pass:

- Deleted `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasDreamOnboardingFlow.swift`.
- Replaced the prior `AtlasOnboardingFlowScreen` implementation in `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift` with a temporary rebuild placeholder.
- Left the shared domain and persistence contracts in place because post-onboarding surfaces still read onboarding draft fields for seeded preferences, mascot defaults, nutrition defaults, and Day 1 continuity.

## Research Inputs

Dense frame extraction was rerun at `0.25s` intervals for all eight local recordings:

- Pep AI / peptide app: `ScreenRecording_04-21-2026 13-43-08_1.MP4`
- Shotsy: `ScreenRecording_04-21-2026 13-48-12_1.MP4`
- Cal AI: `ScreenRecording_04-21-2026 13-53-26_1.MP4`
- Finch onboarding: `ScreenRecording_04-21-2026 15-09-05_1.MP4`
- Finch app continuation: `ScreenRecording_04-21-2026 15-17-54_1.MP4`
- Finch profile/collections: `ScreenRecording_04-21-2026 15-19-23_1.MP4`
- Pepty onboarding: `ScreenRecording_04-21-2026 23-15-10_1.MP4`
- Pepty app continuation: `ScreenRecording_04-21-2026 23-16-47_1.MP4`

Output:

- `output/onboarding-rebuild-dense-frames-2026-04-24/`
- Contact sheets: `output/onboarding-rebuild-dense-frames-2026-04-24/contact-sheets/`

External article:

- HubSpot / Starter Story, `Mobile App Onboarding Deep Dive`.

## Competitor Findings

### Shotsy

What works:

- Domain specificity is excellent: already taking GLP-1, route, medication, current dose, device type, cadence, goals, height, weight, start weight/date, goal weight, pace, activity level, hard days, and side-effect concerns.
- It explains why sensitive inputs matter.
- It previews medication-level charts and post-onboarding lands on `Add your first shot`.
- The paywall is tied to concrete features like medication charts, Apple Health, widgets, and treatment summaries.

What Atlas should avoid:

- It is visually form-heavy.
- It asks for rating/social proof before enough actual use.
- It asks exact medication/dose setup before payment; Atlas should keep exact protocol setup after access unless strategy changes.

Atlas takeaway:

- Borrow the protocol-specific setup questions and first-shot clarity.
- Make those questions assemble a visible Atlas artifact instead of feeling like forms.

### Pep AI

What works:

- It exposes the category map quickly: dose, calendar, site tracker, nutrition, hydration, progress photos, daily check-in, sleep, bloodwork, PDF export, Apple Health, achievements, and AI insights.
- The product breadth is easy to scan.

What Atlas should avoid:

- The paywall appears quickly and repeatedly.
- One-time discount language makes the app feel commerce-led.
- Empty product surfaces plus interruptive paywalls make the app feel less earned.
- It leans into AI assistant and meal-scan breadth that Atlas should not copy.

Atlas takeaway:

- Atlas should show breadth through a guided protocol-system preview, not repeated paywall interruption.

### Pepty / The Peptide App

What works:

- It asks direct peptide-market questions: why the user came, what categories interest them, experience level, compounds, frustrations, and learning path.
- It has a generated persona/result moment: `Steady Researcher`.
- It has a before/after chart that shows life without tracking versus with Pepty.
- It builds a learning path with concrete counts.

What Atlas should avoid:

- It includes `Find peptides to buy`, price comparison, vendors/supplies, affiliate disclosure, and marketplace-style browsing.
- It presents interaction guidance in a way that drifts toward advice.
- It asks for a review before the user has completed a meaningful core action.

Atlas takeaway:

- Borrow the persona/result and before/after mechanics.
- Reject vendor, sourcing, price comparison, and research-marketplace framing.

### Cal AI

What works:

- It opens with the product already working.
- Every question is tied to calibration.
- It uses a strong generation sequence with percentages and checklist items.
- It reveals a concrete generated plan before the paywall.
- Its home screen has clear daily targets and fast action entry.

What Atlas should avoid:

- Account creation before paywall makes the personalized plan feel held hostage.
- ATT/permission prompts interrupt the sacred generation moment.
- The three-day trial and billing design can feel aggressive.
- Atlas should not copy calorie-scanner positioning or nutrition sprawl.

Atlas takeaway:

- The strongest Atlas moment should be: `Your Atlas is ready`, with a real protocol-readiness map, Day 1 protocol system, Trust Vault defaults, first-week plan, review preview, and companion signal.

### Finch

What works:

- It gives emotional ownership immediately through egg choice, hatch, pronouns, name, user name, and pet response.
- The pet asks for reminders in context, not as a random permission.
- The questionnaire keeps the pet visible, making long personalization feel less clinical.
- It generates starter goals before the paywall.
- It lands with goals, quests, progress, food/energy payoff, evolution target, widget prompt, and a no-empty-home loop.
- The pet profile makes progress feel owned and collectible.

What Atlas should avoid:

- Atlas should not become pet-first.
- Atlas should not add a shop/furniture/friends/social economy.
- Atlas should not make mascot care feel like an obligation.

Atlas takeaway:

- The companion should awaken after Atlas has assembled the user's protocol system.
- The hatch should feel earned from the user's system, not like the app is a pet game.

### HubSpot / Starter Story Article

Useful principles:

- Onboarding is a story, not a formality.
- The first screens must clarify the problem and solution.
- Ask questions that make the user recognize their own problem, not only questions that feed the app data.
- Create an early personal aha moment from the user's answers.
- Follow that aha with hope and a plan.
- Let the user use the core product inside onboarding.
- Celebrate at the emotional peak.
- Use a loading/generation transition into a personalized summary.
- Make the last pre-paywall screen about the user, not the app.
- Permission setup should be paced and framed, not dumped as raw prompts.

## Proposed Atlas Onboarding

The strongest Atlas onboarding should be a 12-chapter story with roughly 55-70 user-facing states. It should feel substantial but not swollen. The old 180-state flow was ambitious, but the new direction should be tighter, more psychological, more visual, and more consequential.

### Chapter 1: Protocol System Fantasy

Goal: prove Atlas before asking for data.

Screens:

1. `Atlas` / `Build your peptide protocol.`
2. Live Today demo: next shot, runway, rings, site rotation, Share Summary.
3. Live Log Shot ritual demo: site, pain, side effects, vial decrement, reward.
4. Live Companion demo: level ring, quests, badges, locked next form.
5. Boundary screen: not dosing advice, not sourcing, not diagnosis.

Psychology:

- This is Cal AI's live product fantasy, but for protocol operations.
- The user sees the destination before the questionnaire.

### Chapter 2: Why This Matters

Goal: create the first personal aha.

Screens:

1. `What feels hardest to keep straight?`
2. `How are you tracking today?`
3. `How often does real life change the plan?`
4. Personal aha: `Your protocol has 4 places where details can drift.`
5. Bridge: `It does not have to stay scattered. Let's build your Atlas.`

Psychology:

- This borrows HubSpot's problem/solution/bombshell structure.
- It avoids shame. The aha is operational, not diagnostic.

### Chapter 3: Protocol Reality

Goal: capture the minimum domain setup needed to make Atlas feel personalized.

Questions:

- Track type: GLP, peptide, both, custom, exploring.
- Journey stage: planning, active, changing, restarting, importing.
- Route: injection, oral, mixed, not sure.
- Cadence shape: daily, weekly, every few days, phases, irregular.
- Site rotation need.
- Inventory/runway need.
- Side-effect/context need.

Psychology:

- Shotsy-level specificity, but no exact dose recommendation.
- Every answer visibly updates an `Atlas draft` strip.

### Chapter 4: Goals And Evidence

Goal: personalize without becoming a calorie app.

Questions:

- Primary goal: consistency, side-effect context, weight/progress, provider review, privacy, inventory.
- Seven-day win.
- Optional body context.
- Protein/hydration/workout interest.
- Progress evidence preference.
- Share/review audience.

Psychology:

- Cal AI-style calibration, but the output is operational: what Atlas should put on Today and Share Summary.

### Chapter 5: Friction Map

Goal: make the user feel seen.

Questions:

- What interrupts routine?
- Hardest days/times.
- Logging friction.
- Missed-step preference.
- Privacy concern.
- Reminder style.
- Support style.

Payoff:

- `Your friction map`: schedule clarity, logging ease, recovery readiness, privacy comfort, review readiness, inventory confidence.

Psychology:

- Pepty's persona/result moment plus HubSpot reflection.
- The user recognizes themselves in the answer choices.

### Chapter 6: Trust Vault Setup

Goal: make trust a product layer without making privacy the headline.

Screens:

- Clear labels vs discreet labels.
- Notification preview.
- Share Summary redaction preview.
- Local-only by default, backup later.

Psychology:

- Trust reduces hesitation before the paywall.
- The user sees control, not compliance copy.

### Chapter 7: In-Onboarding Core Ritual

Goal: let the user use Atlas before paying.

Interactive demo:

- Tap a demo next shot.
- Select injection site.
- Mark mild side-effect chip.
- Watch vial runway update.
- See `Share Summary` add one clean source fact.

Psychology:

- This is the HubSpot climax: the user performs the core loop, not just sees it.
- It makes Atlas concrete and useful.

### Chapter 8: Atlas Generation

Goal: make the app feel like it worked for the user.

Timed stages:

- Organizing protocol reality.
- Mapping friction.
- Sealing privacy defaults.
- Drafting Today.
- Preparing first-week plan.
- Preparing review summary.
- Warming companion signal.

Psychology:

- Cal AI's generation payoff, but honest and deterministic.
- No permissions or account prompts here.

### Chapter 9: Companion Awakening

Goal: emotional ownership after utility is proven.

Screens:

- Choose Aurielle or Aetherion.
- Signal core opens around the existing companion art.
- Name or accept suggestion.
- Choose role: steady, precise, discreet, encouraging.
- Choose presence: off, subtle, default, more alive.

Psychology:

- Finch's hatching magic, but earned by the protocol system.
- The companion is a continuity layer, not the product premise.

### Chapter 10: Readiness Reveal And First Week

Goal: show the user what they now own.

Screens:

- Protocol Readiness Map.
- Strongest starting point.
- First gap to fix.
- Day 1 checklist.
- First-week plan.
- Choose `Start light` or `Set up everything`.

Psychology:

- The last pre-paywall memory is not feature bullets. It is the user's own Atlas.

### Chapter 11: Trial And Access

Goal: transparent conversion after proof.

Screens:

- Artifact stack: readiness map, Day 1 plan, Trust Vault, review preview, companion.
- Premium unlock: active protocols, widgets, Share Summary, inventory runway, companion progression, weekly review.
- Plain trial timeline.
- Annual/monthly options.
- Basic tracking path visible.

Psychology:

- The paywall feels like continuing the system that already exists, not paying to discover if the app is useful.

### Chapter 12: Permissions And Day 1 Handoff

Goal: land in a non-empty app.

Screens:

- Notification primer.
- Health primer.
- Widget preview.
- Account backup later.
- Morph into Today with Day 1 checklist.
- First real action available.

Psychology:

- Permissions happen after value.
- Today is populated. The user is not dropped into an empty shell.

## Why This Is The Strongest Version

This design is strongest because it layers the best psychological mechanisms in the right order:

1. **Clarity:** the first minute shows exactly what Atlas does.
2. **Self-recognition:** the user chooses from problems they already feel.
3. **Personal aha:** Atlas quantifies operational drift without shame.
4. **Investment:** the user answers meaningful questions and watches their system assemble.
5. **Proof:** the user completes the core logging ritual inside onboarding.
6. **Ownership:** the companion awakens from their built system.
7. **Endowed progress:** the user reaches the paywall already holding a readiness map and Day 1 plan.
8. **Trust:** billing, privacy, permissions, and account backup are explicit and unforced.
9. **No empty home:** the first session has real work waiting.

It borrows Finch's emotional ownership, Cal AI's generated-plan confidence, Shotsy's protocol specificity, Pepty's result/persona mechanics, and HubSpot's story structure, while preserving Atlas' boundaries: no sourcing, no dosing advice, no diagnosis, no social/shop economy, and no mascot-first childishness.

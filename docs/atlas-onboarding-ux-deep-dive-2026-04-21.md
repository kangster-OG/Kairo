# Atlas Onboarding and UX Deep Dive - 2026-04-21

## Executive Read

Atlas should keep its long, proof-led onboarding. The market evidence does not point toward a shorter flow. It points toward a more earned flow: enough input to feel personal, visible output before payment, a clear trial timeline, and a first session that lands the user in a useful Day 1 loop instead of an empty app.

The strongest competitor pattern is not "ask many questions." It is "ask, show why it matters, turn the answer into a concrete artifact, then unlock the product." Cal AI, Shotsy, Finch, Quittr, and Noom all use versions of this. Atlas already has the right strategic foundation in `AtlasOnboardingDraft.sequence()`, but the next leap is making the flow feel less like premium explanation and more like the app is assembling a real protocol system around the user's answers.

Atlas has a better trust story than most of the category. That should become a visible competitive weapon. Cal AI and Quittr show how aggressive subscription or privacy tactics can drive growth while creating backlash. Atlas should win by being serious, clear, local-first, and unusually useful before the paywall.

## Method

- Reviewed all 8 user-provided screen recordings from `/Users/donghokang/Downloads`.
- Extracted timestamped frames every 2 seconds into `/tmp/atlas-onboarding-video-frames`.
- Generated contact sheets in `/tmp/atlas-onboarding-video-sheets`.
- Ran Vision OCR across all extracted frames into `/tmp/atlas-onboarding-video-ocr.tsv`.
- Read the current Atlas repo state, especially:
  - `/Users/donghokang/Developer/Atlas/README.md`
  - `/Users/donghokang/Developer/Atlas/atlas-ios/README.md`
  - `/Users/donghokang/Developer/Atlas/docs/ios-onboarding-paywall-handoff-2026-04-16.md`
  - `/Users/donghokang/Developer/Atlas/docs/figma-feedback-checklist-2026-04-18.md`
  - `/Users/donghokang/Developer/Atlas/docs/ios-ui-audit-2026-04-10.md`
  - `/Users/donghokang/Developer/Atlas/docs/ios-ux-execution-playbook-2026-04-15.md`
  - `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasDomain/Sources/AtlasDomain/AtlasOnboarding.swift`
  - `/Users/donghokang/Developer/Atlas/atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`
- Researched public App Store listings, competitor sites, review-mining articles, UX teardowns, subscription/paywall research, Apple guidance, and behavioral psychology sources.

## Current Atlas Baseline

Atlas is currently positioned as a privacy-first, local-first protocol tracker for injectables and adjacent routines. The native product now includes protocol execution, immutable history, inventory, calculators, site tracking, bounded sharing, review outputs, progress evidence, weekly review, deterministic insights, nutrition context, labs, stack dashboards, widgets, App Intents, Apple Health, rewards, and mascot continuity.

The current onboarding domain sequence has 22 steps:

1. Splash
2. Track type
3. Journey status
4. Protocol preview
5. Focus
6. Goals profile
7. Health disclaimer
8. Privacy preset
9. Premium preview
10. Trust Vault reveal
11. Companion preview
12. Readiness loop
13. System surfaces
14. Personalized unlock
15. Today command preview
16. Protocol change history
17. Review output preview
18. Migration preview
19. Trial timeline
20. Premium paywall
21. Connect apps
22. Plan ready

This is directionally right. It already protects the major strategic constraints: no diagnosis, no dosing advice, no sourcing, no marketplace, no generic AI-doctor claims, no social-feed positioning, and no protocol creation before the paywall.

The current risk is that a 22-step flow can still feel too verbal if the proof screens do not make the user feel, "This app has already done work for me."

## Recording Analysis

### Recording 01: Pep AI

Likely app: Pep AI - Peptide Tracker.

Observed flow:

- User starts inside a mostly empty logged-in app with Home, Track, Lifestyle, Profile tabs.
- Paywall appears very quickly: "Unlock Pep AI to reach your goals faster."
- Feature list is broad: peptide tracking, symptoms, application site tracker, nutrition and hydration, progress photos, journey cards, Pep Bot, sleep, Apple Health, meal scanning, achievements, AI insights.
- Annual subscription is emphasized at `$44.99/yr`; monthly is present; a later one-time discount offers `$34.99/yr`.
- After dismissing, the user can browse empty Home, Track, Lifestyle, Profile surfaces.
- Paywall interrupts repeatedly when exploring premium-looking areas.

Strengths:

- Category clarity is instant.
- The tab structure is understandable.
- The feature breadth mirrors Atlas-adjacent surfaces: inventory, meal scan, Apple Health, sleep, labs/bloodwork, achievements, reports.
- Empty surfaces expose the product map quickly.

Weaknesses:

- The first impression is mostly empty state plus paywall.
- The one-time discount feels commerce-led rather than trust-led.
- There is no meaningful personalized output before the subscription ask.
- Premium list density substitutes for proof.

Atlas implication:

Atlas should beat Pep AI by showing a prebuilt local protocol system, Trust Vault artifact, review preview, migration preview, and Day 1 plan before payment. Atlas should not copy the repeated interruptive paywall pattern.

### Recording 02: Shotsy

Observed flow:

- Starts with product utility screens: customizable widgets, theme/style personalization.
- Asks concrete GLP-1 setup questions: already taking medication, injection vs pill, medication, dose, device type.
- Shows an education screen and health disclaimer.
- Collects primary goals, height, current weight, start weight, goal weight, goal pace, activity level.
- Adds GLP-specific context: toughest days, food noise/cravings, side effects.
- Asks for rating/social proof before paywall.
- Paywall: "Unlock Shotsy+" with one-week free trial, annual `$39.99/yr`, monthly `$9.99/mo`, estimated medication charts, Apple Health import, widgets, PDF exports.
- Apple purchase sheet is standard.
- Post-purchase home lands on Summary with "Add your first shot"; then tabs for Shots, Results, Calendar, Settings.

Strengths:

- Strong domain specificity. It speaks in the user's actual journey language: dose, device, shot day, food noise, side effects.
- It asks enough to make the product feel configured.
- It uses founder authenticity and cancellation reassurance well.
- Post-onboarding first action is concrete: add first shot.

Weaknesses:

- Visually plain and form-heavy.
- The rating prompt before actual product use is questionable.
- The app after onboarding still has empty panels if no first shot is logged.
- Paywall value is narrower than Atlas but very legible.

Atlas implication:

Atlas should borrow the specificity: track type, medication context, stage, constraints, side-effect concerns, and first action. Atlas should avoid fake rating prompts and instead use artifact proof: "Here is what your provider review will contain" and "Here is how Atlas will handle a missed or changed plan."

### Recording 03: Cal AI

Observed flow:

- Opens with a polished "Calorie tracking made easy" product demo.
- Asks gender, workouts, acquisition source, previous calorie app use, height/weight, birthdate, coach, goal, blockers, diet style, desired accomplishment.
- Shows Apple Health connection and optional calorie accounting choices.
- Prompts for notifications and referral.
- Runs a loader: "We're setting everything up for you."
- Displays a generated custom plan with calories, carbs, protein, fat, health score, and supporting methodology.
- Requires account creation with Apple/Google/email.
- Shows a three-day free trial paywall after the plan is ready.
- Post-purchase app surfaces: daily ring dashboard, water logging, food database, scan food, progress, badges, groups, profile, referrals, settings, support/legal.

Strengths:

- Best "generated plan" payoff among the recordings.
- Uses clear daily targets and gives numbers, not just claims.
- Multiple logging paths solve real-life friction: photo, barcode, manual, saved foods, water.
- The home screen is immediate and action-oriented.
- Badges, groups, streaks, and referral paths create retention loops.

Weaknesses:

- Three-day trial feels tight for behavior change.
- Account wall before paywall adds friction.
- ATT prompt appears during the generated-plan moment, which interrupts trust.
- Current public reporting and review mining show major trust risk around billing design and manipulative tactics.

Atlas implication:

Atlas should absolutely borrow the "plan generated from your answers" moment, but execute it with stronger integrity: no manipulative billing, no opaque account requirement, no ATT-style interruption, and no claims that Atlas cannot medically support. The generated Atlas output should be an operations plan, not a health promise.

### Recordings 04 and 05: Quittr

Observed flow:

- Starts with a diagnostic-style question: whether the user has a problem.
- Runs a 10-question assessment around behavior frequency, triggers, escalation, age of first exposure, coping, stress, boredom, spending.
- Asks name and age.
- Uses loader states: understanding responses, learning triggers, building custom plan.
- Presents "Analysis Complete" with a dependence score and alarming red framing.
- Asks the user to select symptoms.
- Runs several fear/education screens.
- Shows social proof, press references, testimonials, goal selection, ATT prompt, rating prompt, referral, personalized plan, quit-by date, notification prompt.
- Paywall frames the product as a system, with first-seven-days preview and plan choice.

Strengths:

- Extremely high commitment-building.
- The "analysis complete" moment is memorable.
- The plan date and first-week preview make the subscription feel like a program, not a feature list.
- The flow repeatedly turns answers into user-specific narrative.

Weaknesses:

- Shame/fear tactics are ethically risky.
- Diagnostic framing is too strong.
- Privacy expectations are very high for this category, and public reporting on a 2026 Quittr Firebase exposure makes this a cautionary example.
- The paywall uses urgency/discount language in a way Atlas should avoid.

Atlas implication:

Atlas should borrow only the structural mechanics: assessment -> generated result -> plan preview -> first-week system. Do not borrow shame, diagnosis, fear, or manipulative urgency. Atlas can create a "Protocol readiness map" or "Operations risk map" without claiming medical diagnosis.

### Recordings 06, 07, and 08: Finch

Observed flow:

- Starts with "Your new self-care best friend" and lets the user hatch/select a Finch egg.
- Asks for account creation early, but Skip is visible.
- User names the pet, chooses pronouns/traits, names themself, and learns the core loop.
- Permission ask for reminders is contextual and skippable.
- Long personalization follows: age, prior use, sleep, getting out of bed, activity, overwhelm, support, mental-health challenges, support areas, confidence blockers, overwhelm sources, eating/activity/procrastination obstacles.
- Loader generates self-care goals with the named pet.
- Shows a starter plan with easy goals.
- Paywall comes after that starter plan and includes a 7-day free trial, timeline, discount, and skip.
- After purchase: community invite, acquisition source, streak commitment, widget prompt, home with goals, energy, adventure, rewards, quests, shop, pet profile, collections, evolution goals.

Strengths:

- Best emotional cold start.
- First action is playful and low-risk: choose/hatch/name a companion.
- "Not about you" personalization lowers friction by having users care for the pet.
- The starter plan solves empty-state problems.
- The app immediately gives small goals and feedback.
- Quest/shop/evolution loops create a clear long-term reward economy.

Weaknesses:

- Early account path is long.
- The experience is intentionally cute; this would be wrong if copied literally into Atlas.
- The amount of post-onboarding surface area can feel overwhelming without strong curation.

Atlas implication:

Atlas should borrow Finch's cold-start lesson, not its tone. Atlas's first useful loop should be "complete one concrete operation, see your command surface improve, receive a calm continuity signal." The mascot should remain optional and ambient, not become the product's main premise.

## Public Market and Review Findings

### Public Video and Social Flow Mining

The most reliable flow evidence came from the user's recordings because social platforms expose partial, search-biased fragments rather than full start-to-finish flows. Public mining still added useful context:

- Cal AI appears strongly social-growth-driven; TechCrunch references its rejection discussion circulating on X, its viral scale, and its acquisition by MyFitnessPal.
- Finch has a public Retention.Blog walkthrough with a linked YouTube overview, and the findings match the recorded flow: early interaction, generated starter goals, multi-screen paywall, trial reminders, and no cold empty home.
- Quittr's growth story is tightly connected to influencer/media content. Public coverage references founder YouTube activity and aggressive viral positioning; that reinforces the lesson that controversial attention can drive installs while creating trust and brand risk.
- Shotsy founder interviews and public site language lean into authenticity: built by a GLP-1 user for GLP-1 users. That authenticity is more useful for Atlas to study than generic ad tactics.

Atlas takeaway:

Use social proof only when it deepens trust. Atlas should not chase viral controversy, exaggerated transformation claims, or influencer-style urgency. The better social strategy is proof of seriousness: privacy posture, beta-user outcomes, provider-review usefulness, and real workflow screenshots.

### Direct Competitors and Adjacent GLP-1 Apps

- Shotsy App Store listing shows 21K ratings at 4.8 and positions itself around GLP-1 logging, medication levels, side effects, weight, calories, protein, water, Apple Health, privacy, and iCloud sync.
- Shotsy's official site emphasizes medication level charts, injection site rotation, side effects, weight, nutrition, reminders, Apple Health, and PDF export. This confirms that Atlas's feature set overlaps but can differentiate through immutable protocol history, review mode, migration, Trust Vault, local-first posture, and protocol change handling.
- Pep AI's App Store listing has a smaller base, 215 ratings at 4.7, but a very broad feature set: vials, dose logs, meals, sleep, bloodwork, symptoms, reminders, Apple Health, research library, AI insights, lessons, achievements, PDF reports, and verified creators.
- MeAgain positions itself around the GLP-1 week: scale, meals, shot, symptoms, protein, water, fiber, progress photos, Journey Cards, widgets, and simple routine. It reports 286K users and 16K+ App Store ratings at 4.8.
- Gila's 2026 comparison says dedicated GLP-1 apps have exploded from a small handful in early 2024 to 30+ on the App Store by April 2026. That supports treating this as a fast-moving category, not a static niche.
- Glapp, Dosefy, Gilly, DoseIQ, TrackShot, ShotClock, Pep, and peptide-specific trackers all cluster around the same core primitives: shot logging, medication level visualization, side-effect tracking, nutrition, reminders, injection sites, inventory, and progress.

Atlas takeaway:

Atlas is already broader and more serious than a simple shot tracker. The product story should not be "we also track shots." It should be "we turn a messy protocol into an inspectable local operating record."

### Calorie, Fitness, and Habit Apps

- Cal AI's App Store listing shows 306K ratings at 4.8 and a simple promise: answer lifestyle questions, snap a meal photo, get nutritional breakdown. It has a strong product promise, but current public reporting is a major warning about subscription trust.
- MyNetDiary's February 2026 review-mining scorecard says Cal AI's February reviews were heavily negative, dominated by trial-cancellation and unwanted-charge complaints, with secondary complaints around inaccurate estimates, crashes, and lack of Apple Health sync.
- TechCrunch reported on April 21, 2026 that Apple temporarily removed Cal AI after alleged App Store rule violations including bypassing IAP, deceptive billing design, and manipulative tactics. This matters because Atlas is also a subscription health app: premium conversion must be clean enough to survive user trust and App Review scrutiny.
- Finch has 683K ratings at 4.9 and an Editors' Choice designation. Its App Store listing and the recordings both point to the same strength: complete lightweight self-care actions to grow a companion and earn rewards.
- Retention.Blog's Finch teardown highlights first-screen interaction, "not about you" personalization, preset options, real product experience inside onboarding, repeated trial reminders, generated plan close-the-loop, and avoiding empty post-onboarding screens.
- Noom's 2026 RevenueCat teardown is especially relevant: it documents a web-to-app onboarding flow up to 113 screens and 10-15 minutes, where sensitive questions are framed carefully and the paywall appears only after substantial personal investment and perceived plan creation.
- Strava remains a best-in-class example for community/status, integrations, and performance data, but its privacy/location/social graph model is not Atlas's lane. The lesson to borrow is relative effort/contextual interpretation, not public feed mechanics.
- Lose It and other calorie trackers show the long-term risk of moving core actions behind ads, popups, or extra steps. In tracking apps, small logging friction compounds fast.

Atlas takeaway:

The best market pattern for Atlas is not pure gamification or pure AI. It is a carefully staged operating-system setup: personalization, plan artifact, trust artifact, first action, and ongoing context.

## Behavioral Psychology Lens

### Fogg Behavior Model

The Fogg model says behavior happens when motivation, ability, and prompt converge. Atlas should treat onboarding as the place where all three are assembled:

- Motivation: "I need a calmer way to run and explain my protocol."
- Ability: "Atlas already made the next action obvious."
- Prompt: "Here is the first thing to do today."

Current Atlas opportunity:

The 22-step flow has motivation and explanation. It needs more ability and prompt. The user should leave onboarding with one obvious task that is easier than manually building a protocol from scratch.

### COM-B

COM-B frames behavior as capability, opportunity, and motivation. Health-related tracking often fails because one of those is missing.

Atlas mapping:

- Capability: setup templates, import, migration, first protocol draft, simple logging.
- Opportunity: widgets, reminders, Apple Health, one-thumb quick capture, scheduled review.
- Motivation: trust, progress evidence, provider-ready summaries, calm companion/rewards.

Current Atlas opportunity:

Onboarding should explicitly map the user's barriers to Atlas surfaces. For example: "I miss logs" maps to Today and widgets; "I change plans" maps to Protocol Change Studio; "I need to explain this later" maps to Review Mode; "I am already mid-protocol" maps to Migration.

### Self-Determination Theory

Self-determination theory emphasizes autonomy, competence, and relatedness.

Atlas mapping:

- Autonomy: guest-first, local-first, skip Apple Health, choose privacy posture, basic path.
- Competence: show the user they can handle missed steps, inventory, review, and changes.
- Relatedness: bounded provider handoff, not social feed; optional companion for continuity.

Current Atlas opportunity:

Rewards and mascot should support competence, not replace it. The app should celebrate "you have an inspectable record" more than "you kept a streak."

### Implementation Intentions

Implementation intentions use if-then plans to connect a situation cue with a response. This is perfect for Atlas.

Atlas onboarding should produce small if-then commitments:

- If today is shot day, then Atlas reminds me discreetly and shows the dose action.
- If I miss the planned window, then Atlas shows recovery options without rewriting history.
- If I change a protocol, then Atlas keeps old logs intact and starts a new revision.
- If I need to share, then Atlas shows an inspect-before-sharing review pack.

### Gamification Evidence

Health gamification can help adoption and retention, but reviews of health apps repeatedly warn that many gamified experiences use points/badges without grounding them in behavior-change theory.

Atlas implication:

Keep rewards and mascot, but anchor them to meaningful actions: log a due action, complete a weekly review, protect privacy settings, import history, capture progress evidence, prepare a review pack. Avoid arbitrary badges that distract from serious protocol work.

## Competitor Matrix

| App | Onboarding shape | Paywall timing | Best UX move | Biggest risk | Atlas should borrow | Atlas should avoid |
| --- | --- | --- | --- | --- | --- | --- |
| Pep AI | App first, repeated premium interrupts | Very early and repeated | Broad feature visibility | Empty app plus paywall fatigue | Feature breadth clarity | Repeated surprise paywalls |
| Shotsy | Concrete GLP setup quiz | After setup, proof, reviews | Domain-specific questions | Plain, form-like UI | GLP journey language and first-shot action | Rating prompt before value |
| Cal AI | Long personal quiz, generated plan | After custom plan and account | Numeric plan artifact | Billing/trust backlash | Plan-generation payoff | Manipulative billing, ATT interruption |
| Quittr | Diagnostic quiz, result, fear education | After analysis and plan promise | Memorable "result" and plan date | Shame, diagnosis, privacy risk | Readiness map and first-week preview | Alarmist/diagnostic claims |
| Finch | Companion-first, long personalization, generated goals | After starter goals | Cold-start loop and no empty app | Too cute for serious categories | Easy first actions, companion as continuity | Pet-game framing |
| Noom | Very long structured commitment flow | After heavy personalization | Every question builds toward plan | Can feel opaque if payoff is weak | Length with payoff and rationale | Empty personalization theater |
| Strava | Fast account/connect/social setup | Mixed/in-app | Social proof and data context | Privacy/social pressure | Contextual effort interpretation | Public social feed |
| MeAgain | GLP weekly routine framing | Subscription around all-in-one tracker | Makes the GLP week readable | Marketplace adjacency | Week-based structure and Journey Cards | Sourcing/commerce emphasis |

## Atlas Strengths Versus Market

Atlas's current moat is not a single feature. It is the combination:

- Local-first and guest-first posture.
- Explicit privacy modes and Trust Vault.
- Immutable timeline and protocol change history.
- Review Mode and provider handoff outputs.
- Universal Migration for already-started users.
- Inventory runway tied to protocols.
- Today command surface for next action and recovery.
- Weekly Review and progress evidence.
- Lightweight nutrition as protocol context rather than a full calorie-counting trap.
- Optional Apple Health instead of required quantified-self sprawl.
- Optional mascot/rewards that can support continuity without becoming the brand.

This is stronger than most dedicated GLP/peptide trackers if presented correctly. The challenge is that many users will not infer the value from a feature list. The onboarding must make the operating system visible.

## Where Atlas Should Improve Onboarding

### 1. Replace "feature preview" with "assembled artifact"

Current proof screens should feel more like generated output from the user's answers. Instead of only previewing Today, Review Mode, Migration, or Trust Vault, build a single "Your Atlas setup" artifact:

- Your track: GLP, peptide, both, or custom.
- Your stage: planning, already running, changing, restarting.
- Your primary friction: missed steps, side effects, inventory, privacy, review, progress.
- Your privacy posture.
- Your Day 1 recommendation.
- Your first review artifact preview.

This can still be deterministic and safe. It does not need to recommend dosing.

### 2. Add a "Protocol Readiness Map"

Borrow Quittr's result mechanics without diagnosis. Name it something operational:

- "Your protocol readiness map"
- "Your Atlas operating map"
- "Your setup risk map"

Possible dimensions:

- Schedule clarity
- Inventory confidence
- Change-history risk
- Review readiness
- Privacy posture
- Context signal coverage

This gives users a memorable result while staying non-medical.

### 3. Make each sensitive question explain its use

Noom's long flow works because sensitive questions are framed with rationale. Atlas should do this for:

- Weight and goal weight
- Health/nutrition interest
- Medication/protocol context
- Privacy preferences
- Already-started history
- Apple Health

Short rationale lines should answer: "Why are you asking, and what will you do with it?"

### 4. Strengthen stage-based branching without shortening the flow

The flow should feel different for:

- "I have not started yet"
- "I am already mid-protocol"
- "I am changing/restarting"
- "I track multiple compounds"
- "I mainly need privacy/review"

Same total length is fine; the content should feel tailored.

### 5. Turn onboarding into a first-session setup, not just pre-app education

After paywall/basic path and optional system connection, the app should land in a Day 1 checklist:

- Add or import first protocol
- Set first discreet reminder
- Add one inventory item or skip
- Choose review/privacy mode
- Log first context/weight/symptom if relevant

This should sit on Today, not as a detached modal. It should disappear as tasks are completed.

### 6. Add first-week preview

Borrow Finch and Quittr's plan preview without gimmick:

- Day 0: choose privacy posture and first protocol/import.
- Day 1: confirm next action.
- Day 2-3: review side effects/context.
- Day 4-6: inventory and trend check.
- Day 7: weekly review and export-ready summary.

This makes premium feel like a system and sets expectations for trial value.

### 7. Make the paywall more artifact-driven

The paywall should reference what the user just saw:

- "Unlock your protocol system"
- "Keep protocol history and review packs"
- "Use Trust Vault privacy controls"
- "Bring messy history in safely"
- "Run weekly reviews"

Keep clear trial timeline. Avoid fake urgency. Keep basic path if that remains product strategy.

### 8. Add public social proof only when real

Competitors use reviews heavily. Atlas should not fake this. When beta feedback exists, add:

- "Beta testers use Atlas to..."
- Store rating once available.
- Privacy-safe testimonial snippets only with permission.
- "Built local-first" trust proof rather than vague social proof.

Until then, product proof should carry the flow.

### 9. Make Apple Health permission more like a tool choice

Apple guidance and user trust both point to asking for sensitive data only when the need is clear. Atlas should keep Apple Health optional and skippable, but strengthen the pre-permission explanation:

- What Atlas can read/write.
- Why it helps.
- What works without it.
- How to change it later.

### 10. Use the companion as "continuity signal," not "pet premise"

Finch proves companion systems can drive retention. Atlas should not become Finch. The companion should:

- Appear after the user understands Atlas as a serious tool.
- Acknowledge completion and continuity.
- Stay out of Trust Vault, Review Mode, high-stakes sharing, and protocol-change decisions.
- Be suppressible.

### 11. Improve visual proof density

The Figma feedback and prior UI audit already point here. The next onboarding version should show richer mini mockups:

- Today command surface as a live-looking card stack.
- Protocol Change Studio as a version timeline.
- Review Output as a share preview with redaction controls.
- Migration as source -> validation -> preview -> commit.
- Trust Vault as a secure mode switcher with visible state.

### 12. Instrument the funnel as product truth

Atlas already has onboarding funnel event concepts. Make sure the analysis can answer:

- Step view to step continue rate.
- Drop-off by step.
- Paywall viewed -> trial/basic choice.
- Time spent per step.
- Backtracking and secondary taps.
- Apple Health connect vs skip.
- Plan-ready -> first action completed.
- Day 1, Day 3, Day 7 retention by onboarding path.

## Atlas App UX Recommendations Beyond Onboarding

### Today

Today is the core product. It should become even more like a protocol system:

- One primary action should dominate.
- "Why this matters now" should be compact and specific.
- Recovery states should be highly tactile and reassuring.
- Day 1 checklist should live here until activation is complete.
- Completion feedback should be stronger than a normal form save.

### Timeline

The immutable history concept is strong but can become visually repetitive.

Recommended:

- Stronger date grouping and revision markers.
- Protocol-change badges that make history legible.
- Quick filters for "dose", "context", "inventory", "review", "change".
- A "what changed since last review" summary.

### Library

Library should feel like owned protocol infrastructure, not a tools drawer.

Recommended:

- Protocol cards with stage, next due, inventory runway, and latest revision.
- Separate "My protocols" from "Tools".
- Make creation/import the two obvious entry points.
- Add a guided "already started" import path from onboarding.

### Insights

Insights should avoid becoming a wall of equal tiles.

Recommended:

- Make the primary insight contextual to the user's active protocol.
- Separate capture actions from interpretation surfaces.
- Highlight "explainable" insights with source facts.
- Put nutrition in a protocol-adjacent lane, not a full diet-app clone.

### Trust Vault

This is one of Atlas's signature surfaces and should feel more flagship.

Recommended:

- Stronger header state: local-only, protected, discreet, alias, export-ready.
- More ceremony for high-consequence actions.
- Plain-language preview of what changes in discreet/alias mode.
- A reusable trust-state component across Settings, Review Mode, exports, and onboarding.

### Review Mode

Review Mode is a premium differentiator. It should feel less like configuration and more like a workflow.

Recommended:

- Step 1: choose purpose.
- Step 2: choose scope.
- Step 3: inspect preview.
- Step 4: create/export/share.
- Always show what is excluded as clearly as what is included.

### Migration

Migration can be a major Atlas conversion wedge for users already mid-protocol.

Recommended:

- Make source, validation, preview, and commit visually distinct.
- Highlight restore point before commit.
- Use "imperfect history is okay" language.
- Allow a lightweight "start from current state" path.

### Nutrition and Meal Capture

Atlas should not chase Cal AI directly. It should win on context.

Recommended:

- Phrase nutrition as "protocol context".
- Use meal photo parsing to reduce logging friction, not to promise perfect macros.
- Surface protein, hydration, appetite, GI, and timing as explanatory context around protocol outcomes.

### Widgets and System Surfaces

Finch and Shotsy both show widgets during onboarding. Atlas should do the same, but with serious utility:

- Next due
- Discreet reminder state
- Quick log
- Weekly review ready
- Progress evidence reminder

### Rewards and Mascot

Rewards should reflect meaningful operational continuity:

- First protocol created or imported
- First on-time log
- First recovery handled without rewriting history
- First inventory runway set
- First review pack generated
- First weekly review completed

Avoid rewards for sheer app opening if it creates pressure.

## Recommended Next Onboarding Structure

This preserves the long flow but makes the payoff clearer:

1. Atlas promise: "Run your protocol from a private local protocol system."
2. Track type and stage.
3. Current reality: not started, already running, changing, restarting, multi-protocol.
4. Primary friction: schedule, inventory, privacy, review, symptoms/context, nutrition, progress.
5. Minimal profile/goals, with rationale.
6. Health disclaimer.
7. Privacy posture and Trust Vault preview.
8. Protocol operations preview.
9. Generated "Protocol Readiness Map."
10. Generated Day 1 plan.
11. Today command preview using the user's selected friction.
12. Protocol Change Studio proof.
13. Review Output proof.
14. Migration proof, especially for already-started users.
15. Weekly Review/progress evidence proof.
16. Companion/rewards continuity, optional and calm.
17. System surfaces/widgets preview.
18. Trial timeline.
19. Paywall.
20. Optional Apple Health/system permissions.
21. Plan ready.
22. Today with Day 1 activation checklist.

## Prioritized Backlog

### Highest leverage

1. Add Protocol Readiness Map after the current personalized unlock.
2. Make the plan-ready screen produce a Day 1 checklist in Today.
3. Make proof screens visibly use selected answers.
4. Redesign the paywall around the user's generated artifact and clear trial timeline.
5. Add first-week preview before paywall.

### Next

6. Improve stage branching for already-started and changing/restarting users.
7. Strengthen Trust Vault and Review Mode visual proof.
8. Add richer widget/system-surface onboarding.
9. Add onboarding rationale lines for sensitive questions.
10. Instrument activation beyond onboarding completion.

### Later

11. Add real beta social proof after permission.
12. Add comparative "month in review" artifact to onboarding.
13. Add in-app education snippets only where they directly support a user action.
14. Add a carefully bounded care-team/export narrative without turning Atlas social.

## What Not To Do

- Do not shorten onboarding just because it is long.
- Do not copy Finch's pet-first identity.
- Do not copy Quittr's shame, diagnosis, or fear tactics.
- Do not copy Cal AI's aggressive or disputed billing patterns.
- Do not move exact protocol/dosing setup before the paywall unless product strategy changes.
- Do not make Apple Health required.
- Do not turn nutrition into the main product.
- Do not introduce social feeds, public leaderboards, or marketplace/sourcing flows.
- Do not make rewards the reason to use Atlas. They should reinforce serious utility.

## Measurement Plan

Activation should be measured in layers:

- Onboarding completion rate.
- Trial start or basic path choice.
- First protocol created/imported.
- First due action logged.
- First reminder configured.
- First Trust Vault/privacy mode selected.
- First inventory item added.
- First weekly review opened.
- First review/export artifact generated.
- Day 1, Day 3, Day 7, Day 14 return.

The most important metric is not "finished onboarding." It is "finished onboarding and completed one meaningful Atlas operation."

## Source Notes

- Apple App Store: [Shotsy GLP-1 Tracker](https://apps.apple.com/us/app/shotsy-glp-1-tracker/id6499510249)
- Shotsy official site: [shotsyapp.com](https://shotsyapp.com/)
- Apple App Store: [Cal AI - Calorie Tracker](https://apps.apple.com/us/app/cal-ai-calorie-tracker/id6480417616)
- TechCrunch: [Apple's Cal AI crackdown](https://techcrunch.com/2026/04/21/apples-cal-ai-crackdown-signals-its-still-policing-the-app-store/)
- MyNetDiary: [Diet App Scorecard February 2026](https://www.mynetdiary.com/diet-app-scorecard-february-2026.html)
- Apple App Store: [Finch: Self-Care Pet](https://apps.apple.com/us/app/finch-self-care-pet/id1528595748)
- Retention.Blog: [Life of a birb](https://www.retention.blog/p/life-of-a-birb)
- Apple App Store Australia: [QUITTR - Break Free Now](https://apps.apple.com/au/app/quittr-break-free-now/id6532588521)
- Quittr official site: [quittrapp.com](https://quittrapp.com/)
- Journal de Quebec coverage of Quittr exposure: [Quittr data exposure report](https://www.journaldequebec.com/2026/03/11/lappli-quittr-censee-stopper-la-dependance-a-la-porno-expose-les-habitudes-sexuelles-de-milliers-dutilisateurs)
- RevenueCat: [Inside Noom's Web-to-App Onboarding Funnel](https://www.revenuecat.com/blog/growth/web-to-app-onboarding-funnel/)
- Adapty: [High-performing paywall in 2026](https://adapty.io/blog/high-performing-paywall-2026/)
- Apple Developer HIG: [Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy/)
- Apple Developer: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Stanford Behavior Design Lab: [Fogg Behavior Model](https://behaviordesign.stanford.edu/resources/fogg-behavior-model)
- BMC Public Health: [COM-B across eating and physical activity contexts](https://link.springer.com/article/10.1186/s12889-021-11019-w)
- University of Minnesota Conservancy: [Self-Determination Theory-Based Wellness App](https://conservancy.umn.edu/items/35a66792-c5b1-4281-81b4-75f640841d42)
- NIH/NCI: [Implementation Intentions](https://cancercontrol.cancer.gov/brp/research/constructs/implementation-intentions)
- JMIR Serious Games: [Just a Fad? Gamification in Health and Fitness Apps](https://pmc.ncbi.nlm.nih.gov/articles/PMC4307823/)
- PubMed: [Gamification Use and Design in Popular Health and Fitness Mobile Applications](https://pubmed.ncbi.nlm.nih.gov/30049225/)
- MeAgain: [Weight-loss tracker built around the GLP-1 week](https://meagain.com/weight-loss-tracker-app)
- Gila: [Best GLP-1 Tracking Apps Compared 2026](https://gila.coach/learn/best-glp1-tracking-apps-compared-2026)
- Garage Gym Reviews: [Strava Fitness App Review](https://www.garagegymreviews.com/strava-fitness-app-review)

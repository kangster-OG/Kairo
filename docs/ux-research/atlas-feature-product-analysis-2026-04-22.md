# Atlas Feature And Product Analysis

Date: 2026-04-22

This note captures the current app feature inventory, competitor recording review, and a proposed product direction for a mascot-forward peptide protocol tracking overhaul.

## Source Material

- Repo: `/Users/donghokang/Developer/Atlas`
- Recordings copied into: `docs/ux-research/competitor-recordings/`
- Extracted frames, OCR, and contact sheets: `docs/ux-research/competitor-frame-analysis/`
- Extraction helper: `docs/ux-research/extract_recording_frames.swift`

Method used:

- Copied all eight supplied recordings into the repo.
- Extracted one frame per second from each recording.
- Ran local Vision OCR over each extracted frame.
- Built contact sheets from all extracted frames for dense review.
- Reviewed the contact sheets visually and cross-checked app copy through OCR.

Frame inventory:

| Recording | Duration | Frames | App observed |
| --- | ---: | ---: | --- |
| `13-43-08` | 56.57s | 57 | Pep AI |
| `13-48-12` | 95.61s | 96 | Shotsy |
| `13-53-26` | 230.67s | 231 | Cal AI |
| `15-09-05` | 233.65s | 234 | Finch |
| `15-17-54` | 71.81s | 72 | Finch continuation |
| `15-19-23` | 18.78s | 19 | Finch collections |
| `23-15-10` | 85.32s | 86 | Pepty onboarding/paywall |
| `23-16-47` | 158.61s | 159 | Pepty app |

## What Kind Of App Atlas Is

Atlas should be understood as a comprehensive peptide protocol companion, not primarily as a privacy app.

The best one-line product description is:

> Atlas is a peptide protocol tracking protocol system that helps users run, log, understand, and stay consistent with protocols while growing a companion that reflects their progress.

That keeps the important boundaries intact:

- Atlas is not a marketplace, sourcing app, social network, medical advice app, dosing advice app, or diagnostic app.
- Atlas can track protocols, injections, schedules, inventory, symptoms, body changes, nutrition context, workouts, labs, and review-ready summaries.
- Atlas can present educational and reference material as tracking context, but should avoid claims that it recommends doses, diagnoses symptoms, or optimizes treatment.
- Privacy remains a proof point and safety layer, but it should no longer be the lead differentiator in the user-facing story.

## Current Atlas Feature Inventory

Atlas already has a much broader product surface than a simple shot tracker.

| Area | Current Atlas capability | Strategic read |
| --- | --- | --- |
| Protocol core | GLP, peptide, and custom protocol types; injection/oral/sublingual/nasal/topical/transdermal routes; daily/weekly/every-N-days cadence; dose units and notes | Strong foundation. Needs simpler setup and clearer protocol-native framing. |
| Today | Due, overdue, upcoming, next-action command deck, recovery/guidance cards, queue overview | Strong but dense. It should become the obvious first screen: mascot, next shot, protocol status, one action. |
| Quick capture | Shot, weight, symptom, hydration, protein, progress photo; shortcuts and richer context flows | Strong ingredients. Needs a Shotsy/Cal AI style center action and faster shot/food/workout capture. |
| Injection tracking | Mark taken/skip/reschedule, site options, site map, site rotation/inventory hooks | Useful but currently not surfaced as the hero flow. Shot logging needs site, pain, note, side effects, and inventory decrement in one simple capture lane. |
| Medication levels | Half-life and schedule-window estimates | Competitive against Shotsy. Should become a core protocol visualization, not a buried clinical extra. |
| Compound intelligence | Compound knowledge and reference screens | Competitive against Pepty. Must stay educational/reference, not advice. |
| Inventory | Vials, consumables, low stock, projected depletion, label scan preview, procurement review, linked protocols | Differentiating. Should be connected to shot capture and widgets. |
| Calculators | Reconstitution and dosage/unit calculator profiles | Competitive against Pepty. Needs clearer safety language and simpler entry. |
| Nutrition | Meal timing, meal size, composition, fed state, appetite, hydration, GI tags, local food lookup, package code suggestions, typed/voice meal parsing, photo OCR/image cues, protein/fiber/hydration targets | Promising but not yet a Cal AI competitor. Needs calorie/macros optionality, scan-first capture, daily rings, favorites, and less "context" wording. |
| Workout/fitness | Recent workout entries from health data, workout insight section, weekly workout reward goal | Underdeveloped as a first-class feature. Needs manual workout logging, HealthKit import clarity, weekly plan/progress, strength/cardio templates. |
| Weight/progress | Weight trends, symptoms, custom metrics, progress photos, guided recapture, comparisons | Strong. Should sit in a Progress hub alongside mascot evolution and protocol adherence. |
| Rewards | Points, levels, badges, streaks, goals, next level thresholds | Strong but too quiet. It should be the visible growth engine for the mascot. |
| Mascots | Aetherion/Aurielle stages, evolution history, moments, recap media, ambient perch, bottom-tab motion, widget art | Major differentiator. Needs to become central, with stronger progression mechanics and emotional payoff. |
| Widgets/intents | Next due, quick capture, progress evidence, inventory, mascot widgets, widget actions | Competitive. Should be marketed as a main utility pillar. |
| Weekly review | Action plans, weekly focus, payoff cards, archive | Valuable. Should feed companion growth and user progress. |
| Trust Vault/privacy | Render modes, aliases, selective share, audits, review workspaces | Important support layer. Currently over-weighted relative to the product the user wants. |
| Onboarding | Long DREAM onboarding, readiness map, Day 1 plan, Trust Vault defaults, companion reveal | Valuable but should emphasize peptide setup, first protocol, and companion progression more than privacy. Do not shorten the 180-state direction by default. |

## Current Product Problem

Atlas has a strong feature set, but the app reads more like a premium privacy-first protocol workspace than the ultimate peptide tracker.

The current hierarchy creates three problems:

- The lead message is trust/privacy, while the user wants protocol mastery, simplicity, and companion progression.
- High-value features are distributed across Today, Library, Insights, Inventory, Rewards, Mascot, Trust Vault, and Settings, which makes the app feel broader than it feels obvious.
- Nutrition, workout, and injection tracking exist, but they do not yet feel as sharp or effortless as the competitor flows that specialize in those domains.

The product should shift from "private protocol system" to "peptide protocol companion." Privacy should support confidence after the user already understands why Atlas is useful.

## Competitor Recording Findings

### Shotsy

Observed strengths:

- Very simple, dark, focused onboarding.
- One question per screen.
- Domain-specific setup for GLP-1 users: medication, dose, device, frequency, goals, weight, food noise, side effects, Apple Health.
- Clear medication-level chart as a hero feature.
- Strong widget pitch.
- Shot logging is obvious: date/time, medication, dosage, injection site, pain level, notes.
- Calendar day view combines shot, estimated level, weight, calories, protein, side effects, and notes.

Strategic lesson for Atlas:

- Shotsy wins on simplicity and immediacy.
- Atlas should borrow the one-screen-one-job flow, medication-level hero, shot-day focus, and calendar clarity.
- Atlas can beat Shotsy by being peptide-native beyond GLP-1, adding inventory/calculators/compound reference, nutrition/fitness depth, and mascot progression.

### Cal AI

Observed strengths:

- Opening demo shows the product before asking for effort.
- Fast onboarding creates a personalized plan.
- Home is highly legible: calories left, macro cards, date strip, plus action.
- Food capture offers camera, barcode/label scan, search, saved foods, manual, voice, and exercise logging.
- Water logging produces immediate badge feedback.
- Progress includes streaks, badges, weight, milestones, calories, energy, BMI, photos.
- Apple Health and widgets are treated as meaningful product extensions.

Strategic lesson for Atlas:

- Cal AI makes nutrition feel fast and rewarding.
- Atlas nutrition should stop feeling like "context logging" as the primary frame. It should feel like food/protein/hydration capture that happens to enrich protocol insight.
- Atlas does not need to become a pure calorie app, but calorie/macros should be available as optional precision for users who want it.

### Finch

Observed strengths:

- The companion is the operating system, not a decoration.
- The pet hatches, gets named, gains traits, speaks in lightweight bubbles, and remains visible during onboarding.
- Onboarding creates support areas and daily goals, then converts them into daily actions.
- Daily task completion gives visible energy, stones/currency, streaks, celebration, and growth.
- The app contains quests, seasonal journeys, shops, outfits, furniture, locations, friends, collections, micro-pets, widgets, newsletters, and profile history.
- Growth is visible: baby state, toddler unlock, progress gates, countdowns, and collectible rewards.

Strategic lesson for Atlas:

- Atlas's mascot can be the emotional differentiator against utilitarian peptide trackers.
- The mascot should represent protocol consistency, healthy support behaviors, and user progress.
- Rewards should never incentivize risky dosing. Reward logging, preparation, recovery handling, check-ins, reviews, hydration, workouts, meal capture, and progress evidence.

### Pepty

Observed strengths:

- Very peptide-native from the first screen.
- Onboarding asks why the user came, goals, experience, compounds of interest, biggest frustration.
- Compound catalog spans GLP/weight, cosmetic, growth, hormonal, repair, neuro, immune, longevity, other.
- Tools include vendors/supplies, reconstitution calculator, dosage/unit converter, half-life reference charts, injection site rotation tracker, and peptide interaction checker.
- Dashboard includes today's schedule, active compounds, next up, research cycle, logged/streak cards.

Strategic lesson for Atlas:

- Pepty proves there is demand for peptide-native breadth.
- Atlas should match or exceed the useful tracking/tool coverage while being more approachable and more emotionally distinctive.
- Pepty's utilitarian dark UI leaves room for a clearer, friendlier, premium Atlas experience.

### Pep AI

Observed strengths:

- Broad feature list: peptide tracking, symptoms, application sites, nutrition/hydration, progress photos, Pep Bot, sleep, Apple Health, meal scanning, achievements, AI insights.
- Central plus menu exposes Add Peptide, Add Schedule, Log Dose, Log Weight, Progress Photos, Daily Check-in, Calculator, Meal Scan.
- Lifestyle tab groups nutrition, weight, photos, activity, sleep, bloodwork, side effects, and check-ins.

Strategic lesson for Atlas:

- Broad protocol + lifestyle coverage is table stakes for the category.
- Atlas should avoid feeling like a generic AI health utility. The mascot and protocol mastery loop should make it feel authored.

## Recommended Product Thesis

Atlas should become:

> The ultimate peptide protocol app: simple enough for the next shot, comprehensive enough for the whole protocol, and motivating enough that progress feels alive.

The new product hierarchy should be:

1. Protocol tracking: what am I taking, when, how much, where, and what happened?
2. Companion progression: how does my consistency and evidence turn into visible growth?
3. Lifestyle support: food, hydration, workouts, weight, symptoms, progress photos, labs, and HealthKit.
4. Tools and reference: medication levels, calculators, compound education, inventory, interactions, summaries.
5. Trust/privacy: aliases, local-first storage, selective sharing, review-safe exports.

Privacy should move from the headline to the trust layer:

- Visible in settings, export/share flows, onboarding assurance moments, and sensitive screens.
- Not the main first impression, paywall hook, or primary emotional promise.

## Proposed Information Architecture

Recommended bottom navigation:

| Tab | Purpose | Contents |
| --- | --- | --- |
| Today | The one-screen daily protocol system | Mascot, next shot, med-level mini chart, quick rings, inventory alert, next action |
| Log | Fast capture | Shot, food, workout, weight, symptom, hydration, photo, custom metric |
| Protocols | The protocol library | Active protocols, calendar, medication levels, inventory, calculators, compound reference |
| Progress | Proof and trends | Weight, photos, adherence, symptoms, nutrition, workouts, labs, weekly review |
| Companion | Mascot and rewards | Evolution, quests, badges, habitat/items, moments, widgets |

Settings, Trust Vault, import, account, services, and privacy controls can live behind profile/settings rather than occupying prime product hierarchy.

Alternative if five tabs feels too much:

- Today
- Log
- Protocols
- Progress
- Profile

In this version, Companion is a persistent header/widget inside Today and Progress plus a first row in Profile. This is simpler, but weaker for mascot emphasis.

## Mascot-Forward System

The mascot should become a visible representation of user progress.

Core loop:

1. User completes a protocol-supporting action.
2. Atlas confirms the action quickly.
3. Companion reacts.
4. User earns XP, stones, energy, or a similar progression unit.
5. Progress fills toward a level, trait, item, form, or chapter unlock.
6. Weekly review converts the week into a recap, badge, or evolution moment.

Rewardable actions:

- Log a scheduled dose.
- Log the injection site and complete site rotation.
- Capture a symptom or side effect signal.
- Log protein, fiber, hydration, or a meal photo.
- Complete or import a workout.
- Add a progress photo on schedule.
- Review inventory before depletion.
- Complete a weekly review.
- Export a clean summary.
- Keep a safe streak of tracking and review.

Actions that should not be rewarded:

- Taking more than scheduled.
- Changing doses without review context.
- Ignoring symptoms.
- Any behavior that could read as medical optimization advice.

Mascot features to add or emphasize:

- Evolution tree with visible thresholds.
- Protocol mastery badges by protocol, not just generic points.
- Daily quests generated from the user's protocol and goals.
- Companion habitat or capsule that changes with consistency.
- Collectible items tied to tracking categories: hydration, protein, strength, recovery, site rotation, review.
- Widgets that show the companion plus next action.
- Celebration sheets after meaningful streaks, weekly reviews, and form unlocks.
- Trait/personality selection during onboarding, inspired by Finch but mapped to protocol style: steady, curious, focused, resilient, precise.

The companion should awaken only after Atlas has built enough readiness map, Day 1 plan, Trust Vault defaults, and first-week preview. The current DREAM direction can stay long, but its emotional center should shift toward "your protocol companion is forming from your plan."

## Simplicity Principles

Use Shotsy as the simplicity reference:

- One primary action per screen.
- One question per onboarding step.
- No abstract internal nouns on first exposure.
- Show the user their actual next shot/protocol before showing modules.
- Keep advanced tools one tap away, not on the first card.
- Use "Shot", "Food", "Workout", "Progress", "Protocol" before "context", "signals", "review lanes", or "vault".

Suggested copy shifts:

| Current flavor | Stronger direction |
| --- | --- |
| "Privacy-first protocol system" | "Your peptide protocol, made easy to follow." |
| "Trust Vault" as lead | "Private by default" as proof |
| "Log context" | "Log food" / "Log hydration" / "Log how you felt" |
| "Insights" as a tab | "Progress" or "Trends" |
| "Command surface" | "Today" / "Next action" |
| "Calm continuity" | "Streaks" / "Consistency" / "Companion progress" |

## Feature Strengthening Recommendations

### Injection Tracking

Build the shot log as the category-defining flow:

- Default to the next scheduled shot.
- Show protocol name, dose, route, time, and estimated level mini chart.
- Let the user select site with a body map.
- Include pain level, side effects, notes, and optional photo.
- Show last used sites and rotation suggestion without giving medical advice.
- Auto-decrement linked inventory.
- Award companion XP for complete logs and site rotation.
- Provide a day calendar view similar to Shotsy: shot, med level, weight, food, workout, symptoms, notes.

### Nutrition

Make food tracking simple first, detailed second:

- Home ring/cards for protein, hydration, calories/macros if enabled.
- Capture methods: camera, barcode/label, voice/text, favorites, manual.
- Keep protein/fiber/hydration as peptide-relevant defaults.
- Add optional calories/macros for users who expect Cal AI-like power.
- Capture appetite, food noise, nausea/GI, and meal timing as context attached to protocol days.
- Add meal streaks and badges that feed companion growth.

### Workout/Fitness

Make fitness a real pillar:

- HealthKit import as a setup win, not a settings-only utility.
- Manual workout logging: strength, cardio, walking, custom.
- Weekly workout goal with visible progress.
- Workout cards in Today when relevant.
- Recovery/support copy should avoid medical claims.
- Companion can gain energy from workouts and recovery behaviors.

### Progress

Create a proof-led Progress hub:

- Weight trend.
- Body/progress photo compare.
- Adherence calendar.
- Medication-level history.
- Nutrition and workout streaks.
- Symptom trend.
- Weekly review archive.
- Companion evolution timeline.

### Protocol Tools

Move advanced peptide tools into a clear Protocols/Tools area:

- Compound library.
- Medication levels.
- Half-life reference.
- Reconstitution calculator.
- Dose/unit converter.
- Inventory and low-stock runway.
- Site rotation.
- Interaction checker only with careful "reference only" language.

## DREAM Onboarding Reframe

Do not shorten the 180-state DREAM direction by default. Instead, change the emphasis.

The onboarding should feel like:

1. Choose or create your companion seed.
2. Build your first protocol map.
3. Set the next shot and schedule.
4. Choose support goals: food, hydration, workouts, weight, symptoms, progress photos.
5. Configure capture style: fast/simple vs detailed.
6. Preview Day 1.
7. Preview first-week quests.
8. Set private defaults quietly.
9. Companion awakens because the protocol map is ready.
10. Home opens with one clear next action.

Borrow from competitors:

- Shotsy: direct medication/schedule questions.
- Cal AI: plan-generation payoff.
- Finch: companion hatching/growth emotional payoff.
- Pepty: peptide-native goals and compounds of interest.

## Suggested UI Concepts For Image Generation

### Concept 1: Atlas Today

Goal: show the new first screen.

Visual requirements:

- iPhone app screen mockup.
- Mascot-forward header with evolved companion visible.
- Next shot card with protocol, dose, time, and "Log shot" action.
- Medication-level mini curve.
- Three compact daily support rings: protein, hydration, workout.
- Inventory runway pill.
- Bottom navigation: Today, Log, Protocols, Progress, Companion.
- Premium, tactile, clean, not generic medical.

### Concept 2: Shot Capture

Goal: show the category-defining injection log.

Visual requirements:

- iPhone app screen mockup.
- Shot capture sheet for a peptide protocol.
- Dose/time/site selection.
- Body injection-site map.
- Pain slider, side effects chips, optional notes.
- Linked vial inventory decrement preview.
- Small companion reward banner: "Complete log +12 XP".
- Clear "Mark taken" primary action.

### Concept 3: Companion Progress

Goal: show the gamification hub.

Visual requirements:

- iPhone app screen mockup.
- Companion centered with evolution progress.
- Evolution path with locked future form silhouettes.
- Daily quests: log shot, protein meal, workout, progress photo.
- Badges and collectible items.
- Weekly protocol mastery card.
- Energetic but premium, more Finch/Pokemon-inspired than generic health app.

## Recommended Roadmap

### Phase 1: Product Hierarchy Reset

- Rename/reframe key surfaces around peptide protocol tracking.
- Make Today start with mascot + next shot + one action.
- Move privacy/trust from hero to support layer.
- Add a central Log action or Log tab.
- Audit copy for abstract/internal terms.

### Phase 2: Shot Capture Upgrade

- Build a richer but still fast shot log.
- Add site map, pain, notes, side effect chips, inventory decrement, and reward feedback.
- Surface med-level mini chart around shot day.
- Add a calendar day summary.

### Phase 3: Mascot Growth System

- Make rewards enabled and visible by default after onboarding.
- Add daily quests tied to actual protocol-support behaviors.
- Add evolution path, collectible unlocks, and weekly recap moments.
- Strengthen widget companion use.

### Phase 4: Nutrition And Fitness Upgrade

- Add Cal AI-style food capture options while keeping peptide relevance.
- Add optional macros/calories.
- Add HealthKit setup and manual workout logging.
- Feed food/workout progress into companion growth.

### Phase 5: Protocol Tools Polish

- Consolidate inventory, calculators, medication levels, and compound reference.
- Make advanced tools easy to find without cluttering Today.
- Keep reference/advice boundaries clear.

## Bottom Line

Atlas should not compete as "the privacy peptide app." It should compete as the most complete and motivating peptide protocol app.

The strongest direction is:

- Shotsy simplicity for shots and setup.
- Cal AI speed for food and daily tracking.
- Finch emotional loop for companion growth.
- Pepty peptide-native breadth for tools and reference.
- Atlas's own premium polish, local-first trust layer, widgets, inventory, review outputs, and evolved mascot system.

If executed well, Atlas becomes the app for someone who wants more than a shot log: they want a full protocol cockpit that is easy enough to use every day and rewarding enough to keep using.

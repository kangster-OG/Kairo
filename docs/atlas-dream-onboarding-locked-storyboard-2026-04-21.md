# Atlas Dream Onboarding Locked Storyboard - 2026-04-21

This is the build-ready storyboard for the dream Atlas onboarding.

It assumes the direction already established in the Cal AI, Finch, Shotsy, Quittr, Noom, and broader health app research:

- Borrow Cal AI's immediate live product demo, one-question clarity, generated plan payoff, and concrete dashboard landing.
- Borrow Finch's emotional personalization, companion hatching payoff, no-empty-home loop, long progress rail, and reward loop.
- Borrow Shotsy's medication-specific setup depth, but make it more private, more operational, and less narrow.
- Borrow Quittr and Noom's assessment-to-plan mechanics, but avoid shame, diagnosis, fear, or manipulative urgency.
- Keep Atlas's strongest differentiators: private local-first setup, Trust Vault, Protocol Change Studio, Review Output, Universal Migration, rewards, mascots, health connections, and a real Day 1 command center.

The locked target is intentionally long:

**180 user-facing storyboard states across 12 chapters.**

This should not become 180 Swift enum cases. The build should use about 43 SwiftUI scenes with internal substeps, carousels, staged reveals, and generation phases.

## North Star

Atlas should feel like a private protocol operating system assembling itself around the user's real life.

The companion should not be the first thing the user sees. The companion should hatch only after Atlas has earned it by collecting context, building the privacy posture, generating the readiness map, and preparing the Day 1 plan.

The emotional beat is:

1. "This app understands the operational mess I am managing."
2. "It built a private system around my situation."
3. "Now my Atlas has awakened."
4. "I have an actual Day 1 command center, not an empty app."

## Visual Thesis

Atlas should feel like an advanced private control room, softened by a warm companion system.

The material language is glass, paper, sealed containers, clean instrument panels, and quiet status lights. It is not bubbly, childish, or maximalist. The companion can feel alive, but the product shell stays adult, precise, and trustworthy.

## Interaction Thesis

1. Every answer changes a visible "Atlas draft" artifact.
2. Every chapter ends with a generated payoff, not just a Continue button.
3. Every major transition should feel like the operating system is assembling: cards lock into place, surfaces redact, maps calibrate, and the companion awakens from the finished system.

## Non-Negotiables

- Do not change the avatar design direction.
- The hatch is a presentation layer only: egg, capsule, signal core, sealed orb, or protected vessel that opens into the existing companion.
- Do not use shame, diagnosis, medical claims, sourcing claims, or dosing advice.
- Do not interrupt the generation sequence with ATT, analytics, or unrelated permission prompts.
- Do not make Apple Health required.
- Do not land the user in an empty app.
- Do not put the companion inside sensitive Trust Vault, Review Output, or protocol-change decisions unless it is clearly suppressed and non-speaking.
- Do not hide billing details.
- Do not place the paywall before showing meaningful personalized output.

## Build Model

Recommended structure:

- `AtlasOnboardingSceneID`: data-driven scene identifier for the 43 build scenes.
- `AtlasOnboardingSceneState`: local substep state within a build scene.
- `AtlasOnboardingJourney`: computes the 180 visible states from the draft.
- `AtlasOnboardingDraft`: extended with friction, privacy, companion, plan, and activation fields.
- `AtlasProtocolReadinessMap`: deterministic generated output from answers.
- `AtlasOnboardingFirstWeekPlan`: deterministic seven-day plan preview.
- `AtlasDayOneChecklistItem`: seeded into the real Today command center after onboarding.

Keep the current `AtlasOnboardingStep` temporarily as a compatibility wrapper if needed, but the dream build should be scene-driven so the flow can stay long, skippable where appropriate, resumable, testable, and easy to reorder.

## 43 Build Scenes

| Build scene | Internal beat range | Purpose |
| --- | ---: | --- |
| Live product demo | 1-7 | Show the real product before asking for trust. |
| Private start | 8-12 | Establish local-first setup and account boundary. |
| Safety boundaries | 13-18 | State medical and privacy boundaries calmly. |
| Calibration intro | 19-22 | Explain why the long setup is worth it. |
| Track type | 23-26 | Identify GLP, peptide, both, custom, or exploring. |
| Journey status | 27-30 | Understand whether the user is starting, active, changing, or migrating. |
| Current system | 31-34 | Learn how messy the current tracking context is. |
| Route and routine | 35-39 | Capture operational route and cadence without dosing advice. |
| Protocol family | 40-45 | Collect GLP or peptide category specifics. |
| Protocol complexity | 46-50 | Measure multiple items, titration, supplies, and uncertainty. |
| Operating concern | 51-54 | Map the biggest immediate operational problem. |
| Goal north star | 55-59 | Capture outcome goals without diagnosis. |
| Body context | 60-65 | Optional body details for tracking and nutrition personalization. |
| Nutrition context | 66-72 | Food, protein, water, appetite, and logging preferences. |
| Health evidence | 73-78 | Apple Health interest, progress signals, and review outputs. |
| Goal recap | 79-82 | First generated chapter payoff. |
| Friction intro | 83-85 | Frame friction as design input, not personal failure. |
| Schedule friction | 86-91 | Find timing risks. |
| Logging friction | 92-96 | Find capture risks. |
| Recovery friction | 97-102 | Choose what should happen after missed or messy days. |
| Privacy friction | 103-107 | Identify discretion and sharing needs. |
| Support style | 108-112 | Tune reminder, companion, and encouragement style. |
| Friction recap | 113-116 | Second generated payoff. |
| Trust intro | 117-119 | Introduce Trust Vault as product value. |
| Privacy posture | 120-124 | Choose visible privacy mode. |
| Trust demo | 125-130 | Show live redaction, aliasing, labels, and notifications. |
| Sharing boundaries | 131-134 | Configure review and export posture. |
| Vault seal | 135-138 | Lock privacy posture into the system. |
| Generation sequence | 139-148 | Build the user's Atlas with visible progress. |
| Companion hatch | 149-158 | Existing companion awakens from generated system. |
| Companion personalization | 159-168 | Name, color, role, and presence. |
| Readiness reveal | 169-173 | Reveal Protocol Readiness Map. |
| Readiness detail | 174-183 | Drill into dimensions and gaps. |
| Day 1 priority | 184-188 | Let user choose first setup priority. |
| Proof tour | 189-204 | Interactive tour of Today, Trust Vault, Review, Migration, Protocol Change, Inventory, and Evidence. |
| First-week plan | 205-216 | Show seven-day no-empty-home plan. |
| Trial and paywall | 217-229 | Transparent trial, value, plan selection, and basic path. |
| Permissions | 230-239 | Notifications, Health, widgets, and account prompts only after value. |
| Day 1 handoff | 240-250 | Morph onboarding into the real Today command center. |

Note: The table above uses 250 internal beats so the storyboard can include animation and transition beats. The user-facing progression should display these as **180 tappable or timed states** by combining quick animation-only beats into the same state. The implementation inventory below is the canonical 180-state user-facing version.

## Canonical 180-State Storyboard

Each state should have a visible progress rail and a small chapter marker. The first chapter can hide numeric progress for drama, but the long setup should show progress once calibration begins.

### Chapter 1 - Operating System Fantasy

Goal: Show the real Atlas promise before asking questions. No mascot yet.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 1 | Atlas hero | Tap Build my Atlas or Continue privately | Phone mockup rises, Today card breathes once | No data write |
| 2 | Today demo | Swipe or auto-advance | Today card expands from date rail into action stack | Demo only |
| 3 | Trust Vault demo | Swipe or auto-advance | Labels redact with a left-to-right privacy wipe | Demo only |
| 4 | Review Output demo | Swipe or auto-advance | Share preview assembles, redaction toggles animate | Demo only |
| 5 | Migration demo | Swipe or auto-advance | Messy source notes become clean timeline rows | Demo only |
| 6 | Protocol Change Studio demo | Swipe or auto-advance | Before and after cards slide into a version timeline | Demo only |
| 7 | Product promise | Continue | Five Atlas surfaces fan out, then lock into a stack | Record `productDemoCompleted` |
| 8 | Private start | Choose Continue privately or Sign in later | Device icon lights first, backup cloud stays dim | `accountMode = guest` by default |
| 9 | No empty app promise | Continue | Empty dashboard fades into seeded Day 1 checklist | Demo only |
| 10 | Long setup promise | Continue | Progress rail appears with 12 chapter markers | Record onboarding intent |

### Chapter 2 - Boundaries and Trust

Goal: Establish trust, local-first posture, and medical boundaries without sounding legalistic.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 11 | Atlas is private by default | Continue | Local device ring closes like a seal | `privacy.analyticsOptIn = false` default |
| 12 | Account boundary | Choose local-only or backup later | Backup path slides behind local path | `accountMode` |
| 13 | What Atlas does | Continue | Today, Timeline, Library, Insights, Trust Vault appear as instruments | Demo only |
| 14 | What Atlas does not do | Continue | Boundary chips stamp with shield checks | Health disclaimer preface |
| 15 | Medical boundary | Tap I understand | Copy: organizes, does not prescribe | `healthDisclaimerAccepted = true` |
| 16 | Dosing boundary | Continue | Exact-dose fields stay blurred and labeled "after unlock" | Avoid pre-paywall dose claims |
| 17 | Sourcing boundary | Continue | Marketplace icon is crossed out calmly | Compliance boundary |
| 18 | Trust recap | Continue | Boundaries collapse into Trust Vault seed card | Record chapter complete |

### Chapter 3 - Protocol Reality

Goal: Get enough operational specificity to make the output feel tailored.

Shared pattern: one question per screen, selected card compresses 2 percent, border draws clockwise, checkmark appears, light haptic, bottom draft strip updates immediately.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 19 | Calibration intro | Continue | Draft strip slides up from bottom | Start visible progress |
| 20 | Why Atlas asks this | Continue | Product surfaces highlight as examples | Explain long flow value |
| 21 | Draft strip tutorial | Continue | User taps a previous answer chip to see edit affordance | Reusable `AtlasDraftStrip` |
| 22 | Start protocol map | Continue | Map background appears faintly | No data write |
| 23 | Track type | Pick GLP, peptides, both, custom, exploring | Selected path lights corresponding surface | `trackType` |
| 24 | Track type detail | Confirm or edit | Draft strip adds track chip | Branches follow track |
| 25 | Multi-track explanation | Continue if both or custom | Two streams braid into one command center | Conditional |
| 26 | Exploring mode explanation | Continue if exploring | Setup becomes "research-safe tracking" | Conditional |
| 27 | Journey status | Pick not started, active, changing, restarting, importing | Timeline marker moves to current stage | `journeyStatus` |
| 28 | Start date posture | Choose not started, recent, established, long-running | Timeline scale adjusts | New field `journeyAge` |
| 29 | Change status | Choose stable, changing soon, changed recently | Protocol Change Studio chip appears | New field `changePosture` |
| 30 | Migration need | Choose yes, maybe, no | Migration path preview appears | New field `migrationNeed` |
| 31 | Current tracking method | Pick memory, notes, spreadsheet, app, portal, paper | Source icons flow into Migration tray | New field `currentTrackingMethod` |
| 32 | Current pain | Pick scattered, incomplete, too clinical, too public, too manual | Pain maps to Atlas feature chip | New field `currentTrackingPain` |
| 33 | Data confidence | Pick high, medium, low, unknown | Confidence meter sets baseline | New field `dataConfidence` |
| 34 | Current system recap | Continue | Atlas draft shows "source to migrate" | Chapter mini-payoff |
| 35 | Routine route | Pick injection, oral, mixed, supplies, not sure | Route icon joins Today card | New field `routineRoute` |
| 36 | Cadence shape | Pick daily, weekly, every few days, phases, irregular | Calendar tiles animate to chosen pattern | New field `cadenceShape` |
| 37 | Regularity | Pick predictable, sometimes shifts, often shifts, unknown | Readiness meter seed changes | New field `scheduleRegularity` |
| 38 | Supply tracking | Pick yes, no, maybe later | Inventory surface lights if yes | New field `wantsInventoryTracking` |
| 39 | Reminder dependency | Pick low, medium, high | Notification preview changes tone | New field `reminderDependency` |
| 40 | GLP family | Pick semaglutide, tirzepatide, liraglutide, other, not sure | GLP tag joins Library preview | `glp.medication` if known, no dosing advice |
| 41 | GLP phase | Pick researching, starting, titrating, maintenance, pausing | Timeline phase chip appears | New field `glpPhase` |
| 42 | GLP challenge | Pick nausea context, appetite changes, schedule, supply, provider review | Challenge maps to feature | Existing `glp.challenge` plus new detail |
| 43 | Peptide categories | Pick recovery, sleep, performance, wellness, other | Category tokens orbit into Library | Existing `peptide.selections` |
| 44 | Peptide experience | Pick new, some, experienced, rebuilding | Confidence baseline updates | Existing `peptide.experience` |
| 45 | Peptide goal | Pick consistency, review, history, reminders, inventory | Goal maps to feature | Existing `peptide.goal` |
| 46 | Protocol complexity | Pick single, multiple, changing, seasonal, unknown | Complexity rings appear | New field `protocolComplexity` |
| 47 | Titration/change likelihood | Pick none, possible, active, frequent | Protocol Change Studio timeline lengthens | New field `changeLikelihood` |
| 48 | Exact setup timing | Continue | Copy: exact items and doses come after unlock | Locks compliance posture |
| 49 | Operational concern | Pick next action, history, side notes, privacy, provider review, inventory | Concern becomes Day 1 priority candidate | New field `primaryOperationalConcern` |
| 50 | Protocol reality recap | Continue | A small "Protocol Reality Map" prints into the draft | Record chapter complete |

### Chapter 4 - Goals, Body, Nutrition, Evidence

Goal: Borrow Cal AI's personalization depth while staying true to Atlas as protocol operations, not a calorie-only app.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 51 | Goal intro | Continue | Goal compass appears | No data write |
| 52 | Primary goal | Pick weight, consistency, side-effect context, provider review, routine, privacy | Goal becomes north-star chip | Existing `focus` plus new `primaryGoal` |
| 53 | Secondary goals | Multi-select up to three | Chips stack into "first week priorities" | New field `secondaryGoals` |
| 54 | Success definition | Pick calm, clear, consistent, prepared, informed | Success phrase used later | New field `successDefinition` |
| 55 | Seven-day win | Pick one | Day 1 plan seed appears | New field `sevenDayWin` |
| 56 | Body context intro | Continue or skip | Optional lock icon shows private fields | Privacy reassurance |
| 57 | Current weight | Enter or skip | Number writes onto private metric card | Existing `profile.weight` |
| 58 | Goal weight | Enter or skip | Goal line appears if provided | Existing `profile.goalWeight` |
| 59 | Height | Enter or skip | Body metrics card completes | Existing `profile.height` |
| 60 | Pace comfort | Pick gentle, moderate, focused, not tracking | Pace label updates | Existing `goalPacePoundsPerWeek` or new enum |
| 61 | Body context privacy | Choose show, discreet, hide | Trust Vault preview changes metric labels | New field `bodyPrivacyMode` |
| 62 | Nutrition interest | Pick none, light, macros, GLP support, full logging | Nutrition module toggles | Existing `wantsNutritionTracking` plus level |
| 63 | Appetite pattern | Pick stable, low appetite, cravings, variable, unsure | Food context panel adapts | New field `appetitePattern` |
| 64 | Protein focus | Pick yes, maybe, no | Protein tile appears in Today preview | New field `proteinFocus` |
| 65 | Water focus | Pick yes, maybe, no | Water tile appears | New field `waterFocus` |
| 66 | Food logging style | Pick photo, quick text, manual, import, avoid logging | Input affordance preview changes | New field `foodLoggingStyle` |
| 67 | Meal friction | Pick nausea, fullness, cravings, travel, timing, none | Insight tags update | New field `mealFriction` |
| 68 | Apple Health interest | Pick connect later, maybe, no | Health card is queued, no permission prompt | Existing `healthConnectionPromptSeen` later only |
| 69 | Progress evidence | Pick weight, photos, workouts, notes, symptoms, none | Evidence board assembles | New field `progressEvidencePreference` |
| 70 | Review audience | Pick myself, provider, coach, none | Review Output preview tone changes | New field `reviewAudience` |
| 71 | Export comfort | Pick polished PDF, quick summary, private notes only | Export module adapts | New field `exportComfort` |
| 72 | Goals recap | Continue | Atlas generates "Goal Operating Profile" card | Chapter payoff |
| 73 | Personalization receipt | Continue | Shows what changed: Today, review, privacy, nutrition | Reinforces value |
| 74 | Continue to friction | Continue | Goal card folds into readiness map | Transition |

### Chapter 5 - Friction and Risk Map

Goal: Make the user feel seen. This is where Atlas becomes better than a tracker.

Copy framing: "This is not about willpower. It tells Atlas what kind of system to build."

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 75 | Friction intro | Continue | Small obstacles become route markers | No blame language |
| 76 | Schedule interruptions | Pick travel, work, caregiving, weekends, evenings, none | Calendar risk heatmap appears | New field `routineInterruptions` |
| 77 | Hardest days | Multi-select days | Week strip highlights | New field `hardestDays` |
| 78 | Hardest time | Pick morning, afternoon, evening, late, variable | Time dial rotates | New field `hardestTime` |
| 79 | Missed step likelihood | Pick rare, sometimes, often, unknown | Recovery lane appears | New field `missedStepLikelihood` |
| 80 | Reminder tolerance | Pick subtle, normal, persistent, none | Notification preview changes | New field `reminderPreference` |
| 81 | Logging friction | Pick forget, too much detail, private, no time, boring | Capture method adapts | New field `loggingFriction` |
| 82 | Capture speed | Pick under 10 seconds, under 30, detailed later | Today quick action preview changes | New field `captureSpeedPreference` |
| 83 | Backfill comfort | Pick yes, sometimes, no | Timeline backfill affordance appears | New field `backfillComfort` |
| 84 | Recovery preference | Pick reset today, repair history, leave gap, ask me | Missed-day card changes | New field `recoveryPreference` |
| 85 | Side-note sensitivity | Pick side effects, mood, appetite, sleep, none | Insight note types appear | New field `sensitiveNoteTypes` |
| 86 | Inventory confidence | Pick high, medium, low, not tracking | Inventory readiness changes | New field `inventoryConfidence` |
| 87 | Review anxiety | Pick low, medium, high, not sharing | Review readiness changes | New field `reviewAnxiety` |
| 88 | Privacy concern | Pick notifications, labels, sharing, phone glance, none | Trust Vault priority changes | New field `privacyConcern` |
| 89 | Support style | Pick precise, encouraging, discreet, direct, quiet | Companion role seed changes | New field `supportStyle` |
| 90 | Motivation style | Pick streaks, checklist, map progress, rewards, minimal | Rewards tuning changes | New field `motivationStyle` |
| 91 | Companion presence seed | Pick subtle, default, more alive, off | Companion presence queued, not shown yet | Existing `ambientMascotPresence` later |
| 92 | Friction map generation | Timed | Heatmap scans schedule, logging, privacy, recovery | Deterministic generation |
| 93 | Friction map reveal | Continue | Four risk lanes appear with "Atlas will handle" chips | Generated payoff |
| 94 | User chooses top risk | Pick one | Selected risk becomes Day 1 priority candidate | New field `topFrictionRisk` |
| 95 | Friction recap | Continue | Risk map folds into final readiness map | Record chapter complete |

### Chapter 6 - Trust Vault

Goal: Make privacy a flagship feature, not an afterthought.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 96 | Trust Vault intro | Continue | Vault line draws around current draft | Start trust chapter |
| 97 | Privacy posture | Pick standard, discreet, locked down, custom | Whole preview changes instantly | Existing `privacyPreset` |
| 98 | Label mode demo | Toggle clear and discreet | "semaglutide" becomes neutral alias in preview | `hideSensitiveLabels` |
| 99 | Notification mode demo | Toggle direct and discreet | Notification text rewrites live | `discreetNotifications` |
| 100 | App glance mode | Pick normal, subtle, private | Today preview hides sensitive chips | New field `appGlanceMode` |
| 101 | Review redaction | Toggle medication, dates, body metrics, notes | Export preview redacts with privacy wipe | New field `reviewRedactionDefaults` |
| 102 | Sharing boundary | Pick inspect first, always discreet, never export | Review Output rule writes | New field `sharingBoundary` |
| 103 | Biometric later | Choose later or skip | Lock icon settles into settings tray | Existing `biometricLater` |
| 104 | Analytics choice | Opt in or keep off | Copy is plain and non-coercive | Existing `analyticsOptIn` |
| 105 | Privacy receipt | Continue | Shows exact posture selected | Trust payoff |
| 106 | Vault seal | Continue | Firm seal haptic, privacy card locks into Atlas draft | Record chapter complete |

### Chapter 7 - Atlas Generation

Goal: Create the Cal AI style payoff, but with Atlas-specific generated artifacts.

The generation screen should feel real. Use staged progress, deterministic outputs, and visible artifacts. Do not ask for permissions here.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 107 | Ready to build | Tap Generate my Atlas | All draft chips flow into center stack | Start timed generation |
| 108 | Organizing protocol context | Timed | Protocol cards align by route, phase, cadence | Generate protocol summary |
| 109 | Mapping friction | Timed | Risk lanes draw from friction answers | Generate risk profile |
| 110 | Sealing Trust Vault | Timed | Privacy layer wraps around generated cards | Generate privacy posture |
| 111 | Drafting Today | Timed | Day 1 checklist rows appear one by one | Generate checklist |
| 112 | Preparing first week | Timed | Seven small day cards build | Generate week plan |
| 113 | Preparing review output | Timed | Provider/self summary appears redacted | Generate review template |
| 114 | Preparing migration path | Timed | Source input converts into staged import path | Generate migration recommendation |
| 115 | Preparing companion signal | Timed | Sealed capsule glows behind system card | No companion yet |
| 116 | Generation complete | Continue | Stack opens into "Your Atlas is ready" | Record generated output |

### Chapter 8 - Companion Hatch

Goal: Use the egg/hatch mechanic as a powerful emotional payoff, not as the product's premise.

The visual can be called a capsule, signal core, protected vessel, or egg. It opens into the existing Atlas companion art. The avatar design does not change.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 117 | Your Atlas is taking shape | Continue | Generated artifacts orbit sealed vessel | Hatch setup |
| 118 | Choose companion line | Pick existing companion option | Existing mascot preview appears inside vessel silhouette | Existing `mascotSelection` |
| 119 | Vessel warm-up | Timed | Signal color pulses from selected Atlas surfaces | Animation only |
| 120 | Hatch moment | Tap and hold, or tap if Reduce Motion | Vessel opens, existing companion appears | `AtlasFeedback.mascotMoment()` |
| 121 | First companion line | Continue | "I will keep this organized with you." | Non-medical copy |
| 122 | Companion name | Enter or accept suggestion | Name writes onto small companion tag | Existing `mascotNickname` |
| 123 | Name suggestions | Shuffle or continue | Suggested names rotate with subtle flip | Build name suggestion list |
| 124 | Signal color | Choose color | Accent updates companion halo and draft strip | New field `companionSignalColor` |
| 125 | Companion role | Pick steady, precise, discreet, encouraging | Companion line changes by role | New field `companionRole` |
| 126 | Presence level | Pick off, subtle, default, more alive | Perch preview changes | Existing `ambientMascotPresence` |
| 127 | Boundaries | Continue | Companion fades out of Trust Vault and Review previews | Suppression policy |
| 128 | Growth rules | Continue | Evolution path appears tied to useful actions, not streak shame | Existing rewards model |
| 129 | Hatch recap | Continue | Companion joins Atlas draft as optional support layer | Record companion chapter |

### Chapter 9 - Protocol Readiness Map

Goal: Deliver a memorable result that feels generated from the long onboarding.

No diagnosis. No health score. This is an operational readiness map.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 130 | Readiness reveal | Continue | Map draws six rings around Atlas core | Generate `AtlasProtocolReadinessMap` |
| 131 | Schedule clarity | Tap dimension | Ring expands into schedule explanation | Deterministic score |
| 132 | Inventory confidence | Tap dimension | Inventory path preview opens | Deterministic score |
| 133 | Change-history readiness | Tap dimension | Protocol Change timeline expands | Deterministic score |
| 134 | Review readiness | Tap dimension | Review Output preview expands | Deterministic score |
| 135 | Privacy posture | Tap dimension | Trust Vault seal expands | Deterministic score |
| 136 | Context coverage | Tap dimension | Captured inputs list appears | Deterministic score |
| 137 | Strongest starting point | Continue | Best dimension glows | Generated insight |
| 138 | First setup gap | Continue | Lowest dimension becomes "fix first" candidate | Generated insight |
| 139 | Choose Day 1 priority | Pick recommended or another | Day 1 checklist reorders live | New field `dayOnePriority` |
| 140 | Readiness receipt | Continue | Map compresses into Today header readiness strip | Persist generated map |

### Chapter 10 - Interactive Proof Tour

Goal: Convert the generated plan into confidence that the app is useful after onboarding.

This should be hands-on. The user should tap real controls in a safe demo shell.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 141 | Today command center | Tap next action | Today opens with generated Day 1 checklist | Demo shell |
| 142 | Complete a demo action | Tap check | Row completes, readiness strip improves | Haptic success |
| 143 | Quick log demo | Tap plus | Floating action menu opens with relevant actions | Borrow Cal AI speed |
| 144 | Missed-step recovery | Choose recovery option | Gap becomes repaired, skipped, or left open | Demo only |
| 145 | Protocol Change Studio | Drag before/after card | Version timeline updates | Demo only |
| 146 | Trust Vault in context | Toggle discreet mode | Entire demo redacts labels | Shared privacy state |
| 147 | Review Output | Tap preview | Share summary assembles with selected redactions | Demo only |
| 148 | Migration path | Tap import source | Source notes become staged migration checklist | Demo only |
| 149 | Inventory runway | Adjust supply count | Runway warning changes | Demo only |
| 150 | Progress Evidence | Toggle evidence type | Evidence board updates | Demo only |
| 151 | Weekly Review preview | Tap closeout card | Week summary animates from completed actions | Demo only |
| 152 | Widget preview | Swipe small and medium widgets | Widget content respects privacy posture | Demo only |
| 153 | Proof recap | Continue | All proof surfaces collapse into one artifact stack | Record proof tour complete |

### Chapter 11 - First Week, Trial, and Access

Goal: Show a real plan before asking for money, then make access choices plain and trustworthy.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 154 | First-week reveal | Continue | Seven day cards unfold from readiness map | Generate first-week plan |
| 155 | Day 1 plan | Expand or continue | Exact setup, privacy-safe reminder, one quick log | Seed Day 1 checklist |
| 156 | Day 2 plan | Expand or continue | Schedule confirmation card opens | First-week plan item |
| 157 | Day 3 plan | Expand or continue | Inventory or supply confidence card opens | First-week plan item |
| 158 | Day 4 plan | Expand or continue | First private quick log card opens | First-week plan item |
| 159 | Day 5 plan | Expand or continue | Review Output setup card opens | First-week plan item |
| 160 | Day 6 plan | Expand or continue | Migration or backfill card opens | First-week plan item |
| 161 | Day 7 plan | Expand or continue | Weekly Review card opens | First-week plan item |
| 162 | Setup intensity | Pick start light or set everything up now | Week plan reorders and checklist count updates | New field `setupIntensity` |
| 163 | Artifact stack | Continue | Readiness map, first week, Trust Vault, review, migration, companion stack together | Pre-paywall value proof |
| 164 | Premium unlock | Continue | Locked advanced controls glow without fake urgency | Paywall preface |
| 165 | Trial timeline | Review | Day 0, reminder, billing date appear plainly | Billing trust |
| 166 | Plan selection | Pick annual or monthly | Selected plan gets calm check, no casino motion | Existing `premiumPlan` |
| 167 | Basic path | Choose trial or basic | Basic path stays visible and calm | Existing `paywallChoice` |
| 168 | App Store purchase | System sheet or skip | Return to same generated artifacts after result | Purchase flow |
| 169 | Access receipt | Continue | Shows Trial active or Basic tracking active | Persist access choice |

### Chapter 12 - Permissions and Day 1 Handoff

Goal: Ask permissions only after value, then land the user in the real app with work already waiting.

| # | State | User action | Motion and payoff | Data or build note |
| ---: | --- | --- | --- | --- |
| 170 | Reminder setup | Choose direct, discreet, or skip | Notification examples use chosen privacy posture | Prompt primer |
| 171 | Notification permission | Allow or skip | System prompt appears only after primer | Persist result |
| 172 | Apple Health setup | Choose connect, maybe later, skip | Health signals preview appears | Only if relevant |
| 173 | Health permission | Allow or skip | System prompt appears only after signal explanation | Existing Health flow |
| 174 | Widget setup | Choose add later or preview | Widget preview respects discreet labels | Optional |
| 175 | Account backup | Choose local-only or sign in later | Local remains first-class | Existing account mode |
| 176 | Final readiness receipt | Continue | Readiness strip, Trust Vault, Day 1, companion all show final states | Pre-handoff |
| 177 | Shell morph | Continue | Onboarding header/footer dissolve into app shell | Matched geometry |
| 178 | Today live | Continue | Real Today command center appears with checklist | App state seeded |
| 179 | First real action | Complete one action or skip | Rewards, readiness, and companion response update | Real action |
| 180 | Onboarding complete | Open Atlas | Companion settles, Atlas lands in Today | `completeOnboarding()` |

## Required Detail Inside Chapters 11 and 12

The canonical states above are the tap-level inventory. These details are required inside those states through carousels, accordions, or staged reveals.

First-week plan:

1. Reveal "Your first week in Atlas."
2. Show Day 1: set exact protocol items, choose privacy-safe reminder, complete one quick log.
3. Show Day 2: confirm schedule.
4. Show Day 3: add inventory if relevant.
5. Show Day 4: try one private quick log.
6. Show Day 5: configure Review Output.
7. Show Day 6: migrate or backfill if relevant.
8. Show Day 7: run first weekly review.
9. Let the user choose "start light" or "set everything up now."
10. Seed the real Today checklist from this choice.

Trial and access:

1. Show the artifacts Atlas already generated: readiness map, first week, Trust Vault, review template, migration path, companion.
2. Explain what is unlocked by Atlas Premium.
3. Show the trial timeline plainly.
4. Show annual and monthly options.
5. Keep "continue with basic tracking" visible.
6. Do not imply medical outcomes.
7. Do not use fake urgency.
8. After purchase or basic path, return to the same generated plan.

Permissions:

1. Ask notifications only after showing Day 1 reminder value.
2. Show direct vs discreet notification examples before the system prompt.
3. Ask Apple Health only if the user expressed interest.
4. Explain exactly which Health signals Atlas can use.
5. Make Health skippable.
6. Offer widgets or shortcuts after the real Today command center is visible.
7. Offer account backup last, with local-first still respected.

## Motion and Transition Lock

Use these exact motion patterns as the design vocabulary.

| Pattern | Where | Behavior |
| --- | --- | --- |
| Live product morph | Hero demo | Today expands, Trust Vault redacts, Review assembles, Migration cleans, Change Studio versions. |
| Draft strip write | All questionnaire states | Answer chip slides into bottom strip immediately after selection. |
| Clockwise border draw | Option cards | Selection border draws, card compresses 2 percent, checkmark appears. |
| Chapter seal | Chapter recaps | Generated chapter artifact folds into the Atlas draft stack. |
| Privacy wipe | Trust Vault | Sensitive labels transform through a left-to-right redaction wipe. |
| Heavy vault seal | Trust chapter completion | Slower animation, firm haptic, no confetti. |
| Generation stack | Generation | Chips flow inward, artifacts build outward, progress text changes by phase. |
| Hatch warm-up | Companion | Generated artifacts orbit vessel, vessel opens into existing companion. |
| Readiness rings | Readiness map | Six rings draw from lowest to highest score. |
| Shared surface tour | Proof tour | Demo surfaces use matched geometry transitions from generated artifact cards. |
| First-week accordion | Week plan | Day cards unfold one at a time with the chosen Day 1 priority expanded. |
| Shell morph | Handoff | Onboarding header and footer dissolve into app tab shell and Today header. |

All motion must support Reduce Motion:

- Replace parallax with opacity.
- Replace long morphs with crossfades.
- Replace orbiting hatch with fade, open, appear.
- Disable repeating ambient motion.
- Preserve information hierarchy and haptics where appropriate.

## Haptic Lock

Use the existing `AtlasFeedback` primitives.

| Moment | Haptic |
| --- | --- |
| Option selection | `AtlasFeedback.selection()` |
| Continue after required answer | `AtlasFeedback.navigation()` |
| Chapter generated artifact | `AtlasFeedback.milestoneReveal()` |
| Trust Vault seal | `AtlasFeedback.impact(.medium)` |
| Hatch warm-up | `AtlasFeedback.mascotMoment()` if available, otherwise soft impact |
| Hatch reveal | `AtlasFeedback.notify(.success)` |
| Paywall plan select | `AtlasFeedback.selection()` |
| First real Day 1 completion | `AtlasFeedback.levelUp()` |

## Copy Lock For Key Screens

Use this tone: direct, private, operational, calm.

Hero:

- "Atlas"
- "Run your protocol from a private command center."
- "Build my Atlas"
- "Continue privately"

Long setup promise:

- "The setup is thorough because your protocol is not a generic habit."
- "Every answer changes your Atlas."

Boundary:

- "Atlas organizes your protocol. It does not prescribe, diagnose, source, or replace your clinician."

Friction:

- "This is not about willpower. It tells Atlas what kind of system to build."

Generation:

- "Your Atlas is taking shape."
- "Building your Protocol Readiness Map."
- "Preparing your Day 1 command center."
- "Sealing your Trust Vault posture."

Hatch:

- "Your companion is ready."
- "It will keep the system warm without taking over."

Readiness:

- "Your Protocol Readiness Map"
- "This is an operations map, not a medical score."

Trial:

- "Start with the full Atlas system."
- "Your generated map, Day 1 plan, Trust Vault, and companion stay intact."
- "Continue with basic tracking"

Handoff:

- "Your Atlas is ready."
- "Start with one action."

## New Draft Fields Needed

Add these with Codable defaults so old onboarding drafts continue to decode.

Core:

- `journeyAge`
- `changePosture`
- `migrationNeed`
- `currentTrackingMethod`
- `currentTrackingPain`
- `dataConfidence`
- `routineRoute`
- `cadenceShape`
- `scheduleRegularity`
- `wantsInventoryTracking`
- `reminderDependency`
- `protocolComplexity`
- `changeLikelihood`
- `primaryOperationalConcern`

Goals and body:

- `primaryGoal`
- `secondaryGoals`
- `successDefinition`
- `sevenDayWin`
- `bodyPrivacyMode`
- `nutritionTrackingLevel`
- `appetitePattern`
- `proteinFocus`
- `waterFocus`
- `foodLoggingStyle`
- `mealFriction`
- `progressEvidencePreference`
- `reviewAudience`
- `exportComfort`

Friction:

- `routineInterruptions`
- `hardestDays`
- `hardestTime`
- `missedStepLikelihood`
- `reminderPreference`
- `loggingFriction`
- `captureSpeedPreference`
- `backfillComfort`
- `recoveryPreference`
- `sensitiveNoteTypes`
- `inventoryConfidence`
- `reviewAnxiety`
- `privacyConcern`
- `supportStyle`
- `motivationStyle`
- `topFrictionRisk`

Trust and companion:

- `appGlanceMode`
- `reviewRedactionDefaults`
- `sharingBoundary`
- `companionSignalColor`
- `companionRole`
- `dayOnePriority`

Generated outputs:

- `protocolReadinessMap`
- `firstWeekPlan`
- `dayOneChecklist`
- `reviewOutputTemplate`
- `migrationRecommendation`
- `generationCompletedAt`

## Readiness Map Model

Use deterministic scoring. No AI dependency is needed for v1.

Dimensions:

1. Schedule clarity
2. Inventory confidence
3. Change-history readiness
4. Review readiness
5. Privacy posture
6. Context coverage

Each dimension should include:

- `score`: 0-100
- `label`: plain English
- `why`: one-sentence explanation from answers
- `improvesWith`: one action that can improve it
- `mappedSurface`: Today, Inventory, Protocol Change Studio, Review Output, Trust Vault, Migration, or Insights

Important: never call this a health score, risk score, diagnosis, or readiness to start medication.

## First-Week Plan Model

Each day should include:

- `dayIndex`
- `title`
- `whyItMatters`
- `primaryAction`
- `optionalAction`
- `surface`
- `companionLine`
- `rewardPoints`

Default first week:

1. Set exact protocol details and first reminder.
2. Add or confirm schedule.
3. Add inventory or supply confidence.
4. Try one private quick log.
5. Generate one Review Output preview.
6. Migrate or backfill one old note.
7. Complete first weekly review.

Branch the order based on the selected Day 1 priority.

## SwiftUI Implementation Plan

Phase 1: Domain and journey engine

- Add scene IDs and generated output models.
- Extend `AtlasOnboardingDraft` with Codable defaults.
- Add deterministic readiness and first-week generation helpers.
- Add tests for decoding old drafts and generating stable outputs.

Phase 2: Shell and components

- Split the large onboarding file into focused files.
- Build `AtlasOnboardingJourneyShell`.
- Build `AtlasDraftStrip`.
- Build `AtlasOnboardingChapterRail`.
- Build `AtlasOptionCard` selection border draw.
- Build `AtlasGeneratedArtifactCard`.
- Build `AtlasReadinessRingMap`.

Phase 3: Questionnaire chapters

- Build protocol reality, goals, body, nutrition, evidence, and friction scenes.
- Keep one-question-per-state clarity.
- Make every selection update the draft strip.

Phase 4: Trust and generation

- Build live Trust Vault demo with redaction.
- Build timed generation using deterministic outputs.
- Persist generated outputs to the draft.

Phase 5: Companion hatch

- Use existing mascot art and evolution system.
- Build vessel animation as presentation only.
- Add companion role, signal color, and presence fields.
- Enforce companion suppression in sensitive contexts.

Phase 6: Readiness, proof, first week, paywall

- Build readiness map and drilldowns.
- Build proof tour as a safe demo shell.
- Build first-week plan.
- Build transparent trial and basic path.

Phase 7: Permissions and handoff

- Gate notification and Health prompts after value.
- Seed Day 1 checklist into the real Today command center.
- Morph onboarding shell into app shell.

## Test Plan

Minimum tests before shipping:

- Full journey contains required chapters in order.
- Existing 22-step draft migration decodes without data loss.
- Old onboarding JSON decodes with defaults for every new field.
- Required fields do not block optional body, nutrition, Health, or account setup.
- Paywall choice is recorded and basic path works.
- Health prompt is never shown before value and remains optional.
- ATT or analytics prompt never appears during generation.
- Readiness map generation is deterministic.
- First-week plan generation is deterministic.
- Day 1 checklist is seeded after onboarding completion.
- Companion hatching does not change avatar identity.
- Companion suppression works in Trust Vault, Review Output, and protocol-change sensitive states.
- Reduce Motion path contains no required animated-only information.
- VoiceOver labels exist for all option cards, progress rail, readiness rings, and companion hatch controls.
- iPhone SE layout has no clipped CTA, draft strip, or paywall text.
- Dark mode contrast passes for all long-form text and option states.

## QA Checklist For This Build

- Run full GLP path, starting fresh.
- Run full GLP path, already active.
- Run full peptide path.
- Run both GLP and peptide path.
- Run custom protocol path.
- Run exploring path.
- Skip every optional field and confirm completion still works.
- Enter body and nutrition fields and confirm privacy modes affect previews.
- Choose locked-down privacy and confirm labels stay discreet after handoff.
- Choose standard privacy and confirm labels are clear.
- Turn companion off and confirm no hatch pressure after selection.
- Choose subtle companion and confirm companion appears after handoff only where appropriate.
- Use basic path at paywall and confirm generated outputs remain.
- Start trial and confirm same outputs remain.
- Decline notifications and Health and confirm app is usable.
- Enable notifications and Health and confirm settings reflect choices.
- Complete first Day 1 action and confirm rewards, readiness, and Today update.

## Build Readiness Verdict

This storyboard is ready to build.

The strongest implementation path is to keep the dream experience long and emotionally rich, but implement it through a smaller set of reusable scenes and generated artifacts. The build should not try to make every beat a separate screen file. It should feel like 180 states to the user, but it should behave like a disciplined scene engine to the codebase.

The signature sequence is locked:

1. Real product demo.
2. Private and medical boundaries.
3. Protocol reality.
4. Goals, body, nutrition, and evidence.
5. Friction map.
6. Trust Vault.
7. Atlas generation.
8. Companion hatch.
9. Protocol Readiness Map.
10. Interactive proof tour.
11. First-week plan and transparent trial.
12. Permissions and live Day 1 handoff.

That is the dream onboarding.

# Atlas iOS UI Polish Thread Handoff

Last updated: 2026-04-16

## Purpose

This note captures practical UI, copy, keyboard, and mascot lessons from the long April 16 polish thread.

Use it when future work touches Today, Timeline, Library, Insights, Settings, protocol creation, quick capture, Account & Sync, recap/export surfaces, mascot, rewards, or any SwiftUI form.

Read this with:

- `docs/ios-ux-execution-playbook-2026-04-15.md`
- `docs/ios-premium-ui-rubric.md`
- `docs/ios-redesign-context-2026-04-14.md`
- `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`

## Standing Product Direction

Atlas is a calm, premium, local-first iPhone protocol operating system.

It should feel:

- tactile
- decisive
- informative
- trust-heavy
- sparse where the user needs action

It should not feel like:

- a generic health app
- a marketplace
- a social app
- a sourcing app
- a medical advice app
- a noisy mascot/rewards game

## Copy Cleanup Rules

Prefer literal UI labels and action names over narration.

Delete or avoid copy that sounds like:

- product philosophy on root screens
- fake `Atlas ...` helper narration
- motivational filler
- repeated milestone/reward exposition
- explanatory text that does not change the user decision

Specific copy patterns removed or rejected in this thread:

- `Start the loop`
- `Build the foundation`
- `Plain-language recaps`
- `Live form, recap posters, and archive`
- `Immutable from the first event`
- `Local-first by default`
- `Bright first light`
- long mascot evolution / points explainer copy on root or detail surfaces
- repeated `Live journey`, `Latest moment`, or export recommendation prose on the main path

Root surfaces should be title-first and sparse. Detailed summaries can live behind focused drill-ins, archive/detail views, or recap studio surfaces rather than sitting inline every time.

## Stat Tile Rules

Compact stat strips must be predictable.

- If a stat row has three or fewer tiles, all tiles should fit on screen.
- Do not clip the third tile on the right edge.
- Horizontal swipe is appropriate only when there are more than three tiles.
- Equal-count dashboard tiles should visually share width unless there is a deliberate reason not to.
- Long values should scale or truncate inside the tile instead of changing sibling tile width.

Surfaces called out in this thread:

- Today: `Overdue`, `Upcoming`, `Points`
- Timeline filters: `Visible`, `Filter`, `Search`
- New Protocol plan summary: `Kind`, `Route`, `Cadence`
- Account & Sync: `Mode`, `Sync`
- mascot/rewards stats such as `Stage`, `Points`, `Unlocks`

## Empty State Rules

Empty states should not argue with the user.

Today due-state cleanup established this pattern:

- `Nothing due right now` should stay on one line when the viewport allows it.
- Remove secondary filler copy when the primary message and action already explain the state.
- Remove low-value pills like `Clear for now`.
- Keep the primary action obvious.

For Timeline and other history surfaces, avoid extra reassurance badges that repeat the concept already in the body copy.

## Keyboard And Form Rules

Every text entry, search, and number-entry surface must have a visible escape or commit path.

For SwiftUI forms:

- add a keyboard toolbar when the user can get trapped behind the keyboard
- provide `Done`, `Cancel`, and/or `Save` where the surrounding format calls for it
- use `@FocusState` and `dismiss()` deliberately
- set suitable `submitLabel`
- make `onSubmit` dismiss or save when that is the expected iOS behavior
- verify number pads too, since they do not always show a return key

Surfaces explicitly checked or called out in this thread:

- New Protocol naming and fields
- Timeline immutable-history search
- Account & Sync email/password entry
- vial quantity / low-stock numeric inputs
- quick capture sheets
- context, weight, symptom, custom metric, vial, supply, and protocol editor entry points

If a screen scrolls while the keyboard is open, test it on simulator. Avoid layout feedback loops where focus/keyboard avoidance changes content height and causes rapid up/down oscillation.

## Quick Action Rules

Quick actions should read as controls, not mini articles.

- Card labels should not hyphenate.
- Button/card copy should usually be only the action name.
- Remove secondary copy inside compact quick-action cards unless it changes the decision.
- Icon/logo marks in a quick-action row should align with each other.
- Same-rank quick action cards should share the same size.

Surfaces called out:

- Insights capture actions
- Library quick actions
- `Log context`, `Log weight`, `Log symptom`, `Manage metrics`
- inventory `Calculator`, `Vials`, `Supplies`

## Mascot And Rewards Restraint

Mascot and rewards should be ambient, optional, and event-based.

Preserve these decisions:

- no free-roaming mascot overlays on top of main UI
- no permanent mascot homes added just to make a screen feel alive
- no repeated level/evolution/points exposition on root paths
- no always-on live sprite overlay competing with content
- use event-based reactions and existing anchored perches
- keep Aetherion and Aurielle behavior/copy changes in parity unless there is an explicit product reason to diverge

Detailed mascot/reward storytelling belongs in mascot detail, archive, recap, or explicit export/detail views, and even there should stay concise.

## Recap And Export Surface Rules

Recap, latest moment, and live journey content got too dense in this thread.

Future iterations should:

- summarize inline with one concise result or status
- move longer narrative into an archive/detail surface
- avoid stacked oval badges when they do not drive a choice
- keep audience/export mode buttons equal size when they are peers
- delete recommendation copy when it repeats the selected state

Recap Studio specifically should avoid:

- extra subtitle copy under the main title
- separate ovals for `Recommended export`, `Latest moment`, `Share`, and `Full detail` when they crowd the decision
- long `strongest export right now` explanations on the main path

## Settings And Control Center Rules

Settings should stay a focused hub, not a long admin page.

Avoid adding low-value status copy and decorative icon rows to Control Center. In this thread, the direction was to remove:

- `Local-first by default`
- sync/display icon rows that acted as decoration rather than controls

For Account & Sync, peer summary boxes such as `Mode` and `Sync` should be the same size.

## QA Baseline From This Thread

Use a fresh simulator when a thread has accumulated many UI changes.

Known useful setup from this thread:

- canonical repo: `/Users/donghokang/Developer/Atlas`
- Xcode project: `/Users/donghokang/Developer/Atlas/atlas-ios/Atlas.xcodeproj`
- scheme: `Atlas`
- bundle id: `com.dkang2000.Atlas`
- fresh QA simulator used: `AtlasFreshQA`
- derived data used: `/Users/donghokang/Developer/Atlas/atlas-ios/.derived-data-ui-cleanup`

Minimum simulator QA for similar UI work:

- build the app
- install and launch the fresh build
- check Today stat tiles and empty due state
- check Timeline filters, search, and empty history state
- check Insights quick actions and review lanes
- check Library quick actions and empty protocol states
- check Settings / Account & Sync
- test at least one text keyboard and one numeric keyboard
- sweep for exact removed copy strings with `rg`

Do not call broad UI cleanup done only because Swift compiles. The app needs simulator inspection after layout/copy work.

# Kairo Board Fidelity Execution - 2026-04-24

## Target

Match the locked 12-screen mockup board as the visual source of truth while preserving the current working Kairo backend, persistence, routing, rewards, Health/reminders/widgets integrations, and deep app flows.

## Current Pass

Calibration screens: Today, Log Shot, Companion, Protocols, Protocol Detail, Edit Protocol, Progress, Progress Evidence, Inventory, Calculator, Weekly Review, Settings, and the first layer of deep/quick-capture routes.

Reference artifact:

- Locked board: `/Users/donghokang/Library/Messages/Attachments/ee/14/C707BC55-1249-4A7A-8658-AAF0F043CAA4/IMG_5314.png`
- Today side-by-side pass 4: `output/mockup-inspection/today-side-by-side-pass4.png`
- Latest 37-route screenshot sweep: `output/mockup-screenshot-qa/kairo-board-pass-20260424-1856/`
- Focused contact sheet: `output/mockup-screenshot-qa/kairo-board-pass-20260424-1856/contact-sheet-focused.jpg`
- Six-screen exact fidelity pass artifact: `output/mockup-inspection/fidelity-six/live-scale-pass-20260424-194351/paired-six-scale-pass.jpg`
- Test result bundle: `atlas-ios/.derived-data-kairo-mockup-protocol-system/Logs/Test/Test-Atlas-2026.04.24_19-45-19--0400.xcresult`

Latest verification:

- `scripts/atlas-mockup-screenshot-qa.sh` completed 37 route screenshots with blank-frame checks enabled.
- `xcodebuild test ... -only-testing:AtlasTests/AtlasPhaseOneTests` passed after the six-screen scale correction: 207 tests, 0 failures.
- `xcodebuild build -quiet ...` passed after the six-screen fidelity edits and again before capture.

## Fidelity Rules

- The app should look like the board at thumbnail scale before inspecting details.
- Differences should come from live data only, not styling drift.
- Shared primitives must be fixed before downstream screens are tuned.
- Deep flows must inherit the closest board primitive instead of inventing new visual language.

## Shared Primitives To Lock

- Canvas, scroll padding, and bottom-safe-area rhythm.
- 8pt card radius, low border, soft shadow, compact inner padding.
- Board typography roles for screen title, card title, metadata, pills, chart labels, tab labels.
- Mascot hero art and background wash.
- Vial art.
- Medication chart with area fill, dotted target, live marker, compact labels.
- Protein/hydration/workout support rings.
- Compact floating bottom tab shelf.
- Body map and site controls.
- Badge, collectible, crystal, and weekly mastery art.

## Today Mismatch Checklist

- [x] Use board-matching Aetherion hero asset on Today.
- [x] Add soft hero wash across the full hero card.
- [x] Retune Today mascot crop, card density, due indicator, CTA height, support ring scale, chart stroke, and inventory vial detail against the board.
- [x] Move support ring labels to the top of each card.
- [x] Add medication chart area fill, dotted target line, and brighter live point.
- [x] Replace flat vial with glassier vial primitive.
- [x] Remove non-board Today quick-action row.
- [x] Restore actual protocol title on Today.
- [x] Increase Today density so inventory sits closer to the board position.
- [x] Tune shared tab shelf toward board proportions.
- [x] Restore board-scale Today hero, chart, CTA, support rings, and inventory runway after the first six-screen pass over-compressed the app.
- [ ] Fine tune hero mascot crop/scale against the board.
- [ ] Fine tune Today typography weights and exact line heights.
- [ ] Fine tune chart line geometry and label positions.
- [ ] Fine tune support ring text and ring geometry.
- [ ] Fine tune inventory row text alignment and vial scale.

## Board Screens Remaining

- [~] Log Shot
- [~] Companion
- [ ] Protocols
- [~] Protocol Detail
- [~] Edit Protocol
- [ ] Progress
- [~] Progress Evidence
- [~] Inventory
- [~] Calculator
- [~] Weekly Review
- [~] Settings

## Log Shot Pass 1 Notes

- [x] Reuse board-matching Aetherion asset in reward banner.
- [x] Show actual protocol title rather than privacy alias on the mockup-forward Log Shot surface.
- [x] Compress injection map and site controls so the ritual fits closer to the board.
- [x] Use compact Mark as Taken CTA styling.
- [x] Recheck whether vial runway and CTA are visible above the tab shelf on common simulator height.
- [x] Dedupe site button labels and keep an operational Other option.
- [x] Retune Log Shot body-map height, site button density, pain slider row, side-effect chips, note field, CTA height, and trailing checkmark to match the compact ritual board.
- [~] Fine tune body map proportions and side-effect chip widths.

## Companion Pass 1 Notes

- [x] Remove top title/gear chrome to match the locked board.
- [x] Reuse board-matching Aetherion asset in the companion hero.
- [x] Use XP detail in the level ring instead of percent-only text.
- [x] Use Aetherion silhouettes for next-form preview.
- [x] Retune collection-card typography and icon rail density against the board.
- [ ] Fine tune mascot platform/background and next-form silhouette scale.
- [ ] Fine tune badge/collectible icon art against board.

## Protocols Pass 1 Notes

- [x] Limit first viewport to three active protocol cards, schedule summary, and Add Protocol CTA.
- [x] Use actual protocol titles rather than privacy-rendered placeholders.
- [x] Remove secondary Calculator / Share Summary buttons from the board-facing first viewport.
- [x] Retune shared card/title/meta typography and vial scale used by Protocol rows.
- [ ] Tune exact card height and weekday pill placement.

## Progress Pass 1 Notes

- [x] Replace split trend tiles with one board-style Body Trend card.
- [x] Restore board first viewport to Body Trend, Consistency, Symptoms, support rings, Progress Photos, and Health Integrations.
- [x] Keep workout functionality via the Workout support ring.
- [x] Retune body-trend, range selector, support ring, and mini-action density through shared board primitives.
- [ ] Tune ring label wrapping and chart geometry.

## Inventory Pass 1 Notes

- [x] Replace sparse inventory shell with board-style vial rows.
- [x] Actual vials open the vial editor.
- [x] Protocols without a vial render as Add vial rows that open a prelinked vial editor.
- [x] Retune Inventory to use a board-style top-level header, compact rows, smaller vial art, and compact tab shelf.
- [ ] Add richer supply rows once the live inventory store has supplies.

## Remaining Board Screens Pass 1 Notes

- [x] Protocol Detail now follows the board order: hero, metric strip, schedule, adherence, medication chart, recent shots, runway, edit.
- [x] Site Rotation remains functional but is moved below the board-visible detail content.
- [x] Edit Protocol now uses a board-style medication cell, horizontal peptide picker, labeled cadence/route/day sections, and real save.
- [x] Edit Protocol density pass brings the notes and Save Protocol action fully into the first viewport while preserving live create/edit/save behavior.
- [x] Vial Concentration in Edit Protocol opens the calculator, preserving access without cluttering the Protocols board.
- [x] Progress Evidence now renders six board-style evidence tiles when no live photos exist; each opens the real Add Photo flow.
- [x] Progress Evidence now uses stored local photo thumbnails when available, falling back to board-style private silhouettes.
- [x] Calculator now matches the board hierarchy more closely and keeps working stepper math/profile saving.
- [x] Weekly Review now uses compact board-style adherence/support/side-effect/wins/focus sections with real complete-review action.
- [x] Settings can render as the Companion tab state with the bottom tab shelf present; tapping Companion again toggles Companion/Settings.
- [x] Companion reward preview icons use dedicated shield, streak, calendar, heart, crystal, cube, palette, and link glyphs instead of generic SF-symbol-only tiles.
- [x] Protocols title bar now matches the board by relying on the row-level See all affordance instead of a stray plus button.
- [x] Progress range control now matches the board's inline 7d / 30d / 90d / 1y selector instead of a menu pill.
- [ ] Further tune Protocol Detail date rows and metric strip truncation against the board.

## Deep Flow Mapping

- Add/edit vial: Inventory + Edit Protocol visual language.
- Add/edit supply: Inventory visual language.
- Site rotation editor: Log Shot body map and chip language.
- Quick check-in: Weekly Review recap + Log Shot chip language.
- Workout capture: Progress support cards.
- Progress photo add/edit: Progress Evidence grid.
- Share Summary: Weekly Review + Settings grouped rows.
- Trust Vault: Settings + Share Summary privacy rows.
- Permissions: Settings widgets/Health card language.
- Rewards details: Companion badges/collectibles.

## 2026-04-24 Late Fidelity Pass

- [x] Added a deterministic mockup-fidelity seed for the board state: Tirzepatide, BPC-157, CJC-1295, IGF-1 LR3, BAC Water, supplies, site options, rewards, progress, and nutrition/hydration targets.
- [x] Prevented the mockup QA launch from being overwritten by persisted shell data so screenshot comparison stays stable.
- [x] Retuned Today mascot crop, reward/progress text, medication chart sizing, support rings, and vial runway data.
- [x] Retuned Log Shot reward visibility so the banner only appears after a real action in normal app use while remaining visible in QA board captures.
- [x] Retuned Log Shot body map, compact inventory row, site chips, and Mark as Taken visibility.
- [x] Retuned Companion hero scale, next-form preview, artifact taps, collection cards, and weekly mastery copy.
- [x] Retuned Protocol rows to show board-style cadence/day pills instead of the incorrect Active pill.
- [x] Retuned Progress mockup values to 84% nutrition, 1.6 L hydration, 4 workouts, and board-style support captions.
- [x] Retuned Inventory labels so rows read as protocol name plus vial subtitle, with a compact editable supplies footer.
- [x] Build passed with the latest pass.
- [x] Full regression passed: 207 tests, 0 failures.

Latest comparison artifacts:

- `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/live-density-pass-20260424-210016/paired-six-density-pass.jpg`
- `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/live-height-pass-20260424-210624/paired-three-height-pass.jpg`

Remaining visual risk:

- Dynamic Island/status-bar simulator chrome still makes Codex screenshots visually differ from the board thumbnails.
- Mascot art, exact phone crop, and some card vertical rhythm still need hand-tuning against the final board/device target.

## 2026-04-24 22:30 Fidelity Continuation

- [x] Re-ran `git status --short` before continuing; worktree remains dirty from the broader rebuild and was not cleaned/reset/reverted.
- [x] Rebuilt and reinstalled the latest Kairo app on the iPhone 16e and iPhone 17 Pro simulators.
- [x] Corrected board-facing copy/data leaks: Today and Log Shot now use `SubQ`, board-style `Today, 12:30 PM`, and `Due in 2h 35m` in the mockup-fidelity seed instead of internal kind/cadence text.
- [x] Corrected Companion board state so the Log shot quest is complete in QA captures and the XP detail reads `1,260 / 2,000 XP`.
- [x] Corrected Companion collection headers from chevrons to board-style `View all` copy while preserving individual badge/collectible taps.
- [x] Kept badge/collectible individual detail sheets and collection-level reward navigation functional.
- [x] Tightened the Log Shot body-map stroke treatment and collection icon fit.
- [x] Build passed after the latest pass.
- [x] Full regression passed again: 207 tests, 0 failures.

Latest artifacts:

- Six-screen comparison: `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/current-perfect-pass-20260424-222809/paired-six-current.jpg`
- Full test result: `/Users/donghokang/Developer/Atlas/atlas-ios/.derived-data-kairo-mockup-protocol-system/Logs/Test/Test-Atlas-2026.04.24_22-29-10--0400.xcresult`

Still not acceptable to call perfect:

- Mascot rendering/crop and generated-art tone still do not exactly match the board.
- Vial art remains code-drawn rather than board-identical art.
- Card optical weight and a few vertical rhythms are close but still not exact across Today, Log Shot, Companion, Protocols, Progress, and Inventory.

## 2026-04-25 00:05 No-Crop Asset Pass

- [x] Re-ran `git status --short` before editing; the repo remains broadly dirty from the rebuild and no cleanup/reset/revert was performed.
- [x] Replaced the app-facing Aetherion stage 1 mockup asset with the 1024px standalone source mascot from `Mascots/AetherionStage1Mockup`, not a board crop.
- [x] Regenerated vial, weekly crystal, badge, collectible, Today mascot panel, and Companion stage PNG contents as standalone source-art/drawn assets so screenshot-crop-derived production surfaces are no longer referenced.
- [x] Added missing `Contents.json` metadata for `KairoBoardBodyMap.imageset` in the app and widget catalogs to remove asset-catalog unassigned-child warnings.
- [x] Tuned Today and Companion mascot scale/crop using the source mascot asset, and added a native SwiftUI Companion backdrop layer.
- [x] Rebuilt, installed, and recaptured the six primary board screens on the iPhone 16e simulator.
- [x] Reinstalled the latest verified build on both booted simulators: iPhone 16e and iPhone 17 Pro.
- [x] Full regression passed: 207 tests, 0 failures.

Latest artifacts:

- Six-screen no-crop comparison: `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/no-crop-final-capture-20260424-235754/paired-six-board-crops.jpg`
- Vial-focused comparison: `/Users/donghokang/Developer/Atlas/output/mockup-inspection/fidelity-six/wider-vial-pass-20260425-000123/paired-vial-pass.jpg`
- Generated asset preview: `/Users/donghokang/Developer/Atlas/output/mockup-inspection/generated-highres-art-assets-20260424.jpg`
- Full test result: `/Users/donghokang/Developer/Atlas/atlas-ios/.derived-data-kairo-mockup-protocol-system/Logs/Test/Test-Atlas-2026.04.25_00-02-37--0400.xcresult`

Still not acceptable to call perfect:

- The standalone mascot source is now honest high-res art, but it still does not exactly match the board mascot silhouette/color proportions.
- The vial is no longer skinny, but its cap/outline still lacks the exact small-scale realism of the board.
- Companion still needs stronger board-faithful top-stage composition, especially mascot silhouette, platform, backdrop, and vertical density.

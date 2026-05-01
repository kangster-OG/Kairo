# Kairo Mockup Board Fidelity Checklist - 2026-04-24

Source board: `IMG_5314.png`, 12 iPhone screens: Today, Log Shot, Companion, Protocols, Protocol Detail, Edit Protocol, Progress, Progress Photos, Inventory/Supplies, Calculator, Weekly Review, Settings/Integrations.

## Global Visual System

- [x] Warm off-white canvas instead of generic white/blue health app chrome.
- [x] Deep Atlas/Kairo green primary actions, selected segments, tabs, and charts.
- [x] Restrained amber reward accents for XP, crystals, streaks, and collectibles.
- [x] Blue reserved for hydration and functional support states.
- [x] SF/system typography, zero letter spacing, no forced uppercase.
- [x] Compact 8 pt card/control radii and soft low shadows.
- [x] Compact bottom tab pill shelf on root tabs.
- [ ] Root tab shelf and routed headers need another pass for exact board spacing and icon scale.
- [x] Empty states should preserve the board's premium visual density without pretending to have user data.

## Art And Signature Details

- [x] Real Aurielle/Aetherion mascot assets render in app, not generic placeholders.
- [x] Companion screen uses real staged mascot art and locked next-form preview.
- [x] Crystal collectible/mastery reward art is present and visible.
- [x] Injection site body map uses actual site metadata and suggested-site selection.
- [x] Vial icons render as richer glass inventory objects with real fill when inventory exists.
- [ ] Today hero should feel closer to the board's larger mascot/product-card composition.
- [x] Progress Photos empty state needs board-like front/side/back capture slots instead of a plain empty message.
- [x] Protocol cards need denser vial/runway metadata in board style.
- [x] Inventory empty state uses a denser operational setup card.

## 1. Today

- [x] Header shows Kairo, daily streak, XP/reward currency.
- [x] Mascot hero, level pill, progress bar.
- [x] Next Shot card with protocol, dose line, medication-level curve, due badge, Log Shot CTA.
- [x] Protein/hydration/workout rings are tappable and save/open real capture flows.
- [x] Check-in and Progress Photo actions exist.
- [x] Inventory Runway routes to real inventory.
- [ ] Hero art scale and card proportions need closer board matching.
- [x] Next Shot chart should include more board labels/marker detail.

## 2. Log Shot

- [x] Reward banner with mascot and XP.
- [x] Real upcoming occurrence is used.
- [x] Injection site selection is first-class.
- [x] Body map supports front/back mapped sites.
- [x] Pain slider, side-effect chips, notes, vial runway, Mark as Taken.
- [x] Mark as Taken writes a real log and returns to Today.
- [ ] Body-map illustration needs one more polish pass for board-level anatomy/spacing.
- [ ] Vial decrement feedback should be more explicit after a linked vial exists.

## 3. Companion

- [x] Level ring, large mascot, locked next form, quests, badges, collectibles, weekly mastery.
- [x] Crystal mastery card renders with readable dark treatment.
- [x] Settings gear route works and can return.
- [ ] Collection icons should be a closer match to the board's badge/crystal/object set.
- [x] Weekly mastery needs weekday chip row.
- [ ] Weekly mastery needs one more exact board spacing pass.

## 4. Protocols

- [x] Protocol list cards route to detail.
- [x] Add Protocol, Calculator, Share Summary actions are functional.
- [x] Schedule Summary exists.
- [x] Header needs active-count/see-all density like board.
- [x] Protocol cards need tighter board metadata: next date, runway, cadence pills, selected weekdays.
- [ ] Empty/duplicate-data states need to retain premium density.

## 5. Protocol Detail

- [x] Header/detail card, cadence metrics, schedule, adherence, medication chart.
- [x] Site Rotation section is real and editable.
- [x] Recent shots and Inventory Runway are backed by data.
- [x] Edit routes to protocol editor.
- [x] Medication chart needs axis labels and date labels closer to board.
- [ ] Detail layout needs top-right menu affordance if required by board.

## 6. Edit Protocol

- [x] Medication, dose, cadence, route, weekday, time, concentration, reminders, runway, notes, save.
- [x] Save writes real protocol create/update.
- [ ] Editor controls need closer board spacing and row styling.
- [ ] Time and concentration rows should feel more like board disclosure rows.

## 7. Progress

- [x] Weight, body fat, consistency, symptoms, support habits, progress photos, workout, weekly review routes.
- [x] Range menu is functional.
- [x] Body trend card needs mini charts like board.
- [x] Consistency should render as `6 of 7` with day dots/percent visuals, not just large text.
- [x] Health Integrations tile should be present.
- [x] Progress screen needs board-style compact two-column lower cards.

## 8. Progress Evidence

- [x] Timeline/Compare segmented control.
- [x] Real photo and measurement editor sheets exist.
- [x] Existing photos render when user has data.
- [x] Empty state needs premium capture-slot grid matching front/side/back board visual language.
- [ ] Compare mode needs stronger affordance.

## 9. Inventory / Supplies

- [x] Inventory list opens from Today and has back navigation.
- [x] Add Vial and Add Supply open real editor sheets.
- [x] Vials/consumables show real low-stock/runway labels when present.
- [x] Empty inventory needs board-like operational setup state instead of sparse screen.
- [ ] Vial rows need richer mockup-style glass icon, label, dose/runway, chevron.

## 10. Calculator

- [x] Concentration, desired dose, result, syringe-unit guide, save profile are functional.
- [x] Copy stays neutral as math helper, not dosing advice.
- [x] Syringe guide should match board table styling more closely.
- [ ] Result card needs exact typography/spacing pass.

## 11. Weekly Review

- [x] Reward banner, adherence, support habits, side effects, wins, focus, complete review.
- [x] Completion action is backed by real model call.
- [x] Needs date range subtitle like board.
- [ ] Support Habit icons/spacing and side-effect recap table need closer board match.

## 12. Settings / Integrations

- [x] Health integrations, widgets, reminders, companion/rewards, data/privacy.
- [x] Share Summary route opens real export builder.
- [x] Settings opened from Companion can return.
- [ ] Some rows should route to mockup-styled detail/editor surfaces rather than older native screens.
- [ ] Settings row heights and trailing labels need final spacing pass.

## Current Verification

- [x] Simulator smoke tested: Today, Log Shot, Companion, Protocols, Protocol Detail/Edit, Progress, Progress Photos, Weekly Review, Settings, Share Summary, Inventory, Calculator.
- [x] Full XCTest passed after latest fixes: 205 tests, 0 failures.

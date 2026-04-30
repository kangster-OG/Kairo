# Current Thread Handoff: Onboarding, Aetherion, and Logo Direction

Date: 2026-04-26

## Product Context

Kairo is a premium iPhone peptide protocol system. The native iOS app under `atlas-ios/` remains the primary product path. The app is not a marketplace, sourcing app, vendor comparison app, medical advice app, dosing advice app, diagnostic app, AI chatbot product, calorie scanner, social app, shop loop, or broad game economy.

The user expects exact visual translation from approved mockups into native SwiftUI, not loose inspiration. When the user provides or approves a mockup, treat every layout, spacing, copy, icon, animation beat, and information relationship as intentional unless they explicitly authorize a change.

## Important User Feedback From This Thread

- Do not reinterpret approved onboarding mockups. Translate them one-to-one into the native app.
- Do not add unauthorized labels, pills, boxes, shells, containers, background cards, or extra copy.
- Do not use placeholder dashboard values after onboarding. Onboarding inputs must drive preview screens and app state wherever those values are shown.
- Do not call static or weak animation work “premium.” If animation is not truly polished, acknowledge it and improve it.
- Do not constrain mascot or crystal vial pod art inside visible card/shell containers unless the user explicitly approves that treatment.
- The user strongly rejected the most recent simplified logo attempt from this thread. Do not use that attempted generated logo as source of truth.
- The user wants the Kairo logo to keep the original outer flame/leaf shape, become simpler and more iPhone/App Store friendly, and remove the diamond/gem detail in the center. The latest attempt failed because it did not preserve the original shape closely enough.
- Aetherion should be redesigned to use the same teal/cream crystalline palette as Aurielle, but with a more masculine/male-user-appealing silhouette and posture. Do not generate random objects or educational/infographic art. Keep it a Kairo companion.

## Recent Onboarding State To Verify

The onboarding work is in `atlas-ios/Packages/AtlasFeatures/Sources/AtlasFeatures/AtlasOnboardingFeatures.swift`.

Recent accepted or partially accepted direction:

- The old generic onboarding should be replaced by the new Kairo onboarding flow.
- The initial intro should be clean and logo-led, with copy: `Your unified peptide protocol`.
- The Cal AI-style early demo should be adapted using screenshots/components from Kairo itself, not generic mockup boards.
- The second demo flow was requested to be removed.
- The GLP vs peptide branch must be selectable and unselectable, and onboarding must branch correctly.
- Date/number inputs should be genuinely interactive, not decorative.
- The companion hatch should only appear in the hatching/companion interaction part of onboarding, not in unrelated screens.
- The crystal vial/capsule should not sit inside a visible shell/card.
- The desired hatch interaction at the end of this thread: use the original middle crystal vial/capsule art, make it tremble, show a real 0-100 loading progress bar, then advance to the next flow.
- The companion naming title should be `Congrats! Name your companion`.
- Companion choice should preserve mystery: Aurielle and Aetherion should be shown as shaded/silhouette/outline forms before hatch, not fully revealed.
- Aurielle in onboarding should match the in-app Aurielle color/style.
- The user asked for capsule and Aurielle PNGs after fixing Aurielle.

## Health Connect Screen Direction

The health connect screen should match the reference structure closely:

- Use the real Apple Fitness/Health-style icon asset that exists on iPhone/simulator where possible; do not hand-draw a fake Apple Fitness icon.
- Use the Kairo app icon/logo without a black background.
- Remove unauthorized pills such as `Walking`, `Running`, `Yoga`, `Sleep`.
- Use clean broken arrow lines and a central check mark, not a reset/sync icon.
- Keep it neat, simple, and close to the reference layout.

## Data/Placeholder Direction

The user asked to scan for placeholders. Work was started to remove hardcoded `178.4 lb`, `24.1%`, and `Alex`-style placeholders in the onboarding/progress path. Fresh threads should re-check:

- No hardcoded `Alex` in user-facing app screens.
- No static body trend values when onboarding profile values exist.
- Plan-ready and final preview screens should reflect selected peptide/GLP path, dose, frequency, schedule, weight/goal, and companion name.
- TextField placeholder labels are fine, but fake user data is not.

## Rejected Work / Do Not Treat As Approved

The latest logo generation attempt in this thread was rejected by the user. If these files currently contain that bad attempt, replace them with a better design rather than preserving them:

- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingLogoMark.imageset/kairo-onboarding-logo-mark.png`
- `atlas-ios/Atlas/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`
- `atlas-ios/Atlas/Assets.xcassets/KairoAppIconPreview.imageset/`

The user specifically said the generated logo did not keep the original shape. Next attempt should start by viewing the previous/original logo asset if recoverable from git history or prior artifacts, then simplify it without changing the silhouette.

## Aetherion Direction

Do not make Aetherion random or unrelated. Aetherion should be:

- Same teal/cream crystalline material family as Aurielle.
- More masculine than Aurielle through stance, facial structure, horns/crystal spikes, wings/body posture, and proportion.
- Premium and companion-like, not scary, not childish, not a generic monster.
- Full-body PNG with transparent background for onboarding use.
- Distinct from Aurielle, but obviously part of the same Kairo companion family.

Existing assets worth inspecting before generating anything new:

- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAurielleStage1.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAetherionStage1.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAetherionStage2.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/KairoOnboardingAetherionStage3.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage2Mockup.imageset/`
- `atlas-ios/Atlas/Assets.xcassets/AtlasMascotAetherionStage3Mockup.imageset/`

If using image generation, use Aurielle and the existing Aetherion images as strict visual references. Reject outputs that become diagrams, educational graphics, random items, or unrelated logos.

## Recommended Fresh Thread First Steps

1. Read the standard repo docs requested by the user in fresh threads, including `AGENTS.md`, `README.md`, `atlas-ios/README.md`, `docs/fresh-codex-thread-prompt.md`, and the current handoff docs.
2. Run `git status --short` before editing.
3. Inspect the current onboarding in simulator before changing it.
4. Inspect current logo/app icon assets and determine whether the rejected logo attempt is present.
5. Recover or recreate the original Kairo logo shape, then simplify it while preserving the silhouette and removing only the central diamond/gem.
6. Redesign or replace Aetherion only after comparing against Aurielle and existing Aetherion stage assets.
7. Build and run on the iPhone 16e simulator (`9EDCEC16-48C4-4640-B318-CA98ABE59559`) before reporting completion.


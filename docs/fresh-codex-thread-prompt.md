# Fresh Codex Thread Prompt

Copy and paste this into a fresh Codex thread when starting new Atlas work.

---

We are working in the real Atlas repo at:

`/Users/donghokang/Developer/Atlas`

Before doing anything else, please read:

1. `AGENTS.md`
2. `README.md`
3. `atlas-ios/README.md`
4. `docs/codex-launch-handoff.md`
5. `docs/backlog-execution-handoff.md`
6. `docs/current-thread-handoff-2026-04-21.md`
7. `docs/current-thread-handoff-2026-04-24.md`
8. `docs/current-thread-handoff-2026-04-25-kairo-fidelity.md`
9. `docs/current-thread-handoff-2026-04-26-onboarding-aetherion-logo.md`
10. `docs/current-thread-handoff-2026-04-29-launch-widgets-watch.md`
11. `docs/current-thread-handoff-2026-04-30-limited-preview-logo-localization.md`
12. `docs/current-thread-handoff-2026-04-30-app-store-release-screenshot-recovery.md`
13. `docs/current-thread-handoff-2026-05-01-app-store-review-resubmission.md`
14. `docs/atlas-post-onboarding-visual-north-star-2026-04-23.md`
15. `docs/atlas-true-fidelity-pass-handoff-2026-04-22.md`
16. `docs/fresh-codex-visual-fidelity-prompt-2026-04-23.md` if the work involves visual fidelity or post-onboarding UI direction

If this thread touches UI, UX, design, widgets, SwiftUI presentation, mascot, rewards, motion, or polish, also read:

17. `docs/ios-premium-ui-rubric.md`
18. `docs/ios-ui-audit-2026-04-10.md`
19. `docs/ios-ui-skill-stack.md`
20. `docs/ios-ux-execution-playbook-2026-04-15.md`
21. `docs/ios-redesign-context-2026-04-14.md`
22. `docs/ios-ui-polish-thread-handoff-2026-04-16.md`
23. `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` if mascot/rewards/motion/polish are involved
24. Use current native mascot assets and active Kairo companion/widget code if mascot/rewards/media/widgets are involved; do not use archived mascot concept docs
25. `docs/ios-onboarding-paywall-handoff-2026-04-16.md` if onboarding, trial paywalls, premium conversion, or protocol setup ordering are involved
26. `docs/atlas-onboarding-ux-deep-dive-2026-04-21.md` if onboarding, app UX, or competitor research is involved
27. `docs/atlas-cal-ai-finch-dream-ux-2026-04-21.md` if Cal AI, Finch, companion hatching, or dream-product UX is involved
28. `docs/atlas-dream-onboarding-locked-storyboard-2026-04-21.md` if onboarding sequence, density, or copy structure is involved
29. `docs/atlas-dream-onboarding-motion-spec-2026-04-21.md` if onboarding transitions, animation, or interaction polish is involved

Important context:

- Atlas is a premium iPhone peptide protocol system.
- The user-facing app name is now Kairo, though older docs, project names, and bundle identifiers may still say Atlas.
- It is not a marketplace, sourcing app, social app, or medical advice app.
- The native iOS app in `atlas-ios/` is the primary product path.
- The current post-onboarding product direction is calm, tactile, premium, simple, mascot-forward, comprehensive, and utility-first.
- Privacy/trust still matters, but it should no longer be overemphasized as the headline differentiator.
- The main product promise is: `Build your peptide protocol.`
- The April 24 and April 25 handoffs confirm the post-onboarding app has been rebuilt around the locked mockup board. Do not restart the mockup rebuild from scratch.
- The April 29 launch/widgets/watch handoff captures the latest launch-readiness, Supabase, onboarding, progress-photo, Aetherion, widget, and App Intents state.
- The April 30 handoff captures the latest limited-preview gating, existing-account onboarding exits, rebuilt widget requirements, Watch Companion/App Intents direction, cleaned Kairo logo/app icon replacement, last-chance discount product, and localization guidance.
- The April 30 App Store release/screenshot recovery handoff captures App Store Connect state, support/privacy URLs, product IDs, privacy/no-tracking decisions, rejected screenshot attempts, raw screenshot artifact locations, and the warning not to upload screenshots before visual approval.
- The May 1 App Store review/resubmission handoff supersedes the April 30 screenshot-recovery state for App Store submission work: the final screenshots were approved and uploaded, ASO metadata was updated, the first rejection was a metadata-only 3.1.2(c) EULA-link issue, legal links were added, and the app was resubmitted with status `Waiting for Review`.
- The user expects exact mockup-board visual fidelity while preserving real app functionality. Do not strip functionality or make a static shell to match screenshots.
- The next default phase is release hardening and concrete regression fixes, not broad feature expansion.
- App Store payments expect real StoreKit/App Store Connect products `com.dkang2000.Atlas.kairo.pro.annual` and `com.dkang2000.Atlas.kairo.pro.monthly`, each with a 7-day introductory free trial configured.
- The last-chance discount path expects `com.dkang2000.Atlas.kairo.pro.annual.lastchance` for a `$39.99/year` annual membership. Do not show this CTA while purchasing the normal `$59.99/year` annual product.
- App Store metadata must preserve functional legal links for subscription review:
  - Privacy Policy: `https://chloeverse.io/kairo/privacy`
  - Terms of Use (EULA): `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- A future native-paywall polish pass should verify the app itself exposes subscription title, duration, price, restore/access behavior, and functional Privacy Policy / Terms of Use links. Do not ship a new binary that removes or hides these legal links.
- Supabase is still part of the launch architecture for auth/sync/live review. Do not remove it as dead code without a fresh architecture decision.
- Widgets exist through `AtlasWidgetsExtension`; Watch-accessible functions currently exist through embedded App Intents/Shortcuts in `AtlasIntentsExtension`, not a full standalone watchOS app.
- Limited preview users should be able to switch between all five tabs (`Today`, `Log`, `Protocols`, `Progress`, `Companion`), but tapping real app features should present an upgrade prompt for free trial/monthly/annual/last-chance annual purchase.
- The current Kairo logo/app icon is the cleaned teal flame/leaf mark without the small central V-shaped diamond/chevron remnant. Do not restore the old artifact.
- App Store screenshot work is currently sensitive: previous composites were rejected for bad proportions/device frame/header spacing, but the final approved 10-shot set was uploaded from `output/app-store-screenshots/iphone-6-5-real-device-frame-v2-20260430`. Do not replace screenshots unless the user explicitly asks, and show local previews first.
- Avoid generic health-app UI and avoid noisy/childish gamification.
- For mascot art:
  - portrait art = in-app hero/detail/export
  - sticker art = medium in-app cards
  - pixel art = widgets and compact live-state surfaces
- Ambient mascot behavior should be anchored, optional, event-based, and calm. Do not turn it into free-roaming or always-on clutter.
- Onboarding is intentionally long and proof-led. The free-trial paywall belongs before full protocol creation, after Atlas has shown enough premium differentiation to make the trial feel earned.
- The current DREAM onboarding target is roughly 180-plus user-facing states across 12 chapters. Do not shorten it by default.
- The companion hatches or awakens only after Atlas has built enough of the user's readiness map, Day 1 plan, Trust Vault defaults, and first-week preview. Do not make hatch-a-mascot the first screen.
- Do not change the avatar design unless explicitly asked. The hatching/egg/capsule/signal-core moment is a presentation layer around the existing companions.
- The latest documented TestFlight upload before the mockup rebuild was Atlas 1.0 build `2026042103`, uploaded on 2026-04-21 after the final onboarding copy pass.

Working style:

- Please inspect the actual codebase before making assumptions.
- Please explicitly use the Build iOS Apps UI skill medley when relevant: `build-ios-apps:swiftui-ui-patterns`, `build-ios-apps:swiftui-view-refactor`, `build-ios-apps:ios-debugger-agent`, and `build-ios-apps:swiftui-performance-audit` when density/render quality matters. Also use `build-ios-apps:swiftui-liquid-glass` or `build-ios-apps:ios-app-intents` when those surfaces are involved.
- Please use the combined UX lens in `docs/ios-ux-execution-playbook-2026-04-15.md`.
- Please QA test periodically as you work.
- Please do not stop at analysis if implementation is clearly requested.

Additional UX / copy rules:

- Avoid root tabs becoming endless feature stacks.
- Prefer progressive disclosure over showing every subsystem at the root.
- Do not add fake-sounding `Atlas ...` helper narration or other LLM-ish filler copy.
- Keep onboarding copy concise and human. Avoid strategy-doc phrases like `privacy posture`, `generated artifact`, `operating system fantasy`, or repeated explanatory helper text in the UI.
- For broad UI cleanup, use `docs/ios-ui-polish-thread-handoff-2026-04-16.md` for the standing rules on stat tiles, keyboard exits, quick actions, recap clutter, and copy pruning.
- The current docked bottom tab shelf is the baseline; do not default to transparent tab-bar experiments unless explicitly asked.
- For mascot work, prefer event-based reactions over adding more permanent mascot homes.
- For visual fidelity work, use `docs/fresh-codex-visual-fidelity-prompt-2026-04-23.md` as the copy-paste starter prompt and `docs/atlas-post-onboarding-visual-north-star-2026-04-23.md` as the mockup design reference.
- Also use `docs/current-thread-handoff-2026-04-25-kairo-fidelity.md` for the latest Kairo visual-fidelity state, latest screenshot artifacts, test result, and known simulator workflow.
- Use `docs/current-thread-handoff-2026-04-29-launch-widgets-watch.md` for the latest launch-readiness, backend, widgets, watch-functions, onboarding, progress-photo, Aetherion, and App Store caveats.
- Treat the new mockup direction as the visual standard for the entire post-onboarding app, including deep editors, widgets, compact states, and settings, not only Today / Log Shot / Companion.
- Only touch onboarding when explicitly asked, and when you do, preserve the latest branching/multi-select fixes and make onboarding inputs drive preview/app state.
- If doing UI work, use the screenshot QA harness in `scripts/atlas-mockup-screenshot-qa.sh` and compare against the latest intentional references. The latest closeout sweep captured 37 routes at `output/mockup-screenshot-qa/final-confidence-2026-04-24/`.

Once you’ve read the docs above, run `git status --short`, give me a very short summary of what Atlas is building and what you understand the current product/design direction to be, then wait for my feature request.

---

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

If this thread touches UI, UX, design, widgets, SwiftUI presentation, mascot, rewards, motion, or polish, also read:

7. `docs/ios-premium-ui-rubric.md`
8. `docs/ios-ui-audit-2026-04-10.md`
9. `docs/ios-ui-skill-stack.md`
10. `docs/ios-ux-execution-playbook-2026-04-15.md`
11. `docs/ios-redesign-context-2026-04-14.md`
12. `docs/ios-ui-polish-thread-handoff-2026-04-16.md`
13. `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` if mascot/rewards/motion/polish are involved
14. `docs/mascot-concepts/atlas-mascot-asset-matrix.md` if mascot/rewards/media/widgets are involved
15. `docs/ios-onboarding-paywall-handoff-2026-04-16.md` if onboarding, trial paywalls, premium conversion, or protocol setup ordering are involved
16. `docs/atlas-onboarding-ux-deep-dive-2026-04-21.md` if onboarding, app UX, or competitor research is involved
17. `docs/atlas-cal-ai-finch-dream-ux-2026-04-21.md` if Cal AI, Finch, companion hatching, or dream-product UX is involved
18. `docs/atlas-dream-onboarding-locked-storyboard-2026-04-21.md` if onboarding sequence, density, or copy structure is involved
19. `docs/atlas-dream-onboarding-motion-spec-2026-04-21.md` if onboarding transitions, animation, or interaction polish is involved

Important context:

- Atlas is a privacy-first, local-first, premium iPhone protocol operating system.
- It is not a marketplace, sourcing app, social app, or medical advice app.
- The native iOS app in `atlas-ios/` is the primary product path.
- The product direction is calm, tactile, premium, informative, intuitive, and trust-heavy.
- Avoid generic health-app UI and avoid noisy/childish gamification.
- For mascot art:
  - portrait art = in-app hero/detail/export
  - sticker art = medium in-app cards
  - pixel art = widgets and compact live-state surfaces
- Ambient mascot behavior should be anchored, optional, event-based, and calm. Do not turn it into free-roaming or always-on clutter.
- Onboarding is intentionally long and proof-led. The free-trial paywall belongs before full protocol creation, after Atlas has shown enough premium differentiation to make the trial feel earned.
- The current DREAM onboarding target is 180 user-facing states across 12 chapters. Do not shorten it by default.
- The companion hatches or awakens only after Atlas has built enough of the user's readiness map, Day 1 plan, Trust Vault defaults, and first-week preview. Do not make hatch-a-mascot the first screen.
- Do not change the avatar design unless explicitly asked. The hatching/egg/capsule/signal-core moment is a presentation layer around the existing companions.
- The latest TestFlight upload from this thread was Atlas 1.0 build `2026042103`, uploaded on 2026-04-21 after the final onboarding copy pass.

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

Once you’ve read the docs above, run `git status --short`, give me a very short summary of what Atlas is building and what you understand the current product/design direction to be, then wait for my feature request.

---

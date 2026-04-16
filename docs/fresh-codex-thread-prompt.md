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

If this thread touches UI, UX, design, widgets, SwiftUI presentation, mascot, rewards, motion, or polish, also read:

6. `docs/ios-premium-ui-rubric.md`
7. `docs/ios-ui-audit-2026-04-10.md`
8. `docs/ios-ui-skill-stack.md`
9. `docs/ios-ux-execution-playbook-2026-04-15.md`
10. `docs/ios-redesign-context-2026-04-14.md`
11. `docs/ios-ambient-mascot-system-handoff-2026-04-16.md` if mascot/rewards/motion/polish are involved
12. `docs/mascot-concepts/atlas-mascot-asset-matrix.md` if mascot/rewards/media/widgets are involved

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
- The current docked bottom tab shelf is the baseline; do not default to transparent tab-bar experiments unless explicitly asked.
- For mascot work, prefer event-based reactions over adding more permanent mascot homes.

Once you’ve read the docs above, give me a very short summary of what Atlas is building and what you understand the current product/design direction to be, then wait for my feature request.

---

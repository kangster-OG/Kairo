# Fresh Codex Prompt - Atlas Visual Fidelity Push

Copy and paste this into a fresh Codex thread when continuing Atlas visual fidelity work.

---

We are working in the real Atlas repo at:

`/Users/donghokang/Developer/Atlas`

Before doing anything else, read:

1. `AGENTS.md`
2. `README.md`
3. `atlas-ios/README.md`
4. `docs/codex-launch-handoff.md`
5. `docs/backlog-execution-handoff.md`
6. `docs/current-thread-handoff-2026-04-21.md`
7. `docs/fresh-codex-thread-prompt.md`
8. `docs/atlas-post-onboarding-visual-north-star-2026-04-23.md`
9. `docs/atlas-true-fidelity-pass-handoff-2026-04-22.md`

If touching UI, UX, design, SwiftUI presentation, widgets, mascot, rewards, motion, polish, or TestFlight readiness, also read:

1. `docs/ios-premium-ui-rubric.md`
2. `docs/ios-ui-audit-2026-04-10.md`
3. `docs/ios-ui-skill-stack.md`
4. `docs/ios-ux-execution-playbook-2026-04-15.md`
5. `docs/ios-redesign-context-2026-04-14.md`
6. `docs/ios-ui-polish-thread-handoff-2026-04-16.md`
7. `docs/ios-ambient-mascot-system-handoff-2026-04-16.md`
8. `docs/ios-onboarding-paywall-handoff-2026-04-16.md`
9. `docs/atlas-onboarding-ux-deep-dive-2026-04-21.md`
10. `docs/atlas-cal-ai-finch-dream-ux-2026-04-21.md`
11. `docs/atlas-dream-onboarding-locked-storyboard-2026-04-21.md`
12. `docs/atlas-dream-onboarding-motion-spec-2026-04-21.md`

Run `git status --short` before editing. There may be substantial local app changes, generated files, derived data, screenshots, and build outputs. Do not clean, reset, revert, or delete anything unless explicitly asked.

Important product context:

- Atlas is a premium iPhone peptide protocol system.
- The native iOS app in `atlas-ios/` is the primary product path.
- Atlas is not a marketplace, sourcing app, social app, medical advice app, dosing advice app, or diagnostic app.
- Privacy/trust is still important, but it is not the main headline anymore.
- The product should primarily sell: `Build your peptide protocol.`
- The app needs to be comprehensive but simple: protocol tracking, shot logging, vial runway, site rotation, side effects, food/protein, hydration, workouts, health integrations, widgets, companion XP/evolution, quests, badges, collectibles, and progress.

Mockup design direction:

- Use `docs/atlas-post-onboarding-visual-north-star-2026-04-23.md` as the source of truth.
- Treat the mockup direction as the design language for the entire post-onboarding product, not only the three reference screens.
- The approved mockup has three key screens: Today, Log Shot, Companion.
- Today should feel like: mascot hero -> next shot -> medication chart -> Log Shot CTA -> protein/hydration/workout rings -> inventory runway -> compact tabs.
- Log Shot should feel like one clean ritual: shot -> site -> pain/side effects -> notes -> vial decrement -> Mark as Taken -> support prompt -> mascot reward.
- Companion should feel Finch/Pokemon-inspired: level ring, large mascot, locked next form, quests, badges, collectibles, weekly mastery.
- Keep both mascot lines, Aurielle and Aetherion.
- Do not change the avatar designs unless explicitly asked.
- Use warm off-white surfaces, deep green primary, restrained amber reward, rare blue for hydration.
- Use SF/system default typography, not `.rounded`.
- Keep letter spacing 0.
- Avoid forced uppercase.
- Prefer 8pt card/control radii; preserve the compact bottom tab pill shelf.
- Keep shadows soft and low.
- Avoid generic health-app UI, noisy gamification, shame/fear tactics, AI-ish filler copy, and privacy-as-the-headline copy.

Current implementation state from the latest fidelity pass:

- `AtlasTypographyCandidate.current` defaults to `.system`.
- Shared text roles are smaller and calmer.
- Shared and local post-onboarding presentation code has been aggressively moved away from `.rounded` fonts, forced uppercase, and large-radius cards.
- `AtlasMetricStrip` wraps more than three metrics into a compact two-column grid.
- Today, Log, Protocols, Progress, Companion, Protocol Detail, and widgets were moved closer to the mockup direction.
- Build and focused tests passed after the pass:
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesExtensionProjectionSnapshot`
  - `AtlasTests/AtlasPhaseOneTests/testRefreshShellDataWritesSupportRingsProjectionSnapshot`
  - `AtlasTests/AtlasPhaseOneTests/testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection`

Visual references in the repo:

- `output/true-fidelity-pass-2026-04-22/13-today-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/14-log-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/15-companion-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/16-protocols-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/17-progress-strict-final.png`
- `output/true-fidelity-pass-2026-04-22/18-protocol-detail-final.png`

Important instruction:

- Ignore onboarding for now unless explicitly asked. It will be rebuilt separately.
- Do not shorten DREAM onboarding by default when onboarding work resumes.
- For post-onboarding work, keep pushing visual fidelity across every flow: root tabs, protocol detail, inventory, food, workout, health, widgets, settings, empty states, deep editors, and modals.
- Use simulator screenshots to verify. Be ruthless about mismatches: typography, density, card radius, shadows, hierarchy, mascot prominence, CTA clarity, tab chrome, widgets, and deep editor flows.

After reading, give me a very short summary of what Atlas is building, what visual direction you understand, and the current working-tree state. Then continue with the requested task.

---

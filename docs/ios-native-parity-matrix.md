# Atlas Native iOS Parity Matrix

This matrix reflects the current repo state, not the earlier phased migration plan.

| Area | React Native oracle status | Native iOS status | Notes |
| --- | --- | --- | --- |
| Onboarding | Implemented | Complete | Native onboarding, guest path, account boundary, privacy-first branching |
| Guest/account boundary | Implemented | Complete | Guest-first and local-first preserved |
| Today | Implemented | Complete | Next due, overdue, upcoming, quick logging |
| Timeline | Implemented | Complete | Immutable history plus filters and grouping |
| Library | Implemented | Complete | Protocol list/detail, inventory/calculator entry points |
| Insights | Implemented | Complete | Metrics, trends, amount-in-system, Episode Intelligence |
| Settings | Implemented | Complete | Privacy, reminder, sync scaffold, health scaffold, reset/import/Trust Vault entry points |
| Protocol create/edit | Implemented | Complete | Core field editing and revision-aware regeneration |
| Protocol Change Studio | Implemented | Complete | Preview-before-commit, future-only revisions, audits |
| Reminders | Implemented | Complete | Native local reminders, actions, privacy-aware copy |
| Logging | Implemented | Complete | Taken, skipped, rescheduled with immutable events |
| Inventory/vials | Implemented | Complete | Linking, switch-over, depletion, manual corrections |
| Calculator | Implemented | Complete | Saved profiles and vial attachment |
| Site tracking | Implemented | Complete | Site management, logging picker, rotation cues |
| Trust Vault | Implemented | Complete | Full/alias/discreet rendering, aliases, biometric gating, audit trail |
| Selective sharing | Implemented | Complete | Preview, encrypted bundles, bounded scopes |
| Raw exports | Implemented | Complete | Deterministic JSON and CSV exports |
| Atlas import | Implemented | Complete | Atlas JSON import bridge and migration-safe handling |
| Universal migration | Deferred in old plan | Complete | Atlas JSON, Atlas CSV, generic CSV, manual text import |
| Provider handoff | Deferred in old plan | Complete | Static snapshot output with bounded scope |
| Review Mode | Deferred in old plan | Complete | Private, read-only static review packs |
| Metrics/custom metrics | Implemented | Complete | Logging, CRUD, exports, insights |
| Episode Intelligence | Deferred in old plan | Complete | Deterministic episode windows and pattern cards |
| Widgets | Scaffolded | Compile-ready scaffold | Main business logic remains intentionally narrow |
| App Intents / Shortcuts | Scaffolded | Compile-ready scaffold | Main business logic remains intentionally narrow |
| Health integration | Scaffolded | Scaffold-only | Availability/status shell only, richer HealthKit still deferred |
| Full sync execution | Optional/future | Not complete by design | Still optional and non-blocking |

## Release note
Native parity is complete in code. Remaining work before broader beta distribution is release hardening and physical-device/TestFlight verification.

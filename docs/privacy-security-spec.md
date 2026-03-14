# Privacy and Security Spec

## Product stance
Atlas is privacy-first. That means:
- guest mode is fully supported
- cloud sync is optional and deferred
- the product works locally without account creation
- sensitive information is minimized, masked when possible, and never expanded casually

## Hard boundaries
Atlas must not introduce:
- medical advice
- treatment recommendations
- dose optimization
- sourcing flows
- marketplace features

## Current implementation baseline
Today the app already stores onboarding state locally and supports privacy preference capture during onboarding. Privacy settings are asked before any health connection prompt.

Current onboarding privacy fields:
- discreet notifications
- hide sensitive labels
- biometric lock later
- anonymous analytics opt-in

## Data-classification policy
### Low sensitivity
Suitable for AsyncStorage:
- onboarding draft
- lightweight UI state
- view preferences
- feature flags

### Medium sensitivity
Prefer database layer with privacy-aware repository access:
- protocol definitions
- log history
- inventory balances
- reminder settings
- insight summaries

### High sensitivity
SecureStore only:
- auth tokens
- refresh tokens
- device secrets
- future encryption or lock keys

## Storage rules
### AsyncStorage
Keep only:
- onboarding draft
- small, non-relational app preferences
- ephemeral UX state

Do not expand AsyncStorage into the long-term source of truth for:
- logs
- inventory
- schedule occurrences
- protocol definitions

### Database layer
Use for:
- durable structured product data
- offline querying
- timeline reconstruction
- inventory and schedule joins

### SecureStore
Use for:
- token material
- secrets required for optional cloud mode

## Guest mode requirements
- onboarding works without sign-in
- protocol creation works without sign-in
- reminders work without sign-in
- logging works without sign-in
- timeline and inventory work without sign-in
- no dark-pattern upgrade walls in the main loop

## Notification policy
### Standard mode
- notifications may use explicit product copy

### Discreet mode
- generic copy
- no sensitive medication names in notification titles
- lock-screen safe language by default

## Health integration policy
- health connection is optional
- health connection happens late in onboarding
- no health connection requirement for core use
- no broad permission requests without a direct user-triggered reason

## Auth and sync policy
- sync is phase two, not part of the local-first MVP
- auth should layer on top of existing guest data rather than forcing a reset
- guest-to-account upgrade must preserve local records

## Deletion and portability requirements
When the data layer is introduced, Atlas must support:
- clear local data
- local export path planning
- account unlink without orphaning guest-mode access

## Engineering requirements
- keep privacy behavior centralized, not scattered across UI conditionals
- use explicit types for privacy and auth boundaries
- keep the schedule engine free of cloud assumptions
- never silently remove discreet mode features

## Trust Vault policy
Trust Vault becomes the single privacy control center and execution layer for:
- alias mode
- discreet labels
- selective sharing policy
- biometric gating
- sensitive-action auditing

V1 must remain fully local-first and fully usable in guest mode.

## Unified privacy rendering policy
Atlas should render privacy-sensitive content by explicit surface policy instead of ad hoc conditionals.

### Policy levels
- `full`: canonical protocol, compound, vial, and metric labels
- `discreet`: generic privacy-safe labels suitable for lock-screen-safe and glance-safe UI
- `alias`: user-authored codenames in place of canonical labels

### Surface requirements
#### Today
- due cards, quick-action modal, and paused-state cards must honor alias or discreet rendering
- no raw compound labels when alias mode or discreet mode is active

#### Timeline
- event summaries must use privacy-safe wording
- sensitive history labels must never bypass alias/discreet policy

#### Library
- protocol cards should show canonical names only in `full` mode
- alias mode should show codename first, with no accidental compound leakage

#### Insights
- protocol-linked sections must render alias/discreet labels consistently
- estimate and trend sections must not reintroduce raw labels when other surfaces are redacted

#### Settings / Trust Vault
- previews may show exactly what each mode will reveal, but must stay within the currently selected privacy policy unless the user explicitly opens a compare preview

#### Notifications
- `full` may use canonical labels
- `discreet` forces generic copy
- `alias` uses codename if and only if the notification surface is user-visible and the user selected alias-safe output

#### Exports / selective sharing
- bundle preview and bundle output must share the same formatter path
- no export may include canonical labels if alias mode was selected for that bundle

## Alias mode policy
- alias mode is a rendering layer, not a data migration
- canonical names remain stored locally as the source of truth
- aliases attach at the protocol level and may optionally define a compound-facing alias label
- turning alias mode off restores canonical labels locally without rewriting historical data
- exports, shares, reminders, Today, Timeline, Library, Insights, and Trust Vault previews must all honor alias mode when selected

## Biometric gate policy
Biometric gating in V1 is for sensitive actions, not for every screen transition.

### Sensitive actions
- opening Trust Vault when biometric lock is enabled
- creating a selective share/export bundle
- revealing canonical labels while alias/discreet mode is active
- changing alias mode
- changing biometric lock state

### Rules
- use local biometric auth when available
- degrade gracefully on unsupported devices
- guest users and signed-in users both use the same local gate
- do not hard-block the rest of the app if biometrics are unavailable or temporarily fail

## Selective sharing policy
All sharing defaults to least privilege.

### V1 scopes
- current protocol only
- selected protocol + recent timeline
- last 30 days logs
- symptoms only
- inventory only
- summary only
- custom date range

### Rules
- preview-before-export is required
- user must see exactly what will be included
- share bundles are read-only snapshots, never live linked data
- no bundle may contain more data than the selected scope
- imports must remain deterministic, inspectable, and dry-run capable in future phases

## Encrypted bundle policy
- local bundle generation first
- explicit manifest versioning
- explicit integrity metadata
- encryption keys remain device-local in V1
- no open public links in V1
- optional cloud-backed review links remain a later feature-flagged concept only

## Sensitive-action audit policy
Atlas should expose a user-visible audit trail for:
- export created
- selective share created
- alias changed
- privacy mode changed
- biometric lock enabled or disabled
- Trust Vault unlocked

Rules:
- append-only
- local-first
- privacy-safe summaries
- visible to the user inside Trust Vault

## Protocol Change Studio privacy rules
- preview computation must remain local-first
- future-change previews must not require cloud access
- audit entries must be stored locally with the same privacy posture as protocols and logs
- preview, export, and audit summaries must honor discreet labels and alias mode
- change summaries must stay operational and neutral, never drifting into medical guidance

## Threat model for Trust Vault + Selective Sharing V1
Primary risks:
- shoulder-surfing or lock-screen leakage
- accidental export of more data than intended
- alias mode inconsistencies across surfaces
- unencrypted local bundles left in cache/shared storage
- biometric gate bypass on unsupported devices handled incorrectly
- sensitive-action history not visible to the user

Mitigations:
- unified privacy formatter
- preview and export share the same deterministic selection pipeline
- least-privilege default scopes
- encrypted local bundle format with integrity metadata
- biometric gating only around sensitive actions, with graceful fallback
- append-only sensitive-action audit trail

## Open security decision
The future database layer should be evaluated for at-rest protection strategy on device. The current codebase does not yet implement encrypted local domain storage.

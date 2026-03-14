# Trust Vault + Selective Sharing V1

## Purpose
Trust Vault turns Atlas privacy from scattered toggles into a real product system.

It has two jobs:
- act as the control center for privacy behavior across the app
- let a user create a bounded, previewed, encrypted, read-only share/export bundle

V1 must work fully in guest mode and stay local-first by default.

## Current baseline
Already implemented:
- guest mode
- discreet mode onboarding preferences
- privacy-aware reminder copy
- local exports
- local-first structured database
- SecureStore-backed auth/session storage foundation

Not yet implemented:
- alias mode across the app
- unified privacy rendering policy
- Trust Vault screen
- biometric-sensitive action gates
- selective share scopes
- encrypted local share bundles
- sensitive-action audit viewer

## Product goals
- make privacy behavior visible and understandable
- let users share only what they choose
- prevent canonical labels from leaking when alias or discreet mode is active
- keep sharing deterministic and inspectable
- keep cloud optional and out of the critical path

## V1 scope
### Included
- protocol aliases / codenames
- per-surface privacy rendering policy
- local biometric gate where supported
- selective sharing scopes with preview-before-export
- encrypted local bundle generation
- user-visible sensitive-action audit trail
- least-privilege defaults

### Excluded
- public share links
- social sharing layer
- live collaborative access
- server-required privacy features
- AI-generated privacy summaries

## Unified privacy rendering policy
### Modes
- `full`
  - show canonical protocol, compound, vial, and metric labels
- `discreet`
  - show generic privacy-safe labels
- `alias`
  - show user-authored protocol codenames and alias-safe secondary labels

### Precedence
1. biometric gate does not change labels, it only protects access to sensitive flows
2. bundle/share preview mode decides `full`, `discreet`, or `alias` for that output
3. in the app shell, Trust Vault privacy mode decides rendering
4. reminder privacy mode can further reduce output, but never expand beyond the selected app privacy mode

### Surface matrix
#### Today
- protocol title, compound chip, overdue text, quick-log modal title
- `discreet`: generic label
- `alias`: codename
- `full`: canonical name

#### Timeline
- event summary and subtitle
- `discreet`: generic event language
- `alias`: codename in event summary where appropriate
- `full`: canonical protocol label

#### Library
- protocol cards, detail header, future-plan actions
- alias mode shows codename as primary label
- compound label is hidden or alias-safe

#### Insights
- protocol-linked trend labels
- amount-in-system estimate cards
- inventory burn-down cards
- custom metric attachment labels

#### Settings / Trust Vault
- preview cards should display exactly what the chosen policy would reveal
- sensitive compare previews require explicit reveal if they would show canonical labels

#### Notifications
- `full`: canonical protocol label allowed
- `discreet`: generic reminder text only
- `alias`: alias label allowed if the user chose alias-safe reminder output

#### Exports / selective shares
- preview and exported payload must use the same formatter path
- no post-preview formatting changes

## Alias model
### Data model
Recommended new local table:
- `protocol_aliases`

Fields:
- `id`
- `protocol_id`
- `alias_label`
- `alias_compound_label`
- `created_at`
- `updated_at`
- `archived_at`

Rules:
- one active alias per protocol in v1
- canonical protocol and compound names remain unchanged
- alias mode is presentation only
- historical log events stay canonical in storage; rendering applies alias at read time

### Why protocol-level aliases first
- simplest safe model
- keeps revision and inventory links stable
- avoids compound-wide alias side effects across multiple protocols

## Selective sharing scope model
### Supported scopes
- `current_protocol_only`
- `protocol_with_recent_timeline`
- `last_30_days_logs`
- `symptoms_only`
- `inventory_only`
- `summary_only`
- `custom_date_range`

### Scope contract
Each scope resolves to:
- included entity types
- optional protocol ids
- optional date range
- privacy rendering mode
- output notes for omitted data

### Proposed type
```ts
type SelectiveShareScope =
  | { kind: 'current_protocol_only'; protocolId: string; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'protocol_with_recent_timeline'; protocolId: string; days: 30; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'last_30_days_logs'; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'symptoms_only'; dateRange?: DateRange; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'inventory_only'; protocolId?: string; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'summary_only'; protocolId?: string; renderMode: 'full' | 'discreet' | 'alias' }
  | { kind: 'custom_date_range'; dateRange: DateRange; protocolIds?: string[]; include: ShareFacet[]; renderMode: 'full' | 'discreet' | 'alias' };
```

## Encrypted bundle format
### Goals
- deterministic
- inspectable before encryption
- versioned
- integrity-protected
- local-file based

### Proposed bundle layout
```text
atlas-share-bundle/
  manifest.json
  payload.enc
```

### Manifest v1
```json
{
  "manifestVersion": 1,
  "bundleId": "uuid",
  "createdAt": "ISO timestamp",
  "scope": {
    "kind": "current_protocol_only"
  },
  "renderMode": "alias",
  "encrypted": true,
  "cipher": "aes-256-gcm",
  "kdf": "pbkdf2",
  "integrity": {
    "payloadSha256": "hex"
  },
  "counts": {
    "protocols": 1,
    "logEvents": 4,
    "vials": 1
  },
  "notes": [
    "Static snapshot only",
    "No live sync link"
  ]
}
```

### Payload shape
- deterministic JSON object
- records sorted consistently by type and timestamp/id
- explicit omissions and redactions

## Audit log semantics
### New local table
- `sensitive_action_audit_events`

### Event types
- `export_created`
- `selective_share_created`
- `alias_changed`
- `privacy_mode_changed`
- `biometric_lock_changed`
- `vault_unlocked`

### Audit payload
- event type
- surface
- scope kind if applicable
- protocol id if applicable
- render mode used
- manifest version if applicable
- timestamp

Rules:
- append-only
- visible to the user
- summary copy must honor current alias/discreet policy

## Audit viewer IA
Trust Vault contains:
1. privacy mode section
2. alias management section
3. biometric gate section
4. selective sharing section
5. sensitive-action history

The viewer should support:
- latest first
- filter by event type
- filter by protocol where applicable
- detail drawer for payload metadata

## Biometric gate rules
### V1 gates
- opening Trust Vault if the user enabled app lock
- revealing canonical labels from alias/discreet state
- creating an encrypted share bundle
- changing alias settings
- toggling biometric lock

### Behavior
- use local biometric auth when available
- fallback to a local warning/confirm flow if unavailable
- do not block Today logging, reminders, or the main loop if the gate is unavailable
- gate failure never deletes data or changes privacy settings

## Local-first boundary
### Fully local in V1
- privacy profile
- aliases
- biometric preference state
- selective share preview generation
- encrypted bundle generation
- sensitive-action audit trail

### Optional future extension only
- cloud-backed review links
- remote bundle escrow
- account-tied Trust Vault settings sync

## Proposed data-model changes
### Tables
- `privacy_profile`
- `protocol_aliases`
- `sensitive_action_audit_events`

### Repository additions
- `PrivacyProfileRepository`
- `ProtocolAliasRepository`
- `SensitiveActionAuditRepository`

### Formatter layer
Add a dedicated privacy rendering module that becomes the only approved label path for:
- Today
- Timeline
- Library
- Insights
- Settings
- notifications
- exports
- selective share preview

## Implementation phases
### Phase 1: foundation
- schema and migration changes
- privacy profile repository
- alias repository
- sensitive-action audit repository
- unified privacy formatter contracts

### Phase 2: app rendering
- replace ad hoc privacy rendering with formatter policy
- Library, Insights, Settings adoption
- protocol alias create/edit UI
- Trust Vault shell

### Phase 3: gating
- biometric adapter
- sensitive action guard wrapper
- audit entries for privacy-sensitive actions

### Phase 4: selective sharing
- scope selector
- preview engine
- deterministic payload builder
- encrypted local bundle writer
- static snapshot copy and confirmation flow

### Phase 5: QA hardening
- privacy leak pass
- alias/off restore pass
- guest-mode pass
- export/bundle integrity pass

## Test matrix
### Unit / service
- alias formatter returns correct labels for `full`, `discreet`, and `alias`
- bundle preview and exported payload contain identical record counts and ids
- date-range scoping excludes out-of-range records
- encryption manifest metadata matches payload
- sensitive-action audit rows are appended correctly
- biometric gate wrapper blocks protected actions and leaves unprotected actions alone

### Integration
- Today/Timeline/Library/Insights/Settings all honor the same privacy formatter
- reminder preview and export output stay privacy-consistent
- guest mode can create a selective share bundle
- turning alias mode off restores canonical labels without changing stored protocol names

### Regression
- canonical names are never lost when alias mode changes
- selective share includes only requested scope
- no bundle preview mismatch
- no privacy leak in audit viewer summaries

## Manual QA checklist
See:
- `qa/trust-vault-selective-sharing-manual-checklist.md`

## Acceptance criteria
- Trust Vault exists as a real privacy control center
- alias mode is available and does not corrupt canonical data
- a user can preview a bounded selective share before commit
- exported bundle contents exactly match the previewed scope
- encrypted local bundle generation works in guest mode
- sensitive-action history is visible
- canonical labels do not leak when alias or discreet mode is active

## Tradeoffs
- protocol-level aliases are simpler and safer than compound-global aliases in v1
- local encrypted bundles are safer and more deterministic than cloud links in v1
- a single formatter layer reduces privacy bugs, even though it requires a larger initial refactor
- biometric gating is limited to sensitive actions so Atlas stays fast and usable

## Open questions
- whether v1 bundle encryption should use a user-entered passphrase or device-held key wrapping by default
- whether alias mode should support separate aliases for vial labels in v1 or only protocol/compound display
- whether the audit viewer belongs under Settings or a dedicated Trust Vault tab entry point

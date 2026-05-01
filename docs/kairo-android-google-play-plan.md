# Kairo Android + Google Play Plan

Date: 2026-05-01

## Decision

Build Kairo for Android as a native Kotlin + Jetpack Compose app inside this repo.

Target repo shape:

```text
/Users/donghokang/Developer/Kairo
|-- atlas-ios/          # current shipped native iOS product path
|-- kairo-android/      # new native Android app
|-- backend/            # Supabase migrations/functions shared by clients
|-- docs/               # product contracts, launch handoffs, release checklists
|-- landing-page/
`-- scripts/
```

Rationale:

- Kairo is already a native SwiftUI iPhone product. Android should be equally native rather than a React Native rebuild that leaves iOS and Android on different product foundations.
- The product depends on platform-specific systems: StoreKit/Play Billing, HealthKit/Health Connect, WidgetKit/Android widgets, App Intents/Android shortcuts, notifications, secure storage, biometric gates, and native file/share surfaces.
- A monorepo keeps shared product rules, backend contracts, screenshots, legal links, release notes, and launch docs together.

Do not create a separate Android repo unless the team later needs isolated release ownership, separate permissions, or independent vendor/team workflows.

## Product Definition

Kairo on Android must be a clone of the Kairo product contract, not a static visual copy.

It should include:

- onboarding
- limited preview mode
- five bottom destinations:
  - Today
  - Log
  - Protocols
  - Progress
  - Companion
- protocol creation/edit/detail
- GLP, peptide, and custom protocol support
- shot logging
- site rotation
- vial/inventory runway
- side-effect/context capture
- hydration/protein/workout support signals
- progress evidence
- companion progression
- widgets
- reminders/notifications
- local export/review surfaces
- optional Supabase auth/sync/live review
- subscription paywall and restore/access management

It must not include:

- dosing advice
- medical recommendations
- diagnostic or treatment claims
- sourcing, marketplace, vendor comparison, or price comparison
- AI chatbot product expansion
- social feed/community/shop loops
- full calorie-tracker sprawl

## Recommended Android Stack

- Language: Kotlin
- UI: Jetpack Compose + Material 3 primitives, custom Kairo design system
- App architecture: single-activity Compose app with typed navigation
- Local database: Room over SQLite
- Local preferences: DataStore
- Secure storage: Android Keystore-backed encrypted storage for auth/session secrets
- Background work: WorkManager where exact timing is not required
- Reminders: Android notification channels plus alarms where user-visible schedule precision is required
- Subscriptions: Google Play Billing Library
- Auth/sync/live review: Supabase Android SDK or direct bounded API client
- Health: Health Connect
- Widgets: Glance/App Widgets where feasible; native RemoteViews if layout control requires it
- Camera/photos: Android Photo Picker and CameraX where needed
- Testing: JUnit, Kotlin coroutines test, Room in-memory tests, Compose UI tests, Play Billing sandbox tests

## Product IDs And Entitlements

iOS StoreKit products:

- `com.dkang2000.Atlas.kairo.pro.annual`
- `com.dkang2000.Atlas.kairo.pro.monthly`
- `com.dkang2000.Atlas.kairo.pro.annual.lastchance`

Android should use matching semantic products in Google Play Console, likely:

- `kairo.pro.monthly`
- `kairo.pro.annual`
- `kairo.pro.annual.lastchance`

Final Android product IDs can differ, but the entitlement model must remain identical:

- monthly: Pro access, 7-day intro trial
- annual: Pro access, 7-day intro trial
- annual last chance: Pro access, $39.99/year discount path, no hidden purchase of the normal annual product

The app must expose:

- subscription title
- subscription duration
- subscription price
- restore/access management
- functional Privacy Policy link
- functional Terms/EULA link

Legal links to preserve until Android-specific legal text is approved:

- Privacy Policy: `https://chloeverse.io/kairo/privacy`
- Terms/EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

## Google Play Requirements To Track

Official references:

- Target API requirement: `https://developer.android.com/google/play/requirements/target-sdk`
- Health apps declaration: `https://support.google.com/googleplay/android-developer/answer/14738291`
- Personal developer testing requirements: `https://support.google.com/googleplay/android-developer/answer/14151465`

Current planning assumptions as of 2026-05-01:

- New Google Play apps and app updates need to target Android 15 / API 35 or higher.
- Kairo will need the Play Console Health apps declaration because it is health-adjacent.
- Kairo will need a Play data safety form that accurately reflects local storage, optional Supabase sync/auth, purchases, diagnostics if added, and Health Connect usage.
- If the developer account is a newer personal Play developer account, production access may require closed testing with enough opted-in testers for the required test period before production can be requested.

Re-check these official docs before Play submission because Play Console policy is time-sensitive.

## Shared Product Contract

Before broad Android UI implementation, create a product contract that Android can implement against:

- protocol schedule model
- historical event model
- inventory/vial runway calculations
- limited preview access rules
- subscription entitlement state
- companion progression rules
- privacy render modes
- export/review scope rules
- Supabase sync object boundaries
- legal/paywall copy requirements

Source of truth order:

1. native iOS implementation under `atlas-ios/`
2. `atlas-ios/README.md`
3. current handoff docs under `docs/`
4. shared Android contract docs created for this effort
5. historical React Native material, only as product-oracle context where still accurate

## Milestones

### Milestone 0: Project Scaffold

Deliver:

- `kairo-android/` Gradle project
- package/application ID decision
- min/target SDK decision
- debug/release build variants
- Compose theme and Kairo design tokens
- app icon placeholders sourced from approved Kairo icon assets
- CI-friendly Gradle commands documented

Done when:

- debug app builds
- release app bundle builds locally
- emulator launches into a real shell, not a demo placeholder

### Milestone 1: Core Domain + Local Persistence

Deliver:

- Kotlin domain models for protocol, occurrence, shot log, inventory, progress, companion, user settings, and entitlement state
- Room schema and migrations
- local-first repositories
- deterministic date/time injection for tests
- seed/demo state for emulator QA

Done when:

- unit tests cover schedule generation, missed/overdue handling, shot logging, inventory decrement, limited preview state, and companion points
- local data survives app relaunch

### Milestone 2: Five-Tab Product Shell

Deliver:

- Today tab
- Log tab
- Protocols tab
- Progress tab
- Companion tab
- settings/account access from Companion or a clear equivalent
- limited preview tab switching with real feature taps gated

Done when:

- limited preview users can switch tabs
- real actions show upgrade prompt
- paid/Pro state can perform actions

### Milestone 3: Onboarding + Limited Preview

Deliver:

- Android onboarding adapted from current Kairo onboarding strategy
- account start modes
- health/legal disclaimers
- companion selection
- premium trial paywall
- limited preview entry
- existing-account sign-in path

Done when:

- limited preview creates local guest state
- existing account sign-in skips onboarding to auth/account route
- onboarding inputs propagate into app preview state

### Milestone 4: Protocol + Shot Logging Vertical Slice

Deliver:

- create protocol
- edit protocol
- protocol detail
- next due display
- log shot
- skip/reschedule
- site selection
- inventory decrement
- basic reminders

Done when:

- a user can create a protocol, see next due, log a shot, and see history/inventory update locally

### Milestone 5: Billing + Entitlements

Deliver:

- Google Play Billing integration
- monthly/annual/last-chance annual products
- restore purchases
- entitlement persistence
- paywall legal links
- limited preview upgrade prompt

Done when:

- sandbox purchases grant Pro access
- restore works
- last-chance product purchases only the last-chance product
- missing/misconfigured products fail safely

### Milestone 6: Supabase Auth + Sync + Live Review

Deliver:

- email/password sign-in
- Google sign-in
- session persistence
- guest-to-account upgrade path
- bounded snapshot sync
- live review create/revoke/fetch path if Android launch scope includes review sharing

Done when:

- Android can sign in, sign out, restore session, sync, and recover safely without making cloud mandatory

### Milestone 7: Progress, Companion, Widgets, Health

Deliver:

- progress evidence flow
- progress photo capture/import
- companion progression surfaces
- Android widgets for companion/activity/next due where feasible
- Health Connect import for approved signals
- notification privacy modes

Done when:

- widgets render real local projection data
- Health Connect is opt-in and source-attributed
- companion surfaces use Aetherion/Aurielle only, not retired names

### Milestone 8: Play Store Release Readiness

Deliver:

- signed Android App Bundle
- Play App Signing setup
- app content declarations
- health apps declaration
- data safety form
- privacy policy URL
- support URL
- subscription products
- internal testing track
- closed testing track if required
- store listing copy/screenshots
- production release checklist

Done when:

- internal testers can install from Google Play
- billing sandbox works
- Play Console has no blocking policy/setup issues
- production submission has explicit approval

## Suggested Directory Structure

```text
kairo-android/
|-- app/
|   |-- build.gradle.kts
|   `-- src/
|       |-- main/
|       |   |-- AndroidManifest.xml
|       |   |-- java/com/dkang2000/kairo/
|       |   |   |-- MainActivity.kt
|       |   |   |-- KairoApplication.kt
|       |   |   |-- data/
|       |   |   |-- domain/
|       |   |   |-- billing/
|       |   |   |-- sync/
|       |   |   |-- health/
|       |   |   |-- widgets/
|       |   |   `-- ui/
|       |   `-- res/
|       |-- test/
|       `-- androidTest/
|-- build.gradle.kts
|-- settings.gradle.kts
`-- README.md
```

## First Implementation Slice

Start with:

1. Scaffold `kairo-android/`.
2. Build the shell: Today, Log, Protocols, Progress, Companion.
3. Implement Room-backed local state for:
   - onboarding completion
   - limited preview access
   - protocols
   - generated due occurrences
   - immutable shot logs
4. Implement one real flow:
   - create weekly GLP protocol
   - show next due on Today
   - log shot
   - update history and inventory
   - gate the same action in limited preview

This first slice should be real, testable Android product code. It should not be a screenshot shell.

## Open Questions

- Final Android application ID: likely `com.dkang2000.kairo`, but confirm before Play Console setup.
- Android subscription product IDs: match semantic names but confirm final IDs before coding Play Billing.
- Whether Android v1 includes live review or defers it behind auth/sync.
- Whether Android v1 includes progress photo capture or launches with progress metrics first.
- Whether Android store listing should use the same App Store screenshot copy/order or a separate Play-optimized set.
- Whether Android terms should keep Apple's standard EULA temporarily or move to Kairo-specific terms before Play submission.

## Quality Bar

- Android must feel like Kairo, not a generic Material health tracker.
- It should preserve Kairo's calm, premium, protocol-first identity.
- It should use Android-native interaction patterns while matching iOS product behavior.
- It should avoid fake placeholders in any flow marked complete.
- It should keep local-first behavior as a product guarantee.
- It should ship to Google Play only after billing, legal links, health declarations, privacy/data safety, and real-device QA are complete.

# Post-Onboarding Information Architecture

## Purpose
This document defines the app structure after the current onboarding flow completes.

Today, onboarding routes to a Today placeholder. The next build phase replaces that placeholder with a real post-onboarding product shell.

## IA principles
- Today is the home surface.
- The daily job is always obvious: what is next due and what should be logged.
- Logging must be reachable in one tap from Today.
- Inventory and timeline are supporting surfaces, not the initial landing screen.
- Guest mode must see the same core information architecture as signed-in users.
- Privacy settings must shape labels, notifications, and lock behavior without changing the core nav model.

## Primary app structure
Recommended v1 post-onboarding navigation:
- `Today`
- `Timeline`
- `Inventory`
- `Settings`

Secondary flows presented modally or as stacked routes:
- `Protocol setup / edit`
- `Log event`
- `Reminder details`
- `Insight details`
- `Auth`

## Surface definitions
### Today
Home screen and main retention surface.

Primary modules:
- next due card
- overdue state
- quick log button
- protocol summary
- low inventory warning
- upcoming reminders
- recent activity preview
- insight teaser

Primary actions:
- log now
- view protocol
- snooze or review reminder context
- go to inventory
- go to timeline

### Timeline
Chronological history across the retention loop.

Shows:
- generated future occurrences
- logged completions
- skips or misses
- inventory adjustments
- protocol changes

Grouping:
- today
- this week
- older

### Inventory
Operational tracking surface.

Shows:
- current item balances
- estimated runout
- low-stock alerts
- recent adjustments

Actions:
- add inventory
- adjust manually
- mark opened/consumed

### Settings
Control surface for:
- privacy and discreet mode
- notifications
- health connections
- account mode
- export/delete local data

## Route recommendation
Suggested route layout for the next phase:

```text
app/
  (tabs)/
    _layout.tsx
    today/index.tsx
    timeline/index.tsx
    inventory/index.tsx
    settings/index.tsx
  protocols/
    index.tsx
    new.tsx
    [protocolId].tsx
    [protocolId]/edit.tsx
  log/
    new.tsx
    [occurrenceId].tsx
  insights/
    index.tsx
```

## Entry behavior
- First install with incomplete onboarding: route into onboarding.
- Completed onboarding with no real protocols yet: Today shows an empty-state CTA to create the first protocol.
- Completed onboarding with at least one active protocol: Today opens on the next due view.

## Empty states
### No protocols
- explain what a protocol is
- CTA: `Create your first protocol`

### No logs yet
- show next due and explain the logging flow
- CTA: `Log first event`

### No inventory tracked yet
- CTA: `Add inventory`

## Discreet mode impact
Discreet mode changes presentation, not information architecture:
- sensitive labels can be masked
- notifications can be generic
- lock prompts can be added later
- routes and core actions stay stable

## Deferred structures
The following are intentionally not part of the immediate post-onboarding IA:
- marketplace or sourcing areas
- dosing recommendation surfaces
- treatment advice flows
- social or community tabs
- analytics-heavy dashboards

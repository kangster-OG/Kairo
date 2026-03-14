# Atlas Export v1 Spec

## Canonical migration contract
- Atlas JSON export is the canonical migration/import format for native iOS
- CSV remains human-readable export only and is not an import target
- import must support dry-run preview and diff before commit

## Required bundle shape
Top-level JSON bundle should carry:
- manifest metadata
- protocol records
- revision and revision-rule records when available
- immutable log records
- reminder preferences and reminder rows when available
- vial, site, metric, and calculator records when available
- privacy profile, aliases, and sensitive-action audit rows when available

## Compatibility rule
Current React Native exports may be legacy snapshots that do not yet include every dataset needed for full parity. Native import must therefore support:
- spec-complete v1 bundles
- legacy RN bundles with backfilled defaults during staging

## Import rules
- validate first
- compute dry-run counts and diff summary
- never commit partial imports
- preserve stable ids and timestamps when possible
- avoid data loss by backing up existing native data before a replace-import flow

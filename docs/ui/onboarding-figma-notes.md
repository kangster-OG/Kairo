# Atlas onboarding Figma notes

## Visual direction observed
- white background
- soft blue accent
- rounded cards and buttons
- minimal chrome
- compact progress dots/bar in header
- single question per screen
- bottom anchored CTA
- simple typography hierarchy
- pill-style option buttons
- highly guided wizard flow

## Strengths of the current concept
- low-friction onboarding
- easy to understand at a glance
- strong mobile-first feel
- good candidate for reusable onboarding engine
- summary screen gives satisfying completion moment

## Product changes to make before implementation
1. Add auth/account mode before sensitive setup
   - continue as guest
   - sign in
   - create account

2. Add privacy/discreet mode before health integrations
   - discreet notifications
   - hide sensitive labels
   - biometric lock later

3. Replace binary GLP vs peptide split with:
   - GLP
   - Peptide
   - Both
   - Explore first / later

4. Remove "rate us" from first-run onboarding
   - trigger after real product value later

5. Keep body metrics optional
   - gender, age, goal weight, height/weight can be skippable

6. Move health app connection late in the flow
   - after user sees the value of the setup

## Recommended onboarding flow v1
1. Splash
2. Intro / value prop
3. Account mode
4. Privacy/discreet mode
5. Track what?
   - GLP
   - Peptide
   - Both
   - Later
6. Optional profile enrichment
   - gender
   - age
   - goal weight
   - current height/weight
7. Branch-specific setup
   - GLP path
   - peptide path
   - both path
8. Connect health apps
9. Plan ready summary
10. Route to Today placeholder

## GLP branch screens
- which GLP are you taking?
- how often do you take it?
- what day do you inject?
- what is your current dose?
- how long have you been on it?
- what is your main goal?
- biggest challenge right now?

## Peptide branch screens
- which peptide(s) are you taking?
- how often do you take it?
- how experienced are you?
- what time do you usually inject?
- what is your current dose?
- what is your main goal?

## Both branch
Run GLP branch first, then peptide branch, then show a combined summary.

## Design tokens inferred from export
- primary blue: approx #4E86F7
- primary blue pressed: approx #3F76E8
- pale blue background accents: #EAF2FF to #F5F8FF
- neutral border: #E6ECF5
- text primary: #111827
- text secondary: #6B7280
- white: #FFFFFF
- button radius: 12-16
- card radius: 20-24
- horizontal padding: 24
- main CTA height: 48-52

## Component list
- OnboardingScaffold
- ProgressHeader
- AnswerOptionButton
- MultiSelectOptionButton
- BottomCTA
- HeaderBackButton
- UnitToggle
- WheelPickerField
- SummaryCard
- PermissionCard

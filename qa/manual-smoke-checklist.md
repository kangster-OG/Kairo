# Android Emulator QA Checklist

## Setup
- [ ] Start Metro with `npx expo start --dev-client --clear`
- [ ] Ensure `adb reverse tcp:8081 tcp:8081` is active
- [ ] Install/open the Android dev build
- [ ] Clear app data before each first-run path check

## Launch
- [ ] Atlas opens from the emulator without a red screen or blank screen
- [ ] Splash renders with the branded Atlas UI
- [ ] `Continue` advances to intro

## Entry and account
- [ ] Intro renders and `Get started` advances into onboarding
- [ ] `I already have an account` opens the auth placeholder
- [ ] Account mode screen renders
- [ ] `Continue as guest` can be selected
- [ ] `Create account` can be selected
- [ ] `Sign in` can be selected

## Privacy and track type
- [ ] Privacy screen renders before any health-app connection prompt
- [ ] Privacy toggles can be enabled and disabled
- [ ] Track type supports `GLP`, `Peptide`, `Both`, and `Explore first`
- [ ] No app-rating screen appears anywhere in first-run onboarding

## Optional profile
- [ ] Gender can be selected or skipped
- [ ] Age can be skipped
- [ ] Goal weight can be skipped
- [ ] Height and weight can be skipped
- [ ] Skipped profile values do not block completion

## GLP path
- [ ] GLP medication screen renders
- [ ] GLP frequency screen renders
- [ ] GLP injection day screen renders
- [ ] GLP current dose screen renders
- [ ] GLP duration screen renders
- [ ] GLP main goal screen renders
- [ ] GLP biggest challenge screen renders
- [ ] GLP summary reaches Today placeholder

## Peptide path
- [ ] Peptide selection screen renders
- [ ] Peptide frequency screen renders
- [ ] Peptide experience screen renders
- [ ] Peptide usual time screen renders
- [ ] Peptide current dose screen renders
- [ ] Peptide main goal screen renders
- [ ] Peptide summary reaches Today placeholder

## Both path
- [ ] Both path runs GLP first and peptide second
- [ ] Both path preserves separate GLP and peptide answers
- [ ] Both summary shows GLP and peptide sections
- [ ] Both summary reaches Today placeholder

## Explore first / later path
- [ ] `Explore first` skips branch-specific setup
- [ ] Later path still reaches summary and Today placeholder
- [ ] Later summary omits GLP/peptide branch sections

## Connect apps and summary
- [ ] Connect apps appears late in the flow
- [ ] `Not now` works without crashing
- [ ] Summary shows overview data
- [ ] Summary shows privacy data
- [ ] `Let's get started` routes to the Today placeholder

## Persistence and restart
- [ ] Selected account mode persists across app relaunch
- [ ] Selected privacy choices persist across app relaunch
- [ ] Selected track type persists across app relaunch
- [ ] Onboarding state survives app restart without data loss

## Navigation and UI quality
- [ ] Progress indicator is visible on all non-splash screens
- [ ] CTA buttons are tappable above the Android gesture area
- [ ] Back navigation works where shown
- [ ] Option pill selected states are visually clear
- [ ] White background and soft blue CTA styling stay consistent

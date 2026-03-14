import type { OnboardingDraft, TrackType } from '@/src/features/onboarding/schema';

type Option<T extends string> = {
  description?: string;
  label: string;
  value: T;
};

type PrivacyOption = {
  description: string;
  label: string;
  value: keyof OnboardingDraft['privacy'];
};

export const accountModeOptions: Option<'guest' | 'create' | 'signIn'>[] = [
  {
    value: 'guest',
    label: 'Continue as guest',
    description: 'Keep everything local-first now and add cloud sync later if you want.',
  },
  {
    value: 'create',
    label: 'Create account',
    description: 'Prepare for backup and future multi-device access without changing the flow.',
  },
  {
    value: 'signIn',
    label: 'Sign in',
    description: 'Resume an existing account later. For now this remains a mocked shell.',
  },
];

export const privacyOptions: PrivacyOption[] = [
  {
    value: 'discreetNotifications',
    label: 'Discreet notifications',
    description: 'Keep reminders subtle on the lock screen and in banners.',
  },
  {
    value: 'hideSensitiveLabels',
    label: 'Hide sensitive labels',
    description: 'Replace explicit terms with softer language inside the app.',
  },
  {
    value: 'biometricLater',
    label: 'Use biometric lock later',
    description: 'Save the preference now and wire the native lock in a later slice.',
  },
  {
    value: 'analyticsOptIn',
    label: 'Share anonymous analytics',
    description: 'Stay opted out by default unless you explicitly choose to help improve Atlas.',
  },
];

export const trackTypeOptions: Option<TrackType>[] = [
  {
    value: 'glp',
    label: 'GLP',
    description: 'Weight-loss or metabolic medication tracking with injection cadence and routine.',
  },
  {
    value: 'peptide',
    label: 'Peptide',
    description: 'Peptide-specific logging, timing, and experience context.',
  },
  {
    value: 'both',
    label: 'Both',
    description: 'Set up GLP first, then peptide tracking, and combine them in one summary.',
  },
  {
    value: 'later',
    label: 'Explore first',
    description: 'Browse the product now and finish protocol-specific setup later.',
  },
];

export const genderOptions: Option<'male' | 'female' | 'other' | 'skip'>[] = [
  { value: 'male', label: 'Male' },
  { value: 'female', label: 'Female' },
  { value: 'other', label: 'Other' },
  { value: 'skip', label: 'Skip' },
];

export const glpMedicationOptions: Option<string>[] = [
  { value: 'wegovy', label: 'Wegovy' },
  { value: 'ozempic', label: 'Ozempic' },
  { value: 'mounjaro', label: 'Mounjaro' },
  { value: 'zepbound', label: 'Zepbound' },
  { value: 'saxenda', label: 'Saxenda' },
  { value: 'other', label: 'Other / not listed' },
];

export const glpFrequencyOptions: Option<string>[] = [
  { value: 'weekly', label: 'Weekly' },
  { value: 'daily', label: 'Daily' },
  { value: 'every-other-week', label: 'Every other week' },
];

export const weekdayOptions: Option<string>[] = [
  { value: 'monday', label: 'Monday' },
  { value: 'tuesday', label: 'Tuesday' },
  { value: 'wednesday', label: 'Wednesday' },
  { value: 'thursday', label: 'Thursday' },
  { value: 'friday', label: 'Friday' },
  { value: 'saturday', label: 'Saturday' },
  { value: 'sunday', label: 'Sunday' },
];

export const glpDoseOptions: Option<string>[] = [
  { value: '0.25 mg', label: '0.25 mg' },
  { value: '0.5 mg', label: '0.5 mg' },
  { value: '1 mg', label: '1.0 mg' },
  { value: '1.7 mg', label: '1.7 mg' },
  { value: '2.4 mg', label: '2.4 mg' },
];

export const durationOptions: Option<string>[] = [
  { value: 'just-starting', label: 'Just starting' },
  { value: 'under-1-month', label: 'Under 1 month' },
  { value: '1-3-months', label: '1-3 months' },
  { value: '3-6-months', label: '3-6 months' },
  { value: '6-plus-months', label: '6+ months' },
];

export const glpGoalOptions: Option<string>[] = [
  { value: 'weight-loss', label: 'Weight loss' },
  { value: 'maintenance', label: 'Maintenance' },
  { value: 'metabolic-consistency', label: 'Metabolic consistency' },
  { value: 'routine-tracking', label: 'Routine tracking' },
];

export const glpChallengeOptions: Option<string>[] = [
  { value: 'remembering-doses', label: 'Remembering doses' },
  { value: 'side-effects', label: 'Managing side effects' },
  { value: 'supply-tracking', label: 'Supply tracking' },
  { value: 'staying-consistent', label: 'Staying consistent' },
];

export const peptideSelectionOptions: Option<string>[] = [
  { value: 'bpc-157', label: 'BPC-157' },
  { value: 'tb-500', label: 'TB-500' },
  { value: 'cjc-1295', label: 'CJC-1295' },
  { value: 'ipamorelin', label: 'Ipamorelin' },
  { value: 'other', label: 'Other / custom stack' },
];

export const peptideFrequencyOptions: Option<string>[] = [
  { value: 'daily', label: 'Daily' },
  { value: 'five-days', label: '5x / week' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'cyclical', label: 'Cyclical' },
];

export const peptideExperienceOptions: Option<string>[] = [
  { value: 'new', label: 'New to peptides' },
  { value: 'some', label: 'Some experience' },
  { value: 'advanced', label: 'Very experienced' },
];

export const peptideTimeOptions: Option<string>[] = [
  { value: 'morning', label: 'Morning' },
  { value: 'midday', label: 'Midday' },
  { value: 'evening', label: 'Evening' },
  { value: 'before-bed', label: 'Before bed' },
];

export const peptideDoseOptions: Option<string>[] = [
  { value: '100 mcg', label: '100 mcg' },
  { value: '250 mcg', label: '250 mcg' },
  { value: '500 mcg', label: '500 mcg' },
  { value: '1000 mcg', label: '1000 mcg' },
];

export const peptideGoalOptions: Option<string>[] = [
  { value: 'recovery', label: 'Recovery' },
  { value: 'body-composition', label: 'Body composition' },
  { value: 'performance', label: 'Performance' },
  { value: 'wellness', label: 'General wellness tracking' },
];

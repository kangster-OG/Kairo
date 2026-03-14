import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import { hasGlpBranch, hasPeptideBranch } from '@/src/features/onboarding/selectors';

export type HeightUnit = NonNullable<OnboardingDraft['profile']['heightUnit']>;
export type WeightUnit = NonNullable<OnboardingDraft['profile']['weightUnit']>;
export type OnboardingSummaryItem = { label: string; value: string };
export type OnboardingSummarySection = {
  id: 'overview' | 'privacy' | 'glp' | 'peptide';
  items: OnboardingSummaryItem[];
  title: string;
};

export function formatAccountMode(accountMode: OnboardingDraft['accountMode']): string {
  if (accountMode === 'guest') {
    return 'Guest';
  }

  if (accountMode === 'create') {
    return 'Create account';
  }

  if (accountMode === 'signIn') {
    return 'Sign in';
  }

  return 'Not set';
}

export function formatTrackType(trackType: OnboardingDraft['trackType']): string {
  if (trackType === 'later') {
    return 'Explore first';
  }

  if (!trackType) {
    return 'Not set';
  }

  return trackType.toUpperCase();
}

export function formatHeight(value: number, unit: HeightUnit): string {
  if (unit === 'cm') {
    return `${value} cm`;
  }

  const feet = Math.floor(value / 12);
  const inches = value % 12;

  return `${feet}'${inches}"`;
}

export function convertHeight(value: number, fromUnit: HeightUnit, toUnit: HeightUnit): number {
  if (fromUnit === toUnit) {
    return value;
  }

  if (toUnit === 'ft_in') {
    return Math.round(value / 2.54);
  }

  return Math.round(value * 2.54);
}

export function convertWeight(value: number, fromUnit: WeightUnit, toUnit: WeightUnit): number {
  if (fromUnit === toUnit) {
    return value;
  }

  if (toUnit === 'kg') {
    return Math.round(value / 2.20462);
  }

  return Math.round(value * 2.20462);
}

export function buildSummaryItems(draft: OnboardingDraft): { label: string; value: string }[] {
  return [
    { label: 'Account mode', value: formatAccountMode(draft.accountMode) },
    { label: 'Tracking', value: formatTrackType(draft.trackType) },
    { label: 'Gender', value: draft.profile.gender ?? 'Skipped' },
    {
      label: 'Body metrics',
      value:
        draft.profile.height && draft.profile.weight
          ? `${formatHeight(draft.profile.height, draft.profile.heightUnit ?? 'cm')} / ${draft.profile.weight} ${draft.profile.weightUnit ?? 'lb'}`
          : 'Skipped for now',
    },
  ];
}

export function buildPrivacySummary(
  draft: OnboardingDraft
): { label: string; value: string }[] {
  return [
    {
      label: 'Discreet notifications',
      value: draft.privacy.discreetNotifications ? 'On' : 'Off',
    },
    {
      label: 'Hide sensitive labels',
      value: draft.privacy.hideSensitiveLabels ? 'On' : 'Off',
    },
    {
      label: 'Biometric later',
      value: draft.privacy.biometricLater ? 'On' : 'Off',
    },
    {
      label: 'Anonymous analytics',
      value: draft.privacy.analyticsOptIn ? 'On' : 'Off',
    },
  ];
}

export function buildGlpSummary(draft: OnboardingDraft): { label: string; value: string }[] {
  return [
    { label: 'Medication', value: draft.glp.medication ?? 'Not set' },
    { label: 'Frequency', value: draft.glp.frequency ?? 'Not set' },
    { label: 'Injection day', value: draft.glp.injectionDay ?? 'Not set' },
    { label: 'Dose', value: draft.glp.dose ?? 'Not set' },
    { label: 'Duration', value: draft.glp.duration ?? 'Not set' },
    { label: 'Goal', value: draft.glp.goal ?? 'Not set' },
    { label: 'Challenge', value: draft.glp.challenge ?? 'Not set' },
  ];
}

export function buildPeptideSummary(
  draft: OnboardingDraft
): { label: string; value: string }[] {
  return [
    {
      label: 'Selection',
      value: draft.peptide.selections.length > 0 ? draft.peptide.selections.join(', ') : 'Not set',
    },
    { label: 'Frequency', value: draft.peptide.frequency ?? 'Not set' },
    { label: 'Experience', value: draft.peptide.experience ?? 'Not set' },
    { label: 'Typical time', value: draft.peptide.usualTime ?? 'Not set' },
    { label: 'Dose', value: draft.peptide.dose ?? 'Not set' },
    { label: 'Goal', value: draft.peptide.goal ?? 'Not set' },
  ];
}

export function buildSummarySections(draft: OnboardingDraft): OnboardingSummarySection[] {
  const sections: OnboardingSummarySection[] = [
    {
      id: 'overview',
      items: buildSummaryItems(draft),
      title: 'At a glance',
    },
    {
      id: 'privacy',
      items: buildPrivacySummary(draft),
      title: 'Privacy setup',
    },
  ];

  if (hasGlpBranch(draft.trackType)) {
    sections.push({
      id: 'glp',
      items: buildGlpSummary(draft),
      title: 'GLP path',
    });
  }

  if (hasPeptideBranch(draft.trackType)) {
    sections.push({
      id: 'peptide',
      items: buildPeptideSummary(draft),
      title: 'Peptide path',
    });
  }

  return sections;
}

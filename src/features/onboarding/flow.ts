import type { OnboardingDraft, TrackType } from '@/src/features/onboarding/schema';

const BASE_FLOW = [
  'splash',
  'intro',
  'accountMode',
  'privacyMode',
  'trackType',
  'gender',
  'age',
  'goalWeight',
  'heightWeight',
] as const;

const GLP_FLOW = [
  'glpMedication',
  'glpFrequency',
  'glpInjectionDay',
  'glpCurrentDose',
  'glpDuration',
  'glpMainGoal',
  'glpBiggestChallenge',
] as const;

const PEPTIDE_FLOW = [
  'peptideSelection',
  'peptideFrequency',
  'peptideExperience',
  'peptideUsualTime',
  'peptideCurrentDose',
  'peptideMainGoal',
] as const;

const TAIL_FLOW = ['connectApps', 'planReady'] as const;

export const onboardingScreenIds = [...BASE_FLOW, ...GLP_FLOW, ...PEPTIDE_FLOW, ...TAIL_FLOW] as const;

export type OnboardingScreenId = (typeof onboardingScreenIds)[number];

const onboardingScreenIdSet = new Set<string>(onboardingScreenIds);

export function isOnboardingScreenId(value: string): value is OnboardingScreenId {
  return onboardingScreenIdSet.has(value);
}

export function getBranchSequence(trackType: TrackType | null): OnboardingScreenId[] {
  if (trackType === 'glp') {
    return [...GLP_FLOW];
  }

  if (trackType === 'peptide') {
    return [...PEPTIDE_FLOW];
  }

  if (trackType === 'both') {
    return [...GLP_FLOW, ...PEPTIDE_FLOW];
  }

  return [];
}

export function getOnboardingSequence(trackType: TrackType | null): OnboardingScreenId[] {
  return [...BASE_FLOW, ...getBranchSequence(trackType), ...TAIL_FLOW];
}

export function getScreenIndex(screenId: OnboardingScreenId, draft: OnboardingDraft): number {
  return getOnboardingSequence(draft.trackType).indexOf(screenId);
}

export function getNextScreen(
  currentScreenId: OnboardingScreenId,
  draft: OnboardingDraft
): OnboardingScreenId | null {
  const sequence = getOnboardingSequence(draft.trackType);
  const currentIndex = sequence.indexOf(currentScreenId);

  if (currentIndex < 0 || currentIndex === sequence.length - 1) {
    return null;
  }

  return sequence[currentIndex + 1];
}

export function getPreviousScreen(
  currentScreenId: OnboardingScreenId,
  draft: OnboardingDraft
): OnboardingScreenId | null {
  const sequence = getOnboardingSequence(draft.trackType);
  const currentIndex = sequence.indexOf(currentScreenId);

  if (currentIndex <= 0) {
    return null;
  }

  return sequence[currentIndex - 1];
}

export function getProgressState(
  currentScreenId: OnboardingScreenId,
  draft: OnboardingDraft
): {
  currentStep: number;
  showProgress: boolean;
  totalSteps: number;
} {
  const progressSequence = getOnboardingSequence(draft.trackType).filter((screenId) => screenId !== 'splash');

  if (currentScreenId === 'splash') {
    return {
      currentStep: 0,
      showProgress: false,
      totalSteps: progressSequence.length,
    };
  }

  const currentIndex = progressSequence.indexOf(currentScreenId);

  return {
    currentStep: currentIndex + 1,
    showProgress: true,
    totalSteps: progressSequence.length,
  };
}

export function getOnboardingHref(screenId: OnboardingScreenId): `/onboarding/${OnboardingScreenId}` {
  return `/onboarding/${screenId}`;
}

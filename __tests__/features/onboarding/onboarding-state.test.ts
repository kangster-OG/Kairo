import AsyncStorage from '@react-native-async-storage/async-storage';

import { buildSummarySections } from '@/src/features/onboarding/helpers';
import { createEmptyOnboardingDraft, type OnboardingDraft } from '@/src/features/onboarding/schema';
import {
  getOnboardingCompletionStatus,
  getRequiredBranches,
} from '@/src/features/onboarding/selectors';
import { loadOnboardingDraft, saveOnboardingDraft } from '@/src/features/onboarding/storage';
import { createOnboardingStore } from '@/src/features/onboarding/store';

jest.mock('@react-native-async-storage/async-storage', () =>
  jest.requireActual('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

function createCompletedDraft(trackType: 'glp' | 'peptide' | 'both' | 'later'): OnboardingDraft {
  return {
    ...createEmptyOnboardingDraft(),
    accountMode: 'guest',
    healthConnectionPromptSeen: true,
    privacy: {
      discreetNotifications: true,
      hideSensitiveLabels: true,
      biometricLater: false,
      analyticsOptIn: false,
    },
    trackType,
    glp: {
      medication: 'Wegovy',
      frequency: 'weekly',
      injectionDay: 'Monday',
      dose: '0.25 mg',
      duration: 'Just starting',
      goal: 'Weight loss',
      challenge: 'Remembering doses',
    },
    peptide: {
      selections: ['BPC-157'],
      frequency: 'Daily',
      experience: 'New to peptides',
      usualTime: 'Morning',
      dose: '100 mcg',
      goal: 'Recovery',
    },
  };
}

describe('onboarding state', () => {
  beforeEach(async () => {
    await AsyncStorage.clear();
  });

  it('starts with the manifest-shaped default draft and incomplete completion status', () => {
    const store = createOnboardingStore();
    const state = store.getState();

    expect(state.draft).toEqual(createEmptyOnboardingDraft());
    expect(state.completionStatus.isComplete).toBe(false);
    expect(state.completionStatus.missingFields).toEqual(
      expect.arrayContaining(['accountMode', 'trackType', 'healthConnectionPromptSeen'])
    );
    expect(state.completedOutput).toBeNull();
  });

  it('switches branch requirements for glp, peptide, both, and later', () => {
    expect(getRequiredBranches('glp')).toEqual(['glp']);
    expect(getRequiredBranches('peptide')).toEqual(['peptide']);
    expect(getRequiredBranches('both')).toEqual(['glp', 'peptide']);
    expect(getRequiredBranches('later')).toEqual([]);
  });

  it('preserves separate GLP and peptide answers for the both path', () => {
    const completionStatus = getOnboardingCompletionStatus(createCompletedDraft('both'));

    expect(completionStatus.isComplete).toBe(true);
    expect(completionStatus.output?.glp.medication).toBe('Wegovy');
    expect(completionStatus.output?.glp.challenge).toBe('Remembering doses');
    expect(completionStatus.output?.peptide.selections).toEqual(['BPC-157']);
    expect(completionStatus.output?.peptide.goal).toBe('Recovery');
    expect(completionStatus.completedBranches).toEqual(['glp', 'peptide']);
  });

  it('hydrates from persisted storage and recomputes completion state', async () => {
    const persistedDraft = createCompletedDraft('later');
    await saveOnboardingDraft(persistedDraft);

    const store = createOnboardingStore();
    await store.getState().hydrate();

    expect(store.getState().hydrationStatus).toBe('ready');
    expect(store.getState().draft).toEqual(persistedDraft);
    expect(store.getState().completionStatus.isComplete).toBe(true);
    expect(store.getState().completedOutput?.trackType).toBe('later');
  });

  it('persists updates and only completes once required fields are satisfied', async () => {
    const store = createOnboardingStore();

    await expect(store.getState().complete()).resolves.toBeNull();
    expect(store.getState().lastError).toBe('Onboarding is incomplete.');

    await store.getState().updateDraft((draft) => ({
      ...draft,
      accountMode: 'guest',
      trackType: 'later',
      healthConnectionPromptSeen: true,
      privacy: {
        ...draft.privacy,
        discreetNotifications: true,
      },
    }));

    const persistedDraft = await loadOnboardingDraft();
    expect(persistedDraft.accountMode).toBe('guest');
    expect(persistedDraft.trackType).toBe('later');
    expect(persistedDraft.privacy.discreetNotifications).toBe(true);

    await expect(store.getState().complete()).resolves.toEqual(
      expect.objectContaining({
        accountMode: 'guest',
        trackType: 'later',
      })
    );
    expect(store.getState().completionStatus.isComplete).toBe(true);
  });

  it('formats reusable summary sections for completed onboarding data', () => {
    const sections = buildSummarySections(createCompletedDraft('both'));

    expect(sections.map((section) => section.id)).toEqual(['overview', 'privacy', 'glp', 'peptide']);
    expect(sections.find((section) => section.id === 'glp')?.items).toEqual(
      expect.arrayContaining([{ label: 'Medication', value: 'Wegovy' }])
    );
    expect(sections.find((section) => section.id === 'peptide')?.items).toEqual(
      expect.arrayContaining([{ label: 'Selection', value: 'BPC-157' }])
    );
  });
});

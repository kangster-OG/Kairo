import AsyncStorage from '@react-native-async-storage/async-storage';

import {
  createEmptyOnboardingDraft,
  type OnboardingDraft,
} from '@/src/features/onboarding/schema';
import {
  ONBOARDING_STORAGE_KEY,
  clearOnboardingDraft,
  loadOnboardingDraft,
  saveOnboardingDraft,
} from '@/src/features/onboarding/storage';

jest.mock('@react-native-async-storage/async-storage', () =>
  jest.requireActual('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

describe('onboarding storage', () => {
  beforeEach(async () => {
    await AsyncStorage.clear();
  });

  it('returns an empty draft when no saved state exists', async () => {
    await expect(loadOnboardingDraft()).resolves.toEqual(createEmptyOnboardingDraft());
  });

  it('persists and restores a valid onboarding draft', async () => {
    const nextDraft: OnboardingDraft = {
      ...createEmptyOnboardingDraft(),
      accountMode: 'guest',
      privacy: {
        discreetNotifications: true,
        hideSensitiveLabels: true,
        biometricLater: false,
        analyticsOptIn: false,
      },
    };

    await saveOnboardingDraft(nextDraft);

    await expect(loadOnboardingDraft()).resolves.toEqual(nextDraft);
  });

  it('falls back to defaults when persisted data is invalid', async () => {
    await AsyncStorage.setItem(
      ONBOARDING_STORAGE_KEY,
      JSON.stringify({ accountMode: 'invalid-value' })
    );

    await expect(loadOnboardingDraft()).resolves.toEqual(createEmptyOnboardingDraft());
  });

  it('clears the saved onboarding draft', async () => {
    await saveOnboardingDraft({
      ...createEmptyOnboardingDraft(),
      accountMode: 'create',
    });

    await clearOnboardingDraft();

    await expect(loadOnboardingDraft()).resolves.toEqual(createEmptyOnboardingDraft());
  });
});

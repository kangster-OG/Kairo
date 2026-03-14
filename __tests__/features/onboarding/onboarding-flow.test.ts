import { getOnboardingSequence, getProgressState } from '@/src/features/onboarding/flow';
import { createEmptyOnboardingDraft } from '@/src/features/onboarding/schema';

describe('onboarding flow', () => {
  it('includes only the GLP branch when track type is glp', () => {
    const draft = {
      ...createEmptyOnboardingDraft(),
      trackType: 'glp' as const,
    };

    expect(getOnboardingSequence(draft.trackType)).toEqual(
      expect.arrayContaining(['glpMedication', 'glpBiggestChallenge', 'connectApps', 'planReady'])
    );
    expect(getOnboardingSequence(draft.trackType)).not.toEqual(
      expect.arrayContaining(['peptideSelection'])
    );
  });

  it('concatenates GLP and peptide branches when track type is both', () => {
    const sequence = getOnboardingSequence('both');

    expect(sequence.indexOf('glpBiggestChallenge')).toBeLessThan(sequence.indexOf('peptideSelection'));
    expect(sequence.at(-1)).toBe('planReady');
  });

  it('keeps progress hidden on splash and visible after it', () => {
    const draft = createEmptyOnboardingDraft();

    expect(getProgressState('splash', draft)).toEqual(
      expect.objectContaining({
        currentStep: 0,
        showProgress: false,
      })
    );

    expect(getProgressState('intro', draft)).toEqual(
      expect.objectContaining({
        currentStep: 1,
        showProgress: true,
      })
    );
  });
});

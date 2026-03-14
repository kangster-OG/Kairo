import { calculateReconstitution } from '@/src/features/calculator/math';

describe('calculator service', () => {
  it('explains neutral reconstitution math', () => {
    const result = calculateReconstitution({
      diluentUnit: 'mL',
      diluentVolume: 2,
      drawUnit: 'mL',
      drawVolume: 0.25,
      label: 'Baseline',
      powderAmount: 2,
      powderUnit: 'mg',
    });

    expect(result.concentrationLabel).toContain('2 mg / 2 mL');
    expect(result.deliveredLabel).toContain('0.25 mL delivers about 0.25 mg');
    expect(result.explanation).toHaveLength(3);
  });
});

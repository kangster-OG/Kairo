import {
  reconstitutionCalculatorInputSchema,
  type ReconstitutionCalculatorInput,
} from '@/src/features/calculator/schema';

export type ReconstitutionResult = {
  concentrationLabel: string;
  deliveredAmount: number;
  deliveredLabel: string;
  explanation: string[];
};

export function calculateReconstitution(
  input: ReconstitutionCalculatorInput
): ReconstitutionResult {
  const parsed = reconstitutionCalculatorInputSchema.parse(input);
  const concentration = parsed.powderAmount / parsed.diluentVolume;
  const deliveredAmount = concentration * parsed.drawVolume;
  const concentrationLabel = `${formatNumber(parsed.powderAmount)} ${parsed.powderUnit} / ${formatNumber(
    parsed.diluentVolume
  )} ${parsed.diluentUnit} = ${formatNumber(concentration)} ${parsed.powderUnit} per ${parsed.diluentUnit}`;
  const deliveredLabel = `${formatNumber(parsed.drawVolume)} ${parsed.drawUnit} delivers about ${formatNumber(
    deliveredAmount
  )} ${parsed.powderUnit}`;

  return {
    concentrationLabel,
    deliveredAmount,
    deliveredLabel,
    explanation: [
      `1. Divide ${formatNumber(parsed.powderAmount)} ${parsed.powderUnit} by ${formatNumber(
        parsed.diluentVolume
      )} ${parsed.diluentUnit} to get concentration.`,
      `2. Multiply that concentration by ${formatNumber(parsed.drawVolume)} ${parsed.drawUnit}.`,
      'This is a neutral math helper only. Atlas does not recommend what to take.',
    ],
  };
}

function formatNumber(value: number) {
  return Math.abs(value - Math.round(value)) < 0.0001
    ? `${Math.round(value)}`
    : value.toFixed(2).replace(/\.?0+$/, '');
}

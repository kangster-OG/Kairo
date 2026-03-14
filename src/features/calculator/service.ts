import { getAtlasRepositories } from '@/src/lib/database';
import type { CalculatorProfile } from '@/src/lib/database/schemas';
import {
  reconstitutionCalculatorInputSchema,
  type ReconstitutionCalculatorInput,
} from '@/src/features/calculator/schema';

export async function listCalculatorProfiles(): Promise<CalculatorProfile[]> {
  const repositories = await getAtlasRepositories();
  return repositories.calculatorProfiles.listAll();
}

export async function saveCalculatorProfile(input: ReconstitutionCalculatorInput) {
  const parsed = reconstitutionCalculatorInputSchema.parse(input);
  const repositories = await getAtlasRepositories();

  return repositories.calculatorProfiles.create({
    diluentUnit: parsed.diluentUnit,
    diluentVolume: parsed.diluentVolume,
    drawUnit: parsed.drawUnit,
    drawVolume: parsed.drawVolume,
    label: parsed.label?.trim() || 'Saved calculator profile',
    powderAmount: parsed.powderAmount,
    powderUnit: parsed.powderUnit,
  });
}

export async function deleteCalculatorProfile(id: string) {
  const repositories = await getAtlasRepositories();
  return repositories.calculatorProfiles.delete(id);
}

export { calculateReconstitution, type ReconstitutionResult } from '@/src/features/calculator/math';

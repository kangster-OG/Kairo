import { readJsonItem, removeJsonItem, writeJsonItem } from '@/src/lib/storage/json-storage';
import {
  createEmptyOnboardingDraft,
  onboardingDraftSchema,
  type OnboardingDraft,
} from '@/src/features/onboarding/schema';

export const ONBOARDING_STORAGE_KEY = 'atlas:onboarding:draft:v1';

export async function loadOnboardingDraft(): Promise<OnboardingDraft> {
  const fallbackDraft = createEmptyOnboardingDraft();
  const parsedValue = await readJsonItem<unknown>(ONBOARDING_STORAGE_KEY, fallbackDraft);
  const validation = onboardingDraftSchema.safeParse(parsedValue);

  if (!validation.success) {
    return fallbackDraft;
  }

  return validation.data;
}

export async function saveOnboardingDraft(draft: OnboardingDraft): Promise<void> {
  const validation = onboardingDraftSchema.safeParse(draft);

  if (!validation.success) {
    throw new Error('Invalid onboarding draft.');
  }

  await writeJsonItem(ONBOARDING_STORAGE_KEY, validation.data);
}

export async function clearOnboardingDraft(): Promise<void> {
  await removeJsonItem(ONBOARDING_STORAGE_KEY);
}

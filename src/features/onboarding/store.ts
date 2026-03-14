import { create } from 'zustand';
import { createStore } from 'zustand/vanilla';

import {
  createEmptyOnboardingDraft,
  onboardingDraftSchema,
  type OnboardingDraft,
  type OnboardingOutput,
} from '@/src/features/onboarding/schema';
import {
  getOnboardingCompletionStatus,
  type OnboardingCompletionStatus,
} from '@/src/features/onboarding/selectors';
import {
  clearOnboardingDraft,
  loadOnboardingDraft,
  saveOnboardingDraft,
} from '@/src/features/onboarding/storage';

type HydrationStatus = 'idle' | 'loading' | 'ready';

type OnboardingStoreDependencies = {
  clearDraft: typeof clearOnboardingDraft;
  loadDraft: typeof loadOnboardingDraft;
  saveDraft: typeof saveOnboardingDraft;
};

export type OnboardingStore = {
  completedOutput: OnboardingOutput | null;
  completionStatus: OnboardingCompletionStatus;
  draft: OnboardingDraft;
  hydrationStatus: HydrationStatus;
  lastError: string | null;
  complete: () => Promise<OnboardingOutput | null>;
  hydrate: () => Promise<void>;
  reset: () => Promise<void>;
  updateDraft: (updater: (draft: OnboardingDraft) => OnboardingDraft) => Promise<void>;
};

const defaultDependencies: OnboardingStoreDependencies = {
  clearDraft: clearOnboardingDraft,
  loadDraft: loadOnboardingDraft,
  saveDraft: saveOnboardingDraft,
};

function getDerivedState(draft: OnboardingDraft) {
  const completionStatus = getOnboardingCompletionStatus(draft);

  return {
    completedOutput: completionStatus.output,
    completionStatus,
    draft,
  };
}

function createInitialState(): Pick<
  OnboardingStore,
  'completedOutput' | 'completionStatus' | 'draft' | 'hydrationStatus' | 'lastError'
> {
  const draft = createEmptyOnboardingDraft();

  return {
    ...getDerivedState(draft),
    hydrationStatus: 'idle',
    lastError: null,
  };
}

function createOnboardingStoreState(dependencies: OnboardingStoreDependencies) {
  return (set: (partial: Partial<OnboardingStore>) => void, get: () => OnboardingStore): OnboardingStore => ({
    ...createInitialState(),
    complete: async () => {
      const { draft } = get();
      const completionStatus = getOnboardingCompletionStatus(draft);

      if (!completionStatus.isComplete || !completionStatus.output) {
        set({
          completedOutput: null,
          completionStatus,
          lastError: 'Onboarding is incomplete.',
        });
        return null;
      }

      try {
        await dependencies.saveDraft(draft);
        set({
          completedOutput: completionStatus.output,
          completionStatus,
          lastError: null,
        });
        return completionStatus.output;
      } catch {
        set({ lastError: 'Unable to save onboarding progress.' });
        return null;
      }
    },
    hydrate: async () => {
      if (get().hydrationStatus === 'loading' || get().hydrationStatus === 'ready') {
        return;
      }

      set({ hydrationStatus: 'loading', lastError: null });

      try {
        const savedDraft = await dependencies.loadDraft();
        set({
          ...getDerivedState(savedDraft),
          hydrationStatus: 'ready',
          lastError: null,
        });
      } catch {
        const fallbackDraft = createEmptyOnboardingDraft();
        set({
          ...getDerivedState(fallbackDraft),
          hydrationStatus: 'ready',
          lastError: 'Unable to restore onboarding progress.',
        });
      }
    },
    reset: async () => {
      const emptyDraft = createEmptyOnboardingDraft();

      try {
        await dependencies.clearDraft();
        set({
          ...getDerivedState(emptyDraft),
          hydrationStatus: 'ready',
          lastError: null,
        });
      } catch {
        set({
          ...getDerivedState(emptyDraft),
          hydrationStatus: 'ready',
          lastError: 'Unable to clear onboarding progress.',
        });
      }
    },
    updateDraft: async (updater) => {
      const nextDraftResult = onboardingDraftSchema.safeParse(updater(get().draft));

      if (!nextDraftResult.success) {
        set({ lastError: 'Invalid onboarding update.' });
        return;
      }

      const nextDraft = nextDraftResult.data;
      set({
        ...getDerivedState(nextDraft),
        lastError: null,
      });

      try {
        await dependencies.saveDraft(nextDraft);
      } catch {
        set({ lastError: 'Unable to save onboarding progress.' });
      }
    },
  });
}

export function createOnboardingStore(dependencies: OnboardingStoreDependencies = defaultDependencies) {
  return createStore<OnboardingStore>(createOnboardingStoreState(dependencies));
}

export const onboardingStore = createOnboardingStore();

export const useOnboardingStore = create<OnboardingStore>((set, get) =>
  createOnboardingStoreState(defaultDependencies)(
    (partial) => {
      set(partial);
    },
    get
  )
);

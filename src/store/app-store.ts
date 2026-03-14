import { create } from 'zustand';

type AppStore = {
  hasCompletedOnboarding: boolean;
  isDiscreetModeEnabled: boolean;
  setHasCompletedOnboarding: (value: boolean) => void;
  setIsDiscreetModeEnabled: (value: boolean) => void;
};

export const useAppStore = create<AppStore>((set) => ({
  hasCompletedOnboarding: false,
  isDiscreetModeEnabled: false,
  setHasCompletedOnboarding: (value) => set({ hasCompletedOnboarding: value }),
  setIsDiscreetModeEnabled: (value) => set({ isDiscreetModeEnabled: value }),
}));

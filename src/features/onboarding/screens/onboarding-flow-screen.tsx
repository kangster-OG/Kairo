import { useEffect } from 'react';

import { router, type Href } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import {
  accountModeOptions,
  genderOptions,
  glpChallengeOptions,
  glpDoseOptions,
  glpFrequencyOptions,
  glpGoalOptions,
  glpMedicationOptions,
  peptideDoseOptions,
  peptideExperienceOptions,
  peptideFrequencyOptions,
  peptideGoalOptions,
  peptideSelectionOptions,
  peptideTimeOptions,
  privacyOptions,
  trackTypeOptions,
  weekdayOptions,
  durationOptions,
} from '@/src/features/onboarding/content';
import {
  getNextScreen,
  getPreviousScreen,
  getProgressState,
  type OnboardingScreenId,
} from '@/src/features/onboarding/flow';
import { convertHeight, convertWeight, formatHeight } from '@/src/features/onboarding/helpers';
import { ConnectAppsScreen, IntroScreen, PlanReadyScreen, SplashScreen } from '@/src/features/onboarding/screens/onboarding-showcase-screens';
import {
  DualMetricScreen,
  MultiToggleScreen,
  NumberQuestionScreen,
  SingleSelectScreen,
} from '@/src/features/onboarding/screens/onboarding-screen-parts';
import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { useAppStore } from '@/src/store/app-store';
import { atlasTheme } from '@/src/theme/tokens';

export function OnboardingFlowScreen({ screenId }: { screenId: OnboardingScreenId }) {
  const draft = useOnboardingStore((state) => state.draft);
  const hydrationStatus = useOnboardingStore((state) => state.hydrationStatus);
  const hydrate = useOnboardingStore((state) => state.hydrate);
  const updateDraft = useOnboardingStore((state) => state.updateDraft);
  const complete = useOnboardingStore((state) => state.complete);
  const setHasCompletedOnboarding = useAppStore((state) => state.setHasCompletedOnboarding);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  const progress = getProgressState(screenId, draft);
  const nextScreen = getNextScreen(screenId, draft);
  const previousScreen = getPreviousScreen(screenId, draft);

  const persistDraft = async (updater: (currentDraft: OnboardingDraft) => OnboardingDraft) => {
    await updateDraft(updater);
  };

  const goNext = () => {
    if (!nextScreen) {
      return;
    }

    router.replace(getOnboardingRoute(nextScreen));
  };

  const goBack = () => {
    if (!previousScreen) {
      return;
    }

    router.replace(getOnboardingRoute(previousScreen));
  };

  const finishOnboarding = async () => {
    const output = await complete();

    if (!output) {
      return;
    }

    setHasCompletedOnboarding(true);
    router.replace('/today');
  };

  if (hydrationStatus !== 'ready') {
    return (
      <AppScreen>
        <View style={styles.loadingShell}>
          <View style={styles.loadingOrb} />
          <AppText variant="display">Atlas</AppText>
          <AppText style={styles.loadingCopy} variant="caption">
            Restoring your local onboarding draft.
          </AppText>
        </View>
      </AppScreen>
    );
  }

  switch (screenId) {
    case 'splash':
      return (
        <SplashScreen
          onContinue={() => {
            router.replace(getOnboardingRoute('intro'));
          }}
        />
      );
    case 'intro':
      return (
        <IntroScreen
          currentStep={progress.currentStep}
          onBackPress={goBack}
          onContinue={goNext}
          totalSteps={progress.totalSteps}
        />
      );
    case 'accountMode':
      return (
        <SingleSelectScreen
          currentStep={progress.currentStep}
          description="Pick the path that matches your comfort level today. You can still change this later."
          onBackPress={goBack}
          onContinue={goNext}
          onSelect={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              accountMode: value as OnboardingDraft['accountMode'],
            }));
          }}
          options={accountModeOptions}
          selectedValue={draft.accountMode}
          title="How do you want to start?"
          totalSteps={progress.totalSteps}
        />
      );
    case 'privacyMode':
      return (
        <MultiToggleScreen
          currentStep={progress.currentStep}
          description="Set the privacy tone now before Atlas ever asks about health connections."
          onBackPress={goBack}
          onContinue={goNext}
          onToggle={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              privacy: {
                ...currentDraft.privacy,
                [value]: !currentDraft.privacy[value as keyof OnboardingDraft['privacy']],
              },
            }));
          }}
          options={privacyOptions}
          selectedValues={draft.privacy}
          title="Choose your privacy settings"
          totalSteps={progress.totalSteps}
        />
      );
    case 'trackType':
      return (
        <SingleSelectScreen
          currentStep={progress.currentStep}
          description="Atlas supports GLP tracking, peptide tracking, both, or a lighter explore-first path."
          onBackPress={goBack}
          onContinue={goNext}
          onSelect={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              trackType: value as OnboardingDraft['trackType'],
            }));
          }}
          options={trackTypeOptions}
          selectedValue={draft.trackType}
          title="What are you tracking?"
          totalSteps={progress.totalSteps}
        />
      );
    case 'gender':
      return (
        <SingleSelectScreen
          currentStep={progress.currentStep}
          description="Optional profile details help shape the experience, but none of them block setup."
          onBackPress={goBack}
          onContinue={goNext}
          onSelect={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              profile: {
                ...currentDraft.profile,
                gender: value === 'skip' ? null : value,
              },
            }));
          }}
          options={genderOptions}
          selectedValue={(draft.profile.gender ?? 'skip') as 'male' | 'female' | 'other' | 'skip'}
          title="Select your gender"
          totalSteps={progress.totalSteps}
        />
      );
    case 'age':
      return (
        <NumberQuestionScreen
          currentStep={progress.currentStep}
          description="Keep it optional. Atlas can still work well if you skip body metrics for now."
          helperText="Tap plus or minus to mimic a wheel-style picker."
          onBackPress={goBack}
          onChange={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              profile: { ...currentDraft.profile, age: value },
            }));
          }}
          onContinue={goNext}
          onSkip={() => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              profile: { ...currentDraft.profile, age: null },
            }));
            goNext();
          }}
          step={1}
          title="How old are you?"
          totalSteps={progress.totalSteps}
          unitLabel="years"
          value={draft.profile.age}
          valueRange={{ min: 18, max: 85 }}
        />
      );
    case 'goalWeight':
      return (
        <NumberQuestionScreen
          currentStep={progress.currentStep}
          description="This stays optional too. The goal is quick setup, not collecting everything up front."
          helperText={`Currently using ${(draft.profile.weightUnit ?? 'lb').toUpperCase()} for the mocked stepper.`}
          onBackPress={goBack}
          onChange={(value) => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              profile: {
                ...currentDraft.profile,
                goalWeight: value,
                weightUnit: currentDraft.profile.weightUnit ?? 'lb',
              },
            }));
          }}
          onContinue={goNext}
          onSkip={() => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              profile: { ...currentDraft.profile, goalWeight: null },
            }));
            goNext();
          }}
          step={1}
          title="What's your goal weight?"
          totalSteps={progress.totalSteps}
          unitLabel={draft.profile.weightUnit ?? 'lb'}
          value={draft.profile.goalWeight}
          valueRange={{ min: 90, max: 350 }}
        />
      );
    case 'heightWeight':
      return (
        <HeightWeightRouteScreen draft={draft} goBack={goBack} goNext={goNext} persistDraft={persistDraft} progress={progress} />
      );
    case 'connectApps':
      return (
        <ConnectAppsScreen
          currentStep={progress.currentStep}
          onBackPress={goBack}
          onConnect={() => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              healthConnectionPromptSeen: true,
            }));
          }}
          onSkip={() => {
            void persistDraft((currentDraft) => ({
              ...currentDraft,
              healthConnectionPromptSeen: true,
            }));
            goNext();
          }}
          totalSteps={progress.totalSteps}
        />
      );
    case 'planReady':
      return (
        <PlanReadyScreen
          currentStep={progress.currentStep}
          draft={draft}
          onBackPress={goBack}
          onFinish={() => void finishOnboarding()}
          totalSteps={progress.totalSteps}
        />
      );
    default:
      return (
        <BranchSelectRouteScreen
          draft={draft}
          goBack={goBack}
          goNext={goNext}
          persistDraft={persistDraft}
          progress={progress}
          screenId={screenId}
        />
      );
  }
}

function getOnboardingRoute(screenId: OnboardingScreenId): Href {
  return {
    pathname: '/onboarding',
    params: { step: screenId },
  } as Href;
}

function HeightWeightRouteScreen({
  draft,
  goBack,
  goNext,
  persistDraft,
  progress,
}: {
  draft: OnboardingDraft;
  goBack: () => void;
  goNext: () => void;
  persistDraft: (updater: (currentDraft: OnboardingDraft) => OnboardingDraft) => Promise<void>;
  progress: { currentStep: number; totalSteps: number };
}) {
  const heightUnit = draft.profile.heightUnit ?? 'cm';
  const weightUnit = draft.profile.weightUnit ?? 'lb';
  const heightValue = draft.profile.height ?? (heightUnit === 'cm' ? 170 : 67);
  const weightValue = draft.profile.weight ?? (weightUnit === 'kg' ? 77 : 170);

  return (
    <DualMetricScreen
      currentStep={progress.currentStep}
      description="Use the mocked steppers for a Figma-like feel. Both measurements remain optional."
      heightDisplay={formatHeight(heightValue, heightUnit)}
      heightUnit={heightUnit}
      onBackPress={goBack}
      onChangeHeightUnit={(nextUnit) => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            height: convertHeight(currentDraft.profile.height ?? 170, currentDraft.profile.heightUnit ?? 'cm', nextUnit),
            heightUnit: nextUnit,
          },
        }));
      }}
      onChangeWeightUnit={(nextUnit) => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            weight: convertWeight(currentDraft.profile.weight ?? 170, currentDraft.profile.weightUnit ?? 'lb', nextUnit),
            weightUnit: nextUnit,
          },
        }));
      }}
      onContinue={goNext}
      onDecreaseHeight={() => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            height: Math.max((currentDraft.profile.height ?? heightValue) - 1, heightUnit === 'cm' ? 140 : 55),
            heightUnit,
          },
        }));
      }}
      onDecreaseWeight={() => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            weight: Math.max((currentDraft.profile.weight ?? weightValue) - 1, weightUnit === 'kg' ? 40 : 88),
            weightUnit,
          },
        }));
      }}
      onIncreaseHeight={() => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            height: Math.min((currentDraft.profile.height ?? heightValue) + 1, heightUnit === 'cm' ? 220 : 84),
            heightUnit,
          },
        }));
      }}
      onIncreaseWeight={() => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            weight: Math.min((currentDraft.profile.weight ?? weightValue) + 1, weightUnit === 'kg' ? 180 : 400),
            weightUnit,
          },
        }));
      }}
      onSkip={() => {
        void persistDraft((currentDraft) => ({
          ...currentDraft,
          profile: {
            ...currentDraft.profile,
            height: null,
            heightUnit: null,
            weight: null,
            weightUnit: null,
          },
        }));
        goNext();
      }}
      title="What's your current height and weight?"
      totalSteps={progress.totalSteps}
      weightDisplay={`${weightValue} ${weightUnit}`}
      weightUnit={weightUnit}
    />
  );
}

function BranchSelectRouteScreen({
  draft,
  goBack,
  goNext,
  persistDraft,
  progress,
  screenId,
}: {
  draft: OnboardingDraft;
  goBack: () => void;
  goNext: () => void;
  persistDraft: (updater: (currentDraft: OnboardingDraft) => OnboardingDraft) => Promise<void>;
  progress: { currentStep: number; totalSteps: number };
  screenId: OnboardingScreenId;
}) {
  const config = getBranchScreenConfig(screenId);

  if (config.kind === 'single') {
    const selectedValue = config.getValue(draft);

    return (
      <SingleSelectScreen
        currentStep={progress.currentStep}
        description={config.description}
        onBackPress={goBack}
        onContinue={goNext}
        onSelect={(value) => {
          void persistDraft((currentDraft) => config.setValue(currentDraft, value));
        }}
        options={config.options}
        selectedValue={selectedValue}
        title={config.title}
        totalSteps={progress.totalSteps}
      />
    );
  }

  return (
    <MultiToggleScreen
      currentStep={progress.currentStep}
      description={config.description}
      onBackPress={goBack}
      onContinue={goNext}
      onToggle={(value) => {
        void persistDraft((currentDraft) => config.toggleValue(currentDraft, value));
      }}
      options={config.options}
      selectedValues={config.getSelectedValues(draft)}
      title={config.title}
      totalSteps={progress.totalSteps}
      useCheckboxStyle
    />
  );
}

function getBranchScreenConfig(screenId: OnboardingScreenId) {
  switch (screenId) {
    case 'glpMedication':
      return singleConfig('Which GLP are you taking?', 'A mocked medication choice keeps the UI real without adding any backend or dosing advice.', glpMedicationOptions, (draft) => draft.glp.medication, (draft, value) => ({ ...draft, glp: { ...draft.glp, medication: value } }));
    case 'glpFrequency':
      return singleConfig('How often do you take it?', 'This just shapes the routine UI for now. Protocol logic stays out of this slice.', glpFrequencyOptions, (draft) => draft.glp.frequency, (draft, value) => ({ ...draft, glp: { ...draft.glp, frequency: value } }));
    case 'glpInjectionDay':
      return singleConfig('What day do you inject?', 'Choose the day you want Atlas to anchor around for reminders and routine history later.', weekdayOptions, (draft) => draft.glp.injectionDay, (draft, value) => ({ ...draft, glp: { ...draft.glp, injectionDay: value } }));
    case 'glpCurrentDose':
      return singleConfig('What is your current dose?', 'Dose is stored as mocked UI state only. Atlas does not provide dosing advice.', glpDoseOptions, (draft) => draft.glp.dose, (draft, value) => ({ ...draft, glp: { ...draft.glp, dose: value } }));
    case 'glpDuration':
      return singleConfig('How long have you been on it?', 'This helps tailor the tone of the future Today surface without making treatment claims.', durationOptions, (draft) => draft.glp.duration, (draft, value) => ({ ...draft, glp: { ...draft.glp, duration: value } }));
    case 'glpMainGoal':
      return singleConfig('What is your main goal?', 'Goals shape copy and prioritization later, but they do not trigger recommendations.', glpGoalOptions, (draft) => draft.glp.goal, (draft, value) => ({ ...draft, glp: { ...draft.glp, goal: value } }));
    case 'glpBiggestChallenge':
      return singleConfig('Biggest challenge right now?', 'Atlas can surface the right reminders and context without acting like a medical coach.', glpChallengeOptions, (draft) => draft.glp.challenge, (draft, value) => ({ ...draft, glp: { ...draft.glp, challenge: value } }));
    case 'peptideFrequency':
      return singleConfig('How often do you take it?', 'Atlas uses cadence to shape the experience, not to infer treatment guidance.', peptideFrequencyOptions, (draft) => draft.peptide.frequency, (draft, value) => ({ ...draft, peptide: { ...draft.peptide, frequency: value } }));
    case 'peptideExperience':
      return singleConfig('How experienced are you?', 'Experience level helps control future tone and defaults without changing any underlying logic yet.', peptideExperienceOptions, (draft) => draft.peptide.experience, (draft, value) => ({ ...draft, peptide: { ...draft.peptide, experience: value } }));
    case 'peptideUsualTime':
      return singleConfig('What time do you usually inject?', 'Pick the time window that best matches your typical routine.', peptideTimeOptions, (draft) => draft.peptide.usualTime, (draft, value) => ({ ...draft, peptide: { ...draft.peptide, usualTime: value } }));
    case 'peptideCurrentDose':
      return singleConfig('What is your current dose?', 'Dose is captured as local UI state only and is not used for medical guidance.', peptideDoseOptions, (draft) => draft.peptide.dose, (draft, value) => ({ ...draft, peptide: { ...draft.peptide, dose: value } }));
    case 'peptideMainGoal':
      return singleConfig('What is your main goal?', 'Atlas will use this later for prioritization and tone, not for medical recommendations.', peptideGoalOptions, (draft) => draft.peptide.goal, (draft, value) => ({ ...draft, peptide: { ...draft.peptide, goal: value } }));
    default:
      return {
        kind: 'multi' as const,
        title: 'Which peptide(s) are you taking?',
        description: 'Choose one peptide or a small stack. This remains mock state only for this UI slice.',
        options: peptideSelectionOptions,
        getSelectedValues: (draft: OnboardingDraft) =>
          Object.fromEntries(
            peptideSelectionOptions.map((option) => [option.value, draft.peptide.selections.includes(option.value)])
          ) as Record<string, boolean>,
        toggleValue: (draft: OnboardingDraft, value: string) => {
          const alreadySelected = draft.peptide.selections.includes(value);
          return {
            ...draft,
            peptide: {
              ...draft.peptide,
              selections: alreadySelected
                ? draft.peptide.selections.filter((item) => item !== value)
                : [...draft.peptide.selections, value],
            },
          };
        },
      };
  }
}

function singleConfig(
  title: string,
  description: string,
  options: { description?: string; label: string; value: string }[],
  getValue: (draft: OnboardingDraft) => string | null,
  setValue: (draft: OnboardingDraft, value: string) => OnboardingDraft
) {
  return {
    kind: 'single' as const,
    title,
    description,
    options,
    getValue,
    setValue,
  };
}

const styles = StyleSheet.create({
  loadingShell: {
    alignItems: 'center',
    flex: 1,
    gap: atlasTheme.spacing.md,
    justifyContent: 'center',
  },
  loadingOrb: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: 999,
    height: 112,
    width: 112,
  },
  loadingCopy: {
    textAlign: 'center',
  },
});

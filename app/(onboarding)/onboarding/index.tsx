import { useLocalSearchParams } from 'expo-router';

import { isOnboardingScreenId } from '@/src/features/onboarding/flow';
import { OnboardingFlowScreen } from '@/src/features/onboarding/screens/onboarding-flow-screen';

export default function OnboardingIndexRoute() {
  const { step } = useLocalSearchParams<{ step?: string }>();
  const screenId = step && isOnboardingScreenId(step) ? step : 'splash';

  return <OnboardingFlowScreen screenId={screenId} />;
}

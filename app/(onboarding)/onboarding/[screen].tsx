import { Redirect, useLocalSearchParams } from 'expo-router';

import { isOnboardingScreenId } from '@/src/features/onboarding/flow';

export default function OnboardingScreenRoute() {
  const { screen } = useLocalSearchParams<{ screen?: string }>();
  const screenId = screen && isOnboardingScreenId(screen) ? screen : 'splash';

  return <Redirect href={{ pathname: '/onboarding', params: { step: screenId } }} />;
}

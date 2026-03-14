import { useEffect } from 'react';

import { Redirect } from 'expo-router';
import { View } from 'react-native';

import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { useOnboardingStore } from '@/src/features/onboarding/store';

export default function IndexRoute() {
  const hydrate = useOnboardingStore((state) => state.hydrate);
  const hydrationStatus = useOnboardingStore((state) => state.hydrationStatus);
  const completionStatus = useOnboardingStore((state) => state.completionStatus);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  if (hydrationStatus !== 'ready') {
    return (
      <AppScreen>
        <View style={{ alignItems: 'center', flex: 1, justifyContent: 'center' }}>
          <AppText variant="display">Atlas</AppText>
          <AppText variant="caption">Preparing your private workspace.</AppText>
        </View>
      </AppScreen>
    );
  }

  if (completionStatus.isComplete) {
    return <Redirect href="/today" />;
  }

  return <Redirect href="/onboarding" />;
}

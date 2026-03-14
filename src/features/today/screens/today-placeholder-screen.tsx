import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { atlasTheme } from '@/src/theme/tokens';

export function TodayPlaceholderScreen() {
  const accountMode = useOnboardingStore((state) => state.draft.accountMode);

  return (
    <AppScreen>
      <View style={styles.container}>
        <View style={styles.copy}>
          <AppText variant="title">Today placeholder</AppText>
          <AppText variant="caption">
            This route exists so the onboarding slice has a concrete destination without pulling in
            protocol scheduling, calculators, or reminders yet.
          </AppText>
        </View>

        <AppCard>
          <View style={styles.cardCopy}>
            <AppText style={styles.cardTitle} variant="heading">
              Foundation status
            </AppText>
            <AppText variant="caption">Current mode: {accountMode ?? 'unselected'}</AppText>
            <AppText variant="caption">
              Next slices can layer real Today data on top of this shell without changing route
              structure.
            </AppText>
          </View>
        </AppCard>

        <AppButton
          label="Back to onboarding"
          onPress={() => {
            router.replace('/');
          }}
          variant="secondary"
        />
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    gap: atlasTheme.spacing.lg,
    justifyContent: 'space-between',
  },
  copy: {
    gap: atlasTheme.spacing.sm,
    marginTop: atlasTheme.spacing.md,
  },
  cardCopy: {
    gap: atlasTheme.spacing.sm,
  },
  cardTitle: {
    fontSize: 20,
  },
});

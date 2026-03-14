import { StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type ProgressHeaderProps = {
  currentStep: number;
  totalSteps: number;
};

export function ProgressHeader({ currentStep, totalSteps }: ProgressHeaderProps) {
  const progressWidth = `${Math.max(currentStep / totalSteps, 0.08) * 100}%` as `${number}%`;

  return (
    <View style={styles.container}>
      <View style={styles.track}>
        <View style={[styles.fill, { width: progressWidth }]} />
      </View>
      <AppText style={styles.label} variant="caption">
        Step {currentStep} of {totalSteps}
      </AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.xs,
  },
  track: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.pill,
    height: 6,
    overflow: 'hidden',
  },
  fill: {
    backgroundColor: atlasTheme.colors.primary,
    borderRadius: atlasTheme.radii.pill,
    height: '100%',
  },
  label: {
    textAlign: 'right',
  },
});

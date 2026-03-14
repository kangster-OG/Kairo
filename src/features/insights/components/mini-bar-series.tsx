import { StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import type { InsightBarPoint } from '@/src/features/insights/service';
import { atlasTheme } from '@/src/theme/tokens';

type MiniBarSeriesProps = {
  points: InsightBarPoint[];
};

export function MiniBarSeries({ points }: MiniBarSeriesProps) {
  const maxValue = Math.max(...points.map((point) => point.value), 1);

  return (
    <View style={styles.container}>
      {points.map((point) => (
        <View key={`${point.label}:${point.value}`} style={styles.point}>
          <View style={styles.barTrack}>
            <View
              style={[
                styles.barFill,
                {
                  width: `${Math.max((point.value / maxValue) * 100, 10)}%`,
                },
              ]}
            />
          </View>
          <View style={styles.copy}>
            <AppText>{point.value}</AppText>
            <AppText variant="caption">{point.label}</AppText>
          </View>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.sm,
  },
  point: {
    gap: atlasTheme.spacing.xs,
  },
  barTrack: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.button,
    height: 10,
    overflow: 'hidden',
  },
  barFill: {
    backgroundColor: atlasTheme.colors.primary,
    borderRadius: atlasTheme.radii.button,
    height: '100%',
  },
  copy: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
});

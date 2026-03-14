import { Pressable, StyleSheet, View } from 'react-native';

import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type WheelPickerFieldProps = {
  decrementDisabled?: boolean;
  helperText?: string;
  label: string;
  onDecrease?: () => void;
  onIncrease?: () => void;
  tone?: 'default' | 'muted';
  valueLabel: string;
};

export function WheelPickerField({
  decrementDisabled = false,
  helperText,
  label,
  onDecrease,
  onIncrease,
  tone = 'default',
  valueLabel,
}: WheelPickerFieldProps) {
  return (
    <AppCard style={tone === 'muted' ? styles.mutedCard : null}>
      <View style={styles.container}>
        <AppText style={styles.label}>{label}</AppText>
        <View style={styles.controlsRow}>
          <Pressable
            disabled={!onDecrease || decrementDisabled}
            onPress={onDecrease}
            style={({ pressed }) => [styles.controlButton, pressed ? styles.controlPressed : null]}>
            <AppText style={styles.controlLabel}>-</AppText>
          </Pressable>
          <AppText style={styles.value} variant="heading">
            {valueLabel}
          </AppText>
          <Pressable
            disabled={!onIncrease}
            onPress={onIncrease}
            style={({ pressed }) => [styles.controlButton, pressed ? styles.controlPressed : null]}>
            <AppText style={styles.controlLabel}>+</AppText>
          </Pressable>
        </View>
        {helperText ? <AppText variant="caption">{helperText}</AppText> : null}
      </View>
    </AppCard>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 8,
  },
  mutedCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  label: {
    fontWeight: '600',
  },
  controlsRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  controlButton: {
    alignItems: 'center',
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: atlasTheme.radii.pill,
    height: 40,
    justifyContent: 'center',
    width: 40,
  },
  controlPressed: {
    opacity: 0.72,
  },
  controlLabel: {
    color: atlasTheme.colors.primary,
    fontSize: 24,
    lineHeight: 24,
  },
  value: {
    fontSize: 28,
  },
});

import { Pressable, StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type AnswerOptionButtonProps = {
  description?: string;
  isSelected: boolean;
  label: string;
  onPress: () => void;
};

export function AnswerOptionButton({
  description,
  isSelected,
  label,
  onPress,
}: AnswerOptionButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        isSelected ? styles.buttonSelected : null,
        pressed ? styles.buttonPressed : null,
      ]}>
      <View style={[styles.indicator, isSelected ? styles.indicatorSelected : null]} />
      <View style={styles.copy}>
        <AppText style={styles.label}>{label}</AppText>
        {description ? (
          <AppText style={styles.description} variant="caption">
            {description}
          </AppText>
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    alignItems: 'flex-start',
    backgroundColor: atlasTheme.colors.surface,
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.pill,
    borderWidth: 1,
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
    minHeight: 68,
    paddingHorizontal: atlasTheme.spacing.md,
    paddingVertical: atlasTheme.spacing.md,
  },
  buttonSelected: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderColor: atlasTheme.colors.primary,
  },
  buttonPressed: {
    opacity: 0.78,
  },
  indicator: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderColor: atlasTheme.colors.border,
    borderRadius: 10,
    borderWidth: 1,
    height: 20,
    width: 20,
  },
  indicatorSelected: {
    backgroundColor: atlasTheme.colors.primary,
    borderColor: atlasTheme.colors.primary,
  },
  copy: {
    flex: 1,
    gap: 2,
  },
  label: {
    fontWeight: '600',
  },
  description: {
    lineHeight: 18,
  },
});

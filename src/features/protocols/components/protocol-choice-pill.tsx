import { Pressable, StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type ProtocolChoicePillProps = {
  accessibilityHint?: string;
  description?: string;
  isSelected: boolean;
  label: string;
  onPress: () => void;
};

export function ProtocolChoicePill({
  accessibilityHint,
  description,
  isSelected,
  label,
  onPress,
}: ProtocolChoicePillProps) {
  return (
    <Pressable
      accessibilityHint={accessibilityHint ?? description}
      accessibilityLabel={label}
      accessibilityRole="button"
      accessibilityState={{ selected: isSelected }}
      hitSlop={6}
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        isSelected ? styles.pillSelected : null,
        pressed ? styles.pillPressed : null,
      ]}>
      <View style={styles.copy}>
        <AppText style={isSelected ? styles.labelSelected : styles.label} variant="body">
          {label}
        </AppText>
        {description ? (
          <AppText style={isSelected ? styles.descriptionSelected : undefined} variant="caption">
            {description}
          </AppText>
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pill: {
    backgroundColor: atlasTheme.colors.surface,
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.button,
    borderWidth: 1,
    minHeight: atlasTheme.ctaHeight,
    paddingHorizontal: atlasTheme.spacing.md,
    paddingVertical: atlasTheme.spacing.md,
  },
  pillSelected: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderColor: atlasTheme.colors.primary,
  },
  pillPressed: {
    opacity: 0.84,
  },
  copy: {
    gap: 4,
  },
  label: {
    fontWeight: '600',
  },
  labelSelected: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
  },
  descriptionSelected: {
    color: atlasTheme.colors.primary,
  },
});

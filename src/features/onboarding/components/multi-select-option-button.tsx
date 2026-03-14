import { Pressable, StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type MultiSelectOptionButtonProps = {
  isSelected: boolean;
  label: string;
  onPress: () => void;
};

export function MultiSelectOptionButton({
  isSelected,
  label,
  onPress,
}: MultiSelectOptionButtonProps) {
  return (
    <Pressable
      accessibilityRole="checkbox"
      accessibilityState={{ checked: isSelected }}
      onPress={onPress}
      style={[styles.button, isSelected ? styles.selected : null]}>
      <View style={[styles.checkmark, isSelected ? styles.checkmarkSelected : null]} />
      <AppText>{label}</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    alignItems: 'center',
    backgroundColor: atlasTheme.colors.surface,
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.pill,
    borderWidth: 1,
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
    minHeight: 60,
    paddingHorizontal: atlasTheme.spacing.md,
    paddingVertical: atlasTheme.spacing.md,
  },
  selected: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderColor: atlasTheme.colors.primary,
  },
  checkmark: {
    borderColor: atlasTheme.colors.border,
    borderRadius: 4,
    borderWidth: 1,
    height: 18,
    width: 18,
  },
  checkmarkSelected: {
    backgroundColor: atlasTheme.colors.primary,
    borderColor: atlasTheme.colors.primary,
  },
});

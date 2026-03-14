import { Pressable, StyleSheet } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type HeaderBackButtonProps = {
  disabled?: boolean;
  onPress?: () => void;
};

export function HeaderBackButton({ disabled = false, onPress }: HeaderBackButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled || !onPress}
      onPress={onPress}
      style={({ pressed }) => [styles.button, pressed ? styles.pressed : null]}>
      <AppText style={styles.label}>Back</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    alignSelf: 'flex-start',
    paddingVertical: atlasTheme.spacing.xs,
  },
  pressed: {
    opacity: 0.65,
  },
  label: {
    color: atlasTheme.colors.textSecondary,
    fontWeight: '600',
  },
});

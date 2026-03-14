import { Pressable, StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type AppButtonVariant = 'primary' | 'secondary' | 'ghost';

type AppButtonProps = {
  accessibilityHint?: string;
  accessibilityLabel?: string;
  label: string;
  disabled?: boolean;
  onPress: () => void;
  variant?: AppButtonVariant;
};

export function AppButton({
  accessibilityHint,
  accessibilityLabel,
  label,
  disabled = false,
  onPress,
  variant = 'primary',
}: AppButtonProps) {
  const variantStyles = {
    primary: styles.primary,
    secondary: styles.secondary,
    ghost: styles.ghost,
  };
  const pressedStyles = {
    primary: styles.primaryPressed,
    secondary: styles.secondaryPressed,
    ghost: styles.ghostPressed,
  };

  return (
    <Pressable
      accessibilityHint={accessibilityHint}
      accessibilityLabel={accessibilityLabel ?? label}
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      hitSlop={6}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        variantStyles[variant],
        pressed && !disabled ? pressedStyles[variant] : null,
        disabled ? styles.disabled : null,
      ]}>
      <View>
        <AppText
          style={[
            styles.label,
            variant === 'secondary' ? styles.secondaryLabel : null,
            variant === 'ghost' ? styles.ghostLabel : null,
          ]}>
          {label}
        </AppText>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    alignItems: 'center',
    borderRadius: atlasTheme.radii.button,
    height: atlasTheme.ctaHeight,
    justifyContent: 'center',
  },
  primary: {
    backgroundColor: atlasTheme.colors.primary,
  },
  primaryPressed: {
    backgroundColor: atlasTheme.colors.primaryPressed,
  },
  secondary: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  secondaryPressed: {
    opacity: 0.82,
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  ghostPressed: {
    opacity: 0.72,
  },
  disabled: {
    opacity: 0.45,
  },
  label: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  secondaryLabel: {
    color: atlasTheme.colors.primary,
  },
  ghostLabel: {
    color: atlasTheme.colors.textPrimary,
  },
});

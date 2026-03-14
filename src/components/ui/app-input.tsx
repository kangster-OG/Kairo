import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type AppInputProps = TextInputProps & {
  description?: string;
  error?: string | null;
  label: string;
};

export function AppInput({ description, error, label, style, ...props }: AppInputProps) {
  return (
    <View style={styles.container}>
      <View style={styles.copy}>
        <AppText style={styles.label} variant="caption">
          {label}
        </AppText>
        {description ? <AppText variant="caption">{description}</AppText> : null}
      </View>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={atlasTheme.colors.textSecondary}
        style={[styles.input, error ? styles.inputError : null, style]}
        {...props}
      />
      {error ? (
        <AppText style={styles.errorText} variant="caption">
          {error}
        </AppText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.xs,
  },
  copy: {
    gap: 4,
  },
  label: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  input: {
    backgroundColor: atlasTheme.colors.surface,
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.button,
    borderWidth: 1,
    color: atlasTheme.colors.textPrimary,
    fontFamily: atlasTheme.typography.bodyFamily,
    fontSize: atlasTheme.typography.bodySize,
    minHeight: atlasTheme.ctaHeight,
    paddingHorizontal: atlasTheme.spacing.md,
    paddingVertical: 14,
  },
  inputError: {
    borderColor: '#E25B5B',
  },
  errorText: {
    color: '#B53F3F',
  },
});

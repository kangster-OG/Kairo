import type { PropsWithChildren } from 'react';

import { StyleSheet, Text, type StyleProp, type TextStyle } from 'react-native';

import { atlasTheme } from '@/src/theme/tokens';

type AppTextVariant = 'display' | 'title' | 'heading' | 'body' | 'caption';

type AppTextProps = PropsWithChildren<{
  style?: StyleProp<TextStyle>;
  variant?: AppTextVariant;
}>;

export function AppText({ children, style, variant = 'body' }: AppTextProps) {
  return <Text style={[styles.base, styles[variant], style]}>{children}</Text>;
}

const styles = StyleSheet.create({
  base: {
    color: atlasTheme.colors.textPrimary,
    fontFamily: atlasTheme.typography.bodyFamily,
  },
  display: {
    fontFamily: atlasTheme.typography.displayFamily,
    fontSize: atlasTheme.typography.displaySize,
    fontWeight: '700',
    letterSpacing: -1.4,
    lineHeight: 48,
  },
  title: {
    fontFamily: atlasTheme.typography.displayFamily,
    fontSize: atlasTheme.typography.titleSize,
    fontWeight: '700',
    letterSpacing: -0.8,
    lineHeight: 38,
  },
  heading: {
    fontFamily: atlasTheme.typography.displayFamily,
    fontSize: atlasTheme.typography.headingSize,
    fontWeight: '700',
    letterSpacing: -0.5,
    lineHeight: 30,
  },
  body: {
    fontSize: atlasTheme.typography.bodySize,
    lineHeight: 24,
  },
  caption: {
    color: atlasTheme.colors.textSecondary,
    fontSize: atlasTheme.typography.captionSize,
    letterSpacing: 0.15,
    lineHeight: 20,
  },
});

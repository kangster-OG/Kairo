import type { PropsWithChildren } from 'react';

import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { atlasTheme } from '@/src/theme/tokens';

type AppCardProps = PropsWithChildren<{
  style?: StyleProp<ViewStyle>;
}>;

export function AppCard({ children, style }: AppCardProps) {
  return <View style={[styles.card, style]}>{children}</View>;
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: atlasTheme.colors.surface,
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.card,
    borderWidth: 1,
    shadowColor: '#BFD1F3',
    shadowOffset: {
      width: 0,
      height: 14,
    },
    shadowOpacity: 0.16,
    shadowRadius: 24,
    padding: atlasTheme.spacing.lg,
    elevation: 3,
  },
});

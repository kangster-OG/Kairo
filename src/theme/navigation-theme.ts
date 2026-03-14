import { DefaultTheme, type Theme } from '@react-navigation/native';

import { atlasTheme } from '@/src/theme/tokens';

export const atlasNavigationTheme: Theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: atlasTheme.colors.background,
    card: atlasTheme.colors.surface,
    border: atlasTheme.colors.border,
    primary: atlasTheme.colors.primary,
    text: atlasTheme.colors.textPrimary,
    notification: atlasTheme.colors.primary,
  },
};

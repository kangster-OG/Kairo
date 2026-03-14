import { Platform } from 'react-native';

export const atlasTheme = {
  colors: {
    background: '#FFFFFF',
    surface: '#FFFFFF',
    surfaceMuted: '#F5F8FF',
    surfaceGlow: '#EAF2FF',
    primary: '#4E86F7',
    primaryPressed: '#3F76E8',
    border: '#E6ECF5',
    textPrimary: '#111827',
    textSecondary: '#6B7280',
    success: '#1F9D61',
  },
  radii: {
    button: 14,
    card: 22,
    pill: 999,
  },
  spacing: {
    xs: 8,
    sm: 12,
    md: 16,
    lg: 24,
    xl: 32,
  },
  typography: {
    displaySize: 44,
    titleSize: 32,
    headingSize: 24,
    bodySize: 16,
    captionSize: 14,
    displayFamily: Platform.select({
      ios: 'Avenir Next',
      android: 'sans-serif-medium',
      default: 'system-ui',
    }),
    bodyFamily: Platform.select({
      ios: 'System',
      android: 'sans-serif',
      default: 'system-ui',
    }),
  },
  screenPadding: 24,
  ctaHeight: 50,
} as const;

export type AtlasTheme = typeof atlasTheme;

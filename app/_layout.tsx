import { ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import 'react-native-reanimated';

import { AppErrorBoundary } from '@/src/components/app-error-boundary';
import { AppProviders } from '@/src/providers/app-providers';
import { atlasNavigationTheme } from '@/src/theme/navigation-theme';

export default function RootLayout() {
  return (
    <AppErrorBoundary>
      <AppProviders>
        <ThemeProvider value={atlasNavigationTheme}>
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="(onboarding)" />
            <Stack.Screen name="(app)" />
          </Stack>
        </ThemeProvider>
      </AppProviders>
    </AppErrorBoundary>
  );
}

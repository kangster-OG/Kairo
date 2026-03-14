import type { PropsWithChildren } from 'react';

import { ScrollView, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { atlasTheme } from '@/src/theme/tokens';

type AppScreenProps = PropsWithChildren<{
  scroll?: boolean;
  style?: StyleProp<ViewStyle>;
}>;

export function AppScreen({ children, scroll = false, style }: AppScreenProps) {
  if (scroll) {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.safeArea}>
        <ScrollView
          contentContainerStyle={[styles.scrollContent, style]}
          keyboardShouldPersistTaps="handled">
          {children}
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView edges={['top', 'bottom']} style={styles.safeArea}>
      <View style={[styles.content, style]}>{children}</View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: atlasTheme.colors.background,
    flex: 1,
  },
  content: {
    flex: 1,
    paddingHorizontal: atlasTheme.screenPadding,
    paddingVertical: atlasTheme.spacing.lg,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: atlasTheme.screenPadding,
    paddingVertical: atlasTheme.spacing.lg,
  },
});

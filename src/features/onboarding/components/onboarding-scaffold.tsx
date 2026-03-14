import type { PropsWithChildren, ReactNode } from 'react';

import { StyleSheet, View } from 'react-native';

import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { HeaderBackButton } from '@/src/features/onboarding/components/header-back-button';
import { ProgressHeader } from '@/src/features/onboarding/components/progress-header';
import { atlasTheme } from '@/src/theme/tokens';

type OnboardingScaffoldProps = PropsWithChildren<{
  currentStep: number;
  description?: string;
  footer?: ReactNode;
  onBackPress?: () => void;
  scroll?: boolean;
  showProgress?: boolean;
  title: string;
  totalSteps: number;
}>;

export function OnboardingScaffold({
  children,
  currentStep,
  description,
  footer,
  onBackPress,
  scroll = false,
  showProgress = true,
  title,
  totalSteps,
}: OnboardingScaffoldProps) {
  return (
    <AppScreen scroll={scroll} style={styles.screen}>
      <View pointerEvents="none" style={styles.backgroundTopOrb} />
      <View pointerEvents="none" style={styles.backgroundBottomOrb} />
      <View style={styles.header}>
        {showProgress ? <ProgressHeader currentStep={currentStep} totalSteps={totalSteps} /> : null}
        {onBackPress ? <HeaderBackButton onPress={onBackPress} /> : null}
        <View style={styles.copy}>
          <AppText variant="title">{title}</AppText>
          {description ? <AppText variant="caption">{description}</AppText> : null}
        </View>
      </View>

      <View style={styles.content}>{children}</View>

      {footer ? <View style={styles.footer}>{footer}</View> : null}
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: atlasTheme.spacing.lg,
  },
  backgroundTopOrb: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: 999,
    height: 180,
    opacity: 0.7,
    position: 'absolute',
    right: -72,
    top: -28,
    width: 180,
  },
  backgroundBottomOrb: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: 999,
    bottom: 112,
    height: 150,
    left: -72,
    opacity: 0.65,
    position: 'absolute',
    width: 150,
  },
  header: {
    gap: atlasTheme.spacing.md,
    zIndex: 1,
  },
  copy: {
    gap: atlasTheme.spacing.sm,
  },
  content: {
    flex: 1,
    gap: atlasTheme.spacing.md,
    zIndex: 1,
  },
  footer: {
    marginTop: 'auto',
    paddingBottom: atlasTheme.spacing.sm,
    zIndex: 1,
  },
});

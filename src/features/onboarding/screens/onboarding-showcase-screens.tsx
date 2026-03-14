import { StyleSheet, View } from 'react-native';

import { router } from 'expo-router';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { BottomCTA } from '@/src/features/onboarding/components/bottom-cta';
import { OnboardingScaffold } from '@/src/features/onboarding/components/onboarding-scaffold';
import { PermissionCard } from '@/src/features/onboarding/components/permission-card';
import { SummaryCard } from '@/src/features/onboarding/components/summary-card';
import {
  buildGlpSummary,
  buildPeptideSummary,
  buildPrivacySummary,
  buildSummaryItems,
} from '@/src/features/onboarding/helpers';
import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import { atlasTheme } from '@/src/theme/tokens';

export function SplashScreen({ onContinue }: { onContinue: () => void }) {
  return (
    <AppScreen style={styles.splashScreen}>
      <View pointerEvents="none" style={styles.splashTopGlow} />
      <View pointerEvents="none" style={styles.splashBottomGlow} />
      <View style={styles.splashContent}>
        <View style={styles.brandBadge}>
          <AppText style={styles.brandBadgeText} variant="caption">
            Privacy-first protocol tracker
          </AppText>
        </View>

        <View style={styles.brandBlock}>
          <AppText style={styles.splashWordmark} variant="display">
            Atlas
          </AppText>
          <AppText style={styles.splashSubtitle} variant="body">
            Logging, reminders, inventory, and wellness context for injectables without forcing a
            cloud account on day one.
          </AppText>
        </View>

        <AppCard style={styles.heroCard}>
          <View style={styles.heroCardContent}>
            <View style={styles.heroTokenRow}>
              <View style={styles.heroToken} />
              <View style={styles.heroTokenWide} />
            </View>
            <AppText style={styles.heroCardTitle} variant="heading">
              Quiet setup. Clear routine.
            </AppText>
            <AppText variant="caption">
              Atlas starts with a guided setup, then fades into the background once your routine is
              in place.
            </AppText>
          </View>
        </AppCard>
      </View>

      <View style={styles.splashFooter}>
        <AppButton label="Continue" onPress={onContinue} />
      </View>
    </AppScreen>
  );
}

export function IntroScreen({
  currentStep,
  onBackPress,
  onContinue,
  totalSteps,
}: {
  currentStep: number;
  onBackPress?: () => void;
  onContinue: () => void;
  totalSteps: number;
}) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description="Atlas keeps the first-run flow calm, guided, and discreet from the start."
      footer={
        <View style={styles.footerStack}>
          <BottomCTA label="Get started" onPress={onContinue} />
          <AppButton
            label="I already have an account"
            onPress={() => {
              router.push('/auth');
            }}
            variant="ghost"
          />
        </View>
      }
      onBackPress={onBackPress}
      title="All your tracking in one place"
      totalSteps={totalSteps}>
      <View style={styles.introFeatureStack}>
        {[
          {
            eyebrow: 'Protocol logging',
            copy: 'Capture cadence, inventory, and routine context without jumping into dosing advice.',
          },
          {
            eyebrow: 'Privacy controls first',
            copy: 'Discreet labels and notification preferences appear before any health-app prompt.',
          },
          {
            eyebrow: 'Guest mode ready',
            copy: 'Start locally today and decide on cloud access later without redoing setup.',
          },
        ].map((item) => (
          <AppCard key={item.eyebrow} style={styles.featureCard}>
            <AppText style={styles.featureEyebrow} variant="caption">
              {item.eyebrow}
            </AppText>
            <AppText>{item.copy}</AppText>
          </AppCard>
        ))}
      </View>
    </OnboardingScaffold>
  );
}

export function ConnectAppsScreen({
  currentStep,
  onBackPress,
  onConnect,
  onSkip,
  totalSteps,
}: {
  currentStep: number;
  onBackPress?: () => void;
  onConnect: () => void;
  onSkip: () => void;
  totalSteps: number;
}) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description="Health connections stay late in the flow so you can see the product value first."
      footer={
        <View style={styles.footerStack}>
          <BottomCTA label="Not now" onPress={onSkip} />
          <AppButton
            label="Connect later with Apple Health / Health Connect"
            onPress={onSkip}
            variant="ghost"
          />
        </View>
      }
      onBackPress={onBackPress}
      title="Connect your health apps"
      totalSteps={totalSteps}>
      <PermissionCard
        actionLabel="Mock permission request"
        body="This is a UI-only placeholder. No native permission request runs yet, but the surface is ready for the next integration slice."
        onPress={onConnect}
        title="Apple Health / Health Connect"
      />
    </OnboardingScaffold>
  );
}

export function PlanReadyScreen({
  currentStep,
  draft,
  onBackPress,
  onFinish,
  totalSteps,
}: {
  currentStep: number;
  draft: OnboardingDraft;
  onBackPress?: () => void;
  onFinish: () => void;
  totalSteps: number;
}) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description="Your mocked setup is ready. The next screen drops you into the Today placeholder with all selections kept locally."
      footer={<BottomCTA label="Let's get started" onPress={onFinish} />}
      onBackPress={onBackPress}
      scroll
      title="Your tracking plan is ready"
      totalSteps={totalSteps}>
      <SummaryCard items={buildSummaryItems(draft)} title="At a glance" />
      <SummaryCard items={buildPrivacySummary(draft)} title="Privacy setup" />
      {draft.trackType === 'glp' || draft.trackType === 'both' ? (
        <SummaryCard items={buildGlpSummary(draft)} title="GLP path" />
      ) : null}
      {draft.trackType === 'peptide' || draft.trackType === 'both' ? (
        <SummaryCard items={buildPeptideSummary(draft)} title="Peptide path" />
      ) : null}
    </OnboardingScaffold>
  );
}

const styles = StyleSheet.create({
  footerStack: {
    gap: atlasTheme.spacing.sm,
  },
  splashScreen: {
    justifyContent: 'space-between',
    overflow: 'hidden',
  },
  splashTopGlow: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: 999,
    height: 260,
    opacity: 0.9,
    position: 'absolute',
    right: -80,
    top: -20,
    width: 260,
  },
  splashBottomGlow: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: 999,
    bottom: -70,
    height: 240,
    left: -120,
    opacity: 0.75,
    position: 'absolute',
    width: 240,
  },
  splashContent: {
    gap: atlasTheme.spacing.xl,
    marginTop: atlasTheme.spacing.md,
  },
  brandBadge: {
    alignSelf: 'flex-start',
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: atlasTheme.radii.pill,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  brandBadgeText: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },
  brandBlock: {
    gap: atlasTheme.spacing.md,
  },
  splashWordmark: {
    fontSize: 58,
    letterSpacing: -2.2,
    lineHeight: 62,
  },
  splashSubtitle: {
    color: atlasTheme.colors.textSecondary,
    maxWidth: 320,
  },
  heroCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  heroCardContent: {
    gap: atlasTheme.spacing.md,
  },
  heroTokenRow: {
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
  },
  heroToken: {
    backgroundColor: atlasTheme.colors.primary,
    borderRadius: atlasTheme.radii.pill,
    height: 12,
    width: 48,
  },
  heroTokenWide: {
    backgroundColor: '#C7D9FB',
    borderRadius: atlasTheme.radii.pill,
    height: 12,
    width: 92,
  },
  heroCardTitle: {
    fontSize: 26,
  },
  splashFooter: {
    paddingBottom: atlasTheme.spacing.xl,
  },
  introFeatureStack: {
    gap: atlasTheme.spacing.md,
  },
  featureCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  featureEyebrow: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    marginBottom: atlasTheme.spacing.xs,
    textTransform: 'uppercase',
  },
});

import { useMemo, useState } from 'react';

import { router, type Href } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { authCredentialsSchema } from '@/src/features/auth/schema';
import { useAuthStore } from '@/src/features/auth/store';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { atlasTheme } from '@/src/theme/tokens';

type AuthMode = 'signIn' | 'signUp';

export function AuthPlaceholderScreen() {
  const [mode, setMode] = useState<AuthMode>('signUp');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; password?: string }>({});

  const session = useAuthStore((state) => state.session);
  const error = useAuthStore((state) => state.error);
  const isPending = useAuthStore((state) => state.isPending);
  const isConfigAvailable = useAuthStore((state) => state.isConfigAvailable);
  const guestUpgradePlan = useAuthStore((state) => state.guestUpgradePlan);
  const signIn = useAuthStore((state) => state.signIn);
  const signUp = useAuthStore((state) => state.signUp);
  const signOut = useAuthStore((state) => state.signOut);

  const completionStatus = useOnboardingStore((state) => state.completionStatus);
  const updateDraft = useOnboardingStore((state) => state.updateDraft);

  const ctaLabel = mode === 'signUp' ? 'Create account' : 'Sign in';
  const returnHref = useMemo(
    () =>
      completionStatus.isComplete
        ? ('/settings' as Href)
        : ({ pathname: '/onboarding', params: { step: 'accountMode' } } as Href),
    [completionStatus.isComplete]
  );

  const handleSubmit = async () => {
    const parsed = authCredentialsSchema.safeParse({ email, password });

    if (!parsed.success) {
      const flattened = parsed.error.flatten().fieldErrors;
      setFieldErrors({
        email: flattened.email?.[0],
        password: flattened.password?.[0],
      });
      return;
    }

    setFieldErrors({});

    if (mode === 'signUp') {
      await signUp(parsed.data);
    } else {
      await signIn(parsed.data);
    }

    const nextStatus = useAuthStore.getState().session.status;

    if (nextStatus === 'authenticated') {
      await updateDraft((currentDraft) => ({
        ...currentDraft,
        accountMode: mode === 'signUp' ? 'create' : 'signIn',
      }));
      router.replace(returnHref);
    }
  };

  const handleBack = () => {
    router.replace(returnHref);
  };

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Keep guest mode, add email auth when you want backup continuity, and never lose the local-first records already on this device."
          eyebrow="Account"
          title="Guest-first auth"
          trailing={
            <StatusPill
              label={session.status === 'authenticated' ? 'Account active' : 'Guest mode ready'}
              tone={session.status === 'authenticated' ? 'success' : 'muted'}
            />
          }
        />

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Upgrade path</AppText>
            <AppText variant="caption">
              {guestUpgradePlan.hasLocalData
                ? `${guestUpgradePlan.pendingUploadCount} local records are ready to attach to an account when sync is enabled.`
                : 'No local records need migration yet, so you can switch modes with a clean slate.'}
            </AppText>
            <View style={styles.modeStack}>
              <ProtocolChoicePill
                description="Create a new Atlas account with email."
                isSelected={mode === 'signUp'}
                label="Create account"
                onPress={() => {
                  setMode('signUp');
                }}
              />
              <ProtocolChoicePill
                description="Sign in to an existing Atlas account."
                isSelected={mode === 'signIn'}
                label="Sign in"
                onPress={() => {
                  setMode('signIn');
                }}
              />
            </View>
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppInput
              autoCapitalize="none"
              autoCorrect={false}
              description="Email auth is optional. Guest mode remains fully supported."
              error={fieldErrors.email}
              keyboardType="email-address"
              label="Email"
              onChangeText={setEmail}
              placeholder="you@example.com"
              value={email}
            />
            <AppInput
              autoCapitalize="none"
              autoCorrect={false}
              error={fieldErrors.password}
              label="Password"
              onChangeText={setPassword}
              placeholder="At least 8 characters"
              secureTextEntry
              value={password}
            />
            {error ? (
              <AppText style={styles.errorText} variant="caption">
                {error}
              </AppText>
            ) : null}
            {!isConfigAvailable ? (
              <AppText variant="caption">
                Supabase environment values are missing in this build, so Atlas will stay guest-only
                until `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` are configured.
              </AppText>
            ) : null}
            <AppButton
              disabled={!isConfigAvailable || isPending}
              label={isPending ? `${ctaLabel}...` : ctaLabel}
              onPress={() => {
                void handleSubmit();
              }}
            />
            <AppButton label="Keep using guest mode" onPress={handleBack} variant="ghost" />
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Current session</AppText>
            <AppText variant="caption">
              {session.status === 'authenticated'
                ? `Signed in as ${session.email ?? 'an Atlas account'}. Local data stays on device first and is only prepared for cloud sync.`
                : 'Still a guest. Core tracking, reminders, inventory, and timeline use remain local-first.'}
            </AppText>
            {session.status === 'authenticated' ? (
              <AppButton
                label={isPending ? 'Signing out...' : 'Sign out'}
                onPress={() => {
                  void signOut().then(() => {
                    router.replace(returnHref);
                  });
                }}
                variant="secondary"
              />
            ) : null}
          </View>
        </AppCard>
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  errorText: {
    color: '#B53F3F',
  },
  modeStack: {
    gap: atlasTheme.spacing.sm,
  },
  section: {
    gap: atlasTheme.spacing.md,
  },
});

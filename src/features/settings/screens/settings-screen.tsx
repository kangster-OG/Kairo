import { useEffect } from 'react';

import { router } from 'expo-router';
import { Switch, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useAuthStore } from '@/src/features/auth/store';
import {
  useAttemptHealthConnectionMutation,
  useHealthConnectionItemsQuery,
  useSetHealthConnectionEnabledMutation,
} from '@/src/features/health/hooks';
import { privacyOptions } from '@/src/features/onboarding/content';
import { formatAccountMode } from '@/src/features/onboarding/helpers';
import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { useReminderPreferencesQuery, useUpdateReminderPreferencesMutation } from '@/src/features/reminders/hooks';
import { useTrustVaultQuery } from '@/src/features/trust-vault/hooks';
import {
  buildReminderPreview,
  getEffectiveReminderPrivacyMode,
  getIsDiscreetModeEnabled,
  indexProtocolAliases,
} from '@/src/features/trust-vault/privacy';
import { useAppStore } from '@/src/store/app-store';
import { atlasTheme } from '@/src/theme/tokens';

const reminderLeadOptions = [
  { label: 'At due time', value: 0 },
  { label: '15 min before', value: 15 },
  { label: '1 hour before', value: 60 },
] as const;

const reminderPrivacyOptions = [
  { label: 'Full detail', value: 'full_detail' },
  { label: 'Generic reminder', value: 'generic' },
  { label: 'Silent mode', value: 'silent' },
] as const;

export function SettingsScreen() {
  const draft = useOnboardingStore((state) => state.draft);
  const updateDraft = useOnboardingStore((state) => state.updateDraft);
  const resetOnboarding = useOnboardingStore((state) => state.reset);
  const setHasCompletedOnboarding = useAppStore((state) => state.setHasCompletedOnboarding);
  const authSession = useAuthStore((state) => state.session);
  const authError = useAuthStore((state) => state.error);
  const guestUpgradePlan = useAuthStore((state) => state.guestUpgradePlan);
  const isAuthPending = useAuthStore((state) => state.isPending);
  const isConfigAvailable = useAuthStore((state) => state.isConfigAvailable);
  const refreshGuestUpgradePlan = useAuthStore((state) => state.refreshGuestUpgradePlan);
  const signOut = useAuthStore((state) => state.signOut);
  const syncStatus = useAuthStore((state) => state.syncStatus);
  const reminderPreferencesQuery = useReminderPreferencesQuery();
  const updateReminderPreferencesMutation = useUpdateReminderPreferencesMutation();
  const healthConnectionsQuery = useHealthConnectionItemsQuery();
  const setHealthConnectionEnabledMutation = useSetHealthConnectionEnabledMutation();
  const attemptHealthConnectionMutation = useAttemptHealthConnectionMutation();
  const trustVaultQuery = useTrustVaultQuery();

  useEffect(() => {
    void refreshGuestUpgradePlan();
  }, [refreshGuestUpgradePlan]);

  const togglePrivacyValue = (value: keyof OnboardingDraft['privacy']) => {
    void updateDraft((currentDraft) => ({
      ...currentDraft,
      privacy: {
        ...currentDraft.privacy,
        [value]: !currentDraft.privacy[value],
      },
    }));
  };

  const handleReset = async () => {
    await resetOnboarding();
    setHasCompletedOnboarding(false);
    router.replace('/onboarding');
  };

  const discreetModeEnabled = getIsDiscreetModeEnabled(draft.privacy);
  const trustVaultProfile = trustVaultQuery.data?.profile;
  const trustVaultAliases = trustVaultQuery.data
    ? indexProtocolAliases(trustVaultQuery.data.aliases)
    : undefined;
  const reminderPreferences = reminderPreferencesQuery.data;
  const reminderPreview = reminderPreferences
    ? buildReminderPreview(
        {
          protocolId: trustVaultQuery.data?.protocols[0]?.id ?? 'preview-protocol',
          kind: 'glp',
          protocolName: 'Wegovy',
          whenLabel: 'Today at 8:00 AM',
        },
        reminderPreferences,
        draft.privacy,
        trustVaultProfile,
        trustVaultAliases
      )
    : null;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Privacy and account controls stay easy to audit. Nothing in Settings should force a cloud path before the local-first MVP is ready."
          eyebrow="Settings"
          title="Privacy-first controls"
          trailing={
            <StatusPill
              label={discreetModeEnabled ? 'Discreet mode active' : 'Standard privacy view'}
              tone={discreetModeEnabled ? 'success' : 'muted'}
            />
          }
        />

        <AppCard>
          <View style={styles.section}>
            <View style={styles.statusRow}>
              <AppText variant="heading">Account status</AppText>
              <StatusPill
                label={
                  authSession.status === 'authenticated'
                    ? 'Signed in'
                    : isConfigAvailable
                      ? 'Guest'
                      : 'Guest-only build'
                }
                tone={authSession.status === 'authenticated' ? 'success' : 'muted'}
              />
            </View>
            <AppText variant="caption">
              {authSession.status === 'authenticated'
                ? `Signed in as ${authSession.email ?? 'an Atlas account'}. Local-first remains active even if sync is offline.`
                : `Current mode: ${formatAccountMode(draft.accountMode)}. Guest mode stays fully usable, and any local records can be prepared for account upgrade later.`}
            </AppText>
            {authSession.status === 'authenticated' ? (
              <AppButton
                disabled={isAuthPending}
                label={isAuthPending ? 'Signing out...' : 'Sign out'}
                onPress={() => {
                  void signOut();
                }}
                variant="secondary"
              />
            ) : (
              <AppButton
                disabled={!isConfigAvailable}
                label={isConfigAvailable ? 'Create account or sign in' : 'Supabase config required'}
                onPress={() => {
                  router.push('/auth');
                }}
              />
            )}
            {!isConfigAvailable ? (
              <AppText variant="caption">
                Configure `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` to enable
                email auth. Atlas will stay guest-first until then.
              </AppText>
            ) : null}
            {authError ? <AppText style={styles.errorText} variant="caption">{authError}</AppText> : null}
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <View style={styles.statusRow}>
              <AppText variant="heading">Trust Vault</AppText>
              <StatusPill
                label={
                  trustVaultProfile?.aliasModeEnabled
                    ? 'Alias mode ready'
                    : discreetModeEnabled
                      ? 'Discreet mode active'
                      : 'Standard mode'
                }
                tone={trustVaultProfile?.aliasModeEnabled ? 'success' : 'muted'}
              />
            </View>
            <AppText variant="caption">
              Manage aliases, sensitive-action gating, selective sharing, and the audit trail in one dedicated place.
            </AppText>
            <AppButton
              label="Open Trust Vault"
              onPress={() => {
                router.push('/trust-vault' as never);
              }}
            />
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <View style={styles.statusRow}>
              <AppText variant="heading">Sync status</AppText>
              <StatusPill label={formatSyncModeLabel(syncStatus.mode)} tone={getSyncTone(syncStatus.mode)} />
            </View>
            <AppText variant="caption">
              {getSyncCopy(syncStatus.mode, guestUpgradePlan.pendingUploadCount)}
            </AppText>
            <View style={styles.syncStats}>
              <StatusPill label={`${guestUpgradePlan.pendingUploadCount} pending uploads`} tone="muted" />
              <StatusPill label={`${syncStatus.pendingDownloadCount} pending downloads`} tone="muted" />
            </View>
            {guestUpgradePlan.hasLocalData ? (
              <AppText variant="caption">
                Upgrade plan: {guestUpgradePlan.recordCounts.protocols} protocols, {guestUpgradePlan.recordCounts.logEvents} log events, {guestUpgradePlan.recordCounts.vials} vials, and {guestUpgradePlan.recordCounts.sites} sites are ready for future cloud migration.
              </AppText>
            ) : null}
            {syncStatus.lastError ? (
              <AppText style={styles.errorText} variant="caption">
                {syncStatus.lastError}
              </AppText>
            ) : null}
            <AppButton
              label="Refresh local sync status"
              onPress={() => {
                void refreshGuestUpgradePlan();
              }}
              variant="secondary"
            />
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Reminder settings</AppText>
            {reminderPreferences ? (
              <View style={styles.section}>
                <View style={styles.settingRow}>
                  <View style={styles.settingCopy}>
                    <AppText>Enable local reminders</AppText>
                    <AppText variant="caption">
                      Notifications are scheduled locally from generated occurrences. Guest mode still works.
                    </AppText>
                  </View>
                  <Switch
                    accessibilityHint="Enable or disable local Atlas reminders."
                    accessibilityLabel="Enable local reminders"
                    onValueChange={(value) => {
                      void updateReminderPreferencesMutation.mutateAsync({ remindersEnabled: value });
                    }}
                    thumbColor="#FFFFFF"
                    trackColor={{
                      false: '#D7E1F2',
                      true: atlasTheme.colors.primary,
                    }}
                    value={reminderPreferences.remindersEnabled}
                  />
                </View>

                {reminderPreferencesQuery.isError ? (
                  <FeedbackStateCard
                    actionLabel="Retry reminder settings"
                    body="Atlas could not load the current reminder preferences, but the rest of the app is still usable."
                    onAction={() => {
                      void reminderPreferencesQuery.refetch();
                    }}
                    title="Reminder settings unavailable"
                  />
                ) : null}

                <View style={styles.section}>
                  <AppText variant="caption">Lead time</AppText>
                  <View style={styles.modeStack}>
                    {reminderLeadOptions.map((option) => (
                      <ProtocolChoicePill
                        key={option.value}
                        isSelected={reminderPreferences.leadTimeMinutes === option.value}
                        label={option.label}
                        onPress={() => {
                          void updateReminderPreferencesMutation.mutateAsync({
                            leadTimeMinutes: option.value,
                          });
                        }}
                      />
                    ))}
                  </View>
                </View>

                <View style={styles.section}>
                  <AppText variant="caption">Notification privacy</AppText>
                  <View style={styles.modeStack}>
                    {reminderPrivacyOptions.map((option) => (
                      <ProtocolChoicePill
                        key={option.value}
                        description={
                          option.value === 'full_detail'
                            ? 'Uses protocol names unless discreet mode forces a safer fallback.'
                            : option.value === 'generic'
                              ? 'Uses neutral Atlas wording.'
                              : 'Uses the calmest local notification style available.'
                        }
                        isSelected={reminderPreferences.privacyMode === option.value}
                        label={option.label}
                        onPress={() => {
                          void updateReminderPreferencesMutation.mutateAsync({
                            privacyMode: option.value,
                          });
                        }}
                      />
                    ))}
                  </View>
                </View>

                {reminderPreview ? (
                  <View style={styles.previewCard}>
                    <View style={styles.statusRow}>
                      <StatusPill
                        label={`Effective mode: ${formatReminderModeLabel(
                          getEffectiveReminderPrivacyMode(
                            reminderPreferences.privacyMode,
                            draft.privacy,
                            trustVaultProfile
                          )
                        )}`}
                        tone="muted"
                      />
                    </View>
                    <AppText>Preview title: {reminderPreview.title}</AppText>
                    <AppText variant="caption">Preview body: {reminderPreview.body}</AppText>
                  </View>
                ) : null}
              </View>
            ) : (
              <AppText variant="caption">Loading local reminder settings.</AppText>
            )}
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Privacy settings</AppText>
            <View style={styles.settingsList}>
              {privacyOptions.map((option) => (
                <View key={option.value} style={styles.settingRow}>
                  <View style={styles.settingCopy}>
                    <AppText>{option.label}</AppText>
                    <AppText variant="caption">{option.description}</AppText>
                  </View>
                  <Switch
                    accessibilityHint={option.description}
                    accessibilityLabel={option.label}
                    onValueChange={() => {
                      togglePrivacyValue(option.value);
                    }}
                    thumbColor="#FFFFFF"
                    trackColor={{
                      false: '#D7E1F2',
                      true: atlasTheme.colors.primary,
                    }}
                    value={draft.privacy[option.value]}
                  />
                </View>
              ))}
            </View>
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Health connections</AppText>
            <AppText variant="caption">
              Health links remain optional. Atlas keeps working locally even if a provider is unavailable or the adapter fails.
            </AppText>
            {healthConnectionsQuery.isLoading ? (
              <AppText variant="caption">Loading provider status.</AppText>
            ) : healthConnectionsQuery.isError ? (
              <FeedbackStateCard
                actionLabel="Retry health status"
                body="Atlas could not load provider status. Health adapters stay optional and nothing else is blocked."
                onAction={() => {
                  void healthConnectionsQuery.refetch();
                }}
                title="Health status unavailable"
              />
            ) : (
              <View style={styles.utilityStack}>
                {healthConnectionsQuery.data?.map((provider) => (
                  <View key={provider.providerKey} style={styles.providerCard}>
                    <View style={styles.statusRow}>
                      <View style={styles.settingCopy}>
                        <AppText>{provider.title}</AppText>
                        <AppText variant="caption">{provider.description}</AppText>
                        <AppText variant="caption">{provider.platformLabel}</AppText>
                        {provider.lastError ? (
                          <AppText style={styles.errorText} variant="caption">
                            {provider.lastError}
                          </AppText>
                        ) : null}
                      </View>
                      <Switch
                        onValueChange={(value) => {
                          void setHealthConnectionEnabledMutation.mutateAsync({
                            enabled: value,
                            providerKey: provider.providerKey,
                          });
                        }}
                        thumbColor="#FFFFFF"
                        trackColor={{
                          false: '#D7E1F2',
                          true: atlasTheme.colors.primary,
                        }}
                        value={provider.enabled}
                      />
                    </View>
                    <View style={styles.statusRow}>
                      <StatusPill label={provider.statusLabel} tone={provider.connected ? 'success' : 'muted'} />
                      {provider.lastSyncAt ? (
                        <StatusPill label={`Checked ${formatTimestamp(provider.lastSyncAt)}`} tone="muted" />
                      ) : null}
                    </View>
                    <AppButton
                      label={
                        attemptHealthConnectionMutation.isPending
                          ? 'Checking adapter...'
                          : 'Check provider adapter'
                      }
                      onPress={() => {
                        void attemptHealthConnectionMutation.mutateAsync(provider.providerKey);
                      }}
                      variant="secondary"
                    />
                  </View>
                )) ?? null}
              </View>
            )}
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Data export</AppText>
            <View style={styles.utilityStack}>
              <View style={styles.utilityCopy}>
                <AppText>Account data export entry point</AppText>
                <AppText variant="caption">
                  Trust Vault now owns sensitive bundle creation so privacy policy, alias mode, and biometric gating stay consistent.
                </AppText>
              </View>
              <AppButton
                label="Open Trust Vault export tools"
                onPress={() => {
                  router.push('/trust-vault' as never);
                }}
              />
              <AppText variant="caption">
                Atlas only exports static local snapshots. Nothing becomes a live shared link in V1.
              </AppText>
            </View>
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">QA tools</AppText>
            <AppText variant="caption">
              Reset onboarding to replay the full first-run flow without clearing the whole app manually.
            </AppText>
            <AppButton label="Reset onboarding for QA" onPress={() => void handleReset()} />
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
  section: {
    gap: atlasTheme.spacing.md,
  },
  settingsList: {
    gap: atlasTheme.spacing.md,
  },
  settingRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  settingCopy: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
  },
  utilityStack: {
    gap: atlasTheme.spacing.md,
  },
  utilityCopy: {
    gap: atlasTheme.spacing.xs,
  },
  providerCard: {
    borderColor: atlasTheme.colors.border,
    borderTopWidth: 1,
    gap: atlasTheme.spacing.md,
    paddingTop: atlasTheme.spacing.md,
  },
  errorText: {
    color: '#B53F3F',
  },
  modeStack: {
    gap: atlasTheme.spacing.sm,
  },
  previewCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.card,
    gap: atlasTheme.spacing.sm,
    padding: atlasTheme.spacing.md,
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  syncStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
});

function formatTimestamp(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function formatReminderModeLabel(value: 'full_detail' | 'generic' | 'silent') {
  switch (value) {
    case 'full_detail':
      return 'Full detail';
    case 'generic':
      return 'Generic reminder';
    default:
      return 'Silent mode';
  }
}

function formatSyncModeLabel(value: 'local_only' | 'ready_to_sync' | 'syncing' | 'sync_error' | 'synced') {
  switch (value) {
    case 'ready_to_sync':
      return 'Ready to sync';
    case 'syncing':
      return 'Syncing';
    case 'sync_error':
      return 'Sync issue';
    case 'synced':
      return 'Synced';
    default:
      return 'Local only';
  }
}

function getSyncTone(value: 'local_only' | 'ready_to_sync' | 'syncing' | 'sync_error' | 'synced') {
  switch (value) {
    case 'synced':
      return 'success' as const;
    case 'ready_to_sync':
    case 'syncing':
      return 'default' as const;
    default:
      return 'muted' as const;
  }
}

function getSyncCopy(
  value: 'local_only' | 'ready_to_sync' | 'syncing' | 'sync_error' | 'synced',
  pendingUploadCount: number
) {
  switch (value) {
    case 'ready_to_sync':
      return `${pendingUploadCount} local records are queued for future account sync. Atlas keeps using the local database until you choose to sync.`;
    case 'syncing':
      return 'Atlas is syncing in the background without blocking your local workflow.';
    case 'sync_error':
      return 'Atlas kept all local data intact. You can retry sync status later without losing access.';
    case 'synced':
      return 'Local data and account state are aligned for the current v1 sync boundary.';
    default:
      return 'Atlas is operating entirely local-first right now. Network access is optional, not required.';
  }
}

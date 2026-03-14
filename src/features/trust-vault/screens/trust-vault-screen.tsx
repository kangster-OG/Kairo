import { useEffect, useState } from 'react';

import { Switch, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import {
  useCreateSelectiveShareBundleMutation,
  useSaveProtocolAliasMutation,
  useSelectiveSharePreviewQuery,
  useTrustVaultQuery,
  useUnlockTrustVaultMutation,
  useUpdateTrustVaultProfileMutation,
} from '@/src/features/trust-vault/hooks';
import type { SelectiveShareScopeKind } from '@/src/features/trust-vault/schema';
import {
  formatCompoundDisplayName,
  formatProtocolDisplayName,
  resolvePrivacyRenderMode,
} from '@/src/features/trust-vault/privacy';
import type { BiometricGateMode, PrivacyRenderMode } from '@/src/lib/database/schemas';
import { atlasTheme } from '@/src/theme/tokens';

const shareScopeOptions: { label: string; value: SelectiveShareScopeKind }[] = [
  { label: 'Summary only', value: 'summary_only' },
  { label: 'Current protocol', value: 'current_protocol_only' },
  { label: 'Protocol + timeline', value: 'protocol_with_recent_timeline' },
  { label: 'Last 30 days logs', value: 'last_30_days_logs' },
  { label: 'Symptoms only', value: 'symptoms_only' },
  { label: 'Inventory only', value: 'inventory_only' },
  { label: 'Custom range', value: 'custom_date_range' },
];

const renderModeOptions: { label: string; value: PrivacyRenderMode }[] = [
  { label: 'Full labels', value: 'full' },
  { label: 'Discreet labels', value: 'discreet' },
  { label: 'Alias labels', value: 'alias' },
];

const biometricModeOptions: { label: string; value: BiometricGateMode }[] = [
  { label: 'Off', value: 'off' },
  { label: 'Best effort', value: 'best_effort' },
  { label: 'Require when available', value: 'required_when_available' },
];

type AliasDraft = {
  aliasCompoundLabel: string;
  aliasLabel: string;
};

export function TrustVaultScreen() {
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const trustVaultQuery = useTrustVaultQuery();
  const updateProfileMutation = useUpdateTrustVaultProfileMutation();
  const saveAliasMutation = useSaveProtocolAliasMutation();
  const unlockMutation = useUnlockTrustVaultMutation();
  const createBundleMutation = useCreateSelectiveShareBundleMutation();

  const [aliasDrafts, setAliasDrafts] = useState<Record<string, AliasDraft>>({});
  const [bundleMessage, setBundleMessage] = useState<string | null>(null);
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [scopeKind, setScopeKind] = useState<SelectiveShareScopeKind>('summary_only');
  const [selectedProtocolId, setSelectedProtocolId] = useState<string | null>(null);
  const [renderMode, setRenderMode] = useState<PrivacyRenderMode>('alias');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [passphrase, setPassphrase] = useState('');

  const snapshot = trustVaultQuery.data;
  const profile = snapshot?.profile;

  useEffect(() => {
    if (!snapshot) {
      return;
    }

    setAliasDrafts((current) => {
      if (Object.keys(current).length > 0) {
        return current;
      }

      return snapshot.protocols.reduce<Record<string, AliasDraft>>((result, protocol) => {
        result[protocol.id] = {
          aliasCompoundLabel: protocol.aliasCompoundLabel,
          aliasLabel: protocol.aliasLabel,
        };
        return result;
      }, {});
    });
  }, [snapshot]);

  useEffect(() => {
    if (!profile) {
      return;
    }

    setRenderMode(
      profile.shareAliasByDefault
        ? 'alias'
        : resolvePrivacyRenderMode(privacy, profile)
    );
    setIsUnlocked(!profile.biometricLockEnabled);
  }, [privacy, profile]);

  const previewInput =
    snapshot &&
    passphrase.trim().length >= 8 &&
    (scopeKind !== 'current_protocol_only' && scopeKind !== 'protocol_with_recent_timeline'
      ? true
      : Boolean(selectedProtocolId)) &&
    (scopeKind !== 'custom_date_range' || (startDate.trim() && endDate.trim()))
      ? {
          endDate: scopeKind === 'custom_date_range' ? endDate.trim() || null : null,
          protocolId:
            scopeKind === 'current_protocol_only' || scopeKind === 'protocol_with_recent_timeline'
              ? selectedProtocolId
              : null,
          renderMode,
          scopeKind,
          shareAfterCreate: false,
          startDate: scopeKind === 'custom_date_range' ? startDate.trim() || null : null,
        }
      : null;

  const previewQuery = useSelectiveSharePreviewQuery(previewInput);

  if (trustVaultQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is loading local privacy policy, aliases, and the sensitive-action audit trail."
          isLoading
          title="Loading Trust Vault"
        />
      </AppScreen>
    );
  }

  if (trustVaultQuery.isError || !snapshot || !profile) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Try again"
          body="Trust Vault could not load, but Atlas kept the rest of the app safe and usable."
          onAction={() => {
            void trustVaultQuery.refetch();
          }}
          title="Trust Vault unavailable"
        />
      </AppScreen>
    );
  }

  const requiresUnlock = profile.biometricLockEnabled && !isUnlocked;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Trust Vault is the control center for privacy rendering, sensitive action gates, scoped sharing, and audit visibility."
          eyebrow="Trust Vault"
          title="Least privilege, made visible"
          trailing={
            <View style={styles.statusRow}>
              <StatusPill
                label={`Render mode: ${formatRenderModeLabel(snapshot.effectiveRenderMode)}`}
                tone={snapshot.effectiveRenderMode === 'full' ? 'muted' : 'success'}
              />
              <StatusPill
                label={profile.biometricLockEnabled ? 'Biometric gate on' : 'Biometric gate off'}
                tone={profile.biometricLockEnabled ? 'default' : 'muted'}
              />
            </View>
          }
        />

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Privacy policy</AppText>
            <View style={styles.settingRow}>
              <View style={styles.settingCopy}>
                <AppText>Alias mode</AppText>
                <AppText variant="caption">
                  Replace protocol and compound labels with codenames anywhere the unified formatter is used.
                </AppText>
              </View>
              <Switch
                onValueChange={(value) => {
                  void updateProfileMutation.mutateAsync({ aliasModeEnabled: value });
                }}
                thumbColor="#FFFFFF"
                trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                value={profile.aliasModeEnabled}
              />
            </View>
            <View style={styles.settingRow}>
              <View style={styles.settingCopy}>
                <AppText>Biometric lock</AppText>
                <AppText variant="caption">
                  Protect Trust Vault and private bundle creation with device biometrics where available.
                </AppText>
              </View>
              <Switch
                onValueChange={(value) => {
                  void updateProfileMutation
                    .mutateAsync({ biometricLockEnabled: value })
                    .then(() => {
                      setIsUnlocked(!value);
                    });
                }}
                thumbColor="#FFFFFF"
                trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                value={profile.biometricLockEnabled}
              />
            </View>
            <View style={styles.pillStack}>
              {biometricModeOptions.map((option) => (
                <ProtocolChoicePill
                  key={option.value}
                  description={
                    option.value === 'required_when_available'
                      ? 'Block sensitive actions if enrolled biometrics are available but not approved.'
                      : option.value === 'best_effort'
                        ? 'Ask when possible, but keep local-first access moving.'
                        : 'Leave biometric gating off.'
                  }
                  isSelected={profile.biometricGateMode === option.value}
                  label={option.label}
                  onPress={() => {
                    void updateProfileMutation.mutateAsync({ biometricGateMode: option.value });
                  }}
                />
              ))}
            </View>
            <View style={styles.settingRow}>
              <View style={styles.settingCopy}>
                <AppText>Alias by default for selective share</AppText>
                <AppText variant="caption">
                  Start scoped shares in alias mode unless you explicitly choose a different preview mode.
                </AppText>
              </View>
              <Switch
                onValueChange={(value) => {
                  void updateProfileMutation.mutateAsync({ shareAliasByDefault: value });
                }}
                thumbColor="#FFFFFF"
                trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                value={profile.shareAliasByDefault}
              />
            </View>
            <View style={styles.settingRow}>
              <View style={styles.settingCopy}>
                <AppText>Alias by default for full export</AppText>
                <AppText variant="caption">
                  Atlas respects the active privacy policy when exporting broad snapshots too.
                </AppText>
              </View>
              <Switch
                onValueChange={(value) => {
                  void updateProfileMutation.mutateAsync({ exportAliasByDefault: value });
                }}
                thumbColor="#FFFFFF"
                trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                value={profile.exportAliasByDefault}
              />
            </View>
          </View>
        </AppCard>

        {requiresUnlock ? (
          <AppCard>
            <View style={styles.section}>
              <AppText variant="heading">Trust Vault is locked</AppText>
              <AppText variant="caption">
                Unlock once to manage aliases, review scoped share contents, or create an encrypted bundle.
              </AppText>
              <AppButton
                label={unlockMutation.isPending ? 'Unlocking...' : 'Unlock Trust Vault'}
                onPress={() => {
                  void unlockMutation.mutateAsync().then((result) => {
                    if (result.granted) {
                      setIsUnlocked(true);
                      setBundleMessage('Trust Vault unlocked for this session.');
                      return;
                    }

                    setBundleMessage('Atlas could not unlock Trust Vault on this device.');
                  });
                }}
              />
              {bundleMessage ? <AppText variant="caption">{bundleMessage}</AppText> : null}
            </View>
          </AppCard>
        ) : (
          <>
            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Protocol aliases</AppText>
                <AppText variant="caption">
                  Aliases change presentation only. Canonical local records stay intact underneath.
                </AppText>
                <AppText variant="caption">
                  Save alias edits before using alias-mode previews or exports so the bundle matches what Atlas shows.
                </AppText>
                <View style={styles.aliasList}>
                  {snapshot.protocols.map((protocol) => (
                    <View key={protocol.id} style={styles.aliasCard}>
                      <View style={styles.statusRow}>
                        <View style={styles.settingCopy}>
                          <AppText>
                            {formatProtocolDisplayName(
                              protocol.canonicalName,
                              protocol.kind,
                              privacy,
                              profile,
                              {
                                aliasLabel: aliasDrafts[protocol.id]?.aliasLabel ?? protocol.aliasLabel,
                              },
                              'full',
                            )}
                          </AppText>
                          <AppText variant="caption">
                            {protocol.canonicalCompoundName
                              ? formatCompoundDisplayName(
                                  protocol.canonicalCompoundName,
                                  protocol.kind,
                                  privacy,
                                  profile,
                                  {
                                    aliasCompoundLabel:
                                      aliasDrafts[protocol.id]?.aliasCompoundLabel ??
                                      protocol.aliasCompoundLabel,
                                  },
                                  'full',
                                )
                              : 'No linked compound'}
                          </AppText>
                        </View>
                        <StatusPill label={protocol.kind.toUpperCase()} tone="muted" />
                      </View>
                      <AppInput
                        label="Protocol codename"
                        onChangeText={(value) => {
                          setAliasDrafts((current) => ({
                            ...current,
                            [protocol.id]: {
                              aliasCompoundLabel:
                                current[protocol.id]?.aliasCompoundLabel ?? protocol.aliasCompoundLabel,
                              aliasLabel: value,
                            },
                          }));
                        }}
                        placeholder="Night plan"
                        value={aliasDrafts[protocol.id]?.aliasLabel ?? protocol.aliasLabel}
                      />
                      <AppInput
                        label="Compound codename"
                        onChangeText={(value) => {
                          setAliasDrafts((current) => ({
                            ...current,
                            [protocol.id]: {
                              aliasCompoundLabel: value,
                              aliasLabel: current[protocol.id]?.aliasLabel ?? protocol.aliasLabel,
                            },
                          }));
                        }}
                        placeholder="Blue vial"
                        value={
                          aliasDrafts[protocol.id]?.aliasCompoundLabel ?? protocol.aliasCompoundLabel
                        }
                      />
                      <AppButton
                        label={saveAliasMutation.isPending ? 'Saving alias...' : 'Save alias'}
                        onPress={() => {
                          const nextAlias = aliasDrafts[protocol.id];
                          void saveAliasMutation
                            .mutateAsync({
                              aliasCompoundLabel: nextAlias?.aliasCompoundLabel?.trim() || null,
                              aliasLabel: nextAlias?.aliasLabel?.trim() || 'Alias protocol',
                              protocolId: protocol.id,
                            })
                            .then(() => {
                              setBundleMessage('Alias saved locally.');
                            });
                        }}
                        variant="secondary"
                      />
                    </View>
                  ))}
                </View>
              </View>
            </AppCard>

            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Selective sharing</AppText>
                <AppText variant="caption">
                  Atlas builds a static, encrypted local bundle. Nothing becomes a live link in V1.
                </AppText>
                <View style={styles.pillStack}>
                  {shareScopeOptions.map((option) => (
                    <ProtocolChoicePill
                      key={option.value}
                      isSelected={scopeKind === option.value}
                      label={option.label}
                      onPress={() => {
                        setScopeKind(option.value);
                      }}
                    />
                  ))}
                </View>

                {(scopeKind === 'current_protocol_only' || scopeKind === 'protocol_with_recent_timeline') ? (
                  <View style={styles.pillStack}>
                    {snapshot.protocols.map((protocol) => (
                      <ProtocolChoicePill
                        key={protocol.id}
                        isSelected={selectedProtocolId === protocol.id}
                        label={formatProtocolDisplayName(
                          protocol.canonicalName,
                          protocol.kind,
                          privacy,
                          profile,
                          {
                            aliasLabel: protocol.aliasLabel,
                          },
                          renderMode,
                        )}
                        onPress={() => {
                          setSelectedProtocolId(protocol.id);
                        }}
                      />
                    ))}
                  </View>
                ) : null}

                {scopeKind === 'custom_date_range' ? (
                  <View style={styles.dateRow}>
                    <AppInput
                      label="Start date"
                      onChangeText={setStartDate}
                      placeholder="YYYY-MM-DD"
                      value={startDate}
                    />
                    <AppInput
                      label="End date"
                      onChangeText={setEndDate}
                      placeholder="YYYY-MM-DD"
                      value={endDate}
                    />
                  </View>
                ) : null}

                <View style={styles.pillStack}>
                  {renderModeOptions.map((option) => (
                    <ProtocolChoicePill
                      key={option.value}
                      description={
                        option.value === 'full'
                          ? 'Use full labels in the bundle.'
                          : option.value === 'discreet'
                            ? 'Use private generic labels in the bundle.'
                            : 'Use protocol codenames in the bundle.'
                      }
                      isSelected={renderMode === option.value}
                      label={option.label}
                      onPress={() => {
                        setRenderMode(option.value);
                      }}
                    />
                  ))}
                </View>

                <AppInput
                  description="Use at least 8 characters. This passphrase encrypts the local bundle payload."
                  label="Bundle passphrase"
                  onChangeText={setPassphrase}
                  placeholder="Enter a bundle passphrase"
                  secureTextEntry
                  value={passphrase}
                />

                {previewQuery.isError ? (
                  <FeedbackStateCard
                    actionLabel="Retry preview"
                    body="Atlas could not build the scoped preview yet. Nothing has been exported."
                    onAction={() => {
                      void previewQuery.refetch();
                    }}
                    title="Preview unavailable"
                  />
                ) : previewQuery.data ? (
                  <View style={styles.previewCard}>
                    <View style={styles.statusRow}>
                      <StatusPill label={previewQuery.data.scopeLabel} tone="default" />
                      <StatusPill
                        label={`Mode: ${formatRenderModeLabel(previewQuery.data.renderMode)}`}
                        tone="muted"
                      />
                    </View>
                    {previewQuery.data.contentPreview.map((item) => (
                      <View key={item.label} style={styles.previewRow}>
                        <AppText>{item.label}</AppText>
                        <StatusPill label={item.value} tone="muted" />
                      </View>
                    ))}
                    {previewQuery.data.payload.notes.map((note) => (
                      <AppText key={note} variant="caption">
                        {note}
                      </AppText>
                    ))}
                  </View>
                ) : (
                  <AppText variant="caption">
                    Choose a scope and passphrase to preview the exact bundle content before export.
                  </AppText>
                )}

                <View style={styles.actionRow}>
                  <AppButton
                    disabled={!previewInput || createBundleMutation.isPending}
                    label={createBundleMutation.isPending ? 'Creating bundle...' : 'Create encrypted bundle'}
                    onPress={() => {
                      if (!previewInput) {
                        return;
                      }

                      void createBundleMutation
                        .mutateAsync({
                          ...previewInput,
                          passphrase: passphrase.trim(),
                          previewGeneratedAt: previewQuery.data?.payload.generatedAt,
                          shareAfterCreate: false,
                        })
                        .then((result) => {
                          setBundleMessage(`${result.fileName} created locally.`);
                        });
                    }}
                    variant="secondary"
                  />
                  <AppButton
                    disabled={!previewInput || createBundleMutation.isPending}
                    label="Create and share"
                    onPress={() => {
                      if (!previewInput) {
                        return;
                      }

                      void createBundleMutation
                        .mutateAsync({
                          ...previewInput,
                          passphrase: passphrase.trim(),
                          previewGeneratedAt: previewQuery.data?.payload.generatedAt,
                          shareAfterCreate: true,
                        })
                        .then((result) => {
                          setBundleMessage(
                            result.shared
                              ? `${result.fileName} created and opened in the share sheet.`
                              : `${result.fileName} created locally.`
                          );
                        });
                    }}
                  />
                </View>
                {bundleMessage ? <AppText variant="caption">{bundleMessage}</AppText> : null}
              </View>
            </AppCard>

            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Sensitive action audit</AppText>
                <AppText variant="caption">
                  This is a local record of privacy-affecting actions and snapshot exports, not a live sync trail.
                </AppText>
                <View style={styles.auditList}>
                  {snapshot.audits.length > 0 ? (
                    snapshot.audits.map((event) => (
                      <View key={event.id} style={styles.auditRow}>
                        <View style={styles.settingCopy}>
                          <AppText>{event.summaryLabel}</AppText>
                          <AppText variant="caption">{formatTimestamp(event.createdAt)}</AppText>
                        </View>
                        <StatusPill label={event.surface.replaceAll('_', ' ')} tone="muted" />
                      </View>
                    ))
                  ) : (
                    <AppText variant="caption">
                      Sensitive actions will appear here after aliases, privacy policy, or sharing changes.
                    </AppText>
                  )}
                </View>
              </View>
            </AppCard>
          </>
        )}
      </View>
    </AppScreen>
  );
}

function formatRenderModeLabel(mode: PrivacyRenderMode) {
  switch (mode) {
    case 'alias':
      return 'Alias';
    case 'discreet':
      return 'Discreet';
    default:
      return 'Full';
  }
}

function formatTimestamp(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    month: 'short',
  }).format(new Date(value));
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  section: {
    gap: atlasTheme.spacing.md,
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
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
  pillStack: {
    gap: atlasTheme.spacing.sm,
  },
  aliasList: {
    gap: atlasTheme.spacing.md,
  },
  aliasCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.card,
    gap: atlasTheme.spacing.md,
    padding: atlasTheme.spacing.md,
  },
  dateRow: {
    gap: atlasTheme.spacing.md,
  },
  previewCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.card,
    gap: atlasTheme.spacing.sm,
    padding: atlasTheme.spacing.md,
  },
  previewRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  actionRow: {
    gap: atlasTheme.spacing.sm,
  },
  auditList: {
    gap: atlasTheme.spacing.md,
  },
  auditRow: {
    alignItems: 'center',
    borderTopColor: atlasTheme.colors.border,
    borderTopWidth: 1,
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
    paddingTop: atlasTheme.spacing.md,
  },
});

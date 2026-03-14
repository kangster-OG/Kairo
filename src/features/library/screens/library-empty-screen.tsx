import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { EmptyStateCard } from '@/src/features/app-shell/components/empty-state-card';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useProtocolListQuery } from '@/src/features/protocols/hooks';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { useTrustVaultQuery } from '@/src/features/trust-vault/hooks';
import {
  formatCompoundDisplayName,
  formatProtocolDisplayName,
  indexProtocolAliases,
} from '@/src/features/trust-vault/privacy';
import { atlasTheme } from '@/src/theme/tokens';

export function LibraryEmptyScreen() {
  const protocolListQuery = useProtocolListQuery();
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const trustVaultQuery = useTrustVaultQuery();

  if (protocolListQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is reading saved protocols from the local database."
          isLoading
          title="Loading library"
        />
      </AppScreen>
    );
  }

  if (protocolListQuery.isError) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Try again"
          body="Atlas could not load the protocol library. Local records should still be safe."
          onAction={() => {
            void protocolListQuery.refetch();
          }}
          title="Library could not load"
        />
      </AppScreen>
    );
  }

  const protocols = protocolListQuery.data ?? [];
  const privacyProfile = trustVaultQuery.data?.profile;
  const aliasLookup = trustVaultQuery.data
    ? indexProtocolAliases(trustVaultQuery.data.aliases)
    : undefined;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description={
            protocols.length > 0
              ? 'Library keeps the active routine definitions Atlas uses for Today and future timeline work.'
              : 'Library is where protocols, saved setups, and future templates will live once structured local data lands.'
          }
          eyebrow="Library"
          title={protocols.length > 0 ? 'Your saved protocols' : 'Your protocols will live here'}
          trailing={
            <StatusPill
              label={protocols.length > 0 ? `${protocols.length} saved` : 'Guest mode ready'}
              tone="default"
            />
          }
        />

        {protocols.length === 0 ? (
          <>
            <EmptyStateCard
              body="Start with one protocol. Atlas will use it to unlock Today, timeline context, reminders, and inventory-aware empty states."
              eyebrow="First protocol"
              onPrimaryAction={() => {
                router.push('/protocols/new');
              }}
              primaryActionLabel="Create your first protocol"
              title="Build the foundation of your routine"
            />

            <AppCard style={styles.previewCard}>
              <View style={styles.previewCopy}>
                <AppText style={styles.sectionLabel} variant="caption">
                  What the library becomes
                </AppText>
                <AppText variant="caption">Active protocols, paused routines, archived history, and reusable setup patterns all in one place.</AppText>
              </View>
              <View style={styles.actionButtons}>
                <AppButton
                  label="Open inventory"
                  onPress={() => {
                    router.push('/inventory' as never);
                  }}
                  variant="secondary"
                />
                <AppButton
                  label="Open calculator"
                  onPress={() => {
                    router.push('/calculator' as never);
                  }}
                  variant="ghost"
                />
              </View>
            </AppCard>
          </>
        ) : (
          <>
            <AppCard style={styles.actionCard}>
              <View style={styles.previewCopy}>
                <AppText style={styles.sectionLabel} variant="caption">
                  Add another
                </AppText>
                <AppText variant="caption">You can add separate GLP, peptide, or custom routines without merging their history.</AppText>
              </View>
              <View style={styles.actionButtons}>
                <AppButton
                  label="Inventory"
                  onPress={() => {
                    router.push('/inventory' as never);
                  }}
                  variant="secondary"
                />
                <AppButton
                  label="Calculator"
                  onPress={() => {
                    router.push('/calculator' as never);
                  }}
                  variant="ghost"
                />
              </View>
              <EmptyStateCard
                body="Each saved protocol stays independent so future reminders, logs, and inventory can remain precise."
                eyebrow="Local-first"
                onPrimaryAction={() => {
                  router.push('/protocols/new');
                }}
                primaryActionLabel="Create another protocol"
                title="Expand your routine library"
              />
            </AppCard>

            <View style={styles.protocolList}>
              {protocols.map((protocol) => (
                <AppCard key={protocol.id} style={styles.protocolCard}>
                  <View style={styles.protocolHeader}>
                    <View style={styles.protocolCopy}>
                      <AppText variant="heading">
                        {formatProtocolDisplayName(
                          protocol.title,
                          protocol.kind,
                          privacy,
                          privacyProfile,
                          aliasLookup?.[protocol.id],
                        )}
                      </AppText>
                      <AppText variant="caption">{protocol.cadenceLabel}</AppText>
                    </View>
                    <StatusPill label={protocol.kindLabel} tone="muted" />
                  </View>
                  {protocol.compoundName ? (
                    <AppText variant="caption">
                      {formatCompoundDisplayName(
                        protocol.compoundName,
                        protocol.kind,
                        privacy,
                        privacyProfile,
                        aliasLookup?.[protocol.id],
                      )}
                    </AppText>
                  ) : null}
                  {protocol.doseLabel ? <AppText variant="caption">Saved amount: {protocol.doseLabel}</AppText> : null}
                  {protocol.nextDue ? <AppText variant="caption">Next due: {protocol.nextDue.whenLabel}</AppText> : null}
                  {protocol.notes ? <AppText variant="caption">{protocol.notes}</AppText> : null}
                  <View style={styles.cardActions}>
                    <AppButton
                      label="Open detail"
                      onPress={() => {
                        router.push(`/protocols/${protocol.id}` as never);
                      }}
                      variant="secondary"
                    />
                    <AppButton
                      label="Change future plan"
                      onPress={() => {
                        router.push(`/protocols/${protocol.id}/change` as never);
                      }}
                      variant="ghost"
                    />
                  </View>
                </AppCard>
              ))}
            </View>
          </>
        )}
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  previewCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  actionCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    gap: atlasTheme.spacing.md,
  },
  previewCopy: {
    gap: atlasTheme.spacing.sm,
  },
  actionButtons: {
    gap: atlasTheme.spacing.sm,
  },
  protocolList: {
    gap: atlasTheme.spacing.md,
  },
  protocolCard: {
    gap: atlasTheme.spacing.sm,
  },
  cardActions: {
    gap: atlasTheme.spacing.sm,
  },
  protocolHeader: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  protocolCopy: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
});

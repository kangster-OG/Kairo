import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useProtocolChangeDetailQuery } from '@/src/features/protocol-changes/hooks';
import { atlasFeatureFlags } from '@/src/lib/feature-flags';
import { atlasTheme } from '@/src/theme/tokens';

export function ProtocolDetailScreen({ protocolId }: { protocolId: string }) {
  const detailQuery = useProtocolChangeDetailQuery(protocolId);

  if (detailQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is reading the current local protocol revision, reminders, and audit history."
          isLoading
          title="Loading protocol"
        />
      </AppScreen>
    );
  }

  if (detailQuery.isError || !detailQuery.data) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Back"
          body="Atlas could not load this protocol detail locally."
          onAction={() => {
            router.back();
          }}
          title="Protocol could not load"
        />
      </AppScreen>
    );
  }

  const detail = detailQuery.data;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Protocol detail is the safe home for future-only edits, audit history, and revision-aware previews."
          eyebrow="Protocol detail"
          title={detail.bundle.protocol.name}
          trailing={
            <StatusPill
              label={detail.activeSnapshot.revision?.lifecycleState ?? detail.bundle.protocol.status}
              tone="default"
            />
          }
        />

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Current future plan
            </AppText>
            <AppText variant="heading">{detail.activeSnapshot.cadenceLabel}</AppText>
            <AppText variant="caption">
              {detail.activeSnapshot.doseLabel ?? 'No saved amount'}
            </AppText>
            <AppText variant="caption">
              {detail.nextDue ? `Next due ${detail.nextDue.whenLabel}` : 'No future occurrence is currently scheduled.'}
            </AppText>
            {detail.activeSnapshot.revision ? (
              <AppText variant="caption">
                Effective from {detail.activeSnapshot.revision.effectiveFrom.slice(0, 10)}
              </AppText>
            ) : null}
          </View>
        </AppCard>

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Linked infrastructure
            </AppText>
            <AppText variant="caption">
              Reminder mode: {detail.reminderPreference.privacyMode.replace('_', ' ')}
            </AppText>
            <AppText variant="caption">
              Saved vials: {detail.vials.length}
            </AppText>
            <AppText variant="caption">
              Saved sites: {detail.sites.length}
            </AppText>
          </View>
        </AppCard>

        {atlasFeatureFlags.protocolChangeStudioV1 ? (
          <AppCard style={styles.card}>
            <View style={styles.section}>
              <AppText style={styles.sectionLabel} variant="caption">
                Protocol Change Studio
              </AppText>
              <AppText variant="caption">
                Preview future-only changes over 7, 14, and 30 days before committing anything.
              </AppText>
              <AppButton
                label="Change future plan"
                onPress={() => {
                  router.push(`/protocols/${protocolId}/change` as never);
                }}
              />
            </View>
          </AppCard>
        ) : null}

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Audit history
            </AppText>
            {detail.audits.length === 0 ? (
              <AppText variant="caption">
                No future plan changes have been committed yet.
              </AppText>
            ) : (
              detail.audits.slice(0, 6).map((audit) => (
                <View key={audit.id} style={styles.auditRow}>
                  <AppText>{audit.summary}</AppText>
                  <AppText variant="caption">{formatAuditDate(audit.createdAt)}</AppText>
                </View>
              ))
            )}
          </View>
        </AppCard>
      </View>
    </AppScreen>
  );
}

function formatAuditDate(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    month: 'short',
    weekday: 'short',
  }).format(new Date(value));
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  card: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  section: {
    gap: atlasTheme.spacing.sm,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  auditRow: {
    borderTopColor: atlasTheme.colors.border,
    borderTopWidth: 1,
    gap: 4,
    paddingTop: atlasTheme.spacing.sm,
  },
});

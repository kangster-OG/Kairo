import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { EmptyStateCard } from '@/src/features/app-shell/components/empty-state-card';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useTodayActionMutation, useTodaySnapshotQuery } from '@/src/features/day-loop/hooks';
import type { GeneratedOccurrence } from '@/src/features/day-loop/service';
import { formatAccountMode } from '@/src/features/onboarding/helpers';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { TodayActionModal } from '@/src/features/today/components/today-action-modal';
import { useTrustVaultQuery } from '@/src/features/trust-vault/hooks';
import {
  formatCompoundDisplayName,
  formatTodayOccurrenceLabel,
  getIsDiscreetModeEnabled,
  indexProtocolAliases,
} from '@/src/features/trust-vault/privacy';
import { atlasTheme } from '@/src/theme/tokens';

export function TodayHomeScreen() {
  const draft = useOnboardingStore((state) => state.draft);
  const todaySnapshotQuery = useTodaySnapshotQuery();
  const todayActionMutation = useTodayActionMutation();
  const trustVaultQuery = useTrustVaultQuery();
  const [activeAction, setActiveAction] = useState<'mark_taken' | 'reschedule' | 'skip' | null>(null);
  const [selectedOccurrence, setSelectedOccurrence] = useState<GeneratedOccurrence | null>(null);
  const discreetModeEnabled = getIsDiscreetModeEnabled(draft.privacy);
  const privacyProfile = trustVaultQuery.data?.profile;
  const aliasLookup = trustVaultQuery.data
    ? indexProtocolAliases(trustVaultQuery.data.aliases)
    : undefined;

  if (todaySnapshotQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is building today’s local schedule from saved protocols, logs, and reminders."
          isLoading
          title="Loading today"
        />
      </AppScreen>
    );
  }

  if (todaySnapshotQuery.isError) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Try again"
          body="Atlas could not read the local day loop. No data was lost, and you can safely retry."
          onAction={() => {
            void todaySnapshotQuery.refetch();
          }}
          title="Today could not load"
        />
      </AppScreen>
    );
  }

  const summary = todaySnapshotQuery.data ?? {
    nextDue: null,
    overdue: [],
    primaryProtocolId: null,
    protocolCount: 0,
    upcoming: [],
  };
  const isPausedState =
    summary.protocolCount > 0 &&
    summary.nextDue === null &&
    summary.overdue.length === 0 &&
    summary.upcoming.length === 0;

  const openAction = (action: 'mark_taken' | 'reschedule' | 'skip', occurrence: GeneratedOccurrence) => {
    setActiveAction(action);
    setSelectedOccurrence(occurrence);
  };

  return (
    <AppScreen scroll>
      <View pointerEvents="none" style={styles.topGlow} />
      <View style={styles.container}>
        <ShellHeader
          description={
            summary.protocolCount > 0
              ? 'Today reflects what is due next, what is paused, and where your next safe action starts.'
              : 'Atlas is ready for the first real protocol. Once you add one, Today becomes your next-due home.'
          }
          eyebrow="Today"
          title={draft.accountMode === 'guest' ? 'Welcome to your private workspace' : 'Welcome back to Atlas'}
          trailing={
            <View style={styles.statusRow}>
              <StatusPill
                label={discreetModeEnabled ? 'Discreet mode active' : 'Standard privacy view'}
                tone={discreetModeEnabled ? 'success' : 'default'}
              />
              <StatusPill label={formatAccountMode(draft.accountMode)} tone="muted" />
            </View>
          }
        />

        {summary.protocolCount === 0 ? (
          <EmptyStateCard
            body="Protocols unlock next due, reminders, logs, inventory signals, and the timeline. Start there, even if you stay in guest mode."
            eyebrow="No protocols yet"
            onPrimaryAction={() => {
              router.push('/protocols/new');
            }}
            onSecondaryAction={() => {
              router.push('/library');
            }}
            primaryActionLabel="Create your first protocol"
            secondaryActionLabel="Open Library"
            title="The daily loop starts with one protocol"
          />
        ) : null}

        {isPausedState ? (
          <EmptyStateCard
            body="Atlas still has a saved protocol, but all future occurrences are paused right now. Resume or edit the future plan when you are ready."
            eyebrow="Future plan paused"
            onPrimaryAction={() => {
              if (!summary.primaryProtocolId) {
                router.push('/library');
                return;
              }

              router.push(`/protocols/${summary.primaryProtocolId}/change` as never);
            }}
            onSecondaryAction={() => {
              router.push('/library');
            }}
            primaryActionLabel="Change future plan"
            secondaryActionLabel="Open Library"
            title="Nothing is due until the plan resumes"
          />
        ) : null}

        {summary.overdue.length > 0 ? (
          <AppCard style={styles.overdueCard}>
            <View style={styles.summaryCopy}>
              <AppText style={styles.overdueLabel} variant="caption">
                Overdue
              </AppText>
              <AppText variant="heading">
                {summary.overdue[0]
                  ? formatTodayOccurrenceLabel(summary.overdue[0], draft.privacy, privacyProfile, aliasLookup)
                  : 'Private protocol'}
              </AppText>
              <AppText variant="caption">{summary.overdue[0]?.whenLabel}</AppText>
              <AppText variant="caption">
                {summary.overdue.length > 1
                  ? `${summary.overdue.length} overdue items need attention.`
                  : 'One overdue item needs attention.'}
              </AppText>
              <View style={styles.quickActionRow}>
                <QuickAction label="Mark taken" onPress={() => summary.overdue[0] && openAction('mark_taken', summary.overdue[0])} />
                <QuickAction label="Skip" onPress={() => summary.overdue[0] && openAction('skip', summary.overdue[0])} />
                <QuickAction label="Reschedule" onPress={() => summary.overdue[0] && openAction('reschedule', summary.overdue[0])} />
              </View>
            </View>
          </AppCard>
        ) : null}

        {summary.nextDue ? (
          <AppCard style={styles.nextDueCard}>
            <View style={styles.summaryCopy}>
              <AppText style={styles.sectionLabel} variant="caption">
                Next due
              </AppText>
              <AppText variant="heading">
                {formatTodayOccurrenceLabel(summary.nextDue, draft.privacy, privacyProfile, aliasLookup)}
              </AppText>
              <AppText variant="caption">{summary.nextDue.whenLabel}</AppText>
              <AppText variant="caption">{summary.nextDue.cadenceLabel}</AppText>
              {summary.nextDue.doseLabel ? (
                <AppText variant="caption">Saved amount: {summary.nextDue.doseLabel}</AppText>
              ) : null}
              <View style={styles.statusRow}>
                <StatusPill label={summary.nextDue.kind === 'custom' ? 'Custom protocol' : `${summary.nextDue.kind.toUpperCase()} protocol`} tone="default" />
                {summary.nextDue.compoundName ? (
                  <StatusPill
                    label={
                      formatCompoundDisplayName(
                        summary.nextDue.compoundName,
                        summary.nextDue.kind,
                        draft.privacy,
                        privacyProfile,
                        aliasLookup?.[summary.nextDue.protocolId],
                      ) ?? 'Private compound'
                    }
                    tone="muted"
                  />
                ) : null}
              </View>
              <View style={styles.quickActionRow}>
                <QuickAction label="Mark taken" onPress={() => openAction('mark_taken', summary.nextDue!)} />
                <QuickAction label="Skip" onPress={() => openAction('skip', summary.nextDue!)} />
                <QuickAction label="Reschedule" onPress={() => openAction('reschedule', summary.nextDue!)} />
              </View>
              <AppButton
                label="Change future plan"
                onPress={() => {
                  router.push(`/protocols/${summary.nextDue!.protocolId}/change` as never);
                }}
                variant="ghost"
              />
            </View>
          </AppCard>
        ) : null}

        {summary.upcoming.length > 0 ? (
          <AppCard style={styles.summaryCard}>
            <View style={styles.summaryCopy}>
              <AppText style={styles.sectionLabel} variant="caption">
                Upcoming
              </AppText>
              {summary.upcoming.map((occurrence) => (
                <View key={occurrence.id} style={styles.upcomingRow}>
                  <View style={styles.upcomingCopy}>
                    <AppText>
                      {formatTodayOccurrenceLabel(occurrence, draft.privacy, privacyProfile, aliasLookup)}
                    </AppText>
                    <AppText variant="caption">{occurrence.whenLabel}</AppText>
                  </View>
                  <StatusPill label={occurrence.timeLabel} tone="muted" />
                </View>
              ))}
            </View>
          </AppCard>
        ) : null}

        <AppCard style={styles.summaryCard}>
          <View style={styles.summaryCopy}>
            <AppText style={styles.sectionLabel} variant="caption">
              {summary.protocolCount > 0 ? 'What unlocks next' : 'What arrives next'}
            </AppText>
            {[
              summary.protocolCount > 0 && !isPausedState
                ? 'Timeline grows from real logs, not placeholders.'
                : isPausedState
                  ? 'Timeline keeps your history intact while the future plan is paused.'
                  : 'Next due appears here once a protocol exists.',
              'Library now stores the local source of truth for each routine.',
              'Insights stay descriptive and privacy-aware.',
            ].map((item) => (
              <View key={item} style={styles.summaryRow}>
                <View style={styles.summaryDot} />
                <AppText variant="caption">{item}</AppText>
              </View>
            ))}
          </View>
        </AppCard>
      </View>

      <TodayActionModal
        action={activeAction ?? 'mark_taken'}
        isPending={todayActionMutation.isPending}
        occurrence={selectedOccurrence}
        onClose={() => {
          setActiveAction(null);
          setSelectedOccurrence(null);
        }}
        onConfirm={({ nextScheduledFor, notes, siteId }) => {
          if (!activeAction || !selectedOccurrence) {
            return;
          }

          void todayActionMutation.mutateAsync({
            action: activeAction,
            nextScheduledFor,
            notes,
            occurrenceId: selectedOccurrence.id,
            protocolId: selectedOccurrence.protocolId,
            scheduledFor: selectedOccurrence.scheduledFor,
            siteId,
          }).then(() => {
            setActiveAction(null);
            setSelectedOccurrence(null);
          });
        }}
        visible={activeAction !== null && selectedOccurrence !== null}
      />
    </AppScreen>
  );
}

function QuickAction({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable
      accessibilityHint={`Use ${label.toLowerCase()} for the currently selected due item.`}
      accessibilityLabel={label}
      accessibilityRole="button"
      hitSlop={6}
      onPress={onPress}
      style={styles.quickActionPill}>
      <AppText style={styles.quickActionLabel} variant="caption">
        {label}
      </AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  loadingState: {
    alignItems: 'center',
    flex: 1,
    gap: atlasTheme.spacing.sm,
    justifyContent: 'center',
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  topGlow: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: 999,
    height: 220,
    opacity: 0.9,
    position: 'absolute',
    right: -70,
    top: -24,
    width: 220,
  },
  summaryCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  nextDueCard: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
  },
  overdueCard: {
    backgroundColor: '#FFF4E8',
    borderColor: '#F0C58A',
  },
  summaryCopy: {
    gap: atlasTheme.spacing.sm,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  overdueLabel: {
    color: '#C26B16',
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  summaryRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
  },
  summaryDot: {
    backgroundColor: atlasTheme.colors.primary,
    borderRadius: 999,
    height: 8,
    width: 8,
  },
  quickActionRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  quickActionPill: {
    backgroundColor: '#FFFFFF',
    borderColor: atlasTheme.colors.border,
    borderRadius: atlasTheme.radii.pill,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  quickActionLabel: {
    color: atlasTheme.colors.textPrimary,
    fontWeight: '700',
  },
  upcomingRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  upcomingCopy: {
    flex: 1,
    gap: 2,
  },
});

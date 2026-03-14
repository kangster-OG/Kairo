import { router } from 'expo-router';
import { useDeferredValue, useState, startTransition } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { EmptyStateCard } from '@/src/features/app-shell/components/empty-state-card';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { useTimelineFeedQuery } from '@/src/features/day-loop/hooks';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { useProtocolListQuery } from '@/src/features/protocols/hooks';
import { useTrustVaultQuery } from '@/src/features/trust-vault/hooks';
import {
  formatProtocolDisplayName,
  formatTimelineItemSummary,
  indexProtocolAliases,
} from '@/src/features/trust-vault/privacy';
import { atlasTheme } from '@/src/theme/tokens';

export function TimelineEmptyScreen() {
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const [protocolFilter, setProtocolFilter] = useState<string | 'all'>('all');
  const [dateWindow, setDateWindow] = useState<'all' | 'last_30_days' | 'last_7_days'>('all');
  const deferredProtocolFilter = useDeferredValue(protocolFilter);
  const deferredDateWindow = useDeferredValue(dateWindow);
  const protocolListQuery = useProtocolListQuery();
  const trustVaultQuery = useTrustVaultQuery();
  const timelineQuery = useTimelineFeedQuery({
    dateWindow: deferredDateWindow,
    protocolId: deferredProtocolFilter,
  });
  const isUpdatingFilters =
    deferredDateWindow !== dateWindow || deferredProtocolFilter !== protocolFilter;
  const privacyProfile = trustVaultQuery.data?.profile;
  const aliasLookup = trustVaultQuery.data
    ? indexProtocolAliases(trustVaultQuery.data.aliases)
    : undefined;

  if (timelineQuery.isLoading || protocolListQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is assembling your local event history and current filters."
          isLoading
          title="Loading timeline"
        />
      </AppScreen>
    );
  }

  if (timelineQuery.isError || protocolListQuery.isError) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Try again"
          body="Atlas could not build the local event feed. Your local records are still intact."
          onAction={() => {
            void Promise.all([timelineQuery.refetch(), protocolListQuery.refetch()]);
          }}
          title="Timeline could not load"
        />
      </AppScreen>
    );
  }

  const protocols = protocolListQuery.data ?? [];
  const items = timelineQuery.data ?? [];

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Timeline becomes the factual record of what was due, what was logged, and how your routine actually unfolded."
          eyebrow="Timeline"
          title={items.length > 0 ? 'Actual history, not guesses' : 'History starts after the first real action'}
        />

        <AppCard style={styles.card}>
          <View style={styles.copy}>
            <AppText style={styles.sectionLabel} variant="caption">
              Filters
            </AppText>
            {isUpdatingFilters ? (
              <AppText variant="caption">Refreshing the filtered timeline.</AppText>
            ) : null}
            <View style={styles.filterSection}>
              <View style={styles.filterStack}>
                <ProtocolChoicePill
                  isSelected={protocolFilter === 'all'}
                  label="All protocols"
                  onPress={() => {
                    startTransition(() => {
                      setProtocolFilter('all');
                    });
                  }}
                />
                {protocols.map((protocol) => (
                  <ProtocolChoicePill
                    key={protocol.id}
                    isSelected={protocolFilter === protocol.id}
                    label={formatProtocolDisplayName(
                      protocol.title,
                      protocol.kind,
                      privacy,
                      privacyProfile,
                      aliasLookup?.[protocol.id],
                    )}
                    onPress={() => {
                      startTransition(() => {
                        setProtocolFilter(protocol.id);
                      });
                    }}
                  />
                ))}
              </View>
              <View style={styles.filterStack}>
                <ProtocolChoicePill
                  isSelected={dateWindow === 'all'}
                  label="All time"
                  onPress={() => {
                    startTransition(() => {
                      setDateWindow('all');
                    });
                  }}
                />
                <ProtocolChoicePill
                  isSelected={dateWindow === 'last_7_days'}
                  label="Last 7 days"
                  onPress={() => {
                    startTransition(() => {
                      setDateWindow('last_7_days');
                    });
                  }}
                />
                <ProtocolChoicePill
                  isSelected={dateWindow === 'last_30_days'}
                  label="Last 30 days"
                  onPress={() => {
                    startTransition(() => {
                      setDateWindow('last_30_days');
                    });
                  }}
                />
              </View>
            </View>
          </View>
        </AppCard>

        {items.length === 0 ? (
          <EmptyStateCard
            body={
              protocols.length === 0
                ? 'Once you create a protocol and log against it, this screen turns into a calm, chronological view instead of a dashboard dump.'
                : 'No events match the current filters yet. Try a different protocol or date range.'
            }
            eyebrow="Nothing to show yet"
              onPrimaryAction={() => {
                if (protocols.length === 0) {
                  router.push('/protocols/new');
                  return;
                }

                startTransition(() => {
                  setProtocolFilter('all');
                  setDateWindow('all');
                });
              }}
              primaryActionLabel={protocols.length === 0 ? 'Create your first protocol' : 'Reset filters'}
              title="No timeline events yet"
          />
        ) : (
          <View style={styles.feed}>
            {items.map((item) => (
              <AppCard key={item.eventId} style={styles.feedCard}>
                <View style={styles.feedHeader}>
                    <View style={styles.feedCopy}>
                    <AppText variant="heading">
                      {formatTimelineItemSummary(item, privacy, privacyProfile, aliasLookup)}
                    </AppText>
                    <AppText variant="caption">
                      {formatProtocolDisplayName(
                        item.protocolName,
                        protocols.find((protocol) => protocol.id === item.protocolId)?.kind ?? 'custom',
                        privacy,
                        privacyProfile,
                        aliasLookup?.[item.protocolId],
                      )}
                    </AppText>
                  </View>
                  <StatusPill label={formatEventType(item.eventType)} tone="muted" />
                </View>
                <AppText variant="caption">{formatFeedTimestamp(item.timestamp)}</AppText>
                <AppButton
                  label="Adjust future plan"
                  onPress={() => {
                    router.push(`/protocols/${item.protocolId}/change` as never);
                  }}
                  variant="ghost"
                />
              </AppCard>
            ))}
          </View>
        )}
      </View>
    </AppScreen>
  );
}

function formatEventType(
  value:
    | 'logged_dose'
    | 'protocol_changed'
    | 'protocol_created'
    | 'rescheduled_dose'
    | 'skipped_dose'
) {
  switch (value) {
    case 'logged_dose':
      return 'Taken';
    case 'skipped_dose':
      return 'Skipped';
    case 'rescheduled_dose':
      return 'Rescheduled';
    case 'protocol_changed':
      return 'Changed';
    default:
      return 'Created';
  }
}

function formatFeedTimestamp(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
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
  copy: {
    gap: atlasTheme.spacing.sm,
  },
  filterSection: {
    gap: atlasTheme.spacing.md,
  },
  filterStack: {
    gap: atlasTheme.spacing.sm,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  feed: {
    gap: atlasTheme.spacing.md,
  },
  feedCard: {
    gap: atlasTheme.spacing.sm,
  },
  feedHeader: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  feedCopy: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
  },
});

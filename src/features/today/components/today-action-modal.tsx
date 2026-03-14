import { useEffect, useMemo, useState } from 'react';
import { Modal, Pressable, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppText } from '@/src/components/ui/app-text';
import { useProtocolSiteOptionsQuery } from '@/src/features/inventory/hooks';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import type { GeneratedOccurrence } from '@/src/features/day-loop/service';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { formatTodayOccurrenceLabel } from '@/src/features/reminders/privacy';
import { atlasTheme } from '@/src/theme/tokens';

type TodayActionModalProps = {
  action: 'mark_taken' | 'reschedule' | 'skip';
  isPending: boolean;
  occurrence: GeneratedOccurrence | null;
  onClose: () => void;
  onConfirm: (payload: {
    nextScheduledFor?: string;
    notes?: string | null;
    siteId?: string | null;
  }) => void;
  visible: boolean;
};

export function TodayActionModal({
  action,
  isPending,
  occurrence,
  onClose,
  onConfirm,
  visible,
}: TodayActionModalProps) {
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const [notes, setNotes] = useState('');
  const rescheduleOptions = useMemo(
    () => (occurrence ? buildRescheduleOptions(occurrence.scheduledFor) : []),
    [occurrence]
  );
  const siteOptionsQuery = useProtocolSiteOptionsQuery(
    visible && occurrence ? occurrence.protocolId : null
  );
  const [selectedSchedule, setSelectedSchedule] = useState<string | null>(rescheduleOptions[0]?.value ?? null);
  const [selectedSiteId, setSelectedSiteId] = useState<string | null>(null);

  useEffect(() => {
    setNotes('');
    setSelectedSchedule(rescheduleOptions[0]?.value ?? null);
  }, [rescheduleOptions, visible]);

  useEffect(() => {
    setSelectedSiteId(siteOptionsQuery.data?.suggestedSiteId ?? null);
  }, [siteOptionsQuery.data?.suggestedSiteId, visible]);

  if (!occurrence) {
    return null;
  }

  const shouldShowSiteSelection =
    action === 'mark_taken' &&
    siteOptionsQuery.data?.protocol.siteTrackingEnabled &&
    (siteOptionsQuery.data?.sites.length ?? 0) > 0;

  return (
    <Modal animationType="fade" onRequestClose={onClose} transparent visible={visible}>
      <View style={styles.backdrop}>
        <Pressable
          accessibilityHint="Dismiss the current action sheet."
          accessibilityLabel="Close dose action modal"
          accessibilityRole="button"
          style={StyleSheet.absoluteFill}
          onPress={onClose}
        />
        <AppCard style={styles.card}>
          <View style={styles.header}>
            <AppText variant="heading">{getModalTitle(action)}</AppText>
            <AppText variant="caption">{formatTodayOccurrenceLabel(occurrence, privacy)}</AppText>
            <AppText variant="caption">{occurrence.whenLabel}</AppText>
          </View>

          {action === 'reschedule' ? (
            <View style={styles.section}>
              <AppText style={styles.label} variant="caption">
                Pick a new time
              </AppText>
              <View style={styles.optionStack}>
                {rescheduleOptions.map((option) => (
                  <ProtocolChoicePill
                    key={option.value}
                    description={option.description}
                    isSelected={selectedSchedule === option.value}
                    label={option.label}
                    onPress={() => {
                      setSelectedSchedule(option.value);
                    }}
                  />
                ))}
              </View>
            </View>
          ) : null}

          {shouldShowSiteSelection ? (
            <View style={styles.section}>
              <AppText style={styles.label} variant="caption">
                Injection site
              </AppText>
              <View style={styles.optionStack}>
                {siteOptionsQuery.data?.sites.map((site) => (
                  <ProtocolChoicePill
                    key={site.id}
                    description={site.bodyArea ?? undefined}
                    isSelected={selectedSiteId === site.id}
                    label={site.name}
                    onPress={() => {
                      setSelectedSiteId(site.id);
                    }}
                  />
                ))}
              </View>
              {siteOptionsQuery.data?.protocol.siteRotationEnabled && selectedSiteId ? (
                <AppText variant="caption">Atlas is suggesting the next site in your saved rotation.</AppText>
              ) : null}
            </View>
          ) : null}

          <AppInput
            label="Optional note"
            multiline
            numberOfLines={3}
            onChangeText={setNotes}
            placeholder={
              action === 'mark_taken'
                ? 'Add anything useful for your own record.'
                : action === 'skip'
                  ? 'Add context for the skipped dose if you want.'
                  : 'Optional note about the schedule change.'
            }
            style={styles.notesInput}
            textAlignVertical="top"
            value={notes}
          />

          <View style={styles.actions}>
            <AppButton
              label={getModalActionLabel(action)}
              onPress={() => {
                onConfirm({
                  nextScheduledFor: action === 'reschedule' ? selectedSchedule ?? undefined : undefined,
                  notes: notes.trim().length > 0 ? notes.trim() : null,
                  siteId: action === 'mark_taken' ? selectedSiteId : undefined,
                });
              }}
            />
            <AppButton label="Cancel" onPress={onClose} variant="ghost" />
            {isPending ? (
              <AppText style={styles.pendingText} variant="caption">
                Saving locally.
              </AppText>
            ) : null}
          </View>
        </AppCard>
      </View>
    </Modal>
  );
}

function getModalTitle(action: TodayActionModalProps['action']) {
  switch (action) {
    case 'mark_taken':
      return 'Log this dose';
    case 'skip':
      return 'Skip this dose';
    default:
      return 'Reschedule this dose';
  }
}

function getModalActionLabel(action: TodayActionModalProps['action']) {
  switch (action) {
    case 'mark_taken':
      return 'Save as taken';
    case 'skip':
      return 'Save skip';
    default:
      return 'Save reschedule';
  }
}

function buildRescheduleOptions(scheduledFor: string) {
  const base = new Date(scheduledFor);
  const sameTimeTomorrow = new Date(base);
  sameTimeTomorrow.setDate(sameTimeTomorrow.getDate() + 1);

  const plusTwoHours = new Date(base);
  plusTwoHours.setHours(plusTwoHours.getHours() + 2);

  const plusTwoDays = new Date(base);
  plusTwoDays.setDate(plusTwoDays.getDate() + 2);

  return [
    {
      description: formatFullDate(plusTwoHours),
      label: 'Later today',
      value: plusTwoHours.toISOString(),
    },
    {
      description: formatFullDate(sameTimeTomorrow),
      label: 'Tomorrow',
      value: sameTimeTomorrow.toISOString(),
    },
    {
      description: formatFullDate(plusTwoDays),
      label: 'In 2 days',
      value: plusTwoDays.toISOString(),
    },
  ];
}

function formatFullDate(value: Date) {
  return new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    month: 'short',
    weekday: 'short',
  }).format(value);
}

const styles = StyleSheet.create({
  backdrop: {
    alignItems: 'center',
    backgroundColor: 'rgba(17, 24, 39, 0.38)',
    flex: 1,
    justifyContent: 'center',
    padding: atlasTheme.spacing.lg,
  },
  card: {
    gap: atlasTheme.spacing.lg,
    width: '100%',
  },
  header: {
    gap: atlasTheme.spacing.xs,
  },
  section: {
    gap: atlasTheme.spacing.sm,
  },
  label: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  optionStack: {
    gap: atlasTheme.spacing.sm,
  },
  notesInput: {
    minHeight: 100,
  },
  actions: {
    gap: atlasTheme.spacing.sm,
  },
  pendingText: {
    textAlign: 'center',
  },
});

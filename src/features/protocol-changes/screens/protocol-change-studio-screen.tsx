import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import {
  useCommitProtocolChangeMutation,
  useProtocolChangeDetailQuery,
  useProtocolChangePreviewQuery,
} from '@/src/features/protocol-changes/hooks';
import type { ProtocolChangeDraft, ProtocolChangeType } from '@/src/features/protocol-changes/schema';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { formatProtocolDisplayName } from '@/src/features/reminders/privacy';
import { atlasTheme } from '@/src/theme/tokens';

const changeTypeOptions: { description: string; label: string; value: ProtocolChangeType }[] = [
  { value: 'future_dose', label: 'Future dose', description: 'Change the saved amount from an effective date forward.' },
  { value: 'future_time', label: 'Time of day', description: 'Move future scheduled time without touching history.' },
  { value: 'day_of_week', label: 'Weekday', description: 'Switch to a different weekly day.' },
  { value: 'every_n_days', label: 'Every N days', description: 'Use a fixed interval cadence instead of a weekday.' },
  { value: 'pause', label: 'Pause', description: 'Stop future occurrences until a later resume revision.' },
  { value: 'resume', label: 'Resume', description: 'Restart future occurrences from a chosen date.' },
  { value: 'titration', label: 'Titration', description: 'Stage a future phase before returning to the base plan.' },
  { value: 'rest_period', label: 'Rest period', description: 'Insert a bounded no-dose future window.' },
  { value: 'missed_dose_policy', label: 'Recovery policy', description: 'Change how future missed-dose semantics are interpreted.' },
  { value: 'timezone', label: 'Timezone / travel', description: 'Adjust future timezone behavior without duplicating history.' },
  { value: 'vial_switch', label: 'Vial handoff', description: 'Plan when future logs should switch to another vial.' },
];

const weekdayOptions = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export function ProtocolChangeStudioScreen({ protocolId }: { protocolId: string }) {
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const commitMutation = useCommitProtocolChangeMutation();
  const [previewReferenceNow, setPreviewReferenceNow] = useState(() => new Date().toISOString());
  const [draft, setDraft] = useState<ProtocolChangeDraft>({
    changeType: 'future_dose',
    doseAmount: '',
    doseUnit: 'mg',
    effectiveDate: getTodayDateString(),
    intervalDays: '2',
    linkedVialId: null,
    missedDosePolicy: 'skip_and_continue',
    notes: '',
    previewWindowDays: 14,
    restLengthDays: '7',
    timeOfDay: '08:00',
    titrationDoseAmount: '',
    titrationDoseUnit: 'mg',
    titrationLengthDays: '14',
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
    timezoneStrategy: 'keep_local_clock',
    weekday: 1,
  });

  const updateDraft = (patch: Partial<ProtocolChangeDraft>) => {
    setPreviewReferenceNow(new Date().toISOString());
    setDraft((current) => ({
      ...current,
      ...patch,
    }));
  };
  const canPreview = hasEnoughFieldsForPreview(draft);
  const detailQueryWithReference = useProtocolChangeDetailQuery(protocolId, {
    referenceNow: previewReferenceNow,
  });
  const previewQuery = useProtocolChangePreviewQuery(canPreview ? protocolId : null, draft, {
    privacy,
    referenceNow: previewReferenceNow,
  });

  if (detailQueryWithReference.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is preparing the current future plan so you can preview changes before commit."
          isLoading
          title="Loading Protocol Change Studio"
        />
      </AppScreen>
    );
  }

  if (detailQueryWithReference.isError || !detailQueryWithReference.data) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Back"
          body="Atlas could not load the local protocol state needed for a safe future edit."
          onAction={() => {
            router.back();
          }}
          title="Protocol Change Studio could not load"
        />
      </AppScreen>
    );
  }

  const detail = detailQueryWithReference.data;
  const preview = previewQuery.data ?? null;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <Pressable onPress={() => router.back()}>
          <AppText style={styles.backLink} variant="caption">
            Back to protocol
          </AppText>
        </Pressable>

        <ShellHeader
          description="Preview the downstream impact before committing anything. Atlas keeps past logs immutable."
          eyebrow="Protocol Change Studio"
          title={formatProtocolDisplayName(
            detail.bundle.protocol.name,
            detail.bundle.protocol.kind,
            privacy
          )}
          trailing={
            <StatusPill
              label={`${draft.previewWindowDays}-day preview`}
              tone="default"
            />
          }
        />

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Change type
            </AppText>
            <View style={styles.optionStack}>
              {changeTypeOptions.map((option) => (
                <ProtocolChoicePill
                  key={option.value}
                  description={option.description}
                  isSelected={draft.changeType === option.value}
                  label={option.label}
                  onPress={() => {
                    updateDraft({ changeType: option.value });
                  }}
                />
              ))}
            </View>
          </View>
        </AppCard>

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Effective date
            </AppText>
            <AppInput
              label="Apply this future change from"
              onChangeText={(value) => {
                updateDraft({ effectiveDate: value });
              }}
              placeholder="YYYY-MM-DD"
              value={draft.effectiveDate}
            />
          </View>
        </AppCard>

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Change values
            </AppText>
            <ChangeInputs
              draft={draft}
              onChange={updateDraft}
              vialOptions={detail.vials}
            />
          </View>
        </AppCard>

        <AppCard style={styles.card}>
          <View style={styles.section}>
            <AppText style={styles.sectionLabel} variant="caption">
              Preview window
            </AppText>
            <View style={styles.inlineOptions}>
              {[7, 14, 30].map((days) => (
                <ProtocolChoicePill
                  key={days}
                  isSelected={draft.previewWindowDays === days}
                  label={`${days} days`}
                  onPress={() => {
                    updateDraft({ previewWindowDays: days as 7 | 14 | 30 });
                  }}
                />
              ))}
            </View>
          </View>
        </AppCard>

        {!canPreview ? (
          <FeedbackStateCard
            body="Finish the required fields for this change type and Atlas will generate a calm preview before commit."
            title="Preview is waiting for the required fields"
          />
        ) : previewQuery.isLoading ? (
          <FeedbackStateCard
            body="Atlas is comparing the committed future plan against your draft change."
            isLoading
            title="Building preview"
          />
        ) : previewQuery.isError || !preview ? (
          <FeedbackStateCard
            actionLabel="Retry preview"
            body="Atlas could not build a safe preview for this draft yet."
            onAction={() => {
              void previewQuery.refetch();
            }}
            title="Preview could not load"
          />
        ) : (
          <>
            <AppCard style={styles.previewCard}>
              <View style={styles.section}>
                <AppText style={styles.sectionLabel} variant="caption">
                  What changes
                </AppText>
                <AppText variant="heading">{preview.summary}</AppText>
                {preview.adherenceNote ? (
                  <AppText variant="caption">{preview.adherenceNote}</AppText>
                ) : null}
              </View>
            </AppCard>

            <AppCard style={styles.card}>
              <View style={styles.section}>
                <AppText style={styles.sectionLabel} variant="caption">
                  Next due
                </AppText>
                <AppText variant="caption">
                  Before: {preview.nextDueBefore ? preview.nextDueBefore.whenLabel : 'No future occurrence'}
                </AppText>
                <AppText variant="caption">
                  After: {preview.nextDueAfter ? preview.nextDueAfter.whenLabel : 'No future occurrence'}
                </AppText>
              </View>
            </AppCard>

            <AppCard style={styles.card}>
              <View style={styles.section}>
                <AppText style={styles.sectionLabel} variant="caption">
                  Upcoming reminders
                </AppText>
                <AppText variant="caption">
                  Before: {preview.currentReminderLabel ?? 'No upcoming reminder'}
                </AppText>
                <AppText variant="caption">
                  After: {preview.draftReminderLabel ?? 'No upcoming reminder'}
                </AppText>
              </View>
            </AppCard>

            <AppCard style={styles.card}>
              <View style={styles.section}>
                <AppText style={styles.sectionLabel} variant="caption">
                  Inventory forecast
                </AppText>
                <AppText variant="caption">
                  Before: {preview.inventoryForecastBefore ?? 'No depletion forecast yet'}
                </AppText>
                <AppText variant="caption">
                  After: {preview.inventoryForecastAfter ?? 'No depletion forecast yet'}
                </AppText>
              </View>
            </AppCard>

            <AppCard style={styles.card}>
              <View style={styles.section}>
                <AppText style={styles.sectionLabel} variant="caption">
                  Occurrence changes
                </AppText>
                {preview.occurrenceChanges.length === 0 ? (
                  <AppText variant="caption">No visible future occurrence changes inside this preview window.</AppText>
                ) : (
                  preview.occurrenceChanges.map((change, index) => (
                    <View key={`${change.kind}-${index}`} style={styles.changeRow}>
                      <StatusPill label={change.kind} tone="muted" />
                      <View style={styles.changeCopy}>
                        {change.beforeLabel ? <AppText variant="caption">Before: {change.beforeLabel}</AppText> : null}
                        {change.afterLabel ? <AppText variant="caption">After: {change.afterLabel}</AppText> : null}
                      </View>
                    </View>
                  ))
                )}
              </View>
            </AppCard>

            {preview.siteWarnings.length > 0 ? (
              <AppCard style={styles.warningCard}>
                <View style={styles.section}>
                  <AppText style={styles.warningLabel} variant="caption">
                    Site rotation warnings
                  </AppText>
                  {preview.siteWarnings.map((warning) => (
                    <AppText key={warning} variant="caption">
                      {warning}
                    </AppText>
                  ))}
                </View>
              </AppCard>
            ) : null}
          </>
        )}

        <View style={styles.actionRow}>
          <AppButton
            disabled={!canPreview || previewQuery.isLoading || Boolean(previewQuery.isError)}
            label="Commit future change"
            onPress={() => {
              void commitMutation
                .mutateAsync({ draft, protocolId, referenceNow: previewReferenceNow })
                .then(() => {
                  router.replace(`/protocols/${protocolId}` as never);
                });
            }}
          />
          <AppButton
            label="Cancel"
            onPress={() => {
              router.back();
            }}
            variant="ghost"
          />
        </View>
      </View>
    </AppScreen>
  );
}

function ChangeInputs({
  draft,
  onChange,
  vialOptions,
}: {
  draft: ProtocolChangeDraft;
  onChange: (patch: Partial<ProtocolChangeDraft>) => void;
  vialOptions: { id: string; label: string }[];
}) {
  switch (draft.changeType) {
    case 'future_dose':
      return (
        <View style={styles.optionStack}>
          <AppInput label="Future saved amount" onChangeText={(value) => onChange({ doseAmount: value })} value={draft.doseAmount} />
          <AppInput label="Dose unit" onChangeText={(value) => onChange({ doseUnit: value })} value={draft.doseUnit} />
        </View>
      );
    case 'future_time':
      return (
        <AppInput label="Future time of day" onChangeText={(value) => onChange({ timeOfDay: value })} value={draft.timeOfDay} />
      );
    case 'day_of_week':
      return (
        <View style={styles.optionStack}>
          <View style={styles.inlineOptions}>
            {weekdayOptions.map((label, index) => (
              <ProtocolChoicePill
                key={label}
                isSelected={draft.weekday === index}
                label={label}
                onPress={() => onChange({ weekday: index })}
              />
            ))}
          </View>
          <AppInput label="Time of day" onChangeText={(value) => onChange({ timeOfDay: value })} value={draft.timeOfDay} />
        </View>
      );
    case 'every_n_days':
      return (
        <View style={styles.optionStack}>
          <AppInput label="Repeat every N days" onChangeText={(value) => onChange({ intervalDays: value })} value={draft.intervalDays} />
          <AppInput label="Time of day" onChangeText={(value) => onChange({ timeOfDay: value })} value={draft.timeOfDay} />
        </View>
      );
    case 'pause':
    case 'resume':
      return <AppText variant="caption">No extra values are needed for this future change.</AppText>;
    case 'titration':
      return (
        <View style={styles.optionStack}>
          <AppInput label="Titration amount" onChangeText={(value) => onChange({ titrationDoseAmount: value })} value={draft.titrationDoseAmount} />
          <AppInput label="Titration unit" onChangeText={(value) => onChange({ titrationDoseUnit: value })} value={draft.titrationDoseUnit} />
          <AppInput label="Titration length in days" onChangeText={(value) => onChange({ titrationLengthDays: value })} value={draft.titrationLengthDays} />
          <AppInput label="Time of day" onChangeText={(value) => onChange({ timeOfDay: value })} value={draft.timeOfDay} />
        </View>
      );
    case 'rest_period':
      return (
        <AppInput label="Rest length in days" onChangeText={(value) => onChange({ restLengthDays: value })} value={draft.restLengthDays} />
      );
    case 'missed_dose_policy':
      return (
        <View style={styles.optionStack}>
          {[
            { label: 'Skip and continue', value: 'skip_and_continue' },
            { label: 'Take now, keep cadence', value: 'take_now_keep_cadence' },
            { label: 'Take now, shift future', value: 'take_now_shift_future' },
          ].map((option) => (
            <ProtocolChoicePill
              key={option.value}
              isSelected={draft.missedDosePolicy === option.value}
              label={option.label}
              onPress={() => onChange({ missedDosePolicy: option.value as ProtocolChangeDraft['missedDosePolicy'] })}
            />
          ))}
        </View>
      );
    case 'timezone':
      return (
        <View style={styles.optionStack}>
          <AppInput label="Timezone" onChangeText={(value) => onChange({ timezone: value })} value={draft.timezone} />
          <ProtocolChoicePill
            isSelected={draft.timezoneStrategy === 'keep_local_clock'}
            label="Keep local clock"
            onPress={() => onChange({ timezoneStrategy: 'keep_local_clock' })}
          />
          <ProtocolChoicePill
            isSelected={draft.timezoneStrategy === 'keep_home_timezone'}
            label="Keep home timezone"
            onPress={() => onChange({ timezoneStrategy: 'keep_home_timezone' })}
          />
        </View>
      );
    case 'vial_switch':
      return (
        <View style={styles.optionStack}>
          {vialOptions.map((vial) => (
            <ProtocolChoicePill
              key={vial.id}
              isSelected={draft.linkedVialId === vial.id}
              label={vial.label}
              onPress={() => onChange({ linkedVialId: vial.id })}
            />
          ))}
        </View>
      );
    default:
      return null;
  }
}

function hasEnoughFieldsForPreview(draft: ProtocolChangeDraft) {
  switch (draft.changeType) {
    case 'future_dose':
      return (draft.doseAmount ?? '').trim().length > 0 && (draft.doseUnit ?? '').trim().length > 0;
    case 'future_time':
      return (draft.timeOfDay ?? '').trim().length > 0;
    case 'day_of_week':
      return draft.weekday !== null && (draft.timeOfDay ?? '').trim().length > 0;
    case 'every_n_days':
      return (draft.intervalDays ?? '').trim().length > 0 && (draft.timeOfDay ?? '').trim().length > 0;
    case 'titration':
      return (
        (draft.titrationDoseAmount ?? '').trim().length > 0 &&
        (draft.titrationDoseUnit ?? '').trim().length > 0 &&
        (draft.titrationLengthDays ?? '').trim().length > 0
      );
    case 'rest_period':
      return (draft.restLengthDays ?? '').trim().length > 0;
    case 'timezone':
      return (draft.timezone ?? '').trim().length > 0;
    case 'vial_switch':
      return Boolean(draft.linkedVialId);
    default:
      return true;
  }
}

function getTodayDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = `${now.getMonth() + 1}`.padStart(2, '0');
  const day = `${now.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  backLink: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
  },
  card: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  previewCard: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
  },
  warningCard: {
    backgroundColor: '#FFF4E8',
    borderColor: '#F0C58A',
  },
  section: {
    gap: atlasTheme.spacing.sm,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  warningLabel: {
    color: '#C26B16',
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  optionStack: {
    gap: atlasTheme.spacing.sm,
  },
  inlineOptions: {
    gap: atlasTheme.spacing.sm,
  },
  changeRow: {
    gap: atlasTheme.spacing.sm,
  },
  changeCopy: {
    gap: 2,
  },
  actionRow: {
    gap: atlasTheme.spacing.sm,
    paddingBottom: atlasTheme.spacing.lg,
  },
});

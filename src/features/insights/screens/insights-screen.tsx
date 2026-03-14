import { useState } from 'react';

import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { EmptyStateCard } from '@/src/features/app-shell/components/empty-state-card';
import { FeedbackStateCard } from '@/src/features/app-shell/components/feedback-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import { InsightSectionCard } from '@/src/features/insights/components/insight-section-card';
import { MiniBarSeries } from '@/src/features/insights/components/mini-bar-series';
import {
  useInsightsSnapshotQuery,
  useSaveCustomMetricEntryMutation,
  useSaveSymptomEntryMutation,
  useSaveWeightEntryMutation,
} from '@/src/features/insights/hooks';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { useProtocolListQuery } from '@/src/features/protocols/hooks';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { useTrustVaultQuery } from '@/src/features/trust-vault/hooks';
import {
  formatProtocolDisplayName,
  formatVialDisplayName,
  indexProtocolAliases,
} from '@/src/features/trust-vault/privacy';
import { atlasTheme } from '@/src/theme/tokens';

const weightUnits = ['lb', 'kg'] as const;
const symptomOptions = ['nausea', 'energy', 'appetite', 'sleep', 'mood'] as const;
const severityOptions = [1, 2, 3, 4, 5] as const;
const metricValueTypes = ['number', 'text', 'boolean'] as const;

export function InsightsScreen() {
  const insightsQuery = useInsightsSnapshotQuery();
  const protocolListQuery = useProtocolListQuery();
  const privacy = useOnboardingStore((state) => state.draft.privacy);
  const trustVaultQuery = useTrustVaultQuery();
  const saveWeightMutation = useSaveWeightEntryMutation();
  const saveSymptomMutation = useSaveSymptomEntryMutation();
  const saveCustomMetricMutation = useSaveCustomMetricEntryMutation();

  const [weightValue, setWeightValue] = useState('');
  const [weightUnit, setWeightUnit] = useState<(typeof weightUnits)[number]>('lb');
  const [weightNotes, setWeightNotes] = useState('');

  const [symptomKey, setSymptomKey] = useState<string>('nausea');
  const [symptomSeverity, setSymptomSeverity] = useState<(typeof severityOptions)[number]>(2);
  const [symptomNotes, setSymptomNotes] = useState('');

  const [selectedMetricId, setSelectedMetricId] = useState<string | null>(null);
  const [metricLabel, setMetricLabel] = useState('');
  const [metricValueType, setMetricValueType] = useState<(typeof metricValueTypes)[number]>('number');
  const [metricUnit, setMetricUnit] = useState('');
  const [metricNumberValue, setMetricNumberValue] = useState('');
  const [metricTextValue, setMetricTextValue] = useState('');
  const [metricBooleanValue, setMetricBooleanValue] = useState<boolean | null>(true);
  const [metricProtocolId, setMetricProtocolId] = useState<string | null>(null);

  if (insightsQuery.isLoading) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          body="Atlas is building descriptive trends from your local logs, inventory, and schedule data."
          isLoading
          title="Loading insights"
        />
      </AppScreen>
    );
  }

  if (insightsQuery.isError) {
    return (
      <AppScreen scroll>
        <FeedbackStateCard
          actionLabel="Try again"
          body="The rest of Atlas is still safe locally. This screen only needs a retry."
          onAction={() => {
            void insightsQuery.refetch();
          }}
          title="Insights could not load"
        />
      </AppScreen>
    );
  }

  const snapshot = insightsQuery.data!;
  const privacyProfile = trustVaultQuery.data?.profile;
  const aliasLookup = trustVaultQuery.data
    ? indexProtocolAliases(trustVaultQuery.data.aliases)
    : undefined;
  const selectedMetric =
    snapshot.customMetricSummaries.find((metric) => metric.metricId === selectedMetricId) ?? null;
  const activeMetricValueType = selectedMetric?.valueType ?? metricValueType;
  const activeMetricUnit = selectedMetric?.unit ?? (metricUnit || null);
  const canSaveWeight = weightValue.trim().length > 0;
  const canSaveCustomMetric =
    (selectedMetric !== null || metricLabel.trim().length > 0) &&
    (activeMetricValueType === 'number'
      ? metricNumberValue.trim().length > 0
      : activeMetricValueType === 'text'
        ? metricTextValue.trim().length > 0
        : metricBooleanValue !== null);

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Atlas keeps insights descriptive. These sections summarize what you logged, what inventory is doing, and what the current schedule window suggests."
          eyebrow="Insights"
          title="Trends built from your own routine"
          trailing={
            <View style={styles.statusRow}>
              <StatusPill
                label={snapshot.hasAnyInsightData ? 'Live local data' : 'Ready for first logs'}
                tone={snapshot.hasAnyInsightData ? 'success' : 'muted'}
              />
            </View>
          }
        />

        {!snapshot.hasAnyInsightData ? (
          <EmptyStateCard
            body="Create a protocol and start logging weight, symptoms, or a custom metric. Atlas will keep this surface descriptive and local-first."
            eyebrow="No insight logs yet"
            onPrimaryAction={() => {
              router.push('/protocols/new');
            }}
            primaryActionLabel="Create your first protocol"
            title="Nothing to summarize yet"
          />
        ) : null}

        <InsightSectionCard
          description="Quick entries stay close to the insights they drive, so daily context can be logged in a few thumb taps."
          eyebrow="Daily inputs"
          title="Log today’s context"
        >
          <View style={styles.formStack}>
            <View style={styles.quickForm}>
              <AppText variant="heading">Weight</AppText>
              <AppInput
                keyboardType="decimal-pad"
                label="Weight value"
                onChange={(event) => {
                  setWeightValue(event.nativeEvent.text);
                }}
                onEndEditing={(event) => {
                  setWeightValue(event.nativeEvent.text);
                }}
                onChangeText={setWeightValue}
                placeholder="Enter weight"
                value={weightValue}
              />
              <View style={styles.pillStack}>
                {weightUnits.map((unit) => (
                  <ProtocolChoicePill
                    key={unit}
                    isSelected={weightUnit === unit}
                    label={unit}
                    onPress={() => {
                      setWeightUnit(unit);
                    }}
                  />
                ))}
              </View>
              <AppInput
                label="Weight note (optional)"
                onChange={(event) => {
                  setWeightNotes(event.nativeEvent.text);
                }}
                onEndEditing={(event) => {
                  setWeightNotes(event.nativeEvent.text);
                }}
                onChangeText={setWeightNotes}
                placeholder="Morning check-in"
                value={weightNotes}
              />
              <AppButton
                disabled={!canSaveWeight}
                label={saveWeightMutation.isPending ? 'Saving weight...' : 'Save weight'}
                onPress={() => {
                  if (!canSaveWeight) {
                    return;
                  }

                  void saveWeightMutation.mutateAsync({
                    notes: weightNotes.trim() || null,
                    unit: weightUnit,
                    value: Number(weightValue),
                  }).then(() => {
                    setWeightValue('');
                    setWeightNotes('');
                  });
                }}
                variant="secondary"
              />
            </View>

            <View style={styles.quickForm}>
              <AppText variant="heading">Symptom</AppText>
              <View style={styles.pillStack}>
                {symptomOptions.map((option) => (
                  <ProtocolChoicePill
                    key={option}
                    isSelected={symptomKey === option}
                    label={option}
                    onPress={() => {
                      setSymptomKey(option);
                    }}
                  />
                ))}
              </View>
              <View style={styles.pillRow}>
                {severityOptions.map((value) => (
                  <ProtocolChoicePill
                    key={value}
                    description={value === 1 ? 'light' : value === 5 ? 'strong' : undefined}
                    isSelected={symptomSeverity === value}
                    label={String(value)}
                    onPress={() => {
                      setSymptomSeverity(value);
                    }}
                  />
                ))}
              </View>
              <AppInput
                label="Symptom note (optional)"
                onChange={(event) => {
                  setSymptomNotes(event.nativeEvent.text);
                }}
                onEndEditing={(event) => {
                  setSymptomNotes(event.nativeEvent.text);
                }}
                onChangeText={setSymptomNotes}
                placeholder="Anything worth remembering"
                value={symptomNotes}
              />
              <AppButton
                label={saveSymptomMutation.isPending ? 'Saving symptom...' : 'Save symptom'}
                onPress={() => {
                  void saveSymptomMutation
                    .mutateAsync({
                      notes: symptomNotes.trim() || null,
                      severity: symptomSeverity,
                      symptomKey,
                    })
                    .then(() => {
                      setSymptomNotes('');
                    });
                }}
                variant="secondary"
              />
            </View>
          </View>

          <View style={styles.quickForm}>
            <AppText variant="heading">Custom metric</AppText>
            {snapshot.customMetricSummaries.length > 0 ? (
              <View style={styles.pillStack}>
                <ProtocolChoicePill
                  isSelected={selectedMetricId === null}
                  label="Create new metric"
                  onPress={() => {
                    setSelectedMetricId(null);
                  }}
                />
                {snapshot.customMetricSummaries.map((metric) => (
                  <ProtocolChoicePill
                    key={metric.metricId}
                    description={metric.latestEntryLabel ?? 'No entries yet'}
                    isSelected={selectedMetricId === metric.metricId}
                    label={metric.label}
                    onPress={() => {
                      setSelectedMetricId(metric.metricId);
                    }}
                  />
                ))}
              </View>
            ) : null}

            {!selectedMetric ? (
              <>
                <AppInput
                  label="Metric label"
                  onChange={(event) => {
                    setMetricLabel(event.nativeEvent.text);
                  }}
                  onEndEditing={(event) => {
                    setMetricLabel(event.nativeEvent.text);
                  }}
                  onChangeText={setMetricLabel}
                  placeholder="Metric name"
                  value={metricLabel}
                />
                <View style={styles.pillStack}>
                  {metricValueTypes.map((type) => (
                    <ProtocolChoicePill
                      key={type}
                      isSelected={metricValueType === type}
                      label={type}
                      onPress={() => {
                        setMetricValueType(type);
                      }}
                    />
                  ))}
                </View>
                <AppInput
                  label="Unit (optional)"
                  onChange={(event) => {
                    setMetricUnit(event.nativeEvent.text);
                  }}
                  onEndEditing={(event) => {
                    setMetricUnit(event.nativeEvent.text);
                  }}
                  onChangeText={setMetricUnit}
                  placeholder="Unit label"
                  value={metricUnit}
                />
                <AppText style={styles.captionLabel} variant="caption">
                  Attach to protocol (optional)
                </AppText>
                <View style={styles.pillStack}>
                  <ProtocolChoicePill
                    isSelected={metricProtocolId === null}
                    label="General metric"
                    onPress={() => {
                      setMetricProtocolId(null);
                    }}
                  />
                  {(protocolListQuery.data ?? []).map((protocol) => (
                    <ProtocolChoicePill
                      key={protocol.id}
                      isSelected={metricProtocolId === protocol.id}
                      label={formatProtocolDisplayName(
                        protocol.title,
                        protocol.kind,
                        privacy,
                        privacyProfile,
                        aliasLookup?.[protocol.id],
                      )}
                      onPress={() => {
                        setMetricProtocolId(protocol.id);
                      }}
                    />
                  ))}
                </View>
              </>
            ) : null}

            {activeMetricValueType === 'number' ? (
              <AppInput
                keyboardType="decimal-pad"
                label={`Number value${activeMetricUnit ? ` (${activeMetricUnit})` : ''}`}
                onChange={(event) => {
                  setMetricNumberValue(event.nativeEvent.text);
                }}
                onEndEditing={(event) => {
                  setMetricNumberValue(event.nativeEvent.text);
                }}
                onChangeText={setMetricNumberValue}
                placeholder="Enter number"
                value={metricNumberValue}
              />
            ) : activeMetricValueType === 'text' ? (
              <AppInput
                label="Text value"
                onChange={(event) => {
                  setMetricTextValue(event.nativeEvent.text);
                }}
                onEndEditing={(event) => {
                  setMetricTextValue(event.nativeEvent.text);
                }}
                onChangeText={setMetricTextValue}
                placeholder="Enter text"
                value={metricTextValue}
              />
            ) : (
              <View style={styles.pillRow}>
                <ProtocolChoicePill
                  isSelected={metricBooleanValue === true}
                  label="Yes"
                  onPress={() => {
                    setMetricBooleanValue(true);
                  }}
                />
                <ProtocolChoicePill
                  isSelected={metricBooleanValue === false}
                  label="No"
                  onPress={() => {
                    setMetricBooleanValue(false);
                  }}
                />
              </View>
            )}

            <AppButton
              disabled={!canSaveCustomMetric}
              label={saveCustomMetricMutation.isPending ? 'Saving metric...' : 'Save metric entry'}
              onPress={() => {
                if (!canSaveCustomMetric) {
                  return;
                }

                void saveCustomMetricMutation
                  .mutateAsync({
                    booleanValue: activeMetricValueType === 'boolean' ? metricBooleanValue : null,
                    metricId: selectedMetric?.metricId ?? null,
                    metricLabel: selectedMetric ? null : metricLabel,
                    numberValue:
                      activeMetricValueType === 'number' && metricNumberValue.trim()
                        ? Number(metricNumberValue)
                        : null,
                    protocolId: selectedMetric ? null : metricProtocolId,
                    textValue:
                      activeMetricValueType === 'text' ? metricTextValue.trim() : null,
                    unit: selectedMetric ? null : metricUnit.trim() || null,
                    valueType: activeMetricValueType,
                  })
                  .then(() => {
                    setMetricLabel('');
                    setMetricNumberValue('');
                    setMetricTextValue('');
                  });
              }}
              variant="secondary"
            />
          </View>
        </InsightSectionCard>

        <InsightSectionCard
          description="Recent body-weight entries stay local and can also stand alone without any health connection."
          eyebrow="Weight trend"
          title="Weight trend"
        >
          {snapshot.weightTrend.latestLabel ? (
            <>
              <View style={styles.statusRow}>
                <StatusPill label={snapshot.weightTrend.latestLabel} tone="muted" />
                {snapshot.weightTrend.changeLabel ? (
                  <StatusPill label={snapshot.weightTrend.changeLabel} tone="default" />
                ) : null}
              </View>
              <MiniBarSeries points={snapshot.weightTrend.points} />
            </>
          ) : (
            <AppText variant="caption">
              Save a weight entry to start a local trend line.
            </AppText>
          )}
        </InsightSectionCard>

        <InsightSectionCard
          description="This is a descriptive average of the symptom entries you logged recently."
          eyebrow="Symptom trend"
          title="Symptoms in the last two weeks"
        >
          {snapshot.symptomTrend.length > 0 ? (
            snapshot.symptomTrend.map((item) => (
              <View key={item.symptomKey} style={styles.rowBetween}>
                <View style={styles.copyStack}>
                  <AppText>{capitalize(item.symptomKey)}</AppText>
                  <AppText variant="caption">{item.latestLabel}</AppText>
                </View>
                <StatusPill
                  label={`${item.averageSeverity}/5 avg across ${item.entryCount}`}
                  tone="muted"
                />
              </View>
            ))
          ) : (
            <AppText variant="caption">
              Save one or two symptom entries to see local trend summaries here.
            </AppText>
          )}
        </InsightSectionCard>

        <InsightSectionCard
          description="Inventory burn-down stays grounded in linked vials, remaining quantity, and projected depletion already used elsewhere in Atlas."
          eyebrow="Inventory"
          title="Inventory burn-down"
        >
          {snapshot.inventoryBurnDown.length > 0 ? (
            snapshot.inventoryBurnDown.map((item) => (
              <View key={item.id} style={styles.inventoryRow}>
                <View style={styles.copyStack}>
                  <AppText>
                    {formatVialDisplayName(item.label, privacy, privacyProfile)}
                  </AppText>
                  <AppText variant="caption">{item.quantityLabel}</AppText>
                  {item.projectedDepletionLabel ? (
                    <AppText variant="caption">{item.projectedDepletionLabel}</AppText>
                  ) : null}
                </View>
                <StatusPill
                  label={item.isLowStock ? 'Low stock' : 'Stable'}
                  tone={item.isLowStock ? 'default' : 'muted'}
                />
              </View>
            ))
          ) : (
            <AppText variant="caption">
              Link a vial in Inventory to watch stock runway here.
            </AppText>
          )}
        </InsightSectionCard>

        <InsightSectionCard
          description="Adherence is based on generated due occurrences and immutable historical logs over the last 30 days."
          eyebrow="Adherence"
          title="Routine follow-through"
        >
          <View style={styles.statusRow}>
            {snapshot.adherenceTrend.completionRateLabel ? (
              <StatusPill label={snapshot.adherenceTrend.completionRateLabel} tone="success" />
            ) : (
              <StatusPill label="No due items yet" tone="muted" />
            )}
            <StatusPill label={`${snapshot.adherenceTrend.completedCount} taken`} tone="muted" />
            <StatusPill label={`${snapshot.adherenceTrend.skippedCount} skipped`} tone="muted" />
            <StatusPill label={`${snapshot.adherenceTrend.overdueCount} overdue`} tone="muted" />
            <StatusPill
              label={`${snapshot.adherenceTrend.rescheduledCount} rescheduled`}
              tone="muted"
            />
          </View>
        </InsightSectionCard>

        <InsightSectionCard
          description={snapshot.amountInSystem.disclaimer}
          eyebrow="Estimate model"
          title="Estimated amount-in-system"
        >
          <View style={styles.disclaimerCard}>
            <AppText variant="caption">{snapshot.amountInSystem.disclaimer}</AppText>
          </View>
          {snapshot.amountInSystem.items.length > 0 ? (
            snapshot.amountInSystem.items.map((item) => (
              <View key={item.protocolId} style={styles.estimateRow}>
                <View style={styles.copyStack}>
                  <AppText>
                    {formatProtocolDisplayName(
                      item.protocolName,
                      (protocolListQuery.data ?? []).find((protocol) => protocol.id === item.protocolId)?.kind ?? 'custom',
                      privacy,
                      privacyProfile,
                      aliasLookup?.[item.protocolId],
                    )}
                  </AppText>
                  <AppText variant="caption">{item.cadenceLabel}</AppText>
                  <AppText variant="caption">{item.notesLabel}</AppText>
                </View>
                <StatusPill label={item.estimateLabel} tone="default" />
              </View>
            ))
          ) : (
            <AppText variant="caption">
              Atlas needs completed logs with saved quantities before it can show this schedule-based estimate.
            </AppText>
          )}
        </InsightSectionCard>

        <InsightSectionCard
          description="Custom metrics stay optional and can stand alone or be attached to a specific protocol."
          eyebrow="Custom metrics"
          title="Saved metric definitions"
        >
          {snapshot.customMetricSummaries.length > 0 ? (
            snapshot.customMetricSummaries.map((metric) => (
              <View key={metric.metricId} style={styles.rowBetween}>
                <View style={styles.copyStack}>
                  <AppText>{metric.label}</AppText>
                  <AppText variant="caption">
                    {metric.protocolName
                      ? `Attached to ${formatProtocolDisplayName(
                          metric.protocolName,
                          (protocolListQuery.data ?? []).find((protocol) => protocol.id === metric.protocolId)?.kind ??
                            'custom',
                          privacy,
                          privacyProfile,
                          metric.protocolId ? aliasLookup?.[metric.protocolId] : null,
                        )}`
                      : 'General metric'}
                  </AppText>
                </View>
                <StatusPill
                  label={metric.latestEntryLabel ?? 'No entries yet'}
                  tone="muted"
                />
              </View>
            ))
          ) : (
            <AppText variant="caption">
              Save a custom metric above to build reusable personal tracking.
            </AppText>
          )}
        </InsightSectionCard>
      </View>
    </AppScreen>
  );
}

function capitalize(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  formStack: {
    gap: atlasTheme.spacing.md,
  },
  quickForm: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.card,
    gap: atlasTheme.spacing.md,
    padding: atlasTheme.spacing.md,
  },
  pillStack: {
    gap: atlasTheme.spacing.sm,
  },
  pillRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  rowBetween: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  inventoryRow: {
    alignItems: 'center',
    borderTopColor: atlasTheme.colors.border,
    borderTopWidth: 1,
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
    paddingTop: atlasTheme.spacing.md,
  },
  estimateRow: {
    gap: atlasTheme.spacing.sm,
  },
  disclaimerCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.button,
    padding: atlasTheme.spacing.md,
  },
  copyStack: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
  },
  captionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
});

import type {
  CustomMetric,
  LogEvent,
  MetricValueLog,
  Protocol,
  ProtocolRevision,
  ProtocolRevisionRule,
  SymptomLog,
  WeightLog,
} from '@/src/lib/database/schemas';
import type { GeneratedOccurrence } from '@/src/features/day-loop/service';
import {
  buildAdherenceTrend,
  buildAmountEstimateItems,
  buildCustomMetricSummaries,
  buildSymptomTrend,
  buildWeightTrend,
  type InsightsProtocolBundle,
} from '@/src/features/insights/service';

describe('insights service', () => {
  it('derives weight and symptom trends from local logs', () => {
    const weightLogs: WeightLog[] = [
      createWeightLog('w1', '2026-03-01T12:00:00.000Z', 182, 'lb'),
      createWeightLog('w2', '2026-03-07T12:00:00.000Z', 180, 'lb'),
    ];
    const symptomLogs: SymptomLog[] = [
      createSymptomLog('s1', '2026-03-10T08:00:00.000Z', 'nausea', 2),
      createSymptomLog('s2', '2026-03-11T08:00:00.000Z', 'nausea', 3),
      createSymptomLog('s3', '2026-03-12T08:00:00.000Z', 'sleep', 4),
    ];

    const weightTrend = buildWeightTrend(weightLogs);
    const symptomTrend = buildSymptomTrend(symptomLogs, new Date('2026-03-13T12:00:00.000Z'));

    expect(weightTrend.latestLabel).toContain('180 lb');
    expect(weightTrend.changeLabel).toContain('-2.0 lb');
    expect(weightTrend.points).toHaveLength(2);
    expect(symptomTrend[0]).toEqual(
      expect.objectContaining({
        averageSeverity: '4.0',
        symptomKey: 'sleep',
      })
    );
  });

  it('derives adherence, amount estimates, and custom metric summaries descriptively', () => {
    const occurrences: GeneratedOccurrence[] = [
      createOccurrence('o1', 'completed', '2026-03-10T08:00:00.000Z'),
      createOccurrence('o2', 'skipped', '2026-03-11T08:00:00.000Z'),
      createOccurrence('o3', 'overdue', '2026-03-12T08:00:00.000Z'),
      createOccurrence('o4', 'rescheduled', '2026-03-12T12:00:00.000Z'),
    ];
    const bundle: InsightsProtocolBundle = {
      compound: null,
      logEvents: [
        createLogEvent('l1', 'completed', '2026-03-12T00:00:00.000Z', 1, 'mg'),
      ],
      protocol: createProtocol('p1'),
      revisions: [
        {
          revision: createRevision('rev1'),
          rules: [createRule('r1')],
        },
      ],
    };
    const metric: CustomMetric = {
      createdAt: '2026-03-01T00:00:00.000Z',
      id: 'm1',
      label: 'Energy',
      metricKey: 'energy',
      protocolId: 'p1',
      unit: 'score',
      updatedAt: '2026-03-01T00:00:00.000Z',
      valueType: 'number',
    };
    const metricValue: MetricValueLog = {
      booleanValue: null,
      createdAt: '2026-03-13T00:00:00.000Z',
      id: 'mv1',
      loggedAt: '2026-03-13T00:00:00.000Z',
      metricId: 'm1',
      numberValue: 8,
      protocolId: 'p1',
      source: 'manual',
      textValue: null,
      updatedAt: '2026-03-13T00:00:00.000Z',
    };

    const adherence = buildAdherenceTrend(occurrences, new Date('2026-03-13T12:00:00.000Z'));
    const amountEstimateItems = buildAmountEstimateItems(
      [bundle],
      new Date('2026-03-13T12:00:00.000Z')
    );
    const metricSummaries = buildCustomMetricSummaries([metric], [metricValue], [bundle.protocol]);

    expect(adherence.completedCount).toBe(1);
    expect(adherence.skippedCount).toBe(1);
    expect(adherence.overdueCount).toBe(1);
    expect(adherence.rescheduledCount).toBe(1);
    expect(adherence.completionRateLabel).toBe('33% logged on time');
    expect(amountEstimateItems[0]?.estimateLabel).toContain('mg in the current schedule window');
    expect(metricSummaries[0]).toEqual(
      expect.objectContaining({
        latestEntryLabel: '8 score',
        protocolName: 'Weekly GLP',
      })
    );
  });
});

function createWeightLog(
  id: string,
  loggedAt: string,
  value: number,
  unit: 'lb' | 'kg'
): WeightLog {
  return {
    createdAt: loggedAt,
    id,
    loggedAt,
    notes: null,
    source: 'manual',
    unit,
    updatedAt: loggedAt,
    value,
  };
}

function createSymptomLog(
  id: string,
  loggedAt: string,
  symptomKey: string,
  severity: number
): SymptomLog {
  return {
    createdAt: loggedAt,
    id,
    loggedAt,
    notes: null,
    severity,
    source: 'manual',
    symptomKey,
    updatedAt: loggedAt,
  };
}

function createOccurrence(
  id: string,
  state: GeneratedOccurrence['state'],
  scheduledFor: string
): GeneratedOccurrence {
  return {
    cadenceLabel: 'Every week',
    compoundName: 'Wegovy',
    doseAmount: 1,
    doseLabel: '1 mg',
    doseUnit: 'mg',
    id,
    kind: 'glp',
    linkedVialId: null,
    originalOccurrenceId: null,
    protocolId: 'p1',
    protocolName: 'Weekly GLP',
    revisionId: 'rev1',
    resolvedBy: null,
    scheduledFor,
    source: 'generated',
    state,
    timeLabel: '8:00 AM',
    whenLabel: 'Today at 8:00 AM',
  };
}

function createProtocol(id: string): Protocol {
  return {
    compoundId: null,
    createdAt: '2026-03-01T00:00:00.000Z',
    defaultTimeOfDay: '08:00',
    doseAmount: 1,
    doseUnit: 'mg',
    id,
    kind: 'glp',
    linkedVialId: null,
    name: 'Weekly GLP',
    notes: null,
    siteRotationEnabled: false,
    siteTrackingEnabled: false,
    startDate: '2026-03-01',
    status: 'active',
    timezone: 'America/New_York',
    updatedAt: '2026-03-01T00:00:00.000Z',
  };
}

function createRule(id: string): ProtocolRevisionRule {
  return {
    anchorDate: '2026-03-01',
    createdAt: '2026-03-01T00:00:00.000Z',
    doseAmountOverride: null,
    doseUnitOverride: null,
    phaseLengthDays: null,
    phaseOrder: 0,
    phaseStartDayOffset: 0,
    phaseType: 'base',
    id,
    intervalCount: 1,
    revisionId: 'rev1',
    ruleType: 'weekly',
    timeOfDay: '08:00',
    updatedAt: '2026-03-01T00:00:00.000Z',
    weekday: 1,
  };
}

function createRevision(id: string): ProtocolRevision {
  return {
    createdAt: '2026-03-01T00:00:00.000Z',
    defaultTimeOfDay: '08:00',
    doseAmount: 1,
    doseUnit: 'mg',
    effectiveFrom: '2026-03-01T00:00:00.000Z',
    effectiveTo: null,
    id,
    lifecycleState: 'active',
    linkedVialId: null,
    missedDosePolicy: 'skip_and_continue',
    notes: null,
    previousRevisionId: null,
    protocolId: 'p1',
    revisionNumber: 1,
    timezone: 'America/New_York',
    timezoneStrategy: 'keep_local_clock',
    updatedAt: '2026-03-01T00:00:00.000Z',
  };
}

function createLogEvent(
  id: string,
  eventType: LogEvent['eventType'],
  effectiveAt: string,
  quantity: number | null,
  quantityUnit: string | null
): LogEvent {
  return {
    effectiveAt,
    eventType,
    id,
    loggedAt: effectiveAt,
    notes: null,
    occurrenceId: 'p1:r1',
    protocolId: 'p1',
    quantity,
    quantityUnit,
    siteId: null,
    source: 'user',
    vialId: null,
  };
}

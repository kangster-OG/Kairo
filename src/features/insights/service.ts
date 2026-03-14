import { createIsoTimestamp } from '@/src/lib/database/id';
import type { AtlasRepositories } from '@/src/lib/database/repositories';
import type {
  CustomMetric,
  LogEvent,
  MetricValueLog,
  Protocol,
  SymptomLog,
  WeightLog,
} from '@/src/lib/database/schemas';
import {
  getActiveRevisionSnapshot,
  type ScheduledProtocolRevisionBundle,
} from '@/src/lib/schedule/protocol-revision-schedule';
import type { GeneratedOccurrence } from '@/src/features/day-loop/service';
import { listProtocolRevisionBundles } from '@/src/features/protocols/bundles';
import {
  saveCustomMetricEntryInputSchema,
  saveSymptomEntryInputSchema,
  saveWeightEntryInputSchema,
  type SaveCustomMetricEntryInput,
  type SaveSymptomEntryInput,
  type SaveWeightEntryInput,
} from '@/src/features/insights/schema';

const TREND_WINDOW_DAYS = 30;
const SYMPTOM_WINDOW_DAYS = 14;

export type InsightsProtocolBundle = ScheduledProtocolRevisionBundle & {
  logEvents: LogEvent[];
};

export type InsightBarPoint = {
  label: string;
  value: number;
};

export type WeightTrendSummary = {
  changeLabel: string | null;
  latestLabel: string | null;
  points: InsightBarPoint[];
};

export type SymptomTrendItem = {
  averageSeverity: string;
  entryCount: number;
  latestLabel: string;
  symptomKey: string;
};

export type InventoryBurnDownItem = {
  id: string;
  isLowStock: boolean;
  label: string;
  projectedDepletionLabel: string | null;
  quantityLabel: string;
};

export type AdherenceTrendSummary = {
  completionRateLabel: string | null;
  completedCount: number;
  overdueCount: number;
  rescheduledCount: number;
  skippedCount: number;
};

export type AmountEstimateItem = {
  cadenceLabel: string;
  estimateLabel: string;
  notesLabel: string;
  protocolId: string;
  protocolName: string;
};

export type CustomMetricSummary = {
  label: string;
  latestEntryLabel: string | null;
  metricId: string;
  protocolId: string | null;
  protocolName: string | null;
  unit: string | null;
  valueType: CustomMetric['valueType'];
};

export type InsightsSnapshot = {
  adherenceTrend: AdherenceTrendSummary;
  amountInSystem: {
    disclaimer:
      'Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation.';
    items: AmountEstimateItem[];
  };
  customMetricSummaries: CustomMetricSummary[];
  hasAnyInsightData: boolean;
  inventoryBurnDown: InventoryBurnDownItem[];
  symptomTrend: SymptomTrendItem[];
  weightTrend: WeightTrendSummary;
};

export async function getInsightsSnapshot(now = new Date()): Promise<InsightsSnapshot> {
  const repositories = await loadAtlasRepositories();
  const { getInventorySnapshot } = await import('@/src/features/inventory/service');
  const [customMetrics, logEvents, metricValueLogs, protocols, symptomLogs, weightLogs, inventorySnapshot] =
    await Promise.all([
    repositories.customMetrics.listAll(),
    repositories.logEvents.listAll(),
    repositories.metricValueLogs.listAll(),
    repositories.protocols.listAll(),
    repositories.symptomLogs.listAll(),
    repositories.weightLogs.listAll(),
    getInventorySnapshot(now),
  ]);

  const bundles = (
    await listProtocolRevisionBundles({
      includeLogs: true,
      repositories,
    })
  ).map((bundle) => ({
    ...bundle,
    logEvents: bundle.logEvents ?? [],
  }));
  const { buildUnresolvedOccurrences } = await import('@/src/features/day-loop/service');
  const occurrences = buildUnresolvedOccurrences(bundles, now);

  return {
    adherenceTrend: buildAdherenceTrend(occurrences, now),
    amountInSystem: {
      disclaimer:
        'Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation.',
      items: buildAmountEstimateItems(bundles, now),
    },
    customMetricSummaries: buildCustomMetricSummaries(customMetrics, metricValueLogs, protocols),
    hasAnyInsightData:
      weightLogs.length > 0 ||
      symptomLogs.length > 0 ||
      metricValueLogs.length > 0 ||
      logEvents.length > 0,
    inventoryBurnDown: inventorySnapshot.vials.map((vial) => ({
      id: vial.id,
      isLowStock: vial.isLowStock,
      label: vial.label,
      projectedDepletionLabel: vial.projectedDepletionLabel,
      quantityLabel: vial.quantityLabel,
    })),
    symptomTrend: buildSymptomTrend(symptomLogs, now),
    weightTrend: buildWeightTrend(weightLogs),
  };
}

export async function saveWeightEntry(input: SaveWeightEntryInput): Promise<WeightLog> {
  const parsed = saveWeightEntryInputSchema.parse(input);
  const repositories = await loadAtlasRepositories();

  return repositories.weightLogs.create({
    loggedAt: parsed.loggedAt ?? createIsoTimestamp(),
    notes: parsed.notes ?? null,
    source: 'manual',
    unit: parsed.unit,
    value: parsed.value,
  });
}

export async function saveSymptomEntry(input: SaveSymptomEntryInput): Promise<SymptomLog> {
  const parsed = saveSymptomEntryInputSchema.parse(input);
  const repositories = await loadAtlasRepositories();

  return repositories.symptomLogs.create({
    loggedAt: parsed.loggedAt ?? createIsoTimestamp(),
    notes: parsed.notes ?? null,
    source: 'manual',
    severity: parsed.severity,
    symptomKey: parsed.symptomKey.trim().toLowerCase(),
  });
}

export async function saveCustomMetricEntry(
  input: SaveCustomMetricEntryInput
): Promise<MetricValueLog> {
  const parsed = saveCustomMetricEntryInputSchema.parse(input);
  const repositories = await loadAtlasRepositories();

  let metricId = parsed.metricId ?? null;

  if (!metricId) {
    const label = parsed.metricLabel?.trim() ?? 'Custom metric';
    const metric = await repositories.customMetrics.create({
      label,
      metricKey: toMetricKey(label),
      protocolId: parsed.protocolId ?? null,
      unit: parsed.unit ?? null,
      valueType: parsed.valueType,
    });
    metricId = metric.id;
  }

  return repositories.metricValueLogs.create({
    booleanValue: parsed.booleanValue ?? null,
    loggedAt: parsed.loggedAt ?? createIsoTimestamp(),
    metricId,
    numberValue: parsed.numberValue ?? null,
    protocolId: parsed.protocolId ?? null,
    source: 'manual',
    textValue: parsed.textValue ?? null,
  });
}

export function buildWeightTrend(weightLogs: WeightLog[]): WeightTrendSummary {
  const ascending = [...weightLogs]
    .sort((left, right) => new Date(left.loggedAt).getTime() - new Date(right.loggedAt).getTime())
    .slice(-6);
  const latest = ascending.at(-1) ?? null;
  const baseline = ascending[0] ?? null;

  return {
    changeLabel:
      latest && baseline && latest.id !== baseline.id
        ? `${formatSigned(latest.value - baseline.value)} ${latest.unit} over recent entries`
        : null,
    latestLabel: latest ? `${latest.value} ${latest.unit} logged ${formatDateLabel(latest.loggedAt)}` : null,
    points: ascending.map((entry) => ({
      label: formatCompactDateLabel(entry.loggedAt),
      value: entry.value,
    })),
  };
}

export function buildSymptomTrend(symptomLogs: SymptomLog[], now: Date): SymptomTrendItem[] {
  const windowStart = new Date(now.getTime() - SYMPTOM_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  const recent = symptomLogs.filter(
    (entry) => new Date(entry.loggedAt).getTime() >= windowStart.getTime()
  );
  const grouped = new Map<string, SymptomLog[]>();

  for (const entry of recent) {
    const existing = grouped.get(entry.symptomKey) ?? [];
    existing.push(entry);
    grouped.set(entry.symptomKey, existing);
  }

  return [...grouped.entries()]
    .map(([symptomKey, entries]) => ({
      averageSeverity: (
        entries.reduce((sum, entry) => sum + entry.severity, 0) / entries.length
      ).toFixed(1),
      entryCount: entries.length,
      latestLabel: `Latest ${formatDateLabel(entries[0]!.loggedAt)}`,
      symptomKey,
    }))
    .sort((left, right) => Number(right.averageSeverity) - Number(left.averageSeverity))
    .slice(0, 4);
}

export function buildAdherenceTrend(
  occurrences: GeneratedOccurrence[],
  now: Date
): AdherenceTrendSummary {
  const windowStart = new Date(now.getTime() - TREND_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  const dueItems = occurrences.filter((entry) => {
    const timestamp = new Date(entry.scheduledFor).getTime();
    return timestamp >= windowStart.getTime() && timestamp <= now.getTime();
  });

  const completedCount = dueItems.filter((entry) => entry.state === 'completed').length;
  const skippedCount = dueItems.filter((entry) => entry.state === 'skipped').length;
  const overdueCount = dueItems.filter((entry) => entry.state === 'overdue').length;
  const rescheduledCount = dueItems.filter((entry) => entry.state === 'rescheduled').length;
  const countedDueItems = completedCount + skippedCount + overdueCount;

  return {
    completionRateLabel:
      countedDueItems > 0 ? `${Math.round((completedCount / countedDueItems) * 100)}% logged on time` : null,
    completedCount,
    overdueCount,
    rescheduledCount,
    skippedCount,
  };
}

export function buildAmountEstimateItems(bundles: InsightsProtocolBundle[], now: Date): AmountEstimateItem[] {
  return bundles
    .filter((bundle) => bundle.protocol.status === 'active')
    .map((bundle) => {
      const snapshot = getActiveRevisionSnapshot(bundle, now);
      const intervalHours = getRuleIntervalHours(snapshot.activeRule);
      const completedLogs = bundle.logEvents.filter(
        (event) =>
          event.eventType === 'completed' &&
          event.quantity !== null &&
          event.quantityUnit !== null &&
          intervalHours !== null
      );

      const estimate = completedLogs.reduce((sum, event) => {
        const elapsedHours =
          (now.getTime() - new Date(event.effectiveAt).getTime()) / (60 * 60 * 1000);
        const remainingFraction = Math.max(0, 1 - elapsedHours / intervalHours!);
        return sum + (event.quantity ?? 0) * remainingFraction;
      }, 0);

      return {
        cadenceLabel: snapshot.activeRule ? describeRule(snapshot.activeRule) : 'No cadence saved yet',
        estimateLabel:
          estimate > 0 && (snapshot.doseUnit ?? bundle.protocol.doseUnit)
            ? `${estimate.toFixed(2)} ${snapshot.doseUnit ?? bundle.protocol.doseUnit} in the current schedule window`
            : 'No recent logged quantity to estimate from',
        notesLabel:
          estimate > 0
            ? `Built from completed logs over the current ${intervalHours ?? 0}-hour interval window.`
            : 'Atlas needs completed logs with saved quantities before it can show this estimate.',
        protocolId: bundle.protocol.id,
        protocolName: bundle.protocol.name,
      };
    })
    .filter((item) => item.estimateLabel.length > 0);
}

export function buildCustomMetricSummaries(
  customMetrics: CustomMetric[],
  metricValueLogs: MetricValueLog[],
  protocols: Protocol[]
): CustomMetricSummary[] {
  return customMetrics
    .map((metric) => {
      const latest = metricValueLogs.find((entry) => entry.metricId === metric.id) ?? null;
      return {
        label: metric.label,
        latestEntryLabel: latest ? formatMetricValue(latest, metric.unit) : null,
        metricId: metric.id,
        protocolId: metric.protocolId,
        protocolName:
          protocols.find((protocol) => protocol.id === metric.protocolId)?.name ?? null,
        unit: metric.unit,
        valueType: metric.valueType,
      };
    })
    .sort((left, right) => left.label.localeCompare(right.label));
}

function formatMetricValue(entry: MetricValueLog, unit: string | null) {
  if (entry.numberValue !== null) {
    return unit ? `${entry.numberValue} ${unit}` : String(entry.numberValue);
  }

  if (entry.textValue !== null) {
    return entry.textValue;
  }

  if (entry.booleanValue !== null) {
    return entry.booleanValue ? 'Yes' : 'No';
  }

  return null;
}

function getRuleIntervalHours(
  rule: { intervalCount: number; ruleType: 'daily' | 'every_n_days' | 'weekly' } | null
) {
  if (!rule) {
    return null;
  }

  if (rule.ruleType === 'weekly') {
    return 7 * 24;
  }

  if (rule.ruleType === 'daily') {
    return 24;
  }

  return rule.intervalCount * 24;
}

function describeRule(rule: { intervalCount: number; ruleType: 'daily' | 'every_n_days' | 'weekly' }) {
  if (rule.ruleType === 'weekly') {
    return 'Weekly interval model';
  }

  if (rule.ruleType === 'daily') {
    return 'Daily interval model';
  }

  return `Every ${rule.intervalCount} days`;
}

function formatDateLabel(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(new Date(value));
}

function formatCompactDateLabel(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'numeric',
    day: 'numeric',
  }).format(new Date(value));
}

function formatSigned(value: number) {
  return value > 0 ? `+${value.toFixed(1)}` : value.toFixed(1);
}

function toMetricKey(label: string) {
  return label
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

async function loadAtlasRepositories(): Promise<AtlasRepositories> {
  const module = await import('@/src/lib/database');
  return module.getAtlasRepositories();
}

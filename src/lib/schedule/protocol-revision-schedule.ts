import type {
  Compound,
  LogEvent,
  Protocol,
  ProtocolRevision,
  ProtocolRevisionRule,
} from '@/src/lib/database/schemas';

const DAY_MS = 24 * 60 * 60 * 1000;

export type ProtocolRevisionSlice = {
  revision: ProtocolRevision;
  rules: ProtocolRevisionRule[];
};

export type ScheduledProtocolRevisionBundle = {
  compound: Compound | null;
  logEvents?: LogEvent[];
  protocol: Protocol;
  revisions: ProtocolRevisionSlice[];
};

export type RevisionProjectedOccurrence = {
  cadenceLabel: string;
  compoundName: string | null;
  doseAmount: number | null;
  doseLabel: string | null;
  doseUnit: string | null;
  id: string;
  kind: Protocol['kind'];
  linkedVialId: string | null;
  protocolId: string;
  protocolName: string;
  revisionId: string;
  scheduledFor: string;
  timeLabel: string;
  whenLabel: string;
};

export type ActiveRevisionSnapshot = {
  activeRule: ProtocolRevisionRule | null;
  cadenceDays: number | null;
  cadenceLabel: string;
  doseAmount: number | null;
  doseLabel: string | null;
  doseUnit: string | null;
  linkedVialId: string | null;
  revision: ProtocolRevision | null;
  timeLabel: string;
};

export function getActiveRevisionSnapshot(
  bundle: ScheduledProtocolRevisionBundle,
  at = new Date()
): ActiveRevisionSnapshot {
  const revision = getEffectiveRevisionAt(bundle.revisions, at);

  if (!revision) {
    return {
      activeRule: null,
      cadenceDays: null,
      cadenceLabel: 'No active future cadence',
      doseAmount: null,
      doseLabel: null,
      doseUnit: null,
      linkedVialId: null,
      revision: null,
      timeLabel: 'Time not set',
    };
  }

  const activeRule = getRuleForDate(revision, at);
  const doseAmount = activeRule?.doseAmountOverride ?? revision.revision.doseAmount;
  const doseUnit = activeRule?.doseUnitOverride ?? revision.revision.doseUnit;

  return {
    activeRule,
    cadenceDays: getCadenceDays(activeRule),
    cadenceLabel: activeRule ? formatCadenceLabel(activeRule, revision.revision.defaultTimeOfDay) : 'Paused',
    doseAmount,
    doseLabel: doseAmount !== null && doseUnit ? `${doseAmount} ${doseUnit}` : null,
    doseUnit,
    linkedVialId: revision.revision.linkedVialId,
    revision: revision.revision,
    timeLabel: formatTimeOfDay(activeRule?.timeOfDay ?? revision.revision.defaultTimeOfDay),
  };
}

export function getEffectiveRevisionAt(
  revisions: ProtocolRevisionSlice[],
  at: Date
): ProtocolRevisionSlice | null {
  const atTime = at.getTime();
  const sorted = [...revisions].sort(
    (left, right) =>
      new Date(left.revision.effectiveFrom).getTime() - new Date(right.revision.effectiveFrom).getTime()
  );

  for (let index = sorted.length - 1; index >= 0; index -= 1) {
    const candidate = sorted[index];
    const start = new Date(candidate.revision.effectiveFrom).getTime();
    const end = candidate.revision.effectiveTo
      ? new Date(candidate.revision.effectiveTo).getTime()
      : Number.POSITIVE_INFINITY;

    if (start <= atTime && atTime < end) {
      return candidate;
    }
  }

  return null;
}

export function getRuleForDate(
  slice: ProtocolRevisionSlice,
  at: Date
): ProtocolRevisionRule | null {
  if (slice.revision.lifecycleState !== 'active') {
    return null;
  }

  const revisionStart = startOfLocalDay(new Date(slice.revision.effectiveFrom));
  const targetDay = startOfLocalDay(at).getTime();

  return (
    [...slice.rules]
      .sort((left, right) => left.phaseOrder - right.phaseOrder)
      .find((rule) => {
        const phaseStart = revisionStart.getTime() + rule.phaseStartDayOffset * DAY_MS;
        const phaseEnd = rule.phaseLengthDays
          ? phaseStart + rule.phaseLengthDays * DAY_MS
          : Number.POSITIVE_INFINITY;
        return phaseStart <= targetDay && targetDay < phaseEnd;
      }) ?? null
  );
}

export function getNextProjectedOccurrence(
  bundle: ScheduledProtocolRevisionBundle,
  now = new Date()
): RevisionProjectedOccurrence | null {
  return (
    generateProjectedOccurrences(bundle, {
      end: new Date(now.getTime() + 30 * DAY_MS),
      now,
      start: now,
    })[0] ?? null
  );
}

export function generateProjectedOccurrences(
  bundle: ScheduledProtocolRevisionBundle,
  options: {
    end: Date;
    now: Date;
    start: Date;
  }
): RevisionProjectedOccurrence[] {
  const sorted = [...bundle.revisions].sort(
    (left, right) =>
      new Date(left.revision.effectiveFrom).getTime() - new Date(right.revision.effectiveFrom).getTime()
  );
  const occurrences: RevisionProjectedOccurrence[] = [];

  for (const slice of sorted) {
    if (slice.revision.lifecycleState !== 'active') {
      continue;
    }

    const revisionStart = new Date(slice.revision.effectiveFrom);
    const revisionEnd = slice.revision.effectiveTo ? new Date(slice.revision.effectiveTo) : options.end;
    const windowStart =
      revisionStart.getTime() > options.start.getTime() ? revisionStart : options.start;
    const windowEnd =
      revisionEnd.getTime() < options.end.getTime() ? revisionEnd : options.end;

    if (windowStart.getTime() >= windowEnd.getTime()) {
      continue;
    }

    for (const rule of [...slice.rules].sort((left, right) => left.phaseOrder - right.phaseOrder)) {
      if (rule.phaseType === 'rest') {
        continue;
      }

      const timeOfDay = rule.timeOfDay ?? slice.revision.defaultTimeOfDay;
      if (!timeOfDay) {
        continue;
      }

      const phaseStart = new Date(startOfLocalDay(revisionStart).getTime() + rule.phaseStartDayOffset * DAY_MS);
      const phaseEnd = rule.phaseLengthDays
        ? new Date(phaseStart.getTime() + rule.phaseLengthDays * DAY_MS)
        : windowEnd;
      const effectiveStart =
        phaseStart.getTime() > windowStart.getTime() ? phaseStart : windowStart;
      const effectiveEnd =
        phaseEnd.getTime() < windowEnd.getTime() ? phaseEnd : windowEnd;

      if (effectiveStart.getTime() >= effectiveEnd.getTime()) {
        continue;
      }

      const dates = generateDatesForRule(
        rule,
        rule.anchorDate ?? formatLocalDate(phaseStart),
        timeOfDay,
        effectiveStart,
        effectiveEnd
      );

      for (const scheduledDate of dates) {
        const doseAmount = rule.doseAmountOverride ?? slice.revision.doseAmount;
        const doseUnit = rule.doseUnitOverride ?? slice.revision.doseUnit;

        occurrences.push({
          cadenceLabel: formatCadenceLabel(rule, slice.revision.defaultTimeOfDay),
          compoundName: bundle.compound?.displayName ?? null,
          doseAmount,
          doseLabel: doseAmount !== null && doseUnit ? `${doseAmount} ${doseUnit}` : null,
          doseUnit,
          id: buildOccurrenceId(bundle.protocol.id, slice.revision.id, rule.id, scheduledDate),
          kind: bundle.protocol.kind,
          linkedVialId: slice.revision.linkedVialId,
          protocolId: bundle.protocol.id,
          protocolName: bundle.protocol.name,
          revisionId: slice.revision.id,
          scheduledFor: scheduledDate.toISOString(),
          timeLabel: formatTimeOfDay(timeOfDay),
          whenLabel: formatWhenLabel(scheduledDate, options.now),
        });
      }
    }
  }

  return occurrences
    .sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime())
    .filter((occurrence) => new Date(occurrence.scheduledFor).getTime() >= options.start.getTime());
}

export function formatTimeOfDay(value: string | null | undefined): string {
  if (!value) {
    return 'Time not set';
  }

  const [hours, minutes] = value.split(':').map(Number);
  const reference = new Date(2026, 0, 1, hours, minutes);

  return new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  }).format(reference);
}

export function formatCadenceLabel(
  rule: Pick<ProtocolRevisionRule, 'intervalCount' | 'ruleType' | 'timeOfDay' | 'weekday'>,
  fallbackTimeOfDay?: string | null
): string {
  const timeLabel = formatTimeOfDay(rule.timeOfDay ?? fallbackTimeOfDay ?? null);

  switch (rule.ruleType) {
    case 'weekly':
      return `Every ${weekdayLabel(rule.weekday)} at ${timeLabel}`;
    case 'every_n_days':
      return `Every ${rule.intervalCount} day${rule.intervalCount === 1 ? '' : 's'} at ${timeLabel}`;
    default:
      return `Every day at ${timeLabel}`;
  }
}

export function getCadenceDays(rule: Pick<ProtocolRevisionRule, 'intervalCount' | 'ruleType'> | null) {
  if (!rule) {
    return null;
  }

  switch (rule.ruleType) {
    case 'weekly':
      return 7 * Math.max(rule.intervalCount, 1);
    case 'every_n_days':
      return Math.max(rule.intervalCount, 1);
    default:
      return 1;
  }
}

function generateDatesForRule(
  rule: Pick<ProtocolRevisionRule, 'intervalCount' | 'ruleType' | 'weekday'>,
  anchorDate: string,
  timeOfDay: string,
  horizonStart: Date,
  horizonEnd: Date
): Date[] {
  return rule.ruleType === 'weekly'
    ? generateWeeklyDates(anchorDate, rule.weekday, timeOfDay, horizonStart, horizonEnd)
    : generateIntervalDates(anchorDate, Math.max(rule.intervalCount, 1), timeOfDay, horizonStart, horizonEnd);
}

function generateWeeklyDates(
  startDate: string,
  weekday: number | null,
  timeOfDay: string,
  horizonStart: Date,
  horizonEnd: Date
): Date[] {
  if (weekday === null) {
    return [];
  }

  const cursor = parseLocalDateTime(startDate, timeOfDay);
  while (cursor.getDay() !== weekday) {
    cursor.setDate(cursor.getDate() + 1);
  }

  const results: Date[] = [];
  while (cursor.getTime() < horizonEnd.getTime()) {
    if (cursor.getTime() >= horizonStart.getTime()) {
      results.push(new Date(cursor));
    }
    cursor.setDate(cursor.getDate() + 7);
  }

  return results;
}

function generateIntervalDates(
  anchorDate: string,
  intervalCount: number,
  timeOfDay: string,
  horizonStart: Date,
  horizonEnd: Date
): Date[] {
  const cursor = parseLocalDateTime(anchorDate, timeOfDay);
  const results: Date[] = [];

  while (cursor.getTime() < horizonStart.getTime()) {
    cursor.setTime(cursor.getTime() + intervalCount * DAY_MS);
  }

  while (cursor.getTime() < horizonEnd.getTime()) {
    results.push(new Date(cursor));
    cursor.setTime(cursor.getTime() + intervalCount * DAY_MS);
  }

  return results;
}

function parseLocalDateTime(dateValue: string, timeOfDay: string): Date {
  const [year, month, day] = dateValue.slice(0, 10).split('-').map(Number);
  const [hours, minutes] = timeOfDay.split(':').map(Number);

  return new Date(year, month - 1, day, hours, minutes, 0, 0);
}

function formatLocalDate(value: Date) {
  const year = value.getFullYear();
  const month = `${value.getMonth() + 1}`.padStart(2, '0');
  const day = `${value.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function startOfLocalDay(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate());
}

function buildOccurrenceId(protocolId: string, revisionId: string, ruleId: string, scheduledDate: Date) {
  return `${protocolId}:${revisionId}:${ruleId}:${scheduledDate.toISOString()}`;
}

function weekdayLabel(weekday: number | null): string {
  const labels = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return weekday === null ? 'day' : labels[weekday] ?? 'day';
}

function formatWhenLabel(value: Date, now: Date): string {
  const startOfNow = startOfLocalDay(now);
  const startOfValue = startOfLocalDay(value);
  const diffDays = Math.round((startOfValue.getTime() - startOfNow.getTime()) / DAY_MS);
  const timeLabel = new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  }).format(value);

  if (diffDays === 0) {
    return `Today at ${timeLabel}`;
  }

  if (diffDays === 1) {
    return `Tomorrow at ${timeLabel}`;
  }

  if (diffDays < 0) {
    return `Was due ${new Intl.DateTimeFormat(undefined, {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    }).format(value)}`;
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    weekday: 'short',
    hour: 'numeric',
    minute: '2-digit',
  }).format(value);
}

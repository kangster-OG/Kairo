import type { Compound, Protocol, ProtocolRule } from '@/src/lib/database/schemas';

const DAY_MS = 24 * 60 * 60 * 1000;

export type ScheduledProtocolBundle = {
  compound: Compound | null;
  protocol: Protocol;
  rules: ProtocolRule[];
};

export type NextDueItem = {
  cadenceLabel: string;
  compoundName: string | null;
  doseLabel: string | null;
  kind: Protocol['kind'];
  protocolId: string;
  protocolName: string;
  scheduledFor: string;
  timeLabel: string;
  whenLabel: string;
};

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

export function formatDoseLabel(protocol: Pick<Protocol, 'doseAmount' | 'doseUnit'>): string | null {
  if (protocol.doseAmount === null || !protocol.doseUnit) {
    return null;
  }

  return `${protocol.doseAmount} ${protocol.doseUnit}`;
}

export function formatCadenceLabel(rule: Pick<ProtocolRule, 'intervalCount' | 'ruleType' | 'timeOfDay' | 'weekday'>): string {
  const timeLabel = formatTimeOfDay(rule.timeOfDay);

  switch (rule.ruleType) {
    case 'weekly':
      return `Every ${weekdayLabel(rule.weekday)} at ${timeLabel}`;
    case 'every_n_days':
      return `Every ${rule.intervalCount} day${rule.intervalCount === 1 ? '' : 's'} at ${timeLabel}`;
    default:
      return `Every day at ${timeLabel}`;
  }
}

export function getNextDueForBundle(
  bundle: ScheduledProtocolBundle,
  now = new Date()
): NextDueItem | null {
  if (bundle.protocol.status !== 'active') {
    return null;
  }

  const candidates = bundle.rules
    .filter((rule) => rule.isActive)
    .map((rule) => {
      const date = getNextOccurrenceDate(bundle.protocol, rule, now);
      return date
        ? {
            cadenceLabel: formatCadenceLabel(rule),
            scheduledDate: date,
            rule,
          }
        : null;
    })
    .filter((value): value is NonNullable<typeof value> => value !== null)
    .sort((left, right) => left.scheduledDate.getTime() - right.scheduledDate.getTime());

  const next = candidates[0];

  if (!next) {
    return null;
  }

  return {
    cadenceLabel: next.cadenceLabel,
    compoundName: bundle.compound?.displayName ?? null,
    doseLabel: formatDoseLabel(bundle.protocol),
    kind: bundle.protocol.kind,
    protocolId: bundle.protocol.id,
    protocolName: bundle.protocol.name,
    scheduledFor: next.scheduledDate.toISOString(),
    timeLabel: formatTimeOfDay(next.rule.timeOfDay ?? bundle.protocol.defaultTimeOfDay),
    whenLabel: formatWhenLabel(next.scheduledDate, now),
  };
}

export function getNextDueAcrossBundles(
  bundles: ScheduledProtocolBundle[],
  now = new Date()
): NextDueItem | null {
  return bundles
    .map((bundle) => getNextDueForBundle(bundle, now))
    .filter((item): item is NextDueItem => item !== null)
    .sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime())[0] ?? null;
}

function getNextOccurrenceDate(protocol: Protocol, rule: ProtocolRule, now: Date): Date | null {
  const timeOfDay = rule.timeOfDay ?? protocol.defaultTimeOfDay;

  if (!timeOfDay) {
    return null;
  }

  switch (rule.ruleType) {
    case 'weekly':
      return getNextWeeklyDate(protocol.startDate, rule.weekday, timeOfDay, now);
    case 'every_n_days':
      return getNextIntervalDate(rule.anchorDate ?? protocol.startDate, rule.intervalCount, timeOfDay, now);
    default:
      return getNextIntervalDate(rule.anchorDate ?? protocol.startDate, 1, timeOfDay, now);
  }
}

function getNextWeeklyDate(
  startDate: string,
  weekday: number | null,
  timeOfDay: string,
  now: Date
): Date | null {
  if (weekday === null) {
    return null;
  }

  const start = parseLocalDateTime(startDate, timeOfDay);
  const cursor = new Date(start);

  while (cursor.getDay() !== weekday) {
    cursor.setDate(cursor.getDate() + 1);
  }

  while (cursor.getTime() < now.getTime()) {
    cursor.setDate(cursor.getDate() + 7);
  }

  return cursor;
}

function getNextIntervalDate(
  anchorDate: string,
  intervalCount: number,
  timeOfDay: string,
  now: Date
): Date {
  const start = parseLocalDateTime(anchorDate, timeOfDay);

  if (start.getTime() >= now.getTime()) {
    return start;
  }

  const elapsedMs = now.getTime() - start.getTime();
  const intervalMs = intervalCount * DAY_MS;
  const completedIntervals = Math.floor(elapsedMs / intervalMs);
  const candidate = new Date(start.getTime() + completedIntervals * intervalMs);

  if (candidate.getTime() < now.getTime()) {
    return new Date(candidate.getTime() + intervalMs);
  }

  return candidate;
}

function parseLocalDateTime(dateValue: string, timeOfDay: string): Date {
  const [year, month, day] = dateValue.split('-').map(Number);
  const [hours, minutes] = timeOfDay.split(':').map(Number);

  return new Date(year, month - 1, day, hours, minutes, 0, 0);
}

function weekdayLabel(weekday: number | null): string {
  const labels = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return weekday === null ? 'day' : labels[weekday] ?? 'day';
}

function formatWhenLabel(value: Date, now: Date): string {
  const startOfNow = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfValue = new Date(value.getFullYear(), value.getMonth(), value.getDate());
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

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    weekday: 'short',
    hour: 'numeric',
    minute: '2-digit',
  }).format(value);
}

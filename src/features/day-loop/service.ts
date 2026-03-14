import { createIsoTimestamp } from '@/src/lib/database/id';
import { trackAnalyticsEvent } from '@/src/lib/analytics/service';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import { createAtlasRepositories, type AtlasRepositories } from '@/src/lib/database/repositories';
import type {
  CreateLogEventInput,
  LogEvent,
  Protocol,
  ProtocolChangeAuditEvent,
} from '@/src/lib/database/schemas';
import {
  formatTimeOfDay,
  generateProjectedOccurrences,
  getActiveRevisionSnapshot,
  type RevisionProjectedOccurrence,
  type ScheduledProtocolRevisionBundle,
} from '@/src/lib/schedule/protocol-revision-schedule';
import { getDoseDecrementForVial } from '@/src/features/inventory/math';
import { listProtocolRevisionBundles } from '@/src/features/protocols/bundles';

const DAY_MS = 24 * 60 * 60 * 1000;
const HORIZON_PAST_DAYS = 14;
const HORIZON_FUTURE_DAYS = 30;

export type GeneratedOccurrenceState =
  | 'completed'
  | 'next_due'
  | 'overdue'
  | 'rescheduled'
  | 'skipped'
  | 'upcoming';

export type GeneratedOccurrence = RevisionProjectedOccurrence & {
  originalOccurrenceId: string | null;
  resolvedBy: LogEvent | null;
  source: 'generated' | 'rescheduled';
  state: GeneratedOccurrenceState;
};

export type TodaySnapshot = {
  nextDue: GeneratedOccurrence | null;
  overdue: GeneratedOccurrence[];
  primaryProtocolId: string | null;
  protocolCount: number;
  upcoming: GeneratedOccurrence[];
};

export type TimelineFeedItem = {
  eventId: string;
  eventType:
    | 'logged_dose'
    | 'protocol_created'
    | 'protocol_changed'
    | 'rescheduled_dose'
    | 'skipped_dose';
  protocolId: string;
  protocolName: string;
  summary: string;
  timestamp: string;
};

export type TimelineFilters = {
  dateWindow: 'all' | 'last_30_days' | 'last_7_days';
  protocolId: string | 'all';
};

type OccurrenceBundle = ScheduledProtocolRevisionBundle & {
  logEvents: LogEvent[];
};

type ProtocolBundle = OccurrenceBundle & {
  auditEvents: ProtocolChangeAuditEvent[];
};

export type TodayActionInput = {
  action: 'mark_taken' | 'reschedule' | 'skip';
  notes?: string | null;
  occurrenceId: string;
  protocolId: string;
  scheduledFor: string;
  nextScheduledFor?: string;
  siteId?: string | null;
};

export async function getTodaySnapshot(now = new Date()): Promise<TodaySnapshot> {
  const bundles = await listProtocolBundles();
  const unresolved = buildUnresolvedOccurrences(bundles, now);

  return {
    nextDue: unresolved.find((occurrence) => occurrence.state === 'next_due') ?? null,
    overdue: unresolved.filter((occurrence) => occurrence.state === 'overdue'),
    primaryProtocolId: bundles[0]?.protocol.id ?? null,
    protocolCount: bundles.length,
    upcoming: unresolved.filter((occurrence) => occurrence.state === 'upcoming').slice(0, 3),
  };
}

export async function logTodayAction(input: TodayActionInput): Promise<LogEvent> {
  const client = await getAtlasDatabaseClient();

  const event = await client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const protocol = await repositories.protocols.getById(input.protocolId);

    if (!protocol) {
      throw new Error('Protocol not found.');
    }

    const bundle = await getProtocolRevisionBundleForInput(repositories, input.protocolId);
    const activeSnapshot = bundle
      ? getActiveRevisionSnapshot(bundle, new Date(input.scheduledFor))
      : null;
    const resolvedDoseAmount = activeSnapshot?.doseAmount ?? protocol.doseAmount;
    const resolvedDoseUnit = activeSnapshot?.doseUnit ?? protocol.doseUnit;
    const resolvedLinkedVialId = activeSnapshot?.linkedVialId ?? protocol.linkedVialId;

    const baseEvent: CreateLogEventInput = {
      eventType:
        input.action === 'mark_taken'
          ? 'completed'
          : input.action === 'skip'
            ? 'skipped'
            : 'rescheduled',
      effectiveAt:
        input.action === 'reschedule'
          ? input.nextScheduledFor ?? input.scheduledFor
          : createIsoTimestamp(),
      notes: input.notes ?? null,
      occurrenceId: input.occurrenceId,
      protocolId: input.protocolId,
      quantity: input.action === 'mark_taken' ? resolvedDoseAmount : null,
      quantityUnit: input.action === 'mark_taken' ? resolvedDoseUnit : null,
      siteId: input.action === 'mark_taken' ? input.siteId ?? null : null,
      source: 'user' as const,
      vialId: input.action === 'mark_taken' ? resolvedLinkedVialId : null,
    };

    const nextEvent = await repositories.logEvents.create(baseEvent);

    if (input.action === 'mark_taken' && resolvedLinkedVialId) {
      const vial = await repositories.vials.getById(resolvedLinkedVialId);

      if (vial) {
        const decrement = getDoseDecrementForVial(
          {
            ...protocol,
            doseAmount: resolvedDoseAmount,
            doseUnit: resolvedDoseUnit,
            linkedVialId: resolvedLinkedVialId,
          },
          vial
        );

        if (decrement) {
          await repositories.vials.update({
            id: vial.id,
            remainingQuantity: Math.max(0, vial.remainingQuantity - decrement.amount),
          });
        }
      }
    }

    return nextEvent;
  });

  if (input.action === 'mark_taken') {
    trackAnalyticsEvent('dose_logged', {
      eventId: event.id,
      protocolId: input.protocolId,
      source: 'today',
    });
  }

  return event;
}

export async function getTimelineFeed(
  filters: TimelineFilters,
  now = new Date()
): Promise<TimelineFeedItem[]> {
  const bundles = await listProtocolBundles();

  const items = [
    ...bundles.map<TimelineFeedItem>((bundle) => ({
      eventId: `protocol_created:${bundle.protocol.id}`,
      eventType: 'protocol_created',
      protocolId: bundle.protocol.id,
      protocolName: bundle.protocol.name,
      summary: `Created protocol ${bundle.protocol.name}`,
      timestamp: bundle.protocol.createdAt,
    })),
    ...bundles.flatMap((bundle) =>
      bundle.auditEvents.map<TimelineFeedItem>((event) => ({
        eventId: event.id,
        eventType: 'protocol_changed',
        protocolId: bundle.protocol.id,
        protocolName: bundle.protocol.name,
        summary: event.summary,
        timestamp: event.createdAt,
      }))
    ),
    ...bundles.flatMap((bundle) =>
      bundle.logEvents
        .filter(
          (event) =>
            event.eventType === 'completed' ||
            event.eventType === 'skipped' ||
            event.eventType === 'rescheduled'
        )
        .map<TimelineFeedItem>((event) => ({
          eventId: event.id,
          eventType:
            event.eventType === 'completed'
              ? 'logged_dose'
              : event.eventType === 'skipped'
                ? 'skipped_dose'
                : 'rescheduled_dose',
          protocolId: bundle.protocol.id,
          protocolName: bundle.protocol.name,
          summary: buildTimelineSummary(bundle.protocol, event),
          timestamp: event.loggedAt,
        }))
    ),
  ]
    .filter((item) => matchesProtocolFilter(item, filters.protocolId))
    .filter((item) => matchesDateFilter(item.timestamp, filters.dateWindow, now))
    .sort((left, right) => new Date(right.timestamp).getTime() - new Date(left.timestamp).getTime());

  return items;
}

export function buildUnresolvedOccurrences(
  bundles: OccurrenceBundle[],
  now = new Date()
): GeneratedOccurrence[] {
  const occurrences = bundles.flatMap((bundle) => buildOccurrencesForBundle(bundle, now));
  const unresolved = occurrences.filter(
    (occurrence) =>
      occurrence.state === 'next_due' ||
      occurrence.state === 'overdue' ||
      occurrence.state === 'upcoming'
  );

  const futureUnresolved = unresolved
    .filter((occurrence) => new Date(occurrence.scheduledFor).getTime() >= now.getTime())
    .sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime());

  const firstFutureId = futureUnresolved[0]?.id ?? null;

  return unresolved
    .map((occurrence) =>
      firstFutureId !== null && occurrence.id === firstFutureId
        ? { ...occurrence, state: 'next_due' as const }
        : occurrence
    )
    .sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime());
}

export function buildOccurrencesForBundle(
  bundle: OccurrenceBundle,
  now = new Date()
): GeneratedOccurrence[] {
  const horizonStart = new Date(now.getTime() - HORIZON_PAST_DAYS * DAY_MS);
  const horizonEnd = new Date(now.getTime() + HORIZON_FUTURE_DAYS * DAY_MS);
  const baseOccurrences = generateProjectedOccurrences(bundle, {
    end: horizonEnd,
    now,
    start: horizonStart,
  }).sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime());

  const logsByOccurrence = groupLogsByOccurrence(bundle.logEvents);
  const resolved: GeneratedOccurrence[] = [];

  for (const occurrence of baseOccurrences) {
    resolveOccurrenceChain(
      {
        ...occurrence,
        originalOccurrenceId: null,
        resolvedBy: null,
        source: 'generated',
        state: 'upcoming',
      },
      logsByOccurrence,
      now,
      resolved
    );
  }

  return resolved;
}

async function listProtocolBundles(): Promise<ProtocolBundle[]> {
  const repositories = await getAtlasRepositories();
  const [auditEvents, bundles] = await Promise.all([
    repositories.protocolChangeAudits.listAll(),
    listProtocolRevisionBundles({
      includeLogs: true,
      repositories,
    }),
  ]);

  return bundles.map((bundle) => ({
    ...bundle,
    auditEvents: auditEvents.filter((event) => event.protocolId === bundle.protocol.id),
    logEvents: bundle.logEvents ?? [],
  }));
}

function resolveOccurrenceChain(
  occurrence: GeneratedOccurrence,
  logsByOccurrence: Map<string, LogEvent[]>,
  now: Date,
  resolved: GeneratedOccurrence[]
) {
  const logs = logsByOccurrence.get(occurrence.id) ?? [];
  const latestAction = logs[0] ?? null;

  if (!latestAction) {
    resolved.push({
      ...occurrence,
      resolvedBy: null,
      state: new Date(occurrence.scheduledFor).getTime() < now.getTime() ? 'overdue' : 'upcoming',
    });
    return;
  }

  if (latestAction.eventType === 'completed' || latestAction.eventType === 'skipped') {
    resolved.push({
      ...occurrence,
      resolvedBy: latestAction,
      state: latestAction.eventType === 'completed' ? 'completed' : 'skipped',
    });
    return;
  }

  if (latestAction.eventType === 'rescheduled') {
    resolved.push({
      ...occurrence,
      resolvedBy: latestAction,
      state: 'rescheduled',
    });

    const movedOccurrence: GeneratedOccurrence = {
      ...occurrence,
      id: `rescheduled:${latestAction.id}`,
      originalOccurrenceId: occurrence.id,
      resolvedBy: null,
      scheduledFor: latestAction.effectiveAt,
      source: 'rescheduled',
      state: new Date(latestAction.effectiveAt).getTime() < now.getTime() ? 'overdue' : 'upcoming',
      timeLabel: formatTimeOfDay(extractTimeOfDay(latestAction.effectiveAt)),
      whenLabel: formatTimelineDateLabel(new Date(latestAction.effectiveAt), now),
    };

    resolveOccurrenceChain(movedOccurrence, logsByOccurrence, now, resolved);
  }
}

function groupLogsByOccurrence(logEvents: LogEvent[]) {
  return logEvents.reduce<Map<string, LogEvent[]>>((map, event) => {
    if (!event.occurrenceId) {
      return map;
    }

    const existing = map.get(event.occurrenceId) ?? [];
    existing.push(event);
    existing.sort(
      (left, right) => new Date(right.loggedAt).getTime() - new Date(left.loggedAt).getTime()
    );
    map.set(event.occurrenceId, existing);
    return map;
  }, new Map());
}

function buildTimelineSummary(protocol: Protocol, event: LogEvent): string {
  switch (event.eventType) {
    case 'completed':
      return `Logged ${protocol.name} as taken`;
    case 'skipped':
      return `Skipped ${protocol.name}`;
    case 'rescheduled':
      return `Rescheduled ${protocol.name} to ${formatTimelineDateLabel(
        new Date(event.effectiveAt),
        new Date(event.loggedAt)
      )}`;
    default:
      return protocol.name;
  }
}

function matchesProtocolFilter(item: TimelineFeedItem, protocolId: string | 'all') {
  return protocolId === 'all' || item.protocolId === protocolId;
}

function matchesDateFilter(timestamp: string, dateWindow: TimelineFilters['dateWindow'], now: Date) {
  if (dateWindow === 'all') {
    return true;
  }

  const days = dateWindow === 'last_7_days' ? 7 : 30;
  return new Date(timestamp).getTime() >= now.getTime() - days * DAY_MS;
}

function formatTimelineDateLabel(value: Date, now: Date) {
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

function extractTimeOfDay(isoTimestamp: string) {
  const date = new Date(isoTimestamp);
  const hours = `${date.getHours()}`.padStart(2, '0');
  const minutes = `${date.getMinutes()}`.padStart(2, '0');
  return `${hours}:${minutes}`;
}

async function getProtocolRevisionBundleForInput(
  repositories: AtlasRepositories,
  protocolId: string
) {
  const bundles = await listProtocolRevisionBundles({
    includeLogs: false,
    repositories,
  });

  return bundles.find((bundle) => bundle.protocol.id === protocolId) ?? null;
}

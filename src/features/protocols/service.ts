import { createAtlasRepositories } from '@/src/lib/database/repositories';
import type { Compound, Protocol } from '@/src/lib/database/schemas';
import { trackAnalyticsEvent } from '@/src/lib/analytics/service';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import {
  formatCadenceLabel,
  getActiveRevisionSnapshot,
  getNextProjectedOccurrence,
  type RevisionProjectedOccurrence,
} from '@/src/lib/schedule/protocol-revision-schedule';
import { describeProtocolCard } from '@/src/features/protocols/helpers';
import { listProtocolRevisionBundles } from '@/src/features/protocols/bundles';
import type { ProtocolWizardFormValues } from '@/src/features/protocols/schema';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';

export type ProtocolListItem = {
  cadenceLabel: string;
  compoundName: string | null;
  doseLabel: string | null;
  id: string;
  kind: Protocol['kind'];
  kindLabel: string;
  nextDue: RevisionProjectedOccurrence | null;
  notes: string | null;
  status: Protocol['status'];
  title: string;
};

export type TodayProtocolSummary = {
  nextDue: RevisionProjectedOccurrence | null;
  protocolCount: number;
};

export async function listAvailableCompounds(): Promise<Compound[]> {
  const repositories = await getAtlasRepositories();
  return repositories.compounds.listAll();
}

export async function createProtocolFromWizard(values: ProtocolWizardFormValues) {
  const client = await getAtlasDatabaseClient();

  const created = await client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    return createProtocolInRepositories(repositories, values);
  });

  trackAnalyticsEvent('protocol_created', {
    kind: created.protocol.kind,
    protocolId: created.protocol.id,
    scheduleType: values.scheduleType,
  });

  return created;
}

export async function listProtocolListItems(now = new Date()): Promise<ProtocolListItem[]> {
  const bundles = await listProtocolRevisionBundles();

  return bundles.map((bundle) => {
    const activeSnapshot = getActiveRevisionSnapshot(bundle, now);
    const summary = describeProtocolCard({
      defaultTimeOfDay:
        activeSnapshot.revision?.defaultTimeOfDay ?? bundle.protocol.defaultTimeOfDay,
      doseAmount: activeSnapshot.doseAmount ?? bundle.protocol.doseAmount,
      doseUnit: activeSnapshot.doseUnit ?? bundle.protocol.doseUnit,
      kind: bundle.protocol.kind,
      rule: activeSnapshot.activeRule
        ? {
            id: activeSnapshot.activeRule.id,
            protocolId: bundle.protocol.id,
            ruleType: activeSnapshot.activeRule.ruleType,
            intervalCount: activeSnapshot.activeRule.intervalCount,
            weekday: activeSnapshot.activeRule.weekday,
            timeOfDay: activeSnapshot.activeRule.timeOfDay,
            anchorDate: activeSnapshot.activeRule.anchorDate,
            isActive: true,
            createdAt: activeSnapshot.activeRule.createdAt,
            updatedAt: activeSnapshot.activeRule.updatedAt,
          }
        : null,
    });

    return {
      cadenceLabel:
        activeSnapshot.activeRule && activeSnapshot.revision
          ? formatCadenceLabel(
              activeSnapshot.activeRule,
              activeSnapshot.revision.defaultTimeOfDay
            )
          : summary.cadence,
      compoundName: bundle.compound?.displayName ?? null,
      doseLabel: activeSnapshot.doseLabel ?? summary.dose,
      id: bundle.protocol.id,
      kind: bundle.protocol.kind,
      kindLabel: summary.kindLabel,
      nextDue: getNextProjectedOccurrence(bundle, now),
      notes: bundle.protocol.notes,
      status: bundle.protocol.status,
      title: bundle.protocol.name,
    };
  });
}

export async function getTodayProtocolSummary(now = new Date()): Promise<TodayProtocolSummary> {
  const bundles = await listProtocolRevisionBundles();

  return {
    nextDue:
      bundles
        .map((bundle) => getNextProjectedOccurrence(bundle, now))
        .filter((item): item is RevisionProjectedOccurrence => item !== null)
        .sort((left, right) => new Date(left.scheduledFor).getTime() - new Date(right.scheduledFor).getTime())[0] ??
      null,
    protocolCount: bundles.length,
  };
}

export { createProtocolInRepositories } from '@/src/features/protocols/persistence';

import { createAtlasRepositories } from '@/src/lib/database/repositories';
import type { AtlasRepositories } from '@/src/lib/database/repositories';
import { trackAnalyticsEventOncePerSession } from '@/src/lib/analytics/service';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import type { Protocol, Site, Vial } from '@/src/lib/database/schemas';
import {
  getActiveRevisionSnapshot,
  getNextProjectedOccurrence,
  type ScheduledProtocolRevisionBundle,
} from '@/src/lib/schedule/protocol-revision-schedule';
import { describeProtocolCard } from '@/src/features/protocols/helpers';
import { listProtocolRevisionBundles } from '@/src/features/protocols/bundles';
import {
  formatQuantity,
  getDoseDecrementForVial,
  getProjectedDepletionDate,
} from '@/src/features/inventory/math';
import {
  inventoryCorrectionInputSchema,
  saveSiteInputSchema,
  saveVialInputSchema,
  updateProtocolInventorySettingsInputSchema,
  type InventoryCorrectionInput,
  type SaveSiteInput,
  type SaveVialInput,
  type UpdateProtocolInventorySettingsInput,
} from '@/src/features/inventory/schema';

type InventoryRepositories = Pick<
  AtlasRepositories,
  'compounds' | 'logEvents' | 'protocolRevisionRules' | 'protocolRevisions' | 'protocols' | 'sites' | 'vials'
>;

type ProtocolBundle = {
  protocol: Protocol;
  snapshot: ReturnType<typeof getActiveRevisionSnapshot>;
} & ScheduledProtocolRevisionBundle;

export type InventoryVialListItem = {
  adjustmentProtocolId: string | null;
  autoDecrementLabel: string | null;
  compoundName: string | null;
  id: string;
  isLowStock: boolean;
  label: string;
  linkedProtocolName: string | null;
  lowStockLabel: string | null;
  projectedDepletionLabel: string | null;
  quantityLabel: string;
  quantityUnit: string;
  remainingQuantity: number;
  startingQuantity: number;
};

export type InventoryProtocolSettingItem = {
  cadenceLabel: string;
  doseLabel: string | null;
  id: string;
  kindLabel: string;
  linkedVialId: string | null;
  linkedVialLabel: string | null;
  name: string;
  siteRotationEnabled: boolean;
  siteTrackingEnabled: boolean;
};

export type InventorySnapshot = {
  protocolSettings: InventoryProtocolSettingItem[];
  protocols: { id: string; name: string }[];
  sites: Site[];
  vials: InventoryVialListItem[];
};

export type ProtocolSiteOptions = {
  protocol: Protocol;
  sites: Site[];
  suggestedSiteId: string | null;
};

export async function getInventorySnapshot(now = new Date()): Promise<InventorySnapshot> {
  const repositories = await getAtlasRepositories();
  const [compounds, protocols, sites, vials] = await Promise.all([
    repositories.compounds.listAll(),
    repositories.protocols.listAll(),
    repositories.sites.listAvailable(),
    repositories.vials.listAll(),
  ]);

  const bundles = await listProtocolBundles(repositories, protocols, now);

  const protocolSettings = bundles.map(({ protocol, snapshot }) => {
    const summary = describeProtocolCard({
      defaultTimeOfDay: snapshot.revision?.defaultTimeOfDay ?? protocol.defaultTimeOfDay,
      doseAmount: snapshot.doseAmount ?? protocol.doseAmount,
      doseUnit: snapshot.doseUnit ?? protocol.doseUnit,
      kind: protocol.kind,
      rule: snapshot.activeRule
        ? {
            id: snapshot.activeRule.id,
            protocolId: protocol.id,
            ruleType: snapshot.activeRule.ruleType,
            intervalCount: snapshot.activeRule.intervalCount,
            weekday: snapshot.activeRule.weekday,
            timeOfDay: snapshot.activeRule.timeOfDay,
            anchorDate: snapshot.activeRule.anchorDate,
            isActive: true,
            createdAt: snapshot.activeRule.createdAt,
            updatedAt: snapshot.activeRule.updatedAt,
          }
        : null,
    });
    const linkedVial = vials.find((item) => item.id === snapshot.linkedVialId) ?? null;

    return {
      cadenceLabel: summary.cadence,
      doseLabel: snapshot.doseLabel ?? summary.dose,
      id: protocol.id,
      kindLabel: summary.kindLabel,
      linkedVialId: snapshot.linkedVialId,
      linkedVialLabel: linkedVial?.label ?? null,
      name: protocol.name,
      siteRotationEnabled: protocol.siteRotationEnabled,
      siteTrackingEnabled: protocol.siteTrackingEnabled,
    };
  });

  const vialItems = vials.map((vial) => {
    const primaryProtocol =
      bundles.find(({ snapshot }) => snapshot.linkedVialId === vial.id)?.protocol ??
      (vial.protocolId ? protocols.find((protocol) => protocol.id === vial.protocolId) ?? null : null);
    const compoundName =
      compounds.find((compound) => compound.id === vial.compoundId)?.displayName ??
      (primaryProtocol ? primaryProtocol.name : null);
    const bundle = primaryProtocol
      ? bundles.find((item) => item.protocol.id === primaryProtocol.id) ?? null
      : null;
    const nextDue = bundle ? getNextProjectedOccurrence(bundle, now) : null;
    const depletionAt =
      primaryProtocol && bundle
        ? getProjectedDepletionDate({
          nextScheduledFor: nextDue?.scheduledFor ?? null,
            protocol: {
              ...primaryProtocol,
              doseAmount: bundle.snapshot.doseAmount ?? primaryProtocol.doseAmount,
              doseUnit: bundle.snapshot.doseUnit ?? primaryProtocol.doseUnit,
            },
            rule: bundle.snapshot.activeRule,
            vial,
          })
        : null;
    const decrement =
      primaryProtocol && bundle
        ? getDoseDecrementForVial(
            {
              ...primaryProtocol,
              doseAmount: bundle.snapshot.doseAmount ?? primaryProtocol.doseAmount,
              doseUnit: bundle.snapshot.doseUnit ?? primaryProtocol.doseUnit,
            },
            vial
          )
        : null;
    const isLowStock =
      vial.lowStockThreshold !== null && vial.remainingQuantity <= vial.lowStockThreshold;

    if (isLowStock) {
      trackAnalyticsEventOncePerSession(`low-stock:${vial.id}`, 'low_stock_seen', {
        protocolId: primaryProtocol?.id ?? null,
        vialId: vial.id,
      });
    }

    return {
      adjustmentProtocolId: primaryProtocol?.id ?? vial.protocolId ?? null,
      autoDecrementLabel: decrement
        ? `Auto-decrements ${formatQuantity(decrement.amount, decrement.unit)} per taken log`
        : null,
      compoundName,
      id: vial.id,
      isLowStock,
      label: vial.label,
      linkedProtocolName: primaryProtocol?.name ?? null,
      lowStockLabel:
        vial.lowStockThreshold !== null
          ? `Low stock at ${formatQuantity(vial.lowStockThreshold, vial.quantityUnit)}`
          : null,
      projectedDepletionLabel: depletionAt
        ? `Projected depletion ${formatDateLabel(new Date(depletionAt))}`
        : null,
      quantityLabel: `${formatQuantity(vial.remainingQuantity, vial.quantityUnit)} remaining of ${formatQuantity(
        vial.startingQuantity,
        vial.quantityUnit
      )}`,
      quantityUnit: vial.quantityUnit,
      remainingQuantity: vial.remainingQuantity,
      startingQuantity: vial.startingQuantity,
    };
  });

  return {
    protocolSettings,
    protocols: protocols.map((protocol) => ({ id: protocol.id, name: protocol.name })),
    sites,
    vials: vialItems,
  };
}

export async function saveVial(input: SaveVialInput): Promise<Vial> {
  const parsed = saveVialInputSchema.parse(input);
  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const vial = await repositories.vials.create({
      compoundId: parsed.compoundId ?? null,
      concentrationUnit: parsed.concentrationUnit ?? null,
      concentrationValue: parsed.concentrationValue ?? null,
      expiresAt: parsed.expiresAt ?? null,
      label: parsed.label,
      lowStockThreshold: parsed.lowStockThreshold ?? null,
      openedAt: parsed.openedAt ?? null,
      protocolId: parsed.protocolId ?? null,
      quantityUnit: parsed.quantityUnit,
      remainingQuantity: parsed.remainingQuantity,
      startingQuantity: parsed.startingQuantity,
      volumeMl: parsed.volumeMl ?? null,
    });

    if (parsed.protocolId) {
      await repositories.protocols.update({
        id: parsed.protocolId,
        linkedVialId: vial.id,
      });
    }

    return vial;
  });
}

export async function deleteVial(id: string): Promise<boolean> {
  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const vial = await repositories.vials.getById(id);

    if (!vial) {
      return false;
    }

    const linkedProtocols = (await repositories.protocols.listAll()).filter(
      (protocol) => protocol.linkedVialId === vial.id
    );

    for (const protocol of linkedProtocols) {
      await repositories.protocols.update({
        id: protocol.id,
        linkedVialId: null,
      });
    }

    return repositories.vials.delete(id);
  });
}

export async function updateProtocolInventorySettings(
  input: UpdateProtocolInventorySettingsInput
): Promise<Protocol | null> {
  const parsed = updateProtocolInventorySettingsInputSchema.parse(input);
  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const existing = await repositories.protocols.getById(parsed.protocolId);

    if (!existing) {
      return null;
    }

    if (existing.linkedVialId && existing.linkedVialId !== parsed.linkedVialId) {
      const previousVial = await repositories.vials.getById(existing.linkedVialId);
      if (previousVial?.protocolId === existing.id) {
        await repositories.vials.update({
          id: previousVial.id,
          protocolId: null,
        });
      }
    }

    if (parsed.linkedVialId) {
      const nextVial = await repositories.vials.getById(parsed.linkedVialId);
      if (nextVial) {
        await repositories.vials.update({
          id: nextVial.id,
          protocolId: existing.id,
        });
      }
    }

    return repositories.protocols.update({
      id: parsed.protocolId,
      linkedVialId: parsed.linkedVialId,
      siteRotationEnabled: parsed.siteRotationEnabled,
      siteTrackingEnabled: parsed.siteTrackingEnabled,
    });
  });
}

export async function applyInventoryCorrection(
  input: InventoryCorrectionInput
): Promise<{ eventId: string | null; vial: Vial }> {
  const parsed = inventoryCorrectionInputSchema.parse(input);
  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const vial = await repositories.vials.getById(parsed.vialId);

    if (!vial) {
      throw new Error('Vial not found.');
    }

    const linkedProtocol =
      (vial.protocolId ? await repositories.protocols.getById(vial.protocolId) : null) ??
      (await repositories.protocols.listAll()).find((protocol) => protocol.linkedVialId === vial.id) ??
      null;

    const updatedVial = await repositories.vials.update({
      id: vial.id,
      remainingQuantity: parsed.nextRemainingQuantity,
    });

    if (!updatedVial) {
      throw new Error('Vial update failed.');
    }

    if (!linkedProtocol) {
      return {
        eventId: null,
        vial: updatedVial,
      };
    }

    const event = await repositories.logEvents.create({
      effectiveAt: createIsoTimestamp(),
      eventType: 'inventory_adjustment',
      notes: parsed.notes ?? 'Manual inventory correction.',
      protocolId: linkedProtocol.id,
      quantity: parsed.nextRemainingQuantity - vial.remainingQuantity,
      quantityUnit: vial.quantityUnit,
      source: 'user',
      vialId: vial.id,
    });

    return {
      eventId: event.id,
      vial: updatedVial,
    };
  });
}

export async function saveSite(input: SaveSiteInput): Promise<Site> {
  const parsed = saveSiteInputSchema.parse(input);
  const repositories = await getAtlasRepositories();

  if (parsed.id) {
    const updated = await repositories.sites.update({
      archivedAt: parsed.archivedAt ?? null,
      bodyArea: parsed.bodyArea ?? null,
      id: parsed.id,
      name: parsed.name,
      notes: parsed.notes ?? null,
    });

    if (!updated) {
      throw new Error('Site not found.');
    }

    return updated;
  }

  return repositories.sites.create({
    archivedAt: parsed.archivedAt ?? null,
    bodyArea: parsed.bodyArea ?? null,
    name: parsed.name,
    notes: parsed.notes ?? null,
  });
}

export async function getProtocolSiteOptions(protocolId: string): Promise<ProtocolSiteOptions> {
  const repositories = await getAtlasRepositories();
  const [protocol, sites, logEvents] = await Promise.all([
    repositories.protocols.getById(protocolId),
    repositories.sites.listAvailable(),
    repositories.logEvents.listByProtocolId(protocolId),
  ]);

  if (!protocol) {
    throw new Error('Protocol not found.');
  }

  const lastUsedSiteId =
    logEvents.find((event) => event.eventType === 'completed' && event.siteId)?.siteId ?? null;
  let suggestedSiteId: string | null = null;

  if (sites.length > 0) {
    if (protocol.siteRotationEnabled && lastUsedSiteId) {
      const lastIndex = sites.findIndex((site) => site.id === lastUsedSiteId);
      suggestedSiteId = sites[(lastIndex + 1) % sites.length]?.id ?? sites[0]?.id ?? null;
    } else {
      suggestedSiteId = lastUsedSiteId ?? sites[0]?.id ?? null;
    }
  }

  return {
    protocol,
    sites,
    suggestedSiteId,
  };
}

async function listProtocolBundles(
  repositories: InventoryRepositories,
  protocols: Protocol[],
  now: Date
): Promise<ProtocolBundle[]> {
  const bundles = await listProtocolRevisionBundles({
    includeLogs: false,
    repositories: repositories as AtlasRepositories,
  });

  return protocols.map((protocol) => {
    const bundle = bundles.find((item) => item.protocol.id === protocol.id) ?? {
      compound: null,
      protocol,
      revisions: [],
    };

    return {
      ...bundle,
      protocol,
      snapshot: getActiveRevisionSnapshot(bundle, now),
    };
  });
}

function formatDateLabel(value: Date) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(value);
}

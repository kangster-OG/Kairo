import CryptoJS from 'crypto-js';
import * as ExpoCrypto from 'expo-crypto';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';

import { trackAnalyticsEvent } from '@/src/lib/analytics/service';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import {
  createAtlasRepositories,
  type AtlasRepositories,
} from '@/src/lib/database/repositories';
import type {
  PrivacyProfile,
  PrivacyRenderMode,
  ProtocolAlias,
  SensitiveActionAuditEvent,
} from '@/src/lib/database/schemas';
import { getTimelineFeed, getTodaySnapshot } from '@/src/features/day-loop/service';
import { getInsightsSnapshot } from '@/src/features/insights/service';
import { getInventorySnapshot } from '@/src/features/inventory/service';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { listProtocolListItems } from '@/src/features/protocols/service';
import {
  formatProtocolDisplayName,
  formatSensitiveAuditSummary,
  formatTimelineItemSummary,
  formatTodayOccurrenceLabel,
  formatVialDisplayName,
  indexProtocolAliases,
  resolvePrivacyRenderMode,
} from '@/src/features/trust-vault/privacy';
import { selectiveShareInputSchema, type SelectiveShareInput } from '@/src/features/trust-vault/schema';
import { runSensitiveActionGate, type BiometricGateClient } from '@/src/features/trust-vault/biometrics';

type TrustVaultDependencies = {
  biometricClient?: BiometricGateClient;
  repositories?: AtlasRepositories;
};

type TrustVaultProtocolItem = {
  aliasCompoundLabel: string;
  aliasLabel: string;
  canonicalCompoundName: string | null;
  canonicalName: string;
  id: string;
  kind: string;
};

export type TrustVaultSnapshot = {
  aliases: ProtocolAlias[];
  audits: (SensitiveActionAuditEvent & { summaryLabel: string })[];
  effectiveRenderMode: PrivacyRenderMode;
  profile: PrivacyProfile;
  protocols: TrustVaultProtocolItem[];
};

type SelectiveSharePayload = {
  generatedAt: string;
  notes: string[];
  renderMode: PrivacyRenderMode;
  scopeKind: SelectiveShareInput['scopeKind'];
  sections: Record<string, unknown>;
  staticSnapshot: true;
};

export type SelectiveSharePreview = {
  contentPreview: { label: string; value: string }[];
  counts: Record<string, number>;
  payload: SelectiveSharePayload;
  renderMode: PrivacyRenderMode;
  scopeLabel: string;
};

export type SelectiveShareBundleResult = {
  fileName: string;
  fileUri: string;
  manifest: Record<string, unknown>;
  shared: boolean;
};

export async function getTrustVaultSnapshot(
  dependencies: TrustVaultDependencies = {}
): Promise<TrustVaultSnapshot> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const onboardingPrivacy = useOnboardingStore.getState().draft.privacy;
  const [aliases, audits, compounds, profile, protocols] = await Promise.all([
    repositories.protocolAliases.listAllActive(),
    repositories.sensitiveActionAudits.listAll(),
    repositories.compounds.listAll(),
    repositories.privacyProfiles.get(),
    repositories.protocols.listAll(),
  ]);
  const aliasLookup = indexProtocolAliases(aliases);
  const compoundLookup = compounds.reduce<Record<string, string>>((result, compound) => {
    result[compound.id] = compound.displayName;
    return result;
  }, {});
  const effectiveRenderMode = resolvePrivacyRenderMode(onboardingPrivacy, profile);

  return {
    aliases,
    audits: audits.map((event) => ({
      ...event,
      summaryLabel: formatSensitiveAuditSummary(
        event.eventType,
        onboardingPrivacy,
        profile,
        event.protocolId ? aliasLookup[event.protocolId]?.aliasLabel ?? null : null
      ),
    })),
    effectiveRenderMode,
    profile,
    protocols: protocols.map((protocol) => ({
      aliasCompoundLabel: aliasLookup[protocol.id]?.aliasCompoundLabel ?? '',
      aliasLabel: aliasLookup[protocol.id]?.aliasLabel ?? '',
      canonicalCompoundName: protocol.compoundId ? compoundLookup[protocol.compoundId] ?? null : null,
      canonicalName: protocol.name,
      id: protocol.id,
      kind: protocol.kind,
    })),
  };
}

export async function updateTrustVaultProfile(
  input: Partial<
    Pick<
      PrivacyProfile,
      | 'aliasModeEnabled'
      | 'biometricGateMode'
      | 'biometricLockEnabled'
      | 'exportAliasByDefault'
      | 'shareAliasByDefault'
    >
  >,
  dependencies: TrustVaultDependencies = {}
) {
  if (dependencies.repositories) {
    const updated = await dependencies.repositories.privacyProfiles.update({
      ...input,
      id: 'default',
    });

    await dependencies.repositories.sensitiveActionAudits.create({
      eventType:
        input.biometricGateMode !== undefined || input.biometricLockEnabled !== undefined
          ? 'biometric_lock_changed'
          : 'privacy_mode_changed',
      payloadJson: JSON.stringify(input),
      protocolId: null,
      renderMode: updated.aliasModeEnabled ? 'alias' : null,
      scopeKind: null,
      surface: 'trust_vault',
    });

    return updated;
  }

  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const updated = await repositories.privacyProfiles.update({
      ...input,
      id: 'default',
    });

    await repositories.sensitiveActionAudits.create({
      eventType:
        input.biometricGateMode !== undefined || input.biometricLockEnabled !== undefined
          ? 'biometric_lock_changed'
          : 'privacy_mode_changed',
      payloadJson: JSON.stringify(input),
      protocolId: null,
      renderMode: updated.aliasModeEnabled ? 'alias' : null,
      scopeKind: null,
      surface: 'trust_vault',
    });

    return updated;
  });
}

export async function saveProtocolAlias(
  input: {
    aliasCompoundLabel: string | null;
    aliasLabel: string;
    protocolId: string;
  },
  dependencies: TrustVaultDependencies = {}
) {
  if (dependencies.repositories) {
    const alias = await dependencies.repositories.protocolAliases.upsert({
      aliasCompoundLabel: input.aliasCompoundLabel,
      aliasLabel: input.aliasLabel.trim(),
      protocolId: input.protocolId,
    });

    await dependencies.repositories.sensitiveActionAudits.create({
      eventType: 'alias_changed',
      payloadJson: JSON.stringify({
        aliasCompoundLabel: alias.aliasCompoundLabel,
        aliasLabel: alias.aliasLabel,
      }),
      protocolId: input.protocolId,
      renderMode: 'alias',
      scopeKind: null,
      surface: 'trust_vault',
    });

    return alias;
  }

  const client = await getAtlasDatabaseClient();

  return client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const alias = await repositories.protocolAliases.upsert({
      aliasCompoundLabel: input.aliasCompoundLabel,
      aliasLabel: input.aliasLabel.trim(),
      protocolId: input.protocolId,
    });

    await repositories.sensitiveActionAudits.create({
      eventType: 'alias_changed',
      payloadJson: JSON.stringify({
        aliasCompoundLabel: alias.aliasCompoundLabel,
        aliasLabel: alias.aliasLabel,
      }),
      protocolId: input.protocolId,
      renderMode: 'alias',
      scopeKind: null,
      surface: 'trust_vault',
    });

    return alias;
  });
}

export async function unlockTrustVault(
  dependencies: TrustVaultDependencies = {}
) {
  const repositories = await resolveRepositories(dependencies.repositories);
  const profile = await repositories.privacyProfiles.get();
  const gateResult = await runSensitiveActionGate({
    client: dependencies.biometricClient,
    gateMode: profile.biometricGateMode,
    promptMessage: 'Unlock Trust Vault',
    requiresLock: profile.biometricLockEnabled,
  });

  if (gateResult.granted && gateResult.reason === 'granted') {
    await repositories.sensitiveActionAudits.create({
      eventType: 'vault_unlocked',
      payloadJson: JSON.stringify(gateResult),
      protocolId: null,
      renderMode: profile.aliasModeEnabled ? 'alias' : null,
      scopeKind: null,
      surface: 'trust_vault',
    });
  }

  return gateResult;
}

export async function buildSelectiveSharePreview(
  input: Omit<SelectiveShareInput, 'passphrase' | 'shareAfterCreate'> & {
    passphrase?: string;
    previewGeneratedAt?: string;
    shareAfterCreate?: boolean;
  },
  dependencies: TrustVaultDependencies = {}
): Promise<SelectiveSharePreview> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const parsed = selectiveShareInputSchema.parse({
    passphrase: input.passphrase ?? 'temporary-passphrase',
    shareAfterCreate: input.shareAfterCreate ?? false,
    ...input,
  });
  const base = await buildSharePayload(parsed, repositories, {
    generatedAt: input.previewGeneratedAt,
  });

  return {
    contentPreview: buildContentPreview(base.payload),
    counts: base.counts,
    payload: base.payload,
    renderMode: parsed.renderMode,
    scopeLabel: formatScopeLabel(parsed.scopeKind),
  };
}

export async function createSelectiveShareBundle(
  input: SelectiveShareInput & { previewGeneratedAt?: string },
  dependencies: TrustVaultDependencies = {}
): Promise<SelectiveShareBundleResult> {
  const parsed = selectiveShareInputSchema.parse(input);
  const repositories = await resolveRepositories(dependencies.repositories);
  const profile = await repositories.privacyProfiles.get();
  const gate = await runSensitiveActionGate({
    client: dependencies.biometricClient,
    gateMode: profile.biometricGateMode,
    promptMessage: 'Authorize private share bundle',
    requiresLock: profile.biometricLockEnabled,
  });

  if (!gate.granted) {
    throw new Error('Atlas could not authorize this private share bundle.');
  }

  const preview = await buildSelectiveSharePreview(
    {
      ...parsed,
      previewGeneratedAt: input.previewGeneratedAt,
    },
    {
      repositories,
    }
  );
  const payloadJson = JSON.stringify(preview.payload, null, 2);
  const payloadSha256 = await ExpoCrypto.digestStringAsync(
    ExpoCrypto.CryptoDigestAlgorithm.SHA256,
    payloadJson
  );
  const encryptedPayload = CryptoJS.AES.encrypt(payloadJson, parsed.passphrase).toString();
  const generatedAt = new Date().toISOString();
  const fileName = `atlas-share-${generatedAt.replace(/[:.]/g, '-')}.json`;
  const directory = new FileSystem.Directory(FileSystem.Paths.cache, 'atlas-shares');
  directory.create({ idempotent: true, intermediates: true });
  const file = new FileSystem.File(directory, fileName);
  const manifest = {
    bundleId: fileName.replace('.json', ''),
    cipher: 'aes-256',
    counts: preview.counts,
    createdAt: generatedAt,
    encrypted: true,
    integrity: {
      payloadSha256,
    },
    manifestVersion: 1,
    notes: preview.payload.notes,
    renderMode: parsed.renderMode,
    scope: {
      endDate: parsed.endDate,
      kind: parsed.scopeKind,
      protocolId: parsed.protocolId,
      startDate: parsed.startDate,
    },
    staticSnapshot: true,
  };
  const bundleDocument = JSON.stringify(
    {
      manifest,
      payloadEnc: encryptedPayload,
    },
    null,
    2
  );

  file.create({ intermediates: true, overwrite: true });
  file.write(bundleDocument, { encoding: 'utf8' });

  let shared = false;
  if (parsed.shareAfterCreate && (await Sharing.isAvailableAsync())) {
    await Sharing.shareAsync(file.uri, {
      mimeType: 'application/json',
      UTI: 'public.json',
    });
    shared = true;
  }

  await repositories.sensitiveActionAudits.create({
    eventType: shared ? 'selective_share_created' : 'export_created',
    manifestVersion: 1,
    payloadJson: JSON.stringify({
      counts: preview.counts,
      shared,
    }),
    protocolId: parsed.protocolId,
    renderMode: parsed.renderMode,
    scopeKind: parsed.scopeKind,
    surface: shared ? 'selective_share' : 'export',
  });

  trackAnalyticsEvent('export_requested', {
    format: 'json',
    rowCount: Object.values(preview.counts).reduce((sum, value) => sum + value, 0),
    shared,
  });

  return {
    fileName,
    fileUri: file.uri,
    manifest,
    shared,
  };
}

async function buildSharePayload(
  input: SelectiveShareInput,
  repositories: AtlasRepositories,
  options: { generatedAt?: string } = {}
) {
  const onboardingPrivacy = useOnboardingStore.getState().draft.privacy;
  const [aliases, profile, protocolItems] = await Promise.all([
    repositories.protocolAliases.listAllActive(),
    repositories.privacyProfiles.get(),
    listProtocolListItems(),
  ]);
  const aliasLookup = indexProtocolAliases(aliases);
  const timelineItems =
    input.scopeKind === 'protocol_with_recent_timeline' || input.scopeKind === 'custom_date_range'
      ? await getTimelineFeed({
          dateWindow:
            input.scopeKind === 'protocol_with_recent_timeline'
              ? 'last_30_days'
              : 'all',
          protocolId: input.protocolId ?? 'all',
        })
      : [];
  const [logEvents, symptomLogs, vials, weightLogs, todaySnapshot, inventorySnapshot, insights] =
    await Promise.all([
      repositories.logEvents.listAll(),
      repositories.symptomLogs.listAll(),
      repositories.vials.listAll(),
      repositories.weightLogs.listAll(),
      getTodaySnapshot(),
      getInventorySnapshot(),
      getInsightsSnapshot(),
    ]);

  const filteredLogEvents = filterByScopeAndDate(logEvents, input, (row) => row.effectiveAt);
  const filteredSymptomLogs = filterByScopeAndDate(symptomLogs, input, (row) => row.loggedAt);
  const filteredWeightLogs = filterByScopeAndDate(weightLogs, input, (row) => row.loggedAt);
  const filteredProtocolCards = protocolItems.filter((protocol) =>
    input.protocolId ? protocol.id === input.protocolId : true
  );

  const payload: SelectiveSharePayload = {
    generatedAt: options.generatedAt ?? new Date().toISOString(),
    notes: ['Static snapshot only', 'No live sync link'],
    renderMode: input.renderMode,
    scopeKind: input.scopeKind,
    sections: {},
    staticSnapshot: true,
  };

  if (input.scopeKind === 'summary_only') {
    payload.sections.summary = {
      adherence: insights.adherenceTrend,
      inventoryLowStockCount: inventorySnapshot.vials.filter((item) => item.isLowStock).length,
      nextDue:
        todaySnapshot.nextDue
          ? formatTodayOccurrenceLabel(
              todaySnapshot.nextDue,
              onboardingPrivacy,
              profile,
              aliasLookup,
              input.renderMode
            )
          : null,
      protocolCount: todaySnapshot.protocolCount,
    };
  }

  if (input.scopeKind === 'inventory_only') {
    payload.sections.inventory = inventorySnapshot.vials.map((vial) => ({
      id: vial.id,
      label: formatVialDisplayName(vial.label, onboardingPrivacy, profile, input.renderMode),
      lowStock: vial.isLowStock,
      projectedDepletionLabel: vial.projectedDepletionLabel,
      quantityLabel: vial.quantityLabel,
    }));
  }

  if (
    input.scopeKind === 'current_protocol_only' ||
    input.scopeKind === 'protocol_with_recent_timeline'
  ) {
    payload.sections.protocols = filteredProtocolCards.map((protocol) => ({
      cadenceLabel: protocol.cadenceLabel,
      doseLabel: protocol.doseLabel,
      id: protocol.id,
      kindLabel: protocol.kindLabel,
      nextDue: protocol.nextDue?.whenLabel ?? null,
      title: formatProtocolDisplayName(
        protocol.title,
        protocol.kindLabel.toLowerCase().includes('glp')
          ? 'glp'
          : protocol.kindLabel.toLowerCase().includes('peptide')
            ? 'peptide'
            : 'custom',
        onboardingPrivacy,
        profile,
        aliasLookup[protocol.id],
        input.renderMode
      ),
    }));
  }

  if (input.scopeKind === 'protocol_with_recent_timeline') {
    payload.sections.timeline = timelineItems.map((item) => ({
      eventType: item.eventType,
      summary: formatTimelineItemSummary(item, onboardingPrivacy, profile, aliasLookup, input.renderMode),
      timestamp: item.timestamp,
    }));
  }

  if (input.scopeKind === 'last_30_days_logs' || input.scopeKind === 'custom_date_range') {
    payload.sections.logs = filteredLogEvents.map((event) => ({
      effectiveAt: event.effectiveAt,
      eventType: event.eventType,
      notes: event.notes,
      protocolId: event.protocolId,
      quantity: event.quantity,
      quantityUnit: event.quantityUnit,
    }));
  }

  if (input.scopeKind === 'symptoms_only' || input.scopeKind === 'custom_date_range') {
    payload.sections.symptoms = filteredSymptomLogs.map((entry) => ({
      loggedAt: entry.loggedAt,
      notes: entry.notes,
      severity: entry.severity,
      symptomKey: entry.symptomKey,
    }));
  }

  if (input.scopeKind === 'custom_date_range') {
    payload.sections.weight = filteredWeightLogs.map((entry) => ({
      loggedAt: entry.loggedAt,
      unit: entry.unit,
      value: entry.value,
    }));
  }

  const vialItems =
    input.scopeKind === 'current_protocol_only'
      ? vials.filter((vial) => vial.protocolId === input.protocolId)
      : [];

  if (vialItems.length > 0) {
    payload.sections.vials = vialItems.map((vial) => ({
      id: vial.id,
      label: formatVialDisplayName(vial.label, onboardingPrivacy, profile, input.renderMode),
      quantityUnit: vial.quantityUnit,
      remainingQuantity: vial.remainingQuantity,
    }));
  }

  return {
    counts: Object.entries(payload.sections).reduce<Record<string, number>>((result, [key, value]) => {
      result[key] = Array.isArray(value) ? value.length : value ? 1 : 0;
      return result;
    }, {}),
    payload,
  };
}

function filterByScopeAndDate<T>(
  rows: T[],
  input: SelectiveShareInput,
  getDateValue: (row: T) => string
) {
  const protocolFiltered = rows.filter((row) => {
    if (!input.protocolId) {
      return true;
    }

    if (!hasProtocolId(row) || !row.protocolId) {
      return true;
    }

    return row.protocolId === input.protocolId;
  });

  if (input.scopeKind === 'last_30_days_logs') {
    const start = new Date();
    start.setUTCDate(start.getUTCDate() - 30);
    return protocolFiltered.filter((row) => new Date(getDateValue(row)).getTime() >= start.getTime());
  }

  if (input.scopeKind === 'custom_date_range' && input.startDate && input.endDate) {
    const start = new Date(`${input.startDate}T00:00:00.000Z`).getTime();
    const end = new Date(`${input.endDate}T23:59:59.999Z`).getTime();
    return protocolFiltered.filter((row) => {
      const timestamp = new Date(getDateValue(row)).getTime();
      return timestamp >= start && timestamp <= end;
    });
  }

  return protocolFiltered;
}

function hasProtocolId(value: unknown): value is { protocolId?: string | null } {
  return typeof value === 'object' && value !== null && 'protocolId' in value;
}

function buildContentPreview(payload: SelectiveSharePayload) {
  return Object.entries(payload.sections).map(([key, value]) => ({
    label: key,
    value: Array.isArray(value)
      ? `${value.length} item${value.length === 1 ? '' : 's'}`
      : '1 summary section',
  }));
}

function formatScopeLabel(scopeKind: SelectiveShareInput['scopeKind']) {
  switch (scopeKind) {
    case 'current_protocol_only':
      return 'Current protocol only';
    case 'protocol_with_recent_timeline':
      return 'Selected protocol + recent timeline';
    case 'last_30_days_logs':
      return 'Last 30 days logs';
    case 'symptoms_only':
      return 'Symptoms only';
    case 'inventory_only':
      return 'Inventory only';
    case 'summary_only':
      return 'Summary only';
    default:
      return 'Custom date range';
  }
}

async function resolveRepositories(repositories?: AtlasRepositories) {
  if (repositories) {
    return repositories;
  }

  return getAtlasRepositories();
}

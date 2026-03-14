import type {
  CalculatorProfile,
  Compound,
  CustomMetric,
  HealthConnection,
  LogEvent,
  MetricValueLog,
  PrivacyProfile,
  Protocol,
  ProtocolAlias,
  ProtocolRule,
  Reminder,
  ReminderPreference,
  Site,
  SymptomLog,
  Vial,
  WeightLog,
} from '@/src/lib/database/schemas';

import { trackAnalyticsEvent } from '@/src/lib/analytics/service';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import {
  buildReminderPreview,
  formatCompoundDisplayName,
  formatProtocolDisplayName,
  formatVialDisplayName,
  indexProtocolAliases,
  resolvePrivacyRenderMode,
} from '@/src/features/trust-vault/privacy';

export type AtlasExportFormat = 'csv' | 'json';

export type AtlasExportResult = {
  fileName: string;
  fileUri: string;
  format: AtlasExportFormat;
  rowCount: number;
  shared: boolean;
};

export type AtlasExportSnapshot = {
  calculatorProfiles: CalculatorProfile[];
  compounds: Compound[];
  customMetrics: CustomMetric[];
  healthConnections: HealthConnection[];
  logEvents: LogEvent[];
  metricValueLogs: MetricValueLog[];
  privacyProfile: PrivacyProfile;
  protocols: Protocol[];
  protocolAliases: ProtocolAlias[];
  protocolRules: ProtocolRule[];
  reminderPreference: ReminderPreference;
  reminders: Reminder[];
  sites: Site[];
  symptomLogs: SymptomLog[];
  vials: Vial[];
  weightLogs: WeightLog[];
};

export async function createAtlasExport(format: AtlasExportFormat): Promise<AtlasExportResult> {
  const snapshot = await getAtlasExportSnapshot();
  const sanitizedSnapshot = sanitizeAtlasExportSnapshot(snapshot);
  const generatedAt = new Date().toISOString();
  const serialized =
    format === 'json'
      ? {
          contents: buildAtlasJsonContents(sanitizedSnapshot, generatedAt),
          fileName: `atlas-export-${generatedAt.replace(/[:.]/g, '-')}.json`,
          rowCount: getSnapshotRowCount(sanitizedSnapshot),
        }
      : {
          contents: buildAtlasCsvContents(sanitizedSnapshot),
          fileName: `atlas-export-${generatedAt.replace(/[:.]/g, '-')}.csv`,
          rowCount: getSnapshotRowCount(sanitizedSnapshot),
        };

  const FileSystem = await import('expo-file-system');
  const Sharing = await import('expo-sharing');
  const exportDirectory = new FileSystem.Directory(FileSystem.Paths.cache, 'atlas-exports');
  exportDirectory.create({ idempotent: true, intermediates: true });

  const exportFile = new FileSystem.File(exportDirectory, serialized.fileName);
  exportFile.create({ intermediates: true, overwrite: true });
  exportFile.write(serialized.contents, { encoding: 'utf8' });
  const fileUri = exportFile.uri;

  let shared = false;

  if (await Sharing.isAvailableAsync()) {
    try {
      await Sharing.shareAsync(fileUri, {
        mimeType: format === 'json' ? 'application/json' : 'text/csv',
        UTI: format === 'json' ? 'public.json' : 'public.comma-separated-values-text',
      });
      shared = true;
    } catch (error) {
      console.warn(
        '[Atlas] Export share sheet failed.',
        error instanceof Error ? error.message : error
      );
    }
  }

  trackAnalyticsEvent('export_requested', {
    format,
    rowCount: serialized.rowCount,
    shared,
  });

  return {
    fileName: serialized.fileName,
    fileUri,
    format,
    rowCount: serialized.rowCount,
    shared,
  };
}

async function getAtlasExportSnapshot(): Promise<AtlasExportSnapshot> {
  const repositories = await loadAtlasRepositories();
  const [
    calculatorProfiles,
    compounds,
    customMetrics,
    healthConnections,
    logEvents,
    metricValueLogs,
    privacyProfile,
    protocols,
    protocolAliases,
    protocolRules,
    reminderPreference,
    reminders,
    sites,
    symptomLogs,
    vials,
    weightLogs,
  ] = await Promise.all([
    repositories.calculatorProfiles.listAll(),
    repositories.compounds.listAll(),
    repositories.customMetrics.listAll(),
    repositories.healthConnections.listAll(),
    repositories.logEvents.listAll(),
    repositories.metricValueLogs.listAll(),
    repositories.privacyProfiles.get(),
    repositories.protocols.listAll(),
    repositories.protocolAliases.listAllActive(),
    repositories.protocolRules.listAll(),
    repositories.reminderPreferences.get(),
    repositories.reminders.listAll(),
    repositories.sites.listAll(),
    repositories.symptomLogs.listAll(),
    repositories.vials.listAll(),
    repositories.weightLogs.listAll(),
  ]);

  return {
    calculatorProfiles,
    compounds,
    customMetrics,
    healthConnections,
    logEvents,
    metricValueLogs,
    privacyProfile,
    protocols,
    protocolAliases,
    protocolRules,
    reminderPreference,
    reminders,
    sites,
    symptomLogs,
    vials,
    weightLogs,
  };
}

export function sanitizeAtlasExportSnapshot(snapshot: AtlasExportSnapshot): AtlasExportSnapshot {
  const onboardingPrivacy = useOnboardingStore.getState().draft.privacy;
  const aliasLookup = indexProtocolAliases(snapshot.protocolAliases);
  const exportRenderMode = snapshot.privacyProfile.exportAliasByDefault
    ? 'alias'
    : resolvePrivacyRenderMode(onboardingPrivacy, snapshot.privacyProfile);
  const protocolLookup = snapshot.protocols.reduce<Record<string, Protocol>>((result, protocol) => {
    result[protocol.id] = protocol;
    return result;
  }, {});
  const protocolByCompoundId = snapshot.protocols.reduce<Record<string, Protocol>>((result, protocol) => {
    if (protocol.compoundId && !result[protocol.compoundId]) {
      result[protocol.compoundId] = protocol;
    }
    return result;
  }, {});

  return {
    ...snapshot,
    compounds: snapshot.compounds.map((compound) => {
      const protocol = protocolByCompoundId[compound.id];
      return {
        ...compound,
        displayName:
          formatCompoundDisplayName(
            compound.displayName,
            protocol?.kind ?? compound.compoundType,
            onboardingPrivacy,
            snapshot.privacyProfile,
            protocol ? aliasLookup[protocol.id] : null,
            exportRenderMode,
          ) ?? compound.displayName,
      };
    }),
    protocols: snapshot.protocols.map((protocol) => ({
      ...protocol,
      name: formatProtocolDisplayName(
        protocol.name,
        protocol.kind,
        onboardingPrivacy,
        snapshot.privacyProfile,
        aliasLookup[protocol.id],
        exportRenderMode,
      ),
    })),
    reminders: snapshot.reminders.map((reminder) => {
      const protocol = protocolLookup[reminder.protocolId];
      const preview = buildReminderPreview(
        {
          kind: protocol?.kind ?? 'custom',
          protocolId: reminder.protocolId,
          protocolName: protocol?.name ?? 'Atlas protocol',
          whenLabel: `on ${reminder.scheduledFor}`,
        },
        { privacyMode: reminder.privacyMode },
        onboardingPrivacy,
        snapshot.privacyProfile,
        aliasLookup,
        exportRenderMode,
      );

      return {
        ...reminder,
        body: preview.body,
        title: preview.title,
      };
    }),
    vials: snapshot.vials.map((vial) => ({
      ...vial,
      label: formatVialDisplayName(
        vial.label,
        onboardingPrivacy,
        snapshot.privacyProfile,
        exportRenderMode,
      ),
    })),
  };
}

export function getSnapshotRowCount(snapshot: AtlasExportSnapshot) {
  return (
    snapshot.calculatorProfiles.length +
    snapshot.compounds.length +
    snapshot.customMetrics.length +
    snapshot.healthConnections.length +
    snapshot.logEvents.length +
    snapshot.metricValueLogs.length +
    1 +
    snapshot.protocols.length +
    snapshot.protocolAliases.length +
    snapshot.protocolRules.length +
    snapshot.reminders.length +
    snapshot.sites.length +
    snapshot.symptomLogs.length +
    snapshot.vials.length +
    snapshot.weightLogs.length
  );
}

export function buildAtlasJsonContents(snapshot: AtlasExportSnapshot, generatedAt: string) {
  return JSON.stringify(
    {
      generatedAt,
      snapshot,
    },
    null,
    2
  );
}

export function buildAtlasCsvContents(snapshot: AtlasExportSnapshot) {
  const rows = [
    ...snapshot.protocols.map((record) =>
      buildCsvRow('protocol', record.id, record.name, record.createdAt, record.status, record.kind, record.notes)
    ),
    ...snapshot.protocolRules.map((record) =>
      buildCsvRow(
        'protocol_rule',
        record.id,
        record.protocolId,
        record.createdAt,
        record.ruleType,
        record.timeOfDay,
        record.anchorDate
      )
    ),
    ...snapshot.logEvents.map((record) =>
      buildCsvRow(
        'log_event',
        record.id,
        record.protocolId,
        record.loggedAt,
        record.eventType,
        record.quantity,
        record.notes
      )
    ),
    ...snapshot.vials.map((record) =>
      buildCsvRow(
        'vial',
        record.id,
        record.label,
        record.updatedAt,
        record.remainingQuantity,
        record.quantityUnit,
        record.lowStockThreshold
      )
    ),
    ...snapshot.weightLogs.map((record) =>
      buildCsvRow('weight_log', record.id, record.unit, record.loggedAt, record.value, record.source, record.notes)
    ),
    ...snapshot.symptomLogs.map((record) =>
      buildCsvRow(
        'symptom_log',
        record.id,
        record.symptomKey,
        record.loggedAt,
        record.severity,
        record.source,
        record.notes
      )
    ),
    ...snapshot.customMetrics.map((record) =>
      buildCsvRow('custom_metric', record.id, record.label, record.createdAt, record.valueType, record.unit, record.metricKey)
    ),
    ...snapshot.metricValueLogs.map((record) =>
      buildCsvRow(
        'metric_value_log',
        record.id,
        record.metricId,
        record.loggedAt,
        record.numberValue ?? record.textValue ?? record.booleanValue,
        record.source,
        record.protocolId
      )
    ),
    ...snapshot.healthConnections.map((record) =>
      buildCsvRow(
        'health_connection',
        record.providerKey,
        record.enabled ? 'enabled' : 'disabled',
        record.updatedAt,
        record.connected ? 'connected' : 'not_connected',
        record.lastSyncAt,
        record.lastError
      )
    ),
    buildCsvRow(
      'privacy_profile',
      snapshot.privacyProfile.id,
      snapshot.privacyProfile.aliasModeEnabled ? 'alias_on' : 'alias_off',
      snapshot.privacyProfile.updatedAt,
      snapshot.privacyProfile.biometricLockEnabled ? 'biometric_on' : 'biometric_off',
      snapshot.privacyProfile.biometricGateMode,
      snapshot.privacyProfile.exportAliasByDefault,
    ),
    ...snapshot.protocolAliases.map((record) =>
      buildCsvRow(
        'protocol_alias',
        record.id,
        record.protocolId,
        record.updatedAt,
        record.aliasLabel,
        record.aliasCompoundLabel,
        record.archivedAt
      )
    ),
    ...snapshot.calculatorProfiles.map((record) =>
      buildCsvRow(
        'calculator_profile',
        record.id,
        record.label,
        record.updatedAt,
        record.powderAmount,
        record.diluentVolume,
        record.drawVolume
      )
    ),
    ...snapshot.reminders.map((record) =>
      buildCsvRow(
        'reminder',
        record.id,
        record.protocolId,
        record.scheduledFor,
        record.status,
        record.privacyMode,
        record.notificationId
      )
    ),
    buildCsvRow(
      'reminder_preference',
      snapshot.reminderPreference.id,
      snapshot.reminderPreference.privacyMode,
      snapshot.reminderPreference.updatedAt,
      snapshot.reminderPreference.remindersEnabled,
      snapshot.reminderPreference.leadTimeMinutes,
      null
    ),
    ...snapshot.sites.map((record) =>
      buildCsvRow('site', record.id, record.name, record.updatedAt, record.bodyArea, record.archivedAt, record.notes)
    ),
    ...snapshot.compounds.map((record) =>
      buildCsvRow('compound', record.id, record.displayName, record.updatedAt, record.compoundType, record.isUserDefined, record.notes)
    ),
  ];

  return [Object.keys(rows[0] ?? {}).join(','), ...rows.map((row) => Object.values(row).map(toCsvCell).join(','))].join('\n');
}

function buildCsvRow(
  dataset: string,
  id: unknown,
  primary: unknown,
  timestamp: unknown,
  value: unknown,
  secondary: unknown,
  notes: unknown
) {
  return {
    dataset,
    id: stringifyValue(id),
    primary: stringifyValue(primary),
    timestamp: stringifyValue(timestamp),
    value: stringifyValue(value),
    secondary: stringifyValue(secondary),
    notes: stringifyValue(notes),
  };
}

function stringifyValue(value: unknown) {
  if (value === null || value === undefined) {
    return '';
  }

  if (typeof value === 'object') {
    return JSON.stringify(value);
  }

  return String(value);
}

function toCsvCell(value: unknown) {
  const normalized = stringifyValue(value).replaceAll('"', '""');
  return `"${normalized}"`;
}

async function loadAtlasRepositories() {
  const module = await import('@/src/lib/database');
  return module.getAtlasRepositories();
}

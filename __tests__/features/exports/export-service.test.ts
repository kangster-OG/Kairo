import type { AtlasExportSnapshot } from '@/src/lib/export/service';
import {
  buildAtlasCsvContents,
  buildAtlasJsonContents,
  getSnapshotRowCount,
  sanitizeAtlasExportSnapshot,
} from '@/src/lib/export/service';
import { useOnboardingStore } from '@/src/features/onboarding/store';

describe('export service', () => {
  it('serializes the local-first bundle to JSON and CSV', () => {
    const snapshot = createSnapshot();
    const json = buildAtlasJsonContents(snapshot, '2026-03-13T12:00:00.000Z');
    const csv = buildAtlasCsvContents(snapshot);

    expect(JSON.parse(json)).toEqual(
      expect.objectContaining({
        manifest: expect.objectContaining({
          format: 'atlas_export',
          generatedAt: '2026-03-13T12:00:00.000Z',
          version: 1,
        }),
      })
    );
    expect(csv).toContain('dataset,id,primary,timestamp,value,secondary,notes');
    expect(csv).toContain('"weight_log"');
    expect(csv).toContain('"health_connection"');
    expect(csv).toContain('"protocol_revision"');
    expect(csv).toContain('"sensitive_action_audit"');
    expect(getSnapshotRowCount(snapshot)).toBe(18);
  });

  it('sanitizes protocol and vial labels when alias export mode is enabled', async () => {
    const snapshot = createSnapshot();

    await useOnboardingStore.getState().updateDraft((draft) => ({
      ...draft,
      privacy: {
        ...draft.privacy,
        discreetNotifications: false,
        hideSensitiveLabels: false,
      },
    }));

    snapshot.privacyProfile.aliasModeEnabled = false;
    snapshot.privacyProfile.exportAliasByDefault = true;
    snapshot.protocolAliases = [
      {
        aliasCompoundLabel: 'Blue vial',
        aliasLabel: 'Evening plan',
        archivedAt: null,
        createdAt: '2026-03-01T00:00:00.000Z',
        id: 'a1',
        protocolId: 'p1',
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ];

    const sanitized = sanitizeAtlasExportSnapshot(snapshot);

    expect(sanitized.protocols[0]?.name).toBe('Evening plan');
    expect(sanitized.compounds[0]?.displayName).toBe('Blue vial');
    expect(sanitized.vials[0]?.label).toBe('Private vial');
    expect(sanitized.reminders[0]?.title).toBe('Evening plan');
  });

  it('includes the Phase 2 migration datasets in the JSON snapshot payload', () => {
    const snapshot = createSnapshot();
    const json = JSON.parse(buildAtlasJsonContents(snapshot, '2026-03-13T12:00:00.000Z'));

    expect(json.manifest).toEqual(
      expect.objectContaining({
        format: 'atlas_export',
        generatedAt: '2026-03-13T12:00:00.000Z',
        source: 'atlas-react-native',
        version: 1,
      })
    );
    expect(json.snapshot.protocolRevisions).toHaveLength(1);
    expect(json.snapshot.protocolRevisionRules).toHaveLength(1);
    expect(json.snapshot.protocolChangeAudits).toHaveLength(1);
    expect(json.snapshot.sensitiveActionAudits).toHaveLength(1);
  });
});

function createSnapshot(): AtlasExportSnapshot {
  return {
    calculatorProfiles: [
      {
        createdAt: '2026-03-01T00:00:00.000Z',
        diluentUnit: 'mL',
        diluentVolume: 2,
        drawUnit: 'mL',
        drawVolume: 0.25,
        id: 'c1',
        label: 'Baseline',
        powderAmount: 2,
        powderUnit: 'mg',
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ],
    compounds: [
      {
        compoundType: 'glp',
        createdAt: '2026-03-01T00:00:00.000Z',
        displayName: 'Wegovy',
        id: 'cmp1',
        isUserDefined: false,
        notes: null,
        slug: 'wegovy',
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ],
    customMetrics: [
      {
        createdAt: '2026-03-01T00:00:00.000Z',
        id: 'm1',
        label: 'Energy',
        metricKey: 'energy',
        protocolId: null,
        unit: 'score',
        updatedAt: '2026-03-01T00:00:00.000Z',
        valueType: 'number',
      },
    ],
    healthConnections: [
      {
        connected: false,
        createdAt: '2026-03-01T00:00:00.000Z',
        enabled: true,
        lastError: 'Scaffold only',
        lastSyncAt: null,
        providerKey: 'health_connect',
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ],
    logEvents: [
      {
        effectiveAt: '2026-03-13T08:00:00.000Z',
        eventType: 'completed',
        id: 'l1',
        loggedAt: '2026-03-13T08:00:00.000Z',
        notes: null,
        occurrenceId: 'occ1',
        protocolId: 'p1',
        quantity: 1,
        quantityUnit: 'mg',
        siteId: null,
        source: 'user',
        vialId: null,
      },
    ],
    metricValueLogs: [
      {
        booleanValue: null,
        createdAt: '2026-03-13T08:00:00.000Z',
        id: 'mv1',
        loggedAt: '2026-03-13T08:00:00.000Z',
        metricId: 'm1',
        numberValue: 8,
        protocolId: null,
        source: 'manual',
        textValue: null,
        updatedAt: '2026-03-13T08:00:00.000Z',
      },
    ],
    privacyProfile: {
      aliasModeEnabled: false,
      biometricGateMode: 'best_effort',
      biometricLockEnabled: false,
      createdAt: '2026-03-01T00:00:00.000Z',
      exportAliasByDefault: false,
      id: 'default',
      shareAliasByDefault: true,
      updatedAt: '2026-03-01T00:00:00.000Z',
    },
    protocolChangeAudits: [
      {
        changeType: 'future_dose_changed',
        createdAt: '2026-03-02T00:00:00.000Z',
        effectiveFrom: '2026-03-08T08:00:00.000Z',
        id: 'pca1',
        payloadJson: '{"doseAmount":2}',
        previousRevisionId: null,
        protocolId: 'p1',
        revisionId: 'prv1',
        summary: 'Dose changes next week.',
      },
    ],
    protocols: [
      {
        compoundId: 'cmp1',
        createdAt: '2026-03-01T00:00:00.000Z',
        defaultTimeOfDay: '08:00',
        doseAmount: 1,
        doseUnit: 'mg',
        id: 'p1',
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
      },
    ],
    protocolAliases: [],
    protocolRevisionRules: [
      {
        anchorDate: '2026-03-01',
        createdAt: '2026-03-01T00:00:00.000Z',
        doseAmountOverride: null,
        doseUnitOverride: null,
        id: 'prr1',
        intervalCount: 1,
        phaseLengthDays: null,
        phaseOrder: 0,
        phaseStartDayOffset: 0,
        phaseType: 'base',
        revisionId: 'prv1',
        ruleType: 'weekly',
        timeOfDay: '08:00',
        updatedAt: '2026-03-01T00:00:00.000Z',
        weekday: 1,
      },
    ],
    protocolRevisions: [
      {
        createdAt: '2026-03-01T00:00:00.000Z',
        defaultTimeOfDay: '08:00',
        doseAmount: 1,
        doseUnit: 'mg',
        effectiveFrom: '2026-03-01T00:00:00.000Z',
        effectiveTo: null,
        id: 'prv1',
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
      },
    ],
    protocolRules: [
      {
        anchorDate: '2026-03-01',
        createdAt: '2026-03-01T00:00:00.000Z',
        id: 'r1',
        intervalCount: 1,
        isActive: true,
        protocolId: 'p1',
        ruleType: 'weekly',
        timeOfDay: '08:00',
        updatedAt: '2026-03-01T00:00:00.000Z',
        weekday: 1,
      },
    ],
    reminderPreference: {
      createdAt: '2026-03-01T00:00:00.000Z',
      id: 'default',
      leadTimeMinutes: 0,
      privacyMode: 'generic',
      remindersEnabled: true,
      updatedAt: '2026-03-01T00:00:00.000Z',
    },
    reminders: [
      {
        body: 'Atlas reminder',
        channel: 'local_notification',
        createdAt: '2026-03-01T00:00:00.000Z',
        discreetCopyEnabled: false,
        id: 'rem1',
        isEnabled: true,
        notificationId: null,
        occurrenceId: 'occ1',
        offsetMinutes: 0,
        privacyMode: 'generic',
        protocolId: 'p1',
        scheduledFor: '2026-03-13T08:00:00.000Z',
        status: 'scheduled',
        title: 'Atlas',
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ],
    sensitiveActionAudits: [
      {
        createdAt: '2026-03-03T00:00:00.000Z',
        eventType: 'export_created',
        id: 'saa1',
        manifestVersion: 1,
        payloadJson: '{"scope":"full"}',
        protocolId: 'p1',
        renderMode: 'alias',
        scopeKind: 'full_export',
        surface: 'trust_vault',
      },
    ],
    sites: [
      {
        archivedAt: null,
        bodyArea: 'abdomen',
        createdAt: '2026-03-01T00:00:00.000Z',
        id: 's1',
        name: 'Left abdomen',
        notes: null,
        updatedAt: '2026-03-01T00:00:00.000Z',
      },
    ],
    symptomLogs: [
      {
        createdAt: '2026-03-13T08:00:00.000Z',
        id: 'sym1',
        loggedAt: '2026-03-13T08:00:00.000Z',
        notes: null,
        severity: 2,
        source: 'manual',
        symptomKey: 'nausea',
        updatedAt: '2026-03-13T08:00:00.000Z',
      },
    ],
    vials: [
      {
        compoundId: 'cmp1',
        concentrationUnit: 'mg',
        concentrationValue: 1,
        createdAt: '2026-03-01T00:00:00.000Z',
        expiresAt: null,
        id: 'v1',
        label: 'Starter pen',
        lowStockThreshold: 1,
        openedAt: null,
        protocolId: 'p1',
        quantityUnit: 'dose',
        remainingQuantity: 3,
        startingQuantity: 4,
        updatedAt: '2026-03-01T00:00:00.000Z',
        volumeMl: 2,
      },
    ],
    weightLogs: [
      {
        createdAt: '2026-03-13T08:00:00.000Z',
        id: 'w1',
        loggedAt: '2026-03-13T08:00:00.000Z',
        notes: null,
        source: 'manual',
        unit: 'lb',
        updatedAt: '2026-03-13T08:00:00.000Z',
        value: 180,
      },
    ],
  };
}

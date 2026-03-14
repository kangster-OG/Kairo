import CryptoJS from 'crypto-js';

import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { runMigrations } from '@/src/lib/database/migrations';
import { createAtlasRepositories } from '@/src/lib/database/repositories';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import {
  buildSelectiveSharePreview,
  createSelectiveShareBundle,
  getTrustVaultSnapshot,
  saveProtocolAlias,
  updateTrustVaultProfile,
} from '@/src/features/trust-vault/service';

jest.mock('@/src/lib/database', () => ({
  getAtlasDatabaseClient: jest.fn(async () => {
    throw new Error('Trust Vault tests should inject repositories directly.');
  }),
  getAtlasRepositories: jest.fn(async () => {
    throw new Error('Trust Vault tests should inject repositories directly.');
  }),
}));

jest.mock('expo-local-authentication', () => ({
  authenticateAsync: jest.fn(async () => ({ success: true })),
  getEnrolledLevelAsync: jest.fn(async () => 1),
  hasHardwareAsync: jest.fn(async () => true),
  isEnrolledAsync: jest.fn(async () => true),
}));

jest.mock('@/src/features/protocols/service', () => ({
  listProtocolListItems: jest.fn(),
}));

jest.mock('@/src/features/day-loop/service', () => ({
  getTimelineFeed: jest.fn(),
  getTodaySnapshot: jest.fn(),
}));

jest.mock('@/src/features/inventory/service', () => ({
  getInventorySnapshot: jest.fn(),
}));

jest.mock('@/src/features/insights/service', () => ({
  getInsightsSnapshot: jest.fn(async () => ({
    adherenceTrend: {
      completedCount: 1,
      completionRateLabel: '100% logged on time',
      overdueCount: 0,
      rescheduledCount: 0,
      skippedCount: 0,
    },
    amountInSystem: {
      disclaimer:
        'Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation.',
      items: [],
    },
    customMetricSummaries: [],
    hasAnyInsightData: true,
    inventoryBurnDown: [],
    symptomTrend: [],
    weightTrend: {
      changeLabel: null,
      latestLabel: null,
      points: [],
    },
  })),
}));

jest.mock('expo-crypto', () => ({
  CryptoDigestAlgorithm: {
    SHA256: 'SHA256',
  },
  digestStringAsync: jest.fn(async () => 'sha256:test'),
}));

const mockFileWrites = new Map<string, string>();

jest.mock('expo-file-system', () => ({
  Directory: class Directory {
    public uri: string;

    constructor(base: string, name: string) {
      this.uri = `${base}/${name}`;
    }

    create() {}
  },
  File: class File {
    public uri: string;

    constructor(directory: { uri: string }, fileName: string) {
      this.uri = `${directory.uri}/${fileName}`;
    }

    create() {}

    write(contents: string) {
      mockFileWrites.set(this.uri, contents);
    }
  },
  Paths: {
    cache: 'cache://atlas',
  },
}));

jest.mock('expo-sharing', () => ({
  isAvailableAsync: jest.fn(async () => true),
  shareAsync: jest.fn(async () => undefined),
}));

describe('trust vault service', () => {
  beforeEach(async () => {
    mockFileWrites.clear();
    jest.clearAllMocks();
    await useOnboardingStore.getState().reset();
    await useOnboardingStore.getState().updateDraft((draft) => ({
      ...draft,
      privacy: {
        ...draft.privacy,
        discreetNotifications: false,
        hideSensitiveLabels: false,
      },
    }));
  });

  it('creates an encrypted selective share bundle whose payload matches the preview', async () => {
    const { protocol, repositories } = await createSeededRepositories();

    await saveProtocolAlias(
      {
        aliasCompoundLabel: 'Blue vial',
        aliasLabel: 'Evening plan',
        protocolId: protocol.id,
      },
      { repositories }
    );
    await updateTrustVaultProfile(
      {
        aliasModeEnabled: true,
        biometricLockEnabled: false,
      },
      { repositories }
    );

    const preview = await buildSelectiveSharePreview(
      {
        endDate: null,
        passphrase: 'atlas-passphrase',
        protocolId: protocol.id,
        renderMode: 'alias',
        scopeKind: 'current_protocol_only',
        shareAfterCreate: false,
        startDate: null,
      },
      { repositories }
    );

    const bundle = await createSelectiveShareBundle(
      {
        endDate: null,
        passphrase: 'atlas-passphrase',
        protocolId: protocol.id,
        renderMode: 'alias',
        scopeKind: 'current_protocol_only',
        shareAfterCreate: false,
        startDate: null,
      },
      { repositories }
    );

    const bundleContents = mockFileWrites.get(bundle.fileUri);
    expect(bundleContents).toBeTruthy();

    const parsed = JSON.parse(bundleContents!);
    const decrypted = CryptoJS.AES.decrypt(parsed.payloadEnc, 'atlas-passphrase').toString(
      CryptoJS.enc.Utf8
    );

    expect(JSON.parse(decrypted)).toEqual(
      expect.objectContaining({
        ...preview.payload,
        generatedAt: expect.any(String),
      })
    );
    expect(preview.payload.sections.protocols).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          title: 'Evening plan',
        }),
      ])
    );
  });

  it('blocks bundle creation when biometric approval is required and denied', async () => {
    const { protocol, repositories } = await createSeededRepositories();

    await updateTrustVaultProfile(
      {
        biometricGateMode: 'required_when_available',
        biometricLockEnabled: true,
      },
      { repositories }
    );

    await expect(
      createSelectiveShareBundle(
        {
          endDate: null,
          passphrase: 'atlas-passphrase',
          protocolId: protocol.id,
          renderMode: 'alias',
          scopeKind: 'current_protocol_only',
          shareAfterCreate: false,
          startDate: null,
        },
        {
          biometricClient: {
            authenticateAsync: jest.fn(async () => ({
              error: 'authentication_failed',
              success: false as const,
            })) as never,
            getEnrolledLevelAsync: jest.fn(async () => 1),
            hasHardwareAsync: jest.fn(async () => true),
            isEnrolledAsync: jest.fn(async () => true),
          },
          repositories,
        }
      )
    ).rejects.toThrow('Atlas could not authorize this private share bundle.');

    expect(await repositories.sensitiveActionAudits.listAll()).toEqual(
      expect.not.arrayContaining([expect.objectContaining({ eventType: 'export_created' })])
    );
  });

  it('keeps canonical names intact when alias mode is later turned off', async () => {
    const { protocol, repositories } = await createSeededRepositories();

    await saveProtocolAlias(
      {
        aliasCompoundLabel: 'Blue vial',
        aliasLabel: 'Evening plan',
        protocolId: protocol.id,
      },
      { repositories }
    );
    await updateTrustVaultProfile({ aliasModeEnabled: true }, { repositories });

    const aliasSnapshot = await getTrustVaultSnapshot({ repositories });
    expect(aliasSnapshot.effectiveRenderMode).toBe('alias');
    expect(aliasSnapshot.protocols[0]?.aliasLabel).toBe('Evening plan');

    await updateTrustVaultProfile({ aliasModeEnabled: false }, { repositories });

    const fullSnapshot = await getTrustVaultSnapshot({ repositories });
    expect(fullSnapshot.protocols[0]?.canonicalName).toBe('Weekly GLP');
    expect(fullSnapshot.protocols[0]?.aliasLabel).toBe('Evening plan');
  });
});

async function createSeededRepositories() {
  const client = await createSqlJsDatabaseClient();
  await runMigrations(client);
  const repositories = createAtlasRepositories(client);

  const compound = await repositories.compounds.create({
    compoundType: 'glp',
    displayName: 'Wegovy',
    isUserDefined: false,
    notes: null,
    slug: 'wegovy',
  });

  const protocol = await repositories.protocols.create({
    compoundId: compound.id,
    defaultTimeOfDay: '08:00',
    doseAmount: 1,
    doseUnit: 'mg',
    kind: 'glp',
    linkedVialId: null,
    name: 'Weekly GLP',
    notes: null,
    siteRotationEnabled: false,
    siteTrackingEnabled: false,
    startDate: '2026-03-01',
    status: 'active',
    timezone: 'America/New_York',
  });

  const vial = await repositories.vials.create({
    compoundId: compound.id,
    concentrationUnit: 'mg',
    concentrationValue: 1,
    expiresAt: null,
    label: 'Starter pen',
    lowStockThreshold: 1,
    openedAt: null,
    protocolId: protocol.id,
    quantityUnit: 'dose',
    remainingQuantity: 3,
    startingQuantity: 4,
    volumeMl: 2,
  });

  const protocolServiceModule = jest.requireMock('@/src/features/protocols/service') as {
    listProtocolListItems: jest.Mock;
  };
  const dayLoopModule = jest.requireMock('@/src/features/day-loop/service') as {
    getTimelineFeed: jest.Mock;
    getTodaySnapshot: jest.Mock;
  };
  const inventoryModule = jest.requireMock('@/src/features/inventory/service') as {
    getInventorySnapshot: jest.Mock;
  };

  protocolServiceModule.listProtocolListItems.mockResolvedValue([
    {
      cadenceLabel: 'Weekly on Monday',
      compoundName: 'Wegovy',
      doseLabel: '1 mg',
      id: protocol.id,
      kind: 'glp',
      kindLabel: 'GLP',
      nextDue: {
        whenLabel: 'Tomorrow at 8:00 AM',
      },
      notes: null,
      status: 'active',
      title: 'Weekly GLP',
    },
  ]);
  dayLoopModule.getTimelineFeed.mockResolvedValue([
    {
      eventId: 'evt1',
      eventType: 'logged_dose',
      protocolId: protocol.id,
      protocolName: 'Weekly GLP',
      summary: 'Logged Weekly GLP as taken',
      timestamp: '2026-03-13T08:00:00.000Z',
    },
  ]);
  dayLoopModule.getTodaySnapshot.mockResolvedValue({
    nextDue: {
      cadenceLabel: 'Weekly on Monday',
      id: 'occ1',
      kind: 'glp',
      protocolId: protocol.id,
      protocolName: 'Weekly GLP',
      scheduledFor: '2026-03-14T08:00:00.000Z',
      timeLabel: '8:00 AM',
      whenLabel: 'Tomorrow at 8:00 AM',
    },
    overdue: [],
    primaryProtocolId: protocol.id,
    protocolCount: 1,
    upcoming: [],
  });
  inventoryModule.getInventorySnapshot.mockResolvedValue({
    protocolSettings: [],
    protocols: [{ id: protocol.id, name: 'Weekly GLP' }],
    sites: [],
    vials: [
      {
        adjustmentProtocolId: protocol.id,
        autoDecrementLabel: 'Auto-decrements 1 dose per taken log',
        compoundName: 'Wegovy',
        id: vial.id,
        isLowStock: false,
        label: vial.label,
        linkedProtocolName: 'Weekly GLP',
        lowStockLabel: null,
        projectedDepletionLabel: 'Projected depletion Mar 28',
        quantityLabel: '3 dose remaining of 4 dose',
        quantityUnit: 'dose',
        remainingQuantity: 3,
        startingQuantity: 4,
      },
    ],
  });

  await repositories.privacyProfiles.update({
    biometricGateMode: 'best_effort',
    biometricLockEnabled: false,
    exportAliasByDefault: false,
    id: 'default',
    shareAliasByDefault: true,
  });

  return { protocol, repositories };
}

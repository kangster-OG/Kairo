import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { runMigrations } from '@/src/lib/database/migrations';
import { createAtlasRepositories } from '@/src/lib/database/repositories';
import { applyInventoryCorrection, getProtocolSiteOptions, saveVial } from '@/src/features/inventory/service';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';
import { logTodayAction } from '@/src/features/day-loop/service';

jest.mock('@/src/lib/database', () => ({
  getAtlasDatabaseClient: jest.fn(),
  getAtlasRepositories: jest.fn(),
}));

describe('inventory service', () => {
  it('decrements linked inventory on taken logs and preserves manual corrections as separate events', async () => {
    const client = await createSqlJsDatabaseClient();
    await runMigrations(client);
    const repositories = createAtlasRepositories(client);

    const getClientSpy = jest.mocked(getAtlasDatabaseClient).mockResolvedValue(client);
    const getRepositoriesSpy = jest.mocked(getAtlasRepositories).mockResolvedValue(repositories);

    try {
      const created = await createProtocolInRepositories(
        repositories,
        {
          compoundMode: 'new',
          compoundName: 'Wegovy',
          doseAmount: '0.25',
          doseUnit: 'mg',
          existingCompoundId: null,
          intervalDays: '1',
          kind: 'glp',
          notes: '',
          scheduleType: 'weekly',
          timeOfDay: '08:00',
          weekday: 4,
        },
        new Date(2026, 2, 12, 7, 30, 0, 0)
      );

      const vial = await saveVial({
        concentrationUnit: null,
        concentrationValue: null,
        label: 'Starter pen',
        lowStockThreshold: 1,
        protocolId: created.protocol.id,
        quantityUnit: 'dose',
        remainingQuantity: 4,
        startingQuantity: 4,
        volumeMl: null,
      });

      const site = await repositories.sites.create({
        bodyArea: 'abdomen',
        name: 'Right abdomen',
        notes: null,
      });

      await logTodayAction({
        action: 'mark_taken',
        occurrenceId: 'pro_occ_1',
        protocolId: created.protocol.id,
        scheduledFor: '2026-03-12T13:00:00.000Z',
        siteId: site.id,
      });

      const decremented = await repositories.vials.getById(vial.id);
      expect(decremented?.remainingQuantity).toBe(3);

      const corrected = await applyInventoryCorrection({
        nextRemainingQuantity: 5,
        notes: 'Manual count after new box added.',
        vialId: vial.id,
      });

      expect(corrected.vial.remainingQuantity).toBe(5);

      const events = await repositories.logEvents.listByProtocolId(created.protocol.id);
      expect(events).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'completed',
            siteId: site.id,
            vialId: vial.id,
          }),
          expect.objectContaining({
            eventType: 'inventory_adjustment',
            notes: 'Manual count after new box added.',
            quantity: 2,
            quantityUnit: 'dose',
            vialId: vial.id,
          }),
        ])
      );
    } finally {
      getClientSpy.mockReset();
      getRepositoriesSpy.mockReset();
      await client.close();
    }
  });

  it('suggests the next site when rotation is enabled', async () => {
    const client = await createSqlJsDatabaseClient();
    await runMigrations(client);
    const repositories = createAtlasRepositories(client);

    const getClientSpy = jest.mocked(getAtlasDatabaseClient).mockResolvedValue(client);
    const getRepositoriesSpy = jest.mocked(getAtlasRepositories).mockResolvedValue(repositories);

    try {
      const created = await createProtocolInRepositories(
        repositories,
        {
          compoundMode: 'new',
          compoundName: 'BPC-157',
          doseAmount: '250',
          doseUnit: 'mcg',
          existingCompoundId: null,
          intervalDays: '2',
          kind: 'peptide',
          notes: '',
          scheduleType: 'every_n_days',
          timeOfDay: '08:00',
          weekday: null,
        },
        new Date(2026, 2, 12, 7, 30, 0, 0)
      );

      await repositories.protocols.update({
        id: created.protocol.id,
        siteRotationEnabled: true,
        siteTrackingEnabled: true,
      });
      const left = await repositories.sites.create({
        bodyArea: 'abdomen',
        name: 'Left abdomen',
        notes: null,
      });
      const right = await repositories.sites.create({
        bodyArea: 'abdomen',
        name: 'Right abdomen',
        notes: null,
      });
      await repositories.logEvents.create({
        effectiveAt: '2026-03-10T13:00:00.000Z',
        eventType: 'completed',
        occurrenceId: 'occ_older',
        protocolId: created.protocol.id,
        quantity: 250,
        quantityUnit: 'mcg',
        siteId: left.id,
        source: 'user',
      });

      const options = await getProtocolSiteOptions(created.protocol.id);

      expect(options.sites).toHaveLength(2);
      expect(options.suggestedSiteId).toBe(right.id);
    } finally {
      getClientSpy.mockReset();
      getRepositoriesSpy.mockReset();
      await client.close();
    }
  });
});

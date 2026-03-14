import { createAtlasRepositories } from '@/src/lib/database/repositories';
import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { runMigrations } from '@/src/lib/database/migrations';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';

describe('protocol creation service', () => {
  it('creates a new protocol, rule, and compound from wizard values', async () => {
    const client = await createSqlJsDatabaseClient();
    await runMigrations(client);
    const repositories = createAtlasRepositories(client);

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
        notes: 'Created in a local-first test.',
        scheduleType: 'weekly',
        timeOfDay: '08:00',
        weekday: 1,
      },
      new Date(2026, 2, 12, 9, 0, 0, 0)
    );

    const savedProtocols = await repositories.protocols.listAll();
    const savedRules = await repositories.protocolRules.listByProtocolId(created.protocol.id);
    const savedCompounds = await repositories.compounds.listAll();

    expect(savedCompounds).toHaveLength(1);
    expect(savedProtocols).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          doseAmount: 0.25,
          doseUnit: 'mg',
          kind: 'glp',
          name: 'Wegovy',
          status: 'active',
        }),
      ])
    );
    expect(savedRules).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          ruleType: 'weekly',
          timeOfDay: '08:00',
          weekday: 1,
        }),
      ])
    );

    await client.close();
  });

  it('reuses an existing compound slug when another protocol uses the same name', async () => {
    const client = await createSqlJsDatabaseClient();
    await runMigrations(client);
    const repositories = createAtlasRepositories(client);

    await createProtocolInRepositories(
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
        timeOfDay: '07:30',
        weekday: null,
      },
      new Date(2026, 2, 12, 9, 0, 0, 0)
    );

    await createProtocolInRepositories(
      repositories,
      {
        compoundMode: 'new',
        compoundName: 'BPC-157',
        doseAmount: '300',
        doseUnit: 'mcg',
        existingCompoundId: null,
        intervalDays: '4',
        kind: 'peptide',
        notes: '',
        scheduleType: 'every_n_days',
        timeOfDay: '09:00',
        weekday: null,
      },
      new Date(2026, 2, 13, 9, 0, 0, 0)
    );

    const compounds = await repositories.compounds.listAll();
    const protocols = await repositories.protocols.listAll();

    expect(compounds).toHaveLength(1);
    expect(protocols).toHaveLength(2);
    expect(protocols.every((protocol) => protocol.compoundId === compounds[0]?.id)).toBe(true);

    await client.close();
  });
});

import type { DatabaseClient } from '@/src/lib/database/client';
import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { runMigrations } from '@/src/lib/database/migrations';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import {
  createAtlasRepositories,
  type AtlasRepositories,
} from '@/src/lib/database/repositories';
import {
  getTimelineFeed,
  getTodaySnapshot,
  logTodayAction,
} from '@/src/features/day-loop/service';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';

jest.mock('@/src/lib/database', () => ({
  getAtlasDatabaseClient: jest.fn(),
  getAtlasRepositories: jest.fn(),
}));

const DAY_MS = 24 * 60 * 60 * 1000;

describe('day loop service', () => {
  it('logs a taken dose, advances next due, and adds a timeline event', async () => {
    await withDayLoopHarness(async (repositories) => {
      const now = new Date(2026, 2, 12, 7, 30, 0, 0);
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Wegovy',
        doseAmount: '0.25',
        doseUnit: 'mg',
        intervalDays: '1',
        kind: 'glp',
        now,
        scheduleType: 'weekly',
        timeOfDay: '08:00',
        weekday: 4,
      });
      const vial = await repositories.vials.create({
        concentrationUnit: null,
        concentrationValue: null,
        label: 'Weekly pen',
        lowStockThreshold: 1,
        protocolId: created.protocol.id,
        quantityUnit: 'dose',
        remainingQuantity: 4,
        startingQuantity: 4,
        volumeMl: null,
      });
      await repositories.protocols.update({
        id: created.protocol.id,
        linkedVialId: vial.id,
      });
      const site = await repositories.sites.create({
        bodyArea: 'abdomen',
        name: 'Left abdomen',
        notes: null,
      });

      const before = await getTodaySnapshot(now);

      expect(before.protocolCount).toBe(1);
      expect(before.nextDue).toMatchObject({
        id: expect.any(String),
        protocolId: created.protocol.id,
        protocolName: created.protocol.name,
        source: 'generated',
        state: 'next_due',
      });

      const nextDue = before.nextDue;
      expect(nextDue).not.toBeNull();

      await logTodayAction({
        action: 'mark_taken',
        notes: 'Felt routine and quick.',
        occurrenceId: nextDue!.id,
        protocolId: nextDue!.protocolId,
        scheduledFor: nextDue!.scheduledFor,
        siteId: site.id,
      });

      const savedEvents = await repositories.logEvents.listByProtocolId(created.protocol.id);
      expect(savedEvents).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'completed',
            occurrenceId: nextDue!.id,
            protocolId: created.protocol.id,
            quantity: 0.25,
            quantityUnit: 'mg',
            siteId: site.id,
            vialId: vial.id,
          }),
        ])
      );
      const updatedVial = await repositories.vials.getById(vial.id);
      expect(updatedVial?.remainingQuantity).toBe(3);

      const after = await getTodaySnapshot(new Date(2026, 2, 12, 9, 0, 0, 0));

      expect(after.overdue).toHaveLength(0);
      expect(after.nextDue).not.toBeNull();
      expect(after.nextDue?.id).not.toBe(nextDue!.id);
      expect(
        new Date(after.nextDue!.scheduledFor).getTime() -
          new Date(nextDue!.scheduledFor).getTime()
      ).toBeGreaterThan(6 * DAY_MS);

      const timeline = await getTimelineFeed(
        {
          dateWindow: 'all',
          protocolId: 'all',
        },
        new Date(2026, 2, 12, 9, 0, 0, 0)
      );

      expect(timeline).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'logged_dose',
            protocolId: created.protocol.id,
          }),
          expect.objectContaining({
            eventType: 'protocol_created',
            protocolId: created.protocol.id,
          }),
        ])
      );
    });
  });

  it('skips the current occurrence without mutating history and advances the schedule', async () => {
    await withDayLoopHarness(async (repositories) => {
      const now = new Date(2026, 2, 12, 7, 45, 0, 0);
      await createProtocolFixture(repositories, {
        compoundName: 'BPC-157',
        doseAmount: '250',
        doseUnit: 'mcg',
        intervalDays: '2',
        kind: 'peptide',
        now,
        scheduleType: 'every_n_days',
        timeOfDay: '08:00',
        weekday: null,
      });

      const before = await getTodaySnapshot(now);
      const nextDue = before.nextDue;

      expect(nextDue).not.toBeNull();

      await logTodayAction({
        action: 'skip',
        notes: 'Travel day.',
        occurrenceId: nextDue!.id,
        protocolId: nextDue!.protocolId,
        scheduledFor: nextDue!.scheduledFor,
      });

      const after = await getTodaySnapshot(new Date(2026, 2, 12, 9, 0, 0, 0));
      expect(after.nextDue).not.toBeNull();
      expect(after.nextDue?.id).not.toBe(nextDue!.id);
      expect(
        new Date(after.nextDue!.scheduledFor).getTime() -
          new Date(nextDue!.scheduledFor).getTime()
      ).toBeGreaterThanOrEqual(2 * DAY_MS);

      const events = await repositories.logEvents.listAll();
      expect(events).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'skipped',
            notes: 'Travel day.',
            occurrenceId: nextDue!.id,
          }),
        ])
      );

      const timeline = await getTimelineFeed(
        {
          dateWindow: 'all',
          protocolId: 'all',
        },
        new Date(2026, 2, 12, 9, 0, 0, 0)
      );

      expect(timeline).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'skipped_dose',
            protocolId: nextDue!.protocolId,
          }),
        ])
      );
    });
  });

  it('reschedules an occurrence into a new upcoming item while keeping an immutable log', async () => {
    await withDayLoopHarness(async (repositories) => {
      const now = new Date(2026, 2, 12, 7, 30, 0, 0);
      await createProtocolFixture(repositories, {
        compoundName: 'Custom stack',
        doseAmount: '5',
        doseUnit: 'units',
        intervalDays: '1',
        kind: 'custom',
        now,
        scheduleType: 'weekly',
        timeOfDay: '08:00',
        weekday: 4,
      });

      const before = await getTodaySnapshot(now);
      const nextDue = before.nextDue;
      const movedTo = new Date(2026, 2, 13, 8, 0, 0, 0).toISOString();

      expect(nextDue).not.toBeNull();

      await logTodayAction({
        action: 'reschedule',
        notes: 'Moved to tomorrow morning.',
        nextScheduledFor: movedTo,
        occurrenceId: nextDue!.id,
        protocolId: nextDue!.protocolId,
        scheduledFor: nextDue!.scheduledFor,
      });

      const after = await getTodaySnapshot(new Date(2026, 2, 12, 9, 0, 0, 0));
      expect(after.nextDue).toMatchObject({
        id: expect.stringContaining('rescheduled:'),
        originalOccurrenceId: nextDue!.id,
        scheduledFor: movedTo,
        source: 'rescheduled',
        state: 'next_due',
      });

      const events = await repositories.logEvents.listAll();
      expect(events).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            effectiveAt: movedTo,
            eventType: 'rescheduled',
            notes: 'Moved to tomorrow morning.',
            occurrenceId: nextDue!.id,
          }),
        ])
      );

      const timeline = await getTimelineFeed(
        {
          dateWindow: 'all',
          protocolId: 'all',
        },
        new Date(2026, 2, 12, 9, 0, 0, 0)
      );

      expect(timeline).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            eventType: 'rescheduled_dose',
            protocolId: nextDue!.protocolId,
          }),
        ])
      );
    });
  });

  it('filters timeline items by protocol and date window', async () => {
    await withDayLoopHarness(async (repositories) => {
      const now = new Date();
      const first = await createProtocolFixture(repositories, {
        compoundName: 'Protocol A',
        doseAmount: '1',
        doseUnit: 'mg',
        intervalDays: '1',
        kind: 'glp',
        now,
        scheduleType: 'weekly',
        timeOfDay: '08:00',
        weekday: now.getDay(),
      });
      const second = await createProtocolFixture(repositories, {
        compoundName: 'Protocol B',
        doseAmount: '2',
        doseUnit: 'mg',
        intervalDays: '3',
        kind: 'peptide',
        now,
        scheduleType: 'every_n_days',
        timeOfDay: '09:00',
        weekday: null,
      });
      const oldTimestamp = new Date(now.getTime() - 40 * DAY_MS).toISOString();

      await repositories.logEvents.create({
        effectiveAt: oldTimestamp,
        eventType: 'skipped',
        loggedAt: oldTimestamp,
        notes: 'Older skipped record.',
        occurrenceId: 'old-occurrence',
        protocolId: first.protocol.id,
        source: 'user',
      });

      const filteredByProtocol = await getTimelineFeed(
        {
          dateWindow: 'all',
          protocolId: second.protocol.id,
        },
        now
      );

      expect(filteredByProtocol).not.toHaveLength(0);
      expect(filteredByProtocol.every((item) => item.protocolId === second.protocol.id)).toBe(true);

      const filteredByDate = await getTimelineFeed(
        {
          dateWindow: 'last_7_days',
          protocolId: first.protocol.id,
        },
        now
      );

      expect(
        filteredByDate.some(
          (item) => item.eventType === 'skipped_dose'
        )
      ).toBe(false);
    });
  });
});

async function withDayLoopHarness(
  run: (repositories: AtlasRepositories) => Promise<void>
) {
  const client = await createSqlJsDatabaseClient();
  await runMigrations(client);
  const repositories = createAtlasRepositories(client);
  const getClientSpy = jest.mocked(getAtlasDatabaseClient).mockResolvedValue(client);
  const getRepositoriesSpy = jest
    .mocked(getAtlasRepositories)
    .mockResolvedValue(repositories);

  try {
    await run(repositories);
  } finally {
    getClientSpy.mockReset();
    getRepositoriesSpy.mockReset();
    await closeClient(client);
  }
}

async function closeClient(client: DatabaseClient) {
  await client.close();
}

async function createProtocolFixture(
  repositories: AtlasRepositories,
  {
    compoundName,
    doseAmount,
    doseUnit,
    intervalDays,
    kind,
    now,
    scheduleType,
    timeOfDay,
    weekday,
  }: {
    compoundName: string;
    doseAmount: string;
    doseUnit: string;
    intervalDays: string;
    kind: 'custom' | 'glp' | 'peptide';
    now: Date;
    scheduleType: 'every_n_days' | 'weekly';
    timeOfDay: string;
    weekday: number | null;
  }
) {
  return createProtocolInRepositories(repositories, {
    compoundMode: 'new',
    compoundName,
    doseAmount,
    doseUnit,
    existingCompoundId: null,
    intervalDays,
    kind,
    notes: '',
    scheduleType,
    timeOfDay,
    weekday,
  }, now);
}

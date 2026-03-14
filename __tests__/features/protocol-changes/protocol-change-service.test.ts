import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import type { AtlasNotificationClient } from '@/src/lib/notifications/client';
import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import { runMigrations } from '@/src/lib/database/migrations';
import { createAtlasRepositories, type AtlasRepositories } from '@/src/lib/database/repositories';
import { createEmptyOnboardingDraft } from '@/src/features/onboarding/schema';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';
import {
  buildProtocolChangePreview,
  commitProtocolChange,
  getProtocolChangeDetail,
} from '@/src/features/protocol-changes/service';
import { regenerateProtocolReminders } from '@/src/features/reminders/service';
import { getTodaySnapshot, logTodayAction, buildOccurrencesForBundle } from '@/src/features/day-loop/service';

jest.mock('@/src/lib/database', () => ({
  getAtlasDatabaseClient: jest.fn(),
  getAtlasRepositories: jest.fn(),
}));

jest.mock('@/src/lib/notifications/expo-notification-client', () => ({
  getAtlasNotificationClient: jest.fn(),
}));

describe('protocol change studio service', () => {
  beforeEach(() => {
    useOnboardingStore.setState((state) => ({
      ...state,
      draft: createEmptyOnboardingDraft(),
    }));
  });

  it('future-only edits preserve historical logs and add an audit entry', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Wegovy',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });
      const before = await getTodaySnapshot(new Date(2026, 2, 12, 7, 30, 0, 0));

      await logTodayAction({
        action: 'mark_taken',
        occurrenceId: before.nextDue!.id,
        protocolId: created.protocol.id,
        scheduledFor: before.nextDue!.scheduledFor,
      });

      const historicalBefore = await repositories.logEvents.listByProtocolId(created.protocol.id);

      await commitProtocolChange(created.protocol.id, {
        changeType: 'future_dose',
        doseAmount: '0.5',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const historicalAfter = await repositories.logEvents.listByProtocolId(created.protocol.id);
      const audits = await repositories.protocolChangeAudits.listByProtocolId(created.protocol.id);

      expect(historicalAfter).toEqual(historicalBefore);
      expect(audits.at(0)?.summary).toContain('Future saved amount changes');
    });
  });

  it('pause removes future reminders and resume restores future occurrences', async () => {
    await withHarness(async (repositories, notificationClient) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Pause test',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'future_dose',
        doseAmount: '1',
        doseUnit: 'mg',
        effectiveDate: '2026-03-12',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'future_time',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-12',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '09:30',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'every_n_days',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-12',
        intervalDays: '2',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '09:30',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'pause',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-12',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const pausedToday = await getTodaySnapshot(new Date(2026, 2, 12, 9, 0, 0, 0));
      const pausedReminders = await regenerateProtocolReminders(created.protocol.id, {
        notificationClient,
        repositories,
      });

      expect(pausedToday.nextDue).toBeNull();
      expect(pausedReminders).toHaveLength(0);

      await commitProtocolChange(created.protocol.id, {
        changeType: 'resume',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-12',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const resumedDetail = await getProtocolChangeDetail(created.protocol.id, { repositories });
      const resumedToday = await getTodaySnapshot(new Date(2026, 2, 12, 9, 0, 0, 0));

      expect(resumedToday.nextDue).not.toBeNull();
      expect(resumedDetail?.activeSnapshot.cadenceLabel).toBe('Every 2 days at 9:30 AM');
      expect(resumedDetail?.activeSnapshot.doseLabel).toBe('1 mg');
    });
  });

  it('titration and rest edits recalculate future occurrences safely', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Phase test',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });

      const titrationPreview = await buildProtocolChangePreview(created.protocol.id, {
        changeType: 'titration',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 30,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '0.5',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      expect(titrationPreview.occurrenceChanges.length).toBeGreaterThan(0);

      await commitProtocolChange(created.protocol.id, {
        changeType: 'rest_period',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 30,
        restLengthDays: '10',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const restWindowToday = await getTodaySnapshot(new Date(2026, 2, 22, 9, 0, 0, 0));
      expect(restWindowToday.nextDue).not.toBeNull();
      expect(new Date(restWindowToday.nextDue!.scheduledFor).getTime()).toBeGreaterThan(
        new Date('2026-03-29T00:00:00.000Z').getTime()
      );
    });
  });

  it('timezone changes do not duplicate future occurrences', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Travel test',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'timezone',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 30,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/Los_Angeles',
        timezoneStrategy: 'keep_home_timezone',
        weekday: 4,
      });

      const detail = await getProtocolChangeDetail(created.protocol.id, { repositories });
      const occurrences = buildOccurrencesForBundle(
        {
          ...detail!.bundle,
          logEvents: detail!.bundle.logEvents ?? [],
        },
        new Date(2026, 2, 20, 9, 0, 0, 0)
      );
      const uniqueIds = new Set(occurrences.map((occurrence) => occurrence.id));

      expect(uniqueIds.size).toBe(occurrences.length);
    });
  });

  it('uses privacy-safe labels in change previews when discreet mode is enabled', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Wegovy',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });
      const vial = await repositories.vials.create({
        protocolId: created.protocol.id,
        compoundId: created.compound?.id ?? null,
        label: 'Blue vial',
        lowStockThreshold: 1,
        quantityUnit: 'dose',
        remainingQuantity: 4,
        startingQuantity: 4,
      });

      await repositories.protocolRevisions.update({
        id: created.revision.id,
        linkedVialId: vial.id,
      });

      const preview = await buildProtocolChangePreview(
        created.protocol.id,
        {
          changeType: 'future_time',
          doseAmount: '',
          doseUnit: 'mg',
          effectiveDate: '2026-03-20',
          intervalDays: '1',
          linkedVialId: null,
          missedDosePolicy: 'skip_and_continue',
          notes: '',
          previewWindowDays: 14,
          restLengthDays: '7',
          timeOfDay: '09:30',
          titrationDoseAmount: '',
          titrationDoseUnit: 'mg',
          titrationLengthDays: '14',
          timezone: 'America/New_York',
          timezoneStrategy: 'keep_local_clock',
          weekday: 4,
        },
        {
          privacy: {
            discreetNotifications: true,
            hideSensitiveLabels: true,
          },
          referenceNow: new Date(2026, 2, 12, 7, 30, 0, 0),
          repositories,
        }
      );

      expect(preview.currentReminderLabel).toContain('Private routine');
      expect(preview.currentReminderLabel).not.toContain('Wegovy');
      expect(preview.inventoryForecastBefore).toContain('Linked vial until');
      expect(preview.inventoryForecastBefore).not.toContain('Blue vial');
    });
  });

  it('vial switch-over uses only the active future vial and does not double-decrement inventory', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Inventory switch',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });
      const firstVial = await repositories.vials.create({
        protocolId: created.protocol.id,
        compoundId: created.compound?.id ?? null,
        label: 'Current vial',
        startingQuantity: 4,
        remainingQuantity: 4,
        quantityUnit: 'dose',
      });
      const secondVial = await repositories.vials.create({
        protocolId: created.protocol.id,
        compoundId: created.compound?.id ?? null,
        label: 'Next vial',
        startingQuantity: 4,
        remainingQuantity: 4,
        quantityUnit: 'dose',
      });

      await repositories.protocolRevisions.update({
        id: created.revision.id,
        linkedVialId: firstVial.id,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'vial_switch',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: secondVial.id,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const today = await getTodaySnapshot(new Date(2026, 2, 20, 9, 0, 0, 0));
      await logTodayAction({
        action: 'mark_taken',
        occurrenceId: today.nextDue!.id,
        protocolId: created.protocol.id,
        scheduledFor: today.nextDue!.scheduledFor,
      });

      const updatedFirst = await repositories.vials.getById(firstVial.id);
      const updatedSecond = await repositories.vials.getById(secondVial.id);

      expect(updatedFirst?.remainingQuantity).toBe(4);
      expect(updatedSecond?.remainingQuantity).toBe(3);
    });
  });

  it('chains same-day revision ancestry using revision order', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Revision lineage',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'future_dose',
        doseAmount: '0.5',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '08:00',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'future_time',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '09:30',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      await commitProtocolChange(created.protocol.id, {
        changeType: 'every_n_days',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '2',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '09:30',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const revisions = await repositories.protocolRevisions.listByProtocolId(created.protocol.id);
      const sameDayRevisions = revisions.filter(
        (revision) => revision.effectiveFrom === '2026-03-20T00:00:00.000Z'
      );

      expect(sameDayRevisions).toHaveLength(3);
      expect(sameDayRevisions[1]?.previousRevisionId).toBe(sameDayRevisions[0]?.id);
      expect(sameDayRevisions[2]?.previousRevisionId).toBe(sameDayRevisions[1]?.id);
    });
  });

  it('previewing and cancelling commits nothing', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Cancel test',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });
      const beforeRevisions = await repositories.protocolRevisions.listByProtocolId(created.protocol.id);
      const beforeAudits = await repositories.protocolChangeAudits.listByProtocolId(created.protocol.id);

      await buildProtocolChangePreview(created.protocol.id, {
        changeType: 'future_time',
        doseAmount: '',
        doseUnit: 'mg',
        effectiveDate: '2026-03-20',
        intervalDays: '1',
        linkedVialId: null,
        missedDosePolicy: 'skip_and_continue',
        notes: '',
        previewWindowDays: 14,
        restLengthDays: '7',
        timeOfDay: '09:30',
        titrationDoseAmount: '',
        titrationDoseUnit: 'mg',
        titrationLengthDays: '14',
        timezone: 'America/New_York',
        timezoneStrategy: 'keep_local_clock',
        weekday: 4,
      });

      const afterRevisions = await repositories.protocolRevisions.listByProtocolId(created.protocol.id);
      const afterAudits = await repositories.protocolChangeAudits.listByProtocolId(created.protocol.id);

      expect(afterRevisions).toEqual(beforeRevisions);
      expect(afterAudits).toEqual(beforeAudits);
    });
  });

  it('shares a stable reference clock between detail and preview generation', async () => {
    await withHarness(async (repositories) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Clock test',
        now: new Date(2026, 2, 12, 7, 0, 0, 0),
        weekday: 4,
      });
      const beforeDue = new Date(2026, 2, 12, 7, 30, 0, 0);
      const afterDue = new Date(2026, 2, 12, 9, 30, 0, 0);

      const detail = await getProtocolChangeDetail(created.protocol.id, {
        referenceNow: beforeDue,
        repositories,
      });
      const beforePreview = await buildProtocolChangePreview(
        created.protocol.id,
        {
          changeType: 'future_time',
          doseAmount: '',
          doseUnit: 'mg',
          effectiveDate: '2026-03-20',
          intervalDays: '1',
          linkedVialId: null,
          missedDosePolicy: 'skip_and_continue',
          notes: '',
          previewWindowDays: 14,
          restLengthDays: '7',
          timeOfDay: '09:30',
          titrationDoseAmount: '',
          titrationDoseUnit: 'mg',
          titrationLengthDays: '14',
          timezone: 'America/New_York',
          timezoneStrategy: 'keep_local_clock',
          weekday: 4,
        },
        {
          referenceNow: beforeDue,
          repositories,
        }
      );
      const afterPreview = await buildProtocolChangePreview(
        created.protocol.id,
        {
          changeType: 'future_time',
          doseAmount: '',
          doseUnit: 'mg',
          effectiveDate: '2026-03-20',
          intervalDays: '1',
          linkedVialId: null,
          missedDosePolicy: 'skip_and_continue',
          notes: '',
          previewWindowDays: 14,
          restLengthDays: '7',
          timeOfDay: '09:30',
          titrationDoseAmount: '',
          titrationDoseUnit: 'mg',
          titrationLengthDays: '14',
          timezone: 'America/New_York',
          timezoneStrategy: 'keep_local_clock',
          weekday: 4,
        },
        {
          referenceNow: afterDue,
          repositories,
        }
      );

      expect(beforePreview.nextDueBefore?.scheduledFor).toBe(detail?.nextDue?.scheduledFor ?? null);
      expect(beforePreview.nextDueBefore?.scheduledFor).not.toBe(
        afterPreview.nextDueBefore?.scheduledFor
      );
    });
  });
});

async function withHarness(
  run: (repositories: AtlasRepositories, notificationClient: FakeNotificationClient) => Promise<void>
) {
  const client = await createSqlJsDatabaseClient();
  await runMigrations(client);
  const repositories = createAtlasRepositories(client);
  const notificationClient = new FakeNotificationClient();
  jest.mocked(getAtlasDatabaseClient).mockResolvedValue(client);
  jest.mocked(getAtlasRepositories).mockResolvedValue(repositories);
  const notifications = jest.requireMock('@/src/lib/notifications/expo-notification-client');
  notifications.getAtlasNotificationClient.mockReturnValue(notificationClient);

  try {
    await run(repositories, notificationClient);
  } finally {
    await client.close();
  }
}

async function createProtocolFixture(
  repositories: AtlasRepositories,
  {
    compoundName,
    now,
    weekday,
  }: {
    compoundName: string;
    now: Date;
    weekday: number | null;
  }
) {
  return createProtocolInRepositories(
    repositories,
    {
      compoundMode: 'new',
      compoundName,
      doseAmount: '0.25',
      doseUnit: 'mg',
      existingCompoundId: null,
      intervalDays: '1',
      kind: 'glp',
      notes: '',
      scheduleType: 'weekly',
      timeOfDay: '08:00',
      weekday,
    },
    now
  );
}

class FakeNotificationClient implements AtlasNotificationClient {
  cancelled: string[] = [];
  scheduled: {
    body: string;
    data: { occurrenceId: string; protocolId: string; scheduledFor: string };
    notificationId: string;
    silent: boolean;
    title: string;
    triggerAt: Date;
  }[] = [];

  async cancelScheduledNotification(notificationId: string) {
    this.cancelled.push(notificationId);
  }

  async configureReminderCategories() {}

  async scheduleLocalReminder(input: {
    body: string;
    data: { occurrenceId: string; protocolId: string; scheduledFor: string };
    silent: boolean;
    title: string;
    triggerAt: Date;
  }) {
    const notificationId = `notification_${this.scheduled.length + 1}`;
    this.scheduled.push({
      ...input,
      notificationId,
    });
    return notificationId;
  }

  subscribeToReminderResponses() {
    return () => {};
  }
}

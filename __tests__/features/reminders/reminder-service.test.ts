import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import type { AtlasNotificationClient } from '@/src/lib/notifications/client';
import { getAtlasRepositories } from '@/src/lib/database';
import { runMigrations } from '@/src/lib/database/migrations';
import { createAtlasRepositories, type AtlasRepositories } from '@/src/lib/database/repositories';
import { createEmptyOnboardingDraft } from '@/src/features/onboarding/schema';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { createProtocolInRepositories } from '@/src/features/protocols/persistence';
import {
  regenerateProtocolReminders,
  updateReminderPreferences,
} from '@/src/features/reminders/service';

jest.mock('@/src/lib/database', () => ({
  getAtlasRepositories: jest.fn(),
}));

jest.mock('@/src/lib/notifications/expo-notification-client', () => ({
  getAtlasNotificationClient: jest.fn(),
}));

describe('reminder service', () => {
  beforeEach(() => {
    useOnboardingStore.setState((state) => ({
      ...state,
      draft: createEmptyOnboardingDraft(),
    }));
  });

  it('schedules a local reminder from the next due occurrence', async () => {
    await withReminderHarness(async (repositories, notificationClient) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Wegovy',
        now: new Date(2026, 2, 13, 7, 0, 0, 0),
        weekday: 6,
      });

      const scheduled = await regenerateProtocolReminders(created.protocol.id, {
        notificationClient,
        repositories,
      });

      expect(scheduled).toHaveLength(1);
      expect(notificationClient.scheduled).toHaveLength(1);
      expect(notificationClient.scheduled[0]).toMatchObject({
        body: expect.stringContaining('Wegovy'),
        data: expect.objectContaining({
          protocolId: created.protocol.id,
        }),
        title: 'Wegovy',
      });
      expect(scheduled[0]).toMatchObject({
        occurrenceId: expect.any(String),
        privacyMode: 'full_detail',
        protocolId: created.protocol.id,
        status: 'scheduled',
      });
    });
  });

  it('regenerates future reminders when protocol timing changes', async () => {
    await withReminderHarness(async (repositories, notificationClient) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'BPC-157',
        kind: 'peptide',
        now: new Date(2026, 2, 13, 7, 0, 0, 0),
        timeOfDay: '08:00',
        weekday: 5,
      });

      const first = await regenerateProtocolReminders(created.protocol.id, {
        notificationClient,
        repositories,
      });
      expect(first).toHaveLength(1);
      expect(notificationClient.scheduled).toHaveLength(1);

      const revisionRules = await repositories.protocolRevisionRules.listByRevisionId(created.revision.id);

      await repositories.protocolRevisionRules.update({
        id: revisionRules[0]!.id,
        timeOfDay: '09:30',
        weekday: 6,
      });

      const second = await regenerateProtocolReminders(created.protocol.id, {
        notificationClient,
        repositories,
      });
      const persisted = await repositories.reminders.listByProtocolId(created.protocol.id);

      expect(second).toHaveLength(1);
      expect(notificationClient.cancelled).toEqual([notificationClient.scheduled[0].notificationId]);
      expect(notificationClient.scheduled).toHaveLength(2);
      expect(notificationClient.scheduled[1].triggerAt.toISOString()).not.toBe(
        notificationClient.scheduled[0].triggerAt.toISOString()
      );
      expect(persisted).toHaveLength(1);
      expect(persisted[0].notificationId).toBe(notificationClient.scheduled[1].notificationId);
    });
  });

  it('rebuilds reminders when privacy settings change', async () => {
    await withReminderHarness(async (repositories, notificationClient) => {
      const created = await createProtocolFixture(repositories, {
        compoundName: 'Custom stack',
        kind: 'custom',
        now: new Date(2026, 2, 13, 7, 0, 0, 0),
        weekday: 6,
      });

      await regenerateProtocolReminders(created.protocol.id, {
        notificationClient,
        repositories,
      });

      useOnboardingStore.setState((state) => ({
        ...state,
        draft: {
          ...state.draft,
          privacy: {
            ...state.draft.privacy,
            discreetNotifications: true,
            hideSensitiveLabels: true,
          },
        },
      }));

      await updateReminderPreferences(
        {
          leadTimeMinutes: 15,
          privacyMode: 'full_detail',
        },
        {
          notificationClient,
          repositories,
        }
      );

      const persisted = await repositories.reminders.listAll();

      expect(notificationClient.scheduled.at(-1)).toMatchObject({
        body: expect.stringContaining('private routine'),
        title: 'Atlas reminder',
      });
      expect(persisted[0]).toMatchObject({
        privacyMode: 'full_detail',
      });
    });
  });
});

async function withReminderHarness(
  run: (repositories: AtlasRepositories, notificationClient: FakeNotificationClient) => Promise<void>
) {
  const client = await createSqlJsDatabaseClient();
  await runMigrations(client);
  const repositories = createAtlasRepositories(client);
  const notificationClient = new FakeNotificationClient();
  jest.mocked(getAtlasRepositories).mockResolvedValue(repositories);

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
    kind = 'glp',
    now,
    timeOfDay = '08:00',
    weekday = 6,
  }: {
    compoundName: string;
    kind?: 'custom' | 'glp' | 'peptide';
    now: Date;
    timeOfDay?: string;
    weekday?: number | null;
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
      kind,
      notes: '',
      scheduleType: 'weekly',
      timeOfDay,
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

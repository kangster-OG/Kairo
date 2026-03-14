import { z } from 'zod';

import { trackAnalyticsEvent } from '@/src/lib/analytics/service';
import { atlasQueryClient } from '@/src/lib/query-client';
import {
  getAtlasRepositories,
  type Reminder,
  type ReminderPreference,
} from '@/src/lib/database';
import type { AtlasRepositories } from '@/src/lib/database/repositories';
import {
  ATLAS_REMINDER_ACTION_MARK_TAKEN,
  ATLAS_REMINDER_ACTION_SKIP,
  type AtlasNotificationClient,
  type NotificationResponsePayload,
} from '@/src/lib/notifications/client';
import { getAtlasNotificationClient } from '@/src/lib/notifications/expo-notification-client';
import { buildUnresolvedOccurrences, logTodayAction } from '@/src/features/day-loop/service';
import { buildReminderPreview } from '@/src/features/reminders/privacy';
import { useOnboardingStore } from '@/src/features/onboarding/store';
import { listProtocolRevisionBundles } from '@/src/features/protocols/bundles';
import { indexProtocolAliases } from '@/src/features/trust-vault/privacy';

const notificationResponseSchema = z.object({
  actionIdentifier: z.string(),
  occurrenceId: z.string().min(1),
  protocolId: z.string().min(1),
  scheduledFor: z.string().min(1),
});

type ReminderServiceDependencies = {
  notificationClient?: AtlasNotificationClient;
  repositories?: AtlasRepositories;
};

export type ReminderPreferenceUpdateInput = Partial<
  Pick<ReminderPreference, 'leadTimeMinutes' | 'privacyMode' | 'remindersEnabled'>
>;

export async function getReminderPreferences(dependencies: ReminderServiceDependencies = {}) {
  const repositories = await resolveRepositories(dependencies.repositories);
  return repositories.reminderPreferences.get();
}

export async function updateReminderPreferences(
  input: ReminderPreferenceUpdateInput,
  dependencies: ReminderServiceDependencies = {}
) {
  const repositories = await resolveRepositories(dependencies.repositories);
  const preferences = await repositories.reminderPreferences.update({
    id: 'default',
    leadTimeMinutes: input.leadTimeMinutes,
    privacyMode: input.privacyMode,
    remindersEnabled: input.remindersEnabled,
  });

  await regenerateAllProtocolReminders({
    notificationClient: dependencies.notificationClient,
    repositories,
  });

  return preferences;
}

export async function regenerateAllProtocolReminders(
  dependencies: ReminderServiceDependencies = {}
): Promise<Reminder[]> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const protocols = await repositories.protocols.listActive();
  const scheduled: Reminder[] = [];

  for (const protocol of protocols) {
    const next = await regenerateProtocolReminders(protocol.id, {
      notificationClient: dependencies.notificationClient,
      repositories,
    });

    scheduled.push(...next);
  }

  return scheduled;
}

export async function regenerateProtocolReminders(
  protocolId: string,
  dependencies: ReminderServiceDependencies = {}
): Promise<Reminder[]> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const notificationClient = dependencies.notificationClient ?? getAtlasNotificationClient();
  const [preferences, existingRows, protocol] = await Promise.all([
    repositories.reminderPreferences.get(),
    repositories.reminders.listByProtocolId(protocolId),
    repositories.protocols.getById(protocolId),
  ]);

  await cancelReminderRows(existingRows, notificationClient, repositories);

  if (!protocol || protocol.status !== 'active' || !preferences.remindersEnabled) {
    return [];
  }

  const occurrence = await getNextReminderOccurrence(protocolId, repositories);

  if (!occurrence) {
    return [];
  }

  const [aliases, profile] = await Promise.all([
    repositories.protocolAliases.listAllActive(),
    repositories.privacyProfiles.get(),
  ]);
  const aliasLookup = indexProtocolAliases(aliases);

  const triggerAt = new Date(new Date(occurrence.scheduledFor).getTime() - preferences.leadTimeMinutes * 60_000);
  if (triggerAt.getTime() <= Date.now() + 5_000) {
    return [];
  }

  const privacy = useOnboardingStore.getState().draft.privacy;
  const preview = buildReminderPreview(occurrence, preferences, privacy, profile, aliasLookup);
  const notificationId = await notificationClient.scheduleLocalReminder({
    body: preview.body,
    data: {
      occurrenceId: occurrence.id,
      protocolId,
      scheduledFor: occurrence.scheduledFor,
    },
    silent: preview.isSilent,
    title: preview.title,
    triggerAt,
  });

  const reminder = await repositories.reminders.create({
    body: preview.body,
    channel: 'local_notification',
    discreetCopyEnabled: privacy.discreetNotifications || privacy.hideSensitiveLabels,
    isEnabled: true,
    notificationId,
    occurrenceId: occurrence.id,
    offsetMinutes: preferences.leadTimeMinutes * -1,
    privacyMode: preferences.privacyMode,
    protocolId,
    scheduledFor: triggerAt.toISOString(),
    status: 'scheduled',
    title: preview.title,
  });

  trackAnalyticsEvent('reminder_scheduled', {
    occurrenceId: occurrence.id,
    privacyMode: preferences.privacyMode,
    protocolId,
  });

  return [reminder];
}

export async function handleReminderResponse(
  payload: NotificationResponsePayload,
  dependencies: ReminderServiceDependencies = {}
) {
  const parsed = notificationResponseSchema.parse(payload);

  if (
    parsed.actionIdentifier !== ATLAS_REMINDER_ACTION_MARK_TAKEN &&
    parsed.actionIdentifier !== ATLAS_REMINDER_ACTION_SKIP
  ) {
    return;
  }

  await logTodayAction({
    action:
      parsed.actionIdentifier === ATLAS_REMINDER_ACTION_MARK_TAKEN
        ? 'mark_taken'
        : 'skip',
    occurrenceId: parsed.occurrenceId,
    protocolId: parsed.protocolId,
    scheduledFor: parsed.scheduledFor,
  });

  await regenerateProtocolReminders(parsed.protocolId, dependencies);
  await invalidateProductQueries();
}

async function getNextReminderOccurrence(protocolId: string, repositories: AtlasRepositories) {
  const bundles = await listProtocolBundles(repositories);
  const bundle = bundles.find((item) => item.protocol.id === protocolId);

  if (!bundle) {
    return null;
  }

  return (
    buildUnresolvedOccurrences([bundle], new Date()).find(
      (occurrence) => occurrence.state === 'next_due' || occurrence.state === 'upcoming'
    ) ?? null
  );
}

async function listProtocolBundles(repositories: AtlasRepositories) {
  const bundles = await listProtocolRevisionBundles({
    includeLogs: true,
    repositories,
  });

  return bundles.map((bundle) => ({
    ...bundle,
    logEvents: bundle.logEvents ?? [],
  }));
}

async function cancelReminderRows(
  rows: Reminder[],
  notificationClient: AtlasNotificationClient,
  repositories: AtlasRepositories
) {
  for (const row of rows) {
    if (row.notificationId) {
      await notificationClient.cancelScheduledNotification(row.notificationId);
    }
  }

  if (rows.length > 0) {
    await repositories.reminders.deleteByProtocolId(rows[0].protocolId);
  }
}

async function resolveRepositories(repositories?: AtlasRepositories) {
  if (repositories) {
    return repositories;
  }

  return getAtlasRepositories();
}

async function invalidateProductQueries() {
  await Promise.all([
    atlasQueryClient.invalidateQueries({ queryKey: ['day-loop', 'today'] }),
    atlasQueryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
    atlasQueryClient.invalidateQueries({ queryKey: ['protocols', 'list'] }),
    atlasQueryClient.invalidateQueries({ queryKey: ['protocols', 'today-summary'] }),
  ]);
}

export async function bootstrapReminderNotifications() {
  const notificationClient = getAtlasNotificationClient();
  await notificationClient.configureReminderCategories();

  return notificationClient.subscribeToReminderResponses(async (payload) => {
    await handleReminderResponse(payload, { notificationClient });
  });
}

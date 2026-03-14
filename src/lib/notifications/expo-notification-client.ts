import * as Notifications from 'expo-notifications';

import {
  ATLAS_REMINDER_ACTION_MARK_TAKEN,
  ATLAS_REMINDER_ACTION_SKIP,
  ATLAS_REMINDER_CATEGORY_ID,
  type AtlasNotificationClient,
  type NotificationResponsePayload,
  type ScheduleLocalReminderInput,
} from '@/src/lib/notifications/client';

let expoNotificationClient: AtlasNotificationClient | null = null;

export function getAtlasNotificationClient(): AtlasNotificationClient {
  if (!expoNotificationClient) {
    expoNotificationClient = createExpoNotificationClient();
  }

  return expoNotificationClient;
}

function createExpoNotificationClient(): AtlasNotificationClient {
  return {
    async cancelScheduledNotification(notificationId) {
      await Notifications.cancelScheduledNotificationAsync(notificationId);
    },
    async configureReminderCategories() {
      await Notifications.setNotificationCategoryAsync(ATLAS_REMINDER_CATEGORY_ID, [
        {
          buttonTitle: 'Mark taken',
          identifier: ATLAS_REMINDER_ACTION_MARK_TAKEN,
          options: { opensAppToForeground: false },
        },
        {
          buttonTitle: 'Skip',
          identifier: ATLAS_REMINDER_ACTION_SKIP,
          options: { opensAppToForeground: false },
        },
      ]);

      await Notifications.setNotificationChannelAsync('atlas-reminders', {
        importance: Notifications.AndroidImportance.DEFAULT,
        name: 'Atlas reminders',
        sound: 'default',
      });
    },
    async scheduleLocalReminder(input: ScheduleLocalReminderInput) {
      return Notifications.scheduleNotificationAsync({
        content: {
          body: input.body,
          categoryIdentifier: ATLAS_REMINDER_CATEGORY_ID,
          data: input.data,
          sound: input.silent ? false : 'default',
          title: input.title,
        },
        trigger: {
          date: input.triggerAt,
          type: Notifications.SchedulableTriggerInputTypes.DATE,
        },
      });
    },
    subscribeToReminderResponses(handler) {
      const subscription = Notifications.addNotificationResponseReceivedListener((response) => {
        const rawData = response.notification.request.content.data as Record<string, unknown>;

        const payload: NotificationResponsePayload = {
          actionIdentifier: response.actionIdentifier,
          occurrenceId: String(rawData.occurrenceId ?? ''),
          protocolId: String(rawData.protocolId ?? ''),
          scheduledFor: String(rawData.scheduledFor ?? ''),
        };

        void handler(payload);
      });

      return () => {
        subscription.remove();
      };
    },
  };
}

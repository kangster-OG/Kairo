export const ATLAS_REMINDER_CATEGORY_ID = 'atlas-reminder-actions';
export const ATLAS_REMINDER_ACTION_MARK_TAKEN = 'atlas-mark-taken';
export const ATLAS_REMINDER_ACTION_SKIP = 'atlas-skip';

export type ReminderNotificationData = {
  occurrenceId: string;
  protocolId: string;
  scheduledFor: string;
};

export type ScheduleLocalReminderInput = {
  body: string;
  data: ReminderNotificationData;
  silent: boolean;
  title: string;
  triggerAt: Date;
};

export type NotificationResponsePayload = ReminderNotificationData & {
  actionIdentifier: string;
};

export interface AtlasNotificationClient {
  cancelScheduledNotification(notificationId: string): Promise<void>;
  configureReminderCategories(): Promise<void>;
  scheduleLocalReminder(input: ScheduleLocalReminderInput): Promise<string>;
  subscribeToReminderResponses(
    handler: (payload: NotificationResponsePayload) => void | Promise<void>
  ): () => void;
}

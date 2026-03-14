type AtlasAnalyticsEventName =
  | 'dose_logged'
  | 'export_requested'
  | 'low_stock_seen'
  | 'protocol_created'
  | 'reminder_scheduled';

export type AtlasAnalyticsEvent = {
  name: AtlasAnalyticsEventName;
  payload: Record<string, unknown>;
  timestamp: string;
};

const sessionEvents: AtlasAnalyticsEvent[] = [];
const onceKeys = new Set<string>();

export function trackAnalyticsEvent(
  name: AtlasAnalyticsEventName,
  payload: Record<string, unknown> = {}
) {
  const event: AtlasAnalyticsEvent = {
    name,
    payload,
    timestamp: new Date().toISOString(),
  };

  sessionEvents.push(event);

  if (__DEV__ && process.env.NODE_ENV !== 'test') {
    console.info('[Atlas analytics]', event.name, event.payload);
  }
}

export function trackAnalyticsEventOncePerSession(
  key: string,
  name: AtlasAnalyticsEventName,
  payload: Record<string, unknown> = {}
) {
  if (onceKeys.has(key)) {
    return;
  }

  onceKeys.add(key);
  trackAnalyticsEvent(name, payload);
}

export function getTrackedAnalyticsEventsForDev() {
  return [...sessionEvents];
}

export function resetTrackedAnalyticsEventsForTests() {
  sessionEvents.length = 0;
  onceKeys.clear();
}

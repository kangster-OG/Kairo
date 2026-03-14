import {
  getTrackedAnalyticsEventsForDev,
  resetTrackedAnalyticsEventsForTests,
  trackAnalyticsEvent,
  trackAnalyticsEventOncePerSession,
} from '@/src/lib/analytics/service';

describe('analytics service', () => {
  beforeEach(() => {
    resetTrackedAnalyticsEventsForTests();
  });

  it('records tracked events with payloads', () => {
    trackAnalyticsEvent('protocol_created', {
      kind: 'glp',
      protocolId: 'protocol-1',
    });

    expect(getTrackedAnalyticsEventsForDev()).toEqual([
      expect.objectContaining({
        name: 'protocol_created',
        payload: {
          kind: 'glp',
          protocolId: 'protocol-1',
        },
      }),
    ]);
  });

  it('only emits once-per-session events once for the same key', () => {
    trackAnalyticsEventOncePerSession('low-stock:vial-1', 'low_stock_seen', {
      vialId: 'vial-1',
    });
    trackAnalyticsEventOncePerSession('low-stock:vial-1', 'low_stock_seen', {
      vialId: 'vial-1',
    });
    trackAnalyticsEventOncePerSession('low-stock:vial-2', 'low_stock_seen', {
      vialId: 'vial-2',
    });

    expect(getTrackedAnalyticsEventsForDev()).toEqual([
      expect.objectContaining({
        name: 'low_stock_seen',
        payload: { vialId: 'vial-1' },
      }),
      expect.objectContaining({
        name: 'low_stock_seen',
        payload: { vialId: 'vial-2' },
      }),
    ]);
  });
});

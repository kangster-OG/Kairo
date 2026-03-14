import {
  buildReminderPreview,
  formatProtocolDisplayName,
  formatTimelineItemSummary,
  getEffectiveReminderPrivacyMode,
  getIsDiscreetModeEnabled,
} from '@/src/features/reminders/privacy';

describe('reminder privacy formatting', () => {
  const privacyOff = {
    discreetNotifications: false,
    hideSensitiveLabels: false,
  } as const;

  const privacyOn = {
    discreetNotifications: true,
    hideSensitiveLabels: true,
  } as const;

  it('keeps full detail when discreet mode is off', () => {
    expect(getIsDiscreetModeEnabled(privacyOff)).toBe(false);
    expect(getEffectiveReminderPrivacyMode('full_detail', privacyOff)).toBe('full_detail');
    expect(formatProtocolDisplayName('Wegovy', 'glp', privacyOff)).toBe('Wegovy');

    expect(
      buildReminderPreview(
        {
          kind: 'glp',
          protocolId: 'p1',
          protocolName: 'Wegovy',
          whenLabel: 'Today at 8:00 AM',
        },
        {
          privacyMode: 'full_detail',
        },
        privacyOff
      )
    ).toEqual({
      body: 'Wegovy is due today at 8:00 AM.',
      isSilent: false,
      title: 'Wegovy',
    });
  });

  it('forces safer notification wording when discreet mode is on', () => {
    expect(getIsDiscreetModeEnabled(privacyOn)).toBe(true);
    expect(getEffectiveReminderPrivacyMode('full_detail', privacyOn)).toBe('generic');
    expect(formatProtocolDisplayName('Wegovy', 'glp', privacyOn)).toBe('Private GLP protocol');

    expect(
      buildReminderPreview(
        {
          kind: 'glp',
          protocolId: 'p1',
          protocolName: 'Wegovy',
          whenLabel: 'Tomorrow at 8:00 AM',
        },
        {
          privacyMode: 'full_detail',
        },
        privacyOn
      )
    ).toEqual({
      body: 'A private routine is due tomorrow at 8:00 AM.',
      isSilent: false,
      title: 'Atlas reminder',
    });
  });

  it('formats timeline summaries generically in discreet mode', () => {
    expect(
      formatTimelineItemSummary(
        {
          eventType: 'logged_dose',
          protocolId: 'p1',
          protocolName: 'Wegovy',
          summary: 'Logged Wegovy as taken',
        },
        privacyOn
      )
    ).toBe('Logged a private dose as taken');

    expect(
      buildReminderPreview(
        {
          kind: 'custom',
          protocolId: 'p1',
          protocolName: 'Custom stack',
          whenLabel: 'Today at 8:00 AM',
        },
        {
          privacyMode: 'silent',
        },
        privacyOn
      )
    ).toEqual({
      body: 'Open Atlas when you are ready.',
      isSilent: true,
      title: 'Atlas',
    });
  });

  it('uses protocol aliases when alias mode is enabled', () => {
    expect(
      formatProtocolDisplayName(
        'Wegovy',
        'glp',
        privacyOff,
        { aliasModeEnabled: true },
        { aliasLabel: 'Evening plan' }
      )
    ).toBe('Evening plan');

    expect(
      buildReminderPreview(
        {
          kind: 'glp',
          protocolId: 'p1',
          protocolName: 'Wegovy',
          whenLabel: 'Today at 8:00 AM',
        },
        {
          privacyMode: 'full_detail',
        },
        privacyOff,
        { aliasModeEnabled: true },
        {
          p1: {
            aliasCompoundLabel: 'Blue vial',
            aliasLabel: 'Evening plan',
            archivedAt: null,
            createdAt: '2026-03-13T00:00:00.000Z',
            id: 'a1',
            protocolId: 'p1',
            updatedAt: '2026-03-13T00:00:00.000Z',
          },
        }
      )
    ).toEqual({
      body: 'Evening plan is due today at 8:00 AM.',
      isSilent: false,
      title: 'Evening plan',
    });
  });
});

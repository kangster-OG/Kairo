import { getNextDueAcrossBundles, getNextDueForBundle } from '@/src/lib/schedule/protocol-schedule';
import type { Compound, Protocol, ProtocolRule } from '@/src/lib/database/schemas';

function createProtocol(overrides: Partial<Protocol> = {}): Protocol {
  return {
    compoundId: 'cmp_1',
    createdAt: '2026-03-12T08:00:00.000Z',
    defaultTimeOfDay: '08:00',
    doseAmount: 0.25,
    doseUnit: 'mg',
    id: 'pro_1',
    kind: 'glp',
    linkedVialId: null,
    name: 'Weekly GLP',
    notes: null,
    siteRotationEnabled: false,
    siteTrackingEnabled: false,
    startDate: '2026-03-12',
    status: 'active',
    timezone: 'America/New_York',
    updatedAt: '2026-03-12T08:00:00.000Z',
    ...overrides,
  };
}

function createRule(overrides: Partial<ProtocolRule> = {}): ProtocolRule {
  return {
    anchorDate: '2026-03-12',
    createdAt: '2026-03-12T08:00:00.000Z',
    id: 'prl_1',
    intervalCount: 1,
    isActive: true,
    protocolId: 'pro_1',
    ruleType: 'weekly',
    timeOfDay: '08:00',
    updatedAt: '2026-03-12T08:00:00.000Z',
    weekday: 1,
    ...overrides,
  };
}

function createCompound(overrides: Partial<Compound> = {}): Compound {
  return {
    compoundType: 'glp',
    createdAt: '2026-03-12T08:00:00.000Z',
    displayName: 'Wegovy',
    id: 'cmp_1',
    isUserDefined: false,
    notes: null,
    slug: 'wegovy',
    updatedAt: '2026-03-12T08:00:00.000Z',
    ...overrides,
  };
}

describe('protocol schedule', () => {
  it('creates the next weekly occurrence on the selected day of week', () => {
    const nextDue = getNextDueForBundle(
      {
        compound: createCompound(),
        protocol: createProtocol(),
        rules: [createRule({ weekday: 1 })],
      },
      new Date(2026, 2, 12, 9, 0, 0, 0)
    );

    expect(nextDue?.doseLabel).toBe('0.25 mg');
    expect(nextDue?.scheduledFor).toBe(new Date(2026, 2, 16, 8, 0, 0, 0).toISOString());
  });

  it('creates the next interval occurrence every N days from the anchor date', () => {
    const nextDue = getNextDueForBundle(
      {
        compound: createCompound({ compoundType: 'other', displayName: 'Custom Blend' }),
        protocol: createProtocol({
          compoundId: 'cmp_2',
          kind: 'custom',
          name: 'Custom Blend',
        }),
        rules: [
          createRule({
            anchorDate: '2026-03-10',
            id: 'prl_2',
            intervalCount: 3,
            ruleType: 'every_n_days',
            weekday: null,
          }),
        ],
      },
      new Date(2026, 2, 12, 9, 0, 0, 0)
    );

    expect(nextDue?.scheduledFor).toBe(new Date(2026, 2, 13, 8, 0, 0, 0).toISOString());
    expect(nextDue?.cadenceLabel).toContain('Every 3 days');
  });

  it('selects the earliest next due across multiple active protocols', () => {
    const nextDue = getNextDueAcrossBundles(
      [
        {
          compound: createCompound(),
          protocol: createProtocol({
            defaultTimeOfDay: '20:00',
            id: 'pro_late',
            name: 'Evening GLP',
          }),
          rules: [createRule({ id: 'prl_late', protocolId: 'pro_late', weekday: 4, timeOfDay: '20:00' })],
        },
        {
          compound: createCompound({ compoundType: 'peptide', displayName: 'BPC-157', id: 'cmp_2', slug: 'bpc-157' }),
          protocol: createProtocol({
            compoundId: 'cmp_2',
            defaultTimeOfDay: '07:30',
            id: 'pro_early',
            kind: 'peptide',
            name: 'Morning peptide',
          }),
          rules: [
            createRule({
              anchorDate: '2026-03-10',
              id: 'prl_early',
              intervalCount: 2,
              protocolId: 'pro_early',
              ruleType: 'every_n_days',
              timeOfDay: '07:30',
              weekday: null,
            }),
          ],
        },
      ],
      new Date(2026, 2, 12, 6, 0, 0, 0)
    );

    expect(nextDue?.protocolId).toBe('pro_early');
    expect(nextDue?.whenLabel).toContain('Today');
  });
});

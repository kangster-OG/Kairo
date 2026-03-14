import type { Protocol, ProtocolRevisionRule, ProtocolRule, Vial } from '@/src/lib/database/schemas';

const DAY_MS = 24 * 60 * 60 * 1000;

export type DoseDecrement = {
  amount: number;
  basis: 'concentration' | 'dose' | 'matching_unit';
  unit: string;
};

export function getDoseDecrementForVial(protocol: Protocol, vial: Vial): DoseDecrement | null {
  if (protocol.doseAmount === null || !protocol.doseUnit) {
    return null;
  }

  const vialUnit = normalizeUnit(vial.quantityUnit);
  const doseUnit = normalizeUnit(protocol.doseUnit);

  if (vialUnit === 'dose') {
    return {
      amount: 1,
      basis: 'dose',
      unit: vial.quantityUnit,
    };
  }

  if (vialUnit === doseUnit) {
    return {
      amount: protocol.doseAmount,
      basis: 'matching_unit',
      unit: vial.quantityUnit,
    };
  }

  if (
    vialUnit === 'ml' &&
    vial.concentrationValue !== null &&
    vial.concentrationValue > 0 &&
    vial.concentrationUnit &&
    normalizeUnit(vial.concentrationUnit) === doseUnit
  ) {
    return {
      amount: protocol.doseAmount / vial.concentrationValue,
      basis: 'concentration',
      unit: vial.quantityUnit,
    };
  }

  return null;
}

export function getProtocolCadenceDays(
  rule: Pick<ProtocolRule, 'intervalCount' | 'ruleType'> | Pick<ProtocolRevisionRule, 'intervalCount' | 'ruleType'> | null
): number | null {
  if (!rule) {
    return null;
  }

  switch (rule.ruleType) {
    case 'weekly':
      return 7 * Math.max(rule.intervalCount, 1);
    case 'every_n_days':
      return Math.max(rule.intervalCount, 1);
    default:
      return 1;
  }
}

export function getProjectedDepletionDate(params: {
  nextScheduledFor: string | null;
  protocol: Protocol;
  rule: Pick<ProtocolRule, 'intervalCount' | 'ruleType'> | Pick<ProtocolRevisionRule, 'intervalCount' | 'ruleType'> | null;
  vial: Vial;
}): string | null {
  const decrement = getDoseDecrementForVial(params.protocol, params.vial);
  const cadenceDays = getProtocolCadenceDays(params.rule);

  if (!params.nextScheduledFor || !decrement || !cadenceDays || decrement.amount <= 0) {
    return null;
  }

  const remainingEvents = Math.ceil(params.vial.remainingQuantity / decrement.amount);
  if (remainingEvents <= 0) {
    return new Date(params.nextScheduledFor).toISOString();
  }

  const depletionTime =
    new Date(params.nextScheduledFor).getTime() + Math.max(remainingEvents - 1, 0) * cadenceDays * DAY_MS;

  return new Date(depletionTime).toISOString();
}

export function normalizeUnit(value: string | null | undefined): string {
  return (value ?? '').trim().toLowerCase();
}

export function formatQuantity(value: number, unit: string | null | undefined): string {
  const rounded =
    Math.abs(value - Math.round(value)) < 0.0001 ? `${Math.round(value)}` : value.toFixed(2).replace(/\.?0+$/, '');

  return unit ? `${rounded} ${unit}` : rounded;
}

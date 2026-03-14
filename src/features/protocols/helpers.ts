import type { ProtocolKind, ProtocolRule } from '@/src/lib/database/schemas';
import { formatCadenceLabel, formatDoseLabel } from '@/src/lib/schedule/protocol-schedule';

export function formatProtocolKind(kind: ProtocolKind): string {
  switch (kind) {
    case 'glp':
      return 'GLP';
    case 'peptide':
      return 'Peptide';
    default:
      return 'Custom';
  }
}

export function describeProtocolCard(params: {
  defaultTimeOfDay: string | null;
  doseAmount: number | null;
  doseUnit: string | null;
  kind: ProtocolKind;
  rule: ProtocolRule | null;
}) {
  const cadence = params.rule
    ? formatCadenceLabel(params.rule)
    : params.defaultTimeOfDay
      ? `Time set for ${params.defaultTimeOfDay}`
      : 'Schedule not set';

  return {
    cadence,
    dose: formatDoseLabel({
      doseAmount: params.doseAmount,
      doseUnit: params.doseUnit,
    }),
    kindLabel: formatProtocolKind(params.kind),
  };
}

export function slugifyCompoundName(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

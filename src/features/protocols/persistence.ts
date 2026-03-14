import type { AtlasRepositories } from '@/src/lib/database/repositories';

import { protocolWizardValuesSchema, type ProtocolWizardFormValues } from '@/src/features/protocols/schema';
import { slugifyCompoundName } from '@/src/features/protocols/helpers';

type ProtocolPersistenceRepositories = Pick<
  AtlasRepositories,
  'compounds' | 'protocolRevisionRules' | 'protocolRevisions' | 'protocolRules' | 'protocols'
>;

export async function createProtocolInRepositories(
  repositories: ProtocolPersistenceRepositories,
  values: ProtocolWizardFormValues,
  now = new Date()
) {
  const parsed = protocolWizardValuesSchema.parse(values);
  const compound = await resolveCompoundForWizard(repositories, parsed);
  const startDate = getTodayDateString(now);
  const protocol = await repositories.protocols.create({
    compoundId: compound?.id ?? null,
    defaultTimeOfDay: parsed.timeOfDay,
    doseAmount: parsed.doseAmount,
    doseUnit: parsed.doseUnit,
    kind: parsed.kind,
    linkedVialId: null,
    name: compound?.displayName ?? parsed.compoundName,
    notes: parsed.notes,
    siteRotationEnabled: false,
    siteTrackingEnabled: false,
    startDate,
    status: 'active',
    timezone: getLocalTimeZone(),
  });

  const rule = await repositories.protocolRules.create({
    anchorDate: startDate,
    intervalCount: parsed.scheduleType === 'every_n_days' ? parsed.intervalDays : 1,
    isActive: true,
    protocolId: protocol.id,
    ruleType: parsed.scheduleType,
    timeOfDay: parsed.timeOfDay,
    weekday: parsed.scheduleType === 'weekly' ? parsed.weekday : null,
  });

  const initialRevision = await repositories.protocolRevisions.create({
    defaultTimeOfDay: parsed.timeOfDay,
    doseAmount: parsed.doseAmount,
    doseUnit: parsed.doseUnit,
    effectiveFrom: `${startDate}T00:00:00.000Z`,
    effectiveTo: null,
    lifecycleState: 'active',
    linkedVialId: null,
    missedDosePolicy: 'skip_and_continue',
    notes: parsed.notes,
    previousRevisionId: null,
    protocolId: protocol.id,
    revisionNumber: 1,
    timezone: protocol.timezone,
    timezoneStrategy: 'keep_local_clock',
  });

  await repositories.protocolRevisionRules.create({
    anchorDate: startDate,
    doseAmountOverride: null,
    doseUnitOverride: null,
    intervalCount: parsed.scheduleType === 'every_n_days' ? parsed.intervalDays : 1,
    phaseLengthDays: null,
    phaseOrder: 0,
    phaseStartDayOffset: 0,
    phaseType: 'base',
    revisionId: initialRevision.id,
    ruleType: parsed.scheduleType,
    timeOfDay: parsed.timeOfDay,
    weekday: parsed.scheduleType === 'weekly' ? parsed.weekday : null,
  });

  return {
    compound,
    protocol,
    revision: initialRevision,
    rule,
  };
}

async function resolveCompoundForWizard(
  repositories: ProtocolPersistenceRepositories,
  values: ReturnType<typeof protocolWizardValuesSchema.parse>
) {
  if (values.compoundMode === 'saved' && values.existingCompoundId) {
    return repositories.compounds.getById(values.existingCompoundId);
  }

  const displayName = values.compoundName.trim();
  const slug = slugifyCompoundName(displayName);

  if (!slug) {
    return null;
  }

  const existing = await repositories.compounds.getBySlug(slug);
  if (existing) {
    return existing;
  }

  return repositories.compounds.create({
    compoundType: values.kind === 'custom' ? 'other' : values.kind,
    displayName,
    isUserDefined: true,
    notes: null,
    slug,
  });
}

function getTodayDateString(now = new Date()): string {
  const year = now.getFullYear();
  const month = `${now.getMonth() + 1}`.padStart(2, '0');
  const day = `${now.getDate()}`.padStart(2, '0');

  return `${year}-${month}-${day}`;
}

function getLocalTimeZone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
}

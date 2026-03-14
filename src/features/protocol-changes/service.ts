import { getAtlasDatabaseClient, getAtlasRepositories } from '@/src/lib/database';
import {
  createAtlasRepositories,
  type AtlasRepositories,
} from '@/src/lib/database/repositories';
import type {
  ProtocolChangeAuditType,
  ProtocolMissedDosePolicy,
  ProtocolRevision,
  ProtocolRevisionRule,
  ProtocolRevisionTimezoneStrategy,
  ReminderPreference,
  Site,
  Vial,
} from '@/src/lib/database/schemas';
import {
  generateProjectedOccurrences,
  getActiveRevisionSnapshot,
  getEffectiveRevisionAt,
  getNextProjectedOccurrence,
  type ProtocolRevisionSlice,
  type RevisionProjectedOccurrence,
  type ScheduledProtocolRevisionBundle,
} from '@/src/lib/schedule/protocol-revision-schedule';
import { getProjectedDepletionDate } from '@/src/features/inventory/math';
import { getProtocolRevisionBundleById } from '@/src/features/protocols/bundles';
import {
  protocolChangeDraftValuesSchema,
  type ProtocolChangeDraft,
  type ProtocolChangeDraftValues,
  type ProtocolChangeType,
} from '@/src/features/protocol-changes/schema';
import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import {
  formatProtocolDisplayName,
  getEffectiveReminderPrivacyMode,
} from '@/src/features/reminders/privacy';
import { regenerateProtocolReminders } from '@/src/features/reminders/service';

const DAY_MS = 24 * 60 * 60 * 1000;

type ProtocolChangeDependencies = {
  privacy?: PrivacyFlags;
  referenceNow?: Date;
  repositories?: AtlasRepositories;
};

type PrivacyFlags = Pick<
  OnboardingDraft['privacy'],
  'discreetNotifications' | 'hideSensitiveLabels'
>;

type DraftRevisionPlan = {
  adherenceNote: string | null;
  auditChangeType: ProtocolChangeAuditType;
  draftRevisions: DraftRevisionInput[];
  payload: Record<string, unknown>;
  siteWarnings: string[];
  summary: string;
};

type DraftRevisionInput = {
  defaultTimeOfDay: string | null;
  doseAmount: number | null;
  doseUnit: string | null;
  effectiveFrom: string;
  effectiveTo: string | null;
  lifecycleState: ProtocolRevision['lifecycleState'];
  linkedVialId: string | null;
  missedDosePolicy: ProtocolMissedDosePolicy;
  notes: string | null;
  timezone: string;
  timezoneStrategy: ProtocolRevisionTimezoneStrategy;
  rules: DraftRuleInput[];
};

type DraftRuleInput = {
  anchorDate: string | null;
  doseAmountOverride: number | null;
  doseUnitOverride: string | null;
  intervalCount: number;
  phaseLengthDays: number | null;
  phaseOrder: number;
  phaseStartDayOffset: number;
  phaseType: ProtocolRevisionRule['phaseType'];
  ruleType: ProtocolRevisionRule['ruleType'];
  timeOfDay: string | null;
  weekday: number | null;
};

export type ProtocolChangePreviewChange = {
  afterLabel: string | null;
  beforeLabel: string | null;
  kind: 'added' | 'moved' | 'removed' | 'rewired';
};

export type ProtocolChangePreview = {
  adherenceNote: string | null;
  changeType: ProtocolChangeType;
  currentReminderLabel: string | null;
  draftReminderLabel: string | null;
  inventoryForecastAfter: string | null;
  inventoryForecastBefore: string | null;
  nextDueAfter: RevisionProjectedOccurrence | null;
  nextDueBefore: RevisionProjectedOccurrence | null;
  occurrenceChanges: ProtocolChangePreviewChange[];
  previewWindowDays: 7 | 14 | 30;
  siteWarnings: string[];
  summary: string;
};

export type ProtocolChangeDetail = {
  activeSnapshot: ReturnType<typeof getActiveRevisionSnapshot>;
  audits: Awaited<ReturnType<AtlasRepositories['protocolChangeAudits']['listByProtocolId']>>;
  bundle: ScheduledProtocolRevisionBundle;
  nextDue: RevisionProjectedOccurrence | null;
  reminderPreference: ReminderPreference;
  sites: Site[];
  vials: Vial[];
};

export async function getProtocolChangeDetail(
  protocolId: string,
  dependencies: ProtocolChangeDependencies = {}
): Promise<ProtocolChangeDetail | null> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const referenceNow = resolveReferenceNow(dependencies.referenceNow);
  const [audits, bundle, reminderPreference, sites, vials] = await Promise.all([
    repositories.protocolChangeAudits.listByProtocolId(protocolId),
    getProtocolRevisionBundleById(protocolId, {
      includeLogs: true,
      repositories,
    }),
    repositories.reminderPreferences.get(),
    repositories.sites.listAvailable(),
    repositories.vials.listAll(),
  ]);

  if (!bundle) {
    return null;
  }

  return {
    activeSnapshot: getActiveRevisionSnapshot(bundle, referenceNow),
    audits,
    bundle,
    nextDue: getNextProjectedOccurrence(bundle, referenceNow),
    reminderPreference,
    sites,
    vials,
  };
}

export async function buildProtocolChangePreview(
  protocolId: string,
  draft: ProtocolChangeDraft,
  dependencies: ProtocolChangeDependencies = {}
): Promise<ProtocolChangePreview> {
  const repositories = await resolveRepositories(dependencies.repositories);
  const referenceNow = resolveReferenceNow(dependencies.referenceNow);
  const privacy = dependencies.privacy ?? {
    discreetNotifications: false,
    hideSensitiveLabels: false,
  };
  const detail = await getProtocolChangeDetail(protocolId, {
    referenceNow,
    repositories,
  });

  if (!detail) {
    throw new Error('Protocol not found.');
  }

  const parsed = protocolChangeDraftValuesSchema.parse(draft);
  const plan = buildDraftRevisionPlan(detail.bundle, parsed, detail.sites);
  const previewBundle = applyDraftPlan(detail.bundle, plan);
  const previewWindowDays = parsed.previewWindowDays;
  const now = referenceNow;
  const horizonEnd = new Date(now.getTime() + previewWindowDays * DAY_MS);
  const currentOccurrences = generateProjectedOccurrences(detail.bundle, {
    end: horizonEnd,
    now,
    start: now,
  });
  const draftOccurrences = generateProjectedOccurrences(previewBundle, {
    end: horizonEnd,
    now,
    start: now,
  });

  return {
    adherenceNote: plan.adherenceNote,
    changeType: parsed.changeType,
    currentReminderLabel: buildReminderImpactLabel(
      getNextProjectedOccurrence(detail.bundle, now),
      detail.reminderPreference,
      privacy
    ),
    draftReminderLabel: buildReminderImpactLabel(
      getNextProjectedOccurrence(previewBundle, now),
      detail.reminderPreference,
      privacy
    ),
    inventoryForecastAfter: buildInventoryForecastLabel(previewBundle, detail.vials, now, privacy),
    inventoryForecastBefore: buildInventoryForecastLabel(detail.bundle, detail.vials, now, privacy),
    nextDueAfter: getNextProjectedOccurrence(previewBundle, now),
    nextDueBefore: getNextProjectedOccurrence(detail.bundle, now),
    occurrenceChanges: buildOccurrenceDiffs(currentOccurrences, draftOccurrences),
    previewWindowDays,
    siteWarnings: plan.siteWarnings,
    summary: plan.summary,
  };
}

export async function commitProtocolChange(
  protocolId: string,
  draft: ProtocolChangeDraft,
  dependencies: ProtocolChangeDependencies = {}
) {
  const client = await getAtlasDatabaseClient();
  const parsed = protocolChangeDraftValuesSchema.parse(draft);

  const result = await client.withTransaction(async (txn) => {
    const repositories = createAtlasRepositories(txn);
    const detail = await getProtocolChangeDetail(protocolId, {
      referenceNow: dependencies.referenceNow,
      repositories,
    });

    if (!detail) {
      throw new Error('Protocol not found.');
    }

    const plan = buildDraftRevisionPlan(detail.bundle, parsed, detail.sites);
    const existingRevisions = await repositories.protocolRevisions.listByProtocolId(protocolId);
    const nextRevisionBaseNumber =
      existingRevisions.reduce(
        (maxValue, revision) => Math.max(maxValue, revision.revisionNumber),
        0
      ) + 1;

    await repositories.protocolRevisions.closeCurrentAndSupersedeFuture(
      protocolId,
      plan.draftRevisions[0].effectiveFrom
    );

    const previousRevisionId =
      findLatestRevisionBefore(existingRevisions, plan.draftRevisions[0].effectiveFrom)?.id ?? null;
    const createdRevisions = [];
    let nextPreviousRevisionId = previousRevisionId;

    for (const [index, draftRevision] of plan.draftRevisions.entries()) {
      const createdRevision = await repositories.protocolRevisions.create({
        defaultTimeOfDay: draftRevision.defaultTimeOfDay,
        doseAmount: draftRevision.doseAmount,
        doseUnit: draftRevision.doseUnit,
        effectiveFrom: draftRevision.effectiveFrom,
        effectiveTo: draftRevision.effectiveTo,
        lifecycleState: draftRevision.lifecycleState,
        linkedVialId: draftRevision.linkedVialId,
        missedDosePolicy: draftRevision.missedDosePolicy,
        notes: draftRevision.notes,
        previousRevisionId: nextPreviousRevisionId,
        protocolId,
        revisionNumber: nextRevisionBaseNumber + index,
        timezone: draftRevision.timezone,
        timezoneStrategy: draftRevision.timezoneStrategy,
      });

      createdRevisions.push(createdRevision);
      nextPreviousRevisionId = createdRevision.id;

      if (draftRevision.rules.length > 0) {
        for (const rule of draftRevision.rules) {
          await repositories.protocolRevisionRules.create({
            ...rule,
            revisionId: createdRevision.id,
          });
        }
      }
    }

    const auditEvent = await repositories.protocolChangeAudits.create({
      changeType: plan.auditChangeType,
      effectiveFrom: plan.draftRevisions[0].effectiveFrom,
      payloadJson: JSON.stringify(plan.payload),
      previousRevisionId,
      protocolId,
      revisionId: createdRevisions[0].id,
      summary: plan.summary,
    });

    return {
      auditEvent,
      revisions: createdRevisions,
    };
  });

  try {
    await regenerateProtocolReminders(protocolId, {
      repositories: dependencies.repositories,
    });
  } catch (error) {
    console.warn(
      '[Atlas] Reminder regeneration after protocol change failed.',
      error instanceof Error ? error.message : error
    );
  }

  return result;
}

function buildDraftRevisionPlan(
  bundle: ScheduledProtocolRevisionBundle,
  draft: ProtocolChangeDraftValues,
  sites: Site[]
): DraftRevisionPlan {
  const effectiveFrom = `${draft.effectiveDate}T00:00:00.000Z`;
  const referenceSlice =
    getEffectiveRevisionAt(bundle.revisions, new Date(effectiveFrom)) ??
    bundle.revisions[bundle.revisions.length - 1] ??
    null;
  const fallbackActiveSlice =
    findLatestActiveRevision(bundle.revisions, effectiveFrom) ?? referenceSlice;

  if (!referenceSlice || !fallbackActiveSlice) {
    throw new Error('Protocol revision state is unavailable.');
  }

  const baseDraft = cloneRevision(referenceSlice, effectiveFrom);
  const activeRule = getFirstNonRestRule(fallbackActiveSlice.rules);
  const siteWarnings = buildSiteWarnings(bundle.protocol.siteTrackingEnabled, bundle.protocol.siteRotationEnabled, sites);

  switch (draft.changeType) {
    case 'future_dose':
      return {
        adherenceNote: 'Future adherence uses the new saved amount from the effective date forward.',
        auditChangeType: 'future_dose_changed',
        draftRevisions: [
          {
            ...baseDraft,
            doseAmount: draft.doseAmount,
            doseUnit: draft.doseUnit,
          },
        ],
        payload: {
          doseAmount: draft.doseAmount,
          doseUnit: draft.doseUnit,
        },
        siteWarnings,
        summary: `Future saved amount changes to ${draft.doseAmount} ${draft.doseUnit} starting ${draft.effectiveDate}.`,
      };
    case 'future_time':
      return {
        adherenceNote: 'Future adherence uses the updated scheduled time from the effective date forward.',
        auditChangeType: 'time_changed',
        draftRevisions: [
          {
            ...baseDraft,
            defaultTimeOfDay: draft.timeOfDay,
            rules: cloneRules(referenceSlice.rules).map((rule) => ({
              ...rule,
              timeOfDay: draft.timeOfDay,
            })),
          },
        ],
        payload: {
          timeOfDay: draft.timeOfDay,
        },
        siteWarnings,
        summary: `Future scheduled time changes to ${draft.timeOfDay} starting ${draft.effectiveDate}.`,
      };
    case 'day_of_week':
      return {
        adherenceNote: 'Future adherence compares against the updated weekly plan only.',
        auditChangeType: 'cadence_changed',
        draftRevisions: [
          {
            ...baseDraft,
            rules: [
              createBaseRule({
                anchorDate: draft.effectiveDate,
                intervalCount: 1,
                ruleType: 'weekly',
                timeOfDay: draft.timeOfDay,
                weekday: draft.weekday,
              }),
            ],
          },
        ],
        payload: {
          ruleType: 'weekly',
          timeOfDay: draft.timeOfDay,
          weekday: draft.weekday,
        },
        siteWarnings,
        summary: `Future cadence moves to ${weekdayLabel(draft.weekday)} at ${draft.timeOfDay} starting ${draft.effectiveDate}.`,
      };
    case 'every_n_days':
      return {
        adherenceNote: 'Future adherence compares against the updated interval only.',
        auditChangeType: 'cadence_changed',
        draftRevisions: [
          {
            ...baseDraft,
            rules: [
              createBaseRule({
                anchorDate: draft.effectiveDate,
                intervalCount: draft.intervalDays,
                ruleType: 'every_n_days',
                timeOfDay: draft.timeOfDay,
                weekday: null,
              }),
            ],
          },
        ],
        payload: {
          intervalDays: draft.intervalDays,
          ruleType: 'every_n_days',
          timeOfDay: draft.timeOfDay,
        },
        siteWarnings,
        summary: `Future cadence changes to every ${draft.intervalDays} days at ${draft.timeOfDay} starting ${draft.effectiveDate}.`,
      };
    case 'pause':
      return {
        adherenceNote: 'Future adherence pauses until the protocol is resumed with a later future revision.',
        auditChangeType: 'paused',
        draftRevisions: [
          {
            ...baseDraft,
            lifecycleState: 'paused',
            rules: [],
          },
        ],
        payload: {
          lifecycleState: 'paused',
        },
        siteWarnings,
        summary: `Future schedule pauses starting ${draft.effectiveDate}.`,
      };
    case 'resume': {
      const resumeSlice = fallbackActiveSlice;

      return {
        adherenceNote: 'Future adherence resumes against the restored plan from the selected date.',
        auditChangeType: 'resumed',
        draftRevisions: [
          {
            ...cloneRevision(resumeSlice, effectiveFrom),
            lifecycleState: 'active',
            rules: cloneRules(resumeSlice.rules),
          },
        ],
        payload: {
          lifecycleState: 'active',
        },
        siteWarnings,
        summary: `Future schedule resumes starting ${draft.effectiveDate}.`,
      };
    }
    case 'titration': {
      const currentBaseRule = activeRule ?? createBaseRule({
        anchorDate: draft.effectiveDate,
        intervalCount: 7,
        ruleType: 'weekly',
        timeOfDay: draft.timeOfDay,
        weekday: 1,
      });

      return {
        adherenceNote: 'Future adherence compares against the staged titration plan from the effective date forward.',
        auditChangeType: 'titration_changed',
        draftRevisions: [
          {
            ...baseDraft,
            rules: [
              {
                ...createBaseRule({
                  anchorDate: draft.effectiveDate,
                  intervalCount: currentBaseRule.intervalCount,
                  ruleType: currentBaseRule.ruleType,
                  timeOfDay: draft.timeOfDay,
                  weekday: currentBaseRule.weekday,
                }),
                doseAmountOverride: draft.titrationDoseAmount,
                doseUnitOverride: draft.titrationDoseUnit,
                phaseLengthDays: draft.titrationLengthDays,
                phaseOrder: 0,
                phaseType: 'titration',
              },
              {
                ...cloneRule(currentBaseRule),
                doseAmountOverride: null,
                doseUnitOverride: null,
                phaseLengthDays: null,
                phaseOrder: 1,
                phaseStartDayOffset: draft.titrationLengthDays,
                phaseType: 'base',
              },
            ],
          },
        ],
        payload: {
          titrationDoseAmount: draft.titrationDoseAmount,
          titrationDoseUnit: draft.titrationDoseUnit,
          titrationLengthDays: draft.titrationLengthDays,
        },
        siteWarnings,
        summary: `Future titration phase lasts ${draft.titrationLengthDays} days starting ${draft.effectiveDate}.`,
      };
    }
    case 'rest_period': {
      const resumeEffectiveFrom = toIsoDate(addDays(new Date(effectiveFrom), draft.restLengthDays));
      const resumeSlice = fallbackActiveSlice;

      return {
        adherenceNote: 'Future adherence ignores the rest window and resumes against the restored plan afterward.',
        auditChangeType: 'rest_period_changed',
        draftRevisions: [
          {
            ...baseDraft,
            effectiveTo: resumeEffectiveFrom,
            lifecycleState: 'resting',
            rules: [],
          },
          {
            ...cloneRevision(resumeSlice, resumeEffectiveFrom),
            rules: cloneRules(resumeSlice.rules),
          },
        ],
        payload: {
          restLengthDays: draft.restLengthDays,
        },
        siteWarnings,
        summary: `Future rest period lasts ${draft.restLengthDays} days starting ${draft.effectiveDate}.`,
      };
    }
    case 'missed_dose_policy':
      return {
        adherenceNote: `Future missed-dose interpretation uses "${formatMissedDosePolicy(draft.missedDosePolicy)}".`,
        auditChangeType: 'missed_dose_policy_changed',
        draftRevisions: [
          {
            ...baseDraft,
            missedDosePolicy: draft.missedDosePolicy,
          },
        ],
        payload: {
          missedDosePolicy: draft.missedDosePolicy,
        },
        siteWarnings,
        summary: `Future missed-dose recovery changes to ${formatMissedDosePolicy(draft.missedDosePolicy)} starting ${draft.effectiveDate}.`,
      };
    case 'timezone':
      return {
        adherenceNote:
          draft.timezoneStrategy === 'keep_local_clock'
            ? 'Future times keep the local clock after the timezone change.'
            : 'Future times stay anchored to the prior home timezone interpretation.',
        auditChangeType: 'timezone_changed',
        draftRevisions: [
          {
            ...baseDraft,
            timezone: draft.timezone,
            timezoneStrategy: draft.timezoneStrategy,
          },
        ],
        payload: {
          timezone: draft.timezone,
          timezoneStrategy: draft.timezoneStrategy,
        },
        siteWarnings,
        summary: `Future timezone behavior changes to ${draft.timezone} starting ${draft.effectiveDate}.`,
      };
    case 'vial_switch':
      return {
        adherenceNote: 'Future inventory forecast now follows the selected vial after the switch date.',
        auditChangeType: 'vial_handoff_planned',
        draftRevisions: [
          {
            ...baseDraft,
            linkedVialId: draft.linkedVialId,
          },
        ],
        payload: {
          linkedVialId: draft.linkedVialId,
        },
        siteWarnings,
        summary: `Future vial handoff switches inventory tracking starting ${draft.effectiveDate}.`,
      };
    default:
      throw new Error('Unsupported protocol change type.');
  }
}

function applyDraftPlan(
  bundle: ScheduledProtocolRevisionBundle,
  plan: DraftRevisionPlan
): ScheduledProtocolRevisionBundle {
  const boundary = plan.draftRevisions[0].effectiveFrom;
  const nextSlices = bundle.revisions
    .map((slice) => {
      if (slice.revision.effectiveFrom >= boundary) {
        return null;
      }

      if (
        slice.revision.effectiveFrom < boundary &&
        (!slice.revision.effectiveTo || slice.revision.effectiveTo > boundary)
      ) {
        return {
          revision: {
            ...slice.revision,
            effectiveTo: boundary,
          },
          rules: slice.rules,
        };
      }

      return slice;
    })
    .filter((slice): slice is ProtocolRevisionSlice => slice !== null);

  const createdSlices = plan.draftRevisions.map((revision, index) => ({
    revision: {
      id: `draft_revision_${index}`,
      protocolId: bundle.protocol.id,
      revisionNumber: 1000 + index,
      previousRevisionId: null,
      effectiveFrom: revision.effectiveFrom,
      effectiveTo: revision.effectiveTo,
      lifecycleState: revision.lifecycleState,
      timezone: revision.timezone,
      timezoneStrategy: revision.timezoneStrategy,
      defaultTimeOfDay: revision.defaultTimeOfDay,
      doseAmount: revision.doseAmount,
      doseUnit: revision.doseUnit,
      linkedVialId: revision.linkedVialId,
      missedDosePolicy: revision.missedDosePolicy,
      notes: revision.notes,
      createdAt: revision.effectiveFrom,
      updatedAt: revision.effectiveFrom,
    },
    rules: revision.rules.map((rule, ruleIndex) => ({
      id: `draft_rule_${index}_${ruleIndex}`,
      revisionId: `draft_revision_${index}`,
      phaseType: rule.phaseType,
      phaseOrder: rule.phaseOrder,
      ruleType: rule.ruleType,
      intervalCount: rule.intervalCount,
      weekday: rule.weekday,
      timeOfDay: rule.timeOfDay,
      anchorDate: rule.anchorDate,
      phaseStartDayOffset: rule.phaseStartDayOffset,
      phaseLengthDays: rule.phaseLengthDays,
      doseAmountOverride: rule.doseAmountOverride,
      doseUnitOverride: rule.doseUnitOverride,
      createdAt: revision.effectiveFrom,
      updatedAt: revision.effectiveFrom,
    })),
  }));

  return {
    ...bundle,
    revisions: [...nextSlices, ...createdSlices].sort(
      (left, right) =>
        new Date(left.revision.effectiveFrom).getTime() -
          new Date(right.revision.effectiveFrom).getTime() ||
        left.revision.revisionNumber - right.revision.revisionNumber
    ),
  };
}

function buildOccurrenceDiffs(
  currentOccurrences: RevisionProjectedOccurrence[],
  draftOccurrences: RevisionProjectedOccurrence[]
): ProtocolChangePreviewChange[] {
  const maxLength = Math.max(currentOccurrences.length, draftOccurrences.length);
  const changes: ProtocolChangePreviewChange[] = [];

  for (let index = 0; index < maxLength; index += 1) {
    const before = currentOccurrences[index] ?? null;
    const after = draftOccurrences[index] ?? null;

    if (before && after) {
      if (
        before.scheduledFor === after.scheduledFor &&
        before.doseLabel === after.doseLabel &&
        before.linkedVialId === after.linkedVialId
      ) {
        continue;
      }

      changes.push({
        afterLabel: describeOccurrence(after),
        beforeLabel: describeOccurrence(before),
        kind:
          before.scheduledFor !== after.scheduledFor
            ? 'moved'
            : before.linkedVialId !== after.linkedVialId || before.doseLabel !== after.doseLabel
              ? 'rewired'
              : 'moved',
      });
      continue;
    }

    if (before && !after) {
      changes.push({
        afterLabel: null,
        beforeLabel: describeOccurrence(before),
        kind: 'removed',
      });
    }

    if (!before && after) {
      changes.push({
        afterLabel: describeOccurrence(after),
        beforeLabel: null,
        kind: 'added',
      });
    }
  }

  return changes.slice(0, 8);
}

function buildReminderImpactLabel(
  occurrence: RevisionProjectedOccurrence | null,
  preference: ReminderPreference,
  privacy: PrivacyFlags
) {
  if (!occurrence) {
    return null;
  }

  const scheduledAt = new Date(new Date(occurrence.scheduledFor).getTime() - preference.leadTimeMinutes * 60_000);
  const effectiveMode = getEffectiveReminderPrivacyMode(preference.privacyMode, privacy);
  const protocolLabel =
    effectiveMode === 'silent'
      ? 'Silent reminder'
      : effectiveMode === 'generic'
        ? 'Private routine'
        : formatProtocolDisplayName(occurrence.protocolName, occurrence.kind, privacy);

  return `${new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    month: 'short',
  }).format(scheduledAt)} · ${protocolLabel}`;
}

function buildInventoryForecastLabel(
  bundle: ScheduledProtocolRevisionBundle,
  vials: Vial[],
  now: Date,
  privacy: PrivacyFlags
) {
  const nextDue = getNextProjectedOccurrence(bundle, now);
  const snapshot = getActiveRevisionSnapshot(bundle, now);

  if (!nextDue || !snapshot.linkedVialId || !snapshot.activeRule) {
    return null;
  }

  const vial = vials.find((item) => item.id === snapshot.linkedVialId) ?? null;
  if (!vial) {
    return null;
  }

  const depletion = getProjectedDepletionDate({
    nextScheduledFor: nextDue.scheduledFor,
    protocol: {
      ...bundle.protocol,
      doseAmount: snapshot.doseAmount ?? bundle.protocol.doseAmount,
      doseUnit: snapshot.doseUnit ?? bundle.protocol.doseUnit,
    },
    rule: snapshot.activeRule,
    vial,
  });

  if (!depletion) {
    return null;
  }

  const vialLabel =
    privacy.discreetNotifications || privacy.hideSensitiveLabels
      ? 'Linked vial'
      : vial.label;

  return `${vialLabel} until ${new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    month: 'short',
  }).format(new Date(depletion))}`;
}

function cloneRevision(slice: ProtocolRevisionSlice, effectiveFrom: string): DraftRevisionInput {
  return {
    defaultTimeOfDay: slice.revision.defaultTimeOfDay,
    doseAmount: slice.revision.doseAmount,
    doseUnit: slice.revision.doseUnit,
    effectiveFrom,
    effectiveTo: null,
    lifecycleState: slice.revision.lifecycleState,
    linkedVialId: slice.revision.linkedVialId,
    missedDosePolicy: slice.revision.missedDosePolicy,
    notes: slice.revision.notes,
    timezone: slice.revision.timezone,
    timezoneStrategy: slice.revision.timezoneStrategy,
    rules: cloneRules(slice.rules),
  };
}

function cloneRules(rules: ProtocolRevisionRule[]): DraftRuleInput[] {
  return rules.map((rule) => cloneRule(rule));
}

function cloneRule(rule: DraftRuleInput | ProtocolRevisionRule): DraftRuleInput {
  return {
    anchorDate: rule.anchorDate,
    doseAmountOverride: rule.doseAmountOverride,
    doseUnitOverride: rule.doseUnitOverride,
    intervalCount: rule.intervalCount,
    phaseLengthDays: rule.phaseLengthDays,
    phaseOrder: rule.phaseOrder,
    phaseStartDayOffset: rule.phaseStartDayOffset,
    phaseType: rule.phaseType,
    ruleType: rule.ruleType,
    timeOfDay: rule.timeOfDay,
    weekday: rule.weekday,
  };
}

function createBaseRule(input: {
  anchorDate: string;
  intervalCount: number;
  ruleType: ProtocolRevisionRule['ruleType'];
  timeOfDay: string;
  weekday: number | null;
}): DraftRuleInput {
  return {
    anchorDate: input.anchorDate,
    doseAmountOverride: null,
    doseUnitOverride: null,
    intervalCount: input.intervalCount,
    phaseLengthDays: null,
    phaseOrder: 0,
    phaseStartDayOffset: 0,
    phaseType: 'base',
    ruleType: input.ruleType,
    timeOfDay: input.timeOfDay,
    weekday: input.weekday,
  };
}

function findLatestActiveRevision(
  slices: ProtocolRevisionSlice[],
  effectiveFrom: string
) {
  return [...slices]
    .filter((slice) => slice.revision.lifecycleState === 'active')
    .sort(
      (left, right) =>
        new Date(right.revision.effectiveFrom).getTime() -
          new Date(left.revision.effectiveFrom).getTime() ||
        right.revision.revisionNumber - left.revision.revisionNumber
    )
    .find((slice) => slice.revision.effectiveFrom <= effectiveFrom) ?? null;
}

function findLatestRevisionBefore(revisions: ProtocolRevision[], effectiveFrom: string) {
  return [...revisions]
    .filter((revision) => revision.effectiveFrom <= effectiveFrom)
    .sort(
      (left, right) =>
        new Date(right.effectiveFrom).getTime() - new Date(left.effectiveFrom).getTime() ||
        right.revisionNumber - left.revisionNumber
    )[0] ?? null;
}

function getFirstNonRestRule(rules: ProtocolRevisionRule[]) {
  return [...rules].sort((left, right) => left.phaseOrder - right.phaseOrder).find((rule) => rule.phaseType !== 'rest') ?? null;
}

function buildSiteWarnings(siteTrackingEnabled: boolean, siteRotationEnabled: boolean, sites: Site[]) {
  if (!siteTrackingEnabled) {
    return [];
  }

  if (sites.length === 0) {
    return ['Site tracking is enabled, but no saved sites exist yet.'];
  }

  if (siteRotationEnabled && sites.length < 2) {
    return ['Site rotation is enabled, but only one saved site is available.'];
  }

  return [];
}

function describeOccurrence(occurrence: RevisionProjectedOccurrence) {
  return `${occurrence.whenLabel}${occurrence.doseLabel ? ` · ${occurrence.doseLabel}` : ''}`;
}

function resolveRepositories(repositories?: AtlasRepositories) {
  if (repositories) {
    return Promise.resolve(repositories);
  }

  return getAtlasRepositories();
}

function resolveReferenceNow(referenceNow?: Date) {
  return referenceNow ? new Date(referenceNow) : new Date();
}

function weekdayLabel(weekday: number | null) {
  const labels = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return weekday === null ? 'day' : labels[weekday] ?? 'day';
}

function addDays(value: Date, days: number) {
  return new Date(value.getTime() + days * DAY_MS);
}

function toIsoDate(value: Date) {
  const year = value.getUTCFullYear();
  const month = `${value.getUTCMonth() + 1}`.padStart(2, '0');
  const day = `${value.getUTCDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}T00:00:00.000Z`;
}

function formatMissedDosePolicy(value: ProtocolMissedDosePolicy) {
  switch (value) {
    case 'take_now_keep_cadence':
      return 'take now, keep cadence';
    case 'take_now_shift_future':
      return 'take now, shift future';
    default:
      return 'skip and continue';
  }
}

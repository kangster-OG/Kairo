import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import type { GeneratedOccurrence, TimelineFeedItem } from '@/src/features/day-loop/service';
import type {
  PrivacyProfile,
  PrivacyRenderMode,
  ProtocolAlias,
  ReminderPreference,
} from '@/src/lib/database/schemas';

type PrivacyFlags = Pick<OnboardingDraft['privacy'], 'discreetNotifications' | 'hideSensitiveLabels'>;

export type ReminderPreview = {
  body: string;
  isSilent: boolean;
  title: string;
};

export type AliasLookup = Record<string, ProtocolAlias>;

export function indexProtocolAliases(aliases: ProtocolAlias[]): AliasLookup {
  return aliases.reduce<AliasLookup>((result, alias) => {
    result[alias.protocolId] = alias;
    return result;
  }, {});
}

export function getIsDiscreetModeEnabled(privacy: PrivacyFlags): boolean {
  return privacy.discreetNotifications || privacy.hideSensitiveLabels;
}

export function resolvePrivacyRenderMode(
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  override?: PrivacyRenderMode
): PrivacyRenderMode {
  if (override) {
    return override;
  }

  if (profile?.aliasModeEnabled) {
    return 'alias';
  }

  return getIsDiscreetModeEnabled(privacy) ? 'discreet' : 'full';
}

export function formatProtocolDisplayName(
  protocolName: string,
  kind: string,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  alias?: Pick<ProtocolAlias, 'aliasLabel'> | null,
  override?: PrivacyRenderMode
): string {
  const mode = resolvePrivacyRenderMode(privacy, profile, override);

  if (mode === 'full') {
    return protocolName;
  }

  if (mode === 'alias') {
    return alias?.aliasLabel?.trim() || aliasFallback(kind);
  }

  switch (kind) {
    case 'glp':
      return 'Private GLP protocol';
    case 'peptide':
      return 'Private peptide protocol';
    default:
      return 'Private protocol';
  }
}

export function formatCompoundDisplayName(
  compoundName: string | null | undefined,
  kind: string,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  alias?: Pick<ProtocolAlias, 'aliasCompoundLabel'> | null,
  override?: PrivacyRenderMode
): string | null {
  if (!compoundName) {
    return null;
  }

  const mode = resolvePrivacyRenderMode(privacy, profile, override);

  if (mode === 'full') {
    return compoundName;
  }

  if (mode === 'alias') {
    return alias?.aliasCompoundLabel?.trim() || 'Alias compound';
  }

  return 'Private compound';
}

export function formatVialDisplayName(
  label: string,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  override?: PrivacyRenderMode
) {
  const mode = resolvePrivacyRenderMode(privacy, profile, override);
  return mode === 'full' ? label : 'Private vial';
}

export function formatTodayOccurrenceLabel(
  occurrence: Pick<GeneratedOccurrence, 'kind' | 'protocolId' | 'protocolName'>,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  aliases?: AliasLookup,
  override?: PrivacyRenderMode
): string {
  return formatProtocolDisplayName(
    occurrence.protocolName,
    occurrence.kind,
    privacy,
    profile,
    aliases?.[occurrence.protocolId] ?? null,
    override
  );
}

export function formatTimelineItemSummary(
  item: Pick<TimelineFeedItem, 'eventType' | 'protocolId' | 'protocolName' | 'summary'>,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  aliases?: AliasLookup,
  override?: PrivacyRenderMode
): string {
  const mode = resolvePrivacyRenderMode(privacy, profile, override);

  if (mode === 'full') {
    return item.summary;
  }

  if (mode === 'alias') {
    const aliasLabel =
      aliases?.[item.protocolId]?.aliasLabel?.trim() || 'Alias protocol';

    switch (item.eventType) {
      case 'logged_dose':
        return `Logged ${aliasLabel} as taken`;
      case 'skipped_dose':
        return `Skipped ${aliasLabel}`;
      case 'rescheduled_dose':
        return `Rescheduled ${aliasLabel}`;
      case 'protocol_changed':
        return `Changed future plan for ${aliasLabel}`;
      default:
        return `Created ${aliasLabel}`;
    }
  }

  switch (item.eventType) {
    case 'logged_dose':
      return 'Logged a private dose as taken';
    case 'skipped_dose':
      return 'Skipped a private dose';
    case 'rescheduled_dose':
      return 'Rescheduled a private dose';
    case 'protocol_changed':
      return 'Changed a private future plan';
    default:
      return 'Created a private protocol';
  }
}

export function buildReminderPreview(
  occurrence: Pick<GeneratedOccurrence, 'kind' | 'protocolId' | 'protocolName' | 'whenLabel'>,
  preferences: Pick<ReminderPreference, 'privacyMode'>,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  aliases?: AliasLookup,
  override?: PrivacyRenderMode
): ReminderPreview {
  const mode = getEffectiveReminderPrivacyMode(
    preferences.privacyMode,
    privacy,
    profile,
    override
  );

  if (mode === 'silent') {
    return {
      body: 'Open Atlas when you are ready.',
      isSilent: true,
      title: 'Atlas',
    };
  }

  if (mode === 'generic') {
    return {
      body: `A private routine is due ${normalizeWhenLabel(occurrence.whenLabel)}.`,
      isSilent: false,
      title: 'Atlas reminder',
    };
  }

  const protocolLabel = formatTodayOccurrenceLabel(
    occurrence,
    privacy,
    profile,
    aliases,
    override
  );

  return {
    body: `${protocolLabel} is due ${normalizeWhenLabel(occurrence.whenLabel)}.`,
    isSilent: false,
    title: protocolLabel,
  };
}

export function getEffectiveReminderPrivacyMode(
  selectedMode: ReminderPreference['privacyMode'],
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  override?: PrivacyRenderMode
): ReminderPreference['privacyMode'] {
  const mode = resolvePrivacyRenderMode(privacy, profile, override);

  if (mode === 'discreet') {
    return selectedMode === 'silent' ? 'silent' : 'generic';
  }

  if (mode === 'alias') {
    return selectedMode === 'silent' ? 'silent' : 'full_detail';
  }

  return selectedMode;
}

export function formatSensitiveAuditSummary(
  eventType: string,
  privacy: PrivacyFlags,
  profile?: Pick<PrivacyProfile, 'aliasModeEnabled'> | null,
  aliasLabel?: string | null,
  override?: PrivacyRenderMode
) {
  const mode = resolvePrivacyRenderMode(privacy, profile, override);

  if (mode === 'full') {
    return formatFullAuditSummary(eventType, aliasLabel);
  }

  if (mode === 'alias') {
    return formatAliasAuditSummary(eventType, aliasLabel);
  }

  return formatDiscreetAuditSummary(eventType);
}

function formatFullAuditSummary(eventType: string, aliasLabel?: string | null) {
  switch (eventType) {
    case 'alias_changed':
      return aliasLabel ? `Updated alias to ${aliasLabel}` : 'Updated protocol alias';
    case 'privacy_mode_changed':
      return 'Changed privacy mode';
    case 'biometric_lock_changed':
      return 'Changed biometric lock settings';
    case 'vault_unlocked':
      return 'Unlocked Trust Vault';
    case 'selective_share_created':
      return 'Created selective share bundle';
    default:
      return 'Created export bundle';
  }
}

function formatAliasAuditSummary(eventType: string, aliasLabel?: string | null) {
  switch (eventType) {
    case 'alias_changed':
      return aliasLabel ? `Updated alias ${aliasLabel}` : 'Updated alias';
    case 'selective_share_created':
      return 'Created alias-safe share bundle';
    default:
      return formatFullAuditSummary(eventType, aliasLabel);
  }
}

function formatDiscreetAuditSummary(eventType: string) {
  switch (eventType) {
    case 'vault_unlocked':
      return 'Unlocked private controls';
    case 'selective_share_created':
      return 'Created private share bundle';
    case 'export_created':
      return 'Created private export';
    default:
      return 'Updated private controls';
  }
}

function aliasFallback(kind: string) {
  switch (kind) {
    case 'glp':
      return 'Alias GLP protocol';
    case 'peptide':
      return 'Alias peptide protocol';
    default:
      return 'Alias protocol';
  }
}

function normalizeWhenLabel(whenLabel: string) {
  const lowered = whenLabel.charAt(0).toLowerCase() + whenLabel.slice(1);
  return lowered.endsWith('.') ? lowered.slice(0, -1) : lowered;
}

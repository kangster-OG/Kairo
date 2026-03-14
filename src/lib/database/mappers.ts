import { createIsoTimestamp, createLocalId } from '@/src/lib/database/id';
import {
  compoundRowSchema,
  compoundSchema,
  createCompoundInputSchema,
  createCustomMetricInputSchema,
  createCalculatorProfileInputSchema,
  createHealthConnectionInputSchema,
  createLogEventInputSchema,
  createMetricValueLogInputSchema,
  createPrivacyProfileInputSchema,
  createReminderPreferenceInputSchema,
  createProtocolAliasInputSchema,
  createProtocolInputSchema,
  createProtocolChangeAuditEventInputSchema,
  createProtocolRevisionInputSchema,
  createProtocolRevisionRuleInputSchema,
  createProtocolRuleInputSchema,
  createReminderInputSchema,
  createSensitiveActionAuditEventInputSchema,
  createSiteInputSchema,
  createVialInputSchema,
  createSymptomLogInputSchema,
  createWeightLogInputSchema,
  customMetricRowSchema,
  customMetricSchema,
  calculatorProfileRowSchema,
  calculatorProfileSchema,
  healthConnectionRowSchema,
  healthConnectionSchema,
  logEventRowSchema,
  logEventSchema,
  metricValueLogRowSchema,
  metricValueLogSchema,
  privacyProfileRowSchema,
  privacyProfileSchema,
  reminderPreferenceRowSchema,
  reminderPreferenceSchema,
  protocolAliasRowSchema,
  protocolAliasSchema,
  protocolRowSchema,
  protocolRevisionRowSchema,
  protocolRevisionRuleRowSchema,
  protocolRevisionSchema,
  protocolRevisionRuleSchema,
  protocolRuleRowSchema,
  protocolRuleSchema,
  protocolSchema,
  protocolChangeAuditEventRowSchema,
  protocolChangeAuditEventSchema,
  reminderRowSchema,
  reminderSchema,
  sensitiveActionAuditEventRowSchema,
  sensitiveActionAuditEventSchema,
  siteRowSchema,
  siteSchema,
  symptomLogRowSchema,
  symptomLogSchema,
  vialRowSchema,
  vialSchema,
  weightLogRowSchema,
  weightLogSchema,
  type Compound,
  type CompoundRow,
  type CreateCompoundInput,
  type CreateCustomMetricInput,
  type CreateCalculatorProfileInput,
  type CreateHealthConnectionInput,
  type CreateLogEventInput,
  type CreateMetricValueLogInput,
  type CreatePrivacyProfileInput,
  type CreateReminderPreferenceInput,
  type CreateProtocolAliasInput,
  type CreateProtocolInput,
  type CreateProtocolChangeAuditEventInput,
  type CreateProtocolRevisionInput,
  type CreateProtocolRevisionRuleInput,
  type CreateProtocolRuleInput,
  type CreateReminderInput,
  type CreateSensitiveActionAuditEventInput,
  type CreateSiteInput,
  type CreateSymptomLogInput,
  type CreateVialInput,
  type CreateWeightLogInput,
  type CustomMetric,
  type CustomMetricRow,
  type CalculatorProfile,
  type CalculatorProfileRow,
  type HealthConnection,
  type HealthConnectionRow,
  type LogEvent,
  type LogEventRow,
  type MetricValueLog,
  type MetricValueLogRow,
  type PrivacyProfile,
  type PrivacyProfileRow,
  type ReminderPreference,
  type ReminderPreferenceRow,
  type ProtocolAlias,
  type ProtocolAliasRow,
  type Protocol,
  type ProtocolRow,
  type ProtocolRevision,
  type ProtocolRevisionRow,
  type ProtocolRevisionRule,
  type ProtocolRevisionRuleRow,
  type ProtocolRule,
  type ProtocolRuleRow,
  type ProtocolChangeAuditEvent,
  type ProtocolChangeAuditEventRow,
  type Reminder,
  type ReminderRow,
  type SensitiveActionAuditEvent,
  type SensitiveActionAuditEventRow,
  type Site,
  type SiteRow,
  type SymptomLog,
  type SymptomLogRow,
  type Vial,
  type VialRow,
  type WeightLog,
  type WeightLogRow,
} from '@/src/lib/database/schemas';

function toSqliteBoolean(value: boolean): number {
  return value ? 1 : 0;
}

function fromSqliteBoolean(value: number): boolean {
  return value === 1;
}

export function mapCompoundRow(row: unknown): Compound {
  const parsed = compoundRowSchema.parse(row);

  return compoundSchema.parse({
    id: parsed.id,
    slug: parsed.slug,
    displayName: parsed.display_name,
    compoundType: parsed.compound_type,
    isUserDefined: fromSqliteBoolean(parsed.is_user_defined),
    notes: parsed.notes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolRow(row: unknown): Protocol {
  const parsed = protocolRowSchema.parse(row);

  return protocolSchema.parse({
    id: parsed.id,
    compoundId: parsed.compound_id,
    linkedVialId: parsed.linked_vial_id,
    name: parsed.name,
    kind: parsed.kind,
    status: parsed.status,
    timezone: parsed.timezone,
    startDate: parsed.start_date,
    defaultTimeOfDay: parsed.default_time_of_day,
    doseAmount: parsed.dose_amount,
    doseUnit: parsed.dose_unit,
    siteTrackingEnabled: fromSqliteBoolean(parsed.site_tracking_enabled),
    siteRotationEnabled: fromSqliteBoolean(parsed.site_rotation_enabled),
    notes: parsed.notes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolRuleRow(row: unknown): ProtocolRule {
  const parsed = protocolRuleRowSchema.parse(row);

  return protocolRuleSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    ruleType: parsed.rule_type,
    intervalCount: parsed.interval_count,
    weekday: parsed.weekday,
    timeOfDay: parsed.time_of_day,
    anchorDate: parsed.anchor_date,
    isActive: fromSqliteBoolean(parsed.is_active),
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolRevisionRow(row: unknown): ProtocolRevision {
  const parsed = protocolRevisionRowSchema.parse(row);

  return protocolRevisionSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    revisionNumber: parsed.revision_number,
    previousRevisionId: parsed.previous_revision_id,
    effectiveFrom: parsed.effective_from,
    effectiveTo: parsed.effective_to,
    lifecycleState: parsed.lifecycle_state,
    timezone: parsed.timezone,
    timezoneStrategy: parsed.timezone_strategy,
    defaultTimeOfDay: parsed.default_time_of_day,
    doseAmount: parsed.dose_amount,
    doseUnit: parsed.dose_unit,
    linkedVialId: parsed.linked_vial_id,
    missedDosePolicy: parsed.missed_dose_policy,
    notes: parsed.notes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolRevisionRuleRow(row: unknown): ProtocolRevisionRule {
  const parsed = protocolRevisionRuleRowSchema.parse(row);

  return protocolRevisionRuleSchema.parse({
    id: parsed.id,
    revisionId: parsed.revision_id,
    phaseType: parsed.phase_type,
    phaseOrder: parsed.phase_order,
    ruleType: parsed.rule_type,
    intervalCount: parsed.interval_count,
    weekday: parsed.weekday,
    timeOfDay: parsed.time_of_day,
    anchorDate: parsed.anchor_date,
    phaseStartDayOffset: parsed.phase_start_day_offset,
    phaseLengthDays: parsed.phase_length_days,
    doseAmountOverride: parsed.dose_amount_override,
    doseUnitOverride: parsed.dose_unit_override,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolChangeAuditEventRow(row: unknown): ProtocolChangeAuditEvent {
  const parsed = protocolChangeAuditEventRowSchema.parse(row);

  return protocolChangeAuditEventSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    revisionId: parsed.revision_id,
    previousRevisionId: parsed.previous_revision_id,
    changeType: parsed.change_type,
    effectiveFrom: parsed.effective_from,
    summary: parsed.summary,
    payloadJson: parsed.payload_json,
    createdAt: parsed.created_at,
  });
}

export function mapVialRow(row: unknown): Vial {
  const parsed = vialRowSchema.parse(row);

  return vialSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    compoundId: parsed.compound_id,
    label: parsed.label,
    startingQuantity: parsed.starting_quantity,
    concentrationValue: parsed.concentration_value,
    concentrationUnit: parsed.concentration_unit,
    volumeMl: parsed.volume_ml,
    remainingQuantity: parsed.remaining_quantity,
    lowStockThreshold: parsed.low_stock_threshold,
    quantityUnit: parsed.quantity_unit,
    openedAt: parsed.opened_at,
    expiresAt: parsed.expires_at,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapLogEventRow(row: unknown): LogEvent {
  const parsed = logEventRowSchema.parse(row);

  return logEventSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    vialId: parsed.vial_id,
    siteId: parsed.site_id,
    occurrenceId: parsed.occurrence_id,
    eventType: parsed.event_type,
    effectiveAt: parsed.effective_at,
    loggedAt: parsed.logged_at,
    quantity: parsed.quantity,
    quantityUnit: parsed.quantity_unit,
    notes: parsed.notes,
    source: parsed.source,
  });
}

export function mapReminderRow(row: unknown): Reminder {
  const parsed = reminderRowSchema.parse(row);

  return reminderSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    occurrenceId: parsed.occurrence_id,
    offsetMinutes: parsed.offset_minutes,
    channel: parsed.channel,
    isEnabled: fromSqliteBoolean(parsed.is_enabled),
    discreetCopyEnabled: fromSqliteBoolean(parsed.discreet_copy_enabled),
    privacyMode: parsed.privacy_mode,
    scheduledFor: parsed.scheduled_for,
    notificationId: parsed.notification_id,
    title: parsed.title,
    body: parsed.body,
    status: parsed.status,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapReminderPreferenceRow(row: unknown): ReminderPreference {
  const parsed = reminderPreferenceRowSchema.parse(row);

  return reminderPreferenceSchema.parse({
    id: parsed.id,
    remindersEnabled: fromSqliteBoolean(parsed.reminders_enabled),
    privacyMode: parsed.privacy_mode,
    leadTimeMinutes: parsed.lead_time_minutes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapPrivacyProfileRow(row: unknown): PrivacyProfile {
  const parsed = privacyProfileRowSchema.parse(row);

  return privacyProfileSchema.parse({
    id: parsed.id,
    aliasModeEnabled: fromSqliteBoolean(parsed.alias_mode_enabled),
    biometricLockEnabled: fromSqliteBoolean(parsed.biometric_lock_enabled),
    biometricGateMode: parsed.biometric_gate_mode,
    shareAliasByDefault: fromSqliteBoolean(parsed.share_alias_by_default),
    exportAliasByDefault: fromSqliteBoolean(parsed.export_alias_by_default),
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapProtocolAliasRow(row: unknown): ProtocolAlias {
  const parsed = protocolAliasRowSchema.parse(row);

  return protocolAliasSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    aliasLabel: parsed.alias_label,
    aliasCompoundLabel: parsed.alias_compound_label,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
    archivedAt: parsed.archived_at,
  });
}

export function mapSensitiveActionAuditEventRow(row: unknown): SensitiveActionAuditEvent {
  const parsed = sensitiveActionAuditEventRowSchema.parse(row);

  return sensitiveActionAuditEventSchema.parse({
    id: parsed.id,
    eventType: parsed.event_type,
    surface: parsed.surface,
    protocolId: parsed.protocol_id,
    scopeKind: parsed.scope_kind,
    renderMode: parsed.render_mode,
    manifestVersion: parsed.manifest_version,
    payloadJson: parsed.payload_json,
    createdAt: parsed.created_at,
  });
}

export function mapCustomMetricRow(row: unknown): CustomMetric {
  const parsed = customMetricRowSchema.parse(row);

  return customMetricSchema.parse({
    id: parsed.id,
    protocolId: parsed.protocol_id,
    metricKey: parsed.metric_key,
    label: parsed.label,
    valueType: parsed.value_type,
    unit: parsed.unit,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapCalculatorProfileRow(row: unknown): CalculatorProfile {
  const parsed = calculatorProfileRowSchema.parse(row);

  return calculatorProfileSchema.parse({
    id: parsed.id,
    label: parsed.label,
    powderAmount: parsed.powder_amount,
    powderUnit: parsed.powder_unit,
    diluentVolume: parsed.diluent_volume,
    diluentUnit: parsed.diluent_unit,
    drawVolume: parsed.draw_volume,
    drawUnit: parsed.draw_unit,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapWeightLogRow(row: unknown): WeightLog {
  const parsed = weightLogRowSchema.parse(row);

  return weightLogSchema.parse({
    id: parsed.id,
    loggedAt: parsed.logged_at,
    value: parsed.value,
    unit: parsed.unit,
    source: parsed.source,
    notes: parsed.notes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapSymptomLogRow(row: unknown): SymptomLog {
  const parsed = symptomLogRowSchema.parse(row);

  return symptomLogSchema.parse({
    id: parsed.id,
    loggedAt: parsed.logged_at,
    symptomKey: parsed.symptom_key,
    severity: parsed.severity,
    notes: parsed.notes,
    source: parsed.source,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapMetricValueLogRow(row: unknown): MetricValueLog {
  const parsed = metricValueLogRowSchema.parse(row);

  return metricValueLogSchema.parse({
    id: parsed.id,
    metricId: parsed.metric_id,
    protocolId: parsed.protocol_id,
    loggedAt: parsed.logged_at,
    numberValue: parsed.number_value,
    textValue: parsed.text_value,
    booleanValue:
      parsed.boolean_value === null ? null : fromSqliteBoolean(parsed.boolean_value),
    source: parsed.source,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapHealthConnectionRow(row: unknown): HealthConnection {
  const parsed = healthConnectionRowSchema.parse(row);

  return healthConnectionSchema.parse({
    providerKey: parsed.provider_key,
    enabled: fromSqliteBoolean(parsed.enabled),
    connected: fromSqliteBoolean(parsed.connected),
    lastSyncAt: parsed.last_sync_at,
    lastError: parsed.last_error,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
  });
}

export function mapSiteRow(row: unknown): Site {
  const parsed = siteRowSchema.parse(row);

  return siteSchema.parse({
    id: parsed.id,
    name: parsed.name,
    bodyArea: parsed.body_area,
    notes: parsed.notes,
    createdAt: parsed.created_at,
    updatedAt: parsed.updated_at,
    archivedAt: parsed.archived_at,
  });
}

export function toCompoundRow(
  input: CreateCompoundInput,
  now = createIsoTimestamp()
): CompoundRow {
  const parsed = createCompoundInputSchema.parse(input);

  return compoundRowSchema.parse({
    id: parsed.id ?? createLocalId('cmp'),
    slug: parsed.slug,
    display_name: parsed.displayName,
    compound_type: parsed.compoundType,
    is_user_defined: toSqliteBoolean(parsed.isUserDefined),
    notes: parsed.notes ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolRow(
  input: CreateProtocolInput,
  now = createIsoTimestamp()
): ProtocolRow {
  const parsed = createProtocolInputSchema.parse(input);

  return protocolRowSchema.parse({
    id: parsed.id ?? createLocalId('pro'),
    compound_id: parsed.compoundId ?? null,
    linked_vial_id: parsed.linkedVialId ?? null,
    name: parsed.name,
    kind: parsed.kind,
    status: parsed.status,
    timezone: parsed.timezone,
    start_date: parsed.startDate,
    default_time_of_day: parsed.defaultTimeOfDay ?? null,
    dose_amount: parsed.doseAmount ?? null,
    dose_unit: parsed.doseUnit ?? null,
    site_tracking_enabled: toSqliteBoolean(parsed.siteTrackingEnabled),
    site_rotation_enabled: toSqliteBoolean(parsed.siteRotationEnabled),
    notes: parsed.notes ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolRuleRow(
  input: CreateProtocolRuleInput,
  now = createIsoTimestamp()
): ProtocolRuleRow {
  const parsed = createProtocolRuleInputSchema.parse(input);

  return protocolRuleRowSchema.parse({
    id: parsed.id ?? createLocalId('prl'),
    protocol_id: parsed.protocolId,
    rule_type: parsed.ruleType,
    interval_count: parsed.intervalCount,
    weekday: parsed.weekday ?? null,
    time_of_day: parsed.timeOfDay ?? null,
    anchor_date: parsed.anchorDate ?? null,
    is_active: toSqliteBoolean(parsed.isActive),
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolRevisionRow(
  input: CreateProtocolRevisionInput,
  now = createIsoTimestamp()
): ProtocolRevisionRow {
  const parsed = createProtocolRevisionInputSchema.parse(input);

  return protocolRevisionRowSchema.parse({
    id: parsed.id ?? createLocalId('prv'),
    protocol_id: parsed.protocolId,
    revision_number: parsed.revisionNumber,
    previous_revision_id: parsed.previousRevisionId ?? null,
    effective_from: parsed.effectiveFrom,
    effective_to: parsed.effectiveTo ?? null,
    lifecycle_state: parsed.lifecycleState,
    timezone: parsed.timezone,
    timezone_strategy: parsed.timezoneStrategy,
    default_time_of_day: parsed.defaultTimeOfDay ?? null,
    dose_amount: parsed.doseAmount ?? null,
    dose_unit: parsed.doseUnit ?? null,
    linked_vial_id: parsed.linkedVialId ?? null,
    missed_dose_policy: parsed.missedDosePolicy,
    notes: parsed.notes ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolRevisionRuleRow(
  input: CreateProtocolRevisionRuleInput,
  now = createIsoTimestamp()
): ProtocolRevisionRuleRow {
  const parsed = createProtocolRevisionRuleInputSchema.parse(input);

  return protocolRevisionRuleRowSchema.parse({
    id: parsed.id ?? createLocalId('prr'),
    revision_id: parsed.revisionId,
    phase_type: parsed.phaseType,
    phase_order: parsed.phaseOrder,
    rule_type: parsed.ruleType,
    interval_count: parsed.intervalCount,
    weekday: parsed.weekday ?? null,
    time_of_day: parsed.timeOfDay ?? null,
    anchor_date: parsed.anchorDate ?? null,
    phase_start_day_offset: parsed.phaseStartDayOffset,
    phase_length_days: parsed.phaseLengthDays ?? null,
    dose_amount_override: parsed.doseAmountOverride ?? null,
    dose_unit_override: parsed.doseUnitOverride ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolChangeAuditEventRow(
  input: CreateProtocolChangeAuditEventInput,
  now = createIsoTimestamp()
): ProtocolChangeAuditEventRow {
  const parsed = createProtocolChangeAuditEventInputSchema.parse(input);

  return protocolChangeAuditEventRowSchema.parse({
    id: parsed.id ?? createLocalId('pca'),
    protocol_id: parsed.protocolId,
    revision_id: parsed.revisionId,
    previous_revision_id: parsed.previousRevisionId ?? null,
    change_type: parsed.changeType,
    effective_from: parsed.effectiveFrom,
    summary: parsed.summary,
    payload_json: parsed.payloadJson,
    created_at: now,
  });
}

export function toVialRow(input: CreateVialInput, now = createIsoTimestamp()): VialRow {
  const parsed = createVialInputSchema.parse(input);

  return vialRowSchema.parse({
    id: parsed.id ?? createLocalId('vil'),
    protocol_id: parsed.protocolId ?? null,
    compound_id: parsed.compoundId ?? null,
    label: parsed.label,
    starting_quantity: parsed.startingQuantity,
    concentration_value: parsed.concentrationValue ?? null,
    concentration_unit: parsed.concentrationUnit ?? null,
    volume_ml: parsed.volumeMl ?? null,
    remaining_quantity: parsed.remainingQuantity,
    low_stock_threshold: parsed.lowStockThreshold ?? null,
    quantity_unit: parsed.quantityUnit,
    opened_at: parsed.openedAt ?? null,
    expires_at: parsed.expiresAt ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toLogEventRow(
  input: CreateLogEventInput,
  now = createIsoTimestamp()
): LogEventRow {
  const parsed = createLogEventInputSchema.parse(input);

  return logEventRowSchema.parse({
    id: parsed.id ?? createLocalId('log'),
    protocol_id: parsed.protocolId,
    vial_id: parsed.vialId ?? null,
    site_id: parsed.siteId ?? null,
    occurrence_id: parsed.occurrenceId ?? null,
    event_type: parsed.eventType,
    effective_at: parsed.effectiveAt,
    logged_at: parsed.loggedAt ?? now,
    quantity: parsed.quantity ?? null,
    quantity_unit: parsed.quantityUnit ?? null,
    notes: parsed.notes ?? null,
    source: parsed.source,
  });
}

export function toReminderRow(
  input: CreateReminderInput,
  now = createIsoTimestamp()
): ReminderRow {
  const parsed = createReminderInputSchema.parse(input);

  return reminderRowSchema.parse({
    id: parsed.id ?? createLocalId('rem'),
    protocol_id: parsed.protocolId,
    occurrence_id: parsed.occurrenceId,
    offset_minutes: parsed.offsetMinutes,
    channel: parsed.channel,
    is_enabled: toSqliteBoolean(parsed.isEnabled),
    discreet_copy_enabled: toSqliteBoolean(parsed.discreetCopyEnabled),
    privacy_mode: parsed.privacyMode,
    scheduled_for: parsed.scheduledFor,
    notification_id: parsed.notificationId ?? null,
    title: parsed.title,
    body: parsed.body,
    status: parsed.status,
    created_at: now,
    updated_at: now,
  });
}

export function toReminderPreferenceRow(
  input: CreateReminderPreferenceInput,
  now = createIsoTimestamp()
): ReminderPreferenceRow {
  const parsed = createReminderPreferenceInputSchema.parse(input);

  return reminderPreferenceRowSchema.parse({
    id: parsed.id,
    reminders_enabled: toSqliteBoolean(parsed.remindersEnabled),
    privacy_mode: parsed.privacyMode,
    lead_time_minutes: parsed.leadTimeMinutes,
    created_at: now,
    updated_at: now,
  });
}

export function toPrivacyProfileRow(
  input: CreatePrivacyProfileInput,
  now = createIsoTimestamp()
): PrivacyProfileRow {
  const parsed = createPrivacyProfileInputSchema.parse(input);

  return privacyProfileRowSchema.parse({
    id: parsed.id,
    alias_mode_enabled: toSqliteBoolean(parsed.aliasModeEnabled),
    biometric_lock_enabled: toSqliteBoolean(parsed.biometricLockEnabled),
    biometric_gate_mode: parsed.biometricGateMode,
    share_alias_by_default: toSqliteBoolean(parsed.shareAliasByDefault),
    export_alias_by_default: toSqliteBoolean(parsed.exportAliasByDefault),
    created_at: now,
    updated_at: now,
  });
}

export function toProtocolAliasRow(
  input: CreateProtocolAliasInput,
  now = createIsoTimestamp()
): ProtocolAliasRow {
  const parsed = createProtocolAliasInputSchema.parse(input);

  return protocolAliasRowSchema.parse({
    id: parsed.id ?? createLocalId('pal'),
    protocol_id: parsed.protocolId,
    alias_label: parsed.aliasLabel,
    alias_compound_label: parsed.aliasCompoundLabel ?? null,
    created_at: now,
    updated_at: now,
    archived_at: parsed.archivedAt ?? null,
  });
}

export function toSensitiveActionAuditEventRow(
  input: CreateSensitiveActionAuditEventInput,
  now = createIsoTimestamp()
): SensitiveActionAuditEventRow {
  const parsed = createSensitiveActionAuditEventInputSchema.parse(input);

  return sensitiveActionAuditEventRowSchema.parse({
    id: parsed.id ?? createLocalId('saa'),
    event_type: parsed.eventType,
    surface: parsed.surface,
    protocol_id: parsed.protocolId ?? null,
    scope_kind: parsed.scopeKind ?? null,
    render_mode: parsed.renderMode ?? null,
    manifest_version: parsed.manifestVersion ?? null,
    payload_json: parsed.payloadJson,
    created_at: now,
  });
}

export function toCustomMetricRow(
  input: CreateCustomMetricInput,
  now = createIsoTimestamp()
): CustomMetricRow {
  const parsed = createCustomMetricInputSchema.parse(input);

  return customMetricRowSchema.parse({
    id: parsed.id ?? createLocalId('met'),
    protocol_id: parsed.protocolId ?? null,
    metric_key: parsed.metricKey,
    label: parsed.label,
    value_type: parsed.valueType,
    unit: parsed.unit ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toCalculatorProfileRow(
  input: CreateCalculatorProfileInput,
  now = createIsoTimestamp()
): CalculatorProfileRow {
  const parsed = createCalculatorProfileInputSchema.parse(input);

  return calculatorProfileRowSchema.parse({
    id: parsed.id ?? createLocalId('cal'),
    label: parsed.label,
    powder_amount: parsed.powderAmount,
    powder_unit: parsed.powderUnit,
    diluent_volume: parsed.diluentVolume,
    diluent_unit: parsed.diluentUnit,
    draw_volume: parsed.drawVolume,
    draw_unit: parsed.drawUnit,
    created_at: now,
    updated_at: now,
  });
}

export function toWeightLogRow(
  input: CreateWeightLogInput,
  now = createIsoTimestamp()
): WeightLogRow {
  const parsed = createWeightLogInputSchema.parse(input);

  return weightLogRowSchema.parse({
    id: parsed.id ?? createLocalId('wgt'),
    logged_at: parsed.loggedAt,
    value: parsed.value,
    unit: parsed.unit,
    source: parsed.source,
    notes: parsed.notes ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toSymptomLogRow(
  input: CreateSymptomLogInput,
  now = createIsoTimestamp()
): SymptomLogRow {
  const parsed = createSymptomLogInputSchema.parse(input);

  return symptomLogRowSchema.parse({
    id: parsed.id ?? createLocalId('sym'),
    logged_at: parsed.loggedAt,
    symptom_key: parsed.symptomKey,
    severity: parsed.severity,
    notes: parsed.notes ?? null,
    source: parsed.source,
    created_at: now,
    updated_at: now,
  });
}

export function toMetricValueLogRow(
  input: CreateMetricValueLogInput,
  now = createIsoTimestamp()
): MetricValueLogRow {
  const parsed = createMetricValueLogInputSchema.parse(input);

  return metricValueLogRowSchema.parse({
    id: parsed.id ?? createLocalId('mvl'),
    metric_id: parsed.metricId,
    protocol_id: parsed.protocolId ?? null,
    logged_at: parsed.loggedAt,
    number_value: parsed.numberValue ?? null,
    text_value: parsed.textValue ?? null,
    boolean_value:
      parsed.booleanValue === undefined || parsed.booleanValue === null
        ? null
        : toSqliteBoolean(parsed.booleanValue),
    source: parsed.source,
    created_at: now,
    updated_at: now,
  });
}

export function toHealthConnectionRow(
  input: CreateHealthConnectionInput,
  now = createIsoTimestamp()
): HealthConnectionRow {
  const parsed = createHealthConnectionInputSchema.parse(input);

  return healthConnectionRowSchema.parse({
    provider_key: parsed.providerKey,
    enabled: toSqliteBoolean(parsed.enabled),
    connected: toSqliteBoolean(parsed.connected),
    last_sync_at: parsed.lastSyncAt ?? null,
    last_error: parsed.lastError ?? null,
    created_at: now,
    updated_at: now,
  });
}

export function toSiteRow(input: CreateSiteInput, now = createIsoTimestamp()): SiteRow {
  const parsed = createSiteInputSchema.parse(input);

  return siteRowSchema.parse({
    id: parsed.id ?? createLocalId('sit'),
    name: parsed.name,
    body_area: parsed.bodyArea ?? null,
    notes: parsed.notes ?? null,
    created_at: now,
    updated_at: now,
    archived_at: parsed.archivedAt ?? null,
  });
}

export function toSqliteBooleanValue(value: boolean): number {
  return toSqliteBoolean(value);
}

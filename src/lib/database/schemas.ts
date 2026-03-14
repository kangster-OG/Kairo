import { z } from 'zod';

const isoTimestampSchema = z.string().min(1);
const sqliteBooleanSchema = z.number().int().min(0).max(1);

export const compoundTypeSchema = z.enum(['glp', 'peptide', 'other']);
export const protocolKindSchema = z.enum(['glp', 'peptide', 'custom']);
export const protocolStatusSchema = z.enum(['draft', 'active', 'paused', 'archived']);
export const protocolRuleTypeSchema = z.enum(['weekly', 'daily', 'every_n_days']);
export const protocolRevisionLifecycleSchema = z.enum(['active', 'paused', 'resting']);
export const protocolRevisionPhaseTypeSchema = z.enum(['base', 'titration', 'rest']);
export const protocolRevisionTimezoneStrategySchema = z.enum([
  'keep_local_clock',
  'keep_home_timezone',
]);
export const protocolMissedDosePolicySchema = z.enum([
  'skip_and_continue',
  'take_now_keep_cadence',
  'take_now_shift_future',
]);
export const protocolChangeAuditTypeSchema = z.enum([
  'future_dose_changed',
  'time_changed',
  'cadence_changed',
  'paused',
  'resumed',
  'titration_changed',
  'rest_period_changed',
  'missed_dose_policy_changed',
  'timezone_changed',
  'vial_handoff_planned',
  'revision_reverted',
]);
export const logEventTypeSchema = z.enum([
  'completed',
  'skipped',
  'rescheduled',
  'manual_log',
  'inventory_adjustment',
]);
export const logEventSourceSchema = z.enum(['user', 'migration', 'system']);
export const reminderChannelSchema = z.enum(['local_notification']);
export const reminderPrivacyModeSchema = z.enum(['full_detail', 'generic', 'silent']);
export const reminderStatusSchema = z.enum(['scheduled', 'cancelled']);
export const biometricGateModeSchema = z.enum([
  'off',
  'best_effort',
  'required_when_available',
]);
export const sensitiveActionAuditEventTypeSchema = z.enum([
  'export_created',
  'selective_share_created',
  'alias_changed',
  'privacy_mode_changed',
  'biometric_lock_changed',
  'vault_unlocked',
]);
export const privacyRenderModeSchema = z.enum(['full', 'discreet', 'alias']);
export const customMetricValueTypeSchema = z.enum(['number', 'text', 'boolean']);
export const weightUnitSchema = z.enum(['lb', 'kg']);
export const healthDataSourceSchema = z.enum(['manual', 'health', 'import']);
export const healthProviderKeySchema = z.enum(['apple_health', 'health_connect']);
export const calculatorProfileSchema = z.object({
  id: z.string(),
  label: z.string(),
  powderAmount: z.number().positive(),
  powderUnit: z.string(),
  diluentVolume: z.number().positive(),
  diluentUnit: z.string(),
  drawVolume: z.number().positive(),
  drawUnit: z.string(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const weightLogSchema = z.object({
  id: z.string(),
  loggedAt: isoTimestampSchema,
  value: z.number().positive(),
  unit: weightUnitSchema,
  source: healthDataSourceSchema,
  notes: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const symptomLogSchema = z.object({
  id: z.string(),
  loggedAt: isoTimestampSchema,
  symptomKey: z.string(),
  severity: z.number().int().min(1).max(5),
  notes: z.string().nullable(),
  source: healthDataSourceSchema,
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const metricValueLogSchema = z
  .object({
    id: z.string(),
    metricId: z.string(),
    protocolId: z.string().nullable(),
    loggedAt: isoTimestampSchema,
    numberValue: z.number().nullable(),
    textValue: z.string().nullable(),
    booleanValue: z.boolean().nullable(),
    source: healthDataSourceSchema,
    createdAt: isoTimestampSchema,
    updatedAt: isoTimestampSchema,
  })
  .refine(
    (value) =>
      value.numberValue !== null || value.textValue !== null || value.booleanValue !== null,
    'Metric value logs require at least one stored value.'
  );

export const healthConnectionSchema = z.object({
  providerKey: healthProviderKeySchema,
  enabled: z.boolean(),
  connected: z.boolean(),
  lastSyncAt: z.string().nullable(),
  lastError: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const compoundSchema = z.object({
  id: z.string(),
  slug: z.string(),
  displayName: z.string(),
  compoundType: compoundTypeSchema,
  isUserDefined: z.boolean(),
  notes: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolSchema = z.object({
  id: z.string(),
  compoundId: z.string().nullable(),
  linkedVialId: z.string().nullable(),
  name: z.string(),
  kind: protocolKindSchema,
  status: protocolStatusSchema,
  timezone: z.string(),
  startDate: z.string(),
  defaultTimeOfDay: z.string().nullable(),
  doseAmount: z.number().nullable(),
  doseUnit: z.string().nullable(),
  siteTrackingEnabled: z.boolean(),
  siteRotationEnabled: z.boolean(),
  notes: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolRuleSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  ruleType: protocolRuleTypeSchema,
  intervalCount: z.number().int().positive(),
  weekday: z.number().int().min(0).max(6).nullable(),
  timeOfDay: z.string().nullable(),
  anchorDate: z.string().nullable(),
  isActive: z.boolean(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolRevisionSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  revisionNumber: z.number().int().positive(),
  previousRevisionId: z.string().nullable(),
  effectiveFrom: isoTimestampSchema,
  effectiveTo: z.string().nullable(),
  lifecycleState: protocolRevisionLifecycleSchema,
  timezone: z.string(),
  timezoneStrategy: protocolRevisionTimezoneStrategySchema,
  defaultTimeOfDay: z.string().nullable(),
  doseAmount: z.number().nullable(),
  doseUnit: z.string().nullable(),
  linkedVialId: z.string().nullable(),
  missedDosePolicy: protocolMissedDosePolicySchema,
  notes: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolRevisionRuleSchema = z.object({
  id: z.string(),
  revisionId: z.string(),
  phaseType: protocolRevisionPhaseTypeSchema,
  phaseOrder: z.number().int().nonnegative(),
  ruleType: protocolRuleTypeSchema,
  intervalCount: z.number().int().positive(),
  weekday: z.number().int().min(0).max(6).nullable(),
  timeOfDay: z.string().nullable(),
  anchorDate: z.string().nullable(),
  phaseStartDayOffset: z.number().int().nonnegative(),
  phaseLengthDays: z.number().int().positive().nullable(),
  doseAmountOverride: z.number().nullable(),
  doseUnitOverride: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolChangeAuditEventSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  revisionId: z.string(),
  previousRevisionId: z.string().nullable(),
  changeType: protocolChangeAuditTypeSchema,
  effectiveFrom: isoTimestampSchema,
  summary: z.string(),
  payloadJson: z.string(),
  createdAt: isoTimestampSchema,
});

export const vialSchema = z.object({
  id: z.string(),
  protocolId: z.string().nullable(),
  compoundId: z.string().nullable(),
  label: z.string(),
  startingQuantity: z.number(),
  concentrationValue: z.number().nullable(),
  concentrationUnit: z.string().nullable(),
  volumeMl: z.number().nullable(),
  remainingQuantity: z.number(),
  lowStockThreshold: z.number().nullable(),
  quantityUnit: z.string(),
  openedAt: z.string().nullable(),
  expiresAt: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const logEventSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  vialId: z.string().nullable(),
  siteId: z.string().nullable(),
  occurrenceId: z.string().nullable(),
  eventType: logEventTypeSchema,
  effectiveAt: isoTimestampSchema,
  loggedAt: isoTimestampSchema,
  quantity: z.number().nullable(),
  quantityUnit: z.string().nullable(),
  notes: z.string().nullable(),
  source: logEventSourceSchema,
});

export const reminderSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  occurrenceId: z.string(),
  offsetMinutes: z.number().int(),
  channel: reminderChannelSchema,
  isEnabled: z.boolean(),
  discreetCopyEnabled: z.boolean(),
  privacyMode: reminderPrivacyModeSchema,
  scheduledFor: isoTimestampSchema,
  notificationId: z.string().nullable(),
  title: z.string(),
  body: z.string(),
  status: reminderStatusSchema,
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const reminderPreferenceSchema = z.object({
  id: z.string(),
  remindersEnabled: z.boolean(),
  privacyMode: reminderPrivacyModeSchema,
  leadTimeMinutes: z.number().int().min(0).max(1440),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const privacyProfileSchema = z.object({
  id: z.string(),
  aliasModeEnabled: z.boolean(),
  biometricLockEnabled: z.boolean(),
  biometricGateMode: biometricGateModeSchema,
  shareAliasByDefault: z.boolean(),
  exportAliasByDefault: z.boolean(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const protocolAliasSchema = z.object({
  id: z.string(),
  protocolId: z.string(),
  aliasLabel: z.string(),
  aliasCompoundLabel: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
  archivedAt: z.string().nullable(),
});

export const sensitiveActionAuditEventSchema = z.object({
  id: z.string(),
  eventType: sensitiveActionAuditEventTypeSchema,
  surface: z.string(),
  protocolId: z.string().nullable(),
  scopeKind: z.string().nullable(),
  renderMode: privacyRenderModeSchema.nullable(),
  manifestVersion: z.number().int().nullable(),
  payloadJson: z.string(),
  createdAt: isoTimestampSchema,
});

export const customMetricSchema = z.object({
  id: z.string(),
  protocolId: z.string().nullable(),
  metricKey: z.string(),
  label: z.string(),
  valueType: customMetricValueTypeSchema,
  unit: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
});

export const siteSchema = z.object({
  id: z.string(),
  name: z.string(),
  bodyArea: z.string().nullable(),
  notes: z.string().nullable(),
  createdAt: isoTimestampSchema,
  updatedAt: isoTimestampSchema,
  archivedAt: z.string().nullable(),
});

export const compoundRowSchema = z.object({
  id: z.string(),
  slug: z.string(),
  display_name: z.string(),
  compound_type: compoundTypeSchema,
  is_user_defined: sqliteBooleanSchema,
  notes: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolRowSchema = z.object({
  id: z.string(),
  compound_id: z.string().nullable(),
  linked_vial_id: z.string().nullable(),
  name: z.string(),
  kind: protocolKindSchema,
  status: protocolStatusSchema,
  timezone: z.string(),
  start_date: z.string(),
  default_time_of_day: z.string().nullable(),
  dose_amount: z.number().nullable(),
  dose_unit: z.string().nullable(),
  site_tracking_enabled: sqliteBooleanSchema,
  site_rotation_enabled: sqliteBooleanSchema,
  notes: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolRuleRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  rule_type: protocolRuleTypeSchema,
  interval_count: z.number().int().positive(),
  weekday: z.number().int().min(0).max(6).nullable(),
  time_of_day: z.string().nullable(),
  anchor_date: z.string().nullable(),
  is_active: sqliteBooleanSchema,
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolRevisionRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  revision_number: z.number().int().positive(),
  previous_revision_id: z.string().nullable(),
  effective_from: isoTimestampSchema,
  effective_to: z.string().nullable(),
  lifecycle_state: protocolRevisionLifecycleSchema,
  timezone: z.string(),
  timezone_strategy: protocolRevisionTimezoneStrategySchema,
  default_time_of_day: z.string().nullable(),
  dose_amount: z.number().nullable(),
  dose_unit: z.string().nullable(),
  linked_vial_id: z.string().nullable(),
  missed_dose_policy: protocolMissedDosePolicySchema,
  notes: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolRevisionRuleRowSchema = z.object({
  id: z.string(),
  revision_id: z.string(),
  phase_type: protocolRevisionPhaseTypeSchema,
  phase_order: z.number().int().nonnegative(),
  rule_type: protocolRuleTypeSchema,
  interval_count: z.number().int().positive(),
  weekday: z.number().int().min(0).max(6).nullable(),
  time_of_day: z.string().nullable(),
  anchor_date: z.string().nullable(),
  phase_start_day_offset: z.number().int().nonnegative(),
  phase_length_days: z.number().int().positive().nullable(),
  dose_amount_override: z.number().nullable(),
  dose_unit_override: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolChangeAuditEventRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  revision_id: z.string(),
  previous_revision_id: z.string().nullable(),
  change_type: protocolChangeAuditTypeSchema,
  effective_from: isoTimestampSchema,
  summary: z.string(),
  payload_json: z.string(),
  created_at: isoTimestampSchema,
});

export const vialRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string().nullable(),
  compound_id: z.string().nullable(),
  label: z.string(),
  starting_quantity: z.number(),
  concentration_value: z.number().nullable(),
  concentration_unit: z.string().nullable(),
  volume_ml: z.number().nullable(),
  remaining_quantity: z.number(),
  low_stock_threshold: z.number().nullable(),
  quantity_unit: z.string(),
  opened_at: z.string().nullable(),
  expires_at: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const logEventRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  vial_id: z.string().nullable(),
  site_id: z.string().nullable(),
  occurrence_id: z.string().nullable(),
  event_type: logEventTypeSchema,
  effective_at: isoTimestampSchema,
  logged_at: isoTimestampSchema,
  quantity: z.number().nullable(),
  quantity_unit: z.string().nullable(),
  notes: z.string().nullable(),
  source: logEventSourceSchema,
});

export const reminderRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  occurrence_id: z.string(),
  offset_minutes: z.number().int(),
  channel: reminderChannelSchema,
  is_enabled: sqliteBooleanSchema,
  discreet_copy_enabled: sqliteBooleanSchema,
  privacy_mode: reminderPrivacyModeSchema,
  scheduled_for: isoTimestampSchema,
  notification_id: z.string().nullable(),
  title: z.string(),
  body: z.string(),
  status: reminderStatusSchema,
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const reminderPreferenceRowSchema = z.object({
  id: z.string(),
  reminders_enabled: sqliteBooleanSchema,
  privacy_mode: reminderPrivacyModeSchema,
  lead_time_minutes: z.number().int().min(0).max(1440),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const privacyProfileRowSchema = z.object({
  id: z.string(),
  alias_mode_enabled: sqliteBooleanSchema,
  biometric_lock_enabled: sqliteBooleanSchema,
  biometric_gate_mode: biometricGateModeSchema,
  share_alias_by_default: sqliteBooleanSchema,
  export_alias_by_default: sqliteBooleanSchema,
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const protocolAliasRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string(),
  alias_label: z.string(),
  alias_compound_label: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
  archived_at: z.string().nullable(),
});

export const sensitiveActionAuditEventRowSchema = z.object({
  id: z.string(),
  event_type: sensitiveActionAuditEventTypeSchema,
  surface: z.string(),
  protocol_id: z.string().nullable(),
  scope_kind: z.string().nullable(),
  render_mode: privacyRenderModeSchema.nullable(),
  manifest_version: z.number().int().nullable(),
  payload_json: z.string(),
  created_at: isoTimestampSchema,
});

export const customMetricRowSchema = z.object({
  id: z.string(),
  protocol_id: z.string().nullable(),
  metric_key: z.string(),
  label: z.string(),
  value_type: customMetricValueTypeSchema,
  unit: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});
export const calculatorProfileRowSchema = z.object({
  id: z.string(),
  label: z.string(),
  powder_amount: z.number().positive(),
  powder_unit: z.string(),
  diluent_volume: z.number().positive(),
  diluent_unit: z.string(),
  draw_volume: z.number().positive(),
  draw_unit: z.string(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const weightLogRowSchema = z.object({
  id: z.string(),
  logged_at: isoTimestampSchema,
  value: z.number().positive(),
  unit: weightUnitSchema,
  source: healthDataSourceSchema,
  notes: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const symptomLogRowSchema = z.object({
  id: z.string(),
  logged_at: isoTimestampSchema,
  symptom_key: z.string(),
  severity: z.number().int().min(1).max(5),
  notes: z.string().nullable(),
  source: healthDataSourceSchema,
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const metricValueLogRowSchema = z.object({
  id: z.string(),
  metric_id: z.string(),
  protocol_id: z.string().nullable(),
  logged_at: isoTimestampSchema,
  number_value: z.number().nullable(),
  text_value: z.string().nullable(),
  boolean_value: sqliteBooleanSchema.nullable(),
  source: healthDataSourceSchema,
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const healthConnectionRowSchema = z.object({
  provider_key: healthProviderKeySchema,
  enabled: sqliteBooleanSchema,
  connected: sqliteBooleanSchema,
  last_sync_at: z.string().nullable(),
  last_error: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
});

export const siteRowSchema = z.object({
  id: z.string(),
  name: z.string(),
  body_area: z.string().nullable(),
  notes: z.string().nullable(),
  created_at: isoTimestampSchema,
  updated_at: isoTimestampSchema,
  archived_at: z.string().nullable(),
});

export const createCompoundInputSchema = z.object({
  id: z.string().optional(),
  slug: z.string(),
  displayName: z.string(),
  compoundType: compoundTypeSchema,
  isUserDefined: z.boolean().default(true),
  notes: z.string().nullable().optional(),
});

export const updateCompoundInputSchema = z.object({
  id: z.string(),
  slug: z.string().optional(),
  displayName: z.string().optional(),
  compoundType: compoundTypeSchema.optional(),
  isUserDefined: z.boolean().optional(),
  notes: z.string().nullable().optional(),
});

export const createProtocolInputSchema = z.object({
  id: z.string().optional(),
  compoundId: z.string().nullable().optional(),
  linkedVialId: z.string().nullable().optional(),
  name: z.string(),
  kind: protocolKindSchema,
  status: protocolStatusSchema.default('draft'),
  timezone: z.string(),
  startDate: z.string(),
  defaultTimeOfDay: z.string().nullable().optional(),
  doseAmount: z.number().nullable().optional(),
  doseUnit: z.string().nullable().optional(),
  siteTrackingEnabled: z.boolean().default(false),
  siteRotationEnabled: z.boolean().default(false),
  notes: z.string().nullable().optional(),
});

export const updateProtocolInputSchema = z.object({
  id: z.string(),
  compoundId: z.string().nullable().optional(),
  linkedVialId: z.string().nullable().optional(),
  name: z.string().optional(),
  kind: protocolKindSchema.optional(),
  status: protocolStatusSchema.optional(),
  timezone: z.string().optional(),
  startDate: z.string().optional(),
  defaultTimeOfDay: z.string().nullable().optional(),
  doseAmount: z.number().nullable().optional(),
  doseUnit: z.string().nullable().optional(),
  siteTrackingEnabled: z.boolean().optional(),
  siteRotationEnabled: z.boolean().optional(),
  notes: z.string().nullable().optional(),
});

export const createProtocolRuleInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  ruleType: protocolRuleTypeSchema,
  intervalCount: z.number().int().positive().default(1),
  weekday: z.number().int().min(0).max(6).nullable().optional(),
  timeOfDay: z.string().nullable().optional(),
  anchorDate: z.string().nullable().optional(),
  isActive: z.boolean().default(true),
});

export const createProtocolRevisionInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  revisionNumber: z.number().int().positive(),
  previousRevisionId: z.string().nullable().optional(),
  effectiveFrom: z.string(),
  effectiveTo: z.string().nullable().optional(),
  lifecycleState: protocolRevisionLifecycleSchema.default('active'),
  timezone: z.string(),
  timezoneStrategy: protocolRevisionTimezoneStrategySchema.default('keep_local_clock'),
  defaultTimeOfDay: z.string().nullable().optional(),
  doseAmount: z.number().nullable().optional(),
  doseUnit: z.string().nullable().optional(),
  linkedVialId: z.string().nullable().optional(),
  missedDosePolicy: protocolMissedDosePolicySchema.default('skip_and_continue'),
  notes: z.string().nullable().optional(),
});

export const updateProtocolRevisionInputSchema = z.object({
  id: z.string(),
  revisionNumber: z.number().int().positive().optional(),
  previousRevisionId: z.string().nullable().optional(),
  effectiveFrom: z.string().optional(),
  effectiveTo: z.string().nullable().optional(),
  lifecycleState: protocolRevisionLifecycleSchema.optional(),
  timezone: z.string().optional(),
  timezoneStrategy: protocolRevisionTimezoneStrategySchema.optional(),
  defaultTimeOfDay: z.string().nullable().optional(),
  doseAmount: z.number().nullable().optional(),
  doseUnit: z.string().nullable().optional(),
  linkedVialId: z.string().nullable().optional(),
  missedDosePolicy: protocolMissedDosePolicySchema.optional(),
  notes: z.string().nullable().optional(),
});

export const createProtocolRevisionRuleInputSchema = z.object({
  id: z.string().optional(),
  revisionId: z.string(),
  phaseType: protocolRevisionPhaseTypeSchema.default('base'),
  phaseOrder: z.number().int().nonnegative().default(0),
  ruleType: protocolRuleTypeSchema,
  intervalCount: z.number().int().positive().default(1),
  weekday: z.number().int().min(0).max(6).nullable().optional(),
  timeOfDay: z.string().nullable().optional(),
  anchorDate: z.string().nullable().optional(),
  phaseStartDayOffset: z.number().int().nonnegative().default(0),
  phaseLengthDays: z.number().int().positive().nullable().optional(),
  doseAmountOverride: z.number().nullable().optional(),
  doseUnitOverride: z.string().nullable().optional(),
});

export const updateProtocolRevisionRuleInputSchema = z.object({
  id: z.string(),
  phaseType: protocolRevisionPhaseTypeSchema.optional(),
  phaseOrder: z.number().int().nonnegative().optional(),
  ruleType: protocolRuleTypeSchema.optional(),
  intervalCount: z.number().int().positive().optional(),
  weekday: z.number().int().min(0).max(6).nullable().optional(),
  timeOfDay: z.string().nullable().optional(),
  anchorDate: z.string().nullable().optional(),
  phaseStartDayOffset: z.number().int().nonnegative().optional(),
  phaseLengthDays: z.number().int().positive().nullable().optional(),
  doseAmountOverride: z.number().nullable().optional(),
  doseUnitOverride: z.string().nullable().optional(),
});

export const createProtocolChangeAuditEventInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  revisionId: z.string(),
  previousRevisionId: z.string().nullable().optional(),
  changeType: protocolChangeAuditTypeSchema,
  effectiveFrom: z.string(),
  summary: z.string().min(1),
  payloadJson: z.string().min(2),
});

export const updateProtocolRuleInputSchema = z.object({
  id: z.string(),
  protocolId: z.string().optional(),
  ruleType: protocolRuleTypeSchema.optional(),
  intervalCount: z.number().int().positive().optional(),
  weekday: z.number().int().min(0).max(6).nullable().optional(),
  timeOfDay: z.string().nullable().optional(),
  anchorDate: z.string().nullable().optional(),
  isActive: z.boolean().optional(),
});

export const createVialInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string().nullable().optional(),
  compoundId: z.string().nullable().optional(),
  label: z.string(),
  startingQuantity: z.number(),
  concentrationValue: z.number().nullable().optional(),
  concentrationUnit: z.string().nullable().optional(),
  volumeMl: z.number().nullable().optional(),
  remainingQuantity: z.number(),
  lowStockThreshold: z.number().nullable().optional(),
  quantityUnit: z.string(),
  openedAt: z.string().nullable().optional(),
  expiresAt: z.string().nullable().optional(),
});

export const updateVialInputSchema = z.object({
  id: z.string(),
  protocolId: z.string().nullable().optional(),
  compoundId: z.string().nullable().optional(),
  label: z.string().optional(),
  startingQuantity: z.number().optional(),
  concentrationValue: z.number().nullable().optional(),
  concentrationUnit: z.string().nullable().optional(),
  volumeMl: z.number().nullable().optional(),
  remainingQuantity: z.number().optional(),
  lowStockThreshold: z.number().nullable().optional(),
  quantityUnit: z.string().optional(),
  openedAt: z.string().nullable().optional(),
  expiresAt: z.string().nullable().optional(),
});

export const createLogEventInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  vialId: z.string().nullable().optional(),
  siteId: z.string().nullable().optional(),
  occurrenceId: z.string().nullable().optional(),
  eventType: logEventTypeSchema,
  effectiveAt: z.string(),
  loggedAt: z.string().optional(),
  quantity: z.number().nullable().optional(),
  quantityUnit: z.string().nullable().optional(),
  notes: z.string().nullable().optional(),
  source: logEventSourceSchema.default('user'),
});

export const createReminderInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  occurrenceId: z.string(),
  offsetMinutes: z.number().int().default(0),
  channel: reminderChannelSchema.default('local_notification'),
  isEnabled: z.boolean().default(true),
  discreetCopyEnabled: z.boolean().default(false),
  privacyMode: reminderPrivacyModeSchema.default('full_detail'),
  scheduledFor: z.string(),
  notificationId: z.string().nullable().optional(),
  title: z.string(),
  body: z.string(),
  status: reminderStatusSchema.default('scheduled'),
});

export const updateReminderInputSchema = z.object({
  id: z.string(),
  protocolId: z.string().optional(),
  occurrenceId: z.string().optional(),
  offsetMinutes: z.number().int().optional(),
  channel: reminderChannelSchema.optional(),
  isEnabled: z.boolean().optional(),
  discreetCopyEnabled: z.boolean().optional(),
  privacyMode: reminderPrivacyModeSchema.optional(),
  scheduledFor: z.string().optional(),
  notificationId: z.string().nullable().optional(),
  title: z.string().optional(),
  body: z.string().optional(),
  status: reminderStatusSchema.optional(),
});

export const createReminderPreferenceInputSchema = z.object({
  id: z.string().default('default'),
  remindersEnabled: z.boolean().default(true),
  privacyMode: reminderPrivacyModeSchema.default('full_detail'),
  leadTimeMinutes: z.number().int().min(0).max(1440).default(0),
});

export const updateReminderPreferenceInputSchema = z.object({
  id: z.string().default('default'),
  remindersEnabled: z.boolean().optional(),
  privacyMode: reminderPrivacyModeSchema.optional(),
  leadTimeMinutes: z.number().int().min(0).max(1440).optional(),
});

export const createPrivacyProfileInputSchema = z.object({
  id: z.string().default('default'),
  aliasModeEnabled: z.boolean().default(false),
  biometricLockEnabled: z.boolean().default(false),
  biometricGateMode: biometricGateModeSchema.default('best_effort'),
  shareAliasByDefault: z.boolean().default(true),
  exportAliasByDefault: z.boolean().default(true),
});

export const updatePrivacyProfileInputSchema = z.object({
  id: z.string().default('default'),
  aliasModeEnabled: z.boolean().optional(),
  biometricLockEnabled: z.boolean().optional(),
  biometricGateMode: biometricGateModeSchema.optional(),
  shareAliasByDefault: z.boolean().optional(),
  exportAliasByDefault: z.boolean().optional(),
});

export const createProtocolAliasInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string(),
  aliasLabel: z.string().min(1),
  aliasCompoundLabel: z.string().nullable().optional(),
  archivedAt: z.string().nullable().optional(),
});

export const updateProtocolAliasInputSchema = z.object({
  id: z.string(),
  aliasLabel: z.string().min(1).optional(),
  aliasCompoundLabel: z.string().nullable().optional(),
  archivedAt: z.string().nullable().optional(),
});

export const createSensitiveActionAuditEventInputSchema = z.object({
  id: z.string().optional(),
  eventType: sensitiveActionAuditEventTypeSchema,
  surface: z.string().min(1),
  protocolId: z.string().nullable().optional(),
  scopeKind: z.string().nullable().optional(),
  renderMode: privacyRenderModeSchema.nullable().optional(),
  manifestVersion: z.number().int().nullable().optional(),
  payloadJson: z.string().min(2),
});

export const createCustomMetricInputSchema = z.object({
  id: z.string().optional(),
  protocolId: z.string().nullable().optional(),
  metricKey: z.string(),
  label: z.string(),
  valueType: customMetricValueTypeSchema,
  unit: z.string().nullable().optional(),
});

export const updateCustomMetricInputSchema = z.object({
  id: z.string(),
  protocolId: z.string().nullable().optional(),
  metricKey: z.string().optional(),
  label: z.string().optional(),
  valueType: customMetricValueTypeSchema.optional(),
  unit: z.string().nullable().optional(),
});
export const createCalculatorProfileInputSchema = z.object({
  id: z.string().optional(),
  label: z.string().min(1),
  powderAmount: z.number().positive(),
  powderUnit: z.string().min(1),
  diluentVolume: z.number().positive(),
  diluentUnit: z.string().min(1),
  drawVolume: z.number().positive(),
  drawUnit: z.string().min(1),
});

export const createWeightLogInputSchema = z.object({
  id: z.string().optional(),
  loggedAt: z.string(),
  value: z.number().positive(),
  unit: weightUnitSchema,
  source: healthDataSourceSchema.default('manual'),
  notes: z.string().nullable().optional(),
});

export const createSymptomLogInputSchema = z.object({
  id: z.string().optional(),
  loggedAt: z.string(),
  symptomKey: z.string().min(1),
  severity: z.number().int().min(1).max(5),
  notes: z.string().nullable().optional(),
  source: healthDataSourceSchema.default('manual'),
});

export const createMetricValueLogInputSchema = z
  .object({
    id: z.string().optional(),
    metricId: z.string(),
    protocolId: z.string().nullable().optional(),
    loggedAt: z.string(),
    numberValue: z.number().nullable().optional(),
    textValue: z.string().nullable().optional(),
    booleanValue: z.boolean().nullable().optional(),
    source: healthDataSourceSchema.default('manual'),
  })
  .refine(
    (value) =>
      value.numberValue !== undefined ||
      value.textValue !== undefined ||
      value.booleanValue !== undefined,
    'Metric value logs require at least one value.'
  );

export const createHealthConnectionInputSchema = z.object({
  providerKey: healthProviderKeySchema,
  enabled: z.boolean().default(false),
  connected: z.boolean().default(false),
  lastSyncAt: z.string().nullable().optional(),
  lastError: z.string().nullable().optional(),
});

export const updateHealthConnectionInputSchema = z.object({
  providerKey: healthProviderKeySchema,
  enabled: z.boolean().optional(),
  connected: z.boolean().optional(),
  lastSyncAt: z.string().nullable().optional(),
  lastError: z.string().nullable().optional(),
});

export const updateCalculatorProfileInputSchema = z.object({
  id: z.string(),
  label: z.string().min(1).optional(),
  powderAmount: z.number().positive().optional(),
  powderUnit: z.string().min(1).optional(),
  diluentVolume: z.number().positive().optional(),
  diluentUnit: z.string().min(1).optional(),
  drawVolume: z.number().positive().optional(),
  drawUnit: z.string().min(1).optional(),
});

export const createSiteInputSchema = z.object({
  id: z.string().optional(),
  name: z.string(),
  bodyArea: z.string().nullable().optional(),
  notes: z.string().nullable().optional(),
  archivedAt: z.string().nullable().optional(),
});

export const updateSiteInputSchema = z.object({
  id: z.string(),
  name: z.string().optional(),
  bodyArea: z.string().nullable().optional(),
  notes: z.string().nullable().optional(),
  archivedAt: z.string().nullable().optional(),
});

export type CompoundType = z.infer<typeof compoundTypeSchema>;
export type ProtocolKind = z.infer<typeof protocolKindSchema>;
export type ProtocolStatus = z.infer<typeof protocolStatusSchema>;
export type ProtocolRuleType = z.infer<typeof protocolRuleTypeSchema>;
export type ProtocolRevisionLifecycle = z.infer<typeof protocolRevisionLifecycleSchema>;
export type ProtocolRevisionPhaseType = z.infer<typeof protocolRevisionPhaseTypeSchema>;
export type ProtocolRevisionTimezoneStrategy = z.infer<typeof protocolRevisionTimezoneStrategySchema>;
export type ProtocolMissedDosePolicy = z.infer<typeof protocolMissedDosePolicySchema>;
export type ProtocolChangeAuditType = z.infer<typeof protocolChangeAuditTypeSchema>;
export type LogEventType = z.infer<typeof logEventTypeSchema>;
export type LogEventSource = z.infer<typeof logEventSourceSchema>;
export type ReminderChannel = z.infer<typeof reminderChannelSchema>;
export type ReminderPrivacyMode = z.infer<typeof reminderPrivacyModeSchema>;
export type ReminderStatus = z.infer<typeof reminderStatusSchema>;
export type BiometricGateMode = z.infer<typeof biometricGateModeSchema>;
export type SensitiveActionAuditEventType = z.infer<typeof sensitiveActionAuditEventTypeSchema>;
export type PrivacyRenderMode = z.infer<typeof privacyRenderModeSchema>;
export type CustomMetricValueType = z.infer<typeof customMetricValueTypeSchema>;
export type WeightUnit = z.infer<typeof weightUnitSchema>;
export type HealthDataSource = z.infer<typeof healthDataSourceSchema>;
export type HealthProviderKey = z.infer<typeof healthProviderKeySchema>;

export type Compound = z.infer<typeof compoundSchema>;
export type Protocol = z.infer<typeof protocolSchema>;
export type ProtocolRule = z.infer<typeof protocolRuleSchema>;
export type ProtocolRevision = z.infer<typeof protocolRevisionSchema>;
export type ProtocolRevisionRule = z.infer<typeof protocolRevisionRuleSchema>;
export type ProtocolChangeAuditEvent = z.infer<typeof protocolChangeAuditEventSchema>;
export type Vial = z.infer<typeof vialSchema>;
export type LogEvent = z.infer<typeof logEventSchema>;
export type Reminder = z.infer<typeof reminderSchema>;
export type ReminderPreference = z.infer<typeof reminderPreferenceSchema>;
export type PrivacyProfile = z.infer<typeof privacyProfileSchema>;
export type ProtocolAlias = z.infer<typeof protocolAliasSchema>;
export type SensitiveActionAuditEvent = z.infer<typeof sensitiveActionAuditEventSchema>;
export type CustomMetric = z.infer<typeof customMetricSchema>;
export type Site = z.infer<typeof siteSchema>;
export type CalculatorProfile = z.infer<typeof calculatorProfileSchema>;
export type WeightLog = z.infer<typeof weightLogSchema>;
export type SymptomLog = z.infer<typeof symptomLogSchema>;
export type MetricValueLog = z.infer<typeof metricValueLogSchema>;
export type HealthConnection = z.infer<typeof healthConnectionSchema>;

export type CompoundRow = z.infer<typeof compoundRowSchema>;
export type ProtocolRow = z.infer<typeof protocolRowSchema>;
export type ProtocolRuleRow = z.infer<typeof protocolRuleRowSchema>;
export type ProtocolRevisionRow = z.infer<typeof protocolRevisionRowSchema>;
export type ProtocolRevisionRuleRow = z.infer<typeof protocolRevisionRuleRowSchema>;
export type ProtocolChangeAuditEventRow = z.infer<typeof protocolChangeAuditEventRowSchema>;
export type VialRow = z.infer<typeof vialRowSchema>;
export type LogEventRow = z.infer<typeof logEventRowSchema>;
export type ReminderRow = z.infer<typeof reminderRowSchema>;
export type ReminderPreferenceRow = z.infer<typeof reminderPreferenceRowSchema>;
export type PrivacyProfileRow = z.infer<typeof privacyProfileRowSchema>;
export type ProtocolAliasRow = z.infer<typeof protocolAliasRowSchema>;
export type SensitiveActionAuditEventRow = z.infer<typeof sensitiveActionAuditEventRowSchema>;
export type CustomMetricRow = z.infer<typeof customMetricRowSchema>;
export type SiteRow = z.infer<typeof siteRowSchema>;
export type CalculatorProfileRow = z.infer<typeof calculatorProfileRowSchema>;
export type WeightLogRow = z.infer<typeof weightLogRowSchema>;
export type SymptomLogRow = z.infer<typeof symptomLogRowSchema>;
export type MetricValueLogRow = z.infer<typeof metricValueLogRowSchema>;
export type HealthConnectionRow = z.infer<typeof healthConnectionRowSchema>;

export type CreateCompoundInput = z.infer<typeof createCompoundInputSchema>;
export type UpdateCompoundInput = z.infer<typeof updateCompoundInputSchema>;
export type CreateProtocolInput = z.infer<typeof createProtocolInputSchema>;
export type UpdateProtocolInput = z.infer<typeof updateProtocolInputSchema>;
export type CreateProtocolRuleInput = z.infer<typeof createProtocolRuleInputSchema>;
export type UpdateProtocolRuleInput = z.infer<typeof updateProtocolRuleInputSchema>;
export type CreateProtocolRevisionInput = z.infer<typeof createProtocolRevisionInputSchema>;
export type UpdateProtocolRevisionInput = z.infer<typeof updateProtocolRevisionInputSchema>;
export type CreateProtocolRevisionRuleInput = z.infer<typeof createProtocolRevisionRuleInputSchema>;
export type UpdateProtocolRevisionRuleInput = z.infer<typeof updateProtocolRevisionRuleInputSchema>;
export type CreateProtocolChangeAuditEventInput = z.infer<
  typeof createProtocolChangeAuditEventInputSchema
>;
export type CreateVialInput = z.infer<typeof createVialInputSchema>;
export type UpdateVialInput = z.infer<typeof updateVialInputSchema>;
export type CreateLogEventInput = z.infer<typeof createLogEventInputSchema>;
export type CreateReminderInput = z.infer<typeof createReminderInputSchema>;
export type UpdateReminderInput = z.infer<typeof updateReminderInputSchema>;
export type CreateReminderPreferenceInput = z.infer<typeof createReminderPreferenceInputSchema>;
export type UpdateReminderPreferenceInput = z.infer<typeof updateReminderPreferenceInputSchema>;
export type CreatePrivacyProfileInput = z.infer<typeof createPrivacyProfileInputSchema>;
export type UpdatePrivacyProfileInput = z.infer<typeof updatePrivacyProfileInputSchema>;
export type CreateProtocolAliasInput = z.infer<typeof createProtocolAliasInputSchema>;
export type UpdateProtocolAliasInput = z.infer<typeof updateProtocolAliasInputSchema>;
export type CreateSensitiveActionAuditEventInput = z.infer<
  typeof createSensitiveActionAuditEventInputSchema
>;
export type CreateCustomMetricInput = z.infer<typeof createCustomMetricInputSchema>;
export type UpdateCustomMetricInput = z.infer<typeof updateCustomMetricInputSchema>;
export type CreateSiteInput = z.infer<typeof createSiteInputSchema>;
export type UpdateSiteInput = z.infer<typeof updateSiteInputSchema>;
export type CreateCalculatorProfileInput = z.infer<typeof createCalculatorProfileInputSchema>;
export type UpdateCalculatorProfileInput = z.infer<typeof updateCalculatorProfileInputSchema>;
export type CreateWeightLogInput = z.infer<typeof createWeightLogInputSchema>;
export type CreateSymptomLogInput = z.infer<typeof createSymptomLogInputSchema>;
export type CreateMetricValueLogInput = z.infer<typeof createMetricValueLogInputSchema>;
export type CreateHealthConnectionInput = z.infer<typeof createHealthConnectionInputSchema>;
export type UpdateHealthConnectionInput = z.infer<typeof updateHealthConnectionInputSchema>;

import type { DatabaseClient } from '@/src/lib/database/client';
import {
  SqliteCalculatorProfileRepository,
  type CalculatorProfileRepository,
} from '@/src/lib/database/repositories/calculator-profile-repository';
import {
  SqliteCompoundRepository,
  type CompoundRepository,
} from '@/src/lib/database/repositories/compound-repository';
import {
  SqliteCustomMetricRepository,
  type CustomMetricRepository,
} from '@/src/lib/database/repositories/custom-metric-repository';
import {
  SqliteHealthConnectionRepository,
  type HealthConnectionRepository,
} from '@/src/lib/database/repositories/health-connection-repository';
import {
  SqliteLogEventRepository,
  type LogEventRepository,
} from '@/src/lib/database/repositories/log-event-repository';
import {
  SqliteMetricValueLogRepository,
  type MetricValueLogRepository,
} from '@/src/lib/database/repositories/metric-value-log-repository';
import {
  SqlitePrivacyProfileRepository,
  type PrivacyProfileRepository,
} from '@/src/lib/database/repositories/privacy-profile-repository';
import {
  SqliteProtocolChangeAuditRepository,
  type ProtocolChangeAuditRepository,
} from '@/src/lib/database/repositories/protocol-change-audit-repository';
import {
  SqliteProtocolAliasRepository,
  type ProtocolAliasRepository,
} from '@/src/lib/database/repositories/protocol-alias-repository';
import {
  SqliteProtocolRepository,
  type ProtocolRepository,
} from '@/src/lib/database/repositories/protocol-repository';
import {
  SqliteProtocolRevisionRepository,
  type ProtocolRevisionRepository,
} from '@/src/lib/database/repositories/protocol-revision-repository';
import {
  SqliteProtocolRevisionRuleRepository,
  type ProtocolRevisionRuleRepository,
} from '@/src/lib/database/repositories/protocol-revision-rule-repository';
import {
  SqliteProtocolRuleRepository,
  type ProtocolRuleRepository,
} from '@/src/lib/database/repositories/protocol-rule-repository';
import {
  SqliteReminderPreferenceRepository,
  type ReminderPreferenceRepository,
} from '@/src/lib/database/repositories/reminder-preference-repository';
import {
  SqliteReminderRepository,
  type ReminderRepository,
} from '@/src/lib/database/repositories/reminder-repository';
import {
  SqliteSensitiveActionAuditRepository,
  type SensitiveActionAuditRepository,
} from '@/src/lib/database/repositories/sensitive-action-audit-repository';
import {
  SqliteSiteRepository,
  type SiteRepository,
} from '@/src/lib/database/repositories/site-repository';
import {
  SqliteSymptomLogRepository,
  type SymptomLogRepository,
} from '@/src/lib/database/repositories/symptom-log-repository';
import {
  SqliteVialRepository,
  type VialRepository,
} from '@/src/lib/database/repositories/vial-repository';
import {
  SqliteWeightLogRepository,
  type WeightLogRepository,
} from '@/src/lib/database/repositories/weight-log-repository';

export type AtlasRepositories = {
  calculatorProfiles: CalculatorProfileRepository;
  compounds: CompoundRepository;
  customMetrics: CustomMetricRepository;
  healthConnections: HealthConnectionRepository;
  logEvents: LogEventRepository;
  metricValueLogs: MetricValueLogRepository;
  privacyProfiles: PrivacyProfileRepository;
  protocolChangeAudits: ProtocolChangeAuditRepository;
  protocolAliases: ProtocolAliasRepository;
  reminderPreferences: ReminderPreferenceRepository;
  protocolRevisionRules: ProtocolRevisionRuleRepository;
  protocolRevisions: ProtocolRevisionRepository;
  protocolRules: ProtocolRuleRepository;
  protocols: ProtocolRepository;
  reminders: ReminderRepository;
  sensitiveActionAudits: SensitiveActionAuditRepository;
  sites: SiteRepository;
  symptomLogs: SymptomLogRepository;
  vials: VialRepository;
  weightLogs: WeightLogRepository;
};

export function createAtlasRepositories(client: DatabaseClient): AtlasRepositories {
  return {
    calculatorProfiles: new SqliteCalculatorProfileRepository(client),
    compounds: new SqliteCompoundRepository(client),
    customMetrics: new SqliteCustomMetricRepository(client),
    healthConnections: new SqliteHealthConnectionRepository(client),
    logEvents: new SqliteLogEventRepository(client),
    metricValueLogs: new SqliteMetricValueLogRepository(client),
    privacyProfiles: new SqlitePrivacyProfileRepository(client),
    protocolChangeAudits: new SqliteProtocolChangeAuditRepository(client),
    protocolAliases: new SqliteProtocolAliasRepository(client),
    reminderPreferences: new SqliteReminderPreferenceRepository(client),
    protocolRevisionRules: new SqliteProtocolRevisionRuleRepository(client),
    protocolRevisions: new SqliteProtocolRevisionRepository(client),
    protocolRules: new SqliteProtocolRuleRepository(client),
    protocols: new SqliteProtocolRepository(client),
    reminders: new SqliteReminderRepository(client),
    sensitiveActionAudits: new SqliteSensitiveActionAuditRepository(client),
    sites: new SqliteSiteRepository(client),
    symptomLogs: new SqliteSymptomLogRepository(client),
    vials: new SqliteVialRepository(client),
    weightLogs: new SqliteWeightLogRepository(client),
  };
}

export * from '@/src/lib/database/repositories/calculator-profile-repository';
export * from '@/src/lib/database/repositories/compound-repository';
export * from '@/src/lib/database/repositories/custom-metric-repository';
export * from '@/src/lib/database/repositories/health-connection-repository';
export * from '@/src/lib/database/repositories/log-event-repository';
export * from '@/src/lib/database/repositories/metric-value-log-repository';
export * from '@/src/lib/database/repositories/privacy-profile-repository';
export * from '@/src/lib/database/repositories/protocol-change-audit-repository';
export * from '@/src/lib/database/repositories/protocol-alias-repository';
export * from '@/src/lib/database/repositories/protocol-repository';
export * from '@/src/lib/database/repositories/protocol-revision-repository';
export * from '@/src/lib/database/repositories/protocol-revision-rule-repository';
export * from '@/src/lib/database/repositories/protocol-rule-repository';
export * from '@/src/lib/database/repositories/reminder-preference-repository';
export * from '@/src/lib/database/repositories/reminder-repository';
export * from '@/src/lib/database/repositories/sensitive-action-audit-repository';
export * from '@/src/lib/database/repositories/site-repository';
export * from '@/src/lib/database/repositories/symptom-log-repository';
export * from '@/src/lib/database/repositories/vial-repository';
export * from '@/src/lib/database/repositories/weight-log-repository';

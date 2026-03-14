import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { runMigrations } from '@/src/lib/database/migrations';
import { createAtlasRepositories } from '@/src/lib/database/repositories';

describe('sqlite repositories', () => {
  it('supports core CRUD and query flows across the local-first entities', async () => {
    const client = await createSqlJsDatabaseClient();
    await runMigrations(client);

    const repositories = createAtlasRepositories(client);

    const compound = await repositories.compounds.create({
      slug: 'test-compound',
      displayName: 'Test Compound',
      compoundType: 'glp',
      isUserDefined: true,
      notes: 'Created in repository basics test.',
    });

    const protocol = await repositories.protocols.create({
      compoundId: compound.id,
      doseAmount: 0.25,
      doseUnit: 'mg',
      name: 'Weekly GLP',
      kind: 'glp',
      linkedVialId: null,
      status: 'active',
      siteRotationEnabled: false,
      siteTrackingEnabled: false,
      timezone: 'America/New_York',
      startDate: '2026-03-12',
      defaultTimeOfDay: '08:00',
      notes: 'Repository flow protocol.',
    });

    const rule = await repositories.protocolRules.create({
      protocolId: protocol.id,
      ruleType: 'weekly',
      intervalCount: 1,
      weekday: 1,
      timeOfDay: '08:00',
      anchorDate: '2026-03-12',
      isActive: true,
    });
    const revision = await repositories.protocolRevisions.create({
      protocolId: protocol.id,
      revisionNumber: 1,
      previousRevisionId: null,
      effectiveFrom: '2026-03-12T00:00:00.000Z',
      effectiveTo: null,
      lifecycleState: 'active',
      timezone: 'America/New_York',
      timezoneStrategy: 'keep_local_clock',
      defaultTimeOfDay: '08:00',
      doseAmount: 0.25,
      doseUnit: 'mg',
      linkedVialId: null,
      missedDosePolicy: 'skip_and_continue',
      notes: 'Initial revision',
    });
    const revisionRule = await repositories.protocolRevisionRules.create({
      revisionId: revision.id,
      phaseType: 'base',
      phaseOrder: 0,
      ruleType: 'weekly',
      intervalCount: 1,
      weekday: 1,
      timeOfDay: '08:00',
      anchorDate: '2026-03-12',
      phaseStartDayOffset: 0,
      phaseLengthDays: null,
      doseAmountOverride: null,
      doseUnitOverride: null,
    });

    const vial = await repositories.vials.create({
      protocolId: protocol.id,
      compoundId: compound.id,
      label: 'Starter pen',
      startingQuantity: 4,
      remainingQuantity: 4,
      quantityUnit: 'dose',
      concentrationValue: 0.25,
      concentrationUnit: 'mg',
      volumeMl: 2,
      openedAt: null,
      expiresAt: null,
    });

    const site = await repositories.sites.create({
      name: 'Abdomen',
      bodyArea: 'abdomen',
      notes: 'Primary site.',
    });

    const reminder = await repositories.reminders.create({
      body: 'Private routine due soon.',
      protocolId: protocol.id,
      occurrenceId: 'occ_test_001',
      offsetMinutes: -60,
      channel: 'local_notification',
      discreetCopyEnabled: true,
      isEnabled: true,
      notificationId: 'notification_test_001',
      privacyMode: 'generic',
      scheduledFor: '2026-03-12T11:00:00.000Z',
      status: 'scheduled',
      title: 'Atlas reminder',
    });

    const reminderPreference = await repositories.reminderPreferences.get();

    const metric = await repositories.customMetrics.create({
      protocolId: protocol.id,
      metricKey: 'energy',
      label: 'Energy',
      valueType: 'number',
      unit: 'score',
    });
    const metricValue = await repositories.metricValueLogs.create({
      loggedAt: '2026-03-13T08:00:00.000Z',
      metricId: metric.id,
      numberValue: 7,
      protocolId: protocol.id,
      source: 'manual',
    });
    const privacyProfile = await repositories.privacyProfiles.get();
    const alias = await repositories.protocolAliases.upsert({
      aliasCompoundLabel: 'Blue vial',
      aliasLabel: 'Evening plan',
      protocolId: protocol.id,
    });
    const sensitiveAudit = await repositories.sensitiveActionAudits.create({
      eventType: 'selective_share_created',
      manifestVersion: 1,
      payloadJson: '{"counts":{"summary":1}}',
      protocolId: protocol.id,
      renderMode: 'alias',
      scopeKind: 'summary_only',
      surface: 'selective_share',
    });
    const calculatorProfile = await repositories.calculatorProfiles.create({
      diluentUnit: 'mL',
      diluentVolume: 2,
      drawUnit: 'mL',
      drawVolume: 0.25,
      label: '2 mg baseline',
      powderAmount: 2,
      powderUnit: 'mg',
    });
    const weightLog = await repositories.weightLogs.create({
      loggedAt: '2026-03-13T09:00:00.000Z',
      notes: 'Morning entry',
      source: 'manual',
      unit: 'lb',
      value: 180.4,
    });
    const symptomLog = await repositories.symptomLogs.create({
      loggedAt: '2026-03-13T09:30:00.000Z',
      notes: 'Low-level nausea',
      severity: 2,
      source: 'manual',
      symptomKey: 'nausea',
    });
    const updatedHealthConnection = await repositories.healthConnections.update({
      enabled: true,
      lastError: 'Scaffold only',
      providerKey: 'health_connect',
    });

    const logEvent = await repositories.logEvents.create({
      protocolId: protocol.id,
      vialId: vial.id,
      siteId: site.id,
      occurrenceId: 'occ_test_001',
      eventType: 'completed',
      effectiveAt: '2026-03-12T12:00:00.000Z',
      quantity: 1,
      quantityUnit: 'dose',
      notes: 'Immutable event.',
      source: 'user',
    });
    const audit = await repositories.protocolChangeAudits.create({
      protocolId: protocol.id,
      revisionId: revision.id,
      previousRevisionId: null,
      changeType: 'future_dose_changed',
      effectiveFrom: '2026-03-20T00:00:00.000Z',
      summary: 'Future saved amount changes.',
      payloadJson: '{"doseAmount":0.5}',
    });

    expect(await repositories.compounds.listByType('glp')).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: compound.id })])
    );
    expect(await repositories.protocols.listActive()).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: protocol.id })])
    );
    expect(await repositories.protocolRules.listByProtocolId(protocol.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: rule.id })])
    );
    expect(await repositories.protocolRevisions.listByProtocolId(protocol.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: revision.id })])
    );
    expect(await repositories.protocolRevisionRules.listByRevisionId(revision.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: revisionRule.id })])
    );
    expect(await repositories.protocolChangeAudits.listByProtocolId(protocol.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: audit.id })])
    );
    expect(await repositories.vials.listByProtocolId(protocol.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: vial.id })])
    );
    expect(await repositories.sites.listAvailable()).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: site.id })])
    );
    expect(await repositories.reminders.listEnabled()).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: reminder.id })])
    );
    expect(reminderPreference.privacyMode).toBe('full_detail');
    expect(await repositories.customMetrics.listByProtocolId(protocol.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: metric.id })])
    );
    expect(await repositories.metricValueLogs.listByMetricId(metric.id)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: metricValue.id })])
    );
    expect(privacyProfile.aliasModeEnabled).toBe(false);
    expect(await repositories.protocolAliases.getByProtocolId(protocol.id)).toEqual(
      expect.objectContaining({ id: alias.id })
    );
    expect(await repositories.sensitiveActionAudits.listAll()).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: sensitiveAudit.id })])
    );
    expect(await repositories.calculatorProfiles.listAll()).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: calculatorProfile.id })])
    );
    expect(await repositories.weightLogs.listRecent(5)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: weightLog.id })])
    );
    expect(await repositories.symptomLogs.listRecent(5)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: symptomLog.id })])
    );
    expect(updatedHealthConnection?.enabled).toBe(true);
    expect(await repositories.logEvents.listRecent(5)).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: logEvent.id })])
    );

    const updatedCompound = await repositories.compounds.update({
      id: compound.id,
      displayName: 'Updated Compound',
    });
    const updatedProtocol = await repositories.protocols.updateStatus(protocol.id, 'paused');
    const updatedRule = await repositories.protocolRules.update({
      id: rule.id,
      intervalCount: 2,
    });
    const updatedRevision = await repositories.protocolRevisions.update({
      id: revision.id,
      doseAmount: 0.5,
    });
    const updatedRevisionRule = await repositories.protocolRevisionRules.update({
      id: revisionRule.id,
      phaseLengthDays: 14,
    });
    const updatedVial = await repositories.vials.update({
      id: vial.id,
      remainingQuantity: 3,
    });
    const updatedReminder = await repositories.reminders.update({
      body: 'Reminder moved closer.',
      id: reminder.id,
      privacyMode: 'silent',
      offsetMinutes: -30,
    });
    const updatedReminderPreference = await repositories.reminderPreferences.update({
      id: 'default',
      leadTimeMinutes: 15,
      privacyMode: 'generic',
    });
    const updatedMetric = await repositories.customMetrics.update({
      id: metric.id,
      label: 'Daily energy',
    });
    const updatedPrivacyProfile = await repositories.privacyProfiles.update({
      aliasModeEnabled: true,
      exportAliasByDefault: true,
      id: 'default',
    });
    const updatedAlias = await repositories.protocolAliases.update({
      aliasLabel: 'Quiet plan',
      id: alias.id,
    });
    const updatedCalculatorProfile = await repositories.calculatorProfiles.update({
      id: calculatorProfile.id,
      drawVolume: 0.3,
    });
    const updatedSite = await repositories.sites.update({
      id: site.id,
      archivedAt: '2026-03-20T10:00:00.000Z',
    });

    expect(updatedCompound?.displayName).toBe('Updated Compound');
    expect(updatedProtocol?.status).toBe('paused');
    expect(updatedProtocol?.doseAmount).toBe(0.25);
    expect(updatedProtocol?.doseUnit).toBe('mg');
    expect(updatedRule?.intervalCount).toBe(2);
    expect(updatedRevision?.doseAmount).toBe(0.5);
    expect(updatedRevisionRule?.phaseLengthDays).toBe(14);
    expect(updatedVial?.remainingQuantity).toBe(3);
    expect(updatedReminder?.offsetMinutes).toBe(-30);
    expect(updatedReminder?.privacyMode).toBe('silent');
    expect(updatedReminderPreference.leadTimeMinutes).toBe(15);
    expect(updatedMetric?.label).toBe('Daily energy');
    expect(updatedPrivacyProfile.aliasModeEnabled).toBe(true);
    expect(updatedPrivacyProfile.exportAliasByDefault).toBe(true);
    expect(updatedAlias?.aliasLabel).toBe('Quiet plan');
    expect(updatedCalculatorProfile?.drawVolume).toBe(0.3);
    expect(updatedSite?.archivedAt).toBe('2026-03-20T10:00:00.000Z');

    expect(await repositories.calculatorProfiles.delete(calculatorProfile.id)).toBe(true);
    expect(await repositories.metricValueLogs.delete(metricValue.id)).toBe(true);
    expect(await repositories.customMetrics.delete(metric.id)).toBe(true);
    expect(await repositories.weightLogs.delete(weightLog.id)).toBe(true);
    expect(await repositories.symptomLogs.delete(symptomLog.id)).toBe(true);
    expect(await repositories.reminders.delete(reminder.id)).toBe(true);
    expect(await repositories.sites.delete(site.id)).toBe(true);
    expect(await repositories.protocolRevisionRules.deleteByRevisionId(revision.id)).toBeGreaterThanOrEqual(1);
    expect(await repositories.vials.delete(vial.id)).toBe(true);
    expect(await repositories.protocolRules.delete(rule.id)).toBe(true);
    expect(await repositories.protocols.delete(protocol.id)).toBe(true);
    expect(await repositories.compounds.delete(compound.id)).toBe(true);

    await client.close();
  });
});

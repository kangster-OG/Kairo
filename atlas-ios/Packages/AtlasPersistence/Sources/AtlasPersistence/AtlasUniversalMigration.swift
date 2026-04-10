import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

extension GRDBImportExportBridge {
    public func prepareUniversalImport(
        _ request: AtlasUniversalImportRequest
    ) async throws -> AtlasUniversalPreparedImport {
        switch request.importer {
        case .atlasJSON:
            guard let fileURL = request.fileURL else {
                throw AtlasImportError.invalidPayload
            }
            let prepared = try await prepareImport(at: fileURL)
            return AtlasUniversalPreparedImport(
                request: request,
                stagedSnapshot: prepared.stagedSnapshot,
                dryRun: AtlasUniversalImportDryRunSummary(
                    importer: .atlasJSON,
                    sourceSummary: "Atlas JSON from \(fileURL.lastPathComponent)",
                    datasetDiffs: prepared.dryRun.datasetDiffs,
                    recordsToCreate: prepared.dryRun.recordsToCreate,
                    recordsToUpdate: prepared.dryRun.recordsToUpdate,
                    lintFindings: prepared.dryRun.lintFindings,
                    warnings: prepared.dryRun.warnings,
                    conflicts: [],
                    unsupportedRows: prepared.dryRun.validation.unsupportedDatasets,
                    privacyNotes: prepared.dryRun.privacyNotes,
                    backfillNotes: prepared.dryRun.backfillNotes,
                    plainLanguageSummary: prepared.dryRun.plainLanguageSummary
                )
            )
        case .atlasCSV:
            let source = try loadImportSourceText(request)
            let staged = try stageAtlasCsvImport(csv: source, request: request)
            let dryRun = try await buildUniversalDryRun(
                importer: .atlasCSV,
                sourceSummary: "Atlas CSV reconstruction",
                staged: staged
            )
            return AtlasUniversalPreparedImport(request: request, stagedSnapshot: staged.snapshot, dryRun: dryRun)
        case .genericCSV:
            let source = try loadImportSourceText(request)
            let staged = try stageGenericCsvImport(csv: source, request: request)
            let dryRun = try await buildUniversalDryRun(
                importer: .genericCSV,
                sourceSummary: "Generic CSV mapping",
                staged: staged
            )
            return AtlasUniversalPreparedImport(request: request, stagedSnapshot: staged.snapshot, dryRun: dryRun)
        case .manualText:
            let source = try loadImportSourceText(request)
            let staged = try stageManualTextImport(text: source, request: request)
            let dryRun = try await buildUniversalDryRun(
                importer: .manualText,
                sourceSummary: "Manual text reconstruction",
                staged: staged
            )
            return AtlasUniversalPreparedImport(request: request, stagedSnapshot: staged.snapshot, dryRun: dryRun)
        }
    }

    public func commitUniversalImport(
        _ prepared: AtlasUniversalPreparedImport,
        mode: AtlasImportMode
    ) async throws -> AtlasImportCommitResult {
        try await commitSnapshot(
            prepared.stagedSnapshot,
            mode: mode,
            sourceSummary: prepared.request.importer.rawValue,
            now: Date()
        )
    }

    public func cancelUniversalImport(_ prepared: AtlasUniversalPreparedImport) async {
        _ = prepared
    }

    public func previewProviderHandoff(
        _ request: AtlasProviderHandoffRequest,
        now: Date
    ) async throws -> AtlasProviderHandoffPreview {
        let (canonical, summarySettings) = try await stack.canonical.read { db in
            (
                try sortExportSnapshot(canonicalSnapshot(from: db)),
                try readSummarySettings(db: db, featureFlags: featureFlags)
            )
        }
        let renderMode: AtlasPrivacyRenderMode = request.aliasModeEnabled ? .alias : .full
        let subset = sanitizeExportSnapshot(
            sortExportSnapshot(providerHandoffSnapshot(from: canonical, request: request, now: now)),
            renderMode: renderMode,
            privacyFormatter: privacyFormatter
        )
        return buildProviderHandoffPreview(
            snapshot: subset,
            request: request,
            now: now,
            summarySettings: summarySettings
        )
    }

    public func createProviderHandoff(
        _ request: AtlasProviderHandoffRequest,
        now: Date
    ) async throws -> AtlasProviderHandoffResult {
        let (canonical, summarySettings) = try await stack.canonical.read { db in
            (
                try sortExportSnapshot(canonicalSnapshot(from: db)),
                try readSummarySettings(db: db, featureFlags: featureFlags)
            )
        }
        let renderMode: AtlasPrivacyRenderMode = request.aliasModeEnabled ? .alias : .full
        let subset = sanitizeExportSnapshot(
            sortExportSnapshot(providerHandoffSnapshot(from: canonical, request: request, now: now)),
            renderMode: renderMode,
            privacyFormatter: privacyFormatter
        )
        let preview = buildProviderHandoffPreview(
            snapshot: subset,
            request: request,
            now: now,
            summarySettings: summarySettings
        )
        let directoryURL = try exportDirectoryURL()
            .appendingPathComponent("atlas-provider-handoff-\(sanitizedFileTimestamp(atlasTimestamp(from: now)))", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let summaryURL = directoryURL.appendingPathComponent("summary.md")
        let attachmentURL = directoryURL.appendingPathComponent("attachment.json")
        try buildProviderHandoffSummary(snapshot: subset, preview: preview).write(
            to: summaryURL,
            atomically: true,
            encoding: .utf8
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(
            AtlasProviderHandoffEnvelope(
                manifest: AtlasProviderHandoffManifest(
                    generatedAt: atlasTimestamp(from: now),
                    renderMode: renderMode,
                    scopeKind: request.scopeKind,
                    rowCount: preview.rowCount,
                    datasets: preview.datasets
                ),
                bundle: AtlasExportBundle(
                    manifest: AtlasExportManifest(
                        format: "atlas_provider_handoff",
                        version: 1,
                        generatedAt: atlasTimestamp(from: now),
                        source: "atlas-ios-native"
                    ),
                    snapshot: subset
                )
            )
        ).write(to: attachmentURL, options: [.atomic])

        try await stack.canonical.write { db in
            try writeSensitiveActionAudit(
                db: db,
                eventType: .providerHandoffCreated,
                surface: "provider_handoff",
                protocolId: request.protocolID,
                scopeKind: request.scopeKind.rawValue,
                renderMode: renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "scopeKind": request.scopeKind.rawValue,
                    "rowCount": "\(preview.rowCount)",
                    "aliasModeEnabled": request.aliasModeEnabled ? "true" : "false"
                ]),
                now: now
            )
        }

        return AtlasProviderHandoffResult(
            directoryURL: directoryURL,
            summaryURL: summaryURL,
            attachmentURL: attachmentURL,
            preview: preview,
            manifestVersion: 1
        )
    }

    func commitSnapshot(
        _ snapshot: AtlasExportSnapshot,
        mode: AtlasImportMode,
        sourceSummary: String,
        now: Date,
        auditEventType: AtlasSensitiveActionAuditEventType = .importCommitted,
        auditSurface: String = "import_center",
        destructiveActionKind: AtlasRestorePointActionKind = .replaceImport
    ) async throws -> AtlasImportCommitResult {
        let existingRowCount = try await stack.canonical.read { db in
            try countUserRows(in: db)
        }

        if existingRowCount > 0, mode != .replaceExisting {
            throw AtlasImportError.replaceImportRequired
        }

        let restorePoint = existingRowCount > 0
            ? try await createRestorePoint(
                actionKind: destructiveActionKind,
                sourceSummary: sourceSummary,
                now: now
            )
            : nil
        try await stack.canonical.writeWithoutTransaction { db in
            try db.inTransaction {
                if existingRowCount > 0 {
                    try clearCanonicalTables(in: db)
                }

                try writeSnapshot(snapshot, to: db)
                if let restorePoint {
                    try writeSensitiveActionAudit(
                        db: db,
                        eventType: .restorePointCreated,
                        surface: "restore_points",
                        protocolId: nil,
                        scopeKind: restorePoint.actionKind.rawValue,
                        renderMode: privacyFormatter.renderMode(for: snapshot.privacyProfile),
                        manifestVersion: 1,
                        payloadJson: trustVaultPayload([
                            "sourceSummary": restorePoint.sourceSummary,
                            "rowCount": "\(restorePoint.rowCount)",
                            "fileName": restorePoint.fileURL.lastPathComponent
                        ]),
                        now: now
                    )
                }
                try replaceOccurrenceProjections([], in: db)
                let importedContext = try loadCoreLoopContext(db: db)
                let schedulableProtocolIDs: [String] = importedContext.protocols.values.compactMap { protocolRecord -> String? in
                    let revisionSlices = importedContext.revisionSlices[protocolRecord.id] ?? []
                    let fallbackRules = importedContext.protocolRules[protocolRecord.id] ?? []
                    if protocolRecord.status == .archived {
                        return nil
                    }
                    if revisionSlices.contains(where: { $0.revision.lifecycleState == .active && $0.rules.isEmpty == false }) {
                        return protocolRecord.id
                    }
                    if revisionSlices.isEmpty, protocolRecord.status == .active, fallbackRules.isEmpty == false {
                        return protocolRecord.id
                    }
                    return nil
                }
                if schedulableProtocolIDs.isEmpty == false {
                    try regenerateFutureOccurrences(
                        db: db,
                        protocolIDs: schedulableProtocolIDs,
                        referenceDate: now,
                        preserveManualReschedules: false
                    )
                }
                try writeSensitiveActionAudit(
                    db: db,
                    eventType: auditEventType,
                    surface: auditSurface,
                    protocolId: nil,
                    scopeKind: sourceSummary,
                    renderMode: privacyFormatter.renderMode(for: snapshot.privacyProfile),
                    manifestVersion: 1,
                    payloadJson: trustVaultPayload([
                        "sourceSummary": sourceSummary,
                        "protocolCount": "\(snapshot.protocols.count)",
                        "logEventCount": "\(snapshot.logEvents.count)"
                    ]),
                    now: now
                )
                return .commit
            }
        }

        try await projectionWriter.refreshProjection(referenceDate: now)
        let projectionState = try await projectionWriter.loadProjectionDebugState()

        return AtlasImportCommitResult(
            backupURL: restorePoint?.fileURL,
            importedProtocolCount: snapshot.protocols.count,
            importedLogEventCount: snapshot.logEvents.count,
            nextDue: projectionState.nextDue
        )
    }
}

private struct AtlasUniversalImportStaging {
    var snapshot: AtlasExportSnapshot
    var lintFindings: [AtlasImportLintItem]
    var warnings: [String]
    var conflicts: [String]
    var unsupportedRows: [String]
    var privacyNotes: [String]
    var backfillNotes: [String]
}

private struct AtlasProviderHandoffManifest: Codable, Equatable {
    var format: String = "atlas_provider_handoff"
    var version: Int = 1
    var generatedAt: String
    var source: String = "atlas-ios-native"
    var renderMode: AtlasPrivacyRenderMode
    var scopeKind: AtlasProviderHandoffScopeKind
    var rowCount: Int
    var datasets: [AtlasProviderHandoffDatasetSummary]
    var staticSnapshot: Bool = true
}

private struct AtlasProviderHandoffEnvelope: Codable, Equatable {
    var manifest: AtlasProviderHandoffManifest
    var bundle: AtlasExportBundle
}

private extension GRDBImportExportBridge {
    func loadImportSourceText(_ request: AtlasUniversalImportRequest) throws -> String {
        if let rawText = request.rawText, rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return rawText
        }
        if let fileURL = request.fileURL {
            return try String(contentsOf: fileURL, encoding: .utf8)
        }
        throw AtlasImportError.invalidPayload
    }

    func buildUniversalDryRun(
        importer: AtlasImporterKind,
        sourceSummary: String,
        staged: AtlasUniversalImportStaging
    ) async throws -> AtlasUniversalImportDryRunSummary {
        let (datasetDiffs, lintFindings, plainLanguageSummary) = try await stack.canonical.read { db in
            let datasetDiffs = try AtlasImportDataset.allCases.map { dataset in
                let incomingIDs = datasetIdentifiers(from: staged.snapshot, for: dataset)
                let existingIDs = try existingIdentifiers(in: db, for: dataset)
                let updates = incomingIDs.filter(existingIDs.contains).count
                return AtlasDatasetDiff(dataset: dataset.rawValue, creates: incomingIDs.count - updates, updates: updates)
            }
            let existingProtocolNames: [String] = try String.fetchAll(db, sql: "SELECT name FROM protocols")
            let lintFindings = try Self.lintImportSnapshot(
                snapshot: staged.snapshot,
                datasetDiffs: datasetDiffs,
                existingProtocolNames: Set(existingProtocolNames.map { Self.normalizedProtocolName($0) }),
                supplemental: staged.lintFindings
            )
            let summarySettings = try readSummarySettings(db: db, featureFlags: featureFlags)
            let plainLanguageSummary = buildImportDiffSummaryRequest(
                sourceLabel: sourceSummary,
                datasetDiffs: datasetDiffs,
                recordsToCreate: datasetDiffs.reduce(0) { $0 + $1.creates },
                recordsToUpdate: datasetDiffs.reduce(0) { $0 + $1.updates },
                lintFindings: lintFindings,
                warnings: staged.warnings,
                privacyNotes: staged.privacyNotes,
                backfillNotes: staged.backfillNotes,
                referenceDate: Date()
            ).flatMap {
                AtlasSummaryService(
                    featureFlags: featureFlags,
                    settings: summarySettings
                ).generate($0)
            }
            return (datasetDiffs, lintFindings, plainLanguageSummary)
        }

        return AtlasUniversalImportDryRunSummary(
            importer: importer,
            sourceSummary: sourceSummary,
            datasetDiffs: datasetDiffs,
            recordsToCreate: datasetDiffs.reduce(0) { $0 + $1.creates },
            recordsToUpdate: datasetDiffs.reduce(0) { $0 + $1.updates },
            lintFindings: lintFindings,
            warnings: staged.warnings,
            conflicts: staged.conflicts,
            unsupportedRows: staged.unsupportedRows,
            privacyNotes: staged.privacyNotes,
            backfillNotes: staged.backfillNotes,
            plainLanguageSummary: plainLanguageSummary
        )
    }

    func stageAtlasCsvImport(
        csv: String,
        request: AtlasUniversalImportRequest
    ) throws -> AtlasUniversalImportStaging {
        let rows = try parseCsvRows(csv)
        let generatedAt = atlasTimestamp(from: Date())
        var snapshot = AtlasExportSnapshot(
            privacyProfile: .default(timestamp: generatedAt),
            reminderPreference: .default(timestamp: generatedAt)
        )
        var warnings = [
            "Atlas CSV is lossy. Missing schedule and dose fields are backfilled with deterministic defaults.",
            "Atlas JSON remains the canonical migration path."
        ]
        var conflicts: [String] = []
        var unsupportedRows: [String] = []

        for (index, row) in rows.enumerated() {
            let dataset = row["dataset"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let id = row["id"] ?? "row_\(index)"
            let primary = row["primary"] ?? ""
            let timestamp = row["timestamp"] ?? generatedAt
            let value = row["value"] ?? ""
            let secondary = row["secondary"] ?? ""
            let notes = row["notes"] ?? ""

            switch dataset {
            case "protocol":
                snapshot.protocols.append(
                    AtlasProtocolRecord.make(
                        id: id,
                        compoundId: nil,
                        linkedVialId: nil,
                        name: primary.isEmpty ? "Imported protocol \(index + 1)" : primary,
                        kind: parseProtocolKind(value: secondary) ?? .custom,
                        status: AtlasProtocolStatus(rawValue: value) ?? .active,
                        timezone: request.manualOptions.timezone,
                        startDate: csvStartDate(from: timestamp),
                        defaultTimeOfDay: csvTimeOfDay(from: timestamp),
                        doseAmount: nil,
                        doseUnit: nil,
                        siteTrackingEnabled: false,
                        siteRotationEnabled: false,
                        notes: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "protocol_rule":
                let ruleType = AtlasProtocolRuleType(rawValue: value) ?? .weekly
                if ruleType == .everyNDays {
                    warnings.append("Atlas CSV cannot recover exact every-N-day interval counts; imported rules default to every 1 day.")
                }
                snapshot.protocolRules.append(
                    AtlasProtocolRuleRecord.make(
                        id: id,
                        protocolId: primary,
                        ruleType: ruleType,
                        intervalCount: ruleType == .everyNDays ? 1 : 1,
                        weekday: csvWeekday(from: notes, ruleType: ruleType),
                        timeOfDay: secondary.nilIfBlank,
                        anchorDate: notes.nilIfBlank,
                        isActive: true,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "protocol_revision":
                snapshot.protocolRevisions.append(
                    AtlasProtocolRevisionRecord(
                        id: id,
                        protocolId: primary,
                        revisionNumber: snapshot.protocolRevisions.filter { $0.protocolId == primary }.count + 1,
                        previousRevisionId: nil,
                        effectiveFrom: timestamp,
                        effectiveTo: nil,
                        lifecycleState: AtlasProtocolRevisionLifecycle(rawValue: value) ?? .active,
                        timezone: request.manualOptions.timezone,
                        timezoneStrategy: AtlasProtocolTimezoneStrategy(rawValue: secondary) ?? .keepLocalClock,
                        defaultTimeOfDay: nil,
                        doseAmount: nil,
                        doseUnit: nil,
                        linkedVialId: nil,
                        missedDosePolicy: .skipAndContinue,
                        notes: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "protocol_revision_rule":
                snapshot.protocolRevisionRules.append(
                    AtlasProtocolRevisionRuleRecord(
                        id: id,
                        revisionId: primary,
                        phaseType: AtlasProtocolRevisionPhaseType(rawValue: secondary) ?? .base,
                        phaseOrder: snapshot.protocolRevisionRules.filter { $0.revisionId == primary }.count,
                        ruleType: AtlasProtocolRuleType(rawValue: value) ?? .weekly,
                        intervalCount: 1,
                        weekday: csvWeekday(
                            from: notes,
                            ruleType: AtlasProtocolRuleType(rawValue: value) ?? .weekly
                        ),
                        timeOfDay: nil,
                        anchorDate: notes.nilIfBlank,
                        phaseStartDayOffset: 0,
                        phaseLengthDays: nil,
                        doseAmountOverride: nil,
                        doseUnitOverride: nil,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "protocol_change_audit":
                snapshot.protocolChangeAudits.append(
                    AtlasProtocolChangeAuditRecord.make(
                        id: id,
                        protocolId: primary,
                        revisionId: primary,
                        previousRevisionId: nil,
                        changeType: AtlasProtocolChangeAuditType(rawValue: value) ?? .futureDoseChanged,
                        effectiveFrom: secondary.nilIfBlank ?? timestamp,
                        summary: notes.nilIfBlank ?? "Imported protocol change",
                        payloadJson: "{}",
                        createdAt: timestamp
                    )
                )
            case "log_event":
                snapshot.logEvents.append(
                    AtlasLogEventRecord.make(
                        id: id,
                        protocolId: primary,
                        vialId: nil,
                        siteId: nil,
                        occurrenceId: nil,
                        eventType: AtlasLogEventType(rawValue: value) ?? .manualLog,
                        effectiveAt: timestamp,
                        loggedAt: timestamp,
                        quantity: Double(secondary),
                        quantityUnit: nil,
                        notes: notes.nilIfBlank,
                        source: .migration
                    )
                )
            case "vial":
                snapshot.vials.append(
                    AtlasVialRecord.make(
                        id: id,
                        protocolId: nil,
                        compoundId: nil,
                        label: primary,
                        startingQuantity: Double(value) ?? 0,
                        concentrationValue: nil,
                        concentrationUnit: nil,
                        volumeMl: nil,
                        remainingQuantity: Double(value) ?? 0,
                        lowStockThreshold: Double(notes),
                        quantityUnit: secondary.isEmpty ? "units" : secondary,
                        openedAt: nil,
                        expiresAt: nil,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "weight_log":
                snapshot.weightLogs.append(
                    AtlasWeightLogRecord.make(
                        id: id,
                        loggedAt: timestamp,
                        value: Double(value) ?? 0,
                        unit: AtlasWeightUnit(rawValue: primary) ?? .lb,
                        source: AtlasHealthDataSource(rawValue: secondary) ?? .import,
                        notes: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "symptom_log":
                snapshot.symptomLogs.append(
                    AtlasSymptomLogRecord.make(
                        id: id,
                        loggedAt: timestamp,
                        symptomKey: primary,
                        severity: Int(value) ?? 0,
                        notes: notes.nilIfBlank,
                        source: AtlasHealthDataSource(rawValue: secondary) ?? .import,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "custom_metric":
                snapshot.customMetrics.append(
                    AtlasCustomMetricRecord.make(
                        id: id,
                        protocolId: nil,
                        metricKey: notes.isEmpty ? id : notes,
                        label: primary,
                        valueType: AtlasCustomMetricValueType(rawValue: value) ?? .number,
                        unit: secondary.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "metric_value_log":
                snapshot.metricValueLogs.append(
                    AtlasMetricValueLogRecord.make(
                        id: id,
                        metricId: primary,
                        protocolId: notes.nilIfBlank,
                        loggedAt: timestamp,
                        numberValue: Double(value),
                        textValue: Double(value) == nil && value.isEmpty == false && value != "true" && value != "false" ? value : nil,
                        booleanValue: Bool(csvBooleanString: value),
                        source: AtlasHealthDataSource(rawValue: secondary) ?? .import,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "health_connection":
                snapshot.healthConnections.append(
                    AtlasHealthConnectionRecord.make(
                        providerKey: AtlasHealthProviderKey(rawValue: id) ?? .appleHealth,
                        enabled: primary == "enabled",
                        connected: value == "connected",
                        lastSyncAt: secondary.nilIfBlank,
                        lastError: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "privacy_profile":
                snapshot.privacyProfile = AtlasPrivacyProfileRecord.make(
                    id: id,
                    renderMode: primary == "alias_on" ? .alias : .full,
                    aliasModeEnabled: primary == "alias_on",
                    biometricLockEnabled: value == "biometric_on",
                    biometricGateMode: AtlasBiometricGateMode(rawValue: secondary) ?? .bestEffort,
                    shareAliasByDefault: true,
                    exportAliasByDefault: notes == "true",
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
            case "protocol_alias":
                snapshot.protocolAliases.append(
                    AtlasProtocolAliasRecord.make(
                        id: id,
                        protocolId: primary,
                        aliasLabel: value.isEmpty ? "Alias protocol" : value,
                        aliasCompoundLabel: secondary.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp,
                        archivedAt: notes.nilIfBlank
                    )
                )
            case "sensitive_action_audit":
                snapshot.sensitiveActionAudits.append(
                    AtlasSensitiveActionAuditRecord.make(
                        id: id,
                        eventType: AtlasSensitiveActionAuditEventType(rawValue: primary) ?? .exportCreated,
                        surface: value,
                        protocolId: nil,
                        scopeKind: notes.nilIfBlank,
                        renderMode: AtlasPrivacyRenderMode(rawValue: secondary),
                        manifestVersion: 1,
                        payloadJson: "{}",
                        createdAt: timestamp
                    )
                )
            case "calculator_profile":
                snapshot.calculatorProfiles.append(
                    AtlasCalculatorProfileRecord.make(
                        id: id,
                        label: primary,
                        powderAmount: Double(value) ?? 0,
                        powderUnit: "mg",
                        diluentVolume: Double(secondary) ?? 0,
                        diluentUnit: "mL",
                        drawVolume: Double(notes) ?? 0,
                        drawUnit: "mL",
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "reminder":
                snapshot.reminders.append(
                    AtlasReminderRecord.make(
                        id: id,
                        protocolId: primary,
                        occurrenceId: "csv_occ_\(id)",
                        offsetMinutes: 0,
                        channel: .localNotification,
                        isEnabled: true,
                        discreetCopyEnabled: value != AtlasReminderPrivacyMode.fullDetail.rawValue,
                        privacyMode: AtlasReminderPrivacyMode(rawValue: secondary) ?? .generic,
                        scheduledFor: timestamp,
                        notificationId: notes.nilIfBlank,
                        title: "Atlas reminder",
                        body: "Imported Atlas CSV reminder.",
                        status: AtlasReminderStatus(rawValue: value) ?? .scheduled,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "reminder_preference":
                snapshot.reminderPreference = AtlasReminderPreferenceRecord.make(
                    id: id,
                    remindersEnabled: Bool(csvBooleanString: value) ?? true,
                    privacyMode: AtlasReminderPrivacyMode(rawValue: primary) ?? .generic,
                    leadTimeMinutes: Int(secondary) ?? 0,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
            case "site":
                snapshot.sites.append(
                    AtlasSiteRecord.make(
                        id: id,
                        name: primary,
                        bodyArea: value.nilIfBlank,
                        notes: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp,
                        archivedAt: secondary.nilIfBlank
                    )
                )
            case "compound":
                snapshot.compounds.append(
                    AtlasCompoundRecord.make(
                        id: id,
                        slug: id.lowercased(),
                        displayName: primary,
                        compoundType: value.isEmpty ? "custom" : value,
                        isUserDefined: Bool(csvBooleanString: secondary) ?? false,
                        notes: notes.nilIfBlank,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            case "":
                unsupportedRows.append("Row \(index + 2) is missing a dataset column.")
            default:
                unsupportedRows.append("Row \(index + 2) uses unsupported dataset '\(dataset)'.")
            }
        }

        let finalized = finalizeImportedSnapshot(
            snapshot,
            generatedAt: generatedAt,
            warnings: &warnings,
            conflicts: &conflicts,
            unsupportedRows: &unsupportedRows
        )
        return AtlasUniversalImportStaging(
            snapshot: finalized,
            lintFindings: [],
            warnings: warnings,
            conflicts: conflicts,
            unsupportedRows: unsupportedRows,
            privacyNotes: [
                "Imported privacy preferences will continue to render through Trust Vault policies.",
                "Atlas CSV aliases stay render-only and do not rewrite canonical names."
            ],
            backfillNotes: [
                "CSV reconstruction backfilled missing timezone, start-date, and revision details with deterministic defaults."
            ]
        )
    }

    func stageGenericCsvImport(
        csv: String,
        request: AtlasUniversalImportRequest
    ) throws -> AtlasUniversalImportStaging {
        guard let mapping = request.genericCsvMapping else {
            throw AtlasImportError.invalidPayload
        }
        let rows = try parseCsvRows(csv)
        let generatedAt = atlasTimestamp(from: Date())
        var snapshot = AtlasExportSnapshot(
            privacyProfile: .default(timestamp: generatedAt),
            reminderPreference: .default(timestamp: generatedAt)
        )
        var warnings: [String] = []
        var conflicts: [String] = []
        var unsupportedRows: [String] = []

        for (index, row) in rows.enumerated() {
            guard let name = row[mapping.nameColumn]?.nilIfBlank else {
                unsupportedRows.append("Row \(index + 2) is missing mapped protocol name.")
                continue
            }
            guard let cadenceText = row[mapping.cadenceColumn]?.nilIfBlank else {
                unsupportedRows.append("Row \(index + 2) is missing mapped cadence.")
                continue
            }

            let parsedCadence = parseCadence(text: cadenceText)
            guard let cadence = parsedCadence.ruleType else {
                unsupportedRows.append("Row \(index + 2) has unsupported cadence '\(cadenceText)'.")
                continue
            }

            let protocolID = "gcsv_protocol_\(index + 1)"
            let nowTimestamp = generatedAt
            let startDate = row[mapping.startDateColumn ?? ""]?.nilIfBlank ?? atlasLocalDateString(request.manualOptions.anchorDate)
            let kind = parseProtocolKind(value: row[mapping.kindColumn ?? ""] ?? "") ?? .custom
            let doseAmount = row[mapping.doseAmountColumn ?? ""]?.nilIfBlank.flatMap(Double.init)
            let doseUnit = row[mapping.doseUnitColumn ?? ""]?.nilIfBlank
            let timeOfDay = row[mapping.timeColumn ?? ""]?.nilIfBlank

            snapshot.protocols.append(
                AtlasProtocolRecord.make(
                    id: protocolID,
                    compoundId: nil,
                    linkedVialId: nil,
                    name: name,
                    kind: kind,
                    status: .active,
                    timezone: request.manualOptions.timezone,
                    startDate: startDate,
                    defaultTimeOfDay: timeOfDay,
                    doseAmount: doseAmount,
                    doseUnit: doseUnit,
                    siteTrackingEnabled: false,
                    siteRotationEnabled: false,
                    notes: row[mapping.notesColumn ?? ""]?.nilIfBlank,
                    createdAt: nowTimestamp,
                    updatedAt: nowTimestamp
                )
            )
            snapshot.protocolRules.append(
                AtlasProtocolRuleRecord.make(
                    id: "gcsv_rule_\(index + 1)",
                    protocolId: protocolID,
                    ruleType: cadence,
                    intervalCount: parsedCadence.intervalCount,
                    weekday: parsedCadence.weekday ?? weekdayNumber(from: row[mapping.weekdayColumn ?? ""] ?? ""),
                    timeOfDay: timeOfDay,
                    anchorDate: startDate,
                    isActive: true,
                    createdAt: nowTimestamp,
                    updatedAt: nowTimestamp
                )
            )
        }

        let finalized = finalizeImportedSnapshot(
            snapshot,
            generatedAt: generatedAt,
            warnings: &warnings,
            conflicts: &conflicts,
            unsupportedRows: &unsupportedRows
        )
        return AtlasUniversalImportStaging(
            snapshot: finalized,
            lintFindings: [],
            warnings: warnings,
            conflicts: conflicts,
            unsupportedRows: unsupportedRows,
            privacyNotes: ["Generic CSV imports create local-first Atlas protocols without requiring an account."],
            backfillNotes: ["Generic CSV rows backfill revision records from mapped protocol fields."]
        )
    }

    func stageManualTextImport(
        text: String,
        request: AtlasUniversalImportRequest
    ) throws -> AtlasUniversalImportStaging {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        let generatedAt = atlasTimestamp(from: Date())
        var snapshot = AtlasExportSnapshot(
            privacyProfile: .default(timestamp: generatedAt),
            reminderPreference: .default(timestamp: generatedAt)
        )
        var warnings = ["Manual text import is intentionally narrow and dry-run-first."]
        var conflicts: [String] = []
        var unsupportedRows: [String] = []

        for (index, line) in lines.enumerated() {
            let parts = splitManualParts(line)
            guard parts.count >= 3 else {
                unsupportedRows.append("Line \(index + 1) could not be parsed. Use 'Name | cadence | time | dose | kind'.")
                continue
            }
            let protocolID = "manual_protocol_\(index + 1)"
            let name = parts[0]
            let cadenceText = parts[1]
            let parsedCadence = parseCadence(text: cadenceText)
            guard let ruleType = parsedCadence.ruleType else {
                unsupportedRows.append("Line \(index + 1) has unsupported cadence '\(cadenceText)'.")
                continue
            }

            let timeOfDay = parts.first(where: { $0.contains(":") })
            let doseToken = parts.first(where: { $0.range(of: #"^\d+(\.\d+)?\s*[A-Za-z/]+"#, options: .regularExpression) != nil })
            let kind = parts.compactMap(parseProtocolKind).first ?? request.manualOptions.defaultKind
            let doseParts = doseToken?.split(separator: " ", maxSplits: 1).map(String.init)

            snapshot.protocols.append(
                AtlasProtocolRecord.make(
                    id: protocolID,
                    compoundId: nil,
                    linkedVialId: nil,
                    name: name,
                    kind: kind,
                    status: .active,
                    timezone: request.manualOptions.timezone,
                    startDate: atlasLocalDateString(request.manualOptions.anchorDate),
                    defaultTimeOfDay: timeOfDay,
                    doseAmount: doseParts?.first.flatMap(Double.init),
                    doseUnit: doseParts?.count == 2 ? doseParts?[1] : nil,
                    siteTrackingEnabled: false,
                    siteRotationEnabled: false,
                    notes: parts.count > 5 ? parts.dropFirst(5).joined(separator: " | ") : nil,
                    createdAt: generatedAt,
                    updatedAt: generatedAt
                )
            )
            snapshot.protocolRules.append(
                AtlasProtocolRuleRecord.make(
                    id: "manual_rule_\(index + 1)",
                    protocolId: protocolID,
                    ruleType: ruleType,
                    intervalCount: parsedCadence.intervalCount,
                    weekday: parsedCadence.weekday,
                    timeOfDay: timeOfDay,
                    anchorDate: atlasLocalDateString(request.manualOptions.anchorDate),
                    isActive: true,
                    createdAt: generatedAt,
                    updatedAt: generatedAt
                )
            )
        }

        let finalized = finalizeImportedSnapshot(
            snapshot,
            generatedAt: generatedAt,
            warnings: &warnings,
            conflicts: &conflicts,
            unsupportedRows: &unsupportedRows
        )
        return AtlasUniversalImportStaging(
            snapshot: finalized,
            lintFindings: [],
            warnings: warnings,
            conflicts: conflicts,
            unsupportedRows: unsupportedRows,
            privacyNotes: ["Manual text imports stay local-first and inspectable before commit."],
            backfillNotes: ["Manual text parsing backfills revision records, reminder preferences, and Trust Vault defaults."]
        )
    }

    func finalizeImportedSnapshot(
        _ snapshot: AtlasExportSnapshot,
        generatedAt: String,
        warnings: inout [String],
        conflicts: inout [String],
        unsupportedRows: inout [String]
    ) -> AtlasExportSnapshot {
        var finalized = snapshot

        if finalized.protocols.isEmpty {
            warnings.append("No protocol rows were reconstructed from this source.")
        }

        let protocolsById = Dictionary(uniqueKeysWithValues: finalized.protocols.map { ($0.id, $0) })

        if finalized.protocolRevisions.isEmpty {
            finalized.protocolRevisions = finalized.protocols.map { protocolRecord in
                AtlasProtocolRevisionRecord(
                    id: "rev_\(protocolRecord.id)_1",
                    protocolId: protocolRecord.id,
                    revisionNumber: 1,
                    previousRevisionId: nil,
                    effectiveFrom: atlasDayStartTimestamp(protocolRecord.startDate),
                    effectiveTo: nil,
                    lifecycleState: protocolRecord.status == .paused ? .paused : .active,
                    timezone: protocolRecord.timezone,
                    timezoneStrategy: .keepLocalClock,
                    defaultTimeOfDay: protocolRecord.defaultTimeOfDay,
                    doseAmount: protocolRecord.doseAmount,
                    doseUnit: protocolRecord.doseUnit,
                    linkedVialId: protocolRecord.linkedVialId,
                    missedDosePolicy: .skipAndContinue,
                    notes: protocolRecord.notes,
                    createdAt: protocolRecord.createdAt,
                    updatedAt: protocolRecord.updatedAt
                )
            }
        }

        let primaryRulesByProtocolID = Dictionary(
            uniqueKeysWithValues: finalized.protocolRules.map { ($0.protocolId, $0) }
        )
        finalized.protocolRevisions = finalized.protocolRevisions.map { revision in
            var value = revision
            if value.defaultTimeOfDay?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                value.defaultTimeOfDay = primaryRulesByProtocolID[revision.protocolId]?.timeOfDay
                    ?? protocolsById[revision.protocolId]?.defaultTimeOfDay
            }
            if value.doseAmount == nil {
                value.doseAmount = protocolsById[revision.protocolId]?.doseAmount
            }
            if value.doseUnit?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                value.doseUnit = protocolsById[revision.protocolId]?.doseUnit
            }
            return value
        }

        if finalized.protocolRevisionRules.isEmpty {
            let revisionLookup = Dictionary(uniqueKeysWithValues: finalized.protocolRevisions.map { ($0.protocolId, $0.id) })
            finalized.protocolRevisionRules = finalized.protocolRules.enumerated().compactMap { offset, rule in
                guard let revisionID = revisionLookup[rule.protocolId] else {
                    return nil
                }
                return AtlasProtocolRevisionRuleRecord(
                    id: "revrule_\(rule.id)",
                    revisionId: revisionID,
                    phaseType: .base,
                    phaseOrder: offset,
                    ruleType: rule.ruleType,
                    intervalCount: rule.intervalCount,
                    weekday: rule.weekday,
                    timeOfDay: rule.timeOfDay,
                    anchorDate: rule.anchorDate,
                    phaseStartDayOffset: 0,
                    phaseLengthDays: nil,
                    doseAmountOverride: nil,
                    doseUnitOverride: nil,
                    createdAt: rule.createdAt,
                    updatedAt: rule.updatedAt
                )
            }
        }

        let revisionsByID = Dictionary(uniqueKeysWithValues: finalized.protocolRevisions.map { ($0.id, $0) })
        finalized.protocolRevisionRules = finalized.protocolRevisionRules.map { rule in
            var value = rule
            let revision = revisionsByID[rule.revisionId]
            let protocolID = revision?.protocolId
            let fallbackRule = protocolID.flatMap { primaryRulesByProtocolID[$0] }
            if value.timeOfDay?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                value.timeOfDay = fallbackRule?.timeOfDay ?? revision?.defaultTimeOfDay
            }
            if value.anchorDate?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                value.anchorDate = fallbackRule?.anchorDate ?? protocolID.flatMap { protocolsById[$0]?.startDate }
            }
            if value.ruleType == .weekly, value.weekday == nil {
                value.weekday = fallbackRule?.weekday
                    ?? fallbackRule?.anchorDate.flatMap(weekdayNumber(fromAnchorDate:))
                    ?? value.anchorDate.flatMap(weekdayNumber(fromAnchorDate:))
            }
            return value
        }

        let validRevisionIDs = Set(finalized.protocolRevisions.map(\.id))
        let protocolRevisionLookup = Dictionary(
            uniqueKeysWithValues: finalized.protocolRevisions.map { ($0.protocolId, $0.id) }
        )
        finalized.protocolChangeAudits = finalized.protocolChangeAudits.map { audit in
            var value = audit
            if validRevisionIDs.contains(value.revisionId) == false {
                value.revisionId = protocolRevisionLookup[value.protocolId] ?? value.revisionId
            }
            if let previousRevisionId = value.previousRevisionId, validRevisionIDs.contains(previousRevisionId) == false {
                value.previousRevisionId = nil
            }
            return value
        }

        for event in finalized.logEvents where protocolsById[event.protocolId] == nil {
            conflicts.append("A log row references missing protocol \(event.protocolId) and will fail to commit.")
        }

        finalized.protocols = finalized.protocols.sorted { $0.id < $1.id }
        finalized.protocolRules = finalized.protocolRules.sorted { $0.id < $1.id }
        finalized.protocolRevisions = finalized.protocolRevisions.sorted { $0.id < $1.id }
        finalized.protocolRevisionRules = finalized.protocolRevisionRules.sorted { $0.id < $1.id }
        finalized.protocolAliases = finalized.protocolAliases.sorted { $0.id < $1.id }
        finalized.protocolChangeAudits = finalized.protocolChangeAudits.sorted { $0.id < $1.id }
        finalized.logEvents = finalized.logEvents.sorted { $0.id < $1.id }
        finalized.customMetrics = finalized.customMetrics.sorted { $0.id < $1.id }
        finalized.metricValueLogs = finalized.metricValueLogs.sorted { $0.id < $1.id }
        finalized.contextLogs = finalized.contextLogs.sorted { $0.id < $1.id }
        finalized.sensitiveActionAudits = finalized.sensitiveActionAudits.sorted { $0.id < $1.id }
        finalized.vials = finalized.vials.sorted { $0.id < $1.id }
        finalized.sites = finalized.sites.sorted { $0.id < $1.id }
        finalized.weightLogs = finalized.weightLogs.sorted { $0.id < $1.id }
        finalized.symptomLogs = finalized.symptomLogs.sorted { $0.id < $1.id }
        finalized.compounds = finalized.compounds.sorted { $0.id < $1.id }
        finalized.calculatorProfiles = finalized.calculatorProfiles.sorted { $0.id < $1.id }
        finalized.reminders = finalized.reminders.sorted { $0.id < $1.id }
        finalized.healthConnections = Dictionary(
            uniqueKeysWithValues: finalized.healthConnections.map { ($0.providerKey, $0) }
        )
        .values
        .sorted { $0.providerKey.rawValue < $1.providerKey.rawValue }
        return finalized
    }

    func parseCsvRows(_ csv: String) throws -> [[String: String]] {
        let lines = csv.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerLine = lines.first else {
            throw AtlasImportError.invalidPayload
        }
        let headers = parseCsvLine(headerLine)
        return lines.dropFirst().map { line in
            let cells = parseCsvLine(line)
            return Dictionary(uniqueKeysWithValues: zip(headers, cells + Array(repeating: "", count: max(0, headers.count - cells.count))))
        }
    }

    func parseCsvLine(_ line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if inQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if character == ",", inQuotes == false {
                values.append(current)
                current = ""
            } else {
                current.append(character)
            }
            index += 1
        }

        values.append(current)
        return values
    }

    func parseProtocolKind(value: String) -> AtlasProtocolKind? {
        AtlasProtocolKind(rawValue: value.lowercased())
    }

    func parseCadence(text: String) -> (ruleType: AtlasProtocolRuleType?, intervalCount: Int, weekday: Int?) {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.contains("daily") {
            return (.daily, 1, nil)
        }
        if lower.contains("weekly") {
            let weekday = weekdayNumber(from: lower)
            return (.weekly, 1, weekday)
        }
        if lower.contains("every"), let intValue = lower.split(separator: " ").compactMap({ Int($0) }).first {
            return (.everyNDays, max(1, intValue), nil)
        }
        if let weekday = weekdayNumber(from: lower) {
            return (.weekly, 1, weekday)
        }
        return (nil, 1, nil)
    }

    func weekdayNumber(from value: String) -> Int? {
        let lower = value.lowercased()
        let mapping = [
            "sunday": 0,
            "monday": 1,
            "tuesday": 2,
            "wednesday": 3,
            "thursday": 4,
            "friday": 5,
            "saturday": 6
        ]
        return mapping.first(where: { lower.contains($0.key) })?.value
    }

    func weekdayNumber(fromAnchorDate value: String) -> Int? {
        guard let date = atlasParseLocalDateTime(dateValue: value, timeOfDay: "00:00") else {
            return nil
        }
        return Calendar.current.component(.weekday, from: date) - 1
    }

    func csvWeekday(from value: String, ruleType: AtlasProtocolRuleType) -> Int? {
        guard ruleType == .weekly else {
            return nil
        }
        return weekdayNumber(from: value) ?? weekdayNumber(fromAnchorDate: value)
    }

    func csvStartDate(from timestamp: String) -> String {
        if timestamp.count >= 10 {
            return String(timestamp.prefix(10))
        }
        return atlasLocalDateString(Date())
    }

    func csvTimeOfDay(from timestamp: String) -> String? {
        guard let date = ISO8601DateFormatter.atlas.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    func createRestorePoint(
        actionKind: AtlasRestorePointActionKind,
        sourceSummary: String,
        now: Date
    ) async throws -> AtlasRestorePointSummary {
        let generatedAt = atlasTimestamp(from: now)
        let snapshot = try await stack.canonical.read { db in
            try canonicalSnapshot(from: db)
        }
        let bundle = AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: generatedAt,
                source: "atlas-ios-native"
            ),
            snapshot: snapshot
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(bundle)
        let directoryURL = stack.locations?.backupDirectoryURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let url = directoryURL.appendingPathComponent("atlas-native-backup-\(generatedAt.replacingOccurrences(of: ":", with: "-")).json")
        try data.write(to: url)
        let summary = AtlasRestorePointSummary(
            id: "restore_point_\(UUID().uuidString.lowercased())",
            title: restorePointTitle(actionKind: actionKind, sourceSummary: sourceSummary),
            actionKind: actionKind,
            sourceSummary: sourceSummary,
            fileURL: url,
            rowCount: snapshotRowCount(snapshot),
            createdAt: now
        )

        try await stack.canonical.write { db in
            try AtlasRestorePointDBRecord(summary: summary).insert(db)
        }

        return summary
    }

    func restorePointTitle(
        actionKind: AtlasRestorePointActionKind,
        sourceSummary: String
    ) -> String {
        switch actionKind {
        case .replaceImport:
            return "Before replace import: \(sourceSummary)"
        case .restoreCommit:
            return "Before restore: \(sourceSummary)"
        }
    }

    func buildProjectionStateFromSnapshot(
        snapshot: AtlasExportSnapshot,
        occurrenceProjections: [AtlasOccurrenceProjectionRecord]
    ) -> (
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) {
        let protocols = Dictionary(uniqueKeysWithValues: snapshot.protocols.map { ($0.id, $0) })
        let aliases = Dictionary(uniqueKeysWithValues: snapshot.protocolAliases.map { ($0.protocolId, $0) })
        let nextOccurrence = occurrenceProjections.sorted { $0.scheduledAt < $1.scheduledAt }.first
        let extensionMode: AtlasPrivacyRenderMode = snapshot.privacyProfile.aliasModeEnabled ? .alias : .discreet

        let nextDue = nextOccurrence.flatMap { projection -> AtlasSharedNextDueSnapshot? in
            guard let protocolRecord = protocols[projection.protocolId] else {
                return nil
            }
            return AtlasSharedNextDueSnapshot(
                occurrenceID: projection.id,
                protocolID: projection.protocolId,
                displayTitle: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: aliases[projection.protocolId]?.aliasLabel,
                    mode: extensionMode
                ),
                dueLabel: relativeDueLabel(for: atlasDate(from: projection.scheduledAt)),
                scheduledAt: projection.scheduledAt,
                state: .upcoming,
                statusSummary: relativeDueLabel(for: atlasDate(from: projection.scheduledAt))
            )
        }

        let renderMode = privacyFormatter.renderMode(for: snapshot.privacyProfile)
        let timeline = snapshot.logEvents
            .sorted { $0.loggedAt > $1.loggedAt }
            .prefix(10)
            .compactMap { event -> AtlasSharedTimelineSummary? in
                guard let protocolRecord = protocols[event.protocolId] else {
                    return nil
                }
                let alias = aliases[event.protocolId]?.aliasLabel
                return AtlasSharedTimelineSummary(
                    id: event.id,
                    protocolID: event.protocolId,
                    displayTitle: privacyFormatter.title(
                        canonical: protocolRecord.name,
                        alias: alias,
                        mode: extensionMode
                    ),
                    summary: privacyFormatter.timelineSummary(
                        eventType: event.eventType,
                        canonical: protocolRecord.name,
                        alias: alias,
                        mode: renderMode
                    ),
                    recordedAt: event.loggedAt
                )
            }

        let labels = snapshot.protocols.map { protocolRecord in
            AtlasSharedLabelProjection(
                id: protocolRecord.id,
                canonicalTitle: protocolRecord.name,
                aliasTitle: aliases[protocolRecord.id]?.aliasLabel,
                discreetTitle: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: aliases[protocolRecord.id]?.aliasLabel,
                    mode: .discreet
                )
            )
        }

        let quickActions = occurrenceProjections.prefix(3).compactMap { projection -> AtlasSharedQuickAction? in
            guard let protocolRecord = protocols[projection.protocolId] else {
                return nil
            }
            return AtlasSharedQuickAction(
                id: "quick_\(projection.id)",
                protocolID: projection.protocolId,
                occurrenceID: projection.id,
                title: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: aliases[projection.protocolId]?.aliasLabel,
                    mode: extensionMode
                ),
                dueLabel: relativeDueLabel(for: atlasDate(from: projection.scheduledAt)),
                state: .upcoming
            )
        }

        return (
            nextDue,
            timeline,
            labels,
            quickActions,
            AtlasSharedFeatureFlagProjection(flags: featureFlags)
        )
    }

    func providerHandoffSnapshot(
        from snapshot: AtlasExportSnapshot,
        request: AtlasProviderHandoffRequest,
        now: Date
    ) -> AtlasExportSnapshot {
        switch request.scopeKind {
        case .currentProtocolOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .currentProtocolOnly,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .selectedProtocols:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .customDateRange,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    protocolIDs: request.protocolIDs,
                    dateRange: request.dateRange,
                    include: [.summary, .logs]
                ),
                now: now
            )
        case .last30Days:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .last30DaysLogs,
                    renderMode: request.aliasModeEnabled ? .alias : .full
                ),
                now: now
            )
        case .symptomsOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .symptomsOnly,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    dateRange: request.dateRange
                ),
                now: now
            )
        case .inventoryOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .inventoryOnly,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .summaryOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .summaryOnly,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .customDateRange:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .customDateRange,
                    renderMode: request.aliasModeEnabled ? .alias : .full,
                    protocolIDs: request.protocolIDs,
                    dateRange: request.dateRange,
                    include: [.summary, .logs, .symptoms, .inventory]
                ),
                now: now
            )
        }
    }

    func buildProviderHandoffPreview(
        snapshot: AtlasExportSnapshot,
        request: AtlasProviderHandoffRequest,
        now: Date,
        summarySettings: AtlasSummarySettingsSnapshot
    ) -> AtlasProviderHandoffPreview {
        let datasets = selectiveShareDatasetSummaries(snapshot: snapshot).map {
            AtlasProviderHandoffDatasetSummary(dataset: $0.dataset, rowCount: $0.rowCount)
        }
        let protocolTitles = snapshot.protocols.prefix(3).map(\.name)
        let renderMode: AtlasPrivacyRenderMode = request.aliasModeEnabled ? .alias : .full
        let episodeInsights = buildEpisodeInsightsSnapshot(snapshot: snapshot, now: now)
        var sections = [
            AtlasProviderHandoffPreviewSection(
                title: "Scope",
                lines: [
                    providerHandoffScopeSummary(request.scopeKind),
                    "Alias mode: \(request.aliasModeEnabled ? "On" : "Off")",
                    "Static snapshot only"
                ]
            ),
            AtlasProviderHandoffPreviewSection(
                title: "Included content",
                lines: datasets.map { "\($0.dataset): \($0.rowCount)" }
            ),
            AtlasProviderHandoffPreviewSection(
                title: "Preview",
                lines: protocolTitles.isEmpty ? ["No protocol titles included in this handoff."] : protocolTitles
            )
        ]
        if episodeInsights.hasAnyEpisodeData {
            sections.append(
                AtlasProviderHandoffPreviewSection(
                    title: "Episode summary",
                    lines: episodePreviewLines(from: episodeInsights)
                )
            )
        }
        let plainLanguageSummary = buildProviderHandoffSummaryRequest(
            scopeSummary: providerHandoffScopeSummary(request.scopeKind),
            renderMode: renderMode,
            rowCount: snapshotRowCount(snapshot),
            datasets: datasets,
            episodeInsights: episodeInsights,
            referenceDate: now
        ).flatMap {
            AtlasSummaryService(
                featureFlags: featureFlags,
                settings: summarySettings
            ).generate($0)
        }
        return AtlasProviderHandoffPreview(
            scopeKind: request.scopeKind,
            renderMode: renderMode,
            summary: "Previewing \(providerHandoffScopeSummary(request.scopeKind).lowercased()) as a static snapshot with \(snapshotRowCount(snapshot)) row(s).",
            plainLanguageSummary: plainLanguageSummary,
            datasets: datasets,
            sections: sections,
            rowCount: snapshotRowCount(snapshot)
        )
    }

    func buildProviderHandoffSummary(
        snapshot: AtlasExportSnapshot,
        preview: AtlasProviderHandoffPreview
    ) -> String {
        let protocolTitles = snapshot.protocols.prefix(10).map(\.name)
        let datasetLines = preview.datasets.map { "- \($0.dataset): \($0.rowCount)" }.joined(separator: "\n")
        let titleLines = protocolTitles.isEmpty ? "- No named protocols in this scope" : protocolTitles.map { "- \($0)" }.joined(separator: "\n")
        let episodeInsights = buildEpisodeInsightsSnapshot(snapshot: snapshot, now: Date())
        var sections: [String] = [
            "# Atlas Provider Handoff",
            "This package is a static snapshot generated locally from Atlas. It is descriptive only and does not include diagnosis, treatment recommendations, or dosing advice.",
            """
            Scope: \(providerHandoffScopeSummary(preview.scopeKind))
            Render mode: \(preview.renderMode.rawValue.capitalized)
            Rows included: \(preview.rowCount)
            """,
            """
            ## Included datasets
            \(datasetLines)
            """,
            """
            ## Protocol summary
            \(titleLines)
            """
        ]
        if episodeInsights.hasAnyEpisodeData {
            sections.append(
                """
                ## Episode summary
                \(episodePreviewLines(from: episodeInsights).map { "- \($0)" }.joined(separator: "\n"))
                """
            )
        }
        if let summary = preview.plainLanguageSummary {
            let sourceSections = summary.sourceSections.map { section in
                """
                ### \(section.title)
                \(section.facts.map { "- \($0.label): \($0.value)" }.joined(separator: "\n"))
                """
            }.joined(separator: "\n\n")
            sections.append(
                """
                ## Plain-language recap
                \(summary.summary)

                \(summary.disclaimer)

                \(sourceSections)
                """
            )
        }
        sections.append(
            """
            ## Snapshot note
            This handoff reflects a point-in-time local export from Atlas and should be interpreted as a bounded historical snapshot.
            """
        )
        return sections.joined(separator: "\n\n")
    }

    func providerHandoffScopeSummary(_ scope: AtlasProviderHandoffScopeKind) -> String {
        switch scope {
        case .currentProtocolOnly:
            return "Current protocol only"
        case .selectedProtocols:
            return "Selected protocols"
        case .last30Days:
            return "Last 30 days"
        case .symptomsOnly:
            return "Symptoms only"
        case .inventoryOnly:
            return "Inventory only"
        case .summaryOnly:
            return "Summary only"
        case .customDateRange:
            return "Custom date range"
        }
    }

    func splitManualParts(_ line: String) -> [String] {
        let separator = line.contains("|") ? "|" : ","
        return line.split(separator: Character(separator)).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Bool {
    init?(csvBooleanString value: String) {
        switch value.lowercased() {
        case "true", "enabled", "connected", "yes":
            self = true
        case "false", "disabled", "not_connected", "no":
            self = false
        default:
            return nil
        }
    }
}

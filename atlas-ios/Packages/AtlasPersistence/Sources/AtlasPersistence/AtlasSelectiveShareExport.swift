import AtlasDomain
import AtlasPrivacy
import CryptoKit
import GRDB
import Foundation

extension GRDBImportExportBridge {
    public func createRawExport(
        _ request: AtlasRawExportRequest,
        now: Date
    ) async throws -> AtlasRawExportResult {
        let snapshot = try await stack.canonical.read { db in
            try sortExportSnapshot(canonicalSnapshot(from: db))
        }
        let sanitized = sanitizeExportSnapshot(snapshot, renderMode: request.renderMode, privacyFormatter: privacyFormatter)
        let generatedAt = atlasTimestamp(from: now)
        let directoryURL = try exportDirectoryURL()
        let fileName = "atlas-export-\(sanitizedFileTimestamp(generatedAt)).\(request.format.rawValue)"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let rowCount = snapshotRowCount(sanitized)

        switch request.format {
        case .json:
            let bundle = AtlasExportBundle(
                manifest: AtlasExportManifest(generatedAt: generatedAt, source: "atlas-ios-native"),
                snapshot: sanitized
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(bundle)
            try data.write(to: fileURL, options: [.atomic])
        case .csv:
            let csv = buildAtlasCsvContents(snapshot: sanitized)
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        try await stack.canonical.write { db in
            try writeSensitiveActionAudit(
                db: db,
                eventType: .exportCreated,
                surface: "trust_vault",
                protocolId: nil,
                scopeKind: request.format.rawValue,
                renderMode: request.renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "format": request.format.rawValue,
                    "renderMode": request.renderMode.rawValue,
                    "rowCount": "\(rowCount)"
                ]),
                now: now
            )
        }

        return AtlasRawExportResult(
            format: request.format,
            renderMode: request.renderMode,
            fileURL: fileURL,
            rowCount: rowCount,
            manifestVersion: 1
        )
    }

    public func previewSelectiveShare(
        _ request: AtlasSelectiveShareRequest,
        now: Date
    ) async throws -> AtlasSelectiveSharePreview {
        let canonical = try await stack.canonical.read { db in
            try sortExportSnapshot(canonicalSnapshot(from: db))
        }
        let subset = selectiveShareSnapshot(from: canonical, request: request, now: now)
        return buildSelectiveSharePreview(
            snapshot: subset,
            request: request,
            privacyFormatter: privacyFormatter,
            now: now
        )
    }

    public func createSelectiveShare(
        _ request: AtlasSelectiveShareRequest,
        now: Date
    ) async throws -> AtlasSelectiveShareResult {
        let canonical = try await stack.canonical.read { db in
            try sortExportSnapshot(canonicalSnapshot(from: db))
        }
        let subset = selectiveShareSnapshot(from: canonical, request: request, now: now)
        let preview = buildSelectiveSharePreview(
            snapshot: subset,
            request: request,
            privacyFormatter: privacyFormatter,
            now: now
        )
        let directoryURL = try exportDirectoryURL()
        let generatedAt = atlasTimestamp(from: now)
        let fileURL = directoryURL.appendingPathComponent(
            "atlas-share-\(sanitizedFileTimestamp(generatedAt)).atlas-share.json"
        )
        let shareCode = makeShareCode()
        let key = symmetricKey(for: shareCode)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payloadData = try encoder.encode(AtlasExportBundle(
            manifest: AtlasExportManifest(generatedAt: generatedAt, source: "atlas-ios-native"),
            snapshot: subset
        ))
        let sealedBox = try AES.GCM.seal(payloadData, using: key)
        let envelope = AtlasSelectiveShareEnvelope(
            manifest: AtlasSelectiveShareManifest(
                generatedAt: generatedAt,
                scopeKind: request.scopeKind,
                renderMode: request.renderMode,
                rowCount: preview.rowCount,
                datasets: preview.datasets
            ),
            encryptedPayload: AtlasEncryptedPayload(
                algorithm: "AES.GCM",
                nonce: Data(sealedBox.nonce.withUnsafeBytes { Data($0) }).base64EncodedString(),
                ciphertext: sealedBox.ciphertext.base64EncodedString(),
                tag: sealedBox.tag.base64EncodedString()
            )
        )
        let envelopeData = try encoder.encode(envelope)
        try envelopeData.write(to: fileURL, options: [.atomic])

        try await stack.canonical.write { db in
            try writeSensitiveActionAudit(
                db: db,
                eventType: .selectiveShareCreated,
                surface: "trust_vault",
                protocolId: request.protocolID,
                scopeKind: request.scopeKind.rawValue,
                renderMode: request.renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "scopeKind": request.scopeKind.rawValue,
                    "renderMode": request.renderMode.rawValue,
                    "rowCount": "\(preview.rowCount)"
                ]),
                now: now
            )
        }

        return AtlasSelectiveShareResult(
            fileURL: fileURL,
            shareCode: shareCode,
            preview: preview,
            snapshot: subset,
            manifestVersion: 1
        )
    }
}

private struct AtlasSelectiveShareManifest: Codable, Equatable {
    var format: String = "atlas_selective_share"
    var version: Int = 1
    var generatedAt: String
    var source: String = "atlas-ios-native"
    var scopeKind: AtlasSelectiveShareScopeKind
    var renderMode: AtlasPrivacyRenderMode
    var rowCount: Int
    var datasets: [AtlasSelectiveShareDatasetSummary]
    var staticSnapshot: Bool = true
}

private struct AtlasEncryptedPayload: Codable, Equatable {
    var algorithm: String
    var nonce: String
    var ciphertext: String
    var tag: String
}

private struct AtlasSelectiveShareEnvelope: Codable, Equatable {
    var manifest: AtlasSelectiveShareManifest
    var encryptedPayload: AtlasEncryptedPayload
}

func sanitizeExportSnapshot(
    _ snapshot: AtlasExportSnapshot,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> AtlasExportSnapshot {
    guard renderMode != .full else {
        return snapshot
    }

    let aliasLookup = Dictionary(uniqueKeysWithValues: snapshot.protocolAliases.map { ($0.protocolId, $0) })
    let protocolLookup = Dictionary(uniqueKeysWithValues: snapshot.protocols.map { ($0.id, $0) })
    let protocolByCompoundID = snapshot.protocols.reduce(into: [String: AtlasProtocolRecord]()) { partialResult, record in
        guard let compoundID = record.compoundId, partialResult[compoundID] == nil else {
            return
        }
        partialResult[compoundID] = record
    }
    var sanitized = snapshot
    sanitized.privacyProfile.renderMode = renderMode
    sanitized.privacyProfile.aliasModeEnabled = renderMode == .alias
    sanitized.compounds = snapshot.compounds.map { compound in
        let relatedProtocol = protocolByCompoundID[compound.id]
        let alias = relatedProtocol.flatMap { aliasLookup[$0.id] }
        var record = compound
        if let title = privacyFormatter.compoundTitle(
            canonical: compound.displayName,
            aliasCompound: alias?.aliasCompoundLabel,
            mode: renderMode
        ) {
            record.displayName = title
        }
        return record
    }
    sanitized.protocols = snapshot.protocols.map { record in
        var value = record
        value.name = privacyFormatter.exportProtocolTitle(
            canonical: record.name,
            alias: aliasLookup[record.id]?.aliasLabel,
            mode: renderMode
        )
        return value
    }
    sanitized.protocolChangeAudits = snapshot.protocolChangeAudits.map { audit in
        guard let protocolRecord = protocolLookup[audit.protocolId] else {
            return audit
        }
        var value = audit
        value.summary = privacyFormatter.protocolChangeAuditSummary(
            canonical: protocolRecord.name,
            alias: aliasLookup[audit.protocolId]?.aliasLabel,
            auditSummary: audit.summary,
            mode: renderMode
        )
        return value
    }
    sanitized.reminders = snapshot.reminders.map { reminder in
        guard let protocolRecord = protocolLookup[reminder.protocolId] else {
            return reminder
        }
        let preview = privacyFormatter.reminderPreview(
            occurrence: AtlasScheduledOccurrence(
                id: reminder.occurrenceId,
                protocolID: reminder.protocolId,
                canonicalTitle: protocolRecord.name,
                aliasTitle: aliasLookup[reminder.protocolId]?.aliasLabel,
                kindLabel: kindLabel(protocolRecord.kind),
                cadenceLabel: "Scheduled routine",
                doseLabel: nil,
                scheduledAt: atlasDate(from: reminder.scheduledFor),
                state: .upcoming
            ),
            selectedMode: reminder.privacyMode,
            renderMode: renderMode,
            now: atlasDate(from: reminder.createdAt)
        )
        var value = reminder
        value.title = preview.title
        value.body = preview.body
        value.privacyMode = preview.effectiveMode
        value.discreetCopyEnabled = preview.effectiveMode != .fullDetail
        return value
    }
    sanitized.vials = snapshot.vials.map { record in
        var value = record
        value.label = privacyFormatter.exportVialTitle(
            canonical: record.label,
            mode: renderMode
        )
        return value
    }
    sanitized.consumables = snapshot.consumables.map { record in
        var value = record
        value.name = privacyFormatter.exportConsumableTitle(
            canonical: record.name,
            category: record.category,
            mode: renderMode
        )
        if renderMode != .full {
            value.vendorLabel = nil
            value.purchaseNotes = nil
            value.lotNumber = nil
            value.sizeDescription = nil
            value.notes = nil
        }
        return value
    }
    sanitized.contextLogs = snapshot.contextLogs.map { record in
        var value = record
        if renderMode != .full {
            value.note = nil
            value.tags = []
        }
        return value
    }
    sanitized.customMetrics = snapshot.customMetrics.map { record in
        var value = record
        value.label = privacyFormatter.metricLabel(
            canonical: record.label,
            mode: renderMode
        )
        return value
    }
    return sortExportSnapshot(sanitized)
}

func sortExportSnapshot(_ snapshot: AtlasExportSnapshot) -> AtlasExportSnapshot {
    AtlasExportSnapshot(
        calculatorProfiles: snapshot.calculatorProfiles.sorted { $0.id < $1.id },
        compounds: snapshot.compounds.sorted { $0.id < $1.id },
        consumableAdjustments: snapshot.consumableAdjustments.sorted { $0.id < $1.id },
        consumables: snapshot.consumables.sorted { $0.id < $1.id },
        contextLogs: snapshot.contextLogs.sorted { $0.id < $1.id },
        customMetrics: snapshot.customMetrics.sorted { $0.id < $1.id },
        healthConnections: snapshot.healthConnections.sorted { $0.providerKey.rawValue < $1.providerKey.rawValue },
        logEvents: snapshot.logEvents.sorted { $0.id < $1.id },
        metricValueLogs: snapshot.metricValueLogs.sorted { $0.id < $1.id },
        privacyProfile: snapshot.privacyProfile,
        protocolChangeAudits: snapshot.protocolChangeAudits.sorted { $0.id < $1.id },
        protocolAliases: snapshot.protocolAliases.sorted { $0.id < $1.id },
        protocolRevisionRules: snapshot.protocolRevisionRules.sorted { $0.id < $1.id },
        protocolRevisions: snapshot.protocolRevisions.sorted { $0.id < $1.id },
        protocols: snapshot.protocols.sorted { $0.id < $1.id },
        protocolRules: snapshot.protocolRules.sorted { $0.id < $1.id },
        reminderPreference: snapshot.reminderPreference,
        reminders: snapshot.reminders.sorted { $0.id < $1.id },
        sensitiveActionAudits: snapshot.sensitiveActionAudits.sorted { $0.id < $1.id },
        sites: snapshot.sites.sorted { $0.id < $1.id },
        symptomLogs: snapshot.symptomLogs.sorted { $0.id < $1.id },
        vials: snapshot.vials.sorted { $0.id < $1.id },
        weightLogs: snapshot.weightLogs.sorted { $0.id < $1.id }
    )
}

func snapshotRowCount(_ snapshot: AtlasExportSnapshot) -> Int {
    let profileCount = snapshot.calculatorProfiles.count
    let compoundCount = snapshot.compounds.count
    let consumableAdjustmentCount = snapshot.consumableAdjustments.count
    let consumableCount = snapshot.consumables.count
    let contextCount = snapshot.contextLogs.count
    let customMetricCount = snapshot.customMetrics.count
    let connectionCount = snapshot.healthConnections.count
    let logCount = snapshot.logEvents.count
    let metricValueCount = snapshot.metricValueLogs.count
    let auditCount = snapshot.protocolChangeAudits.count
    let protocolCount = snapshot.protocols.count
    let aliasCount = snapshot.protocolAliases.count
    let revisionRuleCount = snapshot.protocolRevisionRules.count
    let revisionCount = snapshot.protocolRevisions.count
    let protocolRuleCount = snapshot.protocolRules.count
    let reminderCount = snapshot.reminders.count
    let sensitiveAuditCount = snapshot.sensitiveActionAudits.count
    let siteCount = snapshot.sites.count
    let symptomCount = snapshot.symptomLogs.count
    let vialCount = snapshot.vials.count
    let weightCount = snapshot.weightLogs.count

    return profileCount
        + compoundCount
        + consumableAdjustmentCount
        + consumableCount
        + contextCount
        + customMetricCount
        + connectionCount
        + logCount
        + metricValueCount
        + 1
        + 1
        + auditCount
        + protocolCount
        + aliasCount
        + revisionRuleCount
        + revisionCount
        + protocolRuleCount
        + reminderCount
        + sensitiveAuditCount
        + siteCount
        + symptomCount
        + vialCount
        + weightCount
}

private func buildAtlasCsvContents(snapshot: AtlasExportSnapshot) -> String {
    let rows = [
        buildCsvRows(snapshot.protocols) {
            buildCsvRow("protocol", $0.id, $0.name, $0.createdAt, $0.status.rawValue, $0.kind.rawValue, $0.notes)
        },
        buildCsvRows(snapshot.protocolRules) {
            buildCsvRow("protocol_rule", $0.id, $0.protocolId, $0.createdAt, $0.ruleType.rawValue, $0.timeOfDay, $0.anchorDate)
        },
        buildCsvRows(snapshot.protocolRevisions) {
            buildCsvRow("protocol_revision", $0.id, $0.protocolId, $0.effectiveFrom, $0.lifecycleState.rawValue, $0.timezoneStrategy.rawValue, $0.notes)
        },
        buildCsvRows(snapshot.protocolRevisionRules) {
            buildCsvRow("protocol_revision_rule", $0.id, $0.revisionId, $0.createdAt, $0.ruleType.rawValue, $0.phaseType.rawValue, $0.anchorDate)
        },
        buildCsvRows(snapshot.protocolChangeAudits) {
            buildCsvRow("protocol_change_audit", $0.id, $0.protocolId, $0.createdAt, $0.changeType.rawValue, $0.effectiveFrom, $0.summary)
        },
        buildCsvRows(snapshot.logEvents) {
            buildCsvRow("log_event", $0.id, $0.protocolId, $0.loggedAt, $0.eventType.rawValue, $0.quantity, $0.notes)
        },
        buildCsvRows(snapshot.vials) {
            buildCsvRow("vial", $0.id, $0.label, $0.updatedAt, $0.remainingQuantity, $0.quantityUnit, $0.lowStockThreshold)
        },
        buildCsvRows(snapshot.consumables) {
            buildCsvRow("consumable", $0.id, $0.name, $0.updatedAt, $0.quantityOnHand, $0.unit, $0.category)
        },
        buildCsvRows(snapshot.consumableAdjustments) {
            buildCsvRow("consumable_adjustment", $0.id, $0.consumableId, $0.recordedAt, $0.deltaQuantity, $0.quantityUnit, $0.kind.rawValue)
        },
        buildCsvRows(snapshot.contextLogs) {
            buildCsvRow(
                "context_log",
                $0.id,
                $0.protocolId,
                $0.loggedAt,
                $0.mealTiming?.rawValue,
                $0.fedState?.rawValue ?? $0.appetite?.rawValue ?? $0.hydration?.rawValue,
                $0.note ?? $0.tags.joined(separator: "|")
            )
        },
        buildCsvRows(snapshot.weightLogs) {
            buildCsvRow("weight_log", $0.id, $0.unit.rawValue, $0.loggedAt, $0.value, $0.source.rawValue, $0.notes)
        },
        buildCsvRows(snapshot.symptomLogs) {
            buildCsvRow("symptom_log", $0.id, $0.symptomKey, $0.loggedAt, $0.severity, $0.source.rawValue, $0.notes)
        },
        buildCsvRows(snapshot.customMetrics) {
            buildCsvRow("custom_metric", $0.id, $0.label, $0.createdAt, $0.valueType.rawValue, $0.unit, $0.metricKey)
        },
        buildCsvRows(snapshot.metricValueLogs) {
            buildCsvRow("metric_value_log", $0.id, $0.metricId, $0.loggedAt, $0.numberValue ?? $0.textValue ?? $0.booleanValue, $0.source.rawValue, $0.protocolId)
        },
        buildCsvRows(snapshot.healthConnections) {
            buildCsvRow("health_connection", $0.providerKey.rawValue, $0.enabled ? "enabled" : "disabled", $0.updatedAt, $0.connected ? "connected" : "not_connected", $0.lastSyncAt, $0.lastError)
        },
        [
            buildCsvRow(
                "privacy_profile",
                snapshot.privacyProfile.id,
                snapshot.privacyProfile.aliasModeEnabled ? "alias_on" : "alias_off",
                snapshot.privacyProfile.updatedAt,
                snapshot.privacyProfile.biometricLockEnabled ? "biometric_on" : "biometric_off",
                snapshot.privacyProfile.biometricGateMode.rawValue,
                snapshot.privacyProfile.exportAliasByDefault
            )
        ],
        buildCsvRows(snapshot.protocolAliases) {
            buildCsvRow("protocol_alias", $0.id, $0.protocolId, $0.updatedAt, $0.aliasLabel, $0.aliasCompoundLabel, $0.archivedAt)
        },
        buildCsvRows(snapshot.sensitiveActionAudits) {
            buildCsvRow("sensitive_action_audit", $0.id, $0.eventType.rawValue, $0.createdAt, $0.surface, $0.renderMode?.rawValue, $0.scopeKind)
        },
        buildCsvRows(snapshot.calculatorProfiles) {
            buildCsvRow("calculator_profile", $0.id, $0.label, $0.updatedAt, $0.powderAmount, $0.diluentVolume, $0.drawVolume)
        },
        buildCsvRows(snapshot.reminders) {
            buildCsvRow("reminder", $0.id, $0.protocolId, $0.scheduledFor, $0.status.rawValue, $0.privacyMode.rawValue, $0.notificationId)
        },
        [
            buildCsvRow(
                "reminder_preference",
                snapshot.reminderPreference.id,
                snapshot.reminderPreference.privacyMode.rawValue,
                snapshot.reminderPreference.updatedAt,
                snapshot.reminderPreference.remindersEnabled,
                snapshot.reminderPreference.leadTimeMinutes,
                nil
            )
        ],
        buildCsvRows(snapshot.sites) {
            buildCsvRow("site", $0.id, $0.name, $0.updatedAt, $0.bodyArea, $0.archivedAt, $0.notes)
        },
        buildCsvRows(snapshot.compounds) {
            buildCsvRow("compound", $0.id, $0.displayName, $0.updatedAt, $0.compoundType, $0.isUserDefined, $0.notes)
        }
    ]
    .flatMap { $0 }

    let header = ["dataset", "id", "primary", "timestamp", "value", "secondary", "notes"].joined(separator: ",")
    let body = rows.map { row in
        [row.dataset, row.id, row.primary, row.timestamp, row.value, row.secondary, row.notes]
            .map(toCsvCell)
            .joined(separator: ",")
    }

    return ([header] + body).joined(separator: "\n")
}

private struct AtlasCsvRow {
    let dataset: String
    let id: String
    let primary: String
    let timestamp: String
    let value: String
    let secondary: String
    let notes: String
}

private func buildCsvRows<T>(_ values: [T], rowBuilder: (T) -> AtlasCsvRow) -> [AtlasCsvRow] {
    values.map(rowBuilder)
}

private func buildCsvRow(
    _ dataset: String,
    _ id: Any?,
    _ primary: Any?,
    _ timestamp: Any?,
    _ value: Any?,
    _ secondary: Any?,
    _ notes: Any?
) -> AtlasCsvRow {
    AtlasCsvRow(
        dataset: dataset,
        id: stringifyCsvValue(id),
        primary: stringifyCsvValue(primary),
        timestamp: stringifyCsvValue(timestamp),
        value: stringifyCsvValue(value),
        secondary: stringifyCsvValue(secondary),
        notes: stringifyCsvValue(notes)
    )
}

private func stringifyCsvValue(_ value: Any?) -> String {
    guard let value else {
        return ""
    }
    if let bool = value as? Bool {
        return bool ? "true" : "false"
    }
    return String(describing: value)
}

private func toCsvCell(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
}

func selectiveShareSnapshot(
    from snapshot: AtlasExportSnapshot,
    request: AtlasSelectiveShareRequest,
    now: Date
) -> AtlasExportSnapshot {
    let range30 = AtlasDateRange(
        start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now,
        end: now
    )
    let requestedRange = request.dateRange ?? range30

    func protocolScopedSnapshot(protocolIDs: Set<String>, includeLogs: Bool) -> AtlasExportSnapshot {
        let protocols = snapshot.protocols.filter { protocolIDs.contains($0.id) }
        let revisions = snapshot.protocolRevisions.filter { protocolIDs.contains($0.protocolId) }
        let revisionIDs = Set(revisions.map(\.id))
        let protocolRules = snapshot.protocolRules.filter { protocolIDs.contains($0.protocolId) }
        let revisionRules = snapshot.protocolRevisionRules.filter { revisionIDs.contains($0.revisionId) }
        let audits = snapshot.protocolChangeAudits.filter { protocolIDs.contains($0.protocolId) }
        let reminders = snapshot.reminders.filter { protocolIDs.contains($0.protocolId) }
        let aliases = snapshot.protocolAliases.filter { protocolIDs.contains($0.protocolId) }
        let vials = snapshot.vials.filter { vial in
            vial.protocolId.map(protocolIDs.contains) ?? false
        }
        let consumables = snapshot.consumables.filter { consumable in
            consumable.protocolId.map(protocolIDs.contains) ?? false
        }
        let contextLogs = includeLogs
            ? snapshot.contextLogs.filter {
                ($0.protocolId.map(protocolIDs.contains) ?? false) && matchesRange($0.loggedAt, range: requestedRange)
            }
            : []
        let logEvents = includeLogs
            ? snapshot.logEvents.filter { protocolIDs.contains($0.protocolId) && matchesRange($0.loggedAt, range: requestedRange) }
            : []
        let consumableAdjustments = includeLogs
            ? snapshot.consumableAdjustments.filter {
                ($0.protocolId.map(protocolIDs.contains) ?? false) && matchesRange($0.recordedAt, range: requestedRange)
            }
            : []
        let customMetrics = snapshot.customMetrics.filter { metric in
            metric.protocolId.map(protocolIDs.contains) ?? false
        }
        let metricIDs = Set(customMetrics.map(\.id))
        let metricValueLogs = includeLogs
            ? snapshot.metricValueLogs.filter {
                (($0.protocolId.map(protocolIDs.contains) ?? false) || metricIDs.contains($0.metricId))
                    && matchesRange($0.loggedAt, range: requestedRange)
            }
            : []
        let sites = snapshot.sites.filter { site in
            logEvents.contains(where: { $0.siteId == site.id })
        }

        return AtlasExportSnapshot(
            calculatorProfiles: snapshot.calculatorProfiles.filter { profile in
                vials.contains(where: { $0.calculatorProfileId == profile.id })
            },
            compounds: snapshot.compounds.filter { compound in
                protocols.contains(where: { $0.compoundId == compound.id })
            },
            consumableAdjustments: consumableAdjustments,
            consumables: consumables,
            contextLogs: contextLogs,
            customMetrics: customMetrics,
            healthConnections: [],
            logEvents: logEvents,
            metricValueLogs: metricValueLogs,
            privacyProfile: snapshot.privacyProfile,
            protocolChangeAudits: audits,
            protocolAliases: aliases,
            protocolRevisionRules: revisionRules,
            protocolRevisions: revisions,
            protocols: protocols,
            protocolRules: protocolRules,
            reminderPreference: snapshot.reminderPreference,
            reminders: reminders,
            sensitiveActionAudits: snapshot.sensitiveActionAudits.filter {
                $0.protocolId.map(protocolIDs.contains) ?? false
            },
            sites: sites,
            symptomLogs: [],
            vials: vials,
            weightLogs: []
        )
    }

    var rawSubset: AtlasExportSnapshot
    switch request.scopeKind {
    case .currentProtocolOnly:
        rawSubset = protocolScopedSnapshot(protocolIDs: Set(request.protocolID.map { [$0] } ?? []), includeLogs: false)
    case .protocolWithRecentTimeline:
        rawSubset = protocolScopedSnapshot(protocolIDs: Set(request.protocolID.map { [$0] } ?? []), includeLogs: true)
    case .last30DaysLogs:
        let logs = snapshot.logEvents.filter { matchesRange($0.loggedAt, range: range30) }
        let consumableAdjustments = snapshot.consumableAdjustments.filter { matchesRange($0.recordedAt, range: range30) }
        let metricValueLogs = snapshot.metricValueLogs.filter { matchesRange($0.loggedAt, range: range30) }
        let metricIDs = Set(metricValueLogs.map(\.metricId))
        let protocolIDs = Set(logs.map(\.protocolId))
        rawSubset = AtlasExportSnapshot(
            calculatorProfiles: [],
            compounds: snapshot.compounds.filter { compound in
                snapshot.protocols.contains(where: { protocolIDs.contains($0.id) && $0.compoundId == compound.id })
            },
            consumableAdjustments: consumableAdjustments,
            consumables: snapshot.consumables.filter { $0.protocolId.map(protocolIDs.contains) ?? false },
            contextLogs: snapshot.contextLogs.filter { matchesRange($0.loggedAt, range: range30) },
            customMetrics: snapshot.customMetrics.filter { metricIDs.contains($0.id) },
            healthConnections: [],
            logEvents: logs,
            metricValueLogs: metricValueLogs,
            privacyProfile: snapshot.privacyProfile,
            protocolChangeAudits: snapshot.protocolChangeAudits.filter {
                protocolIDs.contains($0.protocolId) && matchesRange($0.createdAt, range: range30)
            },
            protocolAliases: snapshot.protocolAliases.filter { protocolIDs.contains($0.protocolId) },
            protocolRevisionRules: [],
            protocolRevisions: [],
            protocols: snapshot.protocols.filter { protocolIDs.contains($0.id) },
            protocolRules: [],
            reminderPreference: snapshot.reminderPreference,
            reminders: [],
            sensitiveActionAudits: [],
            sites: snapshot.sites.filter { site in
                logs.contains(where: { $0.siteId == site.id })
            },
            symptomLogs: snapshot.symptomLogs.filter { matchesRange($0.loggedAt, range: range30) },
            vials: snapshot.vials.filter { vial in
                vial.protocolId.map(protocolIDs.contains) ?? false
            },
            weightLogs: snapshot.weightLogs.filter { matchesRange($0.loggedAt, range: range30) }
        )
    case .symptomsOnly:
        rawSubset = AtlasExportSnapshot(
            contextLogs: snapshot.contextLogs.filter { matchesRange($0.loggedAt, range: requestedRange) },
            privacyProfile: snapshot.privacyProfile,
            reminderPreference: snapshot.reminderPreference,
            symptomLogs: snapshot.symptomLogs.filter { matchesRange($0.loggedAt, range: requestedRange) }
        )
    case .inventoryOnly:
        let protocolIDs = Set(request.protocolID.map { [$0] } ?? (snapshot.vials.compactMap(\.protocolId) + snapshot.consumables.compactMap(\.protocolId)))
        let vials = snapshot.vials.filter { vial in
            request.protocolID == nil ? true : vial.protocolId == request.protocolID
        }
        let consumables = snapshot.consumables.filter { consumable in
            request.protocolID == nil ? true : consumable.protocolId == request.protocolID
        }
        let consumableIDs = Set(consumables.map(\.id))
        rawSubset = AtlasExportSnapshot(
            calculatorProfiles: snapshot.calculatorProfiles.filter { profile in
                vials.contains(where: { $0.calculatorProfileId == profile.id })
            },
            compounds: snapshot.compounds.filter { compound in
                snapshot.protocols.contains(where: { protocolIDs.contains($0.id) && $0.compoundId == compound.id })
            },
            consumableAdjustments: snapshot.consumableAdjustments.filter { adjustment in
                consumableIDs.contains(adjustment.consumableId)
            },
            consumables: consumables,
            privacyProfile: snapshot.privacyProfile,
            protocolAliases: snapshot.protocolAliases.filter { protocolIDs.contains($0.protocolId) },
            protocolRevisions: snapshot.protocolRevisions.filter { protocolIDs.contains($0.protocolId) },
            protocols: snapshot.protocols.filter { protocolIDs.contains($0.id) },
            reminderPreference: snapshot.reminderPreference,
            sites: snapshot.sites,
            vials: vials
        )
    case .summaryOnly:
        let protocolIDs = Set(request.protocolID.map { [$0] } ?? snapshot.protocols.map(\.id))
        rawSubset = AtlasExportSnapshot(
            compounds: snapshot.compounds.filter { compound in
                snapshot.protocols.contains(where: { protocolIDs.contains($0.id) && $0.compoundId == compound.id })
            },
            privacyProfile: snapshot.privacyProfile,
            protocolAliases: snapshot.protocolAliases.filter { protocolIDs.contains($0.protocolId) },
            protocolRevisions: snapshot.protocolRevisions.filter { protocolIDs.contains($0.protocolId) },
            protocols: snapshot.protocols.filter { protocolIDs.contains($0.id) },
            reminderPreference: snapshot.reminderPreference
        )
    case .customDateRange:
        let selectedProtocolIDs = request.protocolIDs.isEmpty ? Set(snapshot.protocols.map(\.id)) : Set(request.protocolIDs)
        rawSubset = AtlasExportSnapshot(
            calculatorProfiles: request.include.contains(.inventory) ? snapshot.calculatorProfiles : [],
            compounds: snapshot.compounds.filter { compound in
                snapshot.protocols.contains(where: { selectedProtocolIDs.contains($0.id) && $0.compoundId == compound.id })
            },
            consumableAdjustments: request.include.contains(.inventory)
                ? snapshot.consumableAdjustments.filter {
                    ($0.protocolId.map(selectedProtocolIDs.contains) ?? false) && matchesRange($0.recordedAt, range: requestedRange)
                }
                : [],
            consumables: request.include.contains(.inventory)
                ? snapshot.consumables.filter { $0.protocolId.map(selectedProtocolIDs.contains) ?? false }
                : [],
            contextLogs: (request.include.contains(.logs) || request.include.contains(.symptoms))
                ? snapshot.contextLogs.filter {
                    (($0.protocolId.map(selectedProtocolIDs.contains) ?? false) || $0.protocolId == nil)
                        && matchesRange($0.loggedAt, range: requestedRange)
                }
                : [],
            customMetrics: [],
            healthConnections: [],
            logEvents: request.include.contains(.logs)
                ? snapshot.logEvents.filter {
                    selectedProtocolIDs.contains($0.protocolId) && matchesRange($0.loggedAt, range: requestedRange)
                }
                : [],
            metricValueLogs: request.include.contains(.logs)
                ? snapshot.metricValueLogs.filter {
                    (($0.protocolId.map(selectedProtocolIDs.contains) ?? false) || selectedProtocolIDs.isEmpty)
                        && matchesRange($0.loggedAt, range: requestedRange)
                }
                : [],
            privacyProfile: snapshot.privacyProfile,
            protocolChangeAudits: request.include.contains(.logs)
                ? snapshot.protocolChangeAudits.filter {
                    selectedProtocolIDs.contains($0.protocolId) && matchesRange($0.createdAt, range: requestedRange)
                }
                : [],
            protocolAliases: snapshot.protocolAliases.filter { selectedProtocolIDs.contains($0.protocolId) },
            protocolRevisionRules: request.include.contains(.summary)
                ? snapshot.protocolRevisionRules.filter { rule in
                    snapshot.protocolRevisions.contains(where: { $0.id == rule.revisionId && selectedProtocolIDs.contains($0.protocolId) })
                }
                : [],
            protocolRevisions: request.include.contains(.summary)
                ? snapshot.protocolRevisions.filter { selectedProtocolIDs.contains($0.protocolId) }
                : [],
            protocols: request.include.contains(.summary) || request.include.contains(.inventory) || request.include.contains(.logs)
                ? snapshot.protocols.filter { selectedProtocolIDs.contains($0.id) }
                : [],
            protocolRules: request.include.contains(.summary)
                ? snapshot.protocolRules.filter { selectedProtocolIDs.contains($0.protocolId) }
                : [],
            reminderPreference: snapshot.reminderPreference,
            reminders: [],
            sensitiveActionAudits: [],
            sites: request.include.contains(.inventory) ? snapshot.sites : [],
            symptomLogs: request.include.contains(.symptoms)
                ? snapshot.symptomLogs.filter { matchesRange($0.loggedAt, range: requestedRange) }
                : [],
            vials: request.include.contains(.inventory)
                ? snapshot.vials.filter { $0.protocolId.map(selectedProtocolIDs.contains) ?? false }
                : [],
            weightLogs: request.include.contains(.logs)
                ? snapshot.weightLogs.filter { matchesRange($0.loggedAt, range: requestedRange) }
                : []
        )
        if request.include.contains(.logs) {
            let metricIDs = Set(rawSubset.metricValueLogs.map(\.metricId))
            rawSubset.customMetrics = snapshot.customMetrics.filter { metricIDs.contains($0.id) }
        }
    }

    return sanitizeExportSnapshot(sortExportSnapshot(rawSubset), renderMode: request.renderMode, privacyFormatter: AtlasPrivacyFormatter())
}

func buildSelectiveSharePreview(
    snapshot: AtlasExportSnapshot,
    request: AtlasSelectiveShareRequest,
    privacyFormatter: AtlasPrivacyFormatter,
    now: Date
) -> AtlasSelectiveSharePreview {
    let datasets = selectiveShareDatasetSummaries(snapshot: snapshot)
    let protocolLines = snapshot.protocols.prefix(3).map(\.name)
    let episodeInsights = buildEpisodeInsightsSnapshot(snapshot: snapshot, now: now)
    var sections = [
        AtlasSelectiveSharePreviewSection(
            title: "Scope",
            lines: [
                shareScopeSummary(request.scopeKind),
                "Render mode: \(request.renderMode.rawValue.capitalized)",
                "Static snapshot only"
            ]
        ),
        AtlasSelectiveSharePreviewSection(
            title: "Included content",
            lines: datasets.map { "\($0.dataset): \($0.rowCount)" }
        ),
        AtlasSelectiveSharePreviewSection(
            title: "Preview",
            lines: protocolLines.isEmpty
                ? ["No protocol labels included in this scope."]
                : protocolLines
        )
    ]

    if episodeInsights.hasAnyEpisodeData {
        sections.append(
            AtlasSelectiveSharePreviewSection(
                title: "Episode summary",
                lines: episodePreviewLines(from: episodeInsights)
            )
        )
    }

    let summary = "Previewing \(shareScopeSummary(request.scopeKind).lowercased()) with \(snapshotRowCount(snapshot)) row(s)."

    _ = privacyFormatter

    return AtlasSelectiveSharePreview(
        scopeKind: request.scopeKind,
        renderMode: request.renderMode,
        summary: summary,
        datasets: datasets,
        sections: sections,
        rowCount: snapshotRowCount(snapshot)
    )
}

func selectiveShareDatasetSummaries(snapshot: AtlasExportSnapshot) -> [AtlasSelectiveShareDatasetSummary] {
    let values: [(String, Int)] = [
        ("privacyProfile", 1),
        ("reminderPreference", 1),
        ("protocols", snapshot.protocols.count),
        ("protocolRevisions", snapshot.protocolRevisions.count),
        ("protocolRevisionRules", snapshot.protocolRevisionRules.count),
        ("protocolRules", snapshot.protocolRules.count),
        ("protocolChangeAudits", snapshot.protocolChangeAudits.count),
        ("protocolAliases", snapshot.protocolAliases.count),
        ("logEvents", snapshot.logEvents.count),
        ("consumables", snapshot.consumables.count),
        ("consumableAdjustments", snapshot.consumableAdjustments.count),
        ("contextLogs", snapshot.contextLogs.count),
        ("customMetrics", snapshot.customMetrics.count),
        ("metricValueLogs", snapshot.metricValueLogs.count),
        ("sensitiveActionAudits", snapshot.sensitiveActionAudits.count),
        ("vials", snapshot.vials.count),
        ("sites", snapshot.sites.count),
        ("calculatorProfiles", snapshot.calculatorProfiles.count),
        ("symptomLogs", snapshot.symptomLogs.count),
        ("weightLogs", snapshot.weightLogs.count),
        ("compounds", snapshot.compounds.count),
        ("reminders", snapshot.reminders.count)
    ]

    return values
        .filter { $0.1 > 0 }
        .map { AtlasSelectiveShareDatasetSummary(dataset: $0.0, rowCount: $0.1) }
}

func episodePreviewLines(from insights: AtlasEpisodeInsightsSnapshot) -> [String] {
    var lines: [String] = []
    if let strongest = insights.patternCards.first {
        lines.append(strongest.title)
        lines.append(strongest.detail)
    }
    if let busiestWindow = insights.compareWindows.max(by: {
        ($0.symptomEntryCount + $0.weightEntryCount + $0.metricEntryCount) < ($1.symptomEntryCount + $1.weightEntryCount + $1.metricEntryCount)
    }) {
        lines.append("\(busiestWindow.windowKind.title): \(busiestWindow.summaryLabel)")
    }
    lines.append(insights.disclaimer)
    return lines
}

func matchesRange(_ timestamp: String, range: AtlasDateRange) -> Bool {
    let date = atlasDate(from: timestamp)
    return date >= range.start && date <= range.end
}

func shareScopeSummary(_ scope: AtlasSelectiveShareScopeKind) -> String {
    switch scope {
    case .currentProtocolOnly:
        return "Current protocol only"
    case .protocolWithRecentTimeline:
        return "Selected protocol with recent timeline"
    case .last30DaysLogs:
        return "Last 30 days logs"
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

private func makeShareCode() -> String {
    let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    let code = (0..<12).map { _ in
        characters.randomElement() ?? "A"
    }
    return String(code)
}

private func symmetricKey(for shareCode: String) -> SymmetricKey {
    let digest = SHA256.hash(data: Data(shareCode.utf8))
    return SymmetricKey(data: Data(digest))
}

func sanitizedFileTimestamp(_ timestamp: String) -> String {
    timestamp.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: ".", with: "-")
}

extension GRDBImportExportBridge {
    func exportDirectoryURL() throws -> URL {
        let directoryURL = stack.locations?.backupDirectoryURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}

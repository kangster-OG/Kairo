import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

public struct GRDBTrustVaultRepository: TrustVaultRepository, Sendable {
    let stack: AtlasDatabaseStack
    let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.privacyFormatter = privacyFormatter
    }

    public func fetchTrustVaultSnapshot() async throws -> AtlasTrustVaultSnapshot {
        try await stack.canonical.read { db in
            try buildTrustVaultSnapshot(db: db, privacyFormatter: privacyFormatter)
        }
    }

    public func updatePrivacyProfile(
        _ update: AtlasTrustVaultProfileUpdate,
        now: Date
    ) async throws -> AtlasTrustVaultSnapshot {
        try await stack.canonical.write { db in
            let previous = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            var profile = previous

            if let renderMode = update.renderMode {
                profile.renderMode = renderMode
                profile.aliasModeEnabled = renderMode == .alias
            }
            if let biometricLockEnabled = update.biometricLockEnabled {
                profile.biometricLockEnabled = biometricLockEnabled
            }
            if let biometricGateMode = update.biometricGateMode {
                profile.biometricGateMode = biometricGateMode
            }
            if let shareAliasByDefault = update.shareAliasByDefault {
                profile.shareAliasByDefault = shareAliasByDefault
            }
            if let exportAliasByDefault = update.exportAliasByDefault {
                profile.exportAliasByDefault = exportAliasByDefault
            }
            profile.updatedAt = atlasTimestamp(from: now)

            try AtlasPrivacyProfileDBRecord(record: profile).save(db)

            if previous.renderMode != profile.renderMode {
                try writeSensitiveActionAudit(
                    db: db,
                    eventType: .privacyModeChanged,
                    surface: "trust_vault",
                    protocolId: nil,
                    scopeKind: nil,
                    renderMode: profile.renderMode,
                    manifestVersion: 1,
                    payloadJson: trustVaultPayload([
                        "previousRenderMode": previous.renderMode?.rawValue ?? "full",
                        "nextRenderMode": profile.renderMode?.rawValue ?? "full"
                    ]),
                    now: now
                )
            }

            if previous.biometricLockEnabled != profile.biometricLockEnabled
                || previous.biometricGateMode != profile.biometricGateMode {
                try writeSensitiveActionAudit(
                    db: db,
                    eventType: .biometricLockChanged,
                    surface: "trust_vault",
                    protocolId: nil,
                    scopeKind: nil,
                    renderMode: profile.renderMode,
                    manifestVersion: 1,
                    payloadJson: trustVaultPayload([
                        "biometricLockEnabled": profile.biometricLockEnabled ? "true" : "false",
                        "biometricGateMode": profile.biometricGateMode.rawValue
                    ]),
                    now: now
                )
            }

            return try buildTrustVaultSnapshot(db: db, privacyFormatter: privacyFormatter)
        }
    }

    public func saveProtocolAlias(
        _ draft: AtlasProtocolAliasDraft,
        now: Date
    ) async throws -> AtlasTrustVaultSnapshot {
        try await stack.canonical.write { db in
            let trimmedAlias = draft.aliasLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCompound = draft.aliasCompoundLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let existing = try AtlasProtocolAliasDBRecord
                .filter(Column("protocol_id") == draft.protocolID)
                .fetchOne(db)

            if trimmedAlias.isEmpty, (trimmedCompound ?? "").isEmpty {
                if let existing {
                    try existing.delete(db)
                }
            } else {
                let record = AtlasProtocolAliasRecord.make(
                    id: existing?.id ?? "alias_\(draft.protocolID)",
                    protocolId: draft.protocolID,
                    aliasLabel: trimmedAlias.isEmpty ? "Alias protocol" : trimmedAlias,
                    aliasCompoundLabel: trimmedCompound?.isEmpty == true ? nil : trimmedCompound,
                    createdAt: existing?.createdAt ?? atlasTimestamp(from: now),
                    updatedAt: atlasTimestamp(from: now),
                    archivedAt: nil
                )
                try AtlasProtocolAliasDBRecord(record: record).save(db)
            }

            let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            try writeSensitiveActionAudit(
                db: db,
                eventType: .aliasChanged,
                surface: "trust_vault",
                protocolId: draft.protocolID,
                scopeKind: nil,
                renderMode: profile.renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "aliasLabel": trimmedAlias,
                    "aliasCompoundLabel": trimmedCompound ?? ""
                ]),
                now: now
            )

            return try buildTrustVaultSnapshot(db: db, privacyFormatter: privacyFormatter)
        }
    }

    public func recordVaultUnlock(surface: String, now: Date) async throws {
        try await stack.canonical.write { db in
            let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            try writeSensitiveActionAudit(
                db: db,
                eventType: .vaultUnlocked,
                surface: surface,
                protocolId: nil,
                scopeKind: nil,
                renderMode: profile.renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "surface": surface
                ]),
                now: now
            )
        }
    }
}

func buildTrustVaultSnapshot(
    db: Database,
    privacyFormatter: AtlasPrivacyFormatter
) throws -> AtlasTrustVaultSnapshot {
    let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let protocols = try AtlasProtocolDBRecord.fetchAll(db).map(\.domain)
        .sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id < rhs.id
            }
            return lhs.createdAt < rhs.createdAt
        }
    let aliases = Dictionary(
        uniqueKeysWithValues: try AtlasProtocolAliasDBRecord.fetchAll(db).map { ($0.protocolId, $0.domain) }
    )
    let renderMode = privacyFormatter.renderMode(for: profile)

    let aliasItems = protocols.map { protocolRecord in
        let alias = aliases[protocolRecord.id]
        return AtlasTrustVaultAliasItem(
            protocolID: protocolRecord.id,
            canonicalTitle: protocolRecord.name,
            kind: protocolRecord.kind,
            aliasLabel: alias?.aliasLabel,
            aliasCompoundLabel: alias?.aliasCompoundLabel
        )
    }

    let auditRows = try AtlasSensitiveActionAuditDBRecord
        .order(Column("created_at").desc)
        .limit(80)
        .fetchAll(db)
        .map(\.domain)

    let audits = auditRows.map { record in
        let alias = record.protocolId.flatMap { aliases[$0]?.aliasLabel }
        return AtlasTrustVaultAuditItem(
            id: record.id,
            eventType: record.eventType,
            summary: privacyFormatter.sensitiveAuditSummary(
                eventType: record.eventType,
                alias: alias,
                mode: renderMode
            ),
            createdAt: atlasDate(from: record.createdAt)
        )
    }

    return AtlasTrustVaultSnapshot(
        privacyProfile: profile,
        aliases: aliasItems,
        audits: audits
    )
}

func writeSensitiveActionAudit(
    db: Database,
    eventType: AtlasSensitiveActionAuditEventType,
    surface: String,
    protocolId: String?,
    scopeKind: String?,
    renderMode: AtlasPrivacyRenderMode?,
    manifestVersion: Int?,
    payloadJson: String,
    now: Date
) throws {
    let record = AtlasSensitiveActionAuditRecord.make(
        id: "saa_\(UUID().uuidString.lowercased())",
        eventType: eventType,
        surface: surface,
        protocolId: protocolId,
        scopeKind: scopeKind,
        renderMode: renderMode,
        manifestVersion: manifestVersion,
        payloadJson: payloadJson,
        createdAt: atlasTimestamp(from: now)
    )
    try AtlasSensitiveActionAuditDBRecord(record: record).insert(db)
}

func trustVaultPayload(_ fields: [String: String]) -> String {
    guard
        let data = try? JSONSerialization.data(
            withJSONObject: fields.sorted { $0.key < $1.key }.reduce(into: [String: String]()) { partialResult, pair in
                partialResult[pair.key] = pair.value
            },
            options: [.sortedKeys]
        ),
        let string = String(data: data, encoding: .utf8)
    else {
        return "{}"
    }

    return string
}

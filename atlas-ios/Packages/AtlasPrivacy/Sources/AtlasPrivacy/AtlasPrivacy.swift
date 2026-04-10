import AtlasDomain
import Foundation

public struct AtlasPrivacyFormatter: Sendable {
    public init() {}

    public func renderMode(for profile: AtlasPrivacyProfileRecord) -> AtlasPrivacyRenderMode {
        profile.renderMode ?? (profile.aliasModeEnabled ? .alias : .full)
    }

    public func title(
        canonical: String,
        alias: String? = nil,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full:
            return canonical
        case .discreet:
            return "Private protocol"
        case .alias:
            if let alias, alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                return alias
            }
            return "Alias protocol"
        }
    }

    public func compoundTitle(
        canonical: String?,
        aliasCompound: String? = nil,
        mode: AtlasPrivacyRenderMode
    ) -> String? {
        guard let canonical, canonical.isEmpty == false else {
            return nil
        }

        switch mode {
        case .full:
            return canonical
        case .discreet:
            return "Private compound"
        case .alias:
            if let aliasCompound, aliasCompound.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                return aliasCompound
            }
            return "Alias compound"
        }
    }

    public func vialTitle(
        canonical: String,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full:
            return canonical
        case .discreet, .alias:
            return "Linked vial"
        }
    }

    public func consumableTitle(
        canonical: String,
        category: String? = nil,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full:
            return canonical
        case .discreet, .alias:
            return category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank.map { "\($0) supply" } ?? "Supply item"
        }
    }

    public func timelineSummary(
        eventType: AtlasLogEventType,
        canonical: String,
        alias: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        let title = title(canonical: canonical, alias: alias, mode: mode)

        switch mode {
        case .full, .alias:
            switch eventType {
            case .completed:
                return "Logged \(title) as taken"
            case .skipped:
                return "Skipped \(title)"
            case .rescheduled:
                return "Rescheduled \(title)"
            case .manualLog:
                return "Logged \(title) manually"
            case .inventoryAdjustment:
                return "Adjusted inventory for \(title)"
            }
        case .discreet:
            switch eventType {
            case .completed:
                return "Logged a private dose as taken"
            case .skipped:
                return "Skipped a private dose"
            case .rescheduled:
                return "Rescheduled a private dose"
            case .manualLog:
                return "Logged a private dose manually"
            case .inventoryAdjustment:
                return "Adjusted private inventory"
            }
        }
    }

    public func protocolCreatedSummary(
        canonical: String,
        alias: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        let title = title(canonical: canonical, alias: alias, mode: mode)

        switch mode {
        case .full, .alias:
            return "Created \(title)"
        case .discreet:
            return "Created a private protocol"
        }
    }

    public func protocolEditedSummary(
        canonical: String,
        alias: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        let title = title(canonical: canonical, alias: alias, mode: mode)

        switch mode {
        case .full, .alias:
            return "Updated future plan for \(title)"
        case .discreet:
            return "Updated a private protocol"
        }
    }

    public func protocolChangeAuditSummary(
        canonical: String,
        alias: String?,
        auditSummary: String,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full, .alias:
            return auditSummary
        case .discreet:
            let title = title(canonical: canonical, alias: alias, mode: mode)
            return "Updated \(title.lowercased())"
        }
    }

    public func effectiveReminderPrivacyMode(
        selectedMode: AtlasReminderPrivacyMode,
        renderMode: AtlasPrivacyRenderMode
    ) -> AtlasReminderPrivacyMode {
        switch renderMode {
        case .discreet:
            return selectedMode == .silent ? .silent : .generic
        case .alias:
            return selectedMode == .silent ? .silent : .fullDetail
        case .full:
            return selectedMode
        }
    }

    public func reminderPreview(
        occurrence: AtlasScheduledOccurrence,
        selectedMode: AtlasReminderPrivacyMode,
        renderMode: AtlasPrivacyRenderMode,
        now: Date = Date()
    ) -> AtlasReminderPreview {
        let effectiveMode = effectiveReminderPrivacyMode(
            selectedMode: selectedMode,
            renderMode: renderMode
        )

        switch effectiveMode {
        case .silent:
            return AtlasReminderPreview(
                title: "Atlas",
                body: "Open Atlas when you are ready.",
                isSilent: true,
                effectiveMode: effectiveMode
            )
        case .generic:
            return AtlasReminderPreview(
                title: "Atlas reminder",
                body: "A private routine is due \(notificationWhenLabel(for: occurrence.scheduledAt, now: now)).",
                isSilent: false,
                effectiveMode: effectiveMode
            )
        case .fullDetail:
            let title = self.title(
                canonical: occurrence.canonicalTitle,
                alias: occurrence.aliasTitle,
                mode: renderMode
            )
            return AtlasReminderPreview(
                title: title,
                body: "\(title) is due \(notificationWhenLabel(for: occurrence.scheduledAt, now: now)).",
                isSilent: false,
                effectiveMode: effectiveMode
            )
        }
    }

    public func summary(mode: AtlasPrivacyRenderMode) -> String {
        switch mode {
        case .full:
            return "Canonical labels visible on device."
        case .discreet:
            return "Sensitive labels hidden with discreet rendering."
        case .alias:
            return "Alias rendering is active across privacy-aware surfaces."
        }
    }

    public func sensitiveAuditSummary(
        eventType: AtlasSensitiveActionAuditEventType,
        alias: String? = nil,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full:
            return fullAuditSummary(eventType: eventType, alias: alias)
        case .alias:
            return aliasAuditSummary(eventType: eventType, alias: alias)
        case .discreet:
            return discreetAuditSummary(eventType: eventType)
        }
    }

    public func exportProtocolTitle(
        canonical: String,
        alias: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        title(canonical: canonical, alias: alias, mode: mode)
    }

    public func exportVialTitle(
        canonical: String,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        mode == .full ? canonical : "Private vial"
    }

    public func exportConsumableTitle(
        canonical: String,
        category: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        consumableTitle(canonical: canonical, category: category, mode: mode)
    }

    public func metricLabel(
        canonical: String,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full:
            return canonical
        case .discreet:
            return "Private metric"
        case .alias:
            return "Alias metric"
        }
    }

    public func weightTimelineSummary(mode: AtlasPrivacyRenderMode) -> String {
        switch mode {
        case .full, .alias:
            return "Logged weight entry"
        case .discreet:
            return "Logged a private weight entry"
        }
    }

    public func symptomTimelineSummary(
        symptomKey: String,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .full, .alias:
            return "Logged \(symptomKey) symptom entry"
        case .discreet:
            return "Logged a private symptom entry"
        }
    }

    public func metricTimelineSummary(
        metricLabel: String,
        canonicalProtocol: String?,
        aliasProtocol: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String {
        let safeMetricLabel = self.metricLabel(canonical: metricLabel, mode: mode)

        switch mode {
        case .full:
            if let canonicalProtocol {
                return "Logged \(safeMetricLabel) for \(canonicalProtocol)"
            }
            return "Logged \(safeMetricLabel)"
        case .alias:
            if let canonicalProtocol {
                let title = title(canonical: canonicalProtocol, alias: aliasProtocol, mode: mode)
                return "Logged \(safeMetricLabel) for \(title)"
            }
            return "Logged \(safeMetricLabel)"
        case .discreet:
            return "Logged a private metric entry"
        }
    }

    public func contextTimelineSummary(
        mealTiming: AtlasContextMealTiming?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .discreet:
            return "Logged private context"
        case .full, .alias:
            let details = contextDescriptorList(
                mealTiming: mealTiming,
                fedState: fedState,
                appetite: appetite,
                hydration: hydration,
                giTags: giTags,
                mode: mode
            )
            guard details.isEmpty == false else {
                return "Logged context"
            }
            return "Logged \(details.prefix(2).joined(separator: ", ").lowercased())"
        }
    }

    public func contextEntryTitle(
        mealTiming: AtlasContextMealTiming?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        mode: AtlasPrivacyRenderMode
    ) -> String {
        switch mode {
        case .discreet:
            return "Private context"
        case .full, .alias:
            let details = contextDescriptorList(
                mealTiming: mealTiming,
                fedState: fedState,
                appetite: appetite,
                hydration: hydration,
                giTags: giTags,
                mode: mode
            )
            return details.isEmpty ? "Context entry" : details.prefix(3).joined(separator: " • ")
        }
    }

    public func contextEntryDetail(
        note: String?,
        tags: [String],
        canonicalProtocol: String?,
        aliasProtocol: String?,
        mode: AtlasPrivacyRenderMode
    ) -> String? {
        switch mode {
        case .discreet:
            return nil
        case .alias:
            guard let canonicalProtocol else {
                return nil
            }
            let title = title(canonical: canonicalProtocol, alias: aliasProtocol, mode: mode)
            return "Linked to \(title)"
        case .full:
            var parts: [String] = []
            if let canonicalProtocol {
                parts.append("Linked to \(canonicalProtocol)")
            }
            if tags.isEmpty == false {
                parts.append(tags.prefix(3).joined(separator: " • "))
            }
            if let note, note.isEmpty == false {
                parts.append(note)
            }
            return parts.isEmpty ? nil : parts.joined(separator: " • ")
        }
    }

    private func contextDescriptorList(
        mealTiming: AtlasContextMealTiming?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        mode: AtlasPrivacyRenderMode
    ) -> [String] {
        switch mode {
        case .discreet:
            return ["Private context"]
        case .full, .alias:
            var parts: [String] = []
            if let mealTiming {
                parts.append(mealTiming.title)
            }
            if let fedState {
                parts.append(fedState.title)
            }
            if let appetite {
                parts.append(appetite.title)
            }
            if let hydration {
                parts.append(hydration.title)
            }
            let visibleGITags = giTags
                .filter { $0 != .calm }
                .map(\.title)
            if visibleGITags.isEmpty == false {
                parts.append(visibleGITags.prefix(2).joined(separator: " + "))
            } else if giTags == [.calm] {
                parts.append(AtlasContextGITag.calm.title)
            }
            return parts
        }
    }

    private func notificationWhenLabel(for date: Date, now: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        if calendar.isDate(date, inSameDayAs: now) {
            return "today at \(timeFormatter.string(from: date))"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "tomorrow at \(timeFormatter.string(from: date))"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    private func fullAuditSummary(
        eventType: AtlasSensitiveActionAuditEventType,
        alias: String?
    ) -> String {
        switch eventType {
        case .aliasChanged:
            if let alias, alias.isEmpty == false {
                return "Updated alias to \(alias)"
            }
            return "Updated protocol alias"
        case .importCommitted:
            return "Committed import into Atlas"
        case .restorePointCreated:
            return "Created restore point"
        case .restoreCommitted:
            return "Restored local Atlas data"
        case .privacyModeChanged:
            return "Changed privacy mode"
        case .biometricLockChanged:
            return "Changed biometric lock settings"
        case .vaultUnlocked:
            return "Unlocked Trust Vault"
        case .selectiveShareCreated:
            return "Created selective share bundle"
        case .providerHandoffCreated:
            return "Created provider handoff snapshot"
        case .summaryGeneratedOffDevice:
            return "Generated off-device summary"
        case .reviewPackCreated:
            return "Created review pack"
        case .exportCreated:
            return "Created export bundle"
        }
    }

    private func aliasAuditSummary(
        eventType: AtlasSensitiveActionAuditEventType,
        alias: String?
    ) -> String {
        switch eventType {
        case .aliasChanged:
            if let alias, alias.isEmpty == false {
                return "Updated alias \(alias)"
            }
            return "Updated alias"
        case .selectiveShareCreated:
            return "Created alias-safe share bundle"
        case .providerHandoffCreated:
            return "Created alias-safe provider handoff"
        case .summaryGeneratedOffDevice:
            return "Generated alias-safe off-device summary"
        case .restorePointCreated:
            return "Created restore point"
        case .restoreCommitted:
            return "Restored alias-safe Atlas data"
        case .reviewPackCreated:
            return "Created alias-safe review pack"
        default:
            return fullAuditSummary(eventType: eventType, alias: alias)
        }
    }

    private func discreetAuditSummary(
        eventType: AtlasSensitiveActionAuditEventType
    ) -> String {
        switch eventType {
        case .vaultUnlocked:
            return "Unlocked private controls"
        case .selectiveShareCreated:
            return "Created private share bundle"
        case .providerHandoffCreated:
            return "Created private provider handoff"
        case .summaryGeneratedOffDevice:
            return "Generated private off-device summary"
        case .reviewPackCreated:
            return "Created private review pack"
        case .exportCreated:
            return "Created private export"
        case .restorePointCreated:
            return "Created private restore point"
        case .restoreCommitted:
            return "Restored private Atlas data"
        default:
            return "Updated private controls"
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

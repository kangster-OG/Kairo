import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import Foundation
import SwiftUI

extension AtlasAppModel {
    public func changeStudioContext(protocolID: String) async -> AtlasProtocolChangeStudioContext? {
        do {
            return try await dependencies.persistence.changeStudio.loadStudio(
                protocolID: protocolID,
                referenceDate: currentDate()
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func previewProtocolChange(
        protocolID: String,
        draft: AtlasProtocolChangeDraft
    ) async -> AtlasProtocolChangePreview? {
        do {
            return try await dependencies.persistence.changeStudio.buildPreview(
                protocolID: protocolID,
                draft: draft,
                referenceDate: currentDate()
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func commitProtocolChange(
        protocolID: String,
        draft: AtlasProtocolChangeDraft
    ) async -> AtlasProtocolChangeCommitResult? {
        do {
            let now = currentDate()
            let result = try await dependencies.persistence.changeStudio.commitChange(
                protocolID: protocolID,
                draft: draft,
                referenceDate: now
            )
            try await dependencies.reminders.syncReminders(referenceDate: now)
            protocolDetails[protocolID] = result.detail
            await refreshShellData()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }
}

public struct AtlasProtocolChangeStudioScreen: View {
    let model: AtlasAppModel
    let protocolID: String

    @Environment(\.dismiss) private var dismiss
    @State private var context: AtlasProtocolChangeStudioContext?
    @State private var draft = AtlasProtocolChangeDraft()
    @State private var preview: AtlasProtocolChangePreview?
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var showingCommitConfirmation = false
    @State private var committedResult: AtlasProtocolChangeCommitResult?

    public var body: some View {
        AtlasScreen {
            if let error = model.loadErrorMessage {
                Text(error)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(.red)
            }

            if isLoading {
                ProgressView("Loading Protocol Change Studio")
            } else if let context {
                let planning = atlasProtocolPlanningSummary(context: context, draft: draft)

                AtlasCommandDeck(
                    eyebrow: "Change studio",
                    title: model.renderedTitle(canonical: context.canonicalTitle, alias: context.aliasTitle),
                    detail: "\(context.kindLabel) • \(context.cadenceLabel)",
                    metrics: [
                        AtlasMetricItem(id: "operation", title: "Operation", value: draft.changeType.title, tint: AtlasPalette.primary),
                        AtlasMetricItem(id: "preview", title: "Preview", value: preview == nil ? "Pending" : "Ready", tint: preview == nil ? AtlasPalette.secondaryText : AtlasPalette.success)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) {
                    if let doseLabel = context.doseLabel {
                        AtlasCalloutRow(
                            systemImage: "drop.fill",
                            title: "Current saved amount",
                            detail: doseLabel,
                            tint: AtlasPalette.primary
                        )
                    }
                } footer: {
                    Text("Past logs stay as-is. This only rebuilds the future schedule, reminders, and inventory.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let knowledge = context.compoundKnowledge {
                    AtlasSectionCard(title: "Compound context") {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(knowledge.protocolSummary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("\(knowledge.categoryLabel) • \(knowledge.routeLabel)")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Typical cadence: \(knowledge.typicalCadenceLabel)")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Common units: \(knowledge.commonDoseUnits.joined(separator: ", "))")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AtlasSpacing.xSmall) {
                                    ForEach(knowledge.operationalTags, id: \.self) { tag in
                                        AtlasChangeStudioTagChip(label: tag.title)
                                    }
                                }
                            }

                            Button("Open compound intelligence") {
                                model.open(.compoundIntelligence(knowledge.slug))
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        }
                    }
                }

                if context.activeCompanions.isEmpty == false {
                    AtlasSectionCard(title: "Active alongside") {
                        ForEach(context.activeCompanions) { companion in
                            AtlasCompanionProtocolRow(model: model, companion: companion)
                        }
                    }
                }

                AtlasSectionCard(title: "Planning lens") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(planning.headline)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(planning.summary)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .padding(.vertical, AtlasSpacing.xSmall)

                    if planning.recommendedMoves.isEmpty == false {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AtlasSpacing.small) {
                                ForEach(planning.recommendedMoves) { move in
                                    Button {
                                        draft.changeType = move.changeType
                                        preview = nil
                                        committedResult = nil
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(move.title)
                                                .atlasTextRole(.deckEyebrow)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                            Text(move.detail)
                                                .atlasTextRole(.metricLabel)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }
                                        .padding(.horizontal, AtlasSpacing.small)
                                        .padding(.vertical, AtlasSpacing.small)
                                        .frame(width: 168, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(move.changeType == draft.changeType ? AtlasPalette.primary.opacity(0.14) : AtlasPalette.secondaryFill)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    ForEach(planning.checklist) { item in
                        AtlasPlanningChecklistCard(item: item)
                    }
                }

                AtlasSectionCard(title: "Change") {
                    Picker("Operation", selection: $draft.changeType) {
                        ForEach(AtlasProtocolChangeType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }

                    Text(draft.changeType.description)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    DatePicker(
                        "Effective date",
                        selection: $draft.effectiveDate,
                        displayedComponents: .date
                    )
                }

                AtlasSectionCard(title: "Future values") {
                    changeSpecificFields(context: context)
                }

                AtlasSectionCard(title: "Preview window") {
                    Picker("Preview window", selection: $draft.previewWindow) {
                        ForEach(AtlasProtocolChangePreviewWindow.allCases) { window in
                            Text(window.title).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                AtlasSectionCard(title: "Notes") {
                    TextField(
                        "Optional change note",
                        text: Binding(
                            get: { draft.notes ?? "" },
                            set: { draft.notes = $0.isEmpty ? nil : $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Preview") {
                    Button(preview == nil ? "Build preview" : "Refresh preview") {
                        Task {
                            committedResult = nil
                            preview = await model.previewProtocolChange(protocolID: protocolID, draft: draft)
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }

                if let preview {
                    if let commitCheck = atlasProtocolCommitCheck(preview: preview) {
                        AtlasSectionCard(title: "Commit check") {
                            AtlasProtocolCommitCheckCard(check: commitCheck)
                        }
                    }

                    AtlasSectionCard(title: "What changed") {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(preview.summary)
                                .atlasTextRole(.cardBody)
                            if let adherenceNote = preview.adherenceNote {
                                Text(adherenceNote)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    AtlasSectionCard(title: "Impact") {
                        AtlasBeforeAfterRow(
                            title: "Next due",
                            beforeValue: preview.nextDueBefore?.whenLabel ?? "No future occurrence",
                            afterValue: preview.nextDueAfter?.whenLabel ?? "No future occurrence"
                        )
                        AtlasBeforeAfterRow(
                            title: "Reminders",
                            beforeValue: preview.currentReminderLabel ?? "No upcoming reminder",
                            afterValue: preview.draftReminderLabel ?? "No upcoming reminder"
                        )
                        AtlasBeforeAfterRow(
                            title: "Inventory",
                            beforeValue: preview.inventoryForecastBefore ?? "No depletion forecast yet",
                            afterValue: preview.inventoryForecastAfter ?? "No depletion forecast yet"
                        )
                    }

                    AtlasSectionCard(title: "Future occurrences") {
                        if preview.occurrenceChanges.isEmpty {
                            Text("No visible future occurrence changes inside this preview window.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(preview.occurrenceChanges) { change in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(change.kind.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.primary)
                                    if let beforeLabel = change.beforeLabel {
                                        Text("Before: \(beforeLabel)")
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    if let afterLabel = change.afterLabel {
                                        Text("After: \(afterLabel)")
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    AtlasSectionCard(title: "Interaction guidance") {
                        if preview.interactionWarnings.isEmpty {
                            Text("No obvious conflicts detected. Check unit, cadence, and overlap before you save.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(preview.interactionWarnings) { warning in
                                AtlasInteractionWarningCard(warning: warning)
                            }
                        }
                    }

                    if preview.siteWarnings.isEmpty == false {
                        AtlasSectionCard(title: "Site rotation") {
                            ForEach(preview.siteWarnings, id: \.self) { warning in
                                Text(warning)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Commit change") {
                        Button("Commit change") {
                            showingCommitConfirmation = true
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .disabled(isSubmitting)
                    }
                }

                if let committedResult {
                    AtlasSectionCard(title: "Commit summary") {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(committedResult.impactSummary.title)
                                .atlasTextRole(.cardBody)
                            ForEach(committedResult.impactSummary.facts) { fact in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(fact.label)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.primary)
                                    Text(fact.value)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                            ForEach(committedResult.impactSummary.notes, id: \.self) { note in
                                Text(note)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Done") {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
            } else {
                Text("This protocol could not load yet.")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .navigationTitle("Change Studio")
        .changeStudioInlineNavigationTitle()
        .task {
            guard isLoading else {
                return
            }
            context = await model.changeStudioContext(protocolID: protocolID)
            if let context {
                draft = AtlasProtocolChangeDraft(
                    changeType: .futureDose,
                    effectiveDate: model.currentDate(),
                    doseAmount: context.doseLabel.flatMap(parseLeadingNumber),
                    doseUnit: context.doseLabel.flatMap(parseTrailingUnit) ?? "",
                    timeOfDay: context.effectiveTimeOfDay ?? "08:00",
                    weekday: nil,
                    intervalDays: 1,
                    linkedVialID: context.currentLinkedVialID,
                    missedDosePolicy: context.currentMissedDosePolicy,
                    notes: nil,
                    previewWindow: .fourteen,
                    restLengthDays: 7,
                    titrationDoseAmount: nil,
                    titrationDoseUnit: context.doseLabel.flatMap(parseTrailingUnit) ?? "",
                    titrationLengthDays: 14,
                    timezone: context.currentTimezone,
                    timezoneStrategy: context.currentTimezoneStrategy
                )
            }
            isLoading = false
        }
        .confirmationDialog(
            "Commit this future-only change?",
            isPresented: $showingCommitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Commit change") {
                Task {
                    isSubmitting = true
                    defer { isSubmitting = false }
                    if let result = await model.commitProtocolChange(protocolID: protocolID, draft: draft) {
                        preview = result.preview
                        committedResult = result
                        context = await model.changeStudioContext(protocolID: protocolID)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past logs stay in place. Future occurrences and reminders update from the new revision.")
        }
    }

    @ViewBuilder
    private func changeSpecificFields(context: AtlasProtocolChangeStudioContext) -> some View {
        switch draft.changeType {
        case .futureDose:
            TextField(
                "Dose amount",
                value: Binding(
                    get: { draft.doseAmount ?? 0 },
                    set: { draft.doseAmount = $0 }
                ),
                format: .number
            )
            .changeStudioDecimalKeyboard()
            .atlasStandaloneInputSurface()
            TextField("Dose unit", text: $draft.doseUnit)
                .atlasStandaloneInputSurface()
        case .futureTime:
            DatePicker(
                "Time of day",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
        case .dayOfWeek:
            Picker("Weekday", selection: Binding(
                get: { draft.weekday ?? 1 },
                set: { draft.weekday = $0 }
            )) {
                ForEach(Array(weekdayOptions.enumerated()), id: \.offset) { index, label in
                    Text(label).tag(index)
                }
            }
            DatePicker(
                "Time of day",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
        case .everyNDays:
            Stepper(value: $draft.intervalDays, in: 1...30) {
                Text("Every \(draft.intervalDays) day\(draft.intervalDays == 1 ? "" : "s")")
            }
            DatePicker(
                "Time of day",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
        case .pause, .resume:
            Text("This change only needs an effective date.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        case .titration:
            TextField(
                "Titration amount",
                value: Binding(
                    get: { draft.titrationDoseAmount ?? 0 },
                    set: { draft.titrationDoseAmount = $0 }
                ),
                format: .number
            )
            .changeStudioDecimalKeyboard()
            .atlasStandaloneInputSurface()
            TextField("Titration unit", text: $draft.titrationDoseUnit)
                .atlasStandaloneInputSurface()
            Stepper(value: $draft.titrationLengthDays, in: 1...60) {
                Text("Length \(draft.titrationLengthDays) day\(draft.titrationLengthDays == 1 ? "" : "s")")
            }
            DatePicker(
                "Time of day",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
        case .restPeriod:
            Stepper(value: $draft.restLengthDays, in: 1...60) {
                Text("Rest \(draft.restLengthDays) day\(draft.restLengthDays == 1 ? "" : "s")")
            }
        case .missedDosePolicy:
            Picker("Future recovery", selection: $draft.missedDosePolicy) {
                Text("Skip and continue").tag(AtlasMissedDosePolicy.skipAndContinue)
                Text("Take now, keep cadence").tag(AtlasMissedDosePolicy.takeNowKeepCadence)
                Text("Take now, shift future").tag(AtlasMissedDosePolicy.takeNowShiftFuture)
            }
        case .timezone:
            TextField("Timezone identifier", text: $draft.timezone)
                .changeStudioPlainTextInput()
                .atlasStandaloneInputSurface()
            Picker("Timezone strategy", selection: $draft.timezoneStrategy) {
                Text("Keep local clock").tag(AtlasProtocolTimezoneStrategy.keepLocalClock)
                Text("Keep home timezone").tag(AtlasProtocolTimezoneStrategy.keepHomeTimezone)
            }
        case .vialSwitch:
            Picker("Future vial", selection: Binding(
                get: { draft.linkedVialID ?? "" },
                set: { draft.linkedVialID = $0.isEmpty ? nil : $0 }
            )) {
                Text("Choose a vial").tag("")
                ForEach(context.availableVials.filter { $0.isArchived == false }) { vial in
                    Text("\(vial.label) • \(vial.remainingLabel)").tag(vial.id)
                }
            }
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                atlasParseLocalDateTime(
                    dateValue: changeStudioLocalDateString(draft.effectiveDate),
                    timeOfDay: draft.timeOfDay
                ) ?? model.currentDate()
            },
            set: { newValue in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                draft.timeOfDay = formatter.string(from: newValue)
            }
        )
    }

    private var weekdayOptions: [String] {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    }
}

private struct AtlasCompanionProtocolRow: View {
    let model: AtlasAppModel
    let companion: AtlasProtocolCompanionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(model.renderedTitle(canonical: companion.canonicalTitle, alias: companion.aliasTitle))
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
            Text("\(companion.kindLabel) • \(companion.cadenceLabel)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
            if let doseLabel = companion.doseLabel {
                Text("Dose \(doseLabel)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            if let knowledge = companion.compoundKnowledge {
                Text(knowledge.protocolSummary)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasPlanningChecklistCard: View {
    let item: AtlasProtocolPlanningChecklistItem

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            HStack {
                Text(item.severity.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(item.severityColor)
                Spacer()
                Text(item.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }

            Text(item.detail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(item.severityColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(item.severityColor.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct AtlasChangeStudioTagChip: View {
    let label: String

    var body: some View {
        Text(label)
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.primary)
            .padding(.horizontal, AtlasSpacing.small)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AtlasPalette.secondaryFill)
            )
    }
}

private struct AtlasProtocolCommitCheckCard: View {
    let check: AtlasProtocolCommitCheck

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(check.headline)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            ForEach(check.facts) { fact in
                HStack(spacing: AtlasSpacing.small) {
                    Text(fact.label)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)
                    Spacer()
                    Text(fact.value)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            if check.notes.isEmpty == false {
                Divider()

                ForEach(check.notes, id: \.self) { note in
                    Text(note)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasInteractionWarningCard: View {
    let warning: AtlasInteractionWarning

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            HStack {
                Text(warning.severity.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(severityColor)
                Spacer()
                Text(warning.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }

            Text(warning.detail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(severityColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(severityColor.opacity(0.28), lineWidth: 1)
        )
    }

    private var severityColor: Color {
        switch warning.severity {
        case .advisory:
            AtlasPalette.primary
        case .caution:
            .orange
        case .elevated:
            .red
        }
    }
}

private struct AtlasBeforeAfterRow: View {
    let title: String
    let beforeValue: String
    let afterValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)
            Text("Before: \(beforeValue)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text("After: \(afterValue)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private func parseLeadingNumber(_ value: String) -> Double? {
    let token = value.split(separator: " ").first.map(String.init) ?? ""
    return Double(token)
}

private func parseTrailingUnit(_ value: String) -> String? {
    let tokens = value.split(separator: " ").map(String.init)
    guard tokens.count >= 2 else {
        return nil
    }
    return tokens.dropFirst().joined(separator: " ")
}

private func changeStudioLocalDateString(_ date: Date) -> String {
    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 1970
    let month = String(format: "%02d", components.month ?? 1)
    let day = String(format: "%02d", components.day ?? 1)
    return "\(year)-\(month)-\(day)"
}

private func atlasParseLocalDateTime(dateValue: String, timeOfDay: String) -> Date? {
    let dateParts = dateValue.prefix(10).split(separator: "-").compactMap { Int($0) }
    let timeParts = timeOfDay.split(separator: ":").compactMap { Int($0) }
    guard dateParts.count == 3, timeParts.count >= 2 else {
        return nil
    }

    var components = DateComponents()
    components.year = dateParts[0]
    components.month = dateParts[1]
    components.day = dateParts[2]
    components.hour = timeParts[0]
    components.minute = timeParts[1]
    components.second = 0
    return Calendar.current.date(from: components)
}

struct AtlasProtocolPlanningMove: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let changeType: AtlasProtocolChangeType
}

struct AtlasProtocolPlanningChecklistItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let severity: AtlasInteractionSeverity

    var severityColor: Color {
        switch severity {
        case .advisory:
            return AtlasPalette.primary
        case .caution:
            return .orange
        case .elevated:
            return .red
        }
    }
}

struct AtlasProtocolPlanningSummary: Equatable {
    let headline: String
    let summary: String
    let recommendedMoves: [AtlasProtocolPlanningMove]
    let checklist: [AtlasProtocolPlanningChecklistItem]
}

struct AtlasProtocolCommitCheck: Equatable {
    let headline: String
    let facts: [AtlasExplainerFact]
    let notes: [String]
}

func atlasProtocolPlanningSummary(
    context: AtlasProtocolChangeStudioContext,
    draft: AtlasProtocolChangeDraft
) -> AtlasProtocolPlanningSummary {
    var checklist: [AtlasProtocolPlanningChecklistItem] = [
        AtlasProtocolPlanningChecklistItem(
            id: "effective-date",
            title: "Effective date",
            detail: "Future-only edits begin on \(draft.effectiveDate.formatted(date: .abbreviated, time: .omitted)) and leave past logs untouched.",
            severity: .advisory
        )
    ]

    if draft.changeType == .futureDose || draft.changeType == .titration {
        let hasAmount = draft.changeType == .titration ? draft.titrationDoseAmount != nil : draft.doseAmount != nil
        let unit = draft.changeType == .titration ? draft.titrationDoseUnit : draft.doseUnit
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "dose-explicit",
                title: "Dose and unit",
                detail: hasAmount && unit.isEmpty == false
                    ? "The draft has an explicit amount and unit, so the preview can compare future rows cleanly."
                    : "Set both amount and unit before you preview the future plan.",
                severity: hasAmount && unit.isEmpty == false ? .advisory : .caution
            )
        )
    }

    if draft.changeType == .timezone {
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "timezone",
                title: "Timezone strategy",
                detail: draft.timezone.isEmpty
                    ? "Choose a timezone identifier so travel handling does not fall back to the current device state."
                    : "Uses \(draft.timezoneStrategy.explanationTitle.lowercased()) in \(draft.timezone).",
                severity: draft.timezone.isEmpty ? .caution : .advisory
            )
        )
    }

    if draft.changeType == .vialSwitch {
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "vial",
                title: "Future vial selection",
                detail: draft.linkedVialID == nil
                    ? "Choose the future vial before you preview so inventory and reminder changes stay aligned."
                    : "The preview will rewire future inventory coverage onto the selected vial only.",
                severity: draft.linkedVialID == nil ? .caution : .advisory
            )
        )
    }

    if context.activeCompanions.isEmpty == false {
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "companions",
                title: "Active companions",
                detail: "\(context.activeCompanions.count) other active plan\(context.activeCompanions.count == 1 ? " sits" : "s sit") alongside this one, so preview warnings matter more than usual.",
                severity: .caution
            )
        )
    }

    if context.siteWarnings.isEmpty == false {
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "site-rotation",
                title: "Site rotation",
                detail: context.siteWarnings.first ?? "There is a site rotation reminder for this protocol.",
                severity: .caution
            )
        )
    }

    if draft.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
        checklist.append(
            AtlasProtocolPlanningChecklistItem(
                id: "notes",
                title: "Change note",
                detail: "An optional note helps the timeline explain why this edit happened later without changing the medical meaning of the plan.",
                severity: .advisory
            )
        )
    }

    let headline: String
    let summary: String
    switch draft.changeType {
    case .futureDose:
        headline = "Dose edits work best when the future amount is explicit."
        summary = "Past logs stay in place. Future occurrences regenerate from the effective date after you confirm."
    case .missedDosePolicy:
        headline = "Recovery handling is a planning choice, not an afterthought."
        summary = "Use this to make future misses easier to review."
    case .pause, .resume:
        headline = "Lifecycle changes should stay easy to explain later."
        summary = "A pause or resume will be much easier to trust if the effective date is clean and the preview window shows the future rows you expect."
    case .timezone:
        headline = "Travel changes are easier to trust when the clock rule is explicit."
        summary = "Choose whether the schedule follows the home clock or local time before you save."
    default:
        headline = "Preview the future shape before you commit it."
        summary = "Change Studio is local and future-only, so the goal is making the next schedule shape obvious before it touches reminders or inventory."
    }

    return AtlasProtocolPlanningSummary(
        headline: headline,
        summary: summary,
        recommendedMoves: atlasProtocolPlanningMoves(context: context),
        checklist: checklist
    )
}

func atlasProtocolPlanningMoves(
    context: AtlasProtocolChangeStudioContext
) -> [AtlasProtocolPlanningMove] {
    var moves: [AtlasProtocolPlanningMove] = [
        AtlasProtocolPlanningMove(
            id: AtlasProtocolChangeType.futureDose.rawValue,
            title: "Dose update",
            detail: "Adjust the future amount without touching prior logs.",
            changeType: .futureDose
        ),
        AtlasProtocolPlanningMove(
            id: AtlasProtocolChangeType.futureTime.rawValue,
            title: "Time shift",
            detail: "Move the future time of day while keeping the cadence shape.",
            changeType: .futureTime
        ),
        AtlasProtocolPlanningMove(
            id: AtlasProtocolChangeType.missedDosePolicy.rawValue,
            title: "Recovery rule",
            detail: "Clarify how future missed doses should behave when the week slips.",
            changeType: .missedDosePolicy
        )
    ]

    let cadenceMove: AtlasProtocolPlanningMove
    if context.cadenceLabel.localizedCaseInsensitiveContains("weekly") {
        cadenceMove = AtlasProtocolPlanningMove(
            id: AtlasProtocolChangeType.dayOfWeek.rawValue,
            title: "Weekday move",
            detail: "Shift the weekly anchor to a different day instead of changing the whole cadence.",
            changeType: .dayOfWeek
        )
    } else {
        cadenceMove = AtlasProtocolPlanningMove(
            id: AtlasProtocolChangeType.everyNDays.rawValue,
            title: "Interval change",
            detail: "Move the plan to a fixed every-N-days rhythm.",
            changeType: .everyNDays
        )
    }
    moves.append(cadenceMove)

    if context.availableVials.contains(where: { $0.isArchived == false }) {
        moves.append(
            AtlasProtocolPlanningMove(
                id: AtlasProtocolChangeType.vialSwitch.rawValue,
                title: "Vial handoff",
                detail: "Route future inventory usage onto the right vial before the next run begins.",
                changeType: .vialSwitch
            )
        )
    }

    return Array(moves.prefix(4))
}

func atlasProtocolCommitCheck(preview: AtlasProtocolChangePreview) -> AtlasProtocolCommitCheck? {
    let occurrenceCount = preview.occurrenceChanges.count
    let warningCount = preview.interactionWarnings.count + preview.siteWarnings.count
    let facts = [
        AtlasExplainerFact(label: "Preview window", value: preview.previewWindow.title),
        AtlasExplainerFact(label: "Future rows touched", value: occurrenceCount == 0 ? "None visible" : String(occurrenceCount)),
        AtlasExplainerFact(label: "Reminder result", value: preview.draftReminderLabel ?? "No upcoming reminder"),
        AtlasExplainerFact(label: "Inventory outlook", value: preview.inventoryForecastAfter ?? "No depletion forecast yet")
    ]

    let notes = ([preview.adherenceNote].compactMap { $0 })
        + preview.interactionWarnings.map(\.detail)
        + preview.siteWarnings

    if occurrenceCount == 0 && warningCount == 0 && preview.adherenceNote == nil {
        return AtlasProtocolCommitCheck(
            headline: "The preview is operationally quiet.",
            facts: facts,
            notes: ["No obvious schedule conflicts were found in the selected preview window."]
        )
    }

    return AtlasProtocolCommitCheck(
        headline: warningCount > 0
            ? "This change is plausible, but it deserves one more operational pass."
            : "The preview is readable enough to commit if the future rows look right.",
        facts: facts,
        notes: notes
    )
}

private extension View {
    @ViewBuilder
    func changeStudioInlineNavigationTitle() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    func changeStudioDecimalKeyboard() -> some View {
#if os(iOS)
        keyboardType(.decimalPad)
#else
        self
#endif
    }

    @ViewBuilder
    func changeStudioPlainTextInput() -> some View {
#if os(iOS)
        textInputAutocapitalization(.never)
            .autocorrectionDisabled()
#else
        self
#endif
    }
}

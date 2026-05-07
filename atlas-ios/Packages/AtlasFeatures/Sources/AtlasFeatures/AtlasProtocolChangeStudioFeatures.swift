import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import Foundation
import SwiftUI

extension AtlasAppModel {
    public func changeStudioContext(protocolID: String) async -> AtlasProtocolChangeStudioContext? {
        if protocolID == "mockup-tirzepatide" {
            return AtlasProtocolChangeStudioContext(
                protocolID: protocolID,
                canonicalTitle: "Tirzepatide",
                aliasTitle: nil,
                protocolKind: .glp,
                kindLabel: "GLP",
                cadenceLabel: "Weekly",
                doseLabel: "5.0 mg",
                effectiveTimeOfDay: "12:30",
                currentMissedDosePolicy: .skipAndContinue,
                currentTimezone: TimeZone.current.identifier,
                currentTimezoneStrategy: .keepLocalClock,
                currentLinkedVialID: "mockup-tirzepatide-vial",
                availableVials: [
                    AtlasProtocolChangeVialOption(
                        id: "mockup-tirzepatide-vial",
                        label: "Tirzepatide 10 mg vial",
                        remainingLabel: "12 doses",
                        isArchived: false
                    )
                ],
                siteWarnings: []
            )
        }

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
                ProgressView("Loading plan editor")
            } else if let context {
                let planning = atlasProtocolPlanningSummary(context: context, draft: draft)

                AtlasPlanEditorHeroCard(
                    title: model.renderedTitle(canonical: context.canonicalTitle, alias: context.aliasTitle),
                    detail: "\(context.kindLabel) • \(context.cadenceLabel)",
                    doseLabel: context.doseLabel,
                    changeType: draft.changeType,
                    previewReady: preview != nil
                )

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

                AtlasPlanEditorCard(title: "Change") {
                    AtlasPlanEditorMenuRow(
                        title: "Edit",
                        value: draft.changeType.title,
                        systemImage: "slider.horizontal.3"
                    ) {
                        Picker("Edit", selection: $draft.changeType) {
                            ForEach(AtlasProtocolChangeType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                    }
                    .onChange(of: draft.changeType) { _, _ in
                        preview = nil
                        committedResult = nil
                    }

                    Text(draft.changeType.description)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(2)

                    AtlasPlanEditorDateRow(title: "Effective date", date: $draft.effectiveDate)
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

                AtlasPlanOptionsSection(
                    planning: planning,
                    selectedChangeType: $draft.changeType
                ) {
                    preview = nil
                    committedResult = nil
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
                Text("This plan could not load yet.")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .tint(AtlasPalette.primary)
        .navigationTitle("Plan Editor")
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
            AtlasPlanEditorDoseAmountRow(title: "Dose", value: $draft.doseAmount)
            AtlasPlanEditorTextRow(title: "Unit", text: $draft.doseUnit)
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
            AtlasPlanEditorDoseAmountRow(title: "Dose", value: $draft.titrationDoseAmount)
            AtlasPlanEditorTextRow(title: "Unit", text: $draft.titrationDoseUnit)
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

private struct AtlasPlanEditorHeroCard: View {
    let title: String
    let detail: String
    let doseLabel: String?
    let changeType: AtlasProtocolChangeType
    let previewReady: Bool

    var body: some View {
        AtlasForwardCard(padding: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 34, height: 34)
                        .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                        Text(detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer(minLength: 0)

                    AtlasStatusBadge(previewReady ? "Ready" : "Preview", tint: previewReady ? AtlasPalette.success : AtlasPalette.secondaryText)
                }

                HStack(spacing: 8) {
                    AtlasPlanEditorSignalPill(title: "Change", value: changeType.title, tint: AtlasPalette.primary)
                    AtlasPlanEditorSignalPill(title: "Saved", value: doseLabel ?? "As logged", tint: AtlasPalette.secondaryText)
                }

                Text("Updates future schedule, reminders, and runway. Past logs stay untouched.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AtlasPlanEditorCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        AtlasForwardCard(padding: 10) {
            VStack(alignment: .leading, spacing: 9) {
                if let title {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
                content()
            }
        }
    }
}

private struct AtlasPlanEditorSignalPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text(value)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.42), lineWidth: 1)
        )
    }
}

private struct AtlasPlanEditorMenuRow<MenuContent: View>: View {
    let title: String
    let value: String
    let systemImage: String
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        Menu {
            menuContent()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .frame(width: 28, height: 28)
                    .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)

                Spacer(minLength: 8)

                Text(value)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary.opacity(0.78))
            }
            .padding(9)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.48), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasPlanEditorDoseAmountRow: View {
    let title: String
    @Binding var value: Double?

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Spacer(minLength: 8)

            Button {
                step(by: -0.5)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AtlasPalette.textSecondary)
            .background(AtlasPalette.surfaceMuted, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            TextField("0", text: amountText)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .multilineTextAlignment(.center)
                .foregroundStyle(AtlasPalette.textPrimary)
                .keyboardType(.decimalPad)
                .frame(width: 72, height: 30)
                .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.48), lineWidth: 1)
                )

            Button {
                step(by: 0.5)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AtlasPalette.primary)
            .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(9)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.42), lineWidth: 1)
        )
    }

    private var amountText: Binding<String> {
        Binding(
            get: {
                guard let value else { return "" }
                if value.rounded() == value {
                    return String(Int(value))
                }
                return String(format: "%.1f", value)
            },
            set: { rawValue in
                let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                value = normalized.isEmpty ? nil : Double(normalized)
            }
        )
    }

    private func step(by delta: Double) {
        let nextValue = max(0, (value ?? 0) + delta)
        value = (nextValue * 10).rounded() / 10
    }
}

private struct AtlasPlanEditorTextRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Spacer(minLength: 8)

            TextField("mg", text: $text)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AtlasPalette.primary)
                .frame(maxWidth: 120, minHeight: 30)
        }
        .padding(9)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.42), lineWidth: 1)
        )
    }
}

private struct AtlasPlanEditorDateRow: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Spacer(minLength: 8)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AtlasPalette.primary)
            .scaleEffect(0.78, anchor: .trailing)
            .frame(width: 128, height: 30, alignment: .trailing)
            .clipped()
        }
        .padding(9)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.42), lineWidth: 1)
        )
    }
}

private struct AtlasPlanningChecklistCard: View {
    let item: AtlasProtocolPlanningChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.severity == .advisory ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(item.severityColor)
                .frame(width: 28, height: 28)
                .background(item.severityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)

                Text(item.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AtlasPalette.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.severityColor.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct AtlasPlanOptionsSection: View {
    let planning: AtlasProtocolPlanningSummary
    @Binding var selectedChangeType: AtlasProtocolChangeType
    let onSelectionChanged: () -> Void

    var body: some View {
        AtlasPlanEditorCard(title: "Plan options") {
            VStack(alignment: .leading, spacing: 5) {
                Text(planning.headline)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(planning.summary)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }

            if planning.recommendedMoves.isEmpty == false {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], alignment: .leading, spacing: 8) {
                    ForEach(planning.recommendedMoves.prefix(4)) { move in
                        Button {
                            selectedChangeType = move.changeType
                            onSelectionChanged()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(move.title)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                    .lineLimit(1)
                                Text(move.detail)
                                    .atlasTextRole(.metricLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(move.changeType == selectedChangeType ? AtlasPalette.primary.opacity(0.13) : AtlasPalette.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(move.changeType == selectedChangeType ? AtlasPalette.primary.opacity(0.3) : AtlasPalette.border.opacity(0.38), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if planning.recommendedMoves.count > 4 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(planning.recommendedMoves.dropFirst(4)) { move in
                                Button {
                                    selectedChangeType = move.changeType
                                    onSelectionChanged()
                                } label: {
                                    Text(move.title)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(move.changeType == selectedChangeType ? AtlasPalette.primary : AtlasPalette.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(move.changeType == selectedChangeType ? AtlasPalette.primary.opacity(0.13) : AtlasPalette.surfaceSecondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(AtlasPalette.border.opacity(0.4), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(spacing: 8) {
                    ForEach(Array(planning.checklist.prefix(2))) { item in
                        AtlasPlanningChecklistCard(item: item)
                    }
                }
            }
        }
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(severityColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            detail: "Starts \(draft.effectiveDate.formatted(date: .abbreviated, time: .omitted)); past logs stay untouched.",
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
                    ? "Amount and unit are ready for preview."
                    : "Set both amount and unit before preview.",
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
        headline = "Update upcoming doses only."
        summary = "Past logs stay in place. Preview shows the next schedule before save."
    case .missedDosePolicy:
        headline = "Set the future recovery rule."
        summary = "Keep missed-dose handling simple before the next schedule run."
    case .pause, .resume:
        headline = "Set the next plan state."
        summary = "Choose the effective date, then preview upcoming rows."
    case .timezone:
        headline = "Set the clock rule."
        summary = "Choose home time or local time before saving."
    default:
        headline = "Preview the future plan."
        summary = "Make the next schedule clear before it touches reminders or inventory."
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

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
        List {
            if let error = model.loadErrorMessage {
                Section {
                    Text(error)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            if isLoading {
                Section {
                    ProgressView("Loading Protocol Change Studio")
                }
            } else if let context {
                Section {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(model.renderedTitle(canonical: context.canonicalTitle, alias: context.aliasTitle))
                            .font(.title3.weight(.bold))
                        Text("\(context.kindLabel) • \(context.cadenceLabel)")
                            .foregroundStyle(AtlasPalette.textSecondary)
                        if let doseLabel = context.doseLabel {
                            Text("Current saved amount \(doseLabel)")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .padding(.vertical, AtlasSpacing.small)
                }

                Section("Change") {
                    Picker("Operation", selection: $draft.changeType) {
                        ForEach(AtlasProtocolChangeType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }

                    Text(draft.changeType.description)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    DatePicker(
                        "Effective date",
                        selection: $draft.effectiveDate,
                        displayedComponents: .date
                    )
                }

                Section("Future values") {
                    changeSpecificFields(context: context)
                }

                Section("Preview window") {
                    Picker("Preview window", selection: $draft.previewWindow) {
                        ForEach(AtlasProtocolChangePreviewWindow.allCases) { window in
                            Text(window.title).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField(
                        "Optional change note",
                        text: Binding(
                            get: { draft.notes ?? "" },
                            set: { draft.notes = $0.isEmpty ? nil : $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                }

                Section {
                    Button(preview == nil ? "Build preview" : "Refresh preview") {
                        Task {
                            committedResult = nil
                            preview = await model.previewProtocolChange(protocolID: protocolID, draft: draft)
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }

                if let preview {
                    Section("What changed") {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(preview.summary)
                                .font(.headline)
                            if let adherenceNote = preview.adherenceNote {
                                Text(adherenceNote)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                        .padding(.vertical, AtlasSpacing.xSmall)
                    }

                    Section("Impact") {
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

                    Section("Future occurrences") {
                        if preview.occurrenceChanges.isEmpty {
                            Text("No visible future occurrence changes inside this preview window.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(preview.occurrenceChanges) { change in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(change.kind.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.primary)
                                    if let beforeLabel = change.beforeLabel {
                                        Text("Before: \(beforeLabel)")
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    if let afterLabel = change.afterLabel {
                                        Text("After: \(afterLabel)")
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    if preview.siteWarnings.isEmpty == false {
                        Section("Site rotation") {
                            ForEach(preview.siteWarnings, id: \.self) { warning in
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    Section {
                        Button("Commit change") {
                            showingCommitConfirmation = true
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .disabled(isSubmitting)
                    }
                }

                if let committedResult {
                    Section("Commit summary") {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(committedResult.impactSummary.title)
                                .font(.headline)
                            ForEach(committedResult.impactSummary.facts) { fact in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(fact.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.primary)
                                    Text(fact.value)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                            ForEach(committedResult.impactSummary.notes, id: \.self) { note in
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                        .padding(.vertical, AtlasSpacing.xSmall)
                    }

                    Section {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
            } else {
                Section {
                    Text("Atlas could not load this protocol yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
        .atlasFormSurface()
        .listStyle(.plain)
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
            Text("Atlas will preserve past logs, regenerate future occurrences from the new effective revision, and refresh reminders for affected future occurrences.")
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
            TextField("Dose unit", text: $draft.doseUnit)
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
            TextField("Titration unit", text: $draft.titrationDoseUnit)
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

private struct AtlasBeforeAfterRow: View {
    let title: String
    let beforeValue: String
    let afterValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
            Text("Before: \(beforeValue)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text("After: \(afterValue)")
                .font(.caption)
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

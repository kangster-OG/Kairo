import AtlasDesignSystem
import AtlasDomain
import Charts
import Foundation
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AtlasProgressEvidenceScreen: View {
    let model: AtlasAppModel

    @State private var measurementSheetPresented = false
    @State private var photoSheetPresented = false
    @State private var measurementDraft = AtlasProgressMeasurementDraft()
    @State private var measurementValueText = ""
    @State private var shareArtifact: AtlasProgressEvidenceExportArtifact?
    @State private var exportErrorMessage: String?
    @State private var selectedCompareAngle: AtlasProgressPhotoAngle = .front
    @State private var compareWindow: AtlasProgressCompareWindow = .month
    @State private var compareReveal: CGFloat = 0.5
    @State private var timelineMode: AtlasProgressTimelineMode = .month
    @State private var mascotCourtesySignal = 0
    @State private var mascotContentNoticeTrigger = 0

    public var body: some View {
        let snapshot = model.insightsSnapshot.progressEvidence
        let compareCandidate = atlasProgressCompareCandidate(
            snapshot: snapshot,
            angle: selectedCompareAngle,
            window: compareWindow
        )
        let ambientMascotSelection = atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot)
        let ambientMascotStage = atlasAmbientMascotStage(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot
        )
        let ambientMascotMilestoneNearby = atlasAmbientMascotMilestoneNearby(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot,
            pendingCelebration: model.pendingMascotCelebration
        )
        let exportContext = atlasProgressEvidenceExportContext(
            model: model,
            compareCandidate: compareCandidate
        )
        let timelineSections = atlasProgressTimelineSections(
            snapshot: snapshot,
            weightTrend: model.insightsSnapshot.weightTrend,
            mode: timelineMode
        )
        let noticeState = AtlasProgressEvidenceMascotNoticeState(
            snapshot: snapshot,
            hasCompareCandidate: compareCandidate != nil,
            timelineSectionCount: timelineSections.count
        )

        AtlasScreen {
            AtlasTabHeader(
                title: "Progress Evidence",
                subtitle: nil,
                fullBleed: false
            )

            AtlasSectionCard(title: snapshot.summaryTitle) {
                Text(snapshot.summaryText)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if let comparisonNote = snapshot.comparisonNote {
                    Text(comparisonNote)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasProgressStorySummaryRow(
                    snapshot: snapshot,
                    exportContext: exportContext,
                    compareCandidate: compareCandidate
                )

                Text(atlasProgressNextStepNote(snapshot: snapshot, compareCandidate: compareCandidate))
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                HStack(spacing: AtlasSpacing.small) {
                    Button("Add measurement") {
                        mascotCourtesySignal &+= 1
                        measurementDraft = AtlasProgressMeasurementDraft(loggedAt: model.currentDate())
                        measurementValueText = ""
                        measurementSheetPresented = true
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Add photo") {
                        mascotCourtesySignal &+= 1
                        photoSheetPresented = true
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }

                Button("Export evidence summary") {
                    mascotCourtesySignal &+= 1
                    do {
                        shareArtifact = try atlasCreateProgressEvidenceExportArtifact(
                            snapshot: snapshot,
                            exportContext: exportContext,
                            now: model.currentDate()
                        )
                        model.triggerAmbientMascotReaction(.artifactReady)
                        exportErrorMessage = nil
                    } catch {
                        exportErrorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
            .overlay(alignment: .topTrailing) {
                if let ambientMascotSelection,
                   let ambientMascotStage {
                    AtlasAmbientMascotPerch(
                        selection: ambientMascotSelection,
                        stage: ambientMascotStage,
                        presence: model.settingsSnapshot.ambientMascotPresence,
                        placement: .cardCorner,
                        context: .progressEvidence,
                        size: 60,
                        courtesySignal: mascotCourtesySignal,
                        contentNoticeTrigger: mascotContentNoticeTrigger,
                        suppression: atlasAmbientMascotSuppression(
                            presentingSheet: model.pendingMascotCelebration != nil,
                            presentingExport: shareArtifact != nil,
                            denseEntryActive: measurementSheetPresented || photoSheetPresented
                        ),
                        reactionSignal: model.ambientMascotReactionSignal,
                        milestoneNearby: ambientMascotMilestoneNearby
                    )
                    .offset(x: -12, y: -10)
                }
            }

            AtlasProgressSectionHeader(title: "Compare")
            AtlasSectionCard(title: "Before / after") {
                VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                    Text("Match the same angle across a meaningful time window.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Picker("Angle", selection: $selectedCompareAngle) {
                        ForEach(AtlasProgressPhotoAngle.allCases) { angle in
                            Text(angle.title).tag(angle)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Window", selection: $compareWindow) {
                        ForEach(AtlasProgressCompareWindow.allCases) { window in
                            Text(window.title).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let compareCandidate {
                        AtlasProgressCompareCard(
                            candidate: compareCandidate,
                            reveal: $compareReveal
                        )
                    } else {
                        Text("Add at least two \(selectedCompareAngle.title.lowercased()) check-ins to unlock the compare view.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }

            AtlasProgressSectionHeader(title: "Timeline")
            AtlasSectionCard(title: "Milestone timeline") {
                VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                    Text("Review photos by time bucket or weight milestone so visual progress feels deliberate, not buried.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Picker("Mode", selection: $timelineMode) {
                        ForEach(AtlasProgressTimelineMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if timelineSections.isEmpty {
                        Text("This timeline will fill in as more visual check-ins or weight milestones accumulate.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        ForEach(timelineSections) { section in
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Text(section.title)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(section.subtitle)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AtlasSpacing.small) {
                                        ForEach(section.photos) { photo in
                                            AtlasProgressPhotoTile(photo: photo)
                                                .frame(width: 132)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            AtlasProgressSectionHeader(title: "Measurements")
            if snapshot.measurementTrends.isEmpty {
                AtlasSectionCard {
                    Text("No measurement check-ins yet.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            } else {
                ForEach(snapshot.measurementTrends) { trend in
                    AtlasSectionCard(title: trend.kind.title) {
                        Chart(trend.points) { point in
                            LineMark(
                                x: .value("Date", point.loggedAt),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(AtlasPalette.primary)

                            PointMark(
                                x: .value("Date", point.loggedAt),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(AtlasPalette.primary)
                        }
                        .frame(height: 160)

                        if let latestLabel = trend.latestLabel {
                            Text(latestLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        if let changeLabel = trend.changeLabel {
                            Text(changeLabel)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }

            AtlasProgressSectionHeader(title: "Photo Journal")
            if snapshot.recentPhotos.count >= 2 {
                AtlasSectionCard(title: "Latest compare") {
                    HStack(alignment: .top, spacing: AtlasSpacing.small) {
                        AtlasProgressPhotoTile(photo: snapshot.recentPhotos[0])
                        AtlasProgressPhotoTile(photo: snapshot.recentPhotos[1])
                    }
                }
            }

            if snapshot.recentPhotos.isEmpty {
                AtlasSectionCard {
                    Text("No private photo check-ins yet.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            } else {
                ForEach(snapshot.recentPhotos) { photo in
                    AtlasSectionCard {
                        HStack(alignment: .top, spacing: AtlasSpacing.small) {
                            AtlasProgressPhotoImage(path: photo.absolutePath)
                                .frame(width: 96, height: 112)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(photo.angle.title)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                if let note = photo.note, note.isEmpty == false {
                                    Text(note)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .navigationTitle("Progress Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .atlasAmbientMascotOpenReaction(model: model, kind: .openedSurface)
        .onChange(of: noticeState) { oldValue, newValue in
            guard oldValue != newValue else {
                return
            }
            let gainedCompare = oldValue.hasCompareCandidate == false && newValue.hasCompareCandidate
            let gainedPhoto = newValue.photoCount > oldValue.photoCount
            let gainedMeasurement = newValue.measurementCount > oldValue.measurementCount
            let gainedTimeline = oldValue.timelineSectionCount == 0 && newValue.timelineSectionCount > 0

            if gainedCompare || gainedPhoto || gainedMeasurement || gainedTimeline {
                mascotContentNoticeTrigger &+= 1
            }
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: selectedCompareAngle)
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: compareWindow)
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: timelineMode)
        .sheet(isPresented: $measurementSheetPresented) {
            NavigationStack {
                AtlasScreen {
                    AtlasCommandDeck(
                        eyebrow: "Add measurement",
                        title: measurementDraft.kind.title,
                        detail: "Use consistent measurement labels and units over time.",
                        metrics: [
                            AtlasMetricItem(id: "unit", title: "Unit", value: measurementDraft.unit, tint: AtlasPalette.primary),
                            AtlasMetricItem(id: "value", title: "Value", value: measurementValueText.isEmpty ? "Pending" : measurementValueText, tint: Double(measurementValueText) == nil ? AtlasPalette.warning : AtlasPalette.success)
                        ],
                        tint: AtlasPalette.primary,
                        style: .hero
                    ) { } footer: {
                        Text("Measurements work best when the same unit and body site are used consistently across check-ins.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    AtlasSectionCard(style: .task, title: "Entry") {
                    Picker("Measure", selection: $measurementDraft.kind) {
                        ForEach(AtlasProgressMeasurementKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .onChange(of: measurementDraft.kind) { _, newValue in
                        measurementDraft.unit = newValue.defaultUnit
                    }

                    TextField("Value", text: $measurementValueText)
                        .keyboardType(.decimalPad)
                        .atlasStandaloneInputSurface()
                    TextField("Unit", text: $measurementDraft.unit)
                        .atlasStandaloneInputSurface()
                    DatePicker("Logged at", selection: $measurementDraft.loggedAt)
                    TextField("Optional note", text: Binding(
                        get: { measurementDraft.note ?? "" },
                        set: { measurementDraft.note = $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                    }

                    AtlasSectionCard(style: .utility, title: "Commit") {
                        Button("Save") {
                            AtlasFeedback.selection()
                            guard let value = Double(measurementValueText) else {
                                return
                            }
                            measurementDraft.value = value
                            Task {
                                await model.saveProgressMeasurement(measurementDraft)
                                measurementSheetPresented = false
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .disabled(Double(measurementValueText) == nil)

                        Button("Cancel") {
                            AtlasFeedback.selection()
                            measurementSheetPresented = false
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
                .navigationTitle("Add measurement")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            AtlasFeedback.selection()
                            measurementSheetPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            AtlasFeedback.selection()
                            guard let value = Double(measurementValueText) else {
                                return
                            }
                            measurementDraft.value = value
                            Task {
                                await model.saveProgressMeasurement(measurementDraft)
                                measurementSheetPresented = false
                            }
                        }
                        .disabled(Double(measurementValueText) == nil)
                    }
                }
            }
        }
        .sheet(isPresented: $photoSheetPresented) {
            AtlasProgressPhotoComposerScreen(model: model) {
                photoSheetPresented = false
            }
        }
        .sheet(item: $shareArtifact) { artifact in
            AtlasProgressEvidenceShareSheet(fileURL: artifact.fileURL)
        }
        .alert(
            "Progress export unavailable",
            isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if $0 == false { exportErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { exportErrorMessage = nil }
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }
}

private struct AtlasProgressPhotoComposerScreen: View {
    let model: AtlasAppModel
    let onDismiss: () -> Void

    @State private var draft = AtlasProgressPhotoDraft(jpegData: Data())
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData = Data()
    @State private var guidedOverlayEnabled = true

    var body: some View {
        let referencePhoto = model.insightsSnapshot.progressEvidence.recentPhotos.first(where: { $0.angle == draft.angle })

        NavigationStack {
            AtlasScreen {
                if let referencePhoto {
                    AtlasCommandDeck(
                        eyebrow: "Add photo",
                        title: draft.angle.title,
                        detail: "Match the framing as closely as you can.",
                        metrics: [
                            AtlasMetricItem(id: "angle", title: "Angle", value: draft.angle.title, tint: AtlasPalette.primary),
                            AtlasMetricItem(id: "reference", title: "Reference", value: guidedOverlayEnabled ? "Overlay on" : "Overlay off", tint: guidedOverlayEnabled ? AtlasPalette.success : AtlasPalette.secondaryText)
                        ],
                        tint: AtlasPalette.primary,
                        style: .hero
                    ) {
                        AtlasProgressPhotoImage(path: referencePhoto.absolutePath)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(alignment: .bottomLeading) {
                                Text("Reference")
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.42), in: Capsule())
                                    .padding(12)
                            }
                    } footer: {
                        Toggle("Overlay reference on preview", isOn: $guidedOverlayEnabled)
                    }
                } else {
                    AtlasCommandDeck(
                        eyebrow: "Add photo",
                        title: draft.angle.title,
                        detail: "Start a private photo record for this angle.",
                        metrics: [
                            AtlasMetricItem(id: "angle", title: "Angle", value: draft.angle.title, tint: AtlasPalette.primary),
                            AtlasMetricItem(id: "selected", title: "Photo", value: imageData.isEmpty ? "Pending" : "Ready", tint: imageData.isEmpty ? AtlasPalette.warning : AtlasPalette.success)
                        ],
                        tint: AtlasPalette.primary,
                        style: .hero
                    ) { } footer: { }
                }

                AtlasSectionCard(style: .utility, title: "Capture notes") {
                    VStack(alignment: .leading, spacing: 10) {
                        AtlasProgressCaptureTipRow(
                            title: "Match distance",
                            detail: "Try to keep the phone and crop close to the previous frame."
                        )
                        AtlasProgressCaptureTipRow(
                            title: "Repeat posture",
                            detail: "A calmer pose gives the compare view a much cleaner story later."
                        )
                        AtlasProgressCaptureTipRow(
                            title: "Keep it descriptive",
                            detail: "Photos are stored as private records only."
                        )
                    }
                }

                AtlasSectionCard(style: .task, title: "Capture") {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    if imageData.isEmpty == false {
                        ZStack {
                            if guidedOverlayEnabled, let referencePhoto {
                                AtlasProgressPhotoImage(path: referencePhoto.absolutePath)
                                    .opacity(0.24)
                            }

                            AtlasProgressPhotoImage(data: imageData)
                                .opacity(guidedOverlayEnabled && referencePhoto != nil ? 0.88 : 1)
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    Picker("Angle", selection: $draft.angle) {
                        ForEach(AtlasProgressPhotoAngle.allCases) { angle in
                            Text(angle.title).tag(angle)
                        }
                    }
                    DatePicker("Logged at", selection: $draft.loggedAt)
                    TextField("Optional note", text: Binding(
                        get: { draft.note ?? "" },
                        set: { draft.note = $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save") {
                        AtlasFeedback.selection()
                        draft.jpegData = imageData
                        Task {
                            await model.saveProgressPhoto(draft)
                            onDismiss()
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(imageData.isEmpty)

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        onDismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle("Add photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        AtlasFeedback.selection()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AtlasFeedback.selection()
                        draft.jpegData = imageData
                        Task {
                            await model.saveProgressPhoto(draft)
                            onDismiss()
                        }
                    }
                    .disabled(imageData.isEmpty)
                }
            }
        }
        .task(id: selectedItem) {
            guard let selectedItem else {
                return
            }
            if let data = try? await selectedItem.loadTransferable(type: Data.self),
               let jpegData = atlasNormalizedJPEGData(from: data) {
                imageData = jpegData
            }
        }
    }
}

private struct AtlasProgressStorySummaryRow: View {
    let snapshot: AtlasProgressEvidenceSnapshot
    let exportContext: AtlasProgressEvidenceExportContext
    let compareCandidate: AtlasProgressCompareCandidate?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.small) {
                AtlasStatusBadge("\(snapshot.recentPhotos.count) photo\(snapshot.recentPhotos.count == 1 ? "" : "s")", tint: AtlasPalette.primary)
                AtlasStatusBadge("\(snapshot.recentMeasurements.count) measurement\(snapshot.recentMeasurements.count == 1 ? "" : "s")", tint: AtlasPalette.secondaryText)
                if let compareCandidate {
                    AtlasStatusBadge(atlasProgressElapsedLabel(for: compareCandidate), tint: AtlasPalette.primary)
                } else {
                    AtlasStatusBadge("Compare still building", tint: AtlasPalette.secondaryText)
                }
                if let weightLatestLabel = exportContext.weightLatestLabel {
                    AtlasStatusBadge(weightLatestLabel, tint: AtlasPalette.secondaryText)
                }
            }
        }
    }
}

private struct AtlasProgressEvidenceMascotNoticeState: Equatable {
    let measurementCount: Int
    let photoCount: Int
    let hasCompareCandidate: Bool
    let timelineSectionCount: Int

    init(
        snapshot: AtlasProgressEvidenceSnapshot,
        hasCompareCandidate: Bool,
        timelineSectionCount: Int
    ) {
        measurementCount = snapshot.measurementTrends.reduce(into: 0) { partialResult, trend in
            partialResult += trend.points.count
        }
        photoCount = snapshot.recentPhotos.count
        self.hasCompareCandidate = hasCompareCandidate
        self.timelineSectionCount = timelineSectionCount
    }
}

private struct AtlasProgressSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AtlasSpacing.small)
    }
}

private struct AtlasProgressCaptureTipRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasProgressPhotoTile: View {
    let photo: AtlasProgressPhotoEntrySummary

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            AtlasProgressPhotoImage(path: photo.absolutePath)
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(photo.angle.title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasProgressPhotoImage: View {
    var path: String?
    var data: Data?

    init(path: String) {
        self.path = path
        self.data = nil
    }

    init(data: Data) {
        self.path = nil
        self.data = data
    }

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AtlasPalette.primary.opacity(0.12))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
            }
            #else
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AtlasPalette.primary.opacity(0.12))
            #endif
        }
    }

    #if canImport(UIKit)
    private var uiImage: UIImage? {
        if let data, let image = UIImage(data: data) {
            return image
        }
        if let path {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    #endif
}

public struct AtlasProgressEvidenceExportArtifact: Identifiable, Sendable {
    public var id: String
    public var fileURL: URL
    public var title: String
}

private func atlasCreateProgressEvidenceExportArtifact(
    snapshot: AtlasProgressEvidenceSnapshot,
    exportContext: AtlasProgressEvidenceExportContext,
    now: Date
) throws -> AtlasProgressEvidenceExportArtifact {
    let supportDirectory = try FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first
        .map { $0.appendingPathComponent("AtlasProgressEvidenceExports", isDirectory: true) }
        .unwrapOrThrow(CocoaError(.fileNoSuchFile))
    if FileManager.default.fileExists(atPath: supportDirectory.path) == false {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
    }

    let fileURL = supportDirectory.appendingPathComponent("atlas-progress-evidence-\(atlasProgressEvidenceTimestamp(now)).html")
    try atlasProgressEvidenceHTML(snapshot: snapshot, exportContext: exportContext, generatedAt: now).write(to: fileURL, atomically: true, encoding: .utf8)

    return AtlasProgressEvidenceExportArtifact(
        id: fileURL.lastPathComponent,
        fileURL: fileURL,
        title: "Progress Evidence"
    )
}

private func atlasProgressEvidenceHTML(
    snapshot: AtlasProgressEvidenceSnapshot,
    exportContext: AtlasProgressEvidenceExportContext,
    generatedAt: Date
) -> String {
    let trendBlocks = snapshot.measurementTrends.map { trend in
        "<li><strong>\(trend.kind.title):</strong> \(trend.latestLabel ?? "No entries") \(trend.changeLabel.map { "(\($0))" } ?? "")</li>"
    }.joined()

    let photoBlocks = snapshot.recentPhotos.prefix(2).compactMap { photo -> String? in
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: photo.absolutePath)) else {
            return nil
        }
        return """
        <div style=\"margin-bottom:24px;\">
          <h3>\(photo.angle.title) • \(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))</h3>
          <img src=\"data:image/jpeg;base64,\(data.base64EncodedString())\" style=\"max-width:100%;border-radius:20px;\" />
          <p>\(photo.note ?? "")</p>
        </div>
        """
    }.joined()

    let highlightCards = [
        exportContext.weightLatestLabel.map { ("Latest weight", $0) },
        exportContext.weightChangeLabel.map { ("Trend", $0) },
        exportContext.mascotHeadline.map { ("Mascot", $0) },
        exportContext.mascotDetail.map { ("Momentum", $0) }
    ]
    .compactMap { $0 }
    .map { title, value in
        """
        <div class=\"pill-card\">
          <span class=\"eyebrow\">\(title)</span>
          <strong>\(value)</strong>
        </div>
        """
    }
    .joined()

    let compareSummary = exportContext.compareSummary.map {
        "<p><strong>Visual compare:</strong> \($0)</p>"
    } ?? ""

    return """
    <html>
    <head>
      <meta charset=\"utf-8\" />
      <title>Atlas Progress Evidence</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 32px; color: #14202b; background: linear-gradient(180deg, #f3eddf 0%, #f7f8fb 100%); }
        .card { background: rgba(255,255,255,0.95); border-radius: 28px; padding: 28px; margin-bottom: 24px; box-shadow: 0 12px 36px rgba(20,32,43,0.10); }
        .hero { background: linear-gradient(135deg, #17324a 0%, #29587a 52%, #f0c47a 100%); color: white; }
        .hero p, .hero strong, .hero h1 { color: white; }
        .pill-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-top: 18px; }
        .pill-card { padding: 16px; border-radius: 18px; background: rgba(255,255,255,0.16); }
        .eyebrow { display: block; font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; opacity: 0.82; margin-bottom: 6px; }
      </style>
    </head>
    <body>
      <div class=\"card hero\">
        <h1>\(snapshot.summaryTitle)</h1>
        <p>\(snapshot.summaryText)</p>
        <p><strong>Generated:</strong> \(generatedAt.formatted(date: .abbreviated, time: .shortened))</p>
        <p><strong>Trust note:</strong> Photos are visual records only.</p>
        \(compareSummary)
        <div class=\"pill-grid\">\(highlightCards)</div>
      </div>
      <div class=\"card\">
        <h2>Measurements</h2>
        <ul>\(trendBlocks)</ul>
      </div>
      <div class=\"card\">
        <h2>Latest photo evidence</h2>
        \(photoBlocks.isEmpty ? "<p>No private photo check-ins were available in this export.</p>" : photoBlocks)
      </div>
    </body>
    </html>
    """
}

private func atlasProgressEvidenceTimestamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: date)
}

private struct AtlasProgressCompareCandidate {
    let angle: AtlasProgressPhotoAngle
    let current: AtlasProgressPhotoEntrySummary
    let baseline: AtlasProgressPhotoEntrySummary
    let summary: String
}

private enum AtlasProgressCompareWindow: String, CaseIterable, Identifiable {
    case month
    case quarter
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: "4w"
        case .quarter: "12w"
        case .all: "All"
        }
    }
}

private enum AtlasProgressTimelineMode: String, CaseIterable, Identifiable {
    case week
    case month
    case milestone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .milestone: "Milestone"
        }
    }
}

private struct AtlasProgressTimelineSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let photos: [AtlasProgressPhotoEntrySummary]
}

private struct AtlasProgressEvidenceExportContext {
    var weightLatestLabel: String? = nil
    var weightChangeLabel: String? = nil
    var mascotHeadline: String? = nil
    var mascotDetail: String? = nil
    var compareSummary: String? = nil
}

private struct AtlasProgressCompareCard: View {
    let candidate: AtlasProgressCompareCandidate
    @Binding var reveal: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            Text(candidate.summary)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            HStack(spacing: AtlasSpacing.small) {
                AtlasStatusBadge(atlasProgressElapsedLabel(for: candidate), tint: AtlasPalette.primary)
                AtlasStatusBadge(candidate.angle.title, tint: AtlasPalette.secondaryText)
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                let clampedReveal = min(max(reveal, 0.08), 0.92)

                ZStack(alignment: .leading) {
                    AtlasProgressPhotoImage(path: candidate.baseline.absolutePath)
                        .frame(width: width, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    AtlasProgressPhotoImage(path: candidate.current.absolutePath)
                        .frame(width: width * clampedReveal, height: 260, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Rectangle()
                        .fill(.white.opacity(0.92))
                        .frame(width: 3, height: 260)
                        .offset(x: width * clampedReveal)
                }
            }
            .frame(height: 260)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Before")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(candidate.baseline.loggedAt.formatted(date: .abbreviated, time: .omitted))
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("After")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(candidate.current.loggedAt.formatted(date: .abbreviated, time: .omitted))
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }

            Slider(value: Binding(
                get: { Double(reveal) },
                set: { reveal = CGFloat($0) }
            ), in: 0.08...0.92)
            .tint(AtlasPalette.primary)

            Text("Drag slowly to compare the same frame.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private func atlasProgressCompareCandidate(
    snapshot: AtlasProgressEvidenceSnapshot,
    angle: AtlasProgressPhotoAngle,
    window: AtlasProgressCompareWindow
) -> AtlasProgressCompareCandidate? {
    let photos = snapshot.recentPhotos
        .filter { $0.angle == angle }
        .sorted { $0.loggedAt > $1.loggedAt }
    guard let current = photos.first else {
        return nil
    }

    let baseline: AtlasProgressPhotoEntrySummary?
    switch window {
    case .month:
        baseline = photos.dropFirst().first(where: { Calendar.current.dateComponents([.day], from: $0.loggedAt, to: current.loggedAt).day ?? 0 >= 28 }) ?? photos.last
    case .quarter:
        baseline = photos.dropFirst().first(where: { Calendar.current.dateComponents([.day], from: $0.loggedAt, to: current.loggedAt).day ?? 0 >= 84 }) ?? photos.last
    case .all:
        baseline = photos.last
    }

    guard let baseline, baseline.id != current.id else {
        return nil
    }

    return AtlasProgressCompareCandidate(
        angle: angle,
        current: current,
        baseline: baseline,
        summary: "\(angle.title) compare from \(baseline.loggedAt.formatted(date: .abbreviated, time: .omitted)) to \(current.loggedAt.formatted(date: .abbreviated, time: .omitted))."
    )
}

private func atlasProgressElapsedLabel(for candidate: AtlasProgressCompareCandidate) -> String {
    let dayCount = max(Calendar.current.dateComponents([.day], from: candidate.baseline.loggedAt, to: candidate.current.loggedAt).day ?? 0, 0)
    if dayCount >= 7 {
        let weeks = max(dayCount / 7, 1)
        return "\(weeks) week\(weeks == 1 ? "" : "s") apart"
    }
    return "\(max(dayCount, 1)) day\(dayCount == 1 ? "" : "s") apart"
}

private func atlasProgressNextStepNote(
    snapshot: AtlasProgressEvidenceSnapshot,
    compareCandidate: AtlasProgressCompareCandidate?
) -> String {
    if compareCandidate != nil {
        return "The compare view is ready. Add another matched frame only when the next visual checkpoint would tell a clearer story."
    }

    if snapshot.recentPhotos.isEmpty {
        return "Start with one baseline photo now, then repeat the same angle in a couple of weeks for the first compare."
    }

    if snapshot.recentPhotos.count == 1 {
        return "One frame is in place. Add the next matching angle to compare."
    }

    return "Keep adding the same angles to build a usable timeline."
}

private func atlasProgressTimelineSections(
    snapshot: AtlasProgressEvidenceSnapshot,
    weightTrend: AtlasWeightTrendSummary,
    mode: AtlasProgressTimelineMode
) -> [AtlasProgressTimelineSection] {
    let calendar = Calendar.current

    switch mode {
    case .week:
        let grouped = Dictionary(grouping: snapshot.recentPhotos) { photo in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: photo.loggedAt)
            return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
        }
        return grouped.keys.sorted(by: >).compactMap { key in
            guard let photos = grouped[key]?.sorted(by: { $0.loggedAt > $1.loggedAt }) else {
                return nil
            }
            let labelDate = photos.first?.loggedAt ?? .now
            return AtlasProgressTimelineSection(
                id: key,
                title: "Week of \(labelDate.formatted(date: .abbreviated, time: .omitted))",
                subtitle: "\(photos.count) visual check-in(s)",
                photos: Array(photos.prefix(4))
            )
        }
    case .month:
        let grouped = Dictionary(grouping: snapshot.recentPhotos) { photo in
            let components = calendar.dateComponents([.year, .month], from: photo.loggedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }
        return grouped.keys.sorted(by: >).compactMap { key in
            guard let photos = grouped[key]?.sorted(by: { $0.loggedAt > $1.loggedAt }) else {
                return nil
            }
            let labelDate = photos.first?.loggedAt ?? .now
            return AtlasProgressTimelineSection(
                id: key,
                title: labelDate.formatted(.dateTime.month(.wide).year()),
                subtitle: "\(photos.count) check-in(s) stored locally",
                photos: Array(photos.prefix(4))
            )
        }
    case .milestone:
        let milestoneSections = atlasWeightMilestoneSections(weightTrend: weightTrend, photos: snapshot.recentPhotos)
        return milestoneSections.isEmpty
            ? atlasProgressTimelineSections(snapshot: snapshot, weightTrend: weightTrend, mode: .month)
            : milestoneSections
    }
}

private func atlasWeightMilestoneSections(
    weightTrend: AtlasWeightTrendSummary,
    photos: [AtlasProgressPhotoEntrySummary]
) -> [AtlasProgressTimelineSection] {
    guard let latest = weightTrend.points.last?.value,
          let earliest = weightTrend.points.first?.value else {
        return []
    }

    let change = latest - earliest
    let bucketCount = Int(abs(change) / 5)
    guard bucketCount > 0 else {
        return []
    }

    let sortedPhotos = photos.sorted { $0.loggedAt > $1.loggedAt }
    return (1...bucketCount).compactMap { index in
        let title = change < 0 ? "\(index * 5) unit drop" : "\(index * 5) unit climb"
        let slice = Array(sortedPhotos.dropFirst((index - 1) * 2).prefix(2))
        guard slice.isEmpty == false else {
            return nil
        }
        return AtlasProgressTimelineSection(
            id: "milestone-\(index)",
            title: title,
            subtitle: "Weight milestones paired with nearby progress photos.",
            photos: slice
        )
    }
}

@MainActor
private func atlasProgressEvidenceExportContext(
    model: AtlasAppModel,
    compareCandidate: AtlasProgressCompareCandidate?
) -> AtlasProgressEvidenceExportContext {
    let evolution = atlasRewardsEvolutionProgress(
        for: model.rewardsSnapshot,
        selection: model.settingsSnapshot.mascotSelection
    )

    return AtlasProgressEvidenceExportContext(
        weightLatestLabel: model.insightsSnapshot.weightTrend.latestLabel,
        weightChangeLabel: model.insightsSnapshot.weightTrend.changeLabel,
        mascotHeadline: model.rewardsSnapshot.settings.enabled ? evolution.milestoneHeadline : nil,
        mascotDetail: model.rewardsSnapshot.settings.enabled ? evolution.progressLabel : nil,
        compareSummary: compareCandidate?.summary
    )
}

#if canImport(UIKit)
private struct AtlasProgressEvidenceShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

private extension Optional {
    func unwrapOrThrow(_ error: Error) throws -> Wrapped {
        if let value = self {
            return value
        }
        throw error
    }
}

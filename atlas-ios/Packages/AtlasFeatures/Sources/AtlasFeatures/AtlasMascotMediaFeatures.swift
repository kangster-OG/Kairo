import AtlasDesignSystem
import AtlasDomain
import SwiftUI
import UIKit

public enum AtlasMascotRecapCardKind: String, CaseIterable, Identifiable, Sendable {
    case weeklyRecap = "weekly_recap"
    case evolutionMilestone = "evolution_milestone"
    case latestMoment = "latest_moment"

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .weeklyRecap:
            return "Weekly recap"
        case .evolutionMilestone:
            return "Evolution milestone"
        case .latestMoment:
            return "Latest moment"
        }
    }

    var subtitle: String {
        switch self {
        case .weeklyRecap:
            return "Current progress snapshot with rewards momentum and next target."
        case .evolutionMilestone:
            return "Portrait-first share card for the latest unlocked form or next evolution."
        case .latestMoment:
            return "Share the freshest mascot reaction or journal moment as a clean PNG card."
        }
    }
}

public struct AtlasMascotRecapDescriptor: Equatable, Identifiable, Sendable {
    public var id: String {
        "\(kind.rawValue)-\(audience.rawValue)-\(privacyMode.rawValue)-\(selection.rawValue)-\(stage.rawValue)-\(headline)"
    }

    public let kind: AtlasMascotRecapCardKind
    public let audience: AtlasMascotRecapAudience
    public let privacyMode: AtlasMascotRecapPrivacyMode
    public let selection: AtlasMascotSelection
    public let stage: AtlasMascotStage
    public let displayName: String
    public let currentFormName: String
    public let eyebrow: String
    public let headline: String
    public let detail: String
    public let secondaryDetail: String
    public let footer: String
    public let symbolName: String
}

public struct AtlasMascotExportArtifact: Identifiable, Sendable {
    public let descriptor: AtlasMascotRecapDescriptor
    public let fileURL: URL
    public let archiveRecord: AtlasMascotArchivedRecapRecord

    public var id: String { fileURL.path }
}

enum AtlasMascotExportError: LocalizedError {
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Atlas could not render this mascot recap card right now."
        }
    }
}

public func atlasMascotRecapDescriptor(
    kind: AtlasMascotRecapCardKind,
    audience: AtlasMascotRecapAudience,
    privacyMode: AtlasMascotRecapPrivacyMode,
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolutionHistory: [AtlasMascotEvolutionRecord],
    moments: [AtlasMascotMomentRecord]
) -> AtlasMascotRecapDescriptor {
    let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
    let stage = evolution.stage
    let rawDisplayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let displayName = atlasMascotExportDisplayName(
        rawDisplayName: rawDisplayName,
        selection: selection,
        stage: stage,
        privacyMode: privacyMode
    )
    let currentFormName = selection.title(for: stage)
    let selectionHistory = evolutionHistory.filter { $0.selection == selection }
    let latestEvolution = selectionHistory.first
    let latestMoment = moments.first { $0.selection == selection }
    let completedGoals = rewardsSnapshot.goals.filter(\.isMet).count
    let earnedBadges = rewardsSnapshot.badges.filter(\.isEarned).count
    let topStreak = rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
    let pointLabel = atlasMascotExportPointLabel(rewardsSnapshot.totalPoints, privacyMode: privacyMode)
    let streakDetail = atlasMascotExportStreakLabel(topStreak, privacyMode: privacyMode)
    let recordedLabel = latestMoment.map { atlasMascotReadableTimestamp($0.recordedAt) } ?? "recently"
    let audiencePrefix = atlasMascotAudienceEyebrowPrefix(audience)

    switch kind {
    case .weeklyRecap:
        return AtlasMascotRecapDescriptor(
            kind: kind,
            audience: audience,
            privacyMode: privacyMode,
            selection: selection,
            stage: stage,
            displayName: displayName,
            currentFormName: currentFormName,
            eyebrow: "\(audiencePrefix) weekly recap",
            headline: atlasMascotWeeklyHeadline(
                audience: audience,
                displayName: displayName,
                pointLabel: pointLabel,
                currentFormName: currentFormName
            ),
            detail: atlasMascotWeeklyDetail(
                audience: audience,
                privacyMode: privacyMode,
                currentFormName: currentFormName,
                completedGoals: completedGoals,
                earnedBadges: earnedBadges,
                streakDetail: streakDetail
            ),
            secondaryDetail: atlasMascotSecondaryDetail(
                audience: audience,
                privacyMode: privacyMode,
                fullDetail: evolution.milestoneHeadline,
                privacySafeDetail: "Next form progress is still moving forward inside Atlas."
            ),
            footer: evolution.progressLabel,
            symbolName: selection == .aetherion ? "bolt.fill" : "moon.stars.fill"
        )
    case .evolutionMilestone:
        if let latestEvolution {
            let unlockedFormName = selection.title(for: latestEvolution.stage)
            return AtlasMascotRecapDescriptor(
                kind: kind,
                audience: audience,
                privacyMode: privacyMode,
                selection: selection,
                stage: latestEvolution.stage,
                displayName: displayName,
                currentFormName: unlockedFormName,
                eyebrow: "\(audiencePrefix) evolution milestone",
                headline: atlasMascotEvolutionHeadline(
                    audience: audience,
                    displayName: displayName,
                    unlockedFormName: unlockedFormName
                ),
                detail: privacyMode == .fullDetail
                    ? "Evolution recorded \(atlasMascotReadableTimestamp(latestEvolution.earnedAt))."
                    : "\(unlockedFormName) was unlocked in Atlas and added to the guardian line.",
                secondaryDetail: latestEvolution.stage == .stage3
                    ? atlasMascotSecondaryDetail(
                        audience: audience,
                        privacyMode: privacyMode,
                        fullDetail: "\(unlockedFormName) is the final guardian form for this Atlas line.",
                        privacySafeDetail: "\(unlockedFormName) is now the top guardian form in this line."
                    )
                    : atlasMascotSecondaryDetail(
                        audience: audience,
                        privacyMode: privacyMode,
                        fullDetail: evolution.milestoneHeadline,
                        privacySafeDetail: "The next guardian milestone is still ahead."
                    ),
                footer: latestEvolution.stage == stage ? evolution.progressLabel : "Current form: \(currentFormName)",
                symbolName: "sparkles"
            )
        }

        return AtlasMascotRecapDescriptor(
            kind: kind,
            audience: audience,
            privacyMode: privacyMode,
            selection: selection,
            stage: stage,
            displayName: displayName,
            currentFormName: currentFormName,
            eyebrow: "\(audiencePrefix) evolution milestone",
            headline: evolution.celebrationHeadline,
            detail: privacyMode == .fullDetail
                ? evolution.celebrationBody
                : "Atlas is still building toward the next evolution milestone.",
            secondaryDetail: atlasMascotSecondaryDetail(
                audience: audience,
                privacyMode: privacyMode,
                fullDetail: evolution.milestoneHeadline,
                privacySafeDetail: "The next guardian milestone is still ahead."
            ),
            footer: evolution.progressLabel,
            symbolName: "sparkles"
        )
    case .latestMoment:
        if let latestMoment {
            return AtlasMascotRecapDescriptor(
                kind: kind,
                audience: audience,
                privacyMode: privacyMode,
                selection: selection,
                stage: latestMoment.stage,
                displayName: displayName,
                currentFormName: selection.title(for: latestMoment.stage),
                eyebrow: "\(audiencePrefix) latest moment",
                headline: latestMoment.title,
                detail: privacyMode == .fullDetail
                    ? latestMoment.detail
                    : atlasMascotPrivacySafeMomentDetail(
                        audience: audience,
                        stageName: selection.title(for: latestMoment.stage)
                    ),
                secondaryDetail: privacyMode == .fullDetail
                    ? "Recorded \(recordedLabel)."
                    : "Recorded recently in Atlas.",
                footer: evolution.progressLabel,
                symbolName: latestMoment.symbolName
            )
        }

        let reaction = atlasMascotReactionSummary(
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            history: selectionHistory
        )

        return AtlasMascotRecapDescriptor(
            kind: kind,
            audience: audience,
            privacyMode: privacyMode,
            selection: selection,
            stage: stage,
            displayName: displayName,
            currentFormName: currentFormName,
            eyebrow: "\(audiencePrefix) latest moment",
            headline: reaction?.title ?? "\(displayName) is ready for the next check-in.",
            detail: privacyMode == .fullDetail
                ? (reaction?.detail ?? evolution.milestoneHeadline)
                : atlasMascotSecondaryDetail(
                    audience: audience,
                    privacyMode: privacyMode,
                    fullDetail: reaction?.detail ?? evolution.milestoneHeadline,
                    privacySafeDetail: "The mascot is ready for the next meaningful update."
                ),
            secondaryDetail: "No stored mascot moment yet. Atlas will capture one after the next interaction or milestone.",
            footer: evolution.progressLabel,
            symbolName: reaction?.symbolName ?? "sparkles"
        )
    }
}

@MainActor
func atlasExportMascotRecapCard(
    descriptor: AtlasMascotRecapDescriptor,
    exportedAt: Date = Date()
) throws -> AtlasMascotExportArtifact {
    let directoryURL = try atlasMascotArchiveDirectoryURL()

    let renderer = ImageRenderer(
        content: AtlasMascotRecapCanvas(descriptor: descriptor)
            .frame(width: 1_200, height: 1_500)
    )
    renderer.scale = UIScreen.main.scale

    guard let image = renderer.uiImage, let data = image.pngData() else {
        throw AtlasMascotExportError.renderFailed
    }

    let timestamp = ISO8601DateFormatter.atlas.string(from: exportedAt).replacingOccurrences(of: ":", with: "-")
    let fileName = "atlas-mascot-\(descriptor.kind.rawValue)-\(descriptor.audience.rawValue)-\(descriptor.privacyMode.rawValue)-\(timestamp).png"
    let fileURL = directoryURL.appendingPathComponent(fileName)
    try data.write(to: fileURL, options: .atomic)

    let archiveRecord = AtlasMascotArchivedRecapRecord(
        id: "\(descriptor.kind.rawValue)-\(descriptor.audience.rawValue)-\(descriptor.privacyMode.rawValue)-\(timestamp)",
        selection: descriptor.selection,
        stage: descriptor.stage,
        kind: descriptor.kind.rawValue,
        audience: descriptor.audience,
        privacyMode: descriptor.privacyMode,
        displayName: descriptor.displayName,
        currentFormName: descriptor.currentFormName,
        eyebrow: descriptor.eyebrow,
        headline: descriptor.headline,
        detail: descriptor.detail,
        secondaryDetail: descriptor.secondaryDetail,
        footer: descriptor.footer,
        symbolName: descriptor.symbolName,
        fileName: fileName,
        createdAt: ISO8601DateFormatter.atlas.string(from: exportedAt)
    )

    return AtlasMascotExportArtifact(
        descriptor: descriptor,
        fileURL: fileURL,
        archiveRecord: archiveRecord
    )
}

func atlasMascotArchivedRecapDescriptor(
    _ record: AtlasMascotArchivedRecapRecord
) -> AtlasMascotRecapDescriptor {
    AtlasMascotRecapDescriptor(
        kind: AtlasMascotRecapCardKind(rawValue: record.kind) ?? .weeklyRecap,
        audience: record.audience,
        privacyMode: record.privacyMode,
        selection: record.selection,
        stage: record.stage,
        displayName: record.displayName,
        currentFormName: record.currentFormName,
        eyebrow: record.eyebrow,
        headline: record.headline,
        detail: record.detail,
        secondaryDetail: record.secondaryDetail,
        footer: record.footer,
        symbolName: record.symbolName
    )
}

func atlasMascotArchivedRecapFileURL(
    _ record: AtlasMascotArchivedRecapRecord
) throws -> URL {
    try atlasMascotArchiveDirectoryURL().appendingPathComponent(record.fileName)
}

public func atlasMascotTimelineNotificationRequests(
    selection: AtlasMascotSelection,
    nickname: String?,
    notificationSettings: AtlasMascotRecapNotificationSettings,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolutionHistory: [AtlasMascotEvolutionRecord],
    moments: [AtlasMascotMomentRecord],
    referenceDate: Date
) -> [AtlasMascotNotificationRequest] {
    guard rewardsSnapshot.settings.enabled else {
        return []
    }

    let selectionMoments = moments.filter { $0.selection == selection }
    let latestMoment = selectionMoments.first
    let latestMomentDate = latestMoment.flatMap { ISO8601DateFormatter.atlas.date(from: $0.recordedAt) }
    var requests: [AtlasMascotNotificationRequest] = []

    if notificationSettings.dailyEnabled,
       atlasMascotHasMeaningfulProgress(since: referenceDate.addingTimeInterval(-24 * 60 * 60), latestMomentDate: latestMomentDate) {
        let descriptor = atlasMascotRecapDescriptor(
            kind: latestMoment == nil ? .weeklyRecap : .latestMoment,
            audience: .personal,
            privacyMode: .privacySafe,
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            evolutionHistory: evolutionHistory,
            moments: moments
        )
        let triggerAt = atlasNextMascotRecapTriggerDate(
            cadence: .daily,
            referenceDate: referenceDate
        )
        requests.append(
            AtlasMascotNotificationRequest(
                identifier: "atlas.mascot.recap.daily.\(selection.rawValue).\(atlasMascotRecapPeriodKey(for: triggerAt, cadence: .daily))",
                title: "\(descriptor.displayName) has a nightly recap",
                body: descriptor.detail,
                triggerAt: triggerAt
            )
        )
    }

    if notificationSettings.weeklyEnabled,
       atlasMascotHasMeaningfulProgress(since: referenceDate.addingTimeInterval(-7 * 24 * 60 * 60), latestMomentDate: latestMomentDate) {
        let descriptor = atlasMascotRecapDescriptor(
            kind: .weeklyRecap,
            audience: .coach,
            privacyMode: .privacySafe,
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            evolutionHistory: evolutionHistory,
            moments: moments
        )
        let triggerAt = atlasNextMascotRecapTriggerDate(
            cadence: .weekly,
            referenceDate: referenceDate
        )
        requests.append(
            AtlasMascotNotificationRequest(
                identifier: "atlas.mascot.recap.weekly.\(selection.rawValue).\(atlasMascotRecapPeriodKey(for: triggerAt, cadence: .weekly))",
                title: "\(descriptor.displayName) saved this week's recap",
                body: descriptor.detail,
                triggerAt: triggerAt
            )
        )
    }

    return requests
}

struct AtlasMascotRecapPreviewCard: View {
    let descriptor: AtlasMascotRecapDescriptor
    @State private var previewImage: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white.opacity(0.72))
                        }
                        .padding(12)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 8) {
                atlasRecapBadge(descriptor.kind.title, tint: atlasMascotLineTint(for: descriptor.selection))
                atlasRecapBadge(descriptor.privacyMode.title, tint: AtlasPalette.textSecondary)
            }
            .padding(18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(atlasMascotLineTint(for: descriptor.selection).opacity(0.18), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(
            color: atlasMascotLineTint(for: descriptor.selection).opacity(0.14),
            radius: 18,
            x: 0,
            y: 12
        )
        .task(id: descriptor.id) {
            previewImage = atlasMascotRecapPreviewImage(for: descriptor)
        }
    }
}

struct AtlasMascotShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct AtlasMascotRecapCanvas: View {
    let descriptor: AtlasMascotRecapDescriptor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(backgroundGradient)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear, .black.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            decorativeBackdrop

            VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                header

                switch descriptor.kind {
                case .weeklyRecap:
                    weeklyRecapLayout
                case .evolutionMilestone:
                    evolutionMilestoneLayout
                case .latestMoment:
                    latestMomentLayout
                }

                Spacer(minLength: 0)

                footerBand
            }
            .padding(40)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: descriptor.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                    Text(descriptor.eyebrow)
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .foregroundStyle(.white.opacity(0.84))

                Text(descriptor.displayName)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 24)

            HStack(spacing: 8) {
                atlasRecapCanvasBadge(descriptor.audience.title)
                atlasRecapCanvasBadge(descriptor.privacyMode.title)
            }
        }
    }

    private var weeklyRecapLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text(descriptor.headline)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(descriptor.detail)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                Text(descriptor.secondaryDetail)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 12) {
                    atlasRecapCanvasMetric(title: "Form", value: descriptor.currentFormName)
                    atlasRecapCanvasMetric(title: "Direction", value: descriptor.footer)
                }
            }

            Spacer(minLength: 0)

            heroArt
        }
    }

    private var evolutionMilestoneLayout: some View {
        VStack(spacing: 18) {
            heroArt

            VStack(spacing: 10) {
                Text(descriptor.headline)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(descriptor.detail)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)

                Text(descriptor.secondaryDetail)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                atlasRecapCanvasMetric(title: "Unlocked form", value: descriptor.currentFormName)
                atlasRecapCanvasMetric(title: "Momentum", value: descriptor.footer)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var latestMomentLayout: some View {
        HStack(alignment: .center, spacing: 26) {
            VStack(alignment: .leading, spacing: 14) {
                Text(descriptor.headline)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(descriptor.detail)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                Text(descriptor.secondaryDetail)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))

                atlasRecapCanvasMetric(title: "Current form", value: descriptor.currentFormName)
            }

            Spacer(minLength: 0)

            heroArt
        }
    }

    private var heroArt: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .stroke(.white.opacity(0.28), lineWidth: 2)
                .frame(width: artHaloSize, height: artHaloSize)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            atlasMascotLineHighlight(for: descriptor.selection).opacity(0.34),
                            atlasMascotLineTint(for: descriptor.selection).opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 24,
                        endRadius: artHaloSize * 0.56
                    )
                )
                .frame(width: artHaloSize * 0.92, height: artHaloSize * 0.92)

            AtlasMascotIllustration(
                line: atlasMascotLine(for: descriptor.selection),
                stage: descriptor.stage,
                size: heroArtSize
            )

            AtlasMascotSprite(
                line: atlasMascotLine(for: descriptor.selection),
                stage: descriptor.stage,
                pose: .happy,
                size: 108
            )
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .frame(width: artFrameWidth, height: artFrameHeight, alignment: .center)
    }

    private var footerBand: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(descriptor.currentFormName)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(descriptor.footer)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer(minLength: 0)

            Text("Shared from Atlas mascot recap")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.top, 18)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(height: 1)
        }
    }

    private var decorativeBackdrop: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .frame(width: 560, height: 560)
                .offset(x: descriptor.kind == .latestMoment ? 180 : 240, y: -180)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            atlasMascotLineHighlight(for: descriptor.selection).opacity(0.24),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: descriptor.kind == .evolutionMilestone ? 0 : 220, y: descriptor.kind == .evolutionMilestone ? -40 : -160)
        }
    }

    private var heroArtSize: CGFloat {
        switch descriptor.kind {
        case .weeklyRecap:
            return descriptor.stage == .stage1 ? 360 : 410
        case .evolutionMilestone:
            return descriptor.stage == .stage3 ? 500 : 440
        case .latestMoment:
            return descriptor.stage == .stage3 ? 430 : 390
        }
    }

    private var artHaloSize: CGFloat {
        descriptor.kind == .evolutionMilestone ? 360 : 300
    }

    private var artFrameWidth: CGFloat {
        descriptor.kind == .evolutionMilestone ? 460 : 400
    }

    private var artFrameHeight: CGFloat {
        descriptor.kind == .evolutionMilestone ? 520 : 420
    }

    private var backgroundGradient: LinearGradient {
        switch descriptor.selection {
        case .aetherion:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.21),
                    Color(red: 0.08, green: 0.18, blue: 0.42),
                    Color(red: 0.14, green: 0.26, blue: 0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .aurielle:
            return LinearGradient(
                colors: [
                    Color(red: 0.19, green: 0.29, blue: 0.52),
                    Color(red: 0.30, green: 0.53, blue: 0.78),
                    Color(red: 0.63, green: 0.79, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private func atlasRecapBadge(_ title: String, tint: Color) -> some View {
    Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.9))
        )
}

private func atlasRecapCanvasBadge(_ title: String) -> some View {
    Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(.white.opacity(0.14))
        )
}

private func atlasRecapCanvasMetric(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.68))
            .textCase(.uppercase)
            .tracking(1)
        Text(value)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.16))
    )
    .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(.white.opacity(0.12), lineWidth: 1)
    )
}

private func atlasMascotReadableTimestamp(_ timestamp: String) -> String {
    guard let date = ISO8601DateFormatter.atlas.date(from: timestamp) else {
        return timestamp
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}

@MainActor
private func atlasMascotRecapPreviewImage(for descriptor: AtlasMascotRecapDescriptor) -> UIImage? {
    let renderer = ImageRenderer(
        content: AtlasMascotRecapCanvas(descriptor: descriptor)
            .frame(width: 1_200, height: 1_500)
    )
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}

private func atlasMascotMediaPointLabel(_ points: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return "\(formatter.string(from: NSNumber(value: points)) ?? "\(points)") points"
}

private func atlasMascotArchiveDirectoryURL() throws -> URL {
    let fileManager = FileManager.default
    let baseURL = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let directoryURL = baseURL.appendingPathComponent("AtlasMascotArchive", isDirectory: true)
    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
}

private func atlasMascotExportDisplayName(
    rawDisplayName: String,
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage,
    privacyMode: AtlasMascotRecapPrivacyMode
) -> String {
    guard privacyMode == .privacySafe else {
        return rawDisplayName
    }
    return selection.title(for: stage)
}

private func atlasMascotExportPointLabel(
    _ points: Int,
    privacyMode: AtlasMascotRecapPrivacyMode
) -> String {
    guard privacyMode == .privacySafe else {
        return atlasMascotMediaPointLabel(points)
    }
    switch points {
    case ..<250:
        return "early rewards momentum"
    case ..<750:
        return "steady rewards momentum"
    case ..<1_250:
        return "strong rewards momentum"
    default:
        return "final-form rewards momentum"
    }
}

private func atlasMascotExportStreakLabel(
    _ topStreak: Int,
    privacyMode: AtlasMascotRecapPrivacyMode
) -> String {
    guard topStreak > 0 else {
        return privacyMode == .privacySafe ? "fresh consistency" : "new streak ready to start"
    }
    guard privacyMode == .fullDetail else {
        return "active consistency"
    }
    return "\(topStreak)-day active streak"
}

private func atlasMascotAudienceEyebrowPrefix(_ audience: AtlasMascotRecapAudience) -> String {
    switch audience {
    case .personal:
        return "Personal"
    case .coach:
        return "Coach"
    case .share:
        return "Share"
    }
}

private func atlasMascotWeeklyHeadline(
    audience: AtlasMascotRecapAudience,
    displayName: String,
    pointLabel: String,
    currentFormName: String
) -> String {
    switch audience {
    case .personal:
        return "\(displayName) is carrying \(pointLabel) of momentum."
    case .coach:
        return "\(currentFormName) logged \(pointLabel) and is ready for review."
    case .share:
        return "\(displayName) is holding a strong Atlas rhythm right now."
    }
}

private func atlasMascotWeeklyDetail(
    audience: AtlasMascotRecapAudience,
    privacyMode: AtlasMascotRecapPrivacyMode,
    currentFormName: String,
    completedGoals: Int,
    earnedBadges: Int,
    streakDetail: String
) -> String {
    switch audience {
    case .personal:
        return "\(currentFormName) tracked \(completedGoals) completed goals, \(earnedBadges) earned badges, and a \(streakDetail)."
    case .coach:
        if privacyMode == .privacySafe {
            return "Atlas captured progress across goals, consistency, and reward milestones without exposing private labels."
        }
        return "\(completedGoals) goals closed, \(earnedBadges) badges earned, and \(streakDetail) maintained."
    case .share:
        if privacyMode == .privacySafe {
            return "Atlas captured a steady rhythm across momentum, consistency, and guardian progress."
        }
        return "\(currentFormName) reflected progress across goals, badges, and steady consistency."
    }
}

private func atlasMascotEvolutionHeadline(
    audience: AtlasMascotRecapAudience,
    displayName: String,
    unlockedFormName: String
) -> String {
    switch audience {
    case .personal:
        return "\(displayName) unlocked \(unlockedFormName)."
    case .coach:
        return "\(unlockedFormName) is now active in Atlas."
    case .share:
        return "\(displayName) reached a new guardian form."
    }
}

private func atlasMascotSecondaryDetail(
    audience: AtlasMascotRecapAudience,
    privacyMode: AtlasMascotRecapPrivacyMode,
    fullDetail: String,
    privacySafeDetail: String
) -> String {
    guard privacyMode == .privacySafe else {
        return fullDetail
    }
    switch audience {
    case .personal, .coach, .share:
        return privacySafeDetail
    }
}

private func atlasMascotPrivacySafeMomentDetail(
    audience: AtlasMascotRecapAudience,
    stageName: String
) -> String {
    switch audience {
    case .personal:
        return "\(stageName) reacted to a recent Atlas milestone."
    case .coach:
        return "Atlas recorded a recent mascot reaction tied to meaningful progress."
    case .share:
        return "Atlas captured a recent mascot moment."
    }
}

private enum AtlasMascotRecapNotificationCadence {
    case daily
    case weekly
}

private func atlasMascotHasMeaningfulProgress(
    since startDate: Date,
    latestMomentDate: Date?
) -> Bool {
    guard let latestMomentDate else {
        return false
    }
    return latestMomentDate >= startDate
}

private func atlasNextMascotRecapTriggerDate(
    cadence: AtlasMascotRecapNotificationCadence,
    referenceDate: Date
) -> Date {
    let calendar = Calendar.current
    switch cadence {
    case .daily:
        let targetComponents = DateComponents(hour: 20, minute: 0)
        let todayTarget = calendar.nextDate(
            after: referenceDate.addingTimeInterval(-1),
            matching: targetComponents,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? referenceDate.addingTimeInterval(60 * 60)
        return todayTarget
    case .weekly:
        let targetComponents = DateComponents(hour: 18, minute: 0, weekday: 1)
        return calendar.nextDate(
            after: referenceDate,
            matching: targetComponents,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? referenceDate.addingTimeInterval(24 * 60 * 60)
    }
}

private func atlasMascotRecapPeriodKey(
    for date: Date,
    cadence: AtlasMascotRecapNotificationCadence
) -> String {
    let calendar = Calendar.current
    switch cadence {
    case .daily:
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    case .weekly:
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }
}

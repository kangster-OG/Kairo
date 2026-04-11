import AtlasDomain
import GRDB
import Foundation

private let atlasRetentionCompletedReviewWeeksKey = "retention_completed_review_weeks_json"

public struct GRDBRetentionRepository: RetentionRepository, Sendable {
    let stack: AtlasDatabaseStack
    let featureFlags: AtlasFeatureFlagState

    init(
        stack: AtlasDatabaseStack,
        featureFlags: AtlasFeatureFlagState
    ) {
        self.stack = stack
        self.featureFlags = featureFlags
    }

    public func fetchRetentionSnapshot(referenceDate: Date) async throws -> AtlasRetentionSnapshot {
        try await stack.canonical.read { db in
            try buildRetentionSnapshot(
                db: db,
                referenceDate: referenceDate,
                featureFlags: featureFlags
            )
        }
    }

    public func markWeeklyReviewComplete(now: Date) async throws -> AtlasRetentionSnapshot {
        try await stack.canonical.write { db in
            var completedWeeks = try readCompletedReviewWeeks(db: db)
            completedWeeks.insert(atlasRetentionWeekIdentifier(for: now))
            try writeCompletedReviewWeeks(db: db, weeks: completedWeeks, now: now)
            return try buildRetentionSnapshot(
                db: db,
                referenceDate: now,
                featureFlags: featureFlags
            )
        }
    }
}

func buildRetentionSnapshot(
    db: Database,
    referenceDate: Date,
    featureFlags: AtlasFeatureFlagState
) throws -> AtlasRetentionSnapshot {
    let settings = try readRetentionSettings(db: db, featureFlags: featureFlags)
    guard featureFlags.calmRetention, settings.progressEnabled else {
        return AtlasRetentionSnapshot(settings: settings)
    }

    let inventorySnapshot = try buildInventorySnapshot(db: db, referenceDate: referenceDate)
    let logEvents = try AtlasLogEventDBRecord.fetchAll(db).map(\.domain)
    let contextLogs = try AtlasContextLogDBRecord.fetchAll(db).map(\.domain)
    let symptomLogs = try AtlasSymptomLogDBRecord.fetchAll(db).map(\.domain)
    let weightLogs = try AtlasWeightLogDBRecord.fetchAll(db).map(\.domain)
    let metricLogs = try AtlasMetricValueLogDBRecord.fetchAll(db).map(\.domain)
    let reviewSessions = try AtlasReviewSessionDBRecord.fetchAll(db)
    let completedReviewWeeks = try readCompletedReviewWeeks(db: db)

    let milestones = buildRetentionMilestones(
        referenceDate: referenceDate,
        inventorySnapshot: inventorySnapshot,
        logEvents: logEvents,
        contextLogs: contextLogs,
        symptomLogs: symptomLogs,
        weightLogs: weightLogs,
        metricLogs: metricLogs,
        reviewSessions: reviewSessions,
        completedReviewWeeks: completedReviewWeeks
    )
    let earnedCount = milestones.filter(\.isEarned).count
    let companion: AtlasRetentionCompanionSnapshot? =
        featureFlags.companionSkin && settings.companionEnabled
        ? buildRetentionCompanion(milestones: milestones)
        : nil

    return AtlasRetentionSnapshot(
        settings: settings,
        milestones: milestones,
        earnedMilestoneCount: earnedCount,
        companion: companion,
        note: "Calm continuity is optional, local only, and never rewrites Atlas history."
    )
}

private func buildRetentionMilestones(
    referenceDate: Date,
    inventorySnapshot: AtlasInventorySnapshot,
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    reviewSessions: [AtlasReviewSessionDBRecord],
    completedReviewWeeks: Set<String>
) -> [AtlasRetentionMilestoneSnapshot] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: referenceDate)
    let activityDays = Set(
        logEvents.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + contextLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + symptomLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + weightLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + metricLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
    )
    let todayCheckedIn = activityDays.contains(today)
    let checkInStreak = atlasRetentionConsecutiveDayCount(days: activityDays, endingAt: today)

    let currentWeek = atlasRetentionWeekIdentifier(for: referenceDate)
    let reviewWeeks = completedReviewWeeks.union(
        Set(reviewSessions.map { atlasRetentionWeekIdentifier(fromTimestamp: $0.createdAt) })
    )
    let reviewStreak = atlasRetentionConsecutiveWeekCount(weeks: reviewWeeks, endingAt: referenceDate)
    let weeklyReviewCompleted = reviewWeeks.contains(currentWeek)

    let activeVials = inventorySnapshot.vials.filter { $0.archivedAt == nil }
    let activeConsumables = inventorySnapshot.consumables.filter { $0.archivedAt == nil }
    let activeInventoryCount = activeVials.count + activeConsumables.count
    let activeLowStockCount = activeVials.filter(\.isLowStock).count + activeConsumables.filter(\.isLowStock).count
    let inventoryCurrent = activeInventoryCount > 0 && activeLowStockCount == 0

    let recentContextStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
    let recentContextDays = Set(
        contextLogs
            .map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            .filter { $0 >= recentContextStart && $0 <= today }
    )
    let contextStreak = atlasRetentionConsecutiveDayCount(days: recentContextDays, endingAt: today)
    let contextConsistent = recentContextDays.count >= 3

    return [
        AtlasRetentionMilestoneSnapshot(
            kind: .checkedInToday,
            title: "Local activity today",
            subtitle: todayCheckedIn ? "Atlas recorded local activity today." : "Today is still open for a local entry.",
            helperText: todayCheckedIn
                ? (checkInStreak > 1
                    ? "Recent local continuity spans \(checkInStreak) consecutive days."
                    : "Any local log or signal entry counts.")
                : "Any local log, context entry, symptom, weight, or custom metric entry counts.",
            symbolName: "checkmark.circle.fill",
            isEarned: todayCheckedIn,
            continuityLabel: checkInStreak > 1 ? "\(checkInStreak) days" : nil,
            tone: todayCheckedIn ? .complete : .inProgress
        ),
        AtlasRetentionMilestoneSnapshot(
            kind: .weeklyReviewCompleted,
            title: "Reviewed this week",
            subtitle: weeklyReviewCompleted ? "This week is marked reviewed." : "This week can still be marked reviewed when you are ready.",
            helperText: weeklyReviewCompleted
                ? (reviewStreak > 1
                    ? "Review continuity spans \(reviewStreak) consecutive weeks."
                    : "Review completion stays local to this device.")
                : "Use this only when you have actually looked over the week. Missing a week never affects Atlas history.",
            symbolName: "calendar.badge.checkmark",
            isEarned: weeklyReviewCompleted,
            continuityLabel: reviewStreak > 1 ? "\(reviewStreak) weeks" : nil,
            tone: weeklyReviewCompleted ? .complete : .neutral
        ),
        AtlasRetentionMilestoneSnapshot(
            kind: .inventoryCurrent,
            title: "Inventory looks current",
            subtitle: activeInventoryCount == 0
                ? "Inventory tracking is optional."
                : (inventoryCurrent
                    ? "Tracked inventory is currently above low-stock thresholds."
                    : "A few tracked items need attention."),
            helperText: activeInventoryCount == 0
                ? "Add vials or supplies when you want Atlas to watch depletion."
                : (inventoryCurrent
                    ? "Active items are above low-stock thresholds."
                    : "\(activeLowStockCount) tracked item\(activeLowStockCount == 1 ? "" : "s") are low."),
            symbolName: "shippingbox.fill",
            isEarned: inventoryCurrent,
            continuityLabel: nil,
            tone: activeInventoryCount == 0 ? .neutral : (inventoryCurrent ? .complete : .inProgress)
        ),
        AtlasRetentionMilestoneSnapshot(
            kind: .contextConsistency,
            title: "Context continuity",
            subtitle: contextConsistent
                ? "Context appeared on \(recentContextDays.count) of the last 7 days."
                : "Context has appeared on \(recentContextDays.count) of the last 7 days.",
            helperText: contextConsistent
                ? (contextStreak > 1
                    ? "Recent context continuity spans \(contextStreak) consecutive days."
                    : "Atlas counts days with at least one context entry.")
                : "Atlas counts days with at least one context entry. There is no penalty for quiet stretches.",
            symbolName: "leaf.circle.fill",
            isEarned: contextConsistent,
            continuityLabel: contextStreak > 1 ? "\(contextStreak) days" : nil,
            tone: contextConsistent ? .complete : .neutral
        )
    ]
}

private func buildRetentionCompanion(
    milestones: [AtlasRetentionMilestoneSnapshot]
) -> AtlasRetentionCompanionSnapshot? {
    let checkedInToday = milestones.first(where: { $0.kind == .checkedInToday })?.isEarned == true
    let weeklyReviewCompleted = milestones.first(where: { $0.kind == .weeklyReviewCompleted })?.isEarned == true
    let contextConsistent = milestones.first(where: { $0.kind == .contextConsistency })?.isEarned == true

    if checkedInToday && contextConsistent {
        return AtlasRetentionCompanionSnapshot(
            mood: .settled,
            title: "Board settled",
            subtitle: "Atlas has enough recent continuity to keep this board current.",
            systemImage: "checkmark.circle.fill"
        )
    }

    if checkedInToday || weeklyReviewCompleted || contextConsistent {
        return AtlasRetentionCompanionSnapshot(
            mood: .steady,
            title: "Quietly current",
            subtitle: "Atlas has a recent continuity update to reflect here.",
            systemImage: "leaf.fill"
        )
    }

    return nil
}

private func readCompletedReviewWeeks(
    db: Database
) throws -> Set<String> {
    guard let raw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [atlasRetentionCompletedReviewWeeksKey]
    ), raw.isEmpty == false else {
        return []
    }

    guard let data = raw.data(using: .utf8),
          let weeks = try? JSONDecoder().decode([String].self, from: data) else {
        return []
    }
    return Set(weeks)
}

private func writeCompletedReviewWeeks(
    db: Database,
    weeks: Set<String>,
    now: Date
) throws {
    let encoded = try JSONEncoder().encode(Array(weeks).sorted())
    try writeAppSetting(
        db: db,
        key: atlasRetentionCompletedReviewWeeksKey,
        value: String(decoding: encoded, as: UTF8.self),
        now: now
    )
}

private func atlasRetentionWeekIdentifier(for date: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    let year = components.yearForWeekOfYear ?? 0
    let week = components.weekOfYear ?? 0
    return String(format: "%04d-W%02d", year, week)
}

private func atlasRetentionWeekIdentifier(fromTimestamp timestamp: String) -> String {
    atlasRetentionWeekIdentifier(for: atlasDate(from: timestamp))
}

private func atlasRetentionConsecutiveDayCount(
    days: Set<Date>,
    endingAt endDate: Date
) -> Int {
    let calendar = Calendar.current
    var count = 0
    var cursor = calendar.startOfDay(for: endDate)

    while days.contains(cursor) {
        count += 1
        guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
            break
        }
        cursor = previous
    }

    return count
}

private func atlasRetentionConsecutiveWeekCount(
    weeks: Set<String>,
    endingAt endDate: Date
) -> Int {
    let calendar = Calendar(identifier: .gregorian)
    guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start else {
        return 0
    }

    var count = 0
    var cursor = weekStart
    while weeks.contains(atlasRetentionWeekIdentifier(for: cursor)) {
        count += 1
        guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else {
            break
        }
        cursor = previous
    }
    return count
}

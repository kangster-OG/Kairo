import AtlasDomain
@testable import AtlasFeatures
import AtlasPersistence
import AtlasPrivacy
import AtlasSystem
import Foundation
import XCTest

@MainActor
final class AtlasPhaseOneTests: XCTestCase {
    func testLegacyValidationReportsMissingDatasets() async throws {
        let controller = try makeInMemoryController()
        let url = try writeLegacyBundleURL()

        let validation = try await controller.importExportBridge.validateImport(at: url)

        XCTAssertTrue(validation.isLegacyBundle)
        XCTAssertTrue(validation.missingDatasets.contains("protocolRevisions"))
        XCTAssertTrue(validation.missingDatasets.contains("sensitiveActionAudits"))
    }

    func testDryRunProducesBackfillNotes() async throws {
        let controller = try makeInMemoryController()
        let url = try writeLegacyBundleURL()

        let prepared = try await controller.importExportBridge.prepareImport(at: url)

        XCTAssertGreaterThan(prepared.dryRun.recordsToCreate, 0)
        XCTAssertTrue(
            prepared.dryRun.backfillNotes.contains(where: { $0.contains("Revision rows were backfilled") })
        )
        XCTAssertTrue(
            prepared.dryRun.backfillNotes.contains(where: { $0.contains("privacy control profile rows") })
        )
    }

    func testCommitImportsProtocolsAndNativeShellReadsThem() async throws {
        let controller = try makeInMemoryController()
        let url = try writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        let prepared = try await controller.importExportBridge.prepareImport(at: url)

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let model = await MainActor.run {
            makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        }

        await model.refreshShellData()

        XCTAssertEqual(model.libraryProtocols.count, 1)
        XCTAssertEqual(model.renderedTitle(canonical: "Weekly GLP", alias: "Evening plan"), "Evening plan")
        XCTAssertEqual(model.todaySnapshot.nextDue?.canonicalTitle, "Weekly GLP")
        XCTAssertEqual(model.todaySnapshot.nextDue?.aliasTitle, "Evening plan")
    }

    func testReplaceImportCreatesBackupAndReplacesNativeData() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )

        let firstPrepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: false)
        ))
        _ = try await controller.importExportBridge.commitPreparedImport(firstPrepared, mode: .replaceExisting)

        var secondBundle = makeSpecCompleteBundle(aliasModeEnabled: false)
        secondBundle.snapshot.protocols[0].name = "Replacement protocol"
        secondBundle.snapshot.protocolAliases = []
        let secondPrepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(secondBundle))

        let result = try await controller.importExportBridge.commitPreparedImport(secondPrepared, mode: .replaceExisting)
        let summaries = try await controller.container.protocols.listProtocolSummaries()

        XCTAssertNotNil(result.backupURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.backupURL?.path ?? ""))
        XCTAssertEqual(summaries.first?.canonicalTitle, "Replacement protocol")
    }

    func testCancelPreparedImportLeavesDatabaseEmpty() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: false)
        ))

        await controller.importExportBridge.cancelPreparedImport(prepared)

        let protocols = try await controller.container.protocols.listProtocolSummaries()
        let nextDue = try await controller.container.today.fetchNextDue()

        XCTAssertTrue(protocols.isEmpty)
        XCTAssertNil(nextDue)
    }

    func testRollbackPreventsPartialWritesOnInvalidForeignKeys() async throws {
        let controller = try makeInMemoryController()
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: false)
        bundle.snapshot.reminders[0].protocolId = "missing_protocol"
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))

        do {
            _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
            XCTFail("Expected import to fail")
        } catch {}

        let protocols = try await controller.container.protocols.listProtocolSummaries()
        let history = try await controller.container.timeline.fetchHistory(limit: 10)

        XCTAssertTrue(protocols.isEmpty)
        XCTAssertTrue(history.isEmpty)
    }

    func testProjectionStoreReceivesImportedData() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: true)
        ))

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let debugState = try await controller.sharedProjectionWriter.loadProjectionDebugState()

        XCTAssertEqual(debugState.labels.first?.aliasTitle, "Evening plan")
        XCTAssertEqual(debugState.nextDue?.displayTitle, "Evening plan")
        XCTAssertFalse(debugState.quickActions.isEmpty)
    }

    @MainActor
    func testRefreshShellDataWritesExtensionProjectionSnapshot() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Widget protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        await model.refreshShellData()
        let snapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        XCTAssertEqual(snapshot?.renderMode, .full)
        XCTAssertEqual(snapshot?.nextDue?.displayTitle, "Widget protocol")
        XCTAssertFalse(snapshot?.quickActions.isEmpty ?? true)
        XCTAssertEqual(snapshot?.mascot?.selection, .aetherion)
        XCTAssertEqual(snapshot?.mascot?.currentFormName, AtlasMascotSelection.aetherion.stage1Title)
        XCTAssertEqual(snapshot?.watchCompanion?.nextDueTitle, "Widget protocol")
        XCTAssertFalse(snapshot?.watchCompanion?.quickContextShortcuts.isEmpty ?? true)
    }

    @MainActor
    func testRefreshShellDataWritesSupportRingsProjectionSnapshot() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Support protocol",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(-3_600),
                mealTiming: .breakfast,
                mealComposition: .proteinHeavy,
                hydration: .high,
                tags: ["protein", "hydration"]
            ),
            now: now.addingTimeInterval(-3_600)
        )
        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(-1_800),
                mealTiming: .lunch,
                mealComposition: .proteinHeavy,
                hydration: .high,
                tags: ["protein", "hydration"]
            ),
            now: now.addingTimeInterval(-1_800)
        )
        _ = try await controller.container.metrics.saveWorkoutEntry(
            AtlasWorkoutEntryDraft(
                activityKind: .strength,
                startedAt: now.addingTimeInterval(-900),
                durationMinutes: 35,
                energyBurnedKilocalories: 180
            ),
            now: now.addingTimeInterval(-900)
        )

        await model.refreshShellData()
        let snapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()
        let support = try XCTUnwrap(snapshot?.support)
        let proteinRing = try XCTUnwrap(support.rings.first { $0.kind == "protein" })
        let hydrationRing = try XCTUnwrap(support.rings.first { $0.kind == "hydration" })
        let workoutRing = try XCTUnwrap(support.rings.first { $0.kind == "workout" })

        XCTAssertEqual(support.score, 100)
        XCTAssertEqual(proteinRing.progress, 1, accuracy: 0.001)
        XCTAssertEqual(hydrationRing.progress, 1, accuracy: 0.001)
        XCTAssertEqual(workoutRing.progress, 1, accuracy: 0.001)
    }

    @MainActor
    func testDiscreetPrivacyModeRefreshesExtensionProjectionSnapshot() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let model = makeAppModel(controller: controller)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sensitive protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now.addingTimeInterval(60))
        await model.refreshShellData()
        let snapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        XCTAssertEqual(snapshot?.renderMode, .discreet)
        XCTAssertEqual(snapshot?.nextDue?.displayTitle, "Private protocol")
    }

    @MainActor
    func testLowStockProjectionIncludesProcurementReviewSignal() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let model = makeAppModel(controller: controller)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 2,
                unit: "pad",
                reorderThreshold: 3,
                reorderLeadTimeDays: 5,
                quantityPerUse: 1
            ),
            now: now
        )

        await model.refreshShellData()
        let loadedSnapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()
        let snapshot = try XCTUnwrap(loadedSnapshot)

        XCTAssertEqual(snapshot.lowStock.lowStockCount, 1)
        XCTAssertEqual(snapshot.lowStock.procurementReviewCount, 1)
        XCTAssertEqual(snapshot.lowStock.items.first?.detail, "Supply review now.")
    }

    func testOnboardingSequencePlacesTrialPaywallBeforeAppHandoff() {
        let sequence = AtlasOnboardingDraft.empty().sequence()

        XCTAssertEqual(
            sequence,
            [
                .splash,
                .trackType,
                .journeyStatus,
                .protocolPreview,
                .focus,
                .goalsProfile,
                .healthDisclaimer,
                .privacyPreset,
                .premiumPreview,
                .trustVaultReveal,
                .companionPreview,
                .readinessLoop,
                .systemSurfaces,
                .personalizedUnlock,
                .todayCommandPreview,
                .protocolChangeHistory,
                .reviewOutputPreview,
                .migrationPreview,
                .trialTimeline,
                .premiumPaywall,
                .connectApps,
                .planReady
            ]
        )
    }

    func testDreamOnboardingInventoryStaysLongAndChaptered() {
        XCTAssertEqual(atlasDreamOnboardingSceneCountForTesting, 22)
        XCTAssertEqual(
            atlasDreamOnboardingChapterTitlesForTesting,
            [
                "Command center fantasy",
                "Problem aha",
                "Protocol reality",
                "Goals and evidence",
                "Friction map",
                "Trust Vault setup",
                "Interactive Log Shot ritual",
                "Kairo generation",
                "Companion awakening",
                "Readiness reveal",
                "First-week plan",
                "Trial and paywall",
                "Permissions",
                "Populated Today handoff"
            ]
        )
    }

    func testDreamOnboardingDraftDecodesWithSafeDefaults() throws {
        let data = Data("{}".utf8)
        let draft = try JSONDecoder().decode(AtlasOnboardingDraft.self, from: data)

        XCTAssertEqual(draft.dreamProgressIndex, 0)
        XCTAssertTrue(draft.dreamAnswers.isEmpty)
        XCTAssertTrue(draft.dreamAnswerGroups.isEmpty)
        XCTAssertNil(draft.dayOnePriority)
        XCTAssertNil(draft.companionRole)
        XCTAssertNil(draft.companionSignalColor)
        XCTAssertEqual(draft.companionPresence, .subtle)
        XCTAssertTrue(draft.firstWeekPlanPreview.isEmpty)
    }

    func testOnboardingFunnelEventsPersistLimitAndReset() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let viewed = AtlasOnboardingFunnelEvent(
            id: "00000000-0000-0000-0000-000000000101",
            name: .stepViewed,
            step: .trackType,
            metadata: ["trackType": "later"],
            recordedAt: now
        )
        let selected = AtlasOnboardingFunnelEvent(
            id: "00000000-0000-0000-0000-000000000102",
            name: .answerSelected,
            step: .trackType,
            metadata: ["field": "trackType", "value": "later"],
            recordedAt: now.addingTimeInterval(1)
        )

        try await controller.container.onboarding.recordFunnelEvent(viewed, now: now)
        try await controller.container.onboarding.recordFunnelEvent(selected, now: now.addingTimeInterval(1))

        let allEvents = try await controller.container.onboarding.fetchFunnelEvents(limit: 10)
        let limitedEvents = try await controller.container.onboarding.fetchFunnelEvents(limit: 1)

        XCTAssertEqual(allEvents, [viewed, selected])
        XCTAssertEqual(limitedEvents, [selected])

        _ = try await controller.container.onboarding.resetOnboarding(now: now.addingTimeInterval(2))

        let resetEvents = try await controller.container.onboarding.fetchFunnelEvents(limit: 10)
        XCTAssertTrue(resetEvents.isEmpty)
    }

    func testMascotMilestoneThresholdsResolveExpectedStages() {
        XCTAssertEqual(AtlasMascotMilestone.stage(for: 0), .stage1)
        XCTAssertEqual(AtlasMascotMilestone.stage(for: 499), .stage1)
        XCTAssertEqual(AtlasMascotMilestone.stage(for: 500), .stage2)
        XCTAssertEqual(AtlasMascotMilestone.stage(for: 1_249), .stage2)
        XCTAssertEqual(AtlasMascotMilestone.stage(for: 1_250), .stage3)
        XCTAssertEqual(AtlasMascotMilestone.nextThreshold(after: .stage1), 500)
        XCTAssertEqual(AtlasMascotMilestone.nextThreshold(after: .stage2), 1_250)
        XCTAssertNil(AtlasMascotMilestone.nextThreshold(after: .stage3))
    }

    func testRewardCelebrationCandidatePrioritizesLevelGoalBadgeAndStreakEvents() {
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let prior = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 240,
            level: 1,
            nextLevelPoints: 250,
            streaks: [
                AtlasRewardStreakSnapshot(kind: .activityDays, title: "Daily streak", valueLabel: "2", helperText: "", symbolName: "flame.fill", count: 2, isActive: true)
            ],
            goals: [
                AtlasRewardGoalSnapshot(kind: .weeklyWorkouts, title: "Workout", progressLabel: "2 / 3", helperText: "", symbolName: "dumbbell.fill", currentValue: 2, targetValue: 3, progress: 0.66, isMet: false)
            ],
            badges: [
                AtlasRewardBadgeSnapshot(kind: .workoutGoalMet, title: "Workout", subtitle: "Weekly", symbolName: "dumbbell.fill", isEarned: false)
            ]
        )

        let levelUp = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 260,
            level: 2,
            nextLevelPoints: 500,
            streaks: prior.streaks,
            goals: prior.goals,
            badges: prior.badges
        )
        XCTAssertEqual(
            atlasRewardCelebrationCandidate(previous: prior, current: levelUp, selection: .aetherion, createdAt: now)?.kind,
            .level
        )

        let goalMet = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 340,
            level: 2,
            nextLevelPoints: 500,
            streaks: prior.streaks,
            goals: [
                AtlasRewardGoalSnapshot(kind: .weeklyWorkouts, title: "Workout", progressLabel: "3 / 3", helperText: "", symbolName: "dumbbell.fill", currentValue: 3, targetValue: 3, progress: 1, isMet: true)
            ],
            badges: prior.badges
        )
        XCTAssertEqual(
            atlasRewardCelebrationCandidate(previous: levelUp, current: goalMet, selection: .aetherion, createdAt: now)?.kind,
            .goal
        )

        let badgeEarned = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 420,
            level: 2,
            nextLevelPoints: 500,
            streaks: goalMet.streaks,
            goals: goalMet.goals,
            badges: [
                AtlasRewardBadgeSnapshot(kind: .workoutGoalMet, title: "Workout", subtitle: "Weekly", symbolName: "dumbbell.fill", isEarned: true)
            ]
        )
        XCTAssertEqual(
            atlasRewardCelebrationCandidate(previous: goalMet, current: badgeEarned, selection: .aetherion, createdAt: now)?.kind,
            .badge
        )

        let streakExtended = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 460,
            level: 2,
            nextLevelPoints: 500,
            streaks: [
                AtlasRewardStreakSnapshot(kind: .activityDays, title: "Daily streak", valueLabel: "3", helperText: "", symbolName: "flame.fill", count: 3, isActive: true)
            ],
            goals: badgeEarned.goals,
            badges: badgeEarned.badges
        )
        XCTAssertEqual(
            atlasRewardCelebrationCandidate(previous: badgeEarned, current: streakExtended, selection: .aetherion, createdAt: now)?.kind,
            .streak
        )
    }

    func testRewardCelebrationCandidateDefersToMascotEvolutionAtStageThresholds() {
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let prior = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 490,
            level: 2,
            nextLevelPoints: 500
        )
        let current = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 520,
            level: 3,
            nextLevelPoints: 750
        )

        XCTAssertNil(
            atlasRewardCelebrationCandidate(previous: prior, current: current, selection: .aurielle, createdAt: now)
        )
    }

    func testMascotEvolutionPersistenceDeduplicatesHistoryAndUnlocksHighestStage() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.settings.updateMascotSelection(.aetherion, now: now)
        _ = try await controller.container.settings.recordMascotEvolution(
            selection: .aetherion,
            stage: .stage2,
            earnedAt: now,
            now: now
        )
        let snapshot = try await controller.container.settings.recordMascotEvolution(
            selection: .aetherion,
            stage: .stage2,
            earnedAt: now.addingTimeInterval(60),
            now: now.addingTimeInterval(60)
        )

        XCTAssertEqual(snapshot.highestUnlockedStage(for: .aetherion), .stage2)
        XCTAssertEqual(snapshot.mascotEvolutionHistory.filter { $0.selection == .aetherion && $0.stage == .stage2 }.count, 1)
        XCTAssertEqual(snapshot.mascotEvolutionHistory.first?.selection, .aetherion)
        XCTAssertEqual(snapshot.mascotEvolutionHistory.first?.stage, .stage2)
    }

    func testMascotMomentPersistenceDeduplicatesStableEventKeys() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        let first = AtlasMascotMomentRecord(
            selection: .aurielle,
            stage: .stage1,
            kind: .goal,
            title: "Nova noticed a goal closeout",
            detail: "Weekly goal complete.",
            symbolName: "flag.checkered",
            recordedAt: atlasMascotMomentTimestamp(from: now),
            eventKey: "goal-aurielle-weekly_workouts"
        )
        _ = try await controller.container.settings.recordMascotMoment(first, now: now)

        let second = AtlasMascotMomentRecord(
            selection: .aurielle,
            stage: .stage1,
            kind: .goal,
            title: "Nova noticed a goal closeout",
            detail: "Weekly goal complete.",
            symbolName: "flag.checkered",
            recordedAt: atlasMascotMomentTimestamp(from: now.addingTimeInterval(60)),
            eventKey: "goal-aurielle-weekly_workouts"
        )
        let snapshot = try await controller.container.settings.recordMascotMoment(
            second,
            now: now.addingTimeInterval(60)
        )

        XCTAssertEqual(snapshot.mascotMoments.count, 1)
        XCTAssertEqual(snapshot.mascotMoments.first?.eventKey, "goal-aurielle-weekly_workouts")
    }

    func testMascotAutomaticMomentCandidatesUseRecoveryCopyForOneDayStreak() {
        let snapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 120,
            streaks: [
                AtlasRewardStreakSnapshot(
                    kind: .activityDays,
                    title: "Workout streak",
                    valueLabel: "1 day",
                    helperText: "Momentum restarted.",
                    symbolName: "figure.run",
                    count: 1,
                    isActive: true
                )
            ]
        )

        let moments = atlasMascotAutomaticMomentCandidates(
            selection: .aurielle,
            nickname: "Nova",
            rewardsSnapshot: snapshot,
            evolutionHistory: [],
            archivedRecaps: [],
            existingMoments: [],
            recordedAt: Date(timeIntervalSince1970: 1_773_950_400)
        )

        XCTAssertEqual(moments.count, 1)
        XCTAssertEqual(moments.first?.kind, .streakRescue)
        XCTAssertEqual(moments.first?.title, "Nova recovered the line")
        XCTAssertTrue(moments.first?.detail.contains("Workout streak is back on track.") == true)
        XCTAssertEqual(moments.first?.symbolName, "arrow.clockwise.circle.fill")
    }

    func testMascotNotificationRequestOnlyReturnsEvolutionAndRecoveryEvents() {
        let referenceDate = Date(timeIntervalSince1970: 1_773_950_400)
        let evolution = AtlasMascotMomentRecord(
            selection: .aetherion,
            stage: .stage2,
            kind: .evolution,
            title: "Voltflare unlocked",
            detail: "Aetherion reached the second form.",
            symbolName: "sparkles",
            recordedAt: atlasMascotMomentTimestamp(from: referenceDate),
            eventKey: "evolution-aetherion-stage2"
        )
        let recovery = AtlasMascotMomentRecord(
            selection: .aurielle,
            stage: .stage1,
            kind: .streakRescue,
            title: "Nova recovered the line",
            detail: "Workout streak is back on track.",
            symbolName: "arrow.clockwise.circle.fill",
            recordedAt: atlasMascotMomentTimestamp(from: referenceDate),
            eventKey: "streak-aurielle-activity_days-1"
        )
        let goal = AtlasMascotMomentRecord(
            selection: .aurielle,
            stage: .stage1,
            kind: .goal,
            title: "Nova noticed a goal closeout",
            detail: "Weekly goal complete.",
            symbolName: "flag.checkered",
            recordedAt: atlasMascotMomentTimestamp(from: referenceDate),
            eventKey: "goal-aurielle-weekly_workouts"
        )

        let evolutionRequest = atlasMascotNotificationRequest(for: evolution, referenceDate: referenceDate)
        let recoveryRequest = atlasMascotNotificationRequest(for: recovery, referenceDate: referenceDate)
        let goalRequest = atlasMascotNotificationRequest(for: goal, referenceDate: referenceDate)

        XCTAssertEqual(evolutionRequest?.identifier, "atlas.mascot.aetherion.evolution-aetherion-stage2")
        XCTAssertEqual(recoveryRequest?.identifier, "atlas.mascot.aurielle.streak-aurielle-activity_days-1")
        XCTAssertNil(goalRequest)
    }

    func testMascotAutomaticMomentCandidatesCreateNearEvolutionAndArchiveMilestoneMoments() {
        let snapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 470,
            level: 2,
            nextLevelPoints: 500,
            streaks: [
                AtlasRewardStreakSnapshot(
                    kind: .activityDays,
                    title: "Workout streak",
                    valueLabel: "7 days",
                    helperText: "Moving.",
                    symbolName: "figure.run",
                    count: 7,
                    isActive: true
                )
            ],
            goals: [
                AtlasRewardGoalSnapshot(
                    kind: .weeklyWorkouts,
                    title: "Weekly workouts",
                    progressLabel: "3/3 complete",
                    helperText: "Goal met.",
                    symbolName: "figure.strengthtraining.traditional",
                    currentValue: 3,
                    targetValue: 3,
                    progress: 1,
                    isMet: true
                )
            ]
        )

        let recaps = [
            AtlasMascotArchivedRecapRecord(
                id: "r1",
                selection: .aetherion,
                stage: .stage1,
                kind: AtlasMascotRecapCardKind.weeklyRecap.rawValue,
                audience: .personal,
                privacyMode: .fullDetail,
                displayName: "Cindlet",
                currentFormName: "Cindlet",
                eyebrow: "Weekly recap",
                headline: "One",
                detail: "Detail",
                secondaryDetail: "Secondary",
                footer: "Footer",
                symbolName: "bolt.fill",
                fileName: "one.png",
                createdAt: "2026-04-10T00:00:00.000Z"
            ),
            AtlasMascotArchivedRecapRecord(
                id: "r2",
                selection: .aetherion,
                stage: .stage1,
                kind: AtlasMascotRecapCardKind.latestMoment.rawValue,
                audience: .personal,
                privacyMode: .fullDetail,
                displayName: "Cindlet",
                currentFormName: "Cindlet",
                eyebrow: "Latest moment",
                headline: "Two",
                detail: "Detail",
                secondaryDetail: "Secondary",
                footer: "Footer",
                symbolName: "bolt.fill",
                fileName: "two.png",
                createdAt: "2026-04-11T00:00:00.000Z"
            ),
            AtlasMascotArchivedRecapRecord(
                id: "r3",
                selection: .aetherion,
                stage: .stage1,
                kind: AtlasMascotRecapCardKind.evolutionMilestone.rawValue,
                audience: .personal,
                privacyMode: .fullDetail,
                displayName: "Cindlet",
                currentFormName: "Cindlet",
                eyebrow: "Milestone",
                headline: "Three",
                detail: "Detail",
                secondaryDetail: "Secondary",
                footer: "Footer",
                symbolName: "sparkles",
                fileName: "three.png",
                createdAt: "2026-04-12T00:00:00.000Z"
            )
        ]

        let moments = atlasMascotAutomaticMomentCandidates(
            selection: .aetherion,
            nickname: "Nova",
            rewardsSnapshot: snapshot,
            evolutionHistory: [],
            archivedRecaps: recaps,
            existingMoments: [],
            recordedAt: Date(timeIntervalSince1970: 1_773_950_400)
        )

        XCTAssertTrue(moments.contains(where: { $0.kind == AtlasMascotMomentKind.nearEvolution }))
        XCTAssertTrue(moments.contains(where: { $0.kind == AtlasMascotMomentKind.archiveMilestone }))
        XCTAssertTrue(moments.contains(where: { $0.kind == AtlasMascotMomentKind.quietConsistency }))
    }

    func testMascotRecapDescriptorUsesLatestMomentContentWhenAvailable() {
        let snapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 620,
            level: 3,
            nextLevelPoints: 750,
            goals: [
                AtlasRewardGoalSnapshot(
                    kind: .weeklyWorkouts,
                    title: "Weekly workouts",
                    progressLabel: "3/3 complete",
                    helperText: "Goal met.",
                    symbolName: "figure.strengthtraining.traditional",
                    currentValue: 3,
                    targetValue: 3,
                    progress: 1,
                    isMet: true
                )
            ]
        )
        let moment = AtlasMascotMomentRecord(
            selection: .aurielle,
            stage: .stage2,
            kind: .interaction,
            title: "Nova glides closer",
            detail: "Glisshare mirrors your momentum with quiet focus.",
            symbolName: "wind",
            recordedAt: "2026-04-12T11:00:00.000Z"
        )

        let descriptor = atlasMascotRecapDescriptor(
            kind: .latestMoment,
            audience: .personal,
            privacyMode: .fullDetail,
            selection: .aurielle,
            nickname: "Nova",
            rewardsSnapshot: snapshot,
            evolutionHistory: [],
            moments: [moment]
        )

        XCTAssertEqual(descriptor.stage, .stage2)
        XCTAssertEqual(descriptor.headline, "Nova glides closer")
        XCTAssertEqual(descriptor.detail, "Glisshare mirrors your momentum with quiet focus.")
        XCTAssertEqual(descriptor.symbolName, "wind")
        XCTAssertTrue(descriptor.footer.contains("points"))
    }

    func testMascotArchivedRecapDescriptorPreservesSourceMomentContinuity() {
        let record = AtlasMascotArchivedRecapRecord(
            id: "continuity",
            selection: .aurielle,
            stage: .stage2,
            kind: AtlasMascotRecapCardKind.latestMoment.rawValue,
            audience: .personal,
            privacyMode: .fullDetail,
            displayName: "Nova",
            currentFormName: "Glisshare",
            eyebrow: "Latest moment",
            headline: "Nova glides closer",
            detail: "Glisshare mirrors your momentum with quiet focus.",
            secondaryDetail: "Recorded recently.",
            footer: "30 points to Aurielle.",
            symbolName: "wind",
            fileName: "continuity.png",
            createdAt: "2026-04-12T00:00:00.000Z",
            sourceMomentEventKey: "moment-1",
            sourceMomentTitle: "Nova glides closer"
        )

        let descriptor = atlasMascotArchivedRecapDescriptor(record)

        XCTAssertEqual(descriptor.sourceMomentEventKey, "moment-1")
        XCTAssertEqual(descriptor.sourceMomentTitle, "Nova glides closer")
    }

    func testMascotSharedPoseResolvesRecoveryAndEvolutionReadyStates() {
        let recoverySnapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 120,
            level: 1,
            nextLevelPoints: 250,
            streaks: [
                AtlasRewardStreakSnapshot(
                    kind: .activityDays,
                    title: "Activity days",
                    valueLabel: "Recovered",
                    helperText: "Recovered",
                    symbolName: "figure.walk",
                    count: 1,
                    isActive: true
                )
            ]
        )
        XCTAssertEqual(atlasMascotSharedPose(rewardsSnapshot: recoverySnapshot), .recovery)

        let evolutionReadySnapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 455,
            level: 2,
            nextLevelPoints: 500
        )
        XCTAssertEqual(atlasMascotSharedPose(rewardsSnapshot: evolutionReadySnapshot), .evolutionReady)
    }

    @MainActor
    func testMascotArchivedRecapPersistenceStoresMostRecentExports() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_776_000_000)

        let older = AtlasMascotArchivedRecapRecord(
            id: "older",
            selection: .aetherion,
            stage: .stage1,
            kind: AtlasMascotRecapCardKind.weeklyRecap.rawValue,
            audience: .personal,
            privacyMode: .fullDetail,
            displayName: "Cindlet",
            currentFormName: "Cindlet",
            eyebrow: "Weekly recap",
            headline: "Older recap",
            detail: "Older detail",
            secondaryDetail: "Older secondary",
            footer: "Footer",
            symbolName: "bolt.fill",
            fileName: "older.png",
            createdAt: atlasMascotMomentTimestamp(from: now.addingTimeInterval(-60))
        )
        let newer = AtlasMascotArchivedRecapRecord(
            id: "newer",
            selection: .aetherion,
            stage: .stage2,
            kind: AtlasMascotRecapCardKind.evolutionMilestone.rawValue,
            audience: .coach,
            privacyMode: .privacySafe,
            displayName: "Voltflare",
            currentFormName: "Voltflare",
            eyebrow: "Evolution milestone",
            headline: "Newer recap",
            detail: "Newer detail",
            secondaryDetail: "Newer secondary",
            footer: "Footer",
            symbolName: "sparkles",
            fileName: "newer.png",
            createdAt: atlasMascotMomentTimestamp(from: now)
        )

        _ = try await controller.container.settings.recordMascotArchivedRecap(older, now: now.addingTimeInterval(-60))
        let snapshot = try await controller.container.settings.recordMascotArchivedRecap(newer, now: now)

        XCTAssertEqual(snapshot.mascotArchivedRecaps.map(\.id), ["newer", "older"])
    }

    @MainActor
    func testMascotRecapNotificationSettingsPersist() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_776_000_100)

        let snapshot = try await controller.container.settings.updateMascotRecapNotificationSettings(
            AtlasMascotRecapNotificationSettings(dailyEnabled: false, weeklyEnabled: true),
            now: now
        )

        XCTAssertFalse(snapshot.mascotRecapNotificationSettings.dailyEnabled)
        XCTAssertTrue(snapshot.mascotRecapNotificationSettings.weeklyEnabled)
    }

    func testMascotTimelineNotificationRequestsCreateDailyAndWeeklyRecapsWhenProgressExists() {
        let referenceDate = Date(timeIntervalSince1970: 1_776_000_200)
        let recordedAt = atlasMascotMomentTimestamp(from: referenceDate.addingTimeInterval(-2 * 60 * 60))
        let snapshot = AtlasRewardsSnapshot(
            settings: AtlasRewardsSettingsSnapshot(enabled: true),
            totalPoints: 840,
            level: 4,
            nextLevelPoints: 1_000,
            goals: [
                AtlasRewardGoalSnapshot(
                    kind: .weeklyWorkouts,
                    title: "Weekly workouts",
                    progressLabel: "4/4 complete",
                    helperText: "Closed out.",
                    symbolName: "figure.strengthtraining.traditional",
                    currentValue: 4,
                    targetValue: 4,
                    progress: 1,
                    isMet: true
                )
            ]
        )
        let moment = AtlasMascotMomentRecord(
            selection: .aetherion,
            stage: .stage2,
            kind: .goal,
            title: "Voltflare noticed the closeout",
            detail: "Weekly workouts were completed and recorded.",
            symbolName: "flag.checkered",
            recordedAt: recordedAt
        )

        let requests = atlasMascotTimelineNotificationRequests(
            selection: .aetherion,
            nickname: "Nova",
            notificationSettings: AtlasMascotRecapNotificationSettings(dailyEnabled: true, weeklyEnabled: true),
            rewardsSnapshot: snapshot,
            evolutionHistory: [],
            moments: [moment],
            referenceDate: referenceDate
        )

        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests.first?.identifier.contains("atlas.mascot.recap.daily"), true)
        XCTAssertEqual(requests.last?.identifier.contains("atlas.mascot.recap.weekly"), true)
        XCTAssertTrue(requests.allSatisfy { $0.body.isEmpty == false })
    }

    @MainActor
    func testRefreshShellDataWritesMascotProjectionSnapshot() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let model = makeAppModel(controller: controller)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.settings.updateMascotSelection(.aurielle, now: now)
        _ = try await controller.container.settings.updateMascotNickname("Nova", now: now)
        _ = try await controller.container.settings.updateRewardsSettings(
            AtlasRewardsSettingsUpdate(enabled: true),
            now: now
        )
        _ = try await controller.container.settings.recordMascotMoment(
            AtlasMascotMomentRecord(
                selection: .aurielle,
                stage: .stage1,
                kind: .interaction,
                title: "Nova perks up",
                detail: "Moppet brightens the moment when you stop by.",
                symbolName: "star.fill",
                recordedAt: atlasMascotMomentTimestamp(from: now)
            ),
            now: now
        )

        await model.refreshShellData()
        let snapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        XCTAssertEqual(snapshot?.mascot?.selection, .aurielle)
        XCTAssertEqual(snapshot?.mascot?.stage, .stage1)
        XCTAssertEqual(snapshot?.mascot?.currentFormName, "Moppet")
        XCTAssertEqual(snapshot?.mascot?.nickname, "Nova")
        XCTAssertEqual(snapshot?.mascot?.displayName, "Nova")
        XCTAssertFalse(snapshot?.mascot?.statusLine.isEmpty ?? true)
        XCTAssertEqual(snapshot?.mascot?.nextThresholdPoints, 500)
        XCTAssertEqual(snapshot?.mascot?.latestMomentTitle, "Nova perks up")
        XCTAssertEqual(snapshot?.mascot?.latestMomentSymbolName, "star.fill")
    }

    func testExtensionProjectionFreshnessUsesSurfaceSpecificWindows() {
        let generatedAt = Date(timeIntervalSince1970: 1_773_950_400)

        let nextDueFreshness = AtlasExtensionProjectionFreshness(
            surface: .nextDueWidget,
            generatedAt: generatedAt,
            referenceDate: generatedAt.addingTimeInterval(3 * 60 * 60)
        )
        let intentFreshness = AtlasExtensionProjectionFreshness(
            surface: .nextDueIntent,
            generatedAt: generatedAt,
            referenceDate: generatedAt.addingTimeInterval(3 * 60 * 60)
        )
        let lowStockFreshness = AtlasExtensionProjectionFreshness(
            surface: .lowStockWidget,
            generatedAt: generatedAt,
            referenceDate: generatedAt.addingTimeInterval(3 * 60 * 60)
        )
        let mascotFreshness = AtlasExtensionProjectionFreshness(
            surface: .mascotWidget,
            generatedAt: generatedAt,
            referenceDate: generatedAt.addingTimeInterval(3 * 60 * 60)
        )

        XCTAssertTrue(nextDueFreshness.isStale)
        XCTAssertTrue(intentFreshness.isStale)
        XCTAssertTrue(mascotFreshness.isStale)
        XCTAssertFalse(lowStockFreshness.isStale)
    }

    @MainActor
    func testHandleIncomingMascotURLOpensMascotRoute() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Mascot route protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        let url = try XCTUnwrap(URL(string: "atlas://mascot"))

        await model.handleIncomingURL(url)

        XCTAssertEqual(model.activeTab, .today)
        XCTAssertEqual(model.routePath.last, .mascot)
    }

    @MainActor
    func testHandleIncomingMascotMomentURLRecordsMomentAndOpensMascotRoute() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Mascot moment protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.settings.updateMascotSelection(.aetherion, now: now)
        _ = try await controller.container.settings.updateRewardsSettings(
            AtlasRewardsSettingsUpdate(enabled: true),
            now: now
        )

        await model.refreshShellData()

        let url = try XCTUnwrap(URL(string: "atlas://mascot-moment?kind=shortcut"))
        await model.handleIncomingURL(url)

        XCTAssertEqual(model.activeTab, .today)
        XCTAssertEqual(model.routePath.last, .mascot)
        XCTAssertEqual(model.settingsSnapshot.mascotMoments.first?.kind, .shortcut)
    }

    @MainActor
    func testWeeklyReviewRouteCanBeOpenedFromModel() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)

        model.open(.weeklyReview)

        XCTAssertEqual(model.routePath.last, .weeklyReview)
    }

    @MainActor
    func testRefreshShellDataOnEmptyTemporaryStoreDoesNotSurfaceStartupError() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)

        await model.refreshShellData()
        await model.refreshShellData()

        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.loadErrorMessage)
        XCTAssertFalse(model.todaySnapshot.hasProtocols)
        XCTAssertNil(model.todaySnapshot.nextDue)
    }

    @MainActor
    func testRefreshShellDataIgnoresReminderSyncFailures() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(
            controller: controller,
            reminders: FailingReminderCoordinator(),
            referenceDate: now
        )

        await model.refreshShellData()

        XCTAssertNil(model.loadErrorMessage)
        XCTAssertFalse(model.todaySnapshot.hasProtocols)
        XCTAssertEqual(model.reminderSettings, AtlasReminderSettingsSnapshot())
    }

    @MainActor
    func testCreateProtocolSucceedsWhenReminderSyncFails() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(
            controller: controller,
            reminders: FailingReminderCoordinator(),
            referenceDate: now
        )

        let detail = await model.createProtocol(
            AtlasProtocolDraft(
                name: "Reminder fallback",
                kind: .peptide,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            )
        )

        XCTAssertEqual(detail?.canonicalTitle, "Reminder fallback")
        XCTAssertNil(model.loadErrorMessage)
        XCTAssertEqual(model.libraryProtocols.count, 1)
    }

    @MainActor
    func testHandleIncomingQuickLogURLLogsOccurrenceAndRefreshesProjection() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, referenceDate: now)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Quick log protocol",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let vial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Quick log vial",
                protocolID: detail.id,
                startingQuantity: 4,
                remainingQuantity: 4,
                quantityUnit: "mg"
            ),
            now: now
        )

        await model.refreshShellData()
        let occurrence = try XCTUnwrap(model.todaySnapshot.nextDue)
        try await controller.sharedProjectionWriter.refreshProjection(referenceDate: now)
        let previousSnapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        let url = try XCTUnwrap(
            URL(string: "atlas://quick-log?action=taken&occurrenceId=\(occurrence.id)&protocolId=\(detail.id)")
        )
        await model.handleIncomingURL(url)

        let history = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .dosing, protocolID: detail.id, limit: 20)
        )
        let vialDetail = try await controller.container.inventory.fetchVialDetail(
            id: vial.summary.id,
            referenceDate: now
        )
        let refreshedToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let updatedSnapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        let refreshedVial = try XCTUnwrap(vialDetail)

        XCTAssertTrue(history.contains(where: { $0.type == .doseTaken }))
        XCTAssertEqual(refreshedVial.summary.remainingQuantity, 3, accuracy: 0.001)
        XCTAssertNotEqual(refreshedToday.nextDue?.id, occurrence.id)
        XCTAssertTrue(previousSnapshot?.quickActions.contains(where: { $0.occurrenceID == occurrence.id }) ?? false)
        XCTAssertFalse(updatedSnapshot?.quickActions.contains(where: { $0.occurrenceID == occurrence.id }) ?? true)
    }

    @MainActor
    func testHandleIncomingMetricURLsWriteWeightAndSymptomEntries() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://weight-entry?value=182.4&unit=lb&notes=Morning")!)
        await model.handleIncomingURL(URL(string: "atlas://symptom-entry?symptom=Energy&severity=4&notes=Steady")!)

        XCTAssertEqual(model.insightsSnapshot.recentWeightEntries.first?.valueLabel, "182.4 lb")
        XCTAssertEqual(model.insightsSnapshot.recentSymptomEntries.first?.symptomKey, "energy")
        XCTAssertEqual(model.insightsSnapshot.recentSymptomEntries.first?.severity, 4)
    }

    @MainActor
    func testHandleIncomingTrustVaultURLOpensTrustVaultFromSettings() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://trust-vault")!)

        XCTAssertEqual(model.activeTab, .settings)
        XCTAssertEqual(model.routePath, [.trustVault])
    }

    @MainActor
    func testHandleIncomingWatchCompanionURLOpensCompanionRoute() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://watch-companion")!)

        XCTAssertEqual(model.activeTab, .today)
        XCTAssertEqual(model.routePath, [.watchCompanion])
    }

    @MainActor
    func testHandleIncomingCompoundIntelligenceURLOpensLibraryRoute() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://compound-intelligence?slug=semaglutide")!)

        XCTAssertEqual(model.activeTab, .library)
        XCTAssertEqual(model.routePath, [.compoundIntelligence("semaglutide")])
    }

    @MainActor
    func testHandleIncomingContextShortcutURLWritesHydrationEntry() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Watch shortcut protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: importedFixtureReferenceDate
        )

        await model.handleIncomingURL(URL(string: "atlas://context-shortcut?kind=hydration")!)

        let refreshed = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: importedFixtureReferenceDate)
        XCTAssertEqual(refreshed.recentContextEntries.first?.hydration, .high)
        XCTAssertTrue(refreshed.recentContextEntries.first?.tags.contains("today-quick-capture") ?? false)
    }

    @MainActor
    func testHandleIncomingQuickCaptureURLOpensTodayQuickCaptureLane() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://quick-capture?kind=weight")!)

        XCTAssertEqual(model.activeTab, .today)
        XCTAssertEqual(model.routePath, [.quickCapture(.weight)])
    }

    @MainActor
    func testHandleIncomingProgressEvidenceURLOpensInsightsProgressEvidence() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)
        try await completeOnboardingIfNeeded(controller: controller)

        await model.handleIncomingURL(URL(string: "atlas://progress-evidence")!)

        XCTAssertEqual(model.activeTab, .insights)
        XCTAssertEqual(model.routePath, [.progressEvidence])
    }

    func testContextEntryPersistenceTimelineAndDiscreetPrivacyStayCalm() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Context protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(1800),
                mealTiming: .breakfast,
                fedState: .fasted,
                appetite: .low,
                hydration: .low,
                giTags: [.nausea],
                note: "Coffee only",
                tags: ["travel", "pre-dose"]
            ),
            now: now.addingTimeInterval(1800)
        )

        let insights = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now.addingTimeInterval(1800))
        let timeline = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .wellness, protocolID: protocolDetail.id, limit: 20)
        )

        XCTAssertEqual(insights.contextTrend.recentEntryCount, 1)
        XCTAssertEqual(insights.recentContextEntries.first?.mealTiming, .breakfast)
        XCTAssertEqual(insights.recentContextEntries.first?.fedState, .fasted)
        XCTAssertEqual(insights.recentContextEntries.first?.hydration, .low)
        XCTAssertEqual(timeline.first?.type, .contextLogged)
        XCTAssertTrue(timeline.first?.summary.lowercased().contains("breakfast") ?? false)

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now.addingTimeInterval(3600))
        let discreetTimeline = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .wellness, protocolID: protocolDetail.id, limit: 20)
        )

        XCTAssertEqual(discreetTimeline.first?.summary, "Logged private context")
    }

    func testContextLogsRoundTripThroughJsonExportAndImport() async throws {
        let directory = try makeTemporaryDirectory()
        let sourceController = try AtlasPersistenceController.temporary(
            baseURL: directory.appendingPathComponent("source", isDirectory: true),
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let protocolDetail = try await sourceController.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Round-trip protocol",
                kind: .glp,
                cadenceType: .weekly,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await sourceController.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                protocolID: protocolDetail.id,
                loggedAt: now,
                mealTiming: .dinner,
                fedState: .fed,
                appetite: .typical,
                hydration: .high,
                giTags: [.calm],
                note: "Felt steady",
                tags: ["routine"]
            ),
            now: now
        )

        let export = try await sourceController.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now
        )
        let decoded = try JSONDecoder().decode(AtlasExportBundle.self, from: Data(contentsOf: export.fileURL))
        let exportedContext = try XCTUnwrap(decoded.snapshot.contextLogs.first)
        XCTAssertEqual(exportedContext.mealTiming, .dinner)
        XCTAssertEqual(exportedContext.note, "Felt steady")
        XCTAssertEqual(exportedContext.tags, ["routine"])

        let targetController = try AtlasPersistenceController.temporary(
            baseURL: directory.appendingPathComponent("target", isDirectory: true),
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let prepared = try await targetController.importExportBridge.prepareImport(at: export.fileURL)
        _ = try await targetController.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let importedInsights = try await targetController.container.metrics.fetchInsightsSnapshot(referenceDate: now)

        XCTAssertEqual(importedInsights.recentContextEntries.count, 1)
        XCTAssertEqual(importedInsights.recentContextEntries.first?.mealTiming, .dinner)
        XCTAssertEqual(importedInsights.recentContextEntries.first?.note, "Felt steady")
        XCTAssertEqual(importedInsights.recentContextEntries.first?.tags, ["routine"])
    }

    func testContextLogsFeedEpisodeWindowCountsAndPatterns() async throws {
        let controller = try makeInMemoryController()
        var bundle = makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: false, sparse: false)
        bundle.snapshot.contextLogs = [
            AtlasContextLogRecord.make(
                id: "context_episode_1",
                protocolId: "p1",
                loggedAt: "2026-02-22T09:10:00.000Z",
                mealTiming: .breakfast,
                mealSize: nil,
                mealComposition: nil,
                fedState: .fasted,
                appetite: .low,
                hydration: .low,
                giTags: [.nausea],
                note: nil,
                tags: [],
                presetKey: nil,
                source: .manual,
                createdAt: "2026-02-22T09:10:00.000Z",
                updatedAt: "2026-02-22T09:10:00.000Z"
            ),
            AtlasContextLogRecord.make(
                id: "context_episode_2",
                protocolId: "p1",
                loggedAt: "2026-03-01T09:20:00.000Z",
                mealTiming: .breakfast,
                mealSize: nil,
                mealComposition: nil,
                fedState: .fasted,
                appetite: .low,
                hydration: .low,
                giTags: [.nausea],
                note: nil,
                tags: [],
                presetKey: nil,
                source: .manual,
                createdAt: "2026-03-01T09:20:00.000Z",
                updatedAt: "2026-03-01T09:20:00.000Z"
            ),
            AtlasContextLogRecord.make(
                id: "context_episode_3",
                protocolId: "p1",
                loggedAt: "2026-03-08T09:25:00.000Z",
                mealTiming: .breakfast,
                mealSize: nil,
                mealComposition: nil,
                fedState: .fasted,
                appetite: .low,
                hydration: .low,
                giTags: [.nausea],
                note: nil,
                tags: [],
                presetKey: nil,
                source: .manual,
                createdAt: "2026-03-08T09:25:00.000Z",
                updatedAt: "2026-03-08T09:25:00.000Z"
            )
        ]
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())
        let earlyWindow = try XCTUnwrap(
            snapshot.episodeIntelligence.compareWindows.first(where: { $0.windowKind == .postDose0To12Hours })
        )

        XCTAssertGreaterThanOrEqual(earlyWindow.contextEntryCount, 3)
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.contains(where: { $0.type == .contextCluster }))
        XCTAssertGreaterThanOrEqual(snapshot.episodeIntelligence.recentEpisodes.first?.contextEntryCount ?? 0, 1)
    }

    func testDiscreetExportStripsContextNotesAndTags() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now,
                mealTiming: .snack,
                fedState: .fed,
                giTags: [.bloating],
                note: "Very specific context note",
                tags: ["private-tag"]
            ),
            now: now
        )

        let export = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .discreet),
            now: now
        )
        let decoded = try JSONDecoder().decode(AtlasExportBundle.self, from: Data(contentsOf: export.fileURL))
        let context = try XCTUnwrap(decoded.snapshot.contextLogs.first)
        let preview = try await controller.importExportBridge.previewSelectiveShare(
            AtlasSelectiveShareRequest(scopeKind: .symptomsOnly, renderMode: .discreet),
            now: now
        )

        XCTAssertNil(context.note)
        XCTAssertTrue(context.tags.isEmpty)
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "contextLogs" && $0.rowCount == 1 }))
    }

    func testSummarySettingsDefaultOffAndCanBeEnabled() async throws {
        let controller = try makeInMemoryController()

        let initial = try await controller.container.settings.currentSettingsSnapshot()
        XCTAssertFalse(initial.summarySettings.onDeviceEnabled)
        XCTAssertFalse(initial.summarySettings.externalProviderEnabled)

        let updated = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(onDeviceEnabled: true),
            now: Date()
        )

        XCTAssertTrue(updated.summarySettings.onDeviceEnabled)
        XCTAssertFalse(updated.summarySettings.externalProviderEnabled)
    }

    func testInsightsSummariesStayBoundedAndRespectDiscreetRendering() async throws {
        let controller = try makeInMemoryController()
        _ = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(onDeviceEnabled: true),
            now: importedFixtureReferenceDate
        )

        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let fullSnapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: importedFixtureReferenceDate
        )
        let weeklySummary = try XCTUnwrap(fullSnapshot.weeklyRecapSummary)
        XCTAssertEqual(weeklySummary.executionMode, .deterministicLocal)
        XCTAssertTrue(weeklySummary.executionMode.label.contains("On-device"))
        XCTAssertTrue(weeklySummary.sourceSections.contains(where: { $0.id == "weekly_activity" }))
        XCTAssertTrue(
            weeklySummary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "active_protocols" && $0.value == "1" })
        )
        XCTAssertTrue(
            weeklySummary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "next_due" && $0.value.contains("Weekly GLP") })
        )
        XCTAssertTrue(weeklySummary.summary.contains("active protocol"))
        XCTAssertTrue(weeklySummary.summary.contains("No additional context or symptom entries"))
        assertSummaryGuardrails(weeklySummary.summary)

        _ = try await controller.container.settings.updateTrustVaultRenderMode(
            .discreet,
            now: importedFixtureReferenceDate.addingTimeInterval(60)
        )
        let discreetSnapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: importedFixtureReferenceDate
        )
        let discreetSummary = try XCTUnwrap(discreetSnapshot.weeklyRecapSummary)
        XCTAssertFalse(
            discreetSummary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.value.contains("Weekly GLP") })
        )
        XCTAssertTrue(
            discreetSummary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "next_due" && $0.value.contains("Private protocol") })
        )
        assertSummaryGuardrails(discreetSummary.summary)
    }

    func testEpisodeAndImportSummariesRemainOptionalAndGrounded() async throws {
        let controller = try makeInMemoryController()
        let disabledPrepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        XCTAssertNil(disabledPrepared.dryRun.plainLanguageSummary)

        _ = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(onDeviceEnabled: true),
            now: Date()
        )

        var bundle = makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: false, sparse: false)
        bundle.snapshot.contextLogs = [
            AtlasContextLogRecord.make(
                id: "summary_context_1",
                protocolId: "p1",
                loggedAt: "2026-03-08T09:10:00.000Z",
                mealTiming: .breakfast,
                mealSize: nil,
                mealComposition: nil,
                fedState: .fasted,
                appetite: .low,
                hydration: .low,
                giTags: [.nausea],
                note: nil,
                tags: [],
                presetKey: nil,
                source: .manual,
                createdAt: "2026-03-08T09:10:00.000Z",
                updatedAt: "2026-03-08T09:10:00.000Z"
            )
        ]
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let insights = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())
        let episodeSummary = try XCTUnwrap(insights.episodeRecapSummary)
        XCTAssertTrue(episodeSummary.sourceSections.contains(where: { $0.id == "episode_scope" }))
        XCTAssertTrue(
            episodeSummary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "pattern_count" && $0.value == String(insights.episodeIntelligence.patternCards.count) })
        )
        XCTAssertTrue(episodeSummary.summary.contains("Atlas currently shows"))
        assertSummaryGuardrails(episodeSummary.summary)

        let importPrepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        let dryRun = importPrepared.dryRun
        let importSummary = try XCTUnwrap(dryRun.plainLanguageSummary)
        XCTAssertTrue(importSummary.sourceSections.flatMap(\.facts).contains(where: { $0.id == "records_to_create" }))
        XCTAssertTrue(importSummary.sourceSections.flatMap(\.facts).contains(where: { $0.id == "source_label" }))
        XCTAssertTrue(importSummary.disclaimer.contains("generated locally"))
        XCTAssertTrue(importSummary.summary.contains("dry run would create"))
        assertSummaryGuardrails(importSummary.summary)
    }

    func testDeferredExternalSummaryFallsBackToLocalRecap() async throws {
        let controller = try makeInMemoryController(
            featureFlags: AtlasFeatureFlagState(
                boundedSummaries: true,
                externalSummaryProviders: true
            )
        )
        _ = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(
                onDeviceEnabled: true,
                externalProviderEnabled: true,
                externalProviderConsentRecordedAt: importedFixtureReferenceDate
            ),
            now: importedFixtureReferenceDate
        )

        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: importedFixtureReferenceDate
        )
        let summary = try XCTUnwrap(snapshot.weeklyRecapSummary)
        XCTAssertEqual(summary.executionMode, .deterministicLocal)
        XCTAssertTrue(summary.summary.contains("active protocol"))
        assertSummaryGuardrails(summary.summary)
    }

    func testWeeklyReviewSeedBuildsEvenWhenPlainLanguageSummariesAreOff() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: importedFixtureReferenceDate
        )
        let weeklyReview = try XCTUnwrap(snapshot.weeklyReviewSeed)

        XCTAssertTrue(weeklyReview.periodTitle.contains("-"))
        XCTAssertFalse(weeklyReview.summarySettingEnabled)
        XCTAssertNil(weeklyReview.plainLanguageSummary)
        XCTAssertTrue(weeklyReview.fallbackSummary.contains("Last 7 days"))
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_activity" }))
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_supporting_records" }))
        XCTAssertFalse(snapshot.weeklyReviewHistory.isEmpty)
        XCTAssertTrue(
            weeklyReview.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "next_due" && $0.value.contains("Weekly GLP") })
        )
    }

    @MainActor
    func testWeeklyReviewPresentationIntegratesRewardsAndReviewStatus() async throws {
        let controller = try makeInMemoryController()
        _ = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(onDeviceEnabled: true),
            now: importedFixtureReferenceDate
        )
        _ = try await controller.container.settings.updateRewardsSettings(
            AtlasRewardsSettingsUpdate(enabled: true),
            now: importedFixtureReferenceDate
        )
        _ = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true),
            now: importedFixtureReferenceDate
        )

        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        await model.refreshShellData()

        let weeklyReview = try XCTUnwrap(model.weeklyReviewPresentation())
        XCTAssertTrue(weeklyReview.summaryText.contains("active protocol"))
        XCTAssertTrue(weeklyReview.highlights.contains(where: { $0.id == "adherence" }))
        XCTAssertTrue(weeklyReview.highlights.contains(where: { $0.id == "rewards" }))
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_rewards" }))
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_review_status" }))
        XCTAssertTrue(
            weeklyReview.actions.contains(where: { action in
                if case .markReviewComplete = action.destination {
                    return true
                }
                return false
            })
        )

        await model.markWeeklyReviewComplete()

        let updatedReview = try XCTUnwrap(model.weeklyReviewPresentation())
        XCTAssertTrue(updatedReview.isMarkedReviewed)
        XCTAssertFalse(
            updatedReview.actions.contains(where: { action in
                if case .markReviewComplete = action.destination {
                    return true
                }
                return false
            })
        )
    }

    @MainActor
    func testWeeklyReviewReminderAndSavedActionsPersist() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(
            controller: controller,
            notifications: notifications,
            referenceDate: importedFixtureReferenceDate
        )
        await model.refreshShellData()
        await model.updateWeeklyReviewReminderSettings(.init(enabled: true))

        XCTAssertTrue(model.settingsSnapshot.weeklyReviewReminderSettings.enabled)
        let pendingNotifications = await notifications.pendingMascotNotifications()
        XCTAssertTrue(pendingNotifications.contains(where: { $0.identifier == "atlas.weekly-review" }))

        let weeklyReview = try XCTUnwrap(model.weeklyReviewPresentation())
        let action = try XCTUnwrap(
            weeklyReview.actions.first(where: { action in
                if case .markReviewComplete = action.destination {
                    return false
                }
                return true
            })
        )

        await model.saveWeeklyReviewActionPlan(action, seed: weeklyReview.seed)

        let saved = try XCTUnwrap(model.settingsSnapshot.weeklyReviewActionPlans.first)
        XCTAssertEqual(saved.title, action.title)
        XCTAssertEqual(saved.detail, action.detail)

        await model.updateWeeklyReviewActionPlan(
            id: saved.id,
            isCompleted: true,
            isPinnedForNextWeek: false
        )

        let updated = try XCTUnwrap(model.settingsSnapshot.weeklyReviewActionPlans.first)
        XCTAssertTrue(updated.isCompleted)
        XCTAssertFalse(updated.isPinnedForNextWeek)

        await model.removeWeeklyReviewActionPlan(id: saved.id)

        XCTAssertTrue(model.settingsSnapshot.weeklyReviewActionPlans.isEmpty)
    }

    @MainActor
    func testWeeklyReviewArchiveComparisonAndActionOutcomes() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        await model.refreshShellData()

        let currentReview = try XCTUnwrap(model.weeklyReviewPresentation())
        let previousStart = Calendar.current.date(byAdding: .day, value: -7, to: currentReview.seed.windowStart)
        let previousEnd = currentReview.seed.windowStart.addingTimeInterval(-60)
        let reviewPeriodStart = ISO8601DateFormatter.atlas.string(from: try XCTUnwrap(previousStart))
        let reviewPeriodEnd = ISO8601DateFormatter.atlas.string(from: previousEnd)

        _ = try await controller.container.settings.saveWeeklyReviewActionPlan(
            AtlasWeeklyReviewActionPlan(
                id: "prior-carry",
                title: "Keep one focus alive",
                detail: "Still visible in the next review.",
                symbolName: "arrow.triangle.branch",
                route: .today,
                reviewPeriodStart: reviewPeriodStart,
                reviewPeriodEnd: reviewPeriodEnd,
                createdAt: ISO8601DateFormatter.atlas.string(from: importedFixtureReferenceDate),
                isPinnedForNextWeek: true,
                isCompleted: false
            ),
            now: importedFixtureReferenceDate
        )
        _ = try await controller.container.settings.saveWeeklyReviewActionPlan(
            AtlasWeeklyReviewActionPlan(
                id: "prior-done",
                title: "Close one weekly target",
                detail: "Marked complete before the next review.",
                symbolName: "checkmark.circle.fill",
                route: .insights,
                reviewPeriodStart: reviewPeriodStart,
                reviewPeriodEnd: reviewPeriodEnd,
                createdAt: ISO8601DateFormatter.atlas.string(from: importedFixtureReferenceDate.addingTimeInterval(120)),
                isPinnedForNextWeek: false,
                isCompleted: true
            ),
            now: importedFixtureReferenceDate
        )

        await model.refreshShellData()

        let updatedReview = try XCTUnwrap(model.weeklyReviewPresentation())
        XCTAssertNotNil(updatedReview.comparison)
        let outcomes = try XCTUnwrap(updatedReview.actionOutcomes)
        XCTAssertEqual(outcomes.previousPeriodTitle, "\(try XCTUnwrap(previousStart).formatted(date: .abbreviated, time: .omitted)) - \(previousEnd.formatted(date: .abbreviated, time: .omitted))")
        XCTAssertEqual(outcomes.items.count, 2)
        XCTAssertTrue(outcomes.items.contains(where: { $0.statusLabel == "Carried" }))
        XCTAssertTrue(outcomes.items.contains(where: { $0.statusLabel == "Completed" }))
    }

    @MainActor
    func testWeeklyReviewExportWritesDedicatedArtifact() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        await model.refreshShellData()

        let currentReview = try XCTUnwrap(model.weeklyReviewPresentation())
        let previousStart = Calendar.current.date(byAdding: .day, value: -7, to: currentReview.seed.windowStart)
        let previousEnd = currentReview.seed.windowStart.addingTimeInterval(-60)
        _ = try await controller.container.settings.saveWeeklyReviewActionPlan(
            AtlasWeeklyReviewActionPlan(
                id: "export-prior",
                title: "Carry a focus into export",
                detail: "Used to validate the dedicated weekly review artifact.",
                symbolName: "square.and.arrow.up",
                route: .settings,
                reviewPeriodStart: ISO8601DateFormatter.atlas.string(from: try XCTUnwrap(previousStart)),
                reviewPeriodEnd: ISO8601DateFormatter.atlas.string(from: previousEnd),
                createdAt: ISO8601DateFormatter.atlas.string(from: importedFixtureReferenceDate),
                isPinnedForNextWeek: true,
                isCompleted: false
            ),
            now: importedFixtureReferenceDate
        )

        await model.refreshShellData()
        let review = try XCTUnwrap(model.weeklyReviewPresentation())

        let exportURL = try atlasWriteWeeklyReviewExport(snapshot: review)
        let html = try String(contentsOf: exportURL, encoding: .utf8)
        let jsonURL = exportURL.deletingLastPathComponent().appendingPathComponent("weekly-review.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path))
        XCTAssertTrue(html.contains("Atlas Weekly Review"))
        XCTAssertTrue(html.contains("Archive &amp; compare"))
        XCTAssertTrue(html.contains("Action follow-through"))
        XCTAssertTrue(html.contains("Next actions"))
    }

    func testWeeklyReviewSeedIncludesProtocolChangeOutcomeFacts() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_086_400)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Review protocol",
                kind: .custom,
                cadenceType: .weekly,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: protocolDetail.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .futureDose,
                effectiveDate: now,
                doseAmount: 2,
                doseUnit: "mg",
                timeOfDay: "09:00"
            ),
            referenceDate: now
        )

        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: now)
        let todaySnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(todaySnapshot.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken,
                note: nil
            ),
            now: now.addingTimeInterval(600)
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(900),
                note: "Context around the change"
            ),
            now: now.addingTimeInterval(900)
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(1_200)
        )
        let weeklyReview = try XCTUnwrap(snapshot.weeklyReviewSeed)
        let protocolChangeSummary = try XCTUnwrap(weeklyReview.protocolChangeSummary)
        let followUpSummary = try XCTUnwrap(weeklyReview.protocolFollowUpSummary)

        XCTAssertEqual(protocolChangeSummary.changeCount, 1)
        XCTAssertEqual(protocolChangeSummary.latestProtocolID, protocolDetail.id)
        XCTAssertEqual(protocolChangeSummary.supportingLogCount, 1)
        XCTAssertEqual(protocolChangeSummary.supportingContextCount, 1)
        XCTAssertEqual(followUpSummary.protocolID, protocolDetail.id)
        XCTAssertEqual(followUpSummary.completedCount, 1)
        XCTAssertEqual(followUpSummary.contextEntryCount, 1)
        XCTAssertTrue(followUpSummary.hasVisibleSupportingData)
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_protocol_changes" }))
        XCTAssertTrue(weeklyReview.sourceSections.contains(where: { $0.id == "weekly_protocol_follow_up" }))
    }

    func testImportCommitWritesExtensionProjectionSnapshot() async throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: true)
        ))

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let snapshot = try await controller.sharedProjectionWriter.loadExtensionProjectionSnapshot()

        XCTAssertEqual(snapshot?.renderMode, .alias)
        XCTAssertEqual(snapshot?.nextDue?.displayTitle, "Evening plan")
        XCTAssertFalse(snapshot?.quickActions.isEmpty ?? true)
    }

    func testImmutableHistoryRemainsSeparateFromNextDueProjection() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: false)
        ))

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: importedFixtureReferenceDate)
        let history = try await controller.container.timeline.fetchHistory(limit: 10)
        let nextDue = try await controller.container.today.fetchTodaySnapshot(referenceDate: importedFixtureReferenceDate).nextDue

        XCTAssertEqual(history.count, 1)
        XCTAssertNotNil(nextDue)
        XCTAssertNotEqual(history.first?.id, nextDue?.id)
        XCTAssertEqual(history.first?.protocolID, nextDue?.protocolID)
    }

    @MainActor
    func testHistoricalShellRefreshReprojectsPendingOccurrencesForReferenceDate() async throws {
        let controller = try makeInMemoryController()
        let bundle = try XCTUnwrap(makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle)
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        await model.refreshShellData()

        XCTAssertEqual(model.todaySnapshot.nextDue?.canonicalTitle, "Weekly GLP")
    }

    func testTemporaryControllerCreatesDatabaseFiles() throws {
        let directory = try makeTemporaryDirectory()
        let controller = try AtlasPersistenceController.temporary(
            baseURL: directory,
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: controller.locations?.canonicalDatabaseURL.path ?? ""))
        XCTAssertTrue(FileManager.default.fileExists(atPath: controller.locations?.projectionDatabaseURL.path ?? ""))
    }

    func testBlankFixtureImportsWithoutProtocolsOrNextDue() async throws {
        let controller = try makeInMemoryController()
        let fixture = makeBlankBundle()

        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(fixture))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        XCTAssertEqual(prepared.dryRun.validation.manifest.version, 1)
        XCTAssertTrue(prepared.dryRun.validation.unsupportedDatasets.isEmpty)
        XCTAssertEqual(prepared.dryRun.recordsToUpdate, 2)
        XCTAssertTrue(prepared.dryRun.warnings.contains(where: { $0.contains("does not contain any protocols") }))
        XCTAssertTrue(model.libraryProtocols.isEmpty)
        XCTAssertNil(model.todaySnapshot.nextDue)
        XCTAssertTrue(model.timelineEntries.isEmpty)
    }

    func testFixtureMatrixCoversPhaseTwoMigrationScenarios() async throws {
        for fixture in makePhaseTwoFixtures() {
            let controller = try makeInMemoryController()
            let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(fixture.bundle))
            _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
            try await controller.container.coreLoop.ensureProjectedOccurrences(
                referenceDate: importedFixtureReferenceDate
            )
            let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
            await model.refreshShellData()
            let projectionState = try await controller.sharedProjectionWriter.loadProjectionDebugState()

            XCTAssertEqual(
                prepared.dryRun.validation.manifest.version,
                1,
                "Fixture \(fixture.name) should validate Atlas Export v1."
            )
            XCTAssertTrue(
                prepared.dryRun.validation.unsupportedDatasets.isEmpty,
                "Fixture \(fixture.name) should not introduce unsupported datasets."
            )
            XCTAssertEqual(
                model.libraryProtocols.count,
                fixture.expectedProtocolCount,
                "Fixture \(fixture.name) should import the expected number of protocols."
            )
            let immutableHistory = try await controller.container.timeline.fetchHistory(limit: 100)
            XCTAssertEqual(
                immutableHistory.count,
                fixture.expectedHistoryCount,
                "Fixture \(fixture.name) should preserve immutable history counts."
            )

            if fixture.expectsNextDue {
                XCTAssertNotNil(model.todaySnapshot.nextDue, "Fixture \(fixture.name) should surface Today data.")
                XCTAssertNotNil(projectionState.nextDue, "Fixture \(fixture.name) should populate extension-safe next due projections.")
            } else {
                XCTAssertNil(model.todaySnapshot.nextDue, "Fixture \(fixture.name) should not surface Today data.")
            }

            if let expectedRenderedTitle = fixture.expectedRenderedTitle {
                XCTAssertEqual(
                    model.todaySnapshot.nextDue.map { model.renderedTitle(canonical: $0.canonicalTitle, alias: $0.aliasTitle) },
                    expectedRenderedTitle,
                    "Fixture \(fixture.name) should render through the native privacy layer."
                )
            }

            if let expectedProjectionTitle = fixture.expectedProjectionTitle {
                XCTAssertEqual(
                    projectionState.nextDue?.displayTitle,
                    expectedProjectionTitle,
                    "Fixture \(fixture.name) should project privacy-safe labels for extensions."
                )
            }

            for expectedDataset in fixture.expectedCreatedDatasets {
                XCTAssertTrue(
                    prepared.dryRun.datasetDiffs.contains(where: { $0.dataset == expectedDataset.0 && $0.creates == expectedDataset.1 }),
                    "Fixture \(fixture.name) should create \(expectedDataset.1) row(s) for dataset \(expectedDataset.0)."
                )
            }

            for warningFragment in fixture.expectedWarningFragments {
                XCTAssertTrue(
                    prepared.dryRun.warnings.contains(where: { $0.contains(warningFragment) }),
                    "Fixture \(fixture.name) should surface warning '\(warningFragment)'."
                )
            }

            for backfillFragment in fixture.expectedBackfillFragments {
                XCTAssertTrue(
                    prepared.dryRun.backfillNotes.contains(where: { $0.contains(backfillFragment) }),
                    "Fixture \(fixture.name) should surface backfill note '\(backfillFragment)'."
                )
            }

            for absentBackfillFragment in fixture.unexpectedBackfillFragments {
                XCTAssertFalse(
                    prepared.dryRun.backfillNotes.contains(where: { $0.contains(absentBackfillFragment) }),
                    "Fixture \(fixture.name) should not backfill '\(absentBackfillFragment)'."
                )
            }
        }
    }

    func testNativeProtocolCreationGeneratesLibraryAndTodayState() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400) // 2026-03-14 12:00:00 UTC

        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Native GLP",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: "Created in native"
            ),
            now: now
        )

        let summaries = try await controller.container.protocols.listProtocolSummaries()
        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)

        XCTAssertEqual(detail.canonicalTitle, "Native GLP")
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.doseLabel, "1 mg")
        XCTAssertNotNil(today.nextDue)
        XCTAssertEqual(today.nextDue?.protocolID, detail.id)
    }

    func testNativeProtocolEditCreatesTimelineChangeEntry() async throws {
        let controller = try makeInMemoryController()
        let createDate = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Editable",
                kind: .peptide,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 5,
                doseUnit: "units",
                notes: nil
            ),
            now: createDate
        )

        let edited = try await controller.container.protocols.updateProtocol(
            id: created.id,
            draft: AtlasProtocolDraft(
                name: "Editable",
                kind: .peptide,
                cadenceType: .everyNDays,
                intervalDays: 3,
                weekday: nil,
                defaultTimeOfDay: "10:30",
                doseAmount: 6,
                doseUnit: "units",
                notes: "Updated"
            ),
            now: createDate.addingTimeInterval(3_600)
        )
        let changes = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .changes, protocolID: created.id, limit: 20)
        )

        XCTAssertEqual(edited.cadenceLabel, "Every 3 days at 10:30 AM")
        XCTAssertTrue(changes.contains(where: { $0.type == .protocolEdited }))
    }

    func testQuickLoggingCreatesImmutableHistoryAndUpdatesToday() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Logger",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 2,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        let firstToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let firstOccurrence = try XCTUnwrap(firstToday.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: firstOccurrence.id,
                protocolID: detail.id,
                action: .rescheduled,
                note: "Need a later time",
                rescheduledAt: now.addingTimeInterval(6 * 3_600)
            ),
            now: now
        )

        let refreshedToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let history = try await controller.container.timeline.fetchHistory(limit: 20)
        let timelineEntries = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .dosing, protocolID: detail.id, limit: 20)
        )

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.protocolID, detail.id)
        XCTAssertTrue(timelineEntries.contains(where: { $0.type == .doseRescheduled }))
        XCTAssertNotEqual(refreshedToday.nextDue?.id, firstOccurrence.id)
        XCTAssertEqual(refreshedToday.nextDue?.protocolID, detail.id)
    }

    func testTodayOccurrenceExplanationIsDeterministicAndReminderAware() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Explained due",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        try await controller.reminderCoordinator.syncReminders(referenceDate: now)
        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let explanation = try XCTUnwrap(today.nextDue?.explanation)

        XCTAssertEqual(
            Set(explanation.facts.map(\.label)),
            Set(["Revision", "Revision state", "Timezone", "Rule", "Cadence", "Occurrence", "Reminder"])
        )
        XCTAssertTrue(explanation.summary.contains("saved future plan"))
        XCTAssertFalse(explanation.facts.first(where: { $0.label == "Reminder" })?.value.isEmpty ?? true)
    }

    func testTodayGuidancePrioritizesRecoveryWhenOverdueExists() {
        let now = Date(timeIntervalSince1970: 1_776_124_800)
        let overdue = AtlasScheduledOccurrence(
            id: "overdue-1",
            protocolID: "protocol-1",
            canonicalTitle: "Weekly GLP",
            aliasTitle: "Evening plan",
            kindLabel: "GLP",
            cadenceLabel: "Weekly",
            doseLabel: "1 mg",
            scheduledAt: now.addingTimeInterval(-86_400),
            state: .overdue
        )
        let nextDue = AtlasScheduledOccurrence(
            id: "next-1",
            protocolID: "protocol-1",
            canonicalTitle: "Weekly GLP",
            aliasTitle: "Evening plan",
            kindLabel: "GLP",
            cadenceLabel: "Weekly",
            doseLabel: "1 mg",
            scheduledAt: now.addingTimeInterval(3_600),
            state: .due
        )
        let weeklySeed = AtlasWeeklyReviewSeed(
            periodTitle: "Apr 7, 2026 - Apr 13, 2026",
            generatedAt: now,
            windowStart: now.addingTimeInterval(-6 * 86_400),
            windowEnd: now,
            summarySettingEnabled: true,
            fallbackSummary: "Atlas recorded a recovery-heavy week.",
            sourceSections: [],
            completedCount: 1,
            skippedCount: 2,
            rescheduledCount: 1,
            overdueCount: 1,
            activeProtocolCount: 1,
            contextEntryCount: 1,
            symptomEntryCount: 0,
            weightEntryCount: 0,
            workoutEntryCount: 0,
            nextDueProtocolID: "protocol-1",
            nextDueTitle: "Evening plan",
            protocolChangeSummary: AtlasWeeklyReviewProtocolChangeSummary(
                changeCount: 1,
                latestProtocolID: "protocol-1",
                latestTitle: "Evening plan",
                latestSummary: "Shifted the weekly anchor",
                latestChangedAt: now.addingTimeInterval(-43_200),
                supportingLogCount: 1,
                supportingContextCount: 1
            )
        )
        let actionPlan = AtlasWeeklyReviewActionPlan(
            id: "focus-1",
            title: "Capture one appetite note",
            detail: "Keep one local context signal attached to the current plan.",
            symbolName: "waveform.path.ecg",
            route: .insights,
            reviewPeriodStart: ISO8601DateFormatter.atlas.string(from: now.addingTimeInterval(-6 * 86_400)),
            reviewPeriodEnd: ISO8601DateFormatter.atlas.string(from: now),
            createdAt: ISO8601DateFormatter.atlas.string(from: now)
        )

        let guidance = atlasTodayGuidancePresentation(
            todaySnapshot: AtlasTodaySnapshot(
                hasProtocols: true,
                nextDue: nextDue,
                overdue: [overdue],
                upcoming: []
            ),
            weeklyReviewSeed: weeklySeed,
            actionPlans: [actionPlan]
        )

        XCTAssertEqual(guidance?.headline, "Recovery comes before optimization.")
        XCTAssertEqual(guidance?.primaryAction.destination, .protocolDetail("protocol-1"))
        XCTAssertTrue(guidance?.secondaryActions.contains(where: { $0.destination == .detailedContext(.giCheckIn) }) == true)
        XCTAssertTrue(guidance?.facts.contains(where: { $0.label == "Weekly focus" && $0.value == "Capture one appetite note" }) == true)
    }

    func testTodayRecoveryPresentationUsesFollowUpWindowAndRecoveryRoute() {
        let now = Date(timeIntervalSince1970: 1_776_124_800)
        let nextDue = AtlasScheduledOccurrence(
            id: "next-2",
            protocolID: "protocol-2",
            canonicalTitle: "Repair peptide",
            aliasTitle: nil,
            kindLabel: "Recovery",
            cadenceLabel: "Daily",
            doseLabel: "250 mcg",
            scheduledAt: now.addingTimeInterval(7_200),
            state: .upcoming
        )
        let weeklySeed = AtlasWeeklyReviewSeed(
            periodTitle: "Apr 7, 2026 - Apr 13, 2026",
            generatedAt: now,
            windowStart: now.addingTimeInterval(-6 * 86_400),
            windowEnd: now,
            summarySettingEnabled: true,
            fallbackSummary: "Atlas recorded a descriptive follow-up window.",
            sourceSections: [],
            completedCount: 2,
            skippedCount: 1,
            rescheduledCount: 1,
            overdueCount: 0,
            activeProtocolCount: 1,
            contextEntryCount: 2,
            symptomEntryCount: 0,
            weightEntryCount: 0,
            workoutEntryCount: 0,
            nextDueProtocolID: "protocol-2",
            nextDueTitle: "Repair peptide",
            protocolFollowUpSummary: AtlasWeeklyReviewProtocolFollowUpSummary(
                protocolID: "protocol-2",
                title: "Repair peptide",
                changeTypeTitle: "Missed-dose recovery",
                summary: "This plan is still inside its follow-up window.",
                changedAt: now.addingTimeInterval(-86_400),
                windowDays: 14,
                completedCount: 2,
                skippedCount: 1,
                rescheduledCount: 1,
                contextEntryCount: 2
            )
        )

        let recovery = atlasTodayRecoveryPresentation(
            todaySnapshot: AtlasTodaySnapshot(
                hasProtocols: true,
                nextDue: nextDue,
                overdue: [],
                upcoming: []
            ),
            weeklyReviewSeed: weeklySeed,
            actionPlans: []
        )

        XCTAssertEqual(recovery?.primaryAction.destination, .protocolChange("protocol-2"))
        XCTAssertEqual(recovery?.secondaryAction?.destination, .detailedContext(.giCheckIn))
        XCTAssertTrue(recovery?.facts.contains(where: { $0.label == "Skipped this week" && $0.value == "1" }) == true)
    }

    func testTodayContextShortcutsAttachProtocolAndPrefillEditors() {
        let now = Date(timeIntervalSince1970: 1_776_124_800)

        let hydrationDraft = AtlasTodayContextShortcut.hydration.makeDraft(
            loggedAt: now,
            protocolID: "protocol-3"
        )
        XCTAssertEqual(hydrationDraft.protocolID, "protocol-3")
        XCTAssertEqual(hydrationDraft.hydration, .high)
        XCTAssertEqual(hydrationDraft.giTags, [.calm])

        let proteinEditor = atlasTodayContextEditorState(
            shortcut: .proteinMeal,
            referenceDate: now,
            protocolID: "protocol-3"
        )
        XCTAssertEqual(proteinEditor.protocolID, "protocol-3")
        XCTAssertEqual(proteinEditor.mealComposition, .proteinHeavy)
        XCTAssertEqual(proteinEditor.fedState, .fed)

        let giEditor = atlasTodayContextEditorState(
            shortcut: .giCheckIn,
            referenceDate: now,
            protocolID: nil
        )
        XCTAssertEqual(giEditor.appetite, .low)
        XCTAssertEqual(giEditor.giTags, [.nausea])
    }

    func testProtocolPlanningSummaryAndCommitCheckSurfaceOperationalGuardrails() {
        let now = Date(timeIntervalSince1970: 1_776_124_800)
        let context = AtlasProtocolChangeStudioContext(
            protocolID: "protocol-4",
            canonicalTitle: "Weekly GLP",
            aliasTitle: "Travel plan",
            protocolKind: .glp,
            kindLabel: "GLP",
            cadenceLabel: "Weekly at 8:00 AM",
            doseLabel: "1 mg",
            effectiveTimeOfDay: "08:00",
            currentMissedDosePolicy: .skipAndContinue,
            currentTimezone: "America/New_York",
            currentTimezoneStrategy: .keepLocalClock,
            currentLinkedVialID: nil,
            availableVials: [
                AtlasProtocolChangeVialOption(
                    id: "vial-1",
                    label: "Current vial",
                    remainingLabel: "2.0 mg remaining",
                    isArchived: false
                )
            ],
            compoundKnowledge: nil,
            activeCompanions: [
                AtlasProtocolCompanionSummary(
                    id: "companion-1",
                    canonicalTitle: "Support peptide",
                    aliasTitle: nil,
                    kindLabel: "Recovery",
                    cadenceLabel: "Daily",
                    doseLabel: "250 mcg"
                )
            ],
            siteWarnings: ["Rotate away from the last recent site before the next dose."]
        )
        let draft = AtlasProtocolChangeDraft(
            changeType: .futureDose,
            effectiveDate: now,
            doseAmount: nil,
            doseUnit: "",
            timeOfDay: "08:00"
        )

        let planning = atlasProtocolPlanningSummary(context: context, draft: draft)
        XCTAssertTrue(planning.recommendedMoves.contains(where: { $0.changeType == .missedDosePolicy }))
        XCTAssertTrue(planning.recommendedMoves.contains(where: { $0.changeType == .dayOfWeek }))
        XCTAssertTrue(planning.checklist.contains(where: { $0.id == "dose-explicit" && $0.severity == .caution }))
        XCTAssertTrue(planning.checklist.contains(where: { $0.id == "companions" }))

        let preview = AtlasProtocolChangePreview(
            protocolID: "protocol-4",
            changeType: .futureDose,
            effectiveDate: now,
            previewWindow: .fourteen,
            summary: "Future rows move to the new amount.",
            adherenceNote: "Expect the next two weeks to be the clearest operational read.",
            nextDueBefore: AtlasProtocolChangeOccurrenceSnapshot(
                occurrenceID: "before",
                whenLabel: "Apr 13 at 8:00 AM",
                doseLabel: "1 mg"
            ),
            nextDueAfter: AtlasProtocolChangeOccurrenceSnapshot(
                occurrenceID: "after",
                whenLabel: "Apr 13 at 8:00 AM",
                doseLabel: "1.5 mg"
            ),
            currentReminderLabel: "Apr 13 at 7:30 AM",
            draftReminderLabel: "Apr 13 at 7:30 AM",
            inventoryForecastBefore: "16 days remaining",
            inventoryForecastAfter: "11 days remaining",
            occurrenceChanges: [
                AtlasProtocolChangeOccurrenceDiff(
                    id: "diff-1",
                    kind: .rewired,
                    beforeLabel: "1 mg",
                    afterLabel: "1.5 mg"
                )
            ],
            interactionWarnings: [
                AtlasInteractionWarning(
                    id: "warning-1",
                    severity: .caution,
                    title: "Overlap check",
                    detail: "A companion plan is still active, so compare the combined burden before saving."
                )
            ],
            siteWarnings: ["Rotate away from the last recent site before the next dose."]
        )

        let commitCheck = atlasProtocolCommitCheck(preview: preview)
        XCTAssertTrue(commitCheck?.headline.contains("deserves one more operational pass") == true)
        XCTAssertTrue(commitCheck?.facts.contains(where: { $0.label == "Future rows touched" && $0.value == "1" }) == true)
        XCTAssertTrue(commitCheck?.notes.contains(where: { $0.contains("combined burden") }) == true)
    }

    func testReminderPermissionRequestTransitionsToAuthorized() async throws {
        let notifications = TestNotificationManager(
            currentStatus: .notDetermined,
            requestedStatus: .authorized
        )
        let controller = try makeInMemoryController(notifications: notifications)

        let initial = await controller.reminderCoordinator.authorizationStatus()
        let requested = try await controller.reminderCoordinator.requestAuthorization()
        let requestCount = await notifications.authorizationRequestsCount()

        XCTAssertEqual(initial, .notDetermined)
        XCTAssertEqual(requested, .authorized)
        XCTAssertEqual(requestCount, 1)
    }

    func testPersistedDiscreetRenderModeForcesGenericReminderCopy() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sensitive protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now)

        try await controller.reminderCoordinator.syncReminders(referenceDate: now)

        let settings = try await controller.container.settings.currentSettingsSnapshot()
        let reminderRows = try await controller.container.reminders.listScheduledReminders()
        let row = try XCTUnwrap(reminderRows.first)

        XCTAssertEqual(settings.trustVaultStatus.renderMode, .discreet)
        XCTAssertEqual(row.title, "Atlas reminder")
        XCTAssertFalse(row.body.contains("Sensitive protocol"))
        XCTAssertEqual(row.privacyMode, .generic)
    }

    func testReminderSyncSchedulesNextDueOccurrence() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Reminder protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        try await controller.reminderCoordinator.syncReminders(referenceDate: now)

        let requests = await notifications.pendingRequests()
        let identifiers = await notifications.pendingIdentifiers()
        let rows = try await controller.container.reminders.listScheduledReminders()

        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.status, .scheduled)
        XCTAssertEqual(rows.first?.privacyMode, .fullDetail)
        XCTAssertEqual(rows.first?.notificationId, identifiers.first)
    }

    func testProtocolEditRegeneratesScheduledReminder() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Editable reminder",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 2,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)
        let firstIdentifiers = await notifications.pendingIdentifiers()
        let firstRequests = await notifications.pendingRequests()
        let firstIdentifier = try XCTUnwrap(firstIdentifiers.first)
        let firstTrigger = try XCTUnwrap(firstRequests.first?.triggerAt)

        _ = try await controller.container.protocols.updateProtocol(
            id: detail.id,
            draft: AtlasProtocolDraft(
                name: "Editable reminder",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "20:00",
                doseAmount: 2,
                doseUnit: "mg",
                notes: "Time moved later"
            ),
            now: now.addingTimeInterval(60)
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now.addingTimeInterval(60))

        let secondIdentifiers = await notifications.pendingIdentifiers()
        let secondRequests = await notifications.pendingRequests()
        let canceledIdentifiers = await notifications.canceledIdentifiers()
        let secondIdentifier = try XCTUnwrap(secondIdentifiers.first)
        let secondTrigger = try XCTUnwrap(secondRequests.first?.triggerAt)

        XCTAssertNotEqual(firstIdentifier, secondIdentifier)
        XCTAssertNotEqual(firstTrigger, secondTrigger)
        XCTAssertTrue(canceledIdentifiers.contains(firstIdentifier))
    }

    func testReminderActionHandlingRegeneratesSchedule() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Actionable reminder",
                kind: .peptide,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 3,
                doseUnit: "units",
                notes: nil
            ),
            now: now
        )
        try await controller.reminderCoordinator.configureReminderHandling(onActionApplied: nil)
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)

        let initialRequests = await notifications.pendingRequests()
        let initialIdentifiers = await notifications.pendingIdentifiers()
        let firstRequest = try XCTUnwrap(initialRequests.first)
        let firstIdentifier = try XCTUnwrap(initialIdentifiers.first)

        await notifications.simulateResponse(
            AtlasReminderNotificationResponse(
                action: .markTaken,
                occurrenceID: firstRequest.occurrenceID,
                protocolID: detail.id,
                scheduledAt: firstRequest.scheduledAt
            )
        )

        let rows = try await controller.container.reminders.listScheduledReminders()
        let history = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .dosing, protocolID: detail.id, limit: 20)
        )
        let canceledIdentifiers = await notifications.canceledIdentifiers()

        XCTAssertEqual(rows.count, 1)
        XCTAssertTrue(canceledIdentifiers.contains(firstIdentifier))
        XCTAssertTrue(history.contains(where: { $0.type == .doseTaken }))
    }

    @MainActor
    func testReminderActionRefreshesLiveModelState() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let model = makeAppModel(controller: controller, notifications: notifications)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Live model reminder",
                kind: .peptide,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 2,
                doseUnit: "units",
                notes: nil
            ),
            now: now
        )

        await model.loadShellDataIfNeeded()

        let initialCount = model.timelineEntries.count
        let pendingRequests = await notifications.pendingRequests()
        let firstRequest = try XCTUnwrap(pendingRequests.first)

        await notifications.simulateResponse(
            AtlasReminderNotificationResponse(
                action: .markTaken,
                occurrenceID: firstRequest.occurrenceID,
                protocolID: firstRequest.protocolID,
                scheduledAt: firstRequest.scheduledAt
            )
        )
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertTrue(model.timelineEntries.count > initialCount)
        XCTAssertTrue(model.timelineEntries.contains(where: { $0.type == .doseTaken }))
        XCTAssertEqual(model.todaySnapshot.nextDue?.protocolID, firstRequest.protocolID)
    }

    func testReminderPrivacyFormattingSupportsAliasAndDiscreetModes() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: true)
        bundle.snapshot.reminderPreference.privacyMode = .fullDetail
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            bundle
        ))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        try await controller.reminderCoordinator.syncReminders(
            referenceDate: Date(timeIntervalSince1970: 1_773_489_600)
        )

        let aliasRows = try await controller.container.reminders.listScheduledReminders()
        let aliasRow = try XCTUnwrap(aliasRows.first)
        let discreetPreview = AtlasPrivacyFormatter().reminderPreview(
            occurrence: AtlasScheduledOccurrence(
                id: "preview",
                protocolID: "preview",
                canonicalTitle: "Canonical",
                aliasTitle: "Alias",
                kindLabel: "Routine",
                cadenceLabel: "Daily cadence",
                doseLabel: nil,
                scheduledAt: Date(timeIntervalSince1970: 1_773_972_000),
                state: .upcoming
            ),
            selectedMode: .fullDetail,
            renderMode: .discreet,
            now: Date(timeIntervalSince1970: 1_773_489_600)
        )

        XCTAssertEqual(aliasRow.title, "Evening plan")
        XCTAssertTrue(aliasRow.body.contains("Evening plan"))
        XCTAssertEqual(discreetPreview.effectiveMode, .generic)
        XCTAssertEqual(discreetPreview.title, "Atlas reminder")
    }

    func testDisablingRemindersCancelsObsoleteNotifications() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Cleanup protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)
        let pendingIdentifiers = await notifications.pendingIdentifiers()
        let scheduledIdentifier = try XCTUnwrap(pendingIdentifiers.first)

        _ = try await controller.reminderCoordinator.updateReminderSettings(
            AtlasReminderPreferenceUpdate(remindersEnabled: false),
            referenceDate: now.addingTimeInterval(30)
        )

        let reminderRows = try await controller.container.reminders.listScheduledReminders()
        let remainingRequests = await notifications.pendingRequests()
        let canceledIdentifiers = await notifications.canceledIdentifiers()

        XCTAssertTrue(reminderRows.isEmpty)
        XCTAssertTrue(remainingRequests.isEmpty)
        XCTAssertTrue(canceledIdentifiers.contains(scheduledIdentifier))
    }

    @MainActor
    func testTimelineSearchRefreshFiltersImmutableHistory() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller, referenceDate: importedFixtureReferenceDate)
        let now = importedFixtureReferenceDate

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Timeline Search Protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        await model.refreshShellData()
        XCTAssertTrue(model.timelineEntries.contains(where: { $0.canonicalTitle == "Timeline Search Protocol" }))

        model.updateTimelineSearchText("search protocol")
        try await Task.sleep(nanoseconds: 350_000_000)

        XCTAssertFalse(model.timelineEntries.isEmpty)
        XCTAssertTrue(model.timelineEntries.allSatisfy { $0.canonicalTitle == "Timeline Search Protocol" })

        model.updateTimelineSearchText("missing keyword")
        try await Task.sleep(nanoseconds: 350_000_000)

        XCTAssertTrue(model.timelineEntries.isEmpty)
    }

    func testCalendarSyncWritesUpcomingOccurrencesAndPersistsSelection() async throws {
        let calendars = [
            AtlasExternalCalendarDescriptor(
                id: "calendar.primary",
                title: "Protocols",
                sourceTitle: "Google"
            )
        ]
        let externalCalendars = TestExternalCalendarManager(
            currentStatus: .fullAccess,
            calendars: calendars
        )
        let controller = try makeInMemoryController(externalCalendars: externalCalendars)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Calendar Protocol",
                kind: .peptide,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 2,
                doseUnit: "mg"
            ),
            now: now
        )

        let settings = try await controller.calendarSyncCoordinator.updateSettings(
            AtlasExternalCalendarSettingsUpdate(
                syncEnabled: true,
                calendarSelection: .select(calendars[0]),
                clearError: true
            ),
            referenceDate: now
        )
        let savedEvents = await externalCalendars.savedEvents()

        XCTAssertTrue(settings.syncEnabled)
        XCTAssertEqual(settings.selectedCalendarTitle, "Protocols")
        XCTAssertEqual(settings.syncedEventCount, savedEvents.count)
        XCTAssertEqual(savedEvents.count, 30)
        XCTAssertEqual(savedEvents.first?.title, "Calendar Protocol")
        XCTAssertTrue(savedEvents.first?.notes.contains("Scheduled from Atlas.") ?? false)
    }

    func testCalendarSyncRespectsPrivacyModeAndRemovesEventsWhenDisabled() async throws {
        let calendars = [
            AtlasExternalCalendarDescriptor(
                id: "calendar.primary",
                title: "Protocols",
                sourceTitle: "Apple"
            )
        ]
        let externalCalendars = TestExternalCalendarManager(
            currentStatus: .fullAccess,
            calendars: calendars
        )
        let controller = try makeInMemoryController(externalCalendars: externalCalendars)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sensitive Calendar Protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "18:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        _ = try await controller.calendarSyncCoordinator.updateSettings(
            AtlasExternalCalendarSettingsUpdate(
                syncEnabled: true,
                calendarSelection: .select(calendars[0]),
                clearError: true
            ),
            referenceDate: now
        )
        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now.addingTimeInterval(60))
        try await controller.calendarSyncCoordinator.sync(referenceDate: now.addingTimeInterval(60))

        let savedEvents = await externalCalendars.savedEvents()
        XCTAssertEqual(savedEvents.last?.title, "Atlas routine")

        _ = try await controller.calendarSyncCoordinator.updateSettings(
            AtlasExternalCalendarSettingsUpdate(syncEnabled: false, clearError: true),
            referenceDate: now.addingTimeInterval(120)
        )

        let refreshedSettings = try await controller.container.settings.currentSettingsSnapshot()
        let deletedIdentifiers = await externalCalendars.deletedIdentifiers()

        XCTAssertFalse(refreshedSettings.externalCalendarSettings.syncEnabled)
        XCTAssertEqual(refreshedSettings.externalCalendarSettings.syncedEventCount, 0)
        XCTAssertFalse(deletedIdentifiers.isEmpty)
    }

    func testSilentNotificationPresentationPolicyOmitsSound() {
        XCTAssertEqual(AtlasNotificationPresentationPolicy.options(isSilent: true), [.banner, .list])
        XCTAssertEqual(AtlasNotificationPresentationPolicy.options(isSilent: false), [.banner, .list, .sound])
    }

    func testVialCRUDLinkingAndArchiveFlow() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Inventory protocol",
                kind: .glp,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 2,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        let saved = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Starter pen",
                protocolID: protocolDetail.id,
                startingQuantity: 4,
                remainingQuantity: 4,
                quantityUnit: "dose",
                lowStockThreshold: 1
            ),
            now: now
        )
        let snapshot = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now)

        XCTAssertEqual(saved.summary.label, "Starter pen")
        XCTAssertEqual(snapshot.vials.count, 1)
        XCTAssertEqual(snapshot.protocolSettings.first?.linkedVialID, saved.summary.id)

        _ = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                id: saved.summary.id,
                label: "Starter pen refreshed",
                protocolID: protocolDetail.id,
                startingQuantity: 4,
                remainingQuantity: 3,
                quantityUnit: "dose",
                lowStockThreshold: 1
            ),
            now: now.addingTimeInterval(60)
        )
        try await controller.container.inventory.archiveVial(id: saved.summary.id, now: now.addingTimeInterval(120))

        let archivedDetail = try await controller.container.inventory.fetchVialDetail(
            id: saved.summary.id,
            referenceDate: now
        )
        let archived = try XCTUnwrap(archivedDetail)
        let refreshed = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now)

        XCTAssertEqual(archived.summary.label, "Starter pen refreshed")
        XCTAssertNotNil(archived.summary.archivedAt)
        XCTAssertNil(refreshed.protocolSettings.first?.linkedVialID)
    }

    func testTakenLogDecrementsLinkedVialWithoutDoubleReplay() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Dose-linked vial",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let vial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "4 mg vial",
                protocolID: protocolDetail.id,
                startingQuantity: 4,
                remainingQuantity: 4,
                quantityUnit: "mg"
            ),
            now: now
        )

        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(today.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken
            ),
            now: now
        )

        await XCTAssertThrowsErrorAsync {
            try await controller.container.coreLoop.logOccurrence(
                AtlasOccurrenceLogRequest(
                    occurrenceID: occurrence.id,
                    protocolID: protocolDetail.id,
                    action: .taken
                ),
                now: now.addingTimeInterval(60)
            )
        }

        let vialDetail = try await controller.container.inventory.fetchVialDetail(
            id: vial.summary.id,
            referenceDate: now
        )
        let detail = try XCTUnwrap(vialDetail)

        XCTAssertEqual(detail.summary.remainingQuantity, 3, accuracy: 0.001)
    }

    func testManualCorrectionWritesExplicitAuditHistory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Correction protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let vial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Correction vial",
                protocolID: protocolDetail.id,
                startingQuantity: 10,
                remainingQuantity: 10,
                quantityUnit: "mg"
            ),
            now: now
        )

        let result = try await controller.container.inventory.applyManualCorrection(
            AtlasInventoryCorrectionDraft(
                vialID: vial.summary.id,
                nextRemainingQuantity: 8,
                note: "Counted the drawer."
            ),
            now: now.addingTimeInterval(60)
        )

        XCTAssertNotNil(result.eventID)
        XCTAssertEqual(result.vial.summary.remainingQuantity, 8, accuracy: 0.001)
        XCTAssertEqual(result.vial.correctionHistory.first?.note, "Counted the drawer.")
        XCTAssertEqual(result.vial.correctionHistory.first?.deltaLabel, "-2 mg")
    }

    func testConsumableCrudLowStockAndHistoryStayDeterministic() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Supply protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: now)

        let saved = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: protocolDetail.id,
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 12,
                unit: "pad",
                reorderThreshold: 10,
                reorderLeadTimeDays: 5,
                quantityPerUse: 1,
                lotNumber: "LOT-12",
                sizeDescription: "70%",
                notes: "Travel kit backup",
                vendorLabel: "Local pharmacy",
                purchaseNotes: "Pack of 100"
            ),
            now: now
        )

        let adjusted = try await controller.container.inventory.applyConsumableAdjustment(
            AtlasConsumableAdjustmentDraft(
                consumableID: saved.summary.id,
                nextQuantityOnHand: 9,
                note: "Restocked the travel case."
            ),
            now: now.addingTimeInterval(60)
        )
        let snapshot = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now.addingTimeInterval(60))
        let summary = try XCTUnwrap(snapshot.consumables.first(where: { $0.id == saved.summary.id }))

        XCTAssertEqual(summary.quantityOnHand, 9, accuracy: 0.001)
        XCTAssertTrue(summary.isLowStock)
        XCTAssertEqual(summary.vendorLabel, "Local pharmacy")
        XCTAssertNotNil(summary.projectedDepletionLabel)
        XCTAssertEqual(summary.procurementStatusLabel, "Supply review now.")
        XCTAssertEqual(adjusted.consumable.adjustmentHistory.first?.kind, .manualAdjustment)
        XCTAssertEqual(adjusted.consumable.adjustmentHistory.first?.deltaLabel, "-3 pad")
        XCTAssertEqual(adjusted.consumable.adjustmentHistory.dropFirst().first?.kind, .created)
        XCTAssertEqual(adjusted.consumable.procurementHistory.first?.kind, .created)
        XCTAssertEqual(adjusted.consumable.procurementHistory.first?.vendorLabel, "Local pharmacy")
        XCTAssertEqual(adjusted.consumable.procurementHistory.first?.sourceDetail, "Pack of 100")
        XCTAssertEqual(adjusted.consumable.planning.vendorHistorySummary, "1 inventory note recorded")
    }

    func testConsumableTakenLogDecrementAppendsSeparateSupplyHistory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Needle protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: protocolDetail.id,
                name: "Syringes",
                category: "Injection",
                quantityOnHand: 5,
                unit: "syringe",
                reorderThreshold: 2,
                quantityPerUse: 1
            ),
            now: now
        )
        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: now)
        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(today.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken
            ),
            now: now.addingTimeInterval(60)
        )

        let snapshot = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now.addingTimeInterval(60))
        let loadedDetail = try await controller.container.inventory.fetchConsumableDetail(
            id: snapshot.consumables[0].id,
            referenceDate: now.addingTimeInterval(60)
        )
        let detail = try XCTUnwrap(loadedDetail)
        let history = try await controller.container.timeline.fetchHistory(limit: 10)

        XCTAssertEqual(detail.summary.quantityOnHand, 4, accuracy: 0.001)
        XCTAssertEqual(detail.adjustmentHistory.first?.kind, .protocolUse)
        XCTAssertEqual(detail.adjustmentHistory.first?.deltaLabel, "-1 syringe")
        XCTAssertFalse(history.contains(where: { $0.summary.contains("Syringes") }))
    }

    func testConsumableProcurementRecordsVendorHistoryAndRestoresPlanningHeadroom() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Procurement protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: now)

        let saved = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: protocolDetail.id,
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 12,
                unit: "pad",
                reorderThreshold: 10,
                reorderLeadTimeDays: 5,
                quantityPerUse: 1,
                vendorLabel: "Local pharmacy",
                purchaseNotes: "Starter carton"
            ),
            now: now
        )

        let result = try await controller.container.inventory.recordConsumableProcurement(
            AtlasConsumableProcurementDraft(
                consumableID: saved.summary.id,
                quantityReceived: 24,
                vendorLabel: "Neighborhood pharmacy",
                sourceDetail: "Two sleeves for travel kits",
                receivedAt: now.addingTimeInterval(86_400)
            ),
            now: now.addingTimeInterval(86_460)
        )

        let detail = result.consumable
        XCTAssertEqual(detail.summary.quantityOnHand, 36, accuracy: 0.001)
        XCTAssertEqual(detail.summary.vendorLabel, "Neighborhood pharmacy")
        XCTAssertFalse(detail.summary.needsProcurementReview)
        XCTAssertEqual(detail.adjustmentHistory.first?.kind, .procurement)
        XCTAssertEqual(detail.procurementHistory.first?.kind, .procurement)
        XCTAssertEqual(detail.procurementHistory.first?.vendorLabel, "Neighborhood pharmacy")
        XCTAssertEqual(detail.procurementHistory.first?.sourceDetail, "Two sleeves for travel kits")
        XCTAssertEqual(detail.planning.lastProcurementLabel, "Last supply note Mar 20, 2026")
        XCTAssertEqual(detail.planning.vendorHistorySummary, "2 inventory notes recorded")
    }

    func testInventoryMovementHistoryExplainsDeterministicInventoryChanges() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Movement protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let firstVial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Movement vial A",
                protocolID: protocolDetail.id,
                startingQuantity: 6,
                remainingQuantity: 6,
                quantityUnit: "mg"
            ),
            now: now
        )
        let secondVial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Movement vial B",
                protocolID: nil,
                startingQuantity: 6,
                remainingQuantity: 6,
                quantityUnit: "mg"
            ),
            now: now.addingTimeInterval(30)
        )

        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(today.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken
            ),
            now: now.addingTimeInterval(60)
        )
        _ = try await controller.container.inventory.applyManualCorrection(
            AtlasInventoryCorrectionDraft(
                vialID: firstVial.summary.id,
                nextRemainingQuantity: 4,
                note: "Drawer count"
            ),
            now: now.addingTimeInterval(120)
        )
        _ = try await controller.container.changeStudio.commitChange(
            protocolID: protocolDetail.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .vialSwitch,
                effectiveDate: now.addingTimeInterval(24 * 60 * 60),
                timeOfDay: "09:00",
                linkedVialID: secondVial.summary.id
            ),
            referenceDate: now.addingTimeInterval(180)
        )
        try await controller.container.inventory.archiveVial(
            id: firstVial.summary.id,
            now: now.addingTimeInterval(240)
        )

        let detail = try await controller.container.inventory.fetchVialDetail(
            id: firstVial.summary.id,
            referenceDate: now.addingTimeInterval(48 * 60 * 60)
        )
        let movementHistory = try XCTUnwrap(detail?.movementHistory)
        let movementKinds = movementHistory.map(\.kind)

        XCTAssertTrue(movementKinds.contains(.created))
        XCTAssertTrue(movementKinds.contains(.takenLog))
        XCTAssertTrue(movementKinds.contains(.manualCorrection))
        XCTAssertTrue(movementKinds.contains(.vialHandoff))
        XCTAssertTrue(movementKinds.contains(.archived))
        XCTAssertTrue(movementHistory.contains(where: { $0.kind == .takenLog && $0.deltaLabel == "-1 mg" }))
        XCTAssertTrue(movementHistory.contains(where: { $0.kind == .manualCorrection && $0.detail.contains("Drawer count") }))
    }

    func testProjectedDepletionChangesAfterProtocolEdit() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_918_000)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Depletion protocol",
                kind: .glp,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Depletion vial",
                protocolID: protocolDetail.id,
                startingQuantity: 4,
                remainingQuantity: 4,
                quantityUnit: "mg"
            ),
            now: now
        )

        let initial = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now)
        let initialLabel = initial.vials.first?.projectedDepletionLabel

        _ = try await controller.container.protocols.updateProtocol(
            id: protocolDetail.id,
            draft: AtlasProtocolDraft(
                name: "Depletion protocol",
                kind: .glp,
                cadenceType: .everyNDays,
                intervalDays: 2,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now.addingTimeInterval(60)
        )

        let updated = try await controller.container.inventory.fetchInventorySnapshot(referenceDate: now.addingTimeInterval(60))
        XCTAssertNotNil(initialLabel)
        XCTAssertNotEqual(initialLabel, updated.vials.first?.projectedDepletionLabel)
    }

    func testCalculatorProfileSaveDeleteAndVialAttachment() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let profile = try await controller.container.calculator.saveProfile(
            AtlasCalculatorProfileDraft(
                label: "2 mg baseline",
                powderAmount: 2,
                powderUnit: "mg",
                diluentVolume: 2,
                diluentUnit: "mL",
                drawVolume: 0.25,
                drawUnit: "mL"
            ),
            now: now
        )
        let vial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Profile linked vial",
                startingQuantity: 4,
                remainingQuantity: 4,
                quantityUnit: "mL",
                concentrationValue: 1,
                concentrationUnit: "mg",
                volumeML: 2,
                calculatorProfileID: profile.id
            ),
            now: now
        )

        let profileCount = try await controller.container.calculator.listProfiles().count
        XCTAssertEqual(vial.summary.calculatorProfileLabel, "2 mg baseline")
        XCTAssertEqual(profileCount, 1)

        try await controller.container.calculator.deleteProfile(id: profile.id)
        let loadedDetail = try await controller.container.inventory.fetchVialDetail(
            id: vial.summary.id,
            referenceDate: now
        )
        let detail = try XCTUnwrap(loadedDetail)
        let remainingProfiles = try await controller.container.calculator.listProfiles()

        XCTAssertNil(detail.summary.calculatorProfileID)
        XCTAssertTrue(remainingProfiles.isEmpty)
    }

    func testSiteTrackingPersistsAndRotatesSuggestions() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sites protocol",
                kind: .peptide,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let firstSite = try await controller.container.inventory.saveSite(
            AtlasSiteDraft(name: "Left abdomen", bodyArea: "abdomen"),
            now: now
        )
        let secondSite = try await controller.container.inventory.saveSite(
            AtlasSiteDraft(name: "Right abdomen", bodyArea: "abdomen"),
            now: now.addingTimeInterval(1)
        )

        _ = try await controller.container.inventory.updateProtocolInventorySettings(
            AtlasProtocolInventorySettingsUpdate(
                protocolID: protocolDetail.id,
                linkedVialID: nil,
                siteTrackingEnabled: true,
                siteRotationEnabled: true
            ),
            now: now.addingTimeInterval(2)
        )

        let initialOptions = try await controller.container.inventory.fetchProtocolSiteOptions(protocolID: protocolDetail.id)
        XCTAssertEqual(initialOptions.suggestedSiteID, firstSite.id)

        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(today.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken,
                siteID: firstSite.id
            ),
            now: now.addingTimeInterval(60)
        )

        let rotated = try await controller.container.inventory.fetchProtocolSiteOptions(protocolID: protocolDetail.id)
        XCTAssertEqual(rotated.lastUsedSiteID, firstSite.id)
        XCTAssertEqual(rotated.suggestedSiteID, secondSite.id)
    }

    @MainActor
    func testImportedInventoryDataIsVisibleAndPrivacyAware() async throws {
        let controller = try makeInMemoryController()
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: true)
        bundle.snapshot.sites = [
            AtlasSiteRecord.make(
                id: "site1",
                name: "Left abdomen",
                bodyArea: "abdomen",
                notes: "Primary rotation start",
                createdAt: "2026-03-01T09:00:00.000Z",
                updatedAt: "2026-03-01T09:00:00.000Z",
                archivedAt: nil
            )
        ]
        bundle.snapshot.vials = [
            AtlasVialRecord.make(
                id: "vial1",
                protocolId: "p1",
                compoundId: nil,
                label: "Imported starter",
                startingQuantity: 4,
                concentrationValue: 1,
                concentrationUnit: "mg",
                volumeMl: 2,
                remainingQuantity: 4,
                lowStockThreshold: 1,
                quantityUnit: "mg",
                openedAt: nil,
                expiresAt: nil,
                createdAt: "2026-03-01T09:00:00.000Z",
                updatedAt: "2026-03-01T09:00:00.000Z"
            )
        ]
        bundle.snapshot.protocols[0].linkedVialId = "vial1"
        bundle.snapshot.protocols[0].siteTrackingEnabled = true
        bundle.snapshot.protocols[0].siteRotationEnabled = true
        bundle.snapshot.protocolRevisions[0].linkedVialId = "vial1"

        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        XCTAssertEqual(model.inventorySnapshot.vials.count, 1)
        XCTAssertEqual(model.inventorySnapshot.sites.count, 1)
        XCTAssertEqual(
            model.renderedTitle(
                canonical: model.inventorySnapshot.vials[0].linkedProtocolCanonicalTitle ?? "",
                alias: model.inventorySnapshot.vials[0].linkedProtocolAliasTitle
            ),
            "Evening plan"
        )

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: Date())
        await model.refreshShellData()

        XCTAssertEqual(
            model.renderedTitle(
                canonical: model.inventorySnapshot.vials[0].linkedProtocolCanonicalTitle ?? "",
                alias: model.inventorySnapshot.vials[0].linkedProtocolAliasTitle
            ),
            "Private protocol"
        )
    }

    func testProtocolChangeStudioFutureOnlyEditPreservesHistory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "History keeper",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        let initialToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let firstOccurrence = try XCTUnwrap(initialToday.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: firstOccurrence.id,
                protocolID: created.id,
                action: .taken
            ),
            now: now
        )

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .futureDose,
                effectiveDate: now.addingTimeInterval(24 * 60 * 60),
                doseAmount: 2,
                doseUnit: "mg",
                timeOfDay: "08:00"
            ),
            referenceDate: now
        )

        let history = try await controller.container.timeline.fetchHistory(limit: 10)
        let changes = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .changes, protocolID: created.id, limit: 10)
        )

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.protocolID, created.id)
        XCTAssertTrue(changes.contains(where: { $0.summary.contains("Future saved amount changes to 2 mg") }))
    }

    func testTimelineDoseEntryCarriesOccurrenceExplanationWithoutMutatingHistory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Timeline explanation",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(today.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: created.id,
                action: .taken
            ),
            now: now.addingTimeInterval(60)
        )

        let timeline = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .dosing, protocolID: created.id, limit: 10)
        )
        let entry = try XCTUnwrap(timeline.first(where: { $0.type == .doseTaken }))
        let explanation = try XCTUnwrap(entry.occurrenceExplanation)
        let history = try await controller.container.timeline.fetchHistory(limit: 10)

        XCTAssertTrue(explanation.facts.contains(where: { $0.label == "Occurrence" }))
        XCTAssertTrue(explanation.facts.contains(where: { $0.label == "Revision" }))
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.protocolID, created.id)
    }

    func testProtocolChangeStudioPauseAndResumeRegenerateOccurrencesAndReminders() async throws {
        let notifications = TestNotificationManager()
        let controller = try makeInMemoryController(notifications: notifications)
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Pause me",
                kind: .custom,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "dose",
                notes: nil
            ),
            now: now
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .pause,
                effectiveDate: now,
                timeOfDay: "09:00"
            ),
            referenceDate: now
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)

        let pausedToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let pausedRequests = await notifications.pendingRequests()
        XCTAssertNil(pausedToday.nextDue)
        XCTAssertTrue(pausedRequests.isEmpty)

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .resume,
                effectiveDate: now.addingTimeInterval(24 * 60 * 60),
                timeOfDay: "09:00"
            ),
            referenceDate: now
        )
        try await controller.reminderCoordinator.syncReminders(referenceDate: now)
        let resumedReference = now.addingTimeInterval(36 * 60 * 60)
        let resumedToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: resumedReference)
        let resumedRequests = await notifications.pendingRequests()

        XCTAssertNotNil(resumedToday.nextDue)
        XCTAssertFalse(resumedRequests.isEmpty)
    }

    func testProtocolChangeStudioTitrationAndRestBehavior() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Titrate",
                kind: .peptide,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        let titrationPreview = try await controller.container.changeStudio.buildPreview(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .titration,
                effectiveDate: now,
                timeOfDay: "08:00",
                titrationDoseAmount: 0.5,
                titrationDoseUnit: "mg",
                titrationLengthDays: 5
            ),
            referenceDate: now
        )
        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .titration,
                effectiveDate: now,
                timeOfDay: "08:00",
                titrationDoseAmount: 0.5,
                titrationDoseUnit: "mg",
                titrationLengthDays: 5
            ),
            referenceDate: now
        )
        let titrationToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)

        XCTAssertEqual(titrationPreview.nextDueAfter?.doseLabel, "0.5 mg")
        XCTAssertEqual(titrationToday.nextDue?.doseLabel, "0.5 mg")

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .restPeriod,
                effectiveDate: now,
                timeOfDay: "08:00",
                restLengthDays: 3
            ),
            referenceDate: now
        )

        let restingToday = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let resumedToday = try await controller.container.today.fetchTodaySnapshot(
            referenceDate: now.addingTimeInterval(4 * 24 * 60 * 60)
        )
        let restingNextDue = try XCTUnwrap(restingToday.nextDue)
        let restGapDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: now),
            to: Calendar.current.startOfDay(for: restingNextDue.scheduledAt)
        ).day ?? 0

        XCTAssertGreaterThanOrEqual(restGapDays, 3)
        XCTAssertNotNil(resumedToday.nextDue)
    }

    func testProtocolChangeStudioTimezonePreviewAndCommitDoNotDuplicateOccurrences() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Traveler",
                kind: .glp,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        let preview = try await controller.container.changeStudio.buildPreview(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .timezone,
                effectiveDate: now,
                timeOfDay: "08:00",
                timezone: "America/Los_Angeles",
                timezoneStrategy: .keepHomeTimezone
            ),
            referenceDate: now
        )
        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .timezone,
                effectiveDate: now,
                timeOfDay: "08:00",
                timezone: "America/Los_Angeles",
                timezoneStrategy: .keepHomeTimezone
            ),
            referenceDate: now
        )

        let snapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrenceIDs = [snapshot.nextDue?.id] + snapshot.upcoming.map(\.id)
        let uniqueIDs = Set(occurrenceIDs.compactMap { $0 })

        XCTAssertFalse(preview.summary.isEmpty)
        XCTAssertEqual(uniqueIDs.count, occurrenceIDs.compactMap { $0 }.count)
    }

    func testProtocolChangeStudioVialSwitchDoesNotDoubleDecrementInventory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Switch inventory",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "dose",
                notes: nil
            ),
            now: now
        )
        let firstVial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Vial A",
                protocolID: created.id,
                startingQuantity: 5,
                remainingQuantity: 5,
                quantityUnit: "dose",
                lowStockThreshold: 1
            ),
            now: now
        )
        let preSwitchSnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let preSwitchOccurrence = try XCTUnwrap(preSwitchSnapshot.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: preSwitchOccurrence.id,
                protocolID: created.id,
                action: .taken
            ),
            now: now
        )
        let secondVial = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Vial B",
                protocolID: nil,
                startingQuantity: 5,
                remainingQuantity: 5,
                quantityUnit: "dose",
                lowStockThreshold: 1
            ),
            now: now
        )

        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .vialSwitch,
                effectiveDate: now.addingTimeInterval(24 * 60 * 60),
                timeOfDay: "09:00",
                linkedVialID: secondVial.summary.id
            ),
            referenceDate: now
        )

        let futureReference = now.addingTimeInterval(36 * 60 * 60)
        let switchedSnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: futureReference)
        let switchedOccurrence = try XCTUnwrap(switchedSnapshot.nextDue)
        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: switchedOccurrence.id,
                protocolID: created.id,
                action: .taken
            ),
            now: futureReference
        )

        let firstVialDetail = try await controller.container.inventory.fetchVialDetail(
            id: firstVial.summary.id,
            referenceDate: futureReference
        )
        let secondVialDetail = try await controller.container.inventory.fetchVialDetail(
            id: secondVial.summary.id,
            referenceDate: futureReference
        )

        XCTAssertEqual(firstVialDetail?.summary.remainingQuantity, 4)
        XCTAssertEqual(secondVialDetail?.summary.remainingQuantity, 4)
    }

    func testProtocolChangeStudioPreviewMatchesCommittedOutcomeAndCancelWritesNothing() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Previewed",
                kind: .custom,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )

        let originalDetail = try await controller.container.protocols.fetchProtocolDetail(id: created.id)
        let preview = try await controller.container.changeStudio.buildPreview(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .futureTime,
                effectiveDate: now,
                timeOfDay: "11:30"
            ),
            referenceDate: now
        )

        let unchangedDetail = try await controller.container.protocols.fetchProtocolDetail(id: created.id)
        XCTAssertEqual(originalDetail?.id, unchangedDetail?.id)
        XCTAssertEqual(originalDetail?.canonicalTitle, unchangedDetail?.canonicalTitle)
        XCTAssertEqual(originalDetail?.cadenceLabel, unchangedDetail?.cadenceLabel)
        XCTAssertEqual(originalDetail?.doseLabel, unchangedDetail?.doseLabel)
        XCTAssertEqual(
            originalDetail?.medicationLevel?.estimateLabel,
            unchangedDetail?.medicationLevel?.estimateLabel
        )
        XCTAssertEqual(
            originalDetail?.medicationLevel?.points.count,
            unchangedDetail?.medicationLevel?.points.count
        )

        let commit = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .futureTime,
                effectiveDate: now,
                timeOfDay: "11:30"
            ),
            referenceDate: now
        )

        XCTAssertEqual(preview.nextDueAfter?.whenLabel, commit.preview.nextDueAfter?.whenLabel)
        XCTAssertEqual(commit.auditRecord.summary, preview.summary)
    }

    func testProtocolChangeStudioCommitProducesExplainableImpactAndDetailChanges() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Explainable change",
                kind: .glp,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 1,
                defaultTimeOfDay: "08:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: now
        )
        let preview = try await controller.container.changeStudio.buildPreview(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .everyNDays,
                effectiveDate: now,
                timeOfDay: "10:00",
                intervalDays: 3
            ),
            referenceDate: now
        )

        let commit = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .everyNDays,
                effectiveDate: now,
                timeOfDay: "10:00",
                intervalDays: 3
            ),
            referenceDate: now
        )
        let fetchedDetail = try await controller.container.protocols.fetchProtocolDetail(id: created.id)
        let detail = try XCTUnwrap(fetchedDetail)
        let change = try XCTUnwrap(detail.recentChanges.first)

        XCTAssertEqual(commit.preview, preview)
        XCTAssertEqual(commit.impactSummary.title, "Future plan updated")
        XCTAssertTrue(commit.impactSummary.facts.contains(where: { $0.label == "Future occurrences" }))
        XCTAssertTrue(commit.impactSummary.facts.contains(where: { $0.label == "Reminders" }))
        XCTAssertTrue(commit.impactSummary.facts.contains(where: { $0.label == "Inventory projection" }))
        XCTAssertTrue(commit.impactSummary.facts.contains(where: { $0.label == "Historical logs" && $0.value == "Unchanged" }))
        XCTAssertTrue(change.facts.contains(where: { $0.label == "Cadence" && $0.value.contains("Every 3 days") }))
        XCTAssertTrue(change.notes.contains("Historical logs stayed unchanged."))
    }

    @MainActor
    func testProtocolChangeStudioAuditEntriesAndPrivacyRenderingAreSafe() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: true)
        ))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: Date())

        let referenceDate = Date(timeIntervalSince1970: 1_773_950_400)
        let preview = try await controller.container.changeStudio.buildPreview(
            protocolID: "p1",
            draft: AtlasProtocolChangeDraft(
                changeType: .everyNDays,
                effectiveDate: referenceDate,
                timeOfDay: "10:00",
                intervalDays: 3
            ),
            referenceDate: referenceDate
        )
        _ = try await controller.container.changeStudio.commitChange(
            protocolID: "p1",
            draft: AtlasProtocolChangeDraft(
                changeType: .everyNDays,
                effectiveDate: referenceDate,
                timeOfDay: "10:00",
                intervalDays: 3
            ),
            referenceDate: referenceDate
        )

        let model = makeAppModel(controller: controller)
        await model.refreshShellData()
        let changes = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .changes, protocolID: "p1", limit: 20)
        )

        XCTAssertEqual(model.renderedTitle(canonical: "Weekly GLP", alias: "Evening plan"), "Private protocol")
        XCTAssertFalse(preview.summary.contains("Weekly GLP"))
        XCTAssertTrue(changes.contains(where: { $0.summary == "Updated private protocol" }))
    }

    func testDiscreetModeKeepsDueAndChangeExplanationsPrivacySafe() async throws {
        let controller = try makeInMemoryController()
        let referenceDate = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sensitive protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg",
                notes: nil
            ),
            now: referenceDate
        )
        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: referenceDate)

        let today = try await controller.container.today.fetchTodaySnapshot(referenceDate: referenceDate)
        let dueExplanation = try XCTUnwrap(today.nextDue?.explanation)
        _ = try await controller.container.changeStudio.commitChange(
            protocolID: created.id,
            draft: AtlasProtocolChangeDraft(
                changeType: .futureTime,
                effectiveDate: referenceDate,
                timeOfDay: "11:00"
            ),
            referenceDate: referenceDate
        )
        let fetchedDetail = try await controller.container.protocols.fetchProtocolDetail(id: created.id)
        let detail = try XCTUnwrap(fetchedDetail)
        let changeExplanation = try XCTUnwrap(detail.recentChanges.first)

        XCTAssertFalse(dueExplanation.summary.contains("Sensitive protocol"))
        XCTAssertFalse(dueExplanation.facts.map { $0.value }.joined(separator: " ").contains("Sensitive protocol"))
        XCTAssertFalse(changeExplanation.summary.contains("Sensitive protocol"))
        XCTAssertFalse(changeExplanation.facts.map { $0.value }.joined(separator: " ").contains("Sensitive protocol"))
        XCTAssertEqual(changeExplanation.summary, "Updated private protocol")
    }

    func testProtocolChangeStudioVialOptionsStayPrivacySafeOutsideFullMode() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let created = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Protected plan",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "dose",
                notes: nil
            ),
            now: now
        )
        _ = try await controller.container.inventory.saveVial(
            AtlasVialDraft(
                label: "Semaglutide Vial",
                protocolID: created.id,
                startingQuantity: 5,
                remainingQuantity: 5,
                quantityUnit: "dose",
                lowStockThreshold: 1
            ),
            now: now
        )

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.alias, now: now)
        let aliasContext = try await controller.container.changeStudio.loadStudio(
            protocolID: created.id,
            referenceDate: now
        )
        XCTAssertEqual(aliasContext.availableVials.first?.label, "Linked vial")

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now)
        let discreetContext = try await controller.container.changeStudio.loadStudio(
            protocolID: created.id,
            referenceDate: now
        )
        XCTAssertEqual(discreetContext.availableVials.first?.label, "Linked vial")
    }

    func testTrustVaultSnapshotLoadsImportedAliasesAndAudits() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertEqual(AtlasPrivacyFormatter().renderMode(for: snapshot.privacyProfile), .alias)
        XCTAssertEqual(snapshot.aliases.first?.aliasLabel, "Evening plan")
        XCTAssertTrue(snapshot.audits.contains(where: { $0.eventType == .exportCreated }))
    }

    func testTrustVaultProfileChangesAppendSensitiveActionAudits() async throws {
        let controller = try makeInMemoryController()

        _ = try await controller.container.trustVault.updatePrivacyProfile(
            AtlasTrustVaultProfileUpdate(
                renderMode: .alias,
                biometricLockEnabled: true,
                biometricGateMode: .requiredWhenAvailable,
                shareAliasByDefault: true,
                exportAliasByDefault: true
            ),
            now: Date(timeIntervalSince1970: 1_773_950_400)
        )

        let snapshot = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertEqual(snapshot.privacyProfile.renderMode, .alias)
        XCTAssertTrue(snapshot.audits.contains(where: { $0.eventType == .privacyModeChanged }))
        XCTAssertTrue(snapshot.audits.contains(where: { $0.eventType == .biometricLockChanged }))
    }

    func testSelectiveSharePreviewMatchesEncryptedBundleMetadata() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let request = AtlasSelectiveShareRequest(
            scopeKind: .protocolWithRecentTimeline,
            renderMode: .alias,
            protocolID: "p1"
        )

        let preview = try await controller.importExportBridge.previewSelectiveShare(request, now: now)
        let result = try await controller.importExportBridge.createSelectiveShare(request, now: now)
        let data = try Data(contentsOf: result.fileURL)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let manifest = try XCTUnwrap(payload["manifest"] as? [String: Any])
        let datasets = try XCTUnwrap(manifest["datasets"] as? [[String: Any]])
        let encryptedPayload = try XCTUnwrap(payload["encryptedPayload"] as? [String: Any])
        let fileContents = String(decoding: data, as: UTF8.self)

        XCTAssertEqual(result.preview, preview)
        XCTAssertEqual(result.snapshot.protocols.count, 1)
        XCTAssertEqual(result.snapshot.logEvents.count, 1)
        XCTAssertEqual(manifest["format"] as? String, "atlas_selective_share")
        XCTAssertEqual(manifest["version"] as? Int, 1)
        XCTAssertEqual(manifest["rowCount"] as? Int, preview.rowCount)
        XCTAssertTrue(datasets.contains(where: { $0["dataset"] as? String == "privacyProfile" && $0["rowCount"] as? Int == 1 }))
        XCTAssertTrue(datasets.contains(where: { $0["dataset"] as? String == "reminderPreference" && $0["rowCount"] as? Int == 1 }))
        XCTAssertNotNil(encryptedPayload["ciphertext"] as? String)
        XCTAssertFalse(fileContents.contains("Weekly GLP"))
        XCTAssertFalse(fileContents.contains("Dose changes next week."))
    }

    func testRawJsonExportIsVersionedAndDeterministic() async throws {
        let firstController = try makeInMemoryController()
        let secondController = try makeInMemoryController()
        let prepared = try await firstController.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await firstController.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let secondPrepared = try await secondController.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await secondController.importExportBridge.commitPreparedImport(secondPrepared, mode: .replaceExisting)
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        let first = try await firstController.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now
        )
        let second = try await secondController.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now
        )
        let firstData = try Data(contentsOf: first.fileURL)
        let secondData = try Data(contentsOf: second.fileURL)
        let decoded = try XCTUnwrap(JSONSerialization.jsonObject(with: firstData) as? [String: Any])
        let manifest = try XCTUnwrap(decoded["manifest"] as? [String: Any])
        let snapshot = try XCTUnwrap(decoded["snapshot"] as? [String: Any])

        XCTAssertEqual(first.rowCount, second.rowCount)
        XCTAssertEqual(firstData, secondData)
        XCTAssertEqual(manifest["format"] as? String, "atlas_export")
        XCTAssertEqual(manifest["version"] as? Int, 1)
        XCTAssertEqual(manifest["source"] as? String, "atlas-ios-native")
        XCTAssertNotNil(snapshot["protocols"])
    }

    func testRawCsvAliasExportCoversPhaseFiveDatasets() async throws {
        let controller = try makeInMemoryController()
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: true)
        bundle.snapshot.vials = [
            AtlasVialRecord.make(
                id: "vial_export",
                protocolId: "p1",
                compoundId: "cmp1",
                label: "Starter vial",
                startingQuantity: 4,
                concentrationValue: 1,
                concentrationUnit: "mg",
                volumeMl: 2,
                remainingQuantity: 3,
                lowStockThreshold: 1,
                quantityUnit: "mg",
                openedAt: nil,
                expiresAt: nil,
                createdAt: "2026-03-01T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        ]
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .csv, renderMode: .alias),
            now: Date(timeIntervalSince1970: 1_773_950_400)
        )
        let csv = try String(contentsOf: result.fileURL, encoding: .utf8)

        XCTAssertTrue(csv.contains("dataset,id,primary,timestamp,value,secondary,notes"))
        XCTAssertTrue(csv.contains("\"protocol_revision\""))
        XCTAssertTrue(csv.contains("\"protocol_revision_rule\""))
        XCTAssertTrue(csv.contains("\"protocol_change_audit\""))
        XCTAssertTrue(csv.contains("\"protocol_alias\""))
        XCTAssertTrue(csv.contains("\"sensitive_action_audit\""))
        XCTAssertTrue(csv.contains("\"reminder_preference\""))
        XCTAssertTrue(csv.contains("\"Evening plan\""))
        XCTAssertTrue(csv.contains("\"Private vial\""))
        XCTAssertFalse(csv.contains("Weekly GLP"))
        XCTAssertFalse(csv.contains("Starter vial"))
    }

    func testConsumableProcurementRawExportAndAliasExportStayPrivacySafe() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Export protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let saved = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: protocolDetail.id,
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 25,
                unit: "pad",
                reorderThreshold: 10,
                reorderLeadTimeDays: 5,
                quantityPerUse: 1,
                lotNumber: "LOT-7",
                sizeDescription: "70%",
                notes: "Cabinet",
                vendorLabel: "Neighborhood pharmacy",
                purchaseNotes: "Value pack",
            ),
            now: now
        )
        _ = try await controller.container.inventory.recordConsumableProcurement(
            AtlasConsumableProcurementDraft(
                consumableID: saved.summary.id,
                quantityReceived: 12,
                vendorLabel: "Neighborhood pharmacy",
                sourceDetail: "Value pack",
                receivedAt: now.addingTimeInterval(300)
            ),
            now: now.addingTimeInterval(360)
        )

        let fullJsonExport = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now.addingTimeInterval(600)
        )
        let aliasJsonExport = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .alias),
            now: now.addingTimeInterval(660)
        )
        let aliasCsvExport = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .csv, renderMode: .alias),
            now: now.addingTimeInterval(720)
        )

        let fullBundleData = try Data(contentsOf: fullJsonExport.fileURL)
        let aliasBundleData = try Data(contentsOf: aliasJsonExport.fileURL)
        let fullJsonText = try String(contentsOf: fullJsonExport.fileURL, encoding: .utf8)
        let aliasJsonText = try String(contentsOf: aliasJsonExport.fileURL, encoding: .utf8)
        let decoded = try JSONDecoder().decode(AtlasExportBundle.self, from: fullBundleData)
        let aliasDecoded = try JSONDecoder().decode(AtlasExportBundle.self, from: aliasBundleData)
        let csv = try String(contentsOf: aliasCsvExport.fileURL, encoding: .utf8)

        XCTAssertEqual(decoded.snapshot.consumables.count, 1)
        XCTAssertNotNil(decoded.snapshot.consumableAdjustments.first(where: { $0.kind == .procurement }))
        XCTAssertNotNil(aliasDecoded.snapshot.consumableAdjustments.first(where: { $0.kind == .procurement }))
        XCTAssertTrue(fullJsonText.contains("Neighborhood pharmacy"))
        XCTAssertTrue(fullJsonText.contains("Value pack"))
        XCTAssertFalse(aliasJsonText.contains("Neighborhood pharmacy"))
        XCTAssertFalse(aliasJsonText.contains("Value pack"))
        XCTAssertTrue(csv.contains("\"consumable\""))
        XCTAssertTrue(csv.contains("\"consumable_adjustment\""))
        XCTAssertTrue(csv.contains("\"Swab supply\""))
        XCTAssertFalse(csv.contains("Alcohol pads"))
        XCTAssertFalse(csv.contains("Neighborhood pharmacy"))
        XCTAssertFalse(csv.contains("LOT-7"))
    }

    @MainActor
    func testConsumableRenderModesStayPrivacySafe() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Privacy-linked protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: detail.id,
                name: "Travel syringes",
                category: "Injection",
                quantityOnHand: 6,
                unit: "syringe"
            ),
            now: now
        )

        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        XCTAssertEqual(model.renderedConsumableTitle(canonical: "Travel syringes", category: "Injection"), "Travel syringes")

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.alias, now: now)
        await model.refreshShellData()
        XCTAssertEqual(model.renderedConsumableTitle(canonical: "Travel syringes", category: "Injection"), "Injection supply")

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now.addingTimeInterval(60))
        await model.refreshShellData()
        XCTAssertEqual(model.renderedConsumableTitle(canonical: "Travel syringes", category: "Injection"), "Injection supply")
    }

    @MainActor
    func testBiometricGateBlocksTrustVaultExportAction() async throws {
        let notifications = TestNotificationManager()
        let biometrics = TestBiometricGate(granted: false)
        let controller = try makeInMemoryController(notifications: notifications)
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        _ = try await controller.container.trustVault.updatePrivacyProfile(
            AtlasTrustVaultProfileUpdate(
                biometricLockEnabled: true,
                biometricGateMode: .requiredWhenAvailable
            ),
            now: Date(timeIntervalSince1970: 1_773_950_400)
        )

        let model = makeAppModel(
            controller: controller,
            notifications: notifications,
            biometrics: biometrics
        )
        await model.refreshShellData()

        let export = await model.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full)
        )
        let gateCalls = await biometrics.callCount()
        let snapshot = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertNil(export)
        XCTAssertEqual(gateCalls, 1)
        XCTAssertFalse(snapshot.audits.contains(where: { $0.eventType == .vaultUnlocked }))
    }

    @MainActor
    func testBiometricGateIsSkippedWhenBiometricsAreUnavailable() async throws {
        let notifications = TestNotificationManager()
        let biometrics = TestBiometricGate(available: false, granted: false)
        let controller = try makeInMemoryController(notifications: notifications)
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        _ = try await controller.container.trustVault.updatePrivacyProfile(
            AtlasTrustVaultProfileUpdate(
                biometricLockEnabled: true,
                biometricGateMode: .requiredWhenAvailable
            ),
            now: Date(timeIntervalSince1970: 1_773_950_400)
        )

        let model = makeAppModel(
            controller: controller,
            notifications: notifications,
            biometrics: biometrics
        )
        await model.refreshShellData()

        let export = await model.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full)
        )
        let gateCalls = await biometrics.callCount()

        XCTAssertNotNil(export)
        XCTAssertEqual(gateCalls, 0)
    }

    func testFirstLaunchBootstrapRoutesToOnboarding() async throws {
        let controller = try makeInMemoryController()

        let snapshot = try await controller.container.onboarding.loadBootstrapSnapshot()

        XCTAssertEqual(snapshot.destination, .onboarding)
        XCTAssertEqual(snapshot.reason, .firstRun)
        XCTAssertFalse(snapshot.onboardingCompleted)
        XCTAssertFalse(snapshot.hasLocalData)
    }

    func testGuestOnboardingCompletesAndRoutesIntoApp() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .guest, trackType: .later),
            now: now
        )

        let bootstrap = try await controller.container.onboarding.loadBootstrapSnapshot()
        let settings = try await controller.container.settings.currentSettingsSnapshot()

        XCTAssertEqual(bootstrap.destination, .app)
        XCTAssertEqual(bootstrap.reason, .completedOnboarding)
        XCTAssertTrue(bootstrap.onboardingCompleted)
        XCTAssertEqual(settings.accountMode, .guest)
        XCTAssertEqual(settings.accountStartMode, .guest)
        XCTAssertEqual(settings.syncStatus, .localOnly)
        XCTAssertTrue(settings.rewardsSettings.enabled)
    }

    func testAccountBoundaryModesPersistFromOnboarding() async throws {
        let createController = try makeInMemoryController()
        let signInController = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_500)

        _ = try await createController.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .create, trackType: .later),
            now: now
        )
        _ = try await signInController.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .signIn, trackType: .later),
            now: now
        )

        let createSettings = try await createController.container.settings.currentSettingsSnapshot()
        let signInSettings = try await signInController.container.settings.currentSettingsSnapshot()

        XCTAssertEqual(createSettings.accountMode, .account)
        XCTAssertEqual(createSettings.accountStartMode, .create)
        XCTAssertEqual(createSettings.syncStatus, .accountBoundary)
        XCTAssertEqual(signInSettings.accountMode, .account)
        XCTAssertEqual(signInSettings.accountStartMode, .signIn)
        XCTAssertEqual(signInSettings.syncStatus, .accountBoundary)
    }

    func testGlpBranchCanCompleteWithoutGlpFields() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .glp)
        draft.glp.medication = nil
        draft.glp.frequency = nil
        draft.glp.injectionDay = nil
        draft.glp.dose = nil
        draft.glp.duration = nil
        draft.glp.goal = nil
        draft.glp.challenge = nil

        let snapshot = try await controller.container.onboarding.completeOnboarding(
            draft,
            now: Date(timeIntervalSince1970: 1_773_950_600)
        )

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertTrue(snapshot.onboardingCompleted)
    }

    func testPeptideBranchCanCompleteWithoutPeptideFields() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .peptide)
        draft.peptide.selections = []
        draft.peptide.frequency = nil
        draft.peptide.experience = nil
        draft.peptide.usualTime = nil
        draft.peptide.dose = nil
        draft.peptide.goal = nil

        let snapshot = try await controller.container.onboarding.completeOnboarding(
            draft,
            now: Date(timeIntervalSince1970: 1_773_950_700)
        )

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertTrue(snapshot.onboardingCompleted)
    }

    func testBothBranchCanCompleteWithoutTrackDetails() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .both)
        draft.glp.medication = nil
        draft.glp.frequency = nil
        draft.glp.injectionDay = nil
        draft.glp.dose = nil
        draft.glp.duration = nil
        draft.glp.goal = nil
        draft.glp.challenge = nil
        draft.peptide.selections = []
        draft.peptide.frequency = nil
        draft.peptide.experience = nil
        draft.peptide.usualTime = nil
        draft.peptide.dose = nil
        draft.peptide.goal = nil

        let snapshot = try await controller.container.onboarding.completeOnboarding(
            draft,
            now: Date(timeIntervalSince1970: 1_773_950_800)
        )

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertTrue(snapshot.onboardingCompleted)
    }

    func testExploreFirstBranchSkipsBranchRequirements() async throws {
        let controller = try makeInMemoryController()

        let snapshot = try await controller.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .guest, trackType: .later),
            now: Date(timeIntervalSince1970: 1_773_950_900)
        )

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertTrue(snapshot.onboardingCompleted)
    }

    func testOnboardingPrivacyPreferencesPersistToSettings() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .later)
        draft.privacy.discreetNotifications = true
        draft.privacy.hideSensitiveLabels = true
        draft.privacy.biometricLater = true

        _ = try await controller.container.onboarding.completeOnboarding(
            draft,
            now: Date(timeIntervalSince1970: 1_773_951_000)
        )

        let settings = try await controller.container.settings.currentSettingsSnapshot()
        let vault = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertEqual(settings.trustVaultStatus.renderMode, .discreet)
        XCTAssertEqual(vault.privacyProfile.renderMode, .discreet)
        XCTAssertEqual(vault.privacyProfile.biometricGateMode, .bestEffort)
    }

    @MainActor
    func testOnboardingCompletionRoutesAppModelIntoShell() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)

        await model.loadBootstrapIfNeeded()
        XCTAssertEqual(model.bootstrapSnapshot.destination, .onboarding)

        await model.saveOnboardingDraft(makeCompleteOnboardingDraft(accountMode: .guest, trackType: .later))
        await model.completeOnboarding()

        XCTAssertEqual(model.bootstrapSnapshot.destination, .app)
        XCTAssertTrue(model.bootstrapSnapshot.onboardingCompleted)
    }

    func testImportedUserBootstrapBypassesForcedOnboarding() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.onboarding.loadBootstrapSnapshot()

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertEqual(snapshot.reason, .importedLocalUser)
        XCTAssertTrue(snapshot.isImportedLocalUser)
        XCTAssertFalse(snapshot.onboardingCompleted)
    }

    func testSettingsSnapshotShowsAccountSyncAndHealthScaffolds() async throws {
        let controller = try makeInMemoryController()
        _ = try await controller.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .create, trackType: .later),
            now: Date(timeIntervalSince1970: 1_773_951_100)
        )

        let settings = try await controller.container.settings.currentSettingsSnapshot()

        XCTAssertEqual(settings.accountStartMode, .create)
        XCTAssertEqual(settings.syncStatus, .accountBoundary)
        XCTAssertTrue(settings.healthScaffold.isAvailable)
        XCTAssertEqual(settings.healthScaffold.connections.first?.providerKey, .appleHealth)
    }

    func testResetOnboardingDoesNotForceImportedUserBackThroughWizard() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        _ = try await controller.container.onboarding.resetOnboarding(
            now: Date(timeIntervalSince1970: 1_773_951_200)
        )
        let snapshot = try await controller.container.onboarding.loadBootstrapSnapshot()

        XCTAssertEqual(snapshot.destination, .app)
        XCTAssertTrue(snapshot.isImportedLocalUser)
    }

    func testWeightLoggingPersistsAndBuildsTrend() async throws {
        let controller = try makeInMemoryController()
        let firstLoggedAt = Date(timeIntervalSince1970: 1_773_928_800)
        let secondLoggedAt = firstLoggedAt.addingTimeInterval(24 * 60 * 60)

        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: firstLoggedAt,
                value: 170,
                unit: .lb,
                notes: "Baseline"
            ),
            now: firstLoggedAt
        )
        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: secondLoggedAt,
                value: 167,
                unit: .lb,
                notes: "Week two"
            ),
            now: secondLoggedAt
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: secondLoggedAt.addingTimeInterval(60)
        )

        XCTAssertEqual(snapshot.recentWeightEntries.count, 2)
        XCTAssertEqual(snapshot.recentWeightEntries.first?.valueLabel, "167 lb")
        XCTAssertEqual(snapshot.weightTrend.points.count, 2)
        XCTAssertEqual(snapshot.weightTrend.latestLabel?.contains("167 lb"), true)
        XCTAssertEqual(snapshot.weightTrend.changeLabel?.contains("-3 lb"), true)
    }

    func testSymptomLoggingPersistsAndBuildsTrend() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now,
                symptomKey: "nausea",
                severity: 4,
                notes: "Morning"
            ),
            now: now
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(6 * 60 * 60),
                symptomKey: "nausea",
                severity: 2,
                notes: "Later"
            ),
            now: now.addingTimeInterval(6 * 60 * 60)
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(12 * 60 * 60)
        )

        XCTAssertEqual(snapshot.recentSymptomEntries.count, 2)
        XCTAssertEqual(snapshot.recentSymptomEntries.first?.symptomKey, "nausea")
        XCTAssertEqual(snapshot.symptomTrend.first?.symptomKey, "nausea")
        XCTAssertEqual(snapshot.symptomTrend.first?.averageSeverityLabel, "3.0")
        XCTAssertEqual(snapshot.symptomTrend.first?.entryCount, 2)
    }

    func testInsightsBuildDeterministicExplanationForRepeatedSymptomNearContext() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600) // Apr 10, 2026 UTC

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                symptomKey: "nausea",
                severity: 4
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(5 * 24 * 60 * 60)),
                symptomKey: "nausea",
                severity: 3
            ),
            now: now.addingTimeInterval(-(5 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(10 * 24 * 60 * 60)),
                symptomKey: "nausea",
                severity: 2
            ),
            now: now.addingTimeInterval(-(10 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (2 * 60 * 60)),
                fedState: .fasted
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (2 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-(5 * 24 * 60 * 60) - (90 * 60)),
                fedState: .fasted
            ),
            now: now.addingTimeInterval(-(5 * 24 * 60 * 60) - (90 * 60))
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let explanation = try XCTUnwrap(
            snapshot.deterministicExplanations.first(where: { $0.kind == .symptomContext })
        )

        XCTAssertEqual(explanation.title, "Nausea near fasted context")
        XCTAssertTrue(explanation.summary.contains("Recent nausea entries showed up near fasted context"))
        XCTAssertEqual(
            explanation.facts.map(\.label),
            ["Observed", "Window", "Records", "Why this appears"]
        )
        XCTAssertTrue(explanation.facts[0].value.contains("2 of 3 recent nausea entries"))
        XCTAssertTrue(explanation.facts[0].value.contains("within 6 hours of fasted context"))
        XCTAssertEqual(explanation.facts[2].value, "2 symptom logs and 2 context logs.")
        XCTAssertTrue(explanation.facts[3].value.contains("matched at least twice"))
    }

    func testInsightsBuildDeterministicExplanationForRepeatedSymptomAfterWorkout() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600) // Apr 10, 2026 UTC

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(24 * 60 * 60)),
                symptomKey: "fatigue",
                severity: 4
            ),
            now: now.addingTimeInterval(-(24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(4 * 24 * 60 * 60)),
                symptomKey: "fatigue",
                severity: 3
            ),
            now: now.addingTimeInterval(-(4 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(9 * 24 * 60 * 60)),
                symptomKey: "fatigue",
                severity: 2
            ),
            now: now.addingTimeInterval(-(9 * 24 * 60 * 60))
        )

        let firstRun = AtlasHealthWorkoutSample(
            id: "hk-run-1",
            activityKind: .run,
            startedAt: now.addingTimeInterval(-(24 * 60 * 60) - (3 * 60 * 60)),
            endedAt: now.addingTimeInterval(-(24 * 60 * 60) - (2 * 60 * 60)),
            durationMinutes: 45
        )
        let secondRun = AtlasHealthWorkoutSample(
            id: "hk-run-2",
            activityKind: .run,
            startedAt: now.addingTimeInterval(-(4 * 24 * 60 * 60) - (5 * 60 * 60)),
            endedAt: now.addingTimeInterval(-(4 * 24 * 60 * 60) - (4 * 60 * 60)),
            durationMinutes: 35
        )

        _ = try await controller.container.metrics.importWorkoutSamples([firstRun, secondRun], now: now)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let explanation = try XCTUnwrap(
            snapshot.deterministicExplanations.first(where: { $0.kind == .symptomWorkout })
        )

        XCTAssertEqual(explanation.title, "Fatigue after run workouts")
        XCTAssertTrue(explanation.summary.contains("within 24 hours after run workouts"))
        XCTAssertEqual(
            explanation.facts.map(\.label),
            ["Observed", "Window", "Records", "Why this appears"]
        )
        XCTAssertTrue(explanation.facts[0].value.contains("2 of 3 recent fatigue entries"))
        XCTAssertEqual(explanation.facts[2].value, "2 symptom logs and 2 workout logs.")
        XCTAssertTrue(explanation.facts[3].value.contains("post-workout timing rule"))
    }

    func testInsightsDoNotBuildDeterministicExplanationForSingleWeakMatch() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600)

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                symptomKey: "headache",
                severity: 3
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(5 * 24 * 60 * 60)),
                symptomKey: "headache",
                severity: 2
            ),
            now: now.addingTimeInterval(-(5 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (60 * 60)),
                hydration: .low
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (60 * 60))
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)

        XCTAssertTrue(snapshot.deterministicExplanations.isEmpty)
    }

    func testInsightsSkipSelfReferentialSymptomContextExplanation() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600)

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                symptomKey: "nausea",
                severity: 4
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(4 * 24 * 60 * 60)),
                symptomKey: "nausea",
                severity: 3
            ),
            now: now.addingTimeInterval(-(4 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (60 * 60)),
                giTags: [.nausea]
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (60 * 60))
        )
        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-(4 * 24 * 60 * 60) - (90 * 60)),
                giTags: [.nausea]
            ),
            now: now.addingTimeInterval(-(4 * 24 * 60 * 60) - (90 * 60))
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)

        XCTAssertFalse(
            snapshot.deterministicExplanations.contains(where: { $0.title == "Nausea near nausea context" })
        )
    }

    func testInsightsBuildDeterministicExplanationForRepeatedSymptomNearWeightCheckIns() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600)

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                symptomKey: "dizziness",
                severity: 4
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(6 * 24 * 60 * 60)),
                symptomKey: "dizziness",
                severity: 3
            ),
            now: now.addingTimeInterval(-(6 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(10 * 24 * 60 * 60)),
                symptomKey: "dizziness",
                severity: 2
            ),
            now: now.addingTimeInterval(-(10 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (3 * 60 * 60)),
                value: 170,
                unit: .lb
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60) - (3 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(-(6 * 24 * 60 * 60) + (2 * 60 * 60)),
                value: 169,
                unit: .lb
            ),
            now: now.addingTimeInterval(-(6 * 24 * 60 * 60) + (2 * 60 * 60))
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let explanation = try XCTUnwrap(
            snapshot.deterministicExplanations.first(where: { $0.kind == .symptomWeight })
        )

        XCTAssertEqual(explanation.title, "Dizziness near weight check-ins")
        XCTAssertTrue(explanation.summary.contains("within 24 hours of weight check-ins"))
        XCTAssertEqual(
            explanation.facts.map(\.label),
            ["Observed", "Window", "Records", "Why this appears"]
        )
        XCTAssertTrue(explanation.facts[0].value.contains("2 of 3 recent dizziness entries"))
        XCTAssertEqual(explanation.facts[2].value, "2 symptom logs and 2 weight logs.")
    }

    func testInsightsBuildDeterministicExplanationForRepeatedSymptomNearMetricCheckIns() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_775_793_600)
        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Energy",
                valueType: .number,
                unit: "pts"
            ),
            now: now.addingTimeInterval(-(12 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                symptomKey: "brain fog",
                severity: 4
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(7 * 24 * 60 * 60)),
                symptomKey: "brain fog",
                severity: 3
            ),
            now: now.addingTimeInterval(-(7 * 24 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(-(11 * 24 * 60 * 60)),
                symptomKey: "brain fog",
                severity: 2
            ),
            now: now.addingTimeInterval(-(11 * 24 * 60 * 60))
        )

        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                loggedAt: now.addingTimeInterval(-(2 * 24 * 60 * 60) + (2 * 60 * 60)),
                numberValue: 4
            ),
            now: now.addingTimeInterval(-(2 * 24 * 60 * 60) + (2 * 60 * 60))
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                loggedAt: now.addingTimeInterval(-(7 * 24 * 60 * 60) - (3 * 60 * 60)),
                numberValue: 5
            ),
            now: now.addingTimeInterval(-(7 * 24 * 60 * 60) - (3 * 60 * 60))
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let explanation = try XCTUnwrap(
            snapshot.deterministicExplanations.first(where: { $0.kind == .symptomMetric })
        )

        XCTAssertEqual(explanation.title, "Brain Fog near energy check-ins")
        XCTAssertTrue(explanation.summary.contains("within 24 hours of energy check-ins"))
        XCTAssertEqual(
            explanation.facts.map(\.label),
            ["Observed", "Window", "Records", "Why this appears"]
        )
        XCTAssertTrue(explanation.facts[0].value.contains("2 of 3 recent brain fog entries"))
        XCTAssertEqual(explanation.facts[2].value, "2 symptom logs and 2 metric logs.")
    }

    func testCustomMetricDefinitionCrudAndLogging() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)

        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Energy",
                valueType: .number,
                unit: "pts"
            ),
            now: now
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                loggedAt: now.addingTimeInterval(60),
                numberValue: 8
            ),
            now: now.addingTimeInterval(60)
        )

        var snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(120)
        )

        XCTAssertEqual(snapshot.customMetricDefinitions.count, 1)
        XCTAssertEqual(snapshot.customMetricDefinitions.first?.latestEntryLabel, "8 pts")
        XCTAssertEqual(snapshot.recentMetricEntries.first?.valueLabel, "8 pts")

        try await controller.container.metrics.archiveMetricDefinition(
            id: metric.id,
            now: now.addingTimeInterval(180)
        )
        snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(180)
        )
        XCTAssertNotNil(snapshot.customMetricDefinitions.first?.archivedAt)

        let unusedMetric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Mood",
                valueType: .text
            ),
            now: now.addingTimeInterval(240)
        )
        try await controller.container.metrics.deleteMetricDefinition(id: unusedMetric.id)
        snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(300)
        )

        XCTAssertFalse(snapshot.customMetricDefinitions.contains(where: { $0.id == unusedMetric.id }))

        await XCTAssertThrowsErrorAsync {
            try await controller.container.metrics.deleteMetricDefinition(id: metric.id)
        }
    }

    func testScaleMetricValidationAndPersistence() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Focus",
                valueType: .scale,
                scaleMin: 1,
                scaleMax: 5
            ),
            now: now
        )

        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                loggedAt: now.addingTimeInterval(60),
                numberValue: 4
            ),
            now: now.addingTimeInterval(60)
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(120)
        )

        XCTAssertEqual(snapshot.recentMetricEntries.first?.valueLabel, "4 / 5")

        await XCTAssertThrowsErrorAsync {
            try await controller.container.metrics.saveMetricValueEntry(
                AtlasMetricValueEntryDraft(
                    metricID: metric.id,
                    loggedAt: now.addingTimeInterval(180),
                    numberValue: 7
                ),
                now: now.addingTimeInterval(180)
            )
        }
    }

    func testTimelineIncludesWellnessEntries() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_928_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Wellness protocol",
                kind: .glp,
                cadenceType: .weekly,
                weekday: 2,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                protocolID: protocolDetail.id,
                label: "Recovery",
                valueType: .number,
                unit: "%"
            ),
            now: now.addingTimeInterval(1)
        )
        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(2),
                value: 168,
                unit: .lb
            ),
            now: now.addingTimeInterval(2)
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(3),
                symptomKey: "fatigue",
                severity: 3
            ),
            now: now.addingTimeInterval(3)
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(4),
                numberValue: 82
            ),
            now: now.addingTimeInterval(4)
        )

        let entries = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .wellness, protocolID: nil, limit: 20)
        )

        XCTAssertTrue(entries.contains(where: { $0.type == .weightLogged }))
        XCTAssertTrue(entries.contains(where: { $0.type == .symptomLogged }))
        XCTAssertTrue(entries.contains(where: { $0.type == .customMetricLogged }))
    }

    func testAmountInSystemAndAdherenceInsightsReflectProtocolState() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Insight protocol",
                kind: .glp,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let todaySnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(todaySnapshot.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: detail.id,
                action: .taken
            ),
            now: now
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: now.addingTimeInterval(60)
        )

        XCTAssertEqual(
            snapshot.amountInSystemDisclaimer,
            "Estimate only. Logged quantities use known half-life profiles when available and otherwise fall back to the saved schedule window. These are planning estimates, not serum measurements."
        )
        XCTAssertTrue(snapshot.adherenceTrend.completedCount > 0)
        XCTAssertFalse(snapshot.amountInSystem.isEmpty)
        XCTAssertEqual(snapshot.amountInSystem.first?.canonicalProtocolTitle, "Insight protocol")
        XCTAssertEqual(snapshot.amountInSystem.first?.estimateLabel.contains("estimated active now"), true)
        XCTAssertFalse(snapshot.amountInSystem.first?.points.isEmpty ?? true)
        XCTAssertFalse(snapshot.amountInSystem.first?.sourceFacts.isEmpty ?? true)
    }

    func testProtocolDetailCarriesMedicationLevelViewForKnownCompound() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Semaglutide",
                kind: .glp,
                cadenceType: .weekly,
                intervalDays: 1,
                weekday: 1,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let todaySnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(todaySnapshot.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: detail.id,
                action: .taken
            ),
            now: now
        )

        let fetchedDetail = try await controller.container.protocols.fetchProtocolDetail(id: detail.id)
        let level = try XCTUnwrap(fetchedDetail?.medicationLevel)

        XCTAssertEqual(level.modelKind, .halfLifeEstimate)
        XCTAssertEqual(level.halfLifeLabel, "168 hour half-life profile")
        XCTAssertFalse(level.points.isEmpty)
        XCTAssertTrue(level.sourceFacts.contains(where: { $0.label == "Profile" }))
    }

    func testProgressEvidenceSnapshotReflectsMeasurementsAndPhotos() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)

        _ = try await controller.container.metrics.saveProgressMeasurement(
            AtlasProgressMeasurementDraft(
                kind: .waist,
                value: 34,
                unit: "in",
                loggedAt: now.addingTimeInterval(-7 * 24 * 3600)
            ),
            now: now
        )
        _ = try await controller.container.metrics.saveProgressMeasurement(
            AtlasProgressMeasurementDraft(
                kind: .waist,
                value: 33.5,
                unit: "in",
                loggedAt: now
            ),
            now: now
        )
        _ = try await controller.container.metrics.saveProgressPhoto(
            AtlasProgressPhotoDraft(
                angle: .front,
                note: "Week one",
                loggedAt: now,
                jpegData: Data(repeating: 0xFF, count: 64)
            ),
            now: now
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let waistTrend = try XCTUnwrap(snapshot.progressEvidence.measurementTrends.first(where: { $0.kind == .waist }))
        let photo = try XCTUnwrap(snapshot.progressEvidence.recentPhotos.first)

        XCTAssertEqual(waistTrend.points.count, 2)
        XCTAssertEqual(waistTrend.changeLabel, "-0.5 in vs prior check-in")
        XCTAssertTrue(FileManager.default.fileExists(atPath: photo.absolutePath))
        XCTAssertEqual(snapshot.progressEvidence.recentPhotos.count, 1)
    }

    func testProgressEvidenceRouteCanOpen() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)

        model.open(.progressEvidence)

        XCTAssertEqual(model.routePath.last, .progressEvidence)
    }

    func testWatchCompanionRouteCanOpen() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)

        model.open(.watchCompanion)

        XCTAssertEqual(model.routePath.last, .watchCompanion)
    }

    func testCompoundIntelligenceRouteCanOpen() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)

        model.open(.compoundIntelligence("semaglutide"))

        XCTAssertEqual(model.routePath.last, .compoundIntelligence("semaglutide"))
    }

    func testCompoundKnowledgeLookupBySlugReturnsKnownCandidates() throws {
        let semaglutide = try XCTUnwrap(AtlasCompoundKnowledgeCatalog.knowledge(slug: "semaglutide"))
        let compareCandidates = AtlasCompoundKnowledgeCatalog.compareCandidates(for: semaglutide, kind: .glp)

        XCTAssertEqual(semaglutide.displayName, "Semaglutide")
        XCTAssertNotNil(semaglutide.kineticsProfile)
        XCTAssertTrue(compareCandidates.contains(where: { $0.slug == "tirzepatide" }))
    }

    @MainActor
    func testImportedMetricsAreVisibleAndRespectPrivacyRendering() async throws {
        let controller = try makeInMemoryController()
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: true)
        bundle.snapshot.customMetrics = [
            AtlasCustomMetricRecord.make(
                id: "metric_imported",
                protocolId: "p1",
                metricKey: "recovery_score",
                label: "Recovery score",
                valueType: .number,
                unit: "pts",
                createdAt: "2026-03-09T08:00:00.000Z",
                updatedAt: "2026-03-09T08:00:00.000Z"
            )
        ]
        bundle.snapshot.metricValueLogs = [
            AtlasMetricValueLogRecord.make(
                id: "metric_log_imported",
                metricId: "metric_imported",
                protocolId: "p1",
                loggedAt: "2026-03-10T08:00:00.000Z",
                numberValue: 8,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-10T08:00:00.000Z",
                updatedAt: "2026-03-10T08:00:00.000Z"
            )
        ]
        bundle.snapshot.weightLogs = [
            AtlasWeightLogRecord.make(
                id: "weight_imported",
                loggedAt: "2026-03-10T08:00:00.000Z",
                value: 180,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-03-10T08:00:00.000Z",
                updatedAt: "2026-03-10T08:00:00.000Z"
            )
        ]
        bundle.snapshot.symptomLogs = [
            AtlasSymptomLogRecord.make(
                id: "symptom_imported",
                loggedAt: "2026-03-10T08:00:00.000Z",
                symptomKey: "fatigue",
                severity: 4,
                notes: nil,
                source: .manual,
                createdAt: "2026-03-10T08:00:00.000Z",
                updatedAt: "2026-03-10T08:00:00.000Z"
            )
        ]

        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        XCTAssertEqual(model.insightsSnapshot.customMetricDefinitions.count, 1)
        XCTAssertEqual(model.insightsSnapshot.recentMetricEntries.count, 1)
        XCTAssertEqual(model.insightsSnapshot.recentWeightEntries.count, 1)
        XCTAssertEqual(model.insightsSnapshot.recentSymptomEntries.count, 1)
        XCTAssertEqual(model.insightsSnapshot.customMetricDefinitions.first?.aliasProtocolTitle, "Evening plan")
        XCTAssertEqual(
            model.renderedTitle(
                canonical: model.insightsSnapshot.customMetricDefinitions[0].canonicalProtocolTitle ?? "",
                alias: model.insightsSnapshot.customMetricDefinitions[0].aliasProtocolTitle
            ),
            "Evening plan"
        )

        _ = try await controller.container.settings.updateTrustVaultRenderMode(
            .discreet,
            now: Date(timeIntervalSince1970: 1_773_960_000)
        )
        await model.refreshShellData()

        XCTAssertEqual(
            model.renderedTitle(
                canonical: model.insightsSnapshot.customMetricDefinitions[0].canonicalProtocolTitle ?? "",
                alias: model.insightsSnapshot.customMetricDefinitions[0].aliasProtocolTitle
            ),
            "Private protocol"
        )
    }

    @MainActor
    func testMetricLabelsStayPrivateOutsideFullMode() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Metric privacy protocol",
                kind: .glp,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.trustVault.saveProtocolAlias(
            AtlasProtocolAliasDraft(
                protocolID: protocolDetail.id,
                aliasLabel: "Evening plan"
            ),
            now: now.addingTimeInterval(1)
        )
        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                protocolID: protocolDetail.id,
                label: "Recovery score",
                valueType: .number,
                unit: "pts"
            ),
            now: now.addingTimeInterval(2)
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                protocolID: protocolDetail.id,
                loggedAt: now.addingTimeInterval(3),
                numberValue: 8
            ),
            now: now.addingTimeInterval(3)
        )

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.alias, now: now.addingTimeInterval(4))
        let aliasTimeline = try await controller.container.timeline.fetchTimeline(
            AtlasTimelineQuery(filter: .wellness, protocolID: nil, limit: 20)
        )
        let aliasExport = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .alias),
            now: now.addingTimeInterval(5)
        )
        let aliasContents = try String(contentsOf: aliasExport.fileURL, encoding: .utf8)
        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        XCTAssertEqual(model.renderedMetricLabel(canonical: "Recovery score"), "Alias metric")
        XCTAssertTrue(aliasTimeline.contains(where: { $0.type == .customMetricLogged && $0.summary.contains("Alias metric") }))
        XCTAssertFalse(aliasTimeline.contains(where: { $0.summary.contains("Recovery score") }))
        XCTAssertTrue(aliasContents.contains("Alias metric"))
        XCTAssertFalse(aliasContents.contains("Recovery score"))

        _ = try await controller.container.settings.updateTrustVaultRenderMode(.discreet, now: now.addingTimeInterval(6))
        await model.refreshShellData()

        XCTAssertEqual(model.renderedMetricLabel(canonical: "Recovery score"), "Private metric")
    }

    func testMetricDatasetsFlowIntoSelectiveShareAndRawExport() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let detail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Export protocol",
                kind: .glp,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        let metric = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                protocolID: detail.id,
                label: "Energy",
                valueType: .number,
                unit: "pts"
            ),
            now: now.addingTimeInterval(1)
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: metric.id,
                protocolID: detail.id,
                loggedAt: now.addingTimeInterval(2),
                numberValue: 9
            ),
            now: now.addingTimeInterval(2)
        )
        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(3),
                value: 182,
                unit: .lb
            ),
            now: now.addingTimeInterval(3)
        )
        _ = try await controller.container.metrics.saveSymptomEntry(
            AtlasSymptomEntryDraft(
                loggedAt: now.addingTimeInterval(4),
                symptomKey: "headache",
                severity: 2
            ),
            now: now.addingTimeInterval(4)
        )
        _ = try await controller.container.metrics.importWorkoutSamples(
            [
                AtlasHealthWorkoutSample(
                    id: "hk-export-workout-1",
                    activityKind: .run,
                    startedAt: now.addingTimeInterval(5),
                    endedAt: now.addingTimeInterval(5 + (25 * 60)),
                    durationMinutes: 25,
                    energyBurnedKilocalories: 310,
                    distanceMeters: 4_200
                )
            ],
            now: now.addingTimeInterval(5)
        )

        let preview = try await controller.importExportBridge.previewSelectiveShare(
            AtlasSelectiveShareRequest(
                scopeKind: .last30DaysLogs,
                renderMode: .full
            ),
            now: now.addingTimeInterval(6)
        )
        let export = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now.addingTimeInterval(6)
        )
        let csvExport = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .csv, renderMode: .full),
            now: now.addingTimeInterval(6)
        )
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: export.fileURL)) as? [String: Any]
        )
        let snapshot = try XCTUnwrap(payload["snapshot"] as? [String: Any])
        let csv = try String(contentsOf: csvExport.fileURL, encoding: .utf8)

        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "customMetrics" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "metricValueLogs" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "weightLogs" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "symptomLogs" && $0.rowCount == 1 }))
        XCTAssertFalse(preview.datasets.contains(where: { $0.dataset == "workoutLogs" }))
        XCTAssertEqual((snapshot["customMetrics"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["metricValueLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["weightLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["symptomLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["workoutLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertTrue(csv.contains("\"workout_log\""))
    }

    func testWorkoutLogsRoundTripThroughRawJsonBackup() async throws {
        let directory = try makeTemporaryDirectory()
        let sourceController = try AtlasPersistenceController.temporary(
            baseURL: directory.appendingPathComponent("source", isDirectory: true),
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let targetController = try AtlasPersistenceController.temporary(
            baseURL: directory.appendingPathComponent("target", isDirectory: true),
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: TestNotificationManager()
        )
        let now = Date(timeIntervalSince1970: 1_773_950_400)
        let workout = AtlasHealthWorkoutSample(
            id: "hk-roundtrip-workout-1",
            activityKind: .cycle,
            startedAt: now.addingTimeInterval(-3_600),
            endedAt: now.addingTimeInterval(-2_400),
            durationMinutes: 20,
            energyBurnedKilocalories: 180,
            distanceMeters: 7_500
        )

        _ = try await sourceController.container.metrics.importWorkoutSamples([workout], now: now)

        let export = try await sourceController.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now
        )
        let decoded = try JSONDecoder().decode(AtlasExportBundle.self, from: Data(contentsOf: export.fileURL))
        let exportedWorkout = try XCTUnwrap(decoded.snapshot.workoutLogs.first)

        XCTAssertEqual(decoded.snapshot.workoutLogs.count, 1)
        XCTAssertEqual(exportedWorkout.activityKind, .cycle)
        XCTAssertEqual(exportedWorkout.externalSourceId, "hk-roundtrip-workout-1")

        let prepared = try await targetController.importExportBridge.prepareImport(at: export.fileURL)
        _ = try await targetController.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let importedInsights = try await targetController.container.metrics.fetchInsightsSnapshot(referenceDate: now)

        XCTAssertEqual(importedInsights.recentWorkoutEntries.count, 1)
        XCTAssertEqual(importedInsights.recentWorkoutEntries.first?.activityKind, .cycle)
        XCTAssertEqual(importedInsights.recentWorkoutEntries.first?.durationLabel, "20 min")
    }

    func testUniversalAtlasJSONImportRoundTripAppendsImportAudit() async throws {
        let controller = try makeInMemoryController()
        let url = try writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: url)
        )

        XCTAssertEqual(prepared.dryRun.importer, .atlasJSON)
        XCTAssertGreaterThan(prepared.dryRun.recordsToCreate, 0)

        _ = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)
        let trustVault = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertTrue(trustVault.audits.contains(where: { $0.eventType == .importCommitted }))
    }

    func testAtlasCsvImportReconstructsCoreLoopWithWarnings() async throws {
        let sourceController = try makeInMemoryController()
        let prepared = try await sourceController.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await sourceController.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let export = try await sourceController.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .csv, renderMode: .full),
            now: Date()
        )
        let csv = try String(contentsOf: export.fileURL, encoding: .utf8)

        let targetController = try makeInMemoryController()
        let staged = try await targetController.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasCSV, rawText: csv)
        )

        XCTAssertTrue(staged.dryRun.warnings.contains(where: { $0.contains("Atlas CSV is lossy") }))

        _ = try await targetController.importExportBridge.commitUniversalImport(staged, mode: .replaceExisting)
        try await targetController.container.coreLoop.ensureProjectedOccurrences(referenceDate: importedFixtureReferenceDate)
        let summaries = try await targetController.container.protocols.listProtocolSummaries()
        let nextDue = try await targetController.container.today.fetchTodaySnapshot(referenceDate: importedFixtureReferenceDate).nextDue

        XCTAssertEqual(summaries.count, 1)
        XCTAssertNotNil(nextDue)
    }

    func testGenericCsvMappingValidationFlagsUnsupportedRows() async throws {
        let controller = try makeInMemoryController()
        let csv = """
        name,cadence,kind,time
        ,weekly,glp,08:00
        Travel plan,monthly,glp,08:00
        """

        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(
                importer: .genericCSV,
                rawText: csv,
                genericCsvMapping: AtlasGenericCsvMapping(
                    nameColumn: "name",
                    kindColumn: "kind",
                    cadenceColumn: "cadence",
                    timeColumn: "time"
                )
            )
        )

        XCTAssertEqual(prepared.dryRun.importer, AtlasImporterKind.genericCSV)
        XCTAssertEqual(prepared.stagedSnapshot.protocols.count, 0)
        XCTAssertEqual(prepared.dryRun.unsupportedRows.count, 2)
    }

    func testGenericCsvMappingCanCommitProtocols() async throws {
        let controller = try makeInMemoryController()
        let csv = """
        name,cadence,kind,time,dose,unit,notes,start_date
        Travel plan,every 3 days,glp,08:00,1,mg,Window seat kit,2026-03-20
        """

        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(
                importer: .genericCSV,
                rawText: csv,
                genericCsvMapping: AtlasGenericCsvMapping(
                    nameColumn: "name",
                    kindColumn: "kind",
                    cadenceColumn: "cadence",
                    timeColumn: "time",
                    doseAmountColumn: "dose",
                    doseUnitColumn: "unit",
                    notesColumn: "notes",
                    startDateColumn: "start_date"
                )
            )
        )

        _ = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)
        let summaries = try await controller.container.protocols.listProtocolSummaries()

        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.canonicalTitle, "Travel plan")
        XCTAssertTrue(summaries.first?.cadenceLabel.contains("Every 3") ?? false)
    }

    func testManualTextImportCanPreviewAndCommit() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(
                importer: .manualText,
                rawText: "Travel plan | weekly monday | 08:00 | 1 mg | glp",
                manualOptions: AtlasManualImportOptions(
                    defaultKind: .glp,
                    anchorDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                )
            )
        )

        XCTAssertEqual(prepared.stagedSnapshot.protocols.count, 1)
        _ = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)

        let nextDue = try await controller.container.today.fetchNextDue()
        XCTAssertNotNil(nextDue)
    }

    func testProviderHandoffCreatesSummaryAndAttachmentBundle() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.importExportBridge.createProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .currentProtocolOnly,
                protocolID: "p1",
                aliasModeEnabled: true
            ),
            now: Date()
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.summaryURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.attachmentURL.path))

        let summary = try String(contentsOf: result.summaryURL, encoding: .utf8)
        XCTAssertTrue(summary.contains("static snapshot"))

        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: result.attachmentURL)) as? [String: Any]
        )
        let manifest = try XCTUnwrap(payload["manifest"] as? [String: Any])
        let bundle = try XCTUnwrap(payload["bundle"] as? [String: Any])
        let snapshot = try XCTUnwrap(bundle["snapshot"] as? [String: Any])
        let protocols = try XCTUnwrap(snapshot["protocols"] as? [[String: Any]])

        XCTAssertEqual(manifest["format"] as? String, "atlas_provider_handoff")
        XCTAssertEqual(protocols.first?["name"] as? String, "Evening plan")
        XCTAssertFalse(summary.contains("Weekly GLP"))
    }

    func testProviderHandoffSelectedProtocolsScopeStaysBounded() async throws {
        let controller = try makeInMemoryController()
        let bundle = makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(try XCTUnwrap(bundle))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.importExportBridge.createProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .selectedProtocols,
                protocolIDs: ["p1"],
                aliasModeEnabled: false
            ),
            now: Date()
        )

        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: result.attachmentURL)) as? [String: Any]
        )
        let bundlePayload = try XCTUnwrap(payload["bundle"] as? [String: Any])
        let snapshot = try XCTUnwrap(bundlePayload["snapshot"] as? [String: Any])
        let protocols = try XCTUnwrap(snapshot["protocols"] as? [[String: Any]])

        XCTAssertEqual(protocols.count, 1)
        XCTAssertEqual(protocols.first?["id"] as? String, "p1")
        XCTAssertFalse(protocols.contains(where: { $0["id"] as? String == "p2" }))
    }

    func testProviderHandoffPlainLanguageSummaryUsesCurrentToggleAndAliasScope() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let disabledPreview = try await controller.importExportBridge.previewProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .currentProtocolOnly,
                protocolID: "p1",
                aliasModeEnabled: true
            ),
            now: Date()
        )
        XCTAssertNil(disabledPreview.plainLanguageSummary)

        _ = try await controller.container.settings.updateSummarySettings(
            AtlasSummarySettingsUpdate(onDeviceEnabled: true),
            now: Date()
        )

        let preview = try await controller.importExportBridge.previewProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .currentProtocolOnly,
                protocolID: "p1",
                aliasModeEnabled: true
            ),
            now: Date()
        )
        let summary = try XCTUnwrap(preview.plainLanguageSummary)
        XCTAssertTrue(
            summary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "render_mode" && $0.value == "Alias" })
        )
        XCTAssertTrue(
            summary.sourceSections
                .flatMap(\.facts)
                .contains(where: { $0.id == "dataset_count" && $0.value == String(preview.datasets.count) })
        )
        XCTAssertTrue(summary.summary.contains("across \(preview.datasets.count) datasets"))
        assertSummaryGuardrails(summary.summary)
    }

    func testUniversalImportCancelLeavesNoWrites() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(
                importer: .manualText,
                rawText: "Travel plan | daily | 09:00 | 1 mg | glp"
            )
        )

        await controller.importExportBridge.cancelUniversalImport(prepared)

        let summaries = try await controller.container.protocols.listProtocolSummaries()
        XCTAssertTrue(summaries.isEmpty)
    }

    func testUniversalImportPreservesImmutableHistoryGuarantee() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false)))
        )

        _ = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)
        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: importedFixtureReferenceDate)
        let history = try await controller.container.timeline.fetchHistory(limit: 10)
        let nextDue = try await controller.container.today.fetchTodaySnapshot(referenceDate: importedFixtureReferenceDate).nextDue

        XCTAssertEqual(history.count, 1)
        XCTAssertNotNil(nextDue)
        XCTAssertNotEqual(history.first?.id, nextDue?.id)
    }

    func testReviewModeCurrentProtocolScopeStaysBounded() async throws {
        let controller = try makeInMemoryController()
        let bundle = try XCTUnwrap(makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle)
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.container.reviewMode.createReview(
            AtlasReviewRequest(
                scopeKind: .currentProtocol,
                protocolID: "p1",
                aliasModeEnabled: false
            ),
            now: Date()
        )

        let payload = try reviewPackPayload(at: result.packURL)
        let bundlePayload = try XCTUnwrap(payload["bundle"] as? [String: Any])
        let snapshot = try XCTUnwrap(bundlePayload["snapshot"] as? [String: Any])
        let protocols = try XCTUnwrap(snapshot["protocols"] as? [[String: Any]])

        XCTAssertEqual(protocols.count, 1)
        XCTAssertEqual(protocols.first?["id"] as? String, "p1")
        XCTAssertFalse(protocols.contains(where: { $0["id"] as? String == "p2" }))
    }

    func testReviewModeAliasWorkspaceUsesAliasLabelsAndReadOnlyPack() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.container.reviewMode.createReview(
            AtlasReviewRequest(
                scopeKind: .currentProtocol,
                protocolID: "p1",
                aliasModeEnabled: true
            ),
            now: Date()
        )
        let workspace = try await controller.container.reviewMode.loadWorkspace(from: result.packURL, now: Date())

        XCTAssertTrue(workspace.readOnly)
        XCTAssertEqual(workspace.renderMode, .alias)
        XCTAssertTrue(workspace.sections.flatMap(\.lines).contains(where: { $0.contains("Evening plan") }))
        XCTAssertFalse(workspace.sections.flatMap(\.lines).contains(where: { $0.contains("Weekly GLP") }))
    }

    func testReviewModeExpirationAndOwnerSnapshotStatus() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let createdAt = Date(timeIntervalSince1970: 1_710_000_000)
        let expiresAt = createdAt.addingTimeInterval(3600)
        _ = try await controller.container.reviewMode.createReview(
            AtlasReviewRequest(
                scopeKind: .summaryOnly,
                aliasModeEnabled: false,
                expiresAt: expiresAt
            ),
            now: createdAt
        )

        let snapshot = try await controller.container.reviewMode.fetchOwnerSnapshot(now: expiresAt.addingTimeInterval(7200))
        XCTAssertEqual(snapshot.sessions.count, 1)
        XCTAssertEqual(snapshot.sessions.first?.status, .expired)
        XCTAssertEqual(snapshot.sessions.first?.expiresAt, expiresAt)
    }

    func testReviewModeDigestStaysWithinSelectedProtocolScope() async throws {
        let controller = try makeInMemoryController()
        let bundle = try XCTUnwrap(makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle)
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(bundle))
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let result = try await controller.container.reviewMode.createReview(
            AtlasReviewRequest(
                scopeKind: .selectedProtocols,
                protocolIDs: ["p1"],
                aliasModeEnabled: false
            ),
            now: Date()
        )

        let protocolSection = try XCTUnwrap(result.workspace.sections.first(where: { $0.title == "Protocol summary" }))
        XCTAssertTrue(protocolSection.lines.contains(where: { $0.contains("Weekly GLP") }))
        XCTAssertFalse(protocolSection.lines.contains(where: { $0.contains("Backup peptide") }))
    }

    func testReviewModeLiveSessionRequiresFeatureFlag() async throws {
        let controller = try makeInMemoryController(
            featureFlags: AtlasFeatureFlagState(liveReviewSessions: false)
        )
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        do {
            _ = try await controller.container.reviewMode.createReview(
                AtlasReviewRequest(
                    scopeKind: .summaryOnly,
                    aliasModeEnabled: false,
                    deliveryKind: .liveSession
                ),
                now: Date()
            )
            XCTFail("Expected live review sessions to be feature-flagged off.")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not enabled"))
        }
    }

    @MainActor
    func testReviewModeGuestPathDoesNotRequireAccount() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller)
        await model.refreshBootstrap()
        await model.refreshShellData()

        XCTAssertEqual(model.settingsSnapshot.accountMode, .guest)

        let result = await model.createReview(
            AtlasReviewRequest(
                scopeKind: .summaryOnly,
                aliasModeEnabled: false
            )
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(model.reviewOwnerSnapshot.sessions.count, 1)
    }

    @MainActor
    func testCloudSignInUpdatesAccountSettingsAndSession() async throws {
        let controller = try makeInMemoryController()
        let cloudSync = TestCloudSyncManager()
        let model = makeAppModel(controller: controller, cloudSync: cloudSync)

        await model.signInToCloud(email: "atlas@example.com", password: "secret-passphrase")

        XCTAssertEqual(model.settingsSnapshot.accountMode, .account)
        XCTAssertEqual(model.cloudSession?.email, "atlas@example.com")
        XCTAssertEqual(model.cloudSession?.userID, "test-user")
        XCTAssertEqual(model.cloudStatusDescription, "Signed in as atlas@example.com.")
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testCloudProviderSignInUpdatesAccountSettingsAndSession() async throws {
        let controller = try makeInMemoryController()
        let cloudSync = TestCloudSyncManager()
        let model = makeAppModel(controller: controller, cloudSync: cloudSync)

        await model.signInToCloud(with: .google)

        XCTAssertEqual(model.settingsSnapshot.accountMode, .account)
        XCTAssertEqual(model.cloudSession?.email, "google@atlas.example")
        XCTAssertEqual(model.cloudSession?.userID, "google-user")
        XCTAssertEqual(model.cloudStatusDescription, "Signed in as google@atlas.example.")
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testCloudSyncExportsLatestBundleAndUpdatesLastSync() async throws {
        let controller = try makeInMemoryController()
        let cloudSync = TestCloudSyncManager(
            session: AtlasCloudSessionSnapshot(email: "atlas@example.com", userID: "test-user")
        )
        let now = Date(timeIntervalSince1970: 1_776_000_000)
        let model = makeAppModel(
            controller: controller,
            cloudSync: cloudSync,
            referenceDate: now
        )

        _ = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Cloud protocol",
                kind: .glp,
                cadenceType: .daily,
                intervalDays: 1,
                weekday: nil,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )

        await model.syncToCloud()

        let uploadedBundle = try XCTUnwrap(cloudSync.latestUploadedBundle())
        let decoded = try JSONDecoder().decode(AtlasExportBundle.self, from: uploadedBundle)

        XCTAssertEqual(decoded.snapshot.protocols.first?.name, "Cloud protocol")
        XCTAssertEqual(model.settingsSnapshot.accountMode, .account)
        XCTAssertEqual(model.cloudSession?.lastSyncAt, now)
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testRestoreLatestCloudBackupImportsProtocolsAndRefreshesShell() async throws {
        let controller = try makeInMemoryController()
        let bundleData = try JSONEncoder().encode(makeSpecCompleteBundle(aliasModeEnabled: false))
        let cloudSync = TestCloudSyncManager(
            session: AtlasCloudSessionSnapshot(email: "atlas@example.com", userID: "test-user"),
            latestBundle: bundleData
        )
        let model = makeAppModel(
            controller: controller,
            cloudSync: cloudSync,
            referenceDate: importedFixtureReferenceDate
        )

        await model.restoreLatestCloudBackup()
        await model.refreshShellData()

        XCTAssertEqual(model.settingsSnapshot.accountMode, .account)
        XCTAssertEqual(model.libraryProtocols.count, 1)
        XCTAssertEqual(model.todaySnapshot.nextDue?.canonicalTitle, "Weekly GLP")
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectAndDisconnectHealthKitUpdatesSettingsConnection() async throws {
        let controller = try makeInMemoryController()
        let healthKit = TestHealthKitManager(available: true, authorizationGranted: true)
        let model = makeAppModel(controller: controller, healthKit: healthKit)

        await model.connectHealthKit()

        XCTAssertTrue(model.settingsSnapshot.healthScaffold.connections.contains(where: {
            $0.providerKey == .appleHealth && $0.connected
        }))
        XCTAssertEqual(healthKit.authorizationRequestCount, 1)
        XCTAssertNil(model.loadErrorMessage)

        await model.disconnectHealthKit()

        XCTAssertTrue(model.settingsSnapshot.healthScaffold.connections.allSatisfy { $0.connected == false })
        XCTAssertEqual(healthKit.disconnectCallCount, 1)
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectHealthKitImportsRecentWorkoutsIntoInsights() async throws {
        let controller = try makeInMemoryController()
        let workoutStart = Date(timeIntervalSince1970: 1_712_800_000)
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            workouts: [
                AtlasHealthWorkoutSample(
                    id: "hk-workout-1",
                    activityKind: .walk,
                    startedAt: workoutStart,
                    endedAt: workoutStart.addingTimeInterval(45 * 60),
                    durationMinutes: 45,
                    energyBurnedKilocalories: 220,
                    distanceMeters: 3_200
                )
            ]
        )
        let model = makeAppModel(controller: controller, healthKit: healthKit)

        await model.connectHealthKit()

        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.count, 1)
        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.first?.activityKind, .walk)
        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.first?.durationLabel, "45 min")
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectHealthKitImportsRecentWeightsIntoInsights() async throws {
        let controller = try makeInMemoryController()
        let loggedAt = Date(timeIntervalSince1970: 1_712_800_000)
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            weightSamples: [
                AtlasHealthWeightSample(
                    id: "hk-weight-1",
                    recordedAt: loggedAt,
                    value: 201.5,
                    unit: .lb
                )
            ]
        )
        let model = makeAppModel(controller: controller, healthKit: healthKit)

        await model.connectHealthKit()

        XCTAssertEqual(model.insightsSnapshot.recentWeightEntries.first?.valueLabel, "201.5 lb")
        XCTAssertEqual(model.settingsSnapshot.healthScaffold.syncedWeightEntryCount, 1)
        XCTAssertEqual(healthKit.fetchWeightSinceRequests.count, 1)
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectHealthKitImportsNutritionMetricsIntoInsights() async throws {
        let controller = try makeInMemoryController()
        let loggedAt = Date(timeIntervalSince1970: 1_712_800_000)
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            nutritionSamples: [
                AtlasHealthNutritionSample(
                    id: "hk-water-1",
                    kind: .water,
                    recordedAt: loggedAt,
                    value: 32
                ),
                AtlasHealthNutritionSample(
                    id: "hk-protein-1",
                    kind: .protein,
                    recordedAt: loggedAt.addingTimeInterval(300),
                    value: 42
                )
            ]
        )
        let model = makeAppModel(controller: controller, healthKit: healthKit)

        await model.connectHealthKit()

        XCTAssertEqual(healthKit.fetchNutritionSinceRequests.count, 1)
        XCTAssertTrue(model.insightsSnapshot.customMetricDefinitions.contains(where: { $0.label == "Water" }))
        XCTAssertTrue(model.insightsSnapshot.customMetricDefinitions.contains(where: { $0.label == "Protein" }))
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectHealthKitUsesPreviousLastSyncAtForFollowUpWorkoutImport() async throws {
        final class DateBox: @unchecked Sendable {
            var value: Date

            init(_ value: Date) {
                self.value = value
            }
        }

        let controller = try makeInMemoryController()
        let firstSyncDate = Date(timeIntervalSince1970: 1_712_800_000)
        let secondSyncDate = firstSyncDate.addingTimeInterval(3_600)
        let originalWorkout = AtlasHealthWorkoutSample(
            id: "hk-workout-1",
            activityKind: .walk,
            startedAt: firstSyncDate.addingTimeInterval(-1_800),
            endedAt: firstSyncDate.addingTimeInterval(-900),
            durationMinutes: 15
        )
        let newWorkout = AtlasHealthWorkoutSample(
            id: "hk-workout-2",
            activityKind: .run,
            startedAt: secondSyncDate.addingTimeInterval(300),
            endedAt: secondSyncDate.addingTimeInterval(1_200),
            durationMinutes: 15
        )
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            workouts: [originalWorkout]
        )
        let now = DateBox(firstSyncDate)
        let model = AtlasAppModel(
            dependencies: AtlasAppDependencies(
                featureFlags: AtlasFeatureFlags(flags: AtlasFeatureFlagState()),
                notifications: TestNotificationManager(),
                biometrics: AtlasBiometricGate(),
                healthKit: healthKit,
                cloudSync: TestCloudSyncManager(),
                diagnostics: AtlasDiagnosticsReporter(),
                importExport: controller.importExportBridge,
                sharedProjectionWriter: controller.sharedProjectionWriter,
                persistence: controller.container,
                reminders: controller.reminderCoordinator,
                calendarSync: controller.calendarSyncCoordinator,
                privacyFormatter: AtlasPrivacyFormatter(),
                dateProvider: { now.value }
            )
        )

        await model.connectHealthKit()
        healthKit.replaceWorkouts([originalWorkout, newWorkout])
        now.value = secondSyncDate

        await model.connectHealthKit()

        XCTAssertEqual(healthKit.fetchWorkoutSinceRequests.count, 2)
        XCTAssertNil(healthKit.fetchWorkoutSinceRequests[0])
        XCTAssertEqual(healthKit.fetchWorkoutSinceRequests[1], firstSyncDate)
        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.prefix(2).map(\.activityKind), [.run, .walk])
        XCTAssertEqual(
            model.settingsSnapshot.healthScaffold.connections.first { $0.providerKey == .appleHealth }?.lastSyncAt,
            ISO8601DateFormatter.atlas.string(from: secondSyncDate)
        )
        XCTAssertNil(model.loadErrorMessage)
    }

    @MainActor
    func testConnectHealthKitFollowUpSyncDedupesMixedWorkoutBatch() async throws {
        final class DateBox: @unchecked Sendable {
            var value: Date

            init(_ value: Date) {
                self.value = value
            }
        }

        let controller = try makeInMemoryController()
        let firstSyncDate = Date(timeIntervalSince1970: 1_712_800_000)
        let secondSyncDate = firstSyncDate.addingTimeInterval(7_200)
        let existingWorkout = AtlasHealthWorkoutSample(
            id: "hk-workout-existing",
            activityKind: .walk,
            startedAt: firstSyncDate.addingTimeInterval(-900),
            endedAt: firstSyncDate.addingTimeInterval(-300),
            durationMinutes: 10
        )
        let newWorkout = AtlasHealthWorkoutSample(
            id: "hk-workout-new",
            activityKind: .strength,
            startedAt: secondSyncDate.addingTimeInterval(300),
            endedAt: secondSyncDate.addingTimeInterval(2_100),
            durationMinutes: 30
        )
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            workouts: [existingWorkout],
            workoutResponses: [
                [existingWorkout],
                [existingWorkout, newWorkout]
            ]
        )
        let now = DateBox(firstSyncDate)
        let model = AtlasAppModel(
            dependencies: AtlasAppDependencies(
                featureFlags: AtlasFeatureFlags(flags: AtlasFeatureFlagState()),
                notifications: TestNotificationManager(),
                biometrics: AtlasBiometricGate(),
                healthKit: healthKit,
                cloudSync: TestCloudSyncManager(),
                diagnostics: AtlasDiagnosticsReporter(),
                importExport: controller.importExportBridge,
                sharedProjectionWriter: controller.sharedProjectionWriter,
                persistence: controller.container,
                reminders: controller.reminderCoordinator,
                calendarSync: controller.calendarSyncCoordinator,
                privacyFormatter: AtlasPrivacyFormatter(),
                dateProvider: { now.value }
            )
        )

        await model.connectHealthKit()
        now.value = secondSyncDate
        await model.connectHealthKit()

        XCTAssertEqual(healthKit.fetchWorkoutSinceRequests.count, 2)
        XCTAssertEqual(healthKit.fetchWorkoutSinceRequests[1], firstSyncDate)
        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.count, 2)
        XCTAssertEqual(model.insightsSnapshot.recentWorkoutEntries.prefix(2).map(\.activityKind), [.strength, .walk])
        XCTAssertNil(model.loadErrorMessage)
    }

    func testImportWorkoutSamplesSkipsDuplicatesByExternalSourceID() async throws {
        let controller = try makeInMemoryController()
        let sample = AtlasHealthWorkoutSample(
            id: "hk-workout-duplicate",
            activityKind: .strength,
            startedAt: Date(timeIntervalSince1970: 1_712_800_000),
            endedAt: Date(timeIntervalSince1970: 1_712_800_000).addingTimeInterval(1_800),
            durationMinutes: 30,
            energyBurnedKilocalories: 240
        )

        let firstImportCount = try await controller.container.metrics.importWorkoutSamples(
            [sample],
            now: Date(timeIntervalSince1970: 1_712_803_600)
        )
        let secondImportCount = try await controller.container.metrics.importWorkoutSamples(
            [sample],
            now: Date(timeIntervalSince1970: 1_712_807_200)
        )
        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(
            referenceDate: Date(timeIntervalSince1970: 1_712_807_200)
        )

        XCTAssertEqual(firstImportCount, 1)
        XCTAssertEqual(secondImportCount, 0)
        XCTAssertEqual(snapshot.recentWorkoutEntries.count, 1)
        XCTAssertEqual(snapshot.recentWorkoutEntries.first?.activityKind, .strength)
    }

    @MainActor
    func testLiveReviewSessionUsesCloudShareLinkAndRevokesRemoteSession() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let cloudSync = TestCloudSyncManager(
            session: AtlasCloudSessionSnapshot(email: "atlas@example.com", userID: "test-user")
        )
        let model = makeAppModel(controller: controller, cloudSync: cloudSync)

        await model.refreshShellData()
        let result = await model.createReview(
            AtlasReviewRequest(
                scopeKind: .summaryOnly,
                aliasModeEnabled: false,
                deliveryKind: .liveSession
            )
        )

        let sessionID = try XCTUnwrap(result?.session.id)
        XCTAssertEqual(result?.packURL.absoluteString, "https://atlas.example/live-review/review_test_remote")
        XCTAssertEqual(model.reviewOwnerSnapshot.sessions.first?.packURL?.absoluteString, result?.packURL.absoluteString)

        await model.revokeReviewSession(id: sessionID)

        XCTAssertEqual(cloudSync.revokedRemoteIDs, ["review_test_remote"])
        XCTAssertNil(model.loadErrorMessage)
    }

    func testImportTemplatesSaveListAndDeleteDeterministically() async throws {
        let controller = try makeInMemoryController()
        let createdAt = Date(timeIntervalSince1970: 1_710_000_000)
        let updatedAt = createdAt.addingTimeInterval(600)

        let created = try await controller.importExportBridge.saveImportTemplate(
            AtlasImportTemplateDraft(
                name: "Travel CSV",
                importer: .genericCSV,
                genericCsvMapping: AtlasGenericCsvMapping(
                    nameColumn: "protocol_name",
                    kindColumn: "kind",
                    cadenceColumn: "cadence"
                )
            ),
            now: createdAt
        )

        let updated = try await controller.importExportBridge.saveImportTemplate(
            AtlasImportTemplateDraft(
                name: "Travel CSV",
                importer: .genericCSV,
                genericCsvMapping: AtlasGenericCsvMapping(
                    nameColumn: "protocol_name",
                    kindColumn: "kind",
                    cadenceColumn: "cadence",
                    timeColumn: "time_local",
                    doseAmountColumn: "dose_amount"
                )
            ),
            now: updatedAt
        )

        XCTAssertEqual(created.id, updated.id)

        let templates = try await controller.importExportBridge.listImportTemplates(importer: .genericCSV)
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.name, "Travel CSV")
        XCTAssertEqual(templates.first?.genericCsvMapping?.timeColumn, "time_local")
        XCTAssertEqual(templates.first?.updatedAt, updatedAt)

        try await controller.importExportBridge.deleteImportTemplate(id: updated.id)

        let deleted = try await controller.importExportBridge.listImportTemplates(importer: .genericCSV)
        XCTAssertTrue(deleted.isEmpty)
    }

    func testUniversalImportDryRunSurfacesDeterministicLintFindings() async throws {
        let controller = try makeInMemoryController()
        let seedBundleURL = try writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        let seeded = try await controller.importExportBridge.prepareImport(at: seedBundleURL)
        _ = try await controller.importExportBridge.commitPreparedImport(seeded, mode: .replaceExisting)

        let atlasPrepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: seedBundleURL)
        )
        let atlasCategories = Set(atlasPrepared.dryRun.lintFindings.map(\.category))
        XCTAssertTrue(atlasCategories.contains(.duplicateProtocolName))
        XCTAssertTrue(atlasCategories.contains(.stableIDOverlap))

        let csv = """
        name,cadence,start_date,time,dose_amount,dose_unit
        Travel plan,daily,2026-03-15,09:00,1,mg
        Travel plan,daily,2026-03-15,09:00,1,
        """
        let genericPrepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(
                importer: .genericCSV,
                rawText: csv,
                genericCsvMapping: AtlasGenericCsvMapping(
                    nameColumn: "name",
                    cadenceColumn: "cadence",
                    timeColumn: "time",
                    doseAmountColumn: "dose_amount",
                    doseUnitColumn: "dose_unit",
                    startDateColumn: "start_date"
                ),
                manualOptions: AtlasManualImportOptions(
                    defaultKind: .glp,
                    timezone: "America/New_York",
                    anchorDate: Date(timeIntervalSince1970: 1_710_000_000)
                )
            )
        )
        let genericCategories = Set(genericPrepared.dryRun.lintFindings.map(\.category))
        XCTAssertTrue(genericCategories.contains(.dateTimeParsingCollision))
        XCTAssertTrue(genericCategories.contains(.ambiguousUnitMapping))
    }

    func testReplaceImportCreatesRestorePointBeforeCommit() async throws {
        let controller = try makeInMemoryController()
        let initial = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(initial, mode: .replaceExisting)

        let replacementBundle = try XCTUnwrap(makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle)
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: writeBundleURL(replacementBundle))
        )
        let result = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)
        let restorePoints = try await controller.importExportBridge.listRestorePoints()
        let trustVault = try await controller.container.trustVault.fetchTrustVaultSnapshot()

        XCTAssertEqual(restorePoints.count, 1)
        XCTAssertEqual(result.backupURL, restorePoints.first?.fileURL)
        XCTAssertTrue(trustVault.audits.contains(where: { $0.eventType == .restorePointCreated }))
        XCTAssertTrue(trustVault.audits.contains(where: { $0.eventType == .importCommitted }))
    }

    func testRestorePreviewMatchesRestoreResultAndAppendsAudit() async throws {
        let controller = try makeInMemoryController()
        let originalBundle = makeSpecCompleteBundle(aliasModeEnabled: false)
        let initial = try await controller.importExportBridge.prepareImport(at: writeBundleURL(originalBundle))
        _ = try await controller.importExportBridge.commitPreparedImport(initial, mode: .replaceExisting)

        let emptyTimestamp = "2026-03-14T00:00:00.000Z"
        let emptyBundle = AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: emptyTimestamp,
                source: "atlas-native-empty"
            ),
            snapshot: AtlasExportSnapshot(
                privacyProfile: .default(timestamp: emptyTimestamp),
                reminderPreference: .default(timestamp: emptyTimestamp)
            )
        )
        let emptyPrepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: writeBundleURL(emptyBundle))
        )
        _ = try await controller.importExportBridge.commitUniversalImport(emptyPrepared, mode: .replaceExisting)

        let restorePoints = try await controller.importExportBridge.listRestorePoints()
        let restorePoint = try XCTUnwrap(restorePoints.first)
        let preview = try await controller.importExportBridge.previewRestorePoint(id: restorePoint.id)
        let restored = try await controller.importExportBridge.restoreRestorePoint(
            id: restorePoint.id,
            now: Date(timeIntervalSince1970: 1_710_000_900)
        )
        let summaries = try await controller.container.protocols.listProtocolSummaries()
        let history = try await controller.container.timeline.fetchHistory(limit: 20)
        let trustVault = try await controller.container.trustVault.fetchTrustVaultSnapshot()
        let protocolDiff = preview.datasetDiffs.first(where: { $0.dataset == "protocols" })
        let historyDiff = preview.datasetDiffs.first(where: { $0.dataset == "logEvents" })

        XCTAssertEqual(preview.restorePoint.id, restored.restoredPoint.id)
        XCTAssertEqual(protocolDiff?.creates, restored.restoredProtocolCount)
        XCTAssertEqual(historyDiff?.creates, restored.restoredLogEventCount)
        XCTAssertEqual(summaries.count, restored.restoredProtocolCount)
        XCTAssertEqual(history.count, restored.restoredLogEventCount)
        XCTAssertTrue(trustVault.audits.contains(where: { $0.eventType == .restoreCommitted }))
    }

    func testPreviewRestorePointRejectsMissingBackupFile() async throws {
        let controller = try makeInMemoryController()
        let initial = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(initial, mode: .replaceExisting)

        let emptyTimestamp = "2026-03-14T00:00:00.000Z"
        let emptyBundle = AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: emptyTimestamp,
                source: "atlas-native-empty"
            ),
            snapshot: AtlasExportSnapshot(
                privacyProfile: .default(timestamp: emptyTimestamp),
                reminderPreference: .default(timestamp: emptyTimestamp)
            )
        )
        let emptyPrepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: writeBundleURL(emptyBundle))
        )
        _ = try await controller.importExportBridge.commitUniversalImport(emptyPrepared, mode: .replaceExisting)

        let restorePoints = try await controller.importExportBridge.listRestorePoints()
        let restorePoint = try XCTUnwrap(restorePoints.first)
        try FileManager.default.removeItem(at: restorePoint.fileURL)

        do {
            _ = try await controller.importExportBridge.previewRestorePoint(id: restorePoint.id)
            XCTFail("Expected restore preview to fail")
        } catch let error as AtlasImportError {
            guard case let .restorePointUnavailable(title) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(title, restorePoint.title)
        }
    }

    func testRestoreRestorePointRejectsTamperedBackupFile() async throws {
        let controller = try makeInMemoryController()
        let initialBundle = makeSpecCompleteBundle(aliasModeEnabled: false)
        let initial = try await controller.importExportBridge.prepareImport(at: writeBundleURL(initialBundle))
        _ = try await controller.importExportBridge.commitPreparedImport(initial, mode: .replaceExisting)

        let replacementBundle = try XCTUnwrap(makePhaseTwoFixtures().first(where: { $0.name == "multiple-protocols" })?.bundle)
        let prepared = try await controller.importExportBridge.prepareUniversalImport(
            AtlasUniversalImportRequest(importer: .atlasJSON, fileURL: writeBundleURL(replacementBundle))
        )
        _ = try await controller.importExportBridge.commitUniversalImport(prepared, mode: .replaceExisting)

        let restorePoints = try await controller.importExportBridge.listRestorePoints()
        let restorePoint = try XCTUnwrap(restorePoints.first)
        let tamperedBundle = makeSpecCompleteBundle(aliasModeEnabled: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(tamperedBundle).write(to: restorePoint.fileURL, options: [.atomic])

        do {
            _ = try await controller.importExportBridge.restoreRestorePoint(
                id: restorePoint.id,
                now: Date(timeIntervalSince1970: 1_710_001_000)
            )
            XCTFail("Expected restore commit to fail")
        } catch let error as AtlasImportError {
            guard case let .restorePointIntegrityMismatch(title) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(title, restorePoint.title)
        }
    }

    func testProviderHandoffPresetRequestsStayBounded() {
        let request = AtlasProviderHandoffPreset.partnerReview.makeRequest(
            protocolID: "p1",
            protocolIDs: ["p1", "p2"],
            dateRange: nil,
            now: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertEqual(request.scopeKind, .summaryOnly)
        XCTAssertEqual(request.protocolID, "p1")
        XCTAssertTrue(request.protocolIDs.isEmpty)
        XCTAssertTrue(request.aliasModeEnabled)
        XCTAssertNil(request.dateRange)
    }

    func testReviewPresetRequestsStayStaticAndBounded() {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let request = AtlasReviewPreset.partnerReview.makeRequest(
            protocolID: "p1",
            protocolIDs: ["p1", "p2"],
            dateRange: nil,
            now: now
        )

        XCTAssertEqual(request.scopeKind, .summaryOnly)
        XCTAssertEqual(request.protocolID, "p1")
        XCTAssertTrue(request.protocolIDs.isEmpty)
        XCTAssertTrue(request.aliasModeEnabled)
        XCTAssertEqual(request.deliveryKind, .staticPack)
        XCTAssertNotNil(request.expiresAt)
    }

    func testEpisodeWindowsAndPatternsBuildDeterministically() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: false, sparse: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())

        XCTAssertTrue(snapshot.episodeIntelligence.hasAnyEpisodeData)
        XCTAssertTrue(snapshot.episodeIntelligence.compareWindows.contains(where: { $0.windowKind == .postDose0To12Hours && $0.metricEntryCount > 0 }))
        XCTAssertTrue(snapshot.episodeIntelligence.compareWindows.contains(where: { $0.windowKind == .postDose12To48Hours && $0.symptomEntryCount > 0 && $0.weightEntryCount > 0 }))
        XCTAssertTrue(snapshot.episodeIntelligence.compareWindows.contains(where: { $0.windowKind == .day3To4 && $0.symptomEntryCount > 0 }))
        XCTAssertTrue(snapshot.episodeIntelligence.compareWindows.contains(where: { $0.windowKind == .preNextDose && $0.metricEntryCount > 0 }))
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.contains(where: { $0.type == .symptomCluster }))
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.contains(where: { $0.type == .lateLogging }))
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.contains(where: { $0.type == .weightShift }))
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.contains(where: { $0.type == .siteObservation }))
        XCTAssertTrue(snapshot.episodeIntelligence.disclaimer.contains("descriptive only"))
    }

    func testEpisodePatternThresholdsSuppressWeakSignals() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: false, sparse: true))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())

        XCTAssertTrue(snapshot.episodeIntelligence.hasAnyEpisodeData)
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.isEmpty)
        XCTAssertFalse(snapshot.episodeIntelligence.recentEpisodes.isEmpty)
    }

    func testEpisodePatternsStayIsolatedPerProtocol() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: true, sparse: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())

        XCTAssertFalse(snapshot.episodeIntelligence.patternCards.isEmpty)
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.allSatisfy { $0.protocolID == "p1" })
    }

    func testEpisodeSummariesStayScopedInSelectiveShareAndProviderHandoff() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeEpisodeIntelligenceBundle(aliasModeEnabled: false, includeSecondProtocol: true, sparse: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let sharePreview = try await controller.importExportBridge.previewSelectiveShare(
            AtlasSelectiveShareRequest(
                scopeKind: .protocolWithRecentTimeline,
                renderMode: .full,
                protocolID: "p1"
            ),
            now: Date()
        )
        let providerPreview = try await controller.importExportBridge.previewProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .selectedProtocols,
                protocolIDs: ["p1"],
                aliasModeEnabled: false
            ),
            now: Date()
        )

        XCTAssertNotNil(sharePreview.sections.first(where: { $0.title == "Episode summary" }))
        XCTAssertNotNil(providerPreview.sections.first(where: { $0.title == "Episode summary" }))

        let summaryOnlySharePreview = try await controller.importExportBridge.previewSelectiveShare(
            AtlasSelectiveShareRequest(
                scopeKind: .currentProtocolOnly,
                renderMode: .full,
                protocolID: "p1"
            ),
            now: Date()
        )

        XCTAssertNil(summaryOnlySharePreview.sections.first(where: { $0.title == "Episode summary" }))

        let noEpisodeProviderPreview = try await controller.importExportBridge.previewProviderHandoff(
            AtlasProviderHandoffRequest(
                scopeKind: .selectedProtocols,
                protocolIDs: ["p2"],
                aliasModeEnabled: false
            ),
            now: Date()
        )

        XCTAssertNil(noEpisodeProviderPreview.sections.first(where: { $0.title == "Episode summary" }))
    }

    @MainActor
    func testEpisodeAliasRenderingAndCopyStaySafe() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeEpisodeIntelligenceBundle(aliasModeEnabled: true, includeSecondProtocol: false, sparse: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = makeAppModel(controller: controller)
        await model.refreshShellData()

        let recentEpisode = try XCTUnwrap(model.insightsSnapshot.episodeIntelligence.recentEpisodes.first)
        XCTAssertEqual(
            model.renderedTitle(canonical: recentEpisode.canonicalProtocolTitle, alias: recentEpisode.aliasProtocolTitle),
            "Evening plan"
        )

        let copy = ([model.insightsSnapshot.episodeIntelligence.disclaimer]
            + model.insightsSnapshot.episodeIntelligence.patternCards.map(\.title)
            + model.insightsSnapshot.episodeIntelligence.patternCards.map(\.detail))
            .joined(separator: " ")
            .lowercased()
        XCTAssertFalse(copy.contains("recommend"))
        XCTAssertFalse(copy.contains("increase dose"))
        XCTAssertFalse(copy.contains("decrease dose"))
        XCTAssertFalse(copy.contains("diagnos"))
        XCTAssertFalse(copy.contains("treat"))
    }

    func testEpisodeMissingDataResilienceStaysCalm() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(
            at: writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: false))
        )
        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: Date())

        XCTAssertFalse(snapshot.episodeIntelligence.recentEpisodes.isEmpty)
        XCTAssertTrue(snapshot.episodeIntelligence.patternCards.isEmpty)
        XCTAssertTrue(snapshot.episodeIntelligence.disclaimer.contains("dose recommendations") || snapshot.episodeIntelligence.disclaimer.contains("medical guidance"))
    }

    func testRetentionSettingsDefaultOffAndDisableCompanionWhenProgressTurnsOff() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_000_000)

        let initial = try await controller.container.settings.currentSettingsSnapshot()
        XCTAssertFalse(initial.retentionSettings.progressEnabled)
        XCTAssertFalse(initial.retentionSettings.companionEnabled)

        let progressEnabled = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true),
            now: now
        )
        XCTAssertTrue(progressEnabled.retentionSettings.progressEnabled)
        XCTAssertFalse(progressEnabled.retentionSettings.companionEnabled)

        let companionEnabled = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(companionEnabled: true),
            now: now.addingTimeInterval(60)
        )
        XCTAssertTrue(companionEnabled.retentionSettings.progressEnabled)
        XCTAssertTrue(companionEnabled.retentionSettings.companionEnabled)

        let disabled = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: false),
            now: now.addingTimeInterval(120)
        )
        XCTAssertFalse(disabled.retentionSettings.progressEnabled)
        XCTAssertFalse(disabled.retentionSettings.companionEnabled)
    }

    func testRewardsSettingsDefaultOffAndPersistTargets() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_000_600)

        let initial = try await controller.container.settings.currentSettingsSnapshot()
        XCTAssertFalse(initial.rewardsSettings.enabled)
        XCTAssertEqual(initial.rewardsSettings.weeklyWorkoutGoal, 3)
        XCTAssertEqual(initial.rewardsSettings.weeklySelfGoalTarget, 2)

        let updated = try await controller.container.settings.updateRewardsSettings(
            AtlasRewardsSettingsUpdate(
                enabled: true,
                weeklyWorkoutGoal: 4,
                weeklySelfGoalTarget: 3
            ),
            now: now
        )

        XCTAssertTrue(updated.rewardsSettings.enabled)
        XCTAssertEqual(updated.rewardsSettings.weeklyWorkoutGoal, 4)
        XCTAssertEqual(updated.rewardsSettings.weeklySelfGoalTarget, 3)
    }

    func testRewardsSnapshotStaysHiddenByDefault() async throws {
        let controller = try makeInMemoryController()
        let snapshot = try await controller.container.rewards.fetchRewardsSnapshot(referenceDate: Date())

        XCTAssertFalse(snapshot.settings.enabled)
        XCTAssertEqual(snapshot.totalPoints, 0)
        XCTAssertEqual(snapshot.level, 1)
        XCTAssertTrue(snapshot.streaks.isEmpty)
        XCTAssertTrue(snapshot.goals.isEmpty)
        XCTAssertTrue(snapshot.badges.isEmpty)
    }

    func testRewardsSnapshotBuildsStreaksGoalsBadgesAndPoints() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_345_600)

        _ = try await controller.container.settings.updateRewardsSettings(
            AtlasRewardsSettingsUpdate(
                enabled: true,
                weeklyWorkoutGoal: 3,
                weeklySelfGoalTarget: 2
            ),
            now: now
        )

        _ = try await controller.container.onboarding.saveDraft(
            AtlasOnboardingDraft(
                profile: AtlasOnboardingProfile(
                    goalWeight: 180,
                    weight: 190,
                    weightUnit: .lb
                ),
                glp: AtlasOnboardingGlpSetup(goal: "Build a repeatable routine")
            ),
            now: now
        )

        let hydrationGoal = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Hydration goal",
                valueType: .boolean
            ),
            now: now.addingTimeInterval(30)
        )
        let proteinGoal = try await controller.container.metrics.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: "Protein goal",
                valueType: .boolean
            ),
            now: now.addingTimeInterval(40)
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: hydrationGoal.id,
                loggedAt: now.addingTimeInterval(-3_600),
                booleanValue: true
            ),
            now: now.addingTimeInterval(-3_600)
        )
        _ = try await controller.container.metrics.saveMetricValueEntry(
            AtlasMetricValueEntryDraft(
                metricID: proteinGoal.id,
                loggedAt: now.addingTimeInterval(-1_800),
                booleanValue: true
            ),
            now: now.addingTimeInterval(-1_800)
        )

        for dayOffset in stride(from: 6, through: 0, by: -1) {
            let loggedAt = now.addingTimeInterval(TimeInterval(-86_400 * dayOffset))
            _ = try await controller.container.metrics.saveWeightEntry(
                AtlasWeightEntryDraft(
                    loggedAt: loggedAt,
                    value: 190 - Double(6 - dayOffset),
                    unit: .lb,
                    notes: nil
                ),
                now: loggedAt
            )
        }

        let workouts = [
            AtlasHealthWorkoutSample(
                id: "reward_workout_1",
                activityKind: .run,
                startedAt: now.addingTimeInterval(-2 * 86_400),
                endedAt: now.addingTimeInterval(-2 * 86_400 + 2_700),
                durationMinutes: 45,
                energyBurnedKilocalories: 600
            ),
            AtlasHealthWorkoutSample(
                id: "reward_workout_2",
                activityKind: .strength,
                startedAt: now.addingTimeInterval(-86_400),
                endedAt: now.addingTimeInterval(-86_400 + 3_000),
                durationMinutes: 50,
                energyBurnedKilocalories: 550
            ),
            AtlasHealthWorkoutSample(
                id: "reward_workout_3",
                activityKind: .cycle,
                startedAt: now.addingTimeInterval(-3_600),
                endedAt: now.addingTimeInterval(-900),
                durationMinutes: 45,
                energyBurnedKilocalories: 500
            )
        ]
        _ = try await controller.container.metrics.importWorkoutSamples(workouts, now: now)

        let snapshot = try await controller.container.rewards.fetchRewardsSnapshot(referenceDate: now)
        let activityStreak = try XCTUnwrap(snapshot.streaks.first(where: { $0.kind == .activityDays }))
        let selfGoalStreak = try XCTUnwrap(snapshot.streaks.first(where: { $0.kind == .selfGoalWeeks }))
        let workoutGoal = try XCTUnwrap(snapshot.goals.first(where: { $0.kind == .weeklyWorkouts }))
        let selfGoal = try XCTUnwrap(snapshot.goals.first(where: { $0.kind == .selfDefinedGoals }))
        let weightGoal = try XCTUnwrap(snapshot.goals.first(where: { $0.kind == .weightGoal }))

        XCTAssertTrue(snapshot.settings.enabled)
        XCTAssertEqual(activityStreak.count, 7)
        XCTAssertTrue(activityStreak.isActive)
        XCTAssertEqual(selfGoalStreak.count, 1)
        XCTAssertTrue(selfGoalStreak.isActive)
        XCTAssertTrue(workoutGoal.isMet)
        XCTAssertTrue(selfGoal.isMet)
        XCTAssertGreaterThanOrEqual(weightGoal.progress, 0.25)
        XCTAssertTrue(snapshot.badges.contains(where: { $0.kind == .activityStreak7 && $0.isEarned }))
        XCTAssertTrue(snapshot.badges.contains(where: { $0.kind == .workoutGoalMet && $0.isEarned }))
        XCTAssertTrue(snapshot.badges.contains(where: { $0.kind == .selfGoalTargetMet && $0.isEarned }))
        XCTAssertTrue(snapshot.badges.contains(where: { $0.kind == .weightCheckpoint && $0.isEarned }))
        XCTAssertGreaterThan(snapshot.totalPoints, 0)
        XCTAssertGreaterThan(snapshot.level, 1)
    }

    func testInsightsNutritionSnapshotBuildsTargetsAndMealFavorites() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_518_000)

        _ = try await controller.container.metrics.saveContextPreset(
            AtlasContextPresetDraft(
                title: "Protein lunch",
                mealTiming: .lunch,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed
            ),
            now: now.addingTimeInterval(-600)
        )
        _ = try await controller.container.metrics.saveContextPreset(
            AtlasContextPresetDraft(
                title: "Fiber dinner",
                mealTiming: .dinner,
                mealSize: .standard,
                mealComposition: .fiberForward,
                fedState: .fed
            ),
            now: now.addingTimeInterval(-540)
        )

        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-18_000),
                mealTiming: .breakfast,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed,
                hydration: .high
            ),
            now: now.addingTimeInterval(-18_000)
        )
        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-12_000),
                mealTiming: .lunch,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed
            ),
            now: now.addingTimeInterval(-12_000)
        )
        _ = try await controller.container.metrics.saveContextEntry(
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-4_200),
                mealTiming: .dinner,
                mealSize: .standard,
                mealComposition: .fiberForward,
                fedState: .fed,
                hydration: .high
            ),
            now: now.addingTimeInterval(-4_200)
        )

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let proteinTarget = try XCTUnwrap(snapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals }))
        let fiberTarget = try XCTUnwrap(snapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .fiberMeals }))
        let hydrationTarget = try XCTUnwrap(snapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins }))

        XCTAssertEqual(snapshot.nutritionSnapshot.favoriteMealCount, 2)
        XCTAssertEqual(snapshot.nutritionSnapshot.recentMealCount, 3)
        XCTAssertNotNil(snapshot.nutritionSnapshot.latestMealLabel)
        XCTAssertTrue(proteinTarget.isMet)
        XCTAssertTrue(fiberTarget.isMet)
        XCTAssertTrue(hydrationTarget.isMet)
    }

    func testNutritionQuickCaptureParsesFreeformMealsAndPackageCodes() throws {
        let now = Date(timeIntervalSince1970: 1_774_518_000)

        let parsed = try XCTUnwrap(
            atlasNutritionQuickCaptureSuggestion(
                for: "post workout protein shake and water",
                loggedAt: now
            )
        )
        let packageMatch = try XCTUnwrap(
            atlasNutritionPackageCodeSuggestion(
                for: "SHAKE-01",
                loggedAt: now
            )
        )
        let lookupItems = atlasNutritionLookupItems(matching: "salad greens", limit: 3)

        XCTAssertEqual(parsed.source, .freeform)
        XCTAssertEqual(parsed.draft.mealComposition, .proteinHeavy)
        XCTAssertEqual(parsed.draft.mealTiming, .snack)
        XCTAssertEqual(parsed.draft.note, "post workout protein shake and water")
        XCTAssertEqual(packageMatch.source, .packageCode)
        XCTAssertEqual(packageMatch.draft.mealComposition, .proteinHeavy)
        XCTAssertTrue(lookupItems.contains(where: { $0.id == "big-salad-bowl" }))
    }

    func testInsightsNutritionSnapshotBuildsWeeklySignalsAndCoaching() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_604_400)

        _ = try await controller.container.onboarding.saveDraft(
            AtlasOnboardingDraft(
                profile: AtlasOnboardingProfile(
                    goalWeight: 180,
                    weight: 190,
                    weightUnit: .lb
                ),
                glp: AtlasOnboardingGlpSetup(goal: "Keep meals and training consistent")
            ),
            now: now
        )

        let contextEntries: [AtlasContextEntryDraft] = [
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-6 * 86_400 + 7 * 3_600),
                mealTiming: .breakfast,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-6 * 86_400 + 12 * 3_600),
                mealTiming: .lunch,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-5 * 86_400 + 8 * 3_600),
                mealTiming: .breakfast,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-5 * 86_400 + 18 * 3_600),
                mealTiming: .dinner,
                mealSize: .standard,
                mealComposition: .fiberForward,
                fedState: .fed
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-4 * 86_400 + 7 * 3_600),
                mealTiming: .breakfast,
                mealSize: .standard,
                mealComposition: .proteinHeavy,
                fedState: .fed,
                hydration: .high
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-4 * 86_400 + 19 * 3_600),
                hydration: .high,
                giTags: [.calm]
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-2 * 86_400 + 11 * 3_600),
                mealTiming: .lunch,
                mealSize: .standard,
                mealComposition: .fiberForward,
                fedState: .fed
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-2 * 86_400 + 13 * 3_600),
                hydration: .high,
                giTags: [.calm]
            ),
            AtlasContextEntryDraft(
                loggedAt: now.addingTimeInterval(-3_600),
                mealTiming: .snack,
                mealSize: .light,
                mealComposition: .proteinHeavy,
                fedState: .fed
            )
        ]
        for entry in contextEntries {
            _ = try await controller.container.metrics.saveContextEntry(entry, now: entry.loggedAt)
        }

        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(-10 * 86_400),
                value: 190,
                unit: .lb
            ),
            now: now.addingTimeInterval(-10 * 86_400)
        )
        _ = try await controller.container.metrics.saveWeightEntry(
            AtlasWeightEntryDraft(
                loggedAt: now.addingTimeInterval(-86_400),
                value: 186,
                unit: .lb
            ),
            now: now.addingTimeInterval(-86_400)
        )

        let workouts = [
            AtlasHealthWorkoutSample(
                id: "nutrition_workout_1",
                activityKind: .run,
                startedAt: now.addingTimeInterval(-5 * 86_400 + 13 * 3_600),
                endedAt: now.addingTimeInterval(-5 * 86_400 + 14 * 3_600),
                durationMinutes: 60,
                energyBurnedKilocalories: 520
            ),
            AtlasHealthWorkoutSample(
                id: "nutrition_workout_2",
                activityKind: .strength,
                startedAt: now.addingTimeInterval(-12 * 3_600),
                endedAt: now.addingTimeInterval(-10 * 3_600),
                durationMinutes: 120,
                energyBurnedKilocalories: 450
            )
        ]
        _ = try await controller.container.metrics.importWorkoutSamples(workouts, now: now)

        let snapshot = try await controller.container.metrics.fetchInsightsSnapshot(referenceDate: now)
        let proteinSignal = try XCTUnwrap(snapshot.nutritionSnapshot.weeklySignals.first(where: { $0.kind == .proteinDays }))
        let workoutSignal = try XCTUnwrap(snapshot.nutritionSnapshot.weeklySignals.first(where: { $0.kind == .workoutFueling }))

        XCTAssertEqual(proteinSignal.valueLabel, "1 of 7 days")
        XCTAssertEqual(workoutSignal.valueLabel, "1 of 2 workouts")
        XCTAssertTrue(snapshot.nutritionSnapshot.coachingCards.contains(where: { $0.kind == .workoutFueling }))
        XCTAssertTrue(snapshot.nutritionSnapshot.coachingCards.contains(where: { $0.kind == .weight }))
        XCTAssertFalse(snapshot.nutritionSnapshot.coachingCards.isEmpty)
    }

    @MainActor
    func testRetentionSnapshotStaysHiddenByDefaultAndModelRefreshLoadsCleanly() async throws {
        let controller = try makeInMemoryController()
        let model = makeAppModel(controller: controller)

        await model.refreshShellData()

        XCTAssertNil(model.loadErrorMessage)
        XCTAssertFalse(model.retentionSnapshot.settings.progressEnabled)
        XCTAssertTrue(model.retentionSnapshot.milestones.isEmpty)
        XCTAssertNil(model.retentionSnapshot.companion)
    }

    func testRetentionSnapshotCapturesContextConsistencyAndKeepsCopyGeneric() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_086_400)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Sensitive GLP Plan",
                kind: .glp,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now.addingTimeInterval(-172_800)
        )

        _ = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true, companionEnabled: true),
            now: now
        )

        for dayOffset in stride(from: 2, through: 0, by: -1) {
            let loggedAt = now.addingTimeInterval(TimeInterval(-86_400 * dayOffset + 1_800))
            _ = try await controller.container.metrics.saveContextEntry(
                AtlasContextEntryDraft(
                    protocolID: protocolDetail.id,
                    loggedAt: loggedAt,
                    mealTiming: .breakfast,
                    fedState: .fasted,
                    appetite: .low,
                    hydration: .low,
                    giTags: [.nausea],
                    note: "Private breakfast",
                    tags: ["travel"]
                ),
                now: loggedAt
            )
        }

        let snapshot = try await controller.container.retention.fetchRetentionSnapshot(referenceDate: now)
        let checkedIn = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .checkedInToday }))
        let context = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .contextConsistency }))

        XCTAssertTrue(snapshot.settings.progressEnabled)
        XCTAssertTrue(snapshot.settings.companionEnabled)
        XCTAssertTrue(checkedIn.isEarned)
        XCTAssertTrue(context.isEarned)
        XCTAssertEqual(context.continuityLabel, "3 days")
        XCTAssertNotNil(snapshot.companion)

        assertRetentionCopyPrivacySafe(
            [snapshot.note, snapshot.companion?.title, snapshot.companion?.subtitle]
                + snapshot.milestones.flatMap { [$0.title, $0.subtitle, $0.helperText] }
        )
    }

    func testRetentionCompanionStaysHiddenWithoutMeaningfulContinuity() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_259_200)

        _ = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true, companionEnabled: true),
            now: now
        )

        _ = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 24,
                unit: "pad",
                reorderThreshold: 6,
                quantityPerUse: 1
            ),
            now: now
        )

        let snapshot = try await controller.container.retention.fetchRetentionSnapshot(referenceDate: now.addingTimeInterval(600))
        let inventory = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .inventoryCurrent }))

        XCTAssertTrue(inventory.isEarned)
        XCTAssertNil(snapshot.companion)
    }

    func testMarkWeeklyReviewCompleteDoesNotTouchTimelineHistory() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_172_800)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Retention protocol",
                kind: .custom,
                cadenceType: .daily,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true),
            now: now
        )

        try await controller.container.coreLoop.ensureProjectedOccurrences(referenceDate: now)
        let todaySnapshot = try await controller.container.today.fetchTodaySnapshot(referenceDate: now)
        let occurrence = try XCTUnwrap(todaySnapshot.nextDue)

        try await controller.container.coreLoop.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: protocolDetail.id,
                action: .taken,
                note: nil
            ),
            now: now.addingTimeInterval(600)
        )

        let beforeHistory = try await controller.container.timeline.fetchHistory(limit: 20)
        let snapshot = try await controller.container.retention.markWeeklyReviewComplete(now: now.addingTimeInterval(900))
        let afterHistory = try await controller.container.timeline.fetchHistory(limit: 20)
        let weeklyReview = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .weeklyReviewCompleted }))

        XCTAssertEqual(beforeHistory.map(\.id), afterHistory.map(\.id))
        XCTAssertEqual(beforeHistory.map(\.summary), afterHistory.map(\.summary))
        XCTAssertTrue(weeklyReview.isEarned)
    }

    func testRetentionSnapshotUsesReviewSessionsAndInventorySignals() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_774_259_200)
        let protocolDetail = try await controller.container.protocols.createProtocol(
            AtlasProtocolDraft(
                name: "Inventory review protocol",
                kind: .custom,
                cadenceType: .weekly,
                weekday: 2,
                defaultTimeOfDay: "09:00",
                doseAmount: 1,
                doseUnit: "mg"
            ),
            now: now
        )
        _ = try await controller.container.settings.updateRetentionSettings(
            AtlasRetentionSettingsUpdate(progressEnabled: true),
            now: now
        )

        _ = try await controller.container.inventory.saveConsumable(
            AtlasConsumableDraft(
                protocolID: protocolDetail.id,
                name: "Alcohol pads",
                category: "Swab",
                quantityOnHand: 24,
                unit: "pad",
                reorderThreshold: 6,
                quantityPerUse: 1
            ),
            now: now
        )

        _ = try await controller.container.reviewMode.createReview(
            AtlasReviewRequest(
                scopeKind: .summaryOnly,
                aliasModeEnabled: false
            ),
            now: now.addingTimeInterval(300)
        )

        let snapshot = try await controller.container.retention.fetchRetentionSnapshot(referenceDate: now.addingTimeInterval(600))
        let inventory = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .inventoryCurrent }))
        let weeklyReview = try XCTUnwrap(snapshot.milestones.first(where: { $0.kind == .weeklyReviewCompleted }))

        XCTAssertTrue(inventory.isEarned)
        XCTAssertTrue(weeklyReview.isEarned)
    }

    @MainActor
    func testConnectHealthKitImportsBroaderPassiveSignals() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_776_100_000)
        let healthKit = TestHealthKitManager(
            available: true,
            authorizationGranted: true,
            metricSamples: [
                AtlasHealthMetricSample(
                    id: "steps-1",
                    kind: .steps,
                    recordedAt: now.addingTimeInterval(-3_600),
                    value: 8_400
                ),
                AtlasHealthMetricSample(
                    id: "sleep-1",
                    kind: .sleepHours,
                    recordedAt: now.addingTimeInterval(-1_800),
                    value: 7.4
                ),
                AtlasHealthMetricSample(
                    id: "rhr-1",
                    kind: .restingHeartRate,
                    recordedAt: now.addingTimeInterval(-600),
                    value: 58
                ),
                AtlasHealthMetricSample(
                    id: "bp-1-s",
                    kind: .bloodPressureSystolic,
                    recordedAt: now.addingTimeInterval(-300),
                    value: 118
                ),
                AtlasHealthMetricSample(
                    id: "bp-1-d",
                    kind: .bloodPressureDiastolic,
                    recordedAt: now.addingTimeInterval(-300),
                    value: 74
                ),
                AtlasHealthMetricSample(
                    id: "body-fat-1",
                    kind: .bodyFatPercentage,
                    recordedAt: now,
                    value: 18.6
                )
            ]
        )
        let model = makeAppModel(controller: controller, healthKit: healthKit, referenceDate: now)

        await model.connectHealthKit()

        let summaries = Dictionary(uniqueKeysWithValues: model.settingsSnapshot.healthScaffold.signalSummaries.map { ($0.kind, $0) })
        XCTAssertEqual(summaries[.steps]?.importedEntryCount, 1)
        XCTAssertEqual(summaries[.sleep]?.importedEntryCount, 1)
        XCTAssertEqual(summaries[.restingHeartRate]?.importedEntryCount, 1)
        XCTAssertEqual(summaries[.bloodPressure]?.importedEntryCount, 1)
        XCTAssertEqual(summaries[.bodyFat]?.importedEntryCount, 1)
        XCTAssertEqual(healthKit.fetchMetricSinceRequests, [nil])
        XCTAssertNil(model.loadErrorMessage)
    }

    func testInventorySitesPersistBodyMapRegions() async throws {
        let controller = try makeInMemoryController()
        let now = Date(timeIntervalSince1970: 1_776_100_000)

        _ = try await controller.container.inventory.saveSite(
            AtlasSiteDraft(
                name: "Lower abdomen left",
                bodyArea: "Abdomen",
                mapRegionKey: .abdomenLowerLeft,
                notes: "Primary rotation start"
            ),
            now: now
        )

        let sites = try await controller.container.inventory.listSites()

        XCTAssertEqual(sites.first?.mapRegionKey, .abdomenLowerLeft)
        XCTAssertEqual(sites.first?.bodyArea, "Abdomen")
    }

    @MainActor
    func testSavingSiteQueuesAutomaticCloudBackup() async throws {
        let controller = try makeInMemoryController()
        let cloudSync = TestCloudSyncManager(
            session: AtlasCloudSessionSnapshot(
                email: "atlas@example.com",
                userID: "test-user",
                deviceID: "test-device"
            )
        )
        let model = makeAppModel(controller: controller, cloudSync: cloudSync)

        await model.refreshCloudStatus()
        await model.saveSite(
            AtlasSiteDraft(
                name: "Upper abdomen right",
                bodyArea: "Abdomen",
                mapRegionKey: .abdomenUpperRight
            )
        )

        try await Task.sleep(nanoseconds: 2_500_000_000)

        let data = try XCTUnwrap(cloudSync.latestUploadedBundle())
        let bundle = try JSONDecoder().decode(AtlasExportBundle.self, from: data)

        XCTAssertEqual(bundle.snapshot.sites.first?.mapRegionKey, .abdomenUpperRight)
        XCTAssertEqual(model.cloudSession?.deviceID, "test-device")
        XCTAssertNotNil(model.cloudSession?.lastSyncAt)
    }

    private func makeInMemoryController(
        featureFlags: AtlasFeatureFlagState = AtlasFeatureFlagState(),
        notifications: any NotificationManaging = TestNotificationManager(),
        externalCalendars: any ExternalCalendarManaging = TestExternalCalendarManager()
    ) throws -> AtlasPersistenceController {
        try AtlasPersistenceController.inMemory(
            featureFlags: featureFlags,
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: notifications,
            externalCalendars: externalCalendars
        )
    }

    @MainActor
    private func makeAppModel(
        controller: AtlasPersistenceController,
        featureFlags: AtlasFeatureFlagState = AtlasFeatureFlagState(),
        notifications: any NotificationManaging = TestNotificationManager(),
        biometrics: any BiometricGating = AtlasBiometricGate(),
        healthKit: any HealthKitManaging = AtlasHealthKitManager(),
        cloudSync: any CloudSyncManaging = TestCloudSyncManager(),
        reminders: (any ReminderCoordinating)? = nil,
        referenceDate: Date? = nil
    ) -> AtlasAppModel {
        AtlasAppModel(
            dependencies: AtlasAppDependencies(
                featureFlags: AtlasFeatureFlags(flags: featureFlags),
                notifications: notifications,
                biometrics: biometrics,
                healthKit: healthKit,
                cloudSync: cloudSync,
                diagnostics: AtlasDiagnosticsReporter(),
                importExport: controller.importExportBridge,
                sharedProjectionWriter: controller.sharedProjectionWriter,
                persistence: controller.container,
                reminders: reminders ?? controller.reminderCoordinator,
                calendarSync: controller.calendarSyncCoordinator,
                privacyFormatter: AtlasPrivacyFormatter(),
                dateProvider: { referenceDate ?? Date() }
            )
        )
    }

    private var importedFixtureReferenceDate: Date {
        Date(timeIntervalSince1970: 1_773_576_000) // 2026-03-15 12:00:00 UTC
    }

    private func assertSummaryGuardrails(_ summary: String) {
        let lowered = summary.lowercased()
        let bannedFragments = [
            "diagnos",
            "treat",
            "therapy",
            "prescrib",
            "increase dose",
            "decrease dose",
            "change dose",
            "recommend",
            "buy",
            "purchase",
            "source"
        ]
        for fragment in bannedFragments {
            XCTAssertFalse(
                lowered.contains(fragment),
                "Summary unexpectedly contained banned fragment '\(fragment)'."
            )
        }
    }

    private func assertRetentionCopyPrivacySafe(_ fragments: [String?]) {
        let lowered = fragments
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        let bannedFragments = [
            "sensitive glp plan",
            "private breakfast",
            "travel",
            "streak",
            "points",
            "leaderboard",
            "reward"
        ]
        for fragment in bannedFragments {
            XCTAssertFalse(
                lowered.contains(fragment),
                "Retention copy unexpectedly contained sensitive fragment '\(fragment)'."
            )
        }
    }

    private func completeOnboardingIfNeeded(controller: AtlasPersistenceController) async throws {
        let snapshot = try await controller.container.onboarding.loadBootstrapSnapshot()
        guard snapshot.destination != .app else {
            return
        }

        _ = try await controller.container.onboarding.completeOnboarding(
            makeCompleteOnboardingDraft(accountMode: .guest, trackType: .later),
            now: Date()
        )
    }

    private func writeBundleURL(_ bundle: AtlasExportBundle) throws -> URL {
        let url = try makeTemporaryDirectory().appendingPathComponent(UUID().uuidString + ".json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(bundle).write(to: url)
        return url
    }

    private func reviewPackPayload(at url: URL) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func makeCompleteOnboardingDraft(
        accountMode: AtlasOnboardingAccountMode,
        trackType: AtlasTrackType
    ) -> AtlasOnboardingDraft {
        AtlasOnboardingDraft(
            accountMode: accountMode,
            privacy: AtlasOnboardingPrivacy(),
            trackType: trackType,
            journeyStatus: .active,
            focus: .neverMiss,
            privacyPreset: .standard,
            premiumPlan: .annual,
            paywallChoice: .trialStarted,
            profile: AtlasOnboardingProfile(
                gender: "Other",
                age: 34,
                goalWeight: 165,
                height: 70,
                heightUnit: .ftIn,
                weight: 190,
                weightUnit: .lb,
                goalPacePoundsPerWeek: 1.5,
                wantsNutritionTracking: true
            ),
            glp: AtlasOnboardingGlpSetup(
                medication: "Semaglutide",
                frequency: "Weekly",
                injectionDay: "Monday",
                dose: "1 mg",
                duration: "3 months",
                goal: "Consistency",
                challenge: "Travel days"
            ),
            peptide: AtlasOnboardingPeptideSetup(
                selections: ["BPC-157"],
                frequency: "Daily",
                experience: "Intermediate",
                usualTime: "08:00",
                dose: "250 mcg",
                goal: "Recovery"
            ),
            healthConnectionPromptSeen: true,
            healthDisclaimerAccepted: true
        )
    }

    private func writeLegacyBundleURL() throws -> URL {
        let legacyPayload = """
        {
          "generatedAt": "2026-03-14T00:00:00.000Z",
          "snapshot": {
            "protocols": [
              {
                "id": "p1",
                "compoundId": null,
                "linkedVialId": null,
                "name": "Weekly GLP",
                "kind": "glp",
                "status": "active",
                "timezone": "America/New_York",
                "startDate": "2026-03-01",
                "defaultTimeOfDay": "08:00",
                "doseAmount": 1,
                "doseUnit": "mg",
                "siteTrackingEnabled": false,
                "siteRotationEnabled": false,
                "notes": null,
                "createdAt": "2026-03-01T00:00:00.000Z",
                "updatedAt": "2026-03-01T00:00:00.000Z"
              }
            ],
            "protocolRules": [
              {
                "id": "r1",
                "protocolId": "p1",
                "ruleType": "weekly",
                "intervalCount": 1,
                "weekday": 1,
                "timeOfDay": "08:00",
                "anchorDate": "2026-03-01",
                "isActive": true,
                "createdAt": "2026-03-01T00:00:00.000Z",
                "updatedAt": "2026-03-01T00:00:00.000Z"
              }
            ],
            "reminders": [
              {
                "id": "rem1",
                "protocolId": "p1",
                "occurrenceId": "occ1",
                "offsetMinutes": 0,
                "channel": "local_notification",
                "isEnabled": true,
                "discreetCopyEnabled": false,
                "privacyMode": "generic",
                "scheduledFor": "2026-03-15T08:00:00.000Z",
                "notificationId": null,
                "title": "Atlas",
                "body": "Atlas reminder",
                "status": "scheduled",
                "createdAt": "2026-03-01T00:00:00.000Z",
                "updatedAt": "2026-03-01T00:00:00.000Z"
              }
            ],
            "logEvents": [],
            "calculatorProfiles": [],
            "compounds": [],
            "customMetrics": [],
            "healthConnections": [],
            "metricValueLogs": [],
            "protocolAliases": [],
            "sites": [],
            "symptomLogs": [],
            "vials": [],
            "weightLogs": []
          }
        }
        """

        let url = try makeTemporaryDirectory().appendingPathComponent("legacy.json")
        try legacyPayload.data(using: .utf8).unwrap().write(to: url)
        return url
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return url
    }

    private func makeSpecCompleteBundle(aliasModeEnabled: Bool) -> AtlasExportBundle {
        AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: "2026-03-14T00:00:00.000Z",
                source: "atlas-react-native"
            ),
            snapshot: AtlasExportSnapshot(
                calculatorProfiles: [],
                compounds: [
                    AtlasCompoundRecord.make(
                        id: "cmp1",
                        slug: "wegovy",
                        displayName: "Wegovy",
                        compoundType: "glp",
                        isUserDefined: false,
                        notes: nil,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                customMetrics: [],
                healthConnections: [],
                logEvents: [
                    AtlasLogEventRecord.make(
                        id: "log1",
                        protocolId: "p1",
                        vialId: nil,
                        siteId: nil,
                        occurrenceId: "occ1",
                        eventType: .completed,
                        effectiveAt: "2026-03-08T08:00:00.000Z",
                        loggedAt: "2026-03-08T08:00:00.000Z",
                        quantity: 1,
                        quantityUnit: "mg",
                        notes: nil,
                        source: .user
                    )
                ],
                metricValueLogs: [],
                privacyProfile: AtlasPrivacyProfileRecord.make(
                    id: "default",
                    aliasModeEnabled: aliasModeEnabled,
                    biometricLockEnabled: false,
                    biometricGateMode: .bestEffort,
                    shareAliasByDefault: true,
                    exportAliasByDefault: aliasModeEnabled,
                    createdAt: "2026-03-01T00:00:00.000Z",
                    updatedAt: "2026-03-01T00:00:00.000Z"
                ),
                protocolChangeAudits: [
                    AtlasProtocolChangeAuditRecord.make(
                        id: "audit1",
                        protocolId: "p1",
                        revisionId: "prv1",
                        previousRevisionId: nil,
                        changeType: .futureDoseChanged,
                        effectiveFrom: "2026-03-10T08:00:00.000Z",
                        summary: "Dose changes next week.",
                        payloadJson: "{\"dose\":2}",
                        createdAt: "2026-03-02T00:00:00.000Z"
                    )
                ],
                protocolAliases: [
                    AtlasProtocolAliasRecord.make(
                        id: "alias1",
                        protocolId: "p1",
                        aliasLabel: "Evening plan",
                        aliasCompoundLabel: "Blue vial",
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z",
                        archivedAt: nil
                    )
                ],
                protocolRevisionRules: [
                    AtlasProtocolRevisionRuleRecord(
                        id: "prr1",
                        revisionId: "prv1",
                        phaseType: .base,
                        phaseOrder: 0,
                        ruleType: .weekly,
                        intervalCount: 1,
                        weekday: 1,
                        timeOfDay: "08:00",
                        anchorDate: "2026-03-01",
                        phaseStartDayOffset: 0,
                        phaseLengthDays: nil,
                        doseAmountOverride: nil,
                        doseUnitOverride: nil,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                protocolRevisions: [
                    AtlasProtocolRevisionRecord(
                        id: "prv1",
                        protocolId: "p1",
                        revisionNumber: 1,
                        previousRevisionId: nil,
                        effectiveFrom: "2026-03-01T00:00:00.000Z",
                        effectiveTo: nil,
                        lifecycleState: .active,
                        timezone: "America/New_York",
                        timezoneStrategy: .keepLocalClock,
                        defaultTimeOfDay: "08:00",
                        doseAmount: 1,
                        doseUnit: "mg",
                        linkedVialId: nil,
                        missedDosePolicy: .skipAndContinue,
                        notes: nil,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                protocols: [
                    AtlasProtocolRecord.make(
                        id: "p1",
                        compoundId: "cmp1",
                        linkedVialId: nil,
                        name: "Weekly GLP",
                        kind: .glp,
                        status: .active,
                        timezone: "America/New_York",
                        startDate: "2026-03-01",
                        defaultTimeOfDay: "08:00",
                        doseAmount: 1,
                        doseUnit: "mg",
                        siteTrackingEnabled: false,
                        siteRotationEnabled: false,
                        notes: nil,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                protocolRules: [
                    AtlasProtocolRuleRecord.make(
                        id: "r1",
                        protocolId: "p1",
                        ruleType: .weekly,
                        intervalCount: 1,
                        weekday: 1,
                        timeOfDay: "08:00",
                        anchorDate: "2026-03-01",
                        isActive: true,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                reminderPreference: AtlasReminderPreferenceRecord.make(
                    id: "default",
                    remindersEnabled: true,
                    privacyMode: .generic,
                    leadTimeMinutes: 0,
                    createdAt: "2026-03-01T00:00:00.000Z",
                    updatedAt: "2026-03-01T00:00:00.000Z"
                ),
                reminders: [
                    AtlasReminderRecord.make(
                        id: "rem1",
                        protocolId: "p1",
                        occurrenceId: "occ1",
                        offsetMinutes: 0,
                        channel: .localNotification,
                        isEnabled: true,
                        discreetCopyEnabled: false,
                        privacyMode: .generic,
                        scheduledFor: "2026-03-15T08:00:00.000Z",
                        notificationId: nil,
                        title: "Atlas reminder",
                        body: "A private routine is due tomorrow.",
                        status: .scheduled,
                        createdAt: "2026-03-01T00:00:00.000Z",
                        updatedAt: "2026-03-01T00:00:00.000Z"
                    )
                ],
                sensitiveActionAudits: [
                    AtlasSensitiveActionAuditRecord.make(
                        id: "sensitive1",
                        eventType: .exportCreated,
                        surface: "trust_vault",
                        protocolId: "p1",
                        scopeKind: "full_export",
                        renderMode: .alias,
                        manifestVersion: 1,
                        payloadJson: "{\"scope\":\"full\"}",
                        createdAt: "2026-03-03T00:00:00.000Z"
                    )
                ],
                sites: [],
                symptomLogs: [],
                vials: [],
                weightLogs: []
            )
        )
    }

    private func makeEpisodeIntelligenceBundle(
        aliasModeEnabled: Bool,
        includeSecondProtocol: Bool,
        sparse: Bool
    ) -> AtlasExportBundle {
        var bundle = makeSpecCompleteBundle(aliasModeEnabled: aliasModeEnabled)
        bundle.snapshot.logEvents = [
            AtlasLogEventRecord.make(
                id: "episode_log_1",
                protocolId: "p1",
                vialId: nil,
                siteId: "site_left",
                occurrenceId: "occ_episode_1",
                eventType: .completed,
                effectiveAt: "2026-02-22T08:00:00.000Z",
                loggedAt: sparse ? "2026-02-22T08:10:00.000Z" : "2026-02-22T10:30:00.000Z",
                quantity: 1,
                quantityUnit: "mg",
                notes: nil,
                source: .user
            ),
            AtlasLogEventRecord.make(
                id: "episode_log_2",
                protocolId: "p1",
                vialId: nil,
                siteId: sparse ? nil : "site_left",
                occurrenceId: "occ_episode_2",
                eventType: .completed,
                effectiveAt: "2026-03-01T08:00:00.000Z",
                loggedAt: sparse ? "2026-03-01T08:15:00.000Z" : "2026-03-01T10:40:00.000Z",
                quantity: 1,
                quantityUnit: "mg",
                notes: nil,
                source: .user
            ),
            AtlasLogEventRecord.make(
                id: "episode_log_3",
                protocolId: "p1",
                vialId: nil,
                siteId: sparse ? nil : "site_left",
                occurrenceId: "occ_episode_3",
                eventType: .completed,
                effectiveAt: "2026-03-08T08:00:00.000Z",
                loggedAt: sparse ? "2026-03-08T08:20:00.000Z" : "2026-03-08T10:50:00.000Z",
                quantity: 1,
                quantityUnit: "mg",
                notes: nil,
                source: .user
            )
        ]
        if includeSecondProtocol {
            bundle.snapshot.protocols.append(
                AtlasProtocolRecord.make(
                    id: "p2",
                    compoundId: "cmp1",
                    linkedVialId: nil,
                    name: "Backup peptide",
                    kind: .peptide,
                    status: .active,
                    timezone: "America/New_York",
                    startDate: "2026-02-20",
                    defaultTimeOfDay: "20:00",
                    doseAmount: 0.5,
                    doseUnit: "mg",
                    siteTrackingEnabled: false,
                    siteRotationEnabled: false,
                    notes: nil,
                    createdAt: "2026-02-20T00:00:00.000Z",
                    updatedAt: "2026-02-20T00:00:00.000Z"
                )
            )
            bundle.snapshot.protocolRules.append(
                AtlasProtocolRuleRecord.make(
                    id: "rule_p2",
                    protocolId: "p2",
                    ruleType: .weekly,
                    intervalCount: 1,
                    weekday: 3,
                    timeOfDay: "20:00",
                    anchorDate: "2026-02-20",
                    isActive: true,
                    createdAt: "2026-02-20T00:00:00.000Z",
                    updatedAt: "2026-02-20T00:00:00.000Z"
                )
            )
            bundle.snapshot.protocolRevisions.append(
                AtlasProtocolRevisionRecord(
                    id: "prv2",
                    protocolId: "p2",
                    revisionNumber: 1,
                    previousRevisionId: nil,
                    effectiveFrom: "2026-02-20T00:00:00.000Z",
                    effectiveTo: nil,
                    lifecycleState: .active,
                    timezone: "America/New_York",
                    timezoneStrategy: .keepLocalClock,
                    defaultTimeOfDay: "20:00",
                    doseAmount: 0.5,
                    doseUnit: "mg",
                    linkedVialId: nil,
                    missedDosePolicy: .skipAndContinue,
                    notes: nil,
                    createdAt: "2026-02-20T00:00:00.000Z",
                    updatedAt: "2026-02-20T00:00:00.000Z"
                )
            )
            bundle.snapshot.protocolRevisionRules.append(
                AtlasProtocolRevisionRuleRecord(
                    id: "prr2",
                    revisionId: "prv2",
                    phaseType: .base,
                    phaseOrder: 0,
                    ruleType: .weekly,
                    intervalCount: 1,
                    weekday: 3,
                    timeOfDay: "20:00",
                    anchorDate: "2026-02-20",
                    phaseStartDayOffset: 0,
                    phaseLengthDays: nil,
                    doseAmountOverride: nil,
                    doseUnitOverride: nil,
                    createdAt: "2026-02-20T00:00:00.000Z",
                    updatedAt: "2026-02-20T00:00:00.000Z"
                )
            )
        }

        bundle.snapshot.sites = [
            AtlasSiteRecord.make(
                id: "site_left",
                name: "Left abdomen",
                bodyArea: "abdomen",
                notes: nil,
                createdAt: "2026-02-20T00:00:00.000Z",
                updatedAt: "2026-02-20T00:00:00.000Z",
                archivedAt: nil
            )
        ]
        bundle.snapshot.reminders = [
            AtlasReminderRecord.make(
                id: "rem_episode_1",
                protocolId: "p1",
                occurrenceId: "occ_episode_1",
                offsetMinutes: 30,
                channel: .localNotification,
                isEnabled: true,
                discreetCopyEnabled: false,
                privacyMode: .fullDetail,
                scheduledFor: "2026-02-22T07:30:00.000Z",
                notificationId: nil,
                title: "Weekly GLP",
                body: "Dose due",
                status: .scheduled,
                createdAt: "2026-02-22T07:00:00.000Z",
                updatedAt: "2026-02-22T07:00:00.000Z"
            ),
            AtlasReminderRecord.make(
                id: "rem_episode_2",
                protocolId: "p1",
                occurrenceId: "occ_episode_2",
                offsetMinutes: 30,
                channel: .localNotification,
                isEnabled: true,
                discreetCopyEnabled: false,
                privacyMode: .fullDetail,
                scheduledFor: "2026-03-01T07:30:00.000Z",
                notificationId: nil,
                title: "Weekly GLP",
                body: "Dose due",
                status: .scheduled,
                createdAt: "2026-03-01T07:00:00.000Z",
                updatedAt: "2026-03-01T07:00:00.000Z"
            ),
            AtlasReminderRecord.make(
                id: "rem_episode_3",
                protocolId: "p1",
                occurrenceId: "occ_episode_3",
                offsetMinutes: 30,
                channel: .localNotification,
                isEnabled: true,
                discreetCopyEnabled: false,
                privacyMode: .fullDetail,
                scheduledFor: "2026-03-08T07:30:00.000Z",
                notificationId: nil,
                title: "Weekly GLP",
                body: "Dose due",
                status: .scheduled,
                createdAt: "2026-03-08T07:00:00.000Z",
                updatedAt: "2026-03-08T07:00:00.000Z"
            )
        ]
        bundle.snapshot.customMetrics = [
            AtlasCustomMetricRecord.make(
                id: "metric_energy",
                protocolId: "p1",
                metricKey: "energy",
                label: "Energy",
                valueType: .number,
                unit: "score",
                createdAt: "2026-02-20T00:00:00.000Z",
                updatedAt: "2026-02-20T00:00:00.000Z"
            )
        ]
        bundle.snapshot.weightLogs = [
            AtlasWeightLogRecord.make(
                id: "weight_base_1",
                loggedAt: "2026-02-22T06:00:00.000Z",
                value: 200,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-02-22T06:00:00.000Z",
                updatedAt: "2026-02-22T06:00:00.000Z"
            ),
            AtlasWeightLogRecord.make(
                id: "weight_follow_1",
                loggedAt: sparse ? "2026-02-22T09:00:00.000Z" : "2026-02-23T09:00:00.000Z",
                value: sparse ? 199.9 : 198.8,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-02-23T09:00:00.000Z",
                updatedAt: "2026-02-23T09:00:00.000Z"
            ),
            AtlasWeightLogRecord.make(
                id: "weight_base_2",
                loggedAt: "2026-03-01T06:00:00.000Z",
                value: 199.5,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-03-01T06:00:00.000Z",
                updatedAt: "2026-03-01T06:00:00.000Z"
            ),
            AtlasWeightLogRecord.make(
                id: "weight_follow_2",
                loggedAt: sparse ? "2026-03-01T09:00:00.000Z" : "2026-03-02T09:00:00.000Z",
                value: sparse ? 199.4 : 198.2,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-03-02T09:00:00.000Z",
                updatedAt: "2026-03-02T09:00:00.000Z"
            ),
            AtlasWeightLogRecord.make(
                id: "weight_base_3",
                loggedAt: "2026-03-08T06:00:00.000Z",
                value: 199.0,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-03-08T06:00:00.000Z",
                updatedAt: "2026-03-08T06:00:00.000Z"
            ),
            AtlasWeightLogRecord.make(
                id: "weight_follow_3",
                loggedAt: sparse ? "2026-03-08T09:00:00.000Z" : "2026-03-09T09:00:00.000Z",
                value: sparse ? 198.9 : 197.9,
                unit: .lb,
                source: .manual,
                notes: nil,
                createdAt: "2026-03-09T09:00:00.000Z",
                updatedAt: "2026-03-09T09:00:00.000Z"
            )
        ]
        bundle.snapshot.symptomLogs = sparse ? [
            AtlasSymptomLogRecord.make(
                id: "sym_sparse_1",
                loggedAt: "2026-03-02T10:00:00.000Z",
                symptomKey: "nausea",
                severity: 4,
                notes: nil,
                source: .manual,
                createdAt: "2026-03-02T10:00:00.000Z",
                updatedAt: "2026-03-02T10:00:00.000Z"
            )
        ] : [
            AtlasSymptomLogRecord.make(
                id: "sym_1",
                loggedAt: "2026-02-23T10:00:00.000Z",
                symptomKey: "nausea",
                severity: 4,
                notes: nil,
                source: .manual,
                createdAt: "2026-02-23T10:00:00.000Z",
                updatedAt: "2026-02-23T10:00:00.000Z"
            ),
            AtlasSymptomLogRecord.make(
                id: "sym_2",
                loggedAt: "2026-03-02T10:00:00.000Z",
                symptomKey: "nausea",
                severity: 5,
                notes: nil,
                source: .manual,
                createdAt: "2026-03-02T10:00:00.000Z",
                updatedAt: "2026-03-02T10:00:00.000Z"
            ),
            AtlasSymptomLogRecord.make(
                id: "sym_3",
                loggedAt: "2026-03-09T10:00:00.000Z",
                symptomKey: "nausea",
                severity: 4,
                notes: nil,
                source: .manual,
                createdAt: "2026-03-09T10:00:00.000Z",
                updatedAt: "2026-03-09T10:00:00.000Z"
            ),
            AtlasSymptomLogRecord.make(
                id: "sym_4",
                loggedAt: "2026-03-04T09:00:00.000Z",
                symptomKey: "fatigue",
                severity: 3,
                notes: nil,
                source: .manual,
                createdAt: "2026-03-04T09:00:00.000Z",
                updatedAt: "2026-03-04T09:00:00.000Z"
            )
        ]
        bundle.snapshot.metricValueLogs = sparse ? [
            AtlasMetricValueLogRecord.make(
                id: "metric_sparse_1",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-03-01T12:00:00.000Z",
                numberValue: 4,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-01T12:00:00.000Z",
                updatedAt: "2026-03-01T12:00:00.000Z"
            )
        ] : [
            AtlasMetricValueLogRecord.make(
                id: "metric_1",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-02-22T12:00:00.000Z",
                numberValue: 4,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-02-22T12:00:00.000Z",
                updatedAt: "2026-02-22T12:00:00.000Z"
            ),
            AtlasMetricValueLogRecord.make(
                id: "metric_2",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-03-01T05:00:00.000Z",
                numberValue: 3,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-01T05:00:00.000Z",
                updatedAt: "2026-03-01T05:00:00.000Z"
            ),
            AtlasMetricValueLogRecord.make(
                id: "metric_3",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-03-01T12:00:00.000Z",
                numberValue: 4,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-01T12:00:00.000Z",
                updatedAt: "2026-03-01T12:00:00.000Z"
            ),
            AtlasMetricValueLogRecord.make(
                id: "metric_4",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-03-08T05:30:00.000Z",
                numberValue: 3,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-08T05:30:00.000Z",
                updatedAt: "2026-03-08T05:30:00.000Z"
            ),
            AtlasMetricValueLogRecord.make(
                id: "metric_5",
                metricId: "metric_energy",
                protocolId: "p1",
                loggedAt: "2026-03-08T12:00:00.000Z",
                numberValue: 3,
                textValue: nil,
                booleanValue: nil,
                source: .manual,
                createdAt: "2026-03-08T12:00:00.000Z",
                updatedAt: "2026-03-08T12:00:00.000Z"
            )
        ]
        return bundle
    }

    private func makeBlankBundle() -> AtlasExportBundle {
        AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: "2026-03-14T00:00:00.000Z",
                source: "atlas-react-native"
            ),
            snapshot: AtlasExportSnapshot(
                calculatorProfiles: [],
                compounds: [],
                customMetrics: [],
                healthConnections: [],
                logEvents: [],
                metricValueLogs: [],
                privacyProfile: .default(timestamp: "2026-03-14T00:00:00.000Z"),
                protocolChangeAudits: [],
                protocolAliases: [],
                protocolRevisionRules: [],
                protocolRevisions: [],
                protocols: [],
                protocolRules: [],
                reminderPreference: .default(timestamp: "2026-03-14T00:00:00.000Z"),
                reminders: [],
                sensitiveActionAudits: [],
                sites: [],
                symptomLogs: [],
                vials: [],
                weightLogs: []
            )
        )
    }

    private func makePhaseTwoFixtures() -> [PhaseTwoFixture] {
        var multipleProtocols = makeSpecCompleteBundle(aliasModeEnabled: false)
        multipleProtocols.snapshot.protocols.append(
            AtlasProtocolRecord.make(
                id: "p2",
                compoundId: nil,
                linkedVialId: nil,
                name: "Peptide cycle",
                kind: .peptide,
                status: .active,
                timezone: "America/New_York",
                startDate: "2026-03-02",
                defaultTimeOfDay: "19:00",
                doseAmount: 0.25,
                doseUnit: "mL",
                siteTrackingEnabled: true,
                siteRotationEnabled: false,
                notes: "Evening injection",
                createdAt: "2026-03-02T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        )
        multipleProtocols.snapshot.protocolRules.append(
            AtlasProtocolRuleRecord.make(
                id: "r2",
                protocolId: "p2",
                ruleType: .everyNDays,
                intervalCount: 3,
                weekday: nil,
                timeOfDay: "19:00",
                anchorDate: "2026-03-02",
                isActive: true,
                createdAt: "2026-03-02T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        )
        multipleProtocols.snapshot.protocolRevisions.append(
            AtlasProtocolRevisionRecord(
                id: "prv2",
                protocolId: "p2",
                revisionNumber: 1,
                previousRevisionId: nil,
                effectiveFrom: "2026-03-02T00:00:00.000Z",
                effectiveTo: nil,
                lifecycleState: .active,
                timezone: "America/New_York",
                timezoneStrategy: .keepLocalClock,
                defaultTimeOfDay: "19:00",
                doseAmount: 0.25,
                doseUnit: "mL",
                linkedVialId: nil,
                missedDosePolicy: .skipAndContinue,
                notes: "Evening injection",
                createdAt: "2026-03-02T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        )
        multipleProtocols.snapshot.protocolRevisionRules.append(
            AtlasProtocolRevisionRuleRecord(
                id: "prr2",
                revisionId: "prv2",
                phaseType: .base,
                phaseOrder: 0,
                ruleType: .everyNDays,
                intervalCount: 3,
                weekday: nil,
                timeOfDay: "19:00",
                anchorDate: "2026-03-02",
                phaseStartDayOffset: 0,
                phaseLengthDays: nil,
                doseAmountOverride: nil,
                doseUnitOverride: nil,
                createdAt: "2026-03-02T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        )
        multipleProtocols.snapshot.reminders.append(
            AtlasReminderRecord.make(
                id: "rem2",
                protocolId: "p2",
                occurrenceId: "occ2",
                offsetMinutes: 0,
                channel: .localNotification,
                isEnabled: true,
                discreetCopyEnabled: false,
                privacyMode: .generic,
                scheduledFor: "2026-03-16T19:00:00.000Z",
                notificationId: nil,
                title: "Peptide cycle",
                body: "Atlas reminder",
                status: .scheduled,
                createdAt: "2026-03-02T00:00:00.000Z",
                updatedAt: "2026-03-02T00:00:00.000Z"
            )
        )

        var revisionHistory = makeSpecCompleteBundle(aliasModeEnabled: false)
        revisionHistory.snapshot.protocolRevisions.append(
            AtlasProtocolRevisionRecord(
                id: "prv1b",
                protocolId: "p1",
                revisionNumber: 2,
                previousRevisionId: "prv1",
                effectiveFrom: "2026-03-10T00:00:00.000Z",
                effectiveTo: nil,
                lifecycleState: .active,
                timezone: "America/New_York",
                timezoneStrategy: .keepLocalClock,
                defaultTimeOfDay: "09:00",
                doseAmount: 2,
                doseUnit: "mg",
                linkedVialId: nil,
                missedDosePolicy: .skipAndContinue,
                notes: "Increase after tolerance check",
                createdAt: "2026-03-09T00:00:00.000Z",
                updatedAt: "2026-03-09T00:00:00.000Z"
            )
        )
        revisionHistory.snapshot.protocolRevisionRules.append(
            AtlasProtocolRevisionRuleRecord(
                id: "prr1b",
                revisionId: "prv1b",
                phaseType: .base,
                phaseOrder: 0,
                ruleType: .weekly,
                intervalCount: 1,
                weekday: 1,
                timeOfDay: "09:00",
                anchorDate: "2026-03-10",
                phaseStartDayOffset: 0,
                phaseLengthDays: nil,
                doseAmountOverride: 2,
                doseUnitOverride: "mg",
                createdAt: "2026-03-09T00:00:00.000Z",
                updatedAt: "2026-03-09T00:00:00.000Z"
            )
        )
        revisionHistory.snapshot.protocolChangeAudits.append(
            AtlasProtocolChangeAuditRecord.make(
                id: "audit2",
                protocolId: "p1",
                revisionId: "prv1b",
                previousRevisionId: "prv1",
                changeType: .futureDoseChanged,
                effectiveFrom: "2026-03-10T09:00:00.000Z",
                summary: "Dose increased after week one.",
                payloadJson: "{\"dose\":2}",
                createdAt: "2026-03-09T00:00:00.000Z"
            )
        )

        var trustVaultAlias = makeSpecCompleteBundle(aliasModeEnabled: true)
        trustVaultAlias.snapshot.reminderPreference = AtlasReminderPreferenceRecord.make(
            id: "default",
            remindersEnabled: true,
            privacyMode: .silent,
            leadTimeMinutes: 0,
            createdAt: "2026-03-01T00:00:00.000Z",
            updatedAt: "2026-03-01T00:00:00.000Z"
        )
        trustVaultAlias.snapshot.reminders[0].privacyMode = .silent
        trustVaultAlias.snapshot.reminders[0].body = "A private routine is due tomorrow."

        var inventoryAndSites = makeSpecCompleteBundle(aliasModeEnabled: false)
        inventoryAndSites.snapshot.sites = [
            AtlasSiteRecord.make(
                id: "site1",
                name: "Left abdomen",
                bodyArea: "abdomen",
                notes: "Rotate weekly",
                createdAt: "2026-03-01T00:00:00.000Z",
                updatedAt: "2026-03-01T00:00:00.000Z",
                archivedAt: nil
            )
        ]
        inventoryAndSites.snapshot.vials = [
            AtlasVialRecord.make(
                id: "vial1",
                protocolId: "p1",
                compoundId: "cmp1",
                label: "Current vial",
                startingQuantity: 10,
                concentrationValue: 2.5,
                concentrationUnit: "mg/mL",
                volumeMl: 4,
                remainingQuantity: 7,
                lowStockThreshold: 2,
                quantityUnit: "mg",
                openedAt: "2026-03-01T00:00:00.000Z",
                expiresAt: "2026-04-01T00:00:00.000Z",
                createdAt: "2026-03-01T00:00:00.000Z",
                updatedAt: "2026-03-08T00:00:00.000Z"
            )
        ]
        inventoryAndSites.snapshot.protocols[0].linkedVialId = "vial1"
        inventoryAndSites.snapshot.protocolRevisions[0].linkedVialId = "vial1"
        inventoryAndSites.snapshot.logEvents[0].vialId = "vial1"
        inventoryAndSites.snapshot.logEvents[0].siteId = "site1"

        var auditHeavySharing = makeSpecCompleteBundle(aliasModeEnabled: true)
        auditHeavySharing.snapshot.sensitiveActionAudits.append(
            AtlasSensitiveActionAuditRecord.make(
                id: "sensitive2",
                eventType: .selectiveShareCreated,
                surface: "trust_vault",
                protocolId: "p1",
                scopeKind: "selective_share",
                renderMode: .alias,
                manifestVersion: 1,
                payloadJson: "{\"expiresAt\":\"2026-03-20T00:00:00.000Z\"}",
                createdAt: "2026-03-04T00:00:00.000Z"
            )
        )

        return [
            PhaseTwoFixture(
                name: "one-protocol",
                bundle: makeSpecCompleteBundle(aliasModeEnabled: false),
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Weekly GLP",
                expectedProjectionTitle: "Weekly GLP",
                expectedCreatedDatasets: [("protocols", 1), ("protocolRevisions", 1)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["Revision rows were backfilled", "Trust Vault audit rows"]
            ),
            PhaseTwoFixture(
                name: "multiple-protocols",
                bundle: multipleProtocols,
                expectedProtocolCount: 2,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Weekly GLP",
                expectedProjectionTitle: "Peptide cycle",
                expectedCreatedDatasets: [("protocols", 2), ("protocolRevisions", 2)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["Revision rows were backfilled"]
            ),
            PhaseTwoFixture(
                name: "revision-history",
                bundle: revisionHistory,
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Weekly GLP",
                expectedProjectionTitle: "Weekly GLP",
                expectedCreatedDatasets: [("protocolRevisions", 2), ("protocolChangeAudits", 2)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["Revision rows were backfilled", "protocol change audit rows"]
            ),
            PhaseTwoFixture(
                name: "trust-vault-alias",
                bundle: trustVaultAlias,
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Evening plan",
                expectedProjectionTitle: "Evening plan",
                expectedCreatedDatasets: [("protocolAliases", 1), ("sensitiveActionAudits", 1)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["privacy control profile rows", "Trust Vault audit rows"]
            ),
            PhaseTwoFixture(
                name: "inventory-vials-sites",
                bundle: inventoryAndSites,
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Weekly GLP",
                expectedProjectionTitle: "Weekly GLP",
                expectedCreatedDatasets: [("vials", 1), ("sites", 1)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["Revision rows were backfilled"]
            ),
            PhaseTwoFixture(
                name: "selective-sharing-audits",
                bundle: auditHeavySharing,
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Evening plan",
                expectedProjectionTitle: "Evening plan",
                expectedCreatedDatasets: [("sensitiveActionAudits", 2), ("protocolChangeAudits", 1)],
                expectedWarningFragments: [],
                expectedBackfillFragments: [],
                unexpectedBackfillFragments: ["Trust Vault audit rows"]
            ),
        ]
    }
}

actor TestNotificationManager: NotificationManaging {
    private var status: AtlasNotificationAuthorizationStatus
    private let requestedStatus: AtlasNotificationAuthorizationStatus
    private var handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?
    private var pending: [String: AtlasReminderScheduleRequest]
    private var pendingMascot: [String: AtlasMascotNotificationRequest]
    private var canceled: [String]
    private var requestCount: Int

    init(
        currentStatus: AtlasNotificationAuthorizationStatus = .authorized,
        requestedStatus: AtlasNotificationAuthorizationStatus = .authorized
    ) {
        self.status = currentStatus
        self.requestedStatus = requestedStatus
        self.pending = [:]
        self.pendingMascot = [:]
        self.canceled = []
        self.requestCount = 0
    }

    func authorizationStatus() async -> AtlasNotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus {
        requestCount += 1
        status = requestedStatus
        return status
    }

    func configureReminderNotifications(
        handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?
    ) async throws {
        self.handler = handler
    }

    func scheduleReminder(_ request: AtlasReminderScheduleRequest) async throws -> String {
        let identifier = "test.\(request.protocolID).\(request.occurrenceID).\(pending.count)"
        pending[identifier] = request
        return identifier
    }

    func cancelReminder(identifier: String) async throws {
        pending.removeValue(forKey: identifier)
        canceled.append(identifier)
    }

    func scheduleMascotNotification(_ request: AtlasMascotNotificationRequest) async throws -> String {
        pendingMascot[request.identifier] = request
        return request.identifier
    }

    func pendingRequests() -> [AtlasReminderScheduleRequest] {
        pending.keys.sorted().compactMap { pending[$0] }
    }

    func pendingMascotNotifications() -> [AtlasMascotNotificationRequest] {
        pendingMascot.keys.sorted().compactMap { pendingMascot[$0] }
    }

    func pendingIdentifiers() -> [String] {
        pending.keys.sorted()
    }

    func canceledIdentifiers() -> [String] {
        canceled
    }

    func authorizationRequestsCount() -> Int {
        requestCount
    }

    func simulateResponse(_ response: AtlasReminderNotificationResponse) async {
        if let handler {
            await handler(response)
        }
    }
}

actor TestBiometricGate: BiometricGating {
    private let available: Bool
    private let granted: Bool
    private var calls: Int

    init(available: Bool = true, granted: Bool) {
        self.available = available
        self.granted = granted
        self.calls = 0
    }

    func isAvailable() async -> Bool {
        available
    }

    func authorize(reason: String) async -> Bool {
        _ = reason
        calls += 1
        return granted
    }

    func callCount() -> Int {
        calls
    }
}

final class TestCloudSyncManager: CloudSyncManaging, @unchecked Sendable {
    private var session: AtlasCloudSessionSnapshot?
    private var latestBundle: Data?
    private(set) var revokedRemoteIDs: [String]
    private let localDeviceID: String

    init(
        session: AtlasCloudSessionSnapshot? = nil,
        latestBundle: Data? = nil,
        localDeviceID: String = "test-device"
    ) {
        self.session = session
        self.latestBundle = latestBundle
        self.revokedRemoteIDs = []
        self.localDeviceID = localDeviceID
    }

    func isConfigured() -> Bool {
        true
    }

    func currentSession() async -> AtlasCloudSessionSnapshot? {
        session
    }

    func deviceIdentifier() -> String? {
        localDeviceID
    }

    func signUp(email: String, password: String) async throws -> AtlasCloudSessionSnapshot {
        _ = password
        let snapshot = AtlasCloudSessionSnapshot(email: email, userID: "test-user", deviceID: localDeviceID)
        session = snapshot
        return snapshot
    }

    func signIn(email: String, password: String) async throws -> AtlasCloudSessionSnapshot {
        _ = password
        let snapshot = AtlasCloudSessionSnapshot(email: email, userID: "test-user", deviceID: localDeviceID)
        session = snapshot
        return snapshot
    }

    func signIn(with provider: AtlasCloudIdentityProvider) async throws -> AtlasCloudSessionSnapshot {
        let snapshot: AtlasCloudSessionSnapshot
        switch provider {
        case .google:
            snapshot = AtlasCloudSessionSnapshot(email: "google@atlas.example", userID: "google-user", deviceID: localDeviceID)
        case .apple:
            snapshot = AtlasCloudSessionSnapshot(email: "apple@atlas.example", userID: "apple-user", deviceID: localDeviceID)
        }
        session = snapshot
        return snapshot
    }

    func signOut() async throws {
        session = nil
    }

    func uploadExportBundle(_ data: Data, generatedAt: Date, deviceID: String?) async throws -> AtlasCloudSessionSnapshot {
        _ = deviceID
        latestBundle = data
        let snapshot = AtlasCloudSessionSnapshot(
            email: session?.email ?? "test@atlas.local",
            userID: session?.userID ?? "test-user",
            deviceID: deviceID ?? localDeviceID,
            lastSyncAt: generatedAt,
            latestRemoteBackupAt: generatedAt,
            latestRemoteBackupDeviceID: deviceID ?? localDeviceID,
            latestRemoteBackupUpdatedAt: generatedAt
        )
        session = snapshot
        return snapshot
    }

    func downloadLatestExportBundle() async throws -> Data? {
        latestBundle
    }

    func createLiveReviewSession(
        title: String,
        request: AtlasReviewRequest,
        workspace: AtlasReviewWorkspace
    ) async throws -> AtlasLiveReviewSessionSnapshot {
        _ = title
        _ = request
        _ = workspace
        return AtlasLiveReviewSessionSnapshot(
            id: "review_test_remote",
            shareURL: URL(string: "https://atlas.example/live-review/review_test_remote")!,
            expiresAt: nil
        )
    }

    func revokeLiveReviewSession(id: String) async throws {
        revokedRemoteIDs.append(id)
    }

    func statusDescription() async -> String {
        if let session {
            return "Signed in as \(session.email)."
        }
        return "Cloud sync is ready for sign-in."
    }

    func latestUploadedBundle() -> Data? {
        latestBundle
    }
}

final class TestHealthKitManager: HealthKitManaging, @unchecked Sendable {
    private let available: Bool
    private let authorizationGranted: Bool
    private(set) var authorizationRequestCount: Int
    private(set) var disconnectCallCount: Int
    private(set) var savedWeights: [(value: Double, unit: AtlasWeightUnit, recordedAt: Date)]
    private(set) var weightSamples: [AtlasHealthWeightSample]
    private(set) var workouts: [AtlasHealthWorkoutSample]
    private(set) var nutritionSamples: [AtlasHealthNutritionSample]
    private(set) var metricSamples: [AtlasHealthMetricSample]
    private var workoutResponses: [[AtlasHealthWorkoutSample]]
    private var weightResponses: [[AtlasHealthWeightSample]]
    private var nutritionResponses: [[AtlasHealthNutritionSample]]
    private var metricResponses: [[AtlasHealthMetricSample]]
    private(set) var fetchWorkoutSinceRequests: [Date?]
    private(set) var fetchWeightSinceRequests: [Date?]
    private(set) var fetchNutritionSinceRequests: [Date?]
    private(set) var fetchMetricSinceRequests: [Date?]
    private(set) var connected: Bool

    init(
        available: Bool,
        authorizationGranted: Bool,
        initiallyConnected: Bool = false,
        weightSamples: [AtlasHealthWeightSample] = [],
        workouts: [AtlasHealthWorkoutSample] = [],
        nutritionSamples: [AtlasHealthNutritionSample] = [],
        metricSamples: [AtlasHealthMetricSample] = [],
        workoutResponses: [[AtlasHealthWorkoutSample]] = [],
        weightResponses: [[AtlasHealthWeightSample]] = [],
        nutritionResponses: [[AtlasHealthNutritionSample]] = [],
        metricResponses: [[AtlasHealthMetricSample]] = []
    ) {
        self.available = available
        self.authorizationGranted = authorizationGranted
        self.authorizationRequestCount = 0
        self.disconnectCallCount = 0
        self.savedWeights = []
        self.weightSamples = weightSamples
        self.workouts = workouts
        self.nutritionSamples = nutritionSamples
        self.metricSamples = metricSamples
        self.workoutResponses = workoutResponses
        self.weightResponses = weightResponses
        self.nutritionResponses = nutritionResponses
        self.metricResponses = metricResponses
        self.fetchWorkoutSinceRequests = []
        self.fetchWeightSinceRequests = []
        self.fetchNutritionSinceRequests = []
        self.fetchMetricSinceRequests = []
        self.connected = initiallyConnected
    }

    func isAvailable() -> Bool {
        available
    }

    func isConnected() async -> Bool {
        connected
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        connected = authorizationGranted
        return authorizationGranted
    }

    func disconnect() async {
        disconnectCallCount += 1
        connected = false
    }

    func fetchWeightSamples(since: Date?) async throws -> [AtlasHealthWeightSample] {
        fetchWeightSinceRequests.append(since)
        if weightResponses.isEmpty == false {
            return weightResponses.removeFirst()
        }
        guard let since else {
            return weightSamples
        }
        return weightSamples.filter { $0.recordedAt >= since }
    }

    func fetchWorkouts(since: Date?) async throws -> [AtlasHealthWorkoutSample] {
        fetchWorkoutSinceRequests.append(since)
        if workoutResponses.isEmpty == false {
            return workoutResponses.removeFirst()
        }
        guard let since else {
            return workouts
        }
        return workouts.filter { $0.startedAt >= since }
    }

    func fetchNutritionSamples(since: Date?) async throws -> [AtlasHealthNutritionSample] {
        fetchNutritionSinceRequests.append(since)
        if nutritionResponses.isEmpty == false {
            return nutritionResponses.removeFirst()
        }
        guard let since else {
            return nutritionSamples
        }
        return nutritionSamples.filter { $0.recordedAt >= since }
    }

    func fetchMetricSamples(since: Date?) async throws -> [AtlasHealthMetricSample] {
        fetchMetricSinceRequests.append(since)
        if metricResponses.isEmpty == false {
            return metricResponses.removeFirst()
        }
        guard let since else {
            return metricSamples
        }
        return metricSamples.filter { $0.recordedAt >= since }
    }

    func replaceWorkouts(_ workouts: [AtlasHealthWorkoutSample]) {
        self.workouts = workouts
    }

    func replaceWeightSamples(_ weightSamples: [AtlasHealthWeightSample]) {
        self.weightSamples = weightSamples
    }

    func replaceWorkoutResponses(_ workoutResponses: [[AtlasHealthWorkoutSample]]) {
        self.workoutResponses = workoutResponses
    }

    func replaceWeightResponses(_ weightResponses: [[AtlasHealthWeightSample]]) {
        self.weightResponses = weightResponses
    }

    func replaceNutritionSamples(_ nutritionSamples: [AtlasHealthNutritionSample]) {
        self.nutritionSamples = nutritionSamples
    }

    func replaceNutritionResponses(_ nutritionResponses: [[AtlasHealthNutritionSample]]) {
        self.nutritionResponses = nutritionResponses
    }

    func replaceMetricSamples(_ metricSamples: [AtlasHealthMetricSample]) {
        self.metricSamples = metricSamples
    }

    func replaceMetricResponses(_ metricResponses: [[AtlasHealthMetricSample]]) {
        self.metricResponses = metricResponses
    }

    func saveWeightSample(value: Double, unit: AtlasWeightUnit, recordedAt: Date) async throws {
        savedWeights.append((value, unit, recordedAt))
    }

    func connectionDescription() -> String {
        available ? "Apple Health can sync with Atlas." : "Apple Health is unavailable on this device."
    }
}

actor TestExternalCalendarManager: ExternalCalendarManaging {
    nonisolated let available: Bool
    private var currentStatus: AtlasCalendarAuthorizationStatus
    private let requestedStatus: AtlasCalendarAuthorizationStatus
    private let calendars: [AtlasExternalCalendarDescriptor]
    private var savedDraftStorage: [AtlasExternalCalendarEventDraft]
    private var deletedIdentifierStorage: [String]
    private var eventDraftsByIdentifier: [String: AtlasExternalCalendarEventDraft]
    private var nextIdentifier: Int

    init(
        available: Bool = true,
        currentStatus: AtlasCalendarAuthorizationStatus = .fullAccess,
        requestedStatus: AtlasCalendarAuthorizationStatus? = nil,
        calendars: [AtlasExternalCalendarDescriptor] = []
    ) {
        self.available = available
        self.currentStatus = currentStatus
        self.requestedStatus = requestedStatus ?? currentStatus
        self.calendars = calendars
        self.savedDraftStorage = []
        self.deletedIdentifierStorage = []
        self.eventDraftsByIdentifier = [:]
        self.nextIdentifier = 1
    }

    nonisolated func isAvailable() -> Bool {
        available
    }

    func authorizationStatus() async -> AtlasCalendarAuthorizationStatus {
        currentStatus
    }

    func requestFullAccess() async throws -> AtlasCalendarAuthorizationStatus {
        currentStatus = requestedStatus
        return currentStatus
    }

    func writableCalendars() async throws -> [AtlasExternalCalendarDescriptor] {
        calendars
    }

    func saveEvent(
        _ draft: AtlasExternalCalendarEventDraft,
        existingIdentifier: String?
    ) async throws -> AtlasExternalCalendarSavedEvent {
        let eventIdentifier: String
        if let existingIdentifier {
            eventIdentifier = existingIdentifier
        } else {
            eventIdentifier = "calendar-event-\(nextIdentifier)"
            nextIdentifier += 1
        }

        savedDraftStorage.append(draft)
        eventDraftsByIdentifier[eventIdentifier] = draft
        return AtlasExternalCalendarSavedEvent(eventIdentifier: eventIdentifier)
    }

    func deleteEvent(identifier: String) async throws {
        deletedIdentifierStorage.append(identifier)
        eventDraftsByIdentifier.removeValue(forKey: identifier)
    }

    func savedEvents() -> [AtlasExternalCalendarEventDraft] {
        savedDraftStorage
    }

    func deletedIdentifiers() -> [String] {
        deletedIdentifierStorage
    }
}

actor FailingReminderCoordinator: ReminderCoordinating {
    func authorizationStatus() async -> AtlasNotificationAuthorizationStatus {
        .authorized
    }

    func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus {
        .authorized
    }

    func configureReminderHandling(
        onActionApplied: (@Sendable () async -> Void)?
    ) async throws {
        _ = onActionApplied
    }

    func fetchReminderSettings() async throws -> AtlasReminderSettingsSnapshot {
        AtlasReminderSettingsSnapshot()
    }

    func updateReminderSettings(
        _ update: AtlasReminderPreferenceUpdate,
        referenceDate: Date
    ) async throws -> AtlasReminderSettingsSnapshot {
        _ = update
        _ = referenceDate
        return AtlasReminderSettingsSnapshot()
    }

    func syncReminders(referenceDate: Date) async throws {
        _ = referenceDate
        struct ReminderSyncFailure: LocalizedError {
            var errorDescription: String? { "Reminder sync failed" }
        }
        throw ReminderSyncFailure()
    }
}

private extension Optional {
    func unwrap() throws -> Wrapped {
        guard let self else {
            throw NSError(domain: "AtlasPhaseTwoTests", code: 0)
        }

        return self
    }
}

@MainActor
private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @MainActor () async throws -> T,
    _ message: String = "Expected error to be thrown.",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message, file: file, line: line)
    } catch {
    }
}

private struct PhaseTwoFixture {
    let name: String
    let bundle: AtlasExportBundle
    let expectedProtocolCount: Int
    let expectedHistoryCount: Int
    let expectsNextDue: Bool
    let expectedRenderedTitle: String?
    let expectedProjectionTitle: String?
    let expectedCreatedDatasets: [(String, Int)]
    let expectedWarningFragments: [String]
    let expectedBackfillFragments: [String]
    let unexpectedBackfillFragments: [String]
}

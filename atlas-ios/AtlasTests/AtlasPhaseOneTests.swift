import AtlasDomain
import AtlasFeatures
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
            prepared.dryRun.backfillNotes.contains(where: { $0.contains("Trust Vault profile rows") })
        )
    }

    func testCommitImportsProtocolsAndNativeShellReadsThem() async throws {
        let controller = try makeInMemoryController()
        let url = try writeBundleURL(makeSpecCompleteBundle(aliasModeEnabled: true))
        let prepared = try await controller.importExportBridge.prepareImport(at: url)

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)

        let model = await MainActor.run {
            AtlasAppModel(
                dependencies: AtlasAppDependencies(
                    featureFlags: AtlasFeatureFlags(),
                    notifications: TestNotificationManager(),
                    biometrics: AtlasBiometricGate(),
                    healthKit: AtlasHealthKitManager(),
                    importExport: controller.importExportBridge,
                    sharedProjectionWriter: controller.sharedProjectionWriter,
                    persistence: controller.container,
                    reminders: controller.reminderCoordinator,
                    privacyFormatter: AtlasPrivacyFormatter()
                )
            )
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

    func testImmutableHistoryRemainsSeparateFromNextDueProjection() async throws {
        let controller = try makeInMemoryController()
        let prepared = try await controller.importExportBridge.prepareImport(at: writeBundleURL(
            makeSpecCompleteBundle(aliasModeEnabled: false)
        ))

        _ = try await controller.importExportBridge.commitPreparedImport(prepared, mode: .replaceExisting)
        let history = try await controller.container.timeline.fetchHistory(limit: 10)
        let nextDue = try await controller.container.today.fetchNextDue()

        XCTAssertEqual(history.count, 1)
        XCTAssertNotNil(nextDue)
        XCTAssertNotEqual(history.first?.id, nextDue?.id)
        XCTAssertEqual(history.first?.protocolID, nextDue?.protocolID)
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
            let model = makeAppModel(controller: controller)
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
        XCTAssertEqual(originalDetail, unchangedDetail)

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

    func testGlpBranchRequiresGlpFields() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .glp)
        draft.glp.medication = nil

        await XCTAssertThrowsErrorAsync {
            try await controller.container.onboarding.completeOnboarding(
                draft,
                now: Date(timeIntervalSince1970: 1_773_950_600)
            )
        }
    }

    func testPeptideBranchRequiresPeptideFields() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .peptide)
        draft.peptide.selections = []

        await XCTAssertThrowsErrorAsync {
            try await controller.container.onboarding.completeOnboarding(
                draft,
                now: Date(timeIntervalSince1970: 1_773_950_700)
            )
        }
    }

    func testBothBranchRequiresBothTrackDetails() async throws {
        let controller = try makeInMemoryController()
        var draft = makeCompleteOnboardingDraft(accountMode: .guest, trackType: .both)
        draft.peptide.goal = nil

        await XCTAssertThrowsErrorAsync {
            try await controller.container.onboarding.completeOnboarding(
                draft,
                now: Date(timeIntervalSince1970: 1_773_950_800)
            )
        }
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
            "Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation."
        )
        XCTAssertTrue(snapshot.adherenceTrend.completedCount > 0)
        XCTAssertFalse(snapshot.amountInSystem.isEmpty)
        XCTAssertEqual(snapshot.amountInSystem.first?.canonicalProtocolTitle, "Insight protocol")
        XCTAssertEqual(snapshot.amountInSystem.first?.estimateLabel.contains("in the current schedule window"), true)
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

        let preview = try await controller.importExportBridge.previewSelectiveShare(
            AtlasSelectiveShareRequest(
                scopeKind: .last30DaysLogs,
                renderMode: .full
            ),
            now: now.addingTimeInterval(5)
        )
        let export = try await controller.importExportBridge.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: now.addingTimeInterval(5)
        )
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: export.fileURL)) as? [String: Any]
        )
        let snapshot = try XCTUnwrap(payload["snapshot"] as? [String: Any])

        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "customMetrics" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "metricValueLogs" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "weightLogs" && $0.rowCount == 1 }))
        XCTAssertTrue(preview.datasets.contains(where: { $0.dataset == "symptomLogs" && $0.rowCount == 1 }))
        XCTAssertEqual((snapshot["customMetrics"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["metricValueLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["weightLogs"] as? [[String: Any]])?.count, 1)
        XCTAssertEqual((snapshot["symptomLogs"] as? [[String: Any]])?.count, 1)
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
        let summaries = try await targetController.container.protocols.listProtocolSummaries()
        let nextDue = try await targetController.container.today.fetchNextDue()

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
        let history = try await controller.container.timeline.fetchHistory(limit: 10)
        let nextDue = try await controller.container.today.fetchNextDue()

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
        let controller = try makeInMemoryController()
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

    private func makeInMemoryController(
        notifications: any NotificationManaging = TestNotificationManager()
    ) throws -> AtlasPersistenceController {
        try AtlasPersistenceController.inMemory(
            featureFlags: AtlasFeatureFlagState(),
            privacyFormatter: AtlasPrivacyFormatter(),
            notifications: notifications
        )
    }

    @MainActor
    private func makeAppModel(
        controller: AtlasPersistenceController,
        notifications: any NotificationManaging = TestNotificationManager(),
        biometrics: any BiometricGating = AtlasBiometricGate()
    ) -> AtlasAppModel {
        AtlasAppModel(
            dependencies: AtlasAppDependencies(
                featureFlags: AtlasFeatureFlags(),
                notifications: notifications,
                biometrics: biometrics,
                healthKit: AtlasHealthKitManager(),
                importExport: controller.importExportBridge,
                sharedProjectionWriter: controller.sharedProjectionWriter,
                persistence: controller.container,
                reminders: controller.reminderCoordinator,
                privacyFormatter: AtlasPrivacyFormatter()
            )
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
            profile: AtlasOnboardingProfile(
                gender: "Other",
                age: 34,
                goalWeight: 165,
                height: 70,
                heightUnit: .ftIn,
                weight: 190,
                weightUnit: .lb
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
            healthConnectionPromptSeen: true
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
                expectedProjectionTitle: "Private protocol",
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
                expectedProjectionTitle: "Private protocol",
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
                expectedProjectionTitle: "Private protocol",
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
                unexpectedBackfillFragments: ["Trust Vault profile rows", "Trust Vault audit rows"]
            ),
            PhaseTwoFixture(
                name: "inventory-vials-sites",
                bundle: inventoryAndSites,
                expectedProtocolCount: 1,
                expectedHistoryCount: 1,
                expectsNextDue: true,
                expectedRenderedTitle: "Weekly GLP",
                expectedProjectionTitle: "Private protocol",
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
    private var canceled: [String]
    private var requestCount: Int

    init(
        currentStatus: AtlasNotificationAuthorizationStatus = .authorized,
        requestedStatus: AtlasNotificationAuthorizationStatus = .authorized
    ) {
        self.status = currentStatus
        self.requestedStatus = requestedStatus
        self.pending = [:]
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

    func pendingRequests() -> [AtlasReminderScheduleRequest] {
        pending.keys.sorted().compactMap { pending[$0] }
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
    private let granted: Bool
    private var calls: Int

    init(granted: Bool) {
        self.granted = granted
        self.calls = 0
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

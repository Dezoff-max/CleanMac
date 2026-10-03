import CleanMacCore
import SwiftUI

struct MainWindowView: View {
    @SceneStorage("CleanMac.selectedSection") private var selectedSectionID: String?
    @State private var selectedAreaIDs = CleanMacScanPreferences.selectedAreaIDs()
    @State private var scanItems: [CleanupScanItem] = []
    @State private var scanResults: [ScanResult] = []
    @State private var scanReport: CleanupScanReport?
    @State private var scanProgress: CleanupScanProgress?
    @State private var scanError: String?
    @State private var selectedResultIDs = Set<String>()
    @State private var cleanupHistory = CleanupHistoryStore().load()
    @State private var cleanupStatusMessage: String?
    @State private var cleanupProblemMessage: String?
    @State private var restoreStatusMessage: String?
    @State private var restoreProblemMessage: String?
    @State private var isScanning = false
    @State private var isCleaning = false
    @State private var isRestoring = false

    @AppStorage("CleanMac.safeModeEnabled") private var safeModeEnabled = true
    @AppStorage("CleanMac.confirmBeforeCleanup") private var confirmBeforeCleanup = true
    @AppStorage("CleanMac.showMenuBarStatus") private var showMenuBarStatus = true
    @AppStorage(CleanMacPreferenceKeys.scanInProgress) private var scanInProgress = false
    @AppStorage(CleanMacPreferenceKeys.fileOperationInProgress) private var fileOperationInProgress = false
    @AppStorage(CleanMacPreferenceKeys.requestedSection) private var requestedSectionID = ""

    private let minimumScanAnimationDuration: TimeInterval = 1.15
    private let cleanupHistoryStore = CleanupHistoryStore()

    private var selectedSection: CleanMacSection {
        CleanMacSection(rawValue: selectedSectionID ?? CleanMacSection.dashboard.rawValue) ?? .dashboard
    }

    private var isAnyScanInProgress: Bool {
        isScanning || scanInProgress
            || UserDefaults.standard.bool(forKey: CleanMacPreferenceKeys.scanInProgress)
    }

    private var isOperationBusy: Bool {
        isAnyScanInProgress || isFileMutationInProgress
    }

    private var isFileMutationInProgress: Bool {
        isCleaning || isRestoring || fileOperationInProgress
            || UserDefaults.standard.bool(forKey: CleanMacPreferenceKeys.fileOperationInProgress)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSectionID)
                .disabled(isFileMutationInProgress)
        } detail: {
            detailView
                .navigationTitle(selectedSection.title)
                .toolbar {
                    ToolbarItemGroup {
                        if selectedSection != .diskAnalysis,
                           selectedSection != .duplicates,
                           selectedSection != .systemMaintenance,
                           selectedSection != .shredder {
                            Button {
                                runScan()
                            } label: {
                                Label(isAnyScanInProgress ? L.t("button.scanning") : L.t("button.scan"), systemImage: "magnifyingglass")
                            }
                            .accessibilityLabel(isAnyScanInProgress ? L.t("button.scanning") : L.t("button.scan"))
                            .disabled(isOperationBusy || selectedAreaIDs.isEmpty)
                        }

                        Button {
                            guard !isFileMutationInProgress else { return }
                            selectedSectionID = CleanMacSection.settings.rawValue
                        } label: {
                            Label(L.t("section.settings"), systemImage: "gearshape")
                        }
                        .accessibilityLabel(L.t("section.settings"))
                        .disabled(isFileMutationInProgress)
                    }
                }
                .background(WindowAccessor { window in
                    MainWindowController.configure(window)
                })
        }
        .onChange(of: selectedAreaIDs) { _, newValue in
            CleanMacScanPreferences.storeSelectedAreaIDs(newValue)
        }
        .onChange(of: safeModeEnabled) { _, isEnabled in
            guard isEnabled else {
                return
            }

            restrictSelectionToSafeItems()
        }
        .task(id: requestedSectionID) {
            guard !requestedSectionID.isEmpty else {
                return
            }
            await Task.yield()
            applyRequestedSection(requestedSectionID)
        }
        .onChange(of: fileOperationInProgress) { _, isBusy in
            if !isBusy {
                applyRequestedSection(requestedSectionID)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView(
                report: scanReport,
                resultCount: scanResults.count,
                selectedAreaCount: selectedAreaIDs.count,
                selectedAreas: selectedAreas,
                isScanning: isAnyScanInProgress,
                isOperationBusy: isOperationBusy,
                scanError: scanError,
                onStartScan: runScan,
                onChooseAreas: {
                    guard !isFileMutationInProgress else { return }
                    selectedSectionID = CleanMacSection.scan.rawValue
                },
                onOpenSection: { section in
                    guard !isFileMutationInProgress else { return }
                    selectedSectionID = section.rawValue
                }
            )
        case .scan:
            ScanView(
                selectedAreaIDs: $selectedAreaIDs,
                isScanning: isAnyScanInProgress,
                isOperationBusy: isOperationBusy,
                scanProgress: scanProgress,
                onStartScan: runScan
            )
        case .results:
            ResultsView(
                results: scanResults,
                report: scanReport,
                scanError: scanError,
                safeModeEnabled: safeModeEnabled,
                selectedResultIDs: $selectedResultIDs,
                isCleaning: isCleaning,
                isRestoring: isRestoring,
                isOperationBusy: isOperationBusy,
                cleanupStatusMessage: cleanupStatusMessage,
                cleanupProblemMessage: cleanupProblemMessage,
                restoreStatusMessage: restoreStatusMessage,
                restoreProblemMessage: restoreProblemMessage,
                cleanupHistory: cleanupHistory,
                onConfirmCleanup: cleanupSelectedItems,
                onRestoreHistoryItem: restoreHistoryItem,
                onOpenPermissions: {
                    guard !isFileMutationInProgress else { return }
                    selectedSectionID = CleanMacSection.settings.rawValue
                }
            )
        case .diskAnalysis:
            DiskAnalysisView()
        case .systemMaintenance:
            SystemMaintenanceView()
        case .duplicates:
            DuplicateFinderView()
        case .shredder:
            ShredderView()
        case .applications:
            ApplicationsView()
        case .settings:
            SettingsView(
                safeModeEnabled: $safeModeEnabled,
                confirmBeforeCleanup: $confirmBeforeCleanup,
                showMenuBarStatus: $showMenuBarStatus
            )
        }
    }

    private var selectedCategories: [CleanupCategory] {
        CleanMacCatalog.cleanupAreas
            .filter { selectedAreaIDs.contains($0.id) }
            .map(\.category)
    }

    private func applyRequestedSection(_ rawValue: String) {
        guard !rawValue.isEmpty, !isFileMutationInProgress else {
            return
        }
        defer { requestedSectionID = "" }
        guard CleanMacSection(rawValue: rawValue) != nil else {
            return
        }
        selectedSectionID = rawValue
    }

    private var selectedAreas: [CleanupArea] {
        CleanMacCatalog.cleanupAreas.filter { selectedAreaIDs.contains($0.id) }
    }

    private func runScan() {
        guard !isOperationBusy else {
            return
        }

        let categories = selectedCategories
        guard !categories.isEmpty else {
            return
        }

        isScanning = true
        scanInProgress = true
        scanProgress = CleanupScanProgress(
            phase: .preparing,
            currentCategory: nil,
            currentPath: nil,
            completedCategoryCount: 0,
            totalCategoryCount: categories.count,
            currentCategoryItemCount: 0,
            scannedItemCount: 0,
            totalSizeBytes: 0,
            currentCategoryProgress: 0
        )
        scanError = nil
        cleanupStatusMessage = nil
        cleanupProblemMessage = nil
        restoreStatusMessage = nil
        restoreProblemMessage = nil
        selectedSectionID = CleanMacSection.scan.rawValue
        let scanStartedAt = Date()

        Task {
            let progressChannel = AsyncStream.makeStream(
                of: CleanupScanProgress.self,
                bufferingPolicy: .bufferingNewest(1)
            )
            let scanTask = Task.detached(priority: .userInitiated) {
                let report = CleanupScanner().scan(categories: categories) { progress in
                    progressChannel.continuation.yield(progress)
                }
                progressChannel.continuation.finish()
                return report
            }

            for await progress in progressChannel.stream {
                scanProgress = progress
            }

            let report = await scanTask.value

            let elapsed = Date().timeIntervalSince(scanStartedAt)
            if elapsed < minimumScanAnimationDuration {
                let remaining = minimumScanAnimationDuration - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            scanReport = report
            scanItems = report.items
            scanResults = report.items.map(ScanResult.init)
            CleanMacScanPreferences.storeLastScan(report, source: .manual)
            selectedResultIDs = Set(report.items.filter { $0.risk == .safe }.map(\.id))
            if selectedSection == .scan {
                selectedSectionID = CleanMacSection.results.rawValue
            }
            isScanning = false
            scanInProgress = false
            scanProgress = nil

            if report.issues.isEmpty {
                scanError = nil
            } else {
                scanError = L.f("scan.issue.count", report.issues.count)
            }
        }
    }

    private func cleanupSelectedItems() {
        guard !isOperationBusy else {
            return
        }

        if safeModeEnabled {
            restrictSelectionToSafeItems()
        }

        let selectedItems = scanItems.filter {
            selectedResultIDs.contains($0.id) && (!safeModeEnabled || $0.risk == .safe)
        }
        guard !selectedItems.isEmpty else {
            cleanupProblemMessage = L.t("cleanup.noneSelected")
            return
        }

        isCleaning = true
        fileOperationInProgress = true
        cleanupStatusMessage = nil
        cleanupProblemMessage = nil
        restoreStatusMessage = nil
        restoreProblemMessage = nil

        Task {
            defer { fileOperationInProgress = false }
            let report = await Task.detached(priority: .userInitiated) {
                let plan = CleanupPlanner().plan(for: selectedItems)
                return CleanupExecutor().execute(plan: plan)
            }.value

            let movedIDs = Set(report.movedItems.map(\.id))
            scanItems.removeAll { movedIDs.contains($0.id) }
            scanResults.removeAll { movedIDs.contains($0.id) }
            selectedResultIDs.subtract(movedIDs)
            refreshRemainingScanReport()
            isCleaning = false

            var historySaveFailed = false
            if !report.movedItems.isEmpty {
                let historyItems = report.movedItems.map {
                    CleanupHistoryRecord(movedItem: $0, movedAt: report.completedAt)
                }
                historySaveFailed = !persistCleanupHistoryChanges(historyItems)
                if historySaveFailed {
                    cleanupHistory.insert(contentsOf: historyItems, at: 0)
                    cleanupHistory = Array(
                        cleanupHistory.prefix(CleanupHistoryStore.defaultMaximumRecordCount)
                    )
                }
                cleanupStatusMessage = L.f(
                    "cleanup.success",
                    report.movedItems.count,
                    CleanMacFormatters.bytes(report.totalMovedBytes)
                )
            }

            var problemMessages: [String] = []
            if report.hasProblems {
                problemMessages.append(L.f(
                    "cleanup.problems",
                    report.failedItems.count,
                    report.rejectedItems.count
                ))
            }
            if historySaveFailed {
                problemMessages.append(L.t("history.persistence.failed"))
            }
            cleanupProblemMessage = problemMessages.isEmpty ? nil : problemMessages.joined(separator: " ")
        }
    }

    private func restrictSelectionToSafeItems() {
        let safeItemIDs = Set(scanItems.filter { $0.risk == .safe }.map(\.id))
        selectedResultIDs.formIntersection(safeItemIDs)
    }

    private func refreshRemainingScanReport() {
        guard let report = scanReport else { return }

        let summaries = report.summaries.map { summary in
            let remainingItems = scanItems.filter { $0.category == summary.category }
            return CleanupCategorySummary(
                category: summary.category,
                scannedPath: summary.scannedPath,
                itemCount: remainingItems.count,
                totalSizeBytes: remainingItems.reduce(0) { $0 + $1.sizeBytes },
                isAvailable: summary.isAvailable
            )
        }
        scanReport = CleanupScanReport(
            scannedAt: report.scannedAt,
            durationSeconds: report.durationSeconds,
            items: scanItems,
            summaries: summaries,
            issues: report.issues
        )
    }

    private func restoreHistoryItem(_ historyID: UUID) {
        guard !isOperationBusy else {
            return
        }
        guard let historyIndex = cleanupHistory.firstIndex(where: { $0.id == historyID }) else {
            restoreProblemMessage = L.t("restore.missingHistory")
            return
        }
        guard cleanupHistory[historyIndex].status != .restored else {
            restoreProblemMessage = L.t("restore.alreadyRestored")
            return
        }

        isRestoring = true
        fileOperationInProgress = true
        restoreStatusMessage = nil
        restoreProblemMessage = nil
        let historyRecord = cleanupHistory[historyIndex]

        Task {
            defer { fileOperationInProgress = false }
            let report = await Task.detached(priority: .userInitiated) {
                CleanupRestorer().restore(historyRecords: [historyRecord])
            }.value

            isRestoring = false

            if let restoredItem = report.restoredItems.first,
               let updatedIndex = cleanupHistory.firstIndex(where: { $0.id == historyID }) {
                cleanupHistory[updatedIndex].markRestored(at: report.completedAt)
                let updatedRecord = cleanupHistory[updatedIndex]
                if !persistCleanupHistoryChanges([updatedRecord]) {
                    restoreProblemMessage = L.t("history.persistence.failed")
                }
                restoreStatusMessage = L.f("restore.success", restoredItem.movedItem.item.scanItem.displayName)
            }

            if let failedItem = report.failedItems.first,
               let updatedIndex = cleanupHistory.firstIndex(where: { $0.id == historyID }) {
                cleanupHistory[updatedIndex].markRestoreFailed(reason: failedItem.reason)
                let updatedRecord = cleanupHistory[updatedIndex]
                let messages = [
                    restoreMessage(for: failedItem),
                    persistCleanupHistoryChanges([updatedRecord]) ? nil : L.t("history.persistence.failed")
                ].compactMap { $0 }
                restoreProblemMessage = messages.joined(separator: " ")
            }
        }
    }

    private func persistCleanupHistoryChanges(_ records: [CleanupHistoryRecord]) -> Bool {
        do {
            cleanupHistory = try cleanupHistoryStore.upserting(records)
            return true
        } catch {
            return false
        }
    }

    private func restoreMessage(for failedItem: CleanupRestoreFailedItem) -> String {
        switch failedItem.reason {
        case .missingTrashPath:
            L.t("restore.failure.missingTrashPath")
        case .missingTrashItem:
            L.t("restore.failure.missingTrashItem")
        case .outsideTrash:
            L.t("restore.failure.outsideTrash")
        case .symbolicLink:
            L.t("restore.failure.symbolicLink")
        case .outsideAllowedRoot:
            L.t("restore.failure.outsideAllowedRoot")
        case .destinationExists:
            L.t("restore.failure.destinationExists")
        case .missingOriginalParent:
            L.t("restore.failure.missingOriginalParent")
        case .moveFailed:
            failedItem.message
        }
    }
}

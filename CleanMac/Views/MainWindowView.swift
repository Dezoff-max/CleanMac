import CleanMacCore
import SwiftUI

struct MainWindowView: View {
    @SceneStorage("CleanMac.selectedSection") private var selectedSectionID: String?
    @State private var selectedAreaIDs = Set(
        CleanMacCatalog.cleanupAreas
            .filter(\.isDefaultSelected)
            .map(\.id)
    )
    @State private var scanItems: [CleanupScanItem] = []
    @State private var scanResults: [ScanResult] = []
    @State private var scanReport: CleanupScanReport?
    @State private var scanError: String?
    @State private var selectedResultIDs = Set<String>()
    @State private var cleanupHistory: [CleanupHistoryItem] = []
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

    private let minimumScanAnimationDuration: TimeInterval = 1.15

    private var selectedSection: CleanMacSection {
        CleanMacSection(rawValue: selectedSectionID ?? CleanMacSection.dashboard.rawValue) ?? .dashboard
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSectionID)
        } detail: {
            detailView
                .navigationTitle(selectedSection.title)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            runScan()
                        } label: {
                            Label(isScanning ? L.t("button.scanning") : L.t("button.scan"), systemImage: "magnifyingglass")
                        }
                        .accessibilityLabel(isScanning ? L.t("button.scanning") : L.t("button.scan"))
                        .disabled(isScanning || selectedAreaIDs.isEmpty)

                        Button {
                            selectedSectionID = CleanMacSection.settings.rawValue
                        } label: {
                            Label(L.t("section.settings"), systemImage: "gearshape")
                        }
                        .accessibilityLabel(L.t("section.settings"))
                    }
                }
                .background(WindowAccessor { window in
                    MainWindowController.configure(window)
                })
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
                isScanning: isScanning,
                scanError: scanError,
                onStartScan: runScan,
                onChooseAreas: {
                    selectedSectionID = CleanMacSection.scan.rawValue
                }
            )
        case .scan:
            ScanView(
                selectedAreaIDs: $selectedAreaIDs,
                isScanning: isScanning,
                onStartScan: runScan
            )
        case .results:
            ResultsView(
                results: scanResults,
                report: scanReport,
                scanError: scanError,
                selectedResultIDs: $selectedResultIDs,
                isCleaning: isCleaning,
                isRestoring: isRestoring,
                cleanupStatusMessage: cleanupStatusMessage,
                cleanupProblemMessage: cleanupProblemMessage,
                restoreStatusMessage: restoreStatusMessage,
                restoreProblemMessage: restoreProblemMessage,
                cleanupHistory: cleanupHistory,
                onConfirmCleanup: cleanupSelectedItems,
                onRestoreHistoryItem: restoreHistoryItem
            )
        case .permissions:
            PermissionsView()
        case .settings:
            SettingsView(
                safeModeEnabled: $safeModeEnabled,
                confirmBeforeCleanup: $confirmBeforeCleanup,
                showMenuBarStatus: $showMenuBarStatus
            )
        }
    }

    private var selectedCategories: [CleanupCategory] {
        selectedAreaIDs.compactMap { CleanupCategory(rawValue: $0) }
    }

    private var selectedAreas: [CleanupArea] {
        CleanMacCatalog.cleanupAreas.filter { selectedAreaIDs.contains($0.id) }
    }

    private func runScan() {
        guard !isScanning else {
            return
        }

        let categories = selectedCategories
        guard !categories.isEmpty else {
            return
        }

        isScanning = true
        scanError = nil
        cleanupStatusMessage = nil
        cleanupProblemMessage = nil
        restoreStatusMessage = nil
        restoreProblemMessage = nil
        selectedSectionID = CleanMacSection.scan.rawValue
        let scanStartedAt = Date()

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                CleanupScanner().scan(categories: categories)
            }.value

            let elapsed = Date().timeIntervalSince(scanStartedAt)
            if elapsed < minimumScanAnimationDuration {
                let remaining = minimumScanAnimationDuration - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            scanReport = report
            scanItems = report.items
            scanResults = report.items.map(ScanResult.init)
            selectedResultIDs = Set(report.items.filter { $0.risk == .safe }.map(\.id))
            selectedSectionID = CleanMacSection.results.rawValue
            isScanning = false

            if report.issues.isEmpty {
                scanError = nil
            } else {
                scanError = L.f("scan.issue.count", report.issues.count)
            }
        }
    }

    private func cleanupSelectedItems() {
        guard !isCleaning else {
            return
        }

        let selectedItems = scanItems.filter { selectedResultIDs.contains($0.id) }
        guard !selectedItems.isEmpty else {
            cleanupProblemMessage = L.t("cleanup.noneSelected")
            return
        }

        isCleaning = true
        cleanupStatusMessage = nil
        cleanupProblemMessage = nil
        restoreStatusMessage = nil
        restoreProblemMessage = nil

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                let plan = CleanupPlanner().plan(for: selectedItems)
                return CleanupExecutor().execute(plan: plan)
            }.value

            let movedIDs = Set(report.movedItems.map(\.id))
            scanItems.removeAll { movedIDs.contains($0.id) }
            scanResults.removeAll { movedIDs.contains($0.id) }
            selectedResultIDs.subtract(movedIDs)
            isCleaning = false

            if !report.movedItems.isEmpty {
                let historyItems = report.movedItems.map {
                    CleanupHistoryItem(movedItem: $0, movedAt: report.completedAt)
                }
                cleanupHistory.insert(contentsOf: historyItems, at: 0)
                cleanupStatusMessage = L.f(
                    "cleanup.success",
                    report.movedItems.count,
                    CleanMacFormatters.bytes(report.totalMovedBytes)
                )
            }

            if report.hasProblems {
                cleanupProblemMessage = L.f(
                    "cleanup.problems",
                    report.failedItems.count,
                    report.rejectedItems.count
                )
            }
        }
    }

    private func restoreHistoryItem(_ historyID: String) {
        guard !isRestoring else {
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
        restoreStatusMessage = nil
        restoreProblemMessage = nil
        let movedItem = cleanupHistory[historyIndex].movedItem

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                CleanupRestorer().restore(movedItems: [movedItem])
            }.value

            isRestoring = false

            if let restoredItem = report.restoredItems.first,
               let updatedIndex = cleanupHistory.firstIndex(where: { $0.id == historyID }) {
                cleanupHistory[updatedIndex].status = .restored
                cleanupHistory[updatedIndex].restoredAt = report.completedAt
                cleanupHistory[updatedIndex].restoredPath = restoredItem.restoredPath
                cleanupHistory[updatedIndex].message = nil
                restoreStatusMessage = L.f("restore.success", restoredItem.movedItem.item.scanItem.displayName)
            }

            if let failedItem = report.failedItems.first,
               let updatedIndex = cleanupHistory.firstIndex(where: { $0.id == historyID }) {
                cleanupHistory[updatedIndex].status = .restoreFailed
                cleanupHistory[updatedIndex].message = restoreMessage(for: failedItem)
                restoreProblemMessage = cleanupHistory[updatedIndex].message
            }
        }
    }

    private func restoreMessage(for failedItem: CleanupRestoreFailedItem) -> String {
        switch failedItem.reason {
        case .missingTrashPath:
            L.t("restore.failure.missingTrashPath")
        case .missingTrashItem:
            L.t("restore.failure.missingTrashItem")
        case .destinationExists:
            L.t("restore.failure.destinationExists")
        case .missingOriginalParent:
            L.t("restore.failure.missingOriginalParent")
        case .moveFailed:
            failedItem.message
        }
    }
}

import CleanMacCore
import SwiftUI

struct MainWindowView: View {
    @SceneStorage("CleanMac.selectedSection") private var selectedSectionID: String?
    @State private var selectedAreaIDs = Set(
        CleanMacCatalog.cleanupAreas
            .filter(\.isDefaultSelected)
            .map(\.id)
    )
    @State private var scanResults: [ScanResult] = []
    @State private var scanReport: CleanupScanReport?
    @State private var scanError: String?
    @State private var isScanning = false

    @AppStorage("CleanMac.safeModeEnabled") private var safeModeEnabled = true
    @AppStorage("CleanMac.confirmBeforeCleanup") private var confirmBeforeCleanup = true
    @AppStorage("CleanMac.showMenuBarStatus") private var showMenuBarStatus = true

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
                scanError: scanError
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
        selectedSectionID = CleanMacSection.scan.rawValue

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                CleanupScanner().scan(categories: categories)
            }.value

            scanReport = report
            scanResults = report.items.map(ScanResult.init)
            selectedSectionID = CleanMacSection.results.rawValue
            isScanning = false

            if report.issues.isEmpty {
                scanError = nil
            } else {
                scanError = L.f("scan.issue.count", report.issues.count)
            }
        }
    }
}

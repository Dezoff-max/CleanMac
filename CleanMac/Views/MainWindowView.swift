import SwiftUI

struct MainWindowView: View {
    @SceneStorage("CleanMac.selectedSection") private var selectedSectionID: String?
    @State private var selectedAreaIDs = Set(
        CleanMacCatalog.cleanupAreas
            .filter(\.isDefaultSelected)
            .map(\.id)
    )
    @State private var scanResults: [ScanResult] = []
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
                            runPreviewScan()
                        } label: {
                            Label(isScanning ? "Scanning" : "Scan", systemImage: "magnifyingglass")
                        }
                        .disabled(isScanning || selectedAreaIDs.isEmpty)

                        Button {
                            selectedSectionID = CleanMacSection.settings.rawValue
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView(
                resultCount: scanResults.count,
                selectedAreaCount: selectedAreaIDs.count,
                isScanning: isScanning,
                onStartScan: runPreviewScan
            )
        case .scan:
            ScanView(
                selectedAreaIDs: $selectedAreaIDs,
                isScanning: isScanning,
                onStartScan: runPreviewScan
            )
        case .results:
            ResultsView(results: scanResults)
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

    private func runPreviewScan() {
        isScanning = true
        selectedSectionID = CleanMacSection.scan.rawValue

        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            let results = CleanMacCatalog.previewResults(for: selectedAreaIDs)
            await MainActor.run {
                scanResults = results
                selectedSectionID = CleanMacSection.results.rawValue
                isScanning = false
            }
        }
    }
}

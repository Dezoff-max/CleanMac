import AppKit
import CleanMacCore
import SwiftUI

struct ApplicationsView: View {
    @State private var applications: [InstalledApplication] = []
    @State private var selectedApplicationID: String?
    @State private var selectedLeftoverIDs = Set<String>()
    @State private var searchText = ""
    @State private var scanIssueCount = 0
    @State private var isScanning = false
    @State private var isRemoving = false
    @State private var isShowingConfirmation = false
    @State private var statusMessage: String?
    @State private var problemMessage: String?

    private var selectedApplication: InstalledApplication? {
        applications.first { $0.id == selectedApplicationID }
    }

    private var filteredApplications: [InstalledApplication] {
        guard !searchText.isEmpty else {
            return applications
        }
        return applications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedLeftovers: [ApplicationLeftover] {
        selectedApplication?.leftovers.filter { selectedLeftoverIDs.contains($0.id) } ?? []
    }

    private var selectedRemovalSize: Int64 {
        guard let selectedApplication else {
            return 0
        }
        return selectedApplication.sizeBytes + selectedLeftovers.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(
                    title: L.t("applications.title"),
                    subtitle: L.t("applications.subtitle"),
                    systemImage: "app.badge.checkmark"
                )

                StatusBanner(
                    title: L.t("applications.safety.title"),
                    message: L.t("applications.safety.message"),
                    systemImage: "checkmark.shield",
                    tint: .blue
                )

                if let statusMessage {
                    StatusBanner(
                        title: L.t("applications.status.title"),
                        message: statusMessage,
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }

                if let problemMessage {
                    StatusBanner(
                        title: L.t("applications.problem.title"),
                        message: problemMessage,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                }

                HStack(alignment: .top, spacing: 16) {
                    applicationList
                        .frame(width: 330)

                    applicationDetail
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .task {
            await refreshApplications()
        }
        .alert(
            L.t("applications.confirm.title"),
            isPresented: $isShowingConfirmation,
            presenting: selectedApplication
        ) { application in
            Button(L.t("button.cancel"), role: .cancel) {}
            Button(L.t("applications.remove.button"), role: .destructive) {
                remove(application)
            }
        } message: { application in
            Text(L.f(
                "applications.confirm.message",
                application.name,
                selectedLeftovers.count,
                CleanMacFormatters.bytes(selectedRemovalSize)
            ))
        }
    }

    private var applicationList: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t("applications.list.title"))
                            .font(.headline)
                        Text(L.f("applications.list.count", applications.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await refreshApplications() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help(L.t("applications.refresh"))
                    .disabled(isScanning || isRemoving)
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L.t("applications.search"), text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 7))

                Divider()

                if isScanning {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L.t("applications.scanning"))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else if filteredApplications.isEmpty {
                    ContentUnavailableView(
                        L.t("applications.empty.title"),
                        systemImage: "app.dashed",
                        description: Text(L.t("applications.empty.message"))
                    )
                    .frame(minHeight: 180)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredApplications) { application in
                            Button {
                                select(application)
                            } label: {
                                applicationRow(application)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if scanIssueCount > 0 {
                    Label(
                        L.f("applications.scanIssues", scanIssueCount),
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
        }
    }

    private func applicationRow(_ application: InstalledApplication) -> some View {
        let isSelected = application.id == selectedApplicationID
        return HStack(spacing: 10) {
            Image(systemName: "app.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(application.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(CleanMacFormatters.bytes(application.sizeBytes))
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
            }

            Spacer(minLength: 4)

            if !application.leftovers.isEmpty {
                Text("+\(application.leftovers.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
            }
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(
            isSelected ? Color.accentColor : Color.primary.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var applicationDetail: some View {
        if let application = selectedApplication {
            InfoPanel {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(application.name)
                                .font(.title2.bold())
                            Text(application.bundleIdentifier)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        Text(CleanMacFormatters.bytes(application.sizeBytes))
                            .font(.headline)
                    }

                    LabeledContent(L.t("applications.location")) {
                        Text(application.location == .user
                             ? L.t("applications.location.user")
                             : L.t("applications.location.shared"))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.t("results.detail.path"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(application.path)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }

                    HStack {
                        Button(L.t("button.reveal")) {
                            NSWorkspace.shared.activateFileViewerSelecting([
                                URL(fileURLWithPath: application.path)
                            ])
                        }

                        Spacer()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.t("applications.leftovers.title"))
                            .font(.headline)
                        Text(L.t("applications.leftovers.message"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if application.leftovers.isEmpty {
                        Label(
                            L.t("applications.leftovers.empty"),
                            systemImage: "checkmark.circle"
                        )
                        .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(application.leftovers) { leftover in
                                Toggle(isOn: leftoverBinding(for: leftover.id)) {
                                    HStack(spacing: 10) {
                                        Image(systemName: leftover.kind.systemImage)
                                            .foregroundStyle(.tint)
                                            .frame(width: 22)
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(leftover.kind.title)
                                                    .font(.subheadline.weight(.medium))
                                                Spacer()
                                                Text(CleanMacFormatters.bytes(leftover.sizeBytes))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text(leftover.path)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .toggleStyle(.checkbox)
                                .disabled(isRemoving)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L.f(
                                "applications.removal.summary",
                                selectedLeftovers.count,
                                CleanMacFormatters.bytes(selectedRemovalSize)
                            ))
                            .font(.subheadline.weight(.medium))
                            Text(L.t("applications.removal.trash"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            isShowingConfirmation = true
                        } label: {
                            if isRemoving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label(L.t("applications.remove.button"), systemImage: "trash")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(isRemoving || isScanning)
                    }
                }
            }
        } else {
            InfoPanel {
                ContentUnavailableView(
                    L.t("applications.detail.empty.title"),
                    systemImage: "cursorarrow.click",
                    description: Text(L.t("applications.detail.empty.message"))
                )
                .frame(maxWidth: .infinity, minHeight: 360)
            }
        }
    }

    private func leftoverBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selectedLeftoverIDs.contains(id) },
            set: { isSelected in
                if isSelected {
                    selectedLeftoverIDs.insert(id)
                } else {
                    selectedLeftoverIDs.remove(id)
                }
            }
        )
    }

    private func select(_ application: InstalledApplication) {
        selectedApplicationID = application.id
        selectedLeftoverIDs = []
        statusMessage = nil
        problemMessage = nil
    }

    @MainActor
    private func refreshApplications() async {
        guard !isScanning, !isRemoving else {
            return
        }
        isScanning = true
        problemMessage = nil

        let excludedBundleIdentifiers = Set([Bundle.main.bundleIdentifier].compactMap { $0 })
        let excludedApplicationPaths = Set([Bundle.main.bundleURL.path])
        let report = await Task.detached(priority: .userInitiated) {
            InstalledApplicationScanner(
                excludedBundleIdentifiers: excludedBundleIdentifiers,
                excludedApplicationPaths: excludedApplicationPaths
            ).scan()
        }.value

        applications = report.applications
        scanIssueCount = report.issues.count
        if let selectedApplicationID,
           !applications.contains(where: { $0.id == selectedApplicationID }) {
            self.selectedApplicationID = nil
            selectedLeftoverIDs = []
        }
        isScanning = false
    }

    private func remove(_ application: InstalledApplication) {
        guard !isRemoving else {
            return
        }
        isRemoving = true
        statusMessage = nil
        problemMessage = nil

        let selectedIDs = selectedLeftoverIDs
        let excludedBundleIdentifiers = Set([Bundle.main.bundleIdentifier].compactMap { $0 })
        let excludedApplicationPaths = Set([Bundle.main.bundleURL.path])

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                let plan = ApplicationRemovalPlanner(
                    excludedBundleIdentifiers: excludedBundleIdentifiers,
                    excludedApplicationPaths: excludedApplicationPaths
                ).plan(for: application, selectedLeftoverIDs: selectedIDs)
                return ApplicationRemovalExecutor().execute(plan: plan)
            }.value

            isRemoving = false
            if report.applicationMoved {
                statusMessage = L.f(
                    "applications.removal.success",
                    application.name,
                    report.movedItems.count - 1,
                    CleanMacFormatters.bytes(report.totalMovedBytes)
                )
                selectedApplicationID = nil
                selectedLeftoverIDs = []
                applications.removeAll { $0.id == application.id }
            }

            if report.hasProblems {
                problemMessage = L.f(
                    "applications.removal.problems",
                    report.failedItems.count,
                    report.rejectedItems.count
                )
            }
        }
    }
}

private extension ApplicationLeftoverKind {
    var title: String {
        switch self {
        case .cache: L.t("applications.leftover.cache")
        case .preferences: L.t("applications.leftover.preferences")
        case .savedApplicationState: L.t("applications.leftover.savedState")
        case .logs: L.t("applications.leftover.logs")
        }
    }

    var systemImage: String {
        switch self {
        case .cache: "shippingbox"
        case .preferences: "slider.horizontal.3"
        case .savedApplicationState: "macwindow"
        case .logs: "doc.text"
        }
    }
}

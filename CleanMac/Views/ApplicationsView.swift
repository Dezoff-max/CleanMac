import AppKit
import CleanMacCore
import SwiftUI

struct ApplicationsView: View {
    @State private var applications: [InstalledApplication] = []
    @State private var selectedApplicationID: String?
    @State private var selectedApplicationIDs = Set<String>()
    @State private var selectedLeftoverIDsByApplication: [String: Set<String>] = [:]
    @State private var searchText = ""
    @State private var scanIssueCount = 0
    @State private var isScanning = false
    @State private var isRemoving = false
    @State private var isShowingConfirmation = false
    @State private var removalMode: ApplicationRemovalMode = .moveToTrash
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

    private var selectedApplications: [InstalledApplication] {
        applications.filter { selectedApplicationIDs.contains($0.id) }
    }

    private var selectedLeftoverCount: Int {
        selectedApplications.reduce(0) { count, application in
            count + application.leftovers.filter { effectiveLeftoverIDs(for: application).contains($0.id) }.count
        }
    }

    private var selectedRemovalSize: Int64 {
        selectedApplications.reduce(0) { total, application in
            let selectedLeftoverIDs = effectiveLeftoverIDs(for: application)
            let leftoverSize = application.leftovers
                .filter { selectedLeftoverIDs.contains($0.id) }
                .reduce(0) { $0 + $1.sizeBytes }
            return total + application.sizeBytes + leftoverSize
        }
    }

    private var removalButtonTitle: String {
        switch removalMode {
        case .moveToTrash:
            selectedApplications.count == 1
                ? L.t("applications.remove.button")
                : L.f("applications.remove.multiple", selectedApplications.count)
        case .deletePermanently:
            selectedApplications.count == 1
                ? L.t("applications.remove.permanent.button")
                : L.f("applications.remove.permanent.multiple", selectedApplications.count)
        }
    }

    private var confirmationTitle: String {
        removalMode == .deletePermanently
            ? L.t("applications.confirm.permanent.title")
            : L.t("applications.confirm.title")
    }

    private var confirmationMessageKey: String {
        removalMode == .deletePermanently
            ? "applications.confirm.permanent.message"
            : "applications.confirm.message"
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
        .alert(confirmationTitle, isPresented: $isShowingConfirmation) {
            Button(L.t("button.cancel"), role: .cancel) {}
            Button(removalButtonTitle, role: .destructive) {
                removeSelectedApplications()
            }
        } message: {
            Text(L.f(
                confirmationMessageKey,
                selectedApplications.count,
                selectedLeftoverCount,
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

                if !selectedApplications.isEmpty {
                    Label(
                        L.f(
                            "applications.selected.summary",
                            selectedApplications.count,
                            CleanMacFormatters.bytes(selectedRemovalSize)
                        ),
                        systemImage: "checkmark.square.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
                }

                Divider()

                if isScanning {
                    VStack(spacing: 12) {
                        ModernScanProgressIndicator(
                            systemImage: "app.badge",
                            accessibilityLabel: L.t("applications.scanning")
                        )
                        Text(L.t("applications.scanning"))
                            .font(.subheadline.weight(.medium))
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
                            applicationRow(application)
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
            Toggle("", isOn: applicationSelectionBinding(for: application))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .tint(isSelected ? .white : .accentColor)
                .help(L.t("applications.selection.help"))

            Button {
                showDetails(for: application)
            } label: {
                HStack(spacing: 10) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(
            isSelected ? Color.accentColor : Color.primary.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .disabled(isRemoving)
    }

    private func showDetails(for application: InstalledApplication) {
        selectedApplicationID = application.id
        statusMessage = nil
        problemMessage = nil
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.t("applications.mode.title"))
                            .font(.headline)

                        Picker(L.t("applications.mode.title"), selection: $removalMode) {
                            ForEach(ApplicationRemovalMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(isRemoving)

                        Label(removalMode.detail, systemImage: removalMode.systemImage)
                            .font(.caption)
                            .foregroundStyle(removalMode == .deletePermanently ? .red : .secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.t("applications.leftovers.title"))
                            .font(.headline)
                        Text(removalMode == .deletePermanently
                             ? L.t("applications.leftovers.permanent.message")
                             : L.t("applications.leftovers.message"))
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
                                Toggle(isOn: leftoverBinding(
                                    for: leftover.id,
                                    applicationID: application.id
                                )) {
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
                                .disabled(isRemoving || removalMode == .deletePermanently)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L.f(
                                "applications.removal.summary",
                                selectedApplications.count,
                                selectedLeftoverCount,
                                CleanMacFormatters.bytes(selectedRemovalSize)
                            ))
                            .font(.subheadline.weight(.medium))
                            Text(removalMode == .deletePermanently
                                 ? L.t("applications.removal.permanent")
                                 : L.t("applications.removal.trash"))
                                .font(.caption)
                                .foregroundStyle(removalMode == .deletePermanently ? .red : .secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            isShowingConfirmation = true
                        } label: {
                            if isRemoving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label(removalButtonTitle, systemImage: removalMode.systemImage)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(isRemoving || isScanning || selectedApplications.isEmpty)
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

    private func applicationSelectionBinding(for application: InstalledApplication) -> Binding<Bool> {
        Binding(
            get: { selectedApplicationIDs.contains(application.id) },
            set: { isSelected in
                selectedApplicationID = application.id
                statusMessage = nil
                problemMessage = nil

                if isSelected {
                    selectedApplicationIDs.insert(application.id)
                } else {
                    selectedApplicationIDs.remove(application.id)
                    selectedLeftoverIDsByApplication.removeValue(forKey: application.id)
                }
            }
        )
    }

    private func leftoverBinding(for id: String, applicationID: String) -> Binding<Bool> {
        Binding(
            get: {
                if removalMode == .deletePermanently {
                    return true
                }
                return selectedLeftoverIDsByApplication[applicationID, default: []].contains(id)
            },
            set: { isSelected in
                guard removalMode == .moveToTrash else {
                    return
                }
                if isSelected {
                    selectedApplicationIDs.insert(applicationID)
                    selectedLeftoverIDsByApplication[applicationID, default: []].insert(id)
                } else {
                    selectedLeftoverIDsByApplication[applicationID, default: []].remove(id)
                }
            }
        )
    }

    private func effectiveLeftoverIDs(for application: InstalledApplication) -> Set<String> {
        switch removalMode {
        case .moveToTrash:
            selectedLeftoverIDsByApplication[application.id] ?? []
        case .deletePermanently:
            Set(application.leftovers.map(\.id))
        }
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
        let validApplicationIDs = Set(applications.map(\.id))
        selectedApplicationIDs.formIntersection(validApplicationIDs)
        selectedLeftoverIDsByApplication = selectedLeftoverIDsByApplication.reduce(into: [:]) {
            result, entry in
            guard let application = applications.first(where: { $0.id == entry.key }),
                  selectedApplicationIDs.contains(entry.key) else {
                return
            }
            let validLeftoverIDs = Set(application.leftovers.map(\.id))
            result[entry.key] = entry.value.intersection(validLeftoverIDs)
        }
        if let selectedApplicationID,
           !applications.contains(where: { $0.id == selectedApplicationID }) {
            self.selectedApplicationID = nil
        }
        isScanning = false
    }

    private func removeSelectedApplications() {
        let removalApplications = selectedApplications
        guard !isRemoving, !removalApplications.isEmpty else {
            return
        }
        isRemoving = true
        statusMessage = nil
        problemMessage = nil

        let removalMode = removalMode
        let selectedLeftoverIDs = Dictionary(
            uniqueKeysWithValues: removalApplications.map { application in
                (application.id, effectiveLeftoverIDs(for: application))
            }
        )
        let excludedBundleIdentifiers = Set([Bundle.main.bundleIdentifier].compactMap { $0 })
        let excludedApplicationPaths = Set([Bundle.main.bundleURL.path])

        Task {
            let reports = await Task.detached(priority: .userInitiated) {
                removalApplications.map { application in
                    let plan = ApplicationRemovalPlanner(
                        excludedBundleIdentifiers: excludedBundleIdentifiers,
                        excludedApplicationPaths: excludedApplicationPaths
                    ).plan(
                        for: application,
                        selectedLeftoverIDs: selectedLeftoverIDs[application.id] ?? []
                    )
                    return (application.id, ApplicationRemovalExecutor().execute(plan: plan, mode: removalMode))
                }
            }.value

            isRemoving = false
            let movedApplicationIDs = Set(reports.compactMap { applicationID, report in
                report.applicationMoved ? applicationID : nil
            })
            let movedLeftoverCount = reports.reduce(0) { count, entry in
                count + entry.1.movedItems.count - (entry.1.applicationMoved ? 1 : 0)
            }
            let totalMovedBytes = reports.reduce(0) { $0 + $1.1.totalMovedBytes }
            let failedCount = reports.reduce(0) { $0 + $1.1.failedItems.count }
            let rejectedCount = reports.reduce(0) { $0 + $1.1.rejectedItems.count }

            if !movedApplicationIDs.isEmpty {
                statusMessage = L.f(
                    removalMode == .deletePermanently
                        ? "applications.removal.permanent.success"
                        : "applications.removal.success",
                    movedApplicationIDs.count,
                    movedLeftoverCount,
                    CleanMacFormatters.bytes(totalMovedBytes)
                )
                applications.removeAll { movedApplicationIDs.contains($0.id) }
                selectedApplicationIDs.subtract(movedApplicationIDs)
                for applicationID in movedApplicationIDs {
                    selectedLeftoverIDsByApplication.removeValue(forKey: applicationID)
                }
                if let selectedApplicationID, movedApplicationIDs.contains(selectedApplicationID) {
                    self.selectedApplicationID = selectedApplications.first?.id
                }
            }

            if failedCount > 0 || rejectedCount > 0 {
                problemMessage = L.f(
                    "applications.removal.problems",
                    failedCount,
                    rejectedCount
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
        case .applicationSupport: L.t("applications.leftover.applicationSupport")
        case .container: L.t("applications.leftover.container")
        case .groupContainer: L.t("applications.leftover.groupContainer")
        case .httpStorage: L.t("applications.leftover.httpStorage")
        case .webKit: L.t("applications.leftover.webKit")
        case .cookies: L.t("applications.leftover.cookies")
        case .applicationScripts: L.t("applications.leftover.applicationScripts")
        case .launchAgent: L.t("applications.leftover.launchAgent")
        }
    }

    var systemImage: String {
        switch self {
        case .cache: "shippingbox"
        case .preferences: "slider.horizontal.3"
        case .savedApplicationState: "macwindow"
        case .logs: "doc.text"
        case .applicationSupport: "folder.badge.gearshape"
        case .container: "shippingbox.circle"
        case .groupContainer: "square.stack.3d.up"
        case .httpStorage: "network"
        case .webKit: "safari"
        case .cookies: "circle.hexagongrid"
        case .applicationScripts: "applescript"
        case .launchAgent: "gearshape.arrow.triangle.2.circlepath"
        }
    }
}

private extension ApplicationRemovalMode {
    var title: String {
        switch self {
        case .moveToTrash: L.t("applications.mode.trash")
        case .deletePermanently: L.t("applications.mode.permanent")
        }
    }

    var detail: String {
        switch self {
        case .moveToTrash: L.t("applications.mode.trash.detail")
        case .deletePermanently: L.t("applications.mode.permanent.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .moveToTrash: "trash"
        case .deletePermanently: "trash.slash"
        }
    }
}

import CleanMacCore
import SwiftUI

struct DuplicateFinderView: View {
    @State private var source: DuplicateSearchSource = .downloads
    @State private var customFolderURL: URL?
    @State private var includeLargeFiles = false
    @State private var scanReport: DuplicateScanReport?
    @State private var groups: [DuplicateGroup] = []
    @State private var progress: DuplicateScanProgress?
    @State private var selectedCopyIDs: Set<String> = []
    @State private var expandedGroupIDs: Set<String> = []
    @State private var statusMessage: String?
    @State private var problemMessage: String?
    @State private var isScanning = false
    @State private var isCleaning = false
    @State private var isChoosingCustomFolder = false
    @State private var showingCleanupConfirmation = false
    @State private var activeScanID: UUID?
    @State private var workerTask: Task<DuplicateScanReport, Error>?
    @State private var coordinatorTask: Task<Void, Never>?

    private var sourceURL: URL? {
        switch source {
        case .home:
            FileManager.default.homeDirectoryForCurrentUser
        case .downloads:
            FileManager.default.homeDirectoryForCurrentUser
                .appending(path: "Downloads", directoryHint: .isDirectory)
        case .custom:
            customFolderURL
        }
    }

    private var selectedCopies: [DuplicateFile] {
        groups.flatMap(\.copies).filter { selectedCopyIDs.contains($0.id) }
    }

    private var selectedBytes: Int64 {
        selectedCopies.reduce(0) { total, file in
            let result = total.addingReportingOverflow(file.sizeBytes)
            return result.overflow ? Int64.max : result.partialValue
        }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: L.t("duplicates.title"),
                    subtitle: L.t("duplicates.subtitle"),
                    systemImage: "square.on.square"
                )

                StatusBanner(
                    title: L.t("duplicates.safety.title"),
                    message: L.t("duplicates.safety.message"),
                    systemImage: "lock.shield",
                    tint: .green
                )

                sourceControls

                if isScanning {
                    scanningPanel
                }

                if let statusMessage {
                    StatusBanner(
                        title: L.t("duplicates.status.title"),
                        message: statusMessage,
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }

                if let problemMessage {
                    StatusBanner(
                        title: L.t("duplicates.problem.title"),
                        message: problemMessage,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                }

                if let scanReport {
                    summaryPanel(scanReport)
                    deferredLargePanel(scanReport)

                    if !groups.isEmpty {
                        selectionPanel
                        duplicateGroups
                    } else if !isScanning {
                        emptyResults
                    }
                } else if !isScanning {
                    initialState
                }
            }
        }
        .onChange(of: source) { _, _ in
            resetResults()
        }
        .onChange(of: includeLargeFiles) { _, _ in
            resetResults()
        }
        .onDisappear {
            cancelScan(showMessage: false)
        }
        .alert(
            L.t("duplicates.cleanup.confirm.title"),
            isPresented: $showingCleanupConfirmation
        ) {
            Button(L.t("button.cancel"), role: .cancel) {}
            Button(L.t("duplicates.cleanup.confirm.action"), role: .destructive) {
                cleanSelectedCopies()
            }
        } message: {
            Text(L.f(
                "duplicates.cleanup.confirm.message",
                selectedCopies.count,
                CleanMacFormatters.bytes(selectedBytes)
            ))
        }
    }

    private var sourceControls: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        sourcePicker
                        Spacer(minLength: 8)
                        sourceActions
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sourcePicker
                        sourceActions
                    }
                }

                Divider()

                Toggle(isOn: $includeLargeFiles) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L.t("duplicates.slowMode.title"))
                            .font(.subheadline.weight(.semibold))
                        Text(L.t("duplicates.slowMode.detail"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .disabled(isScanning || isCleaning)

                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(sourceURL?.path ?? L.t("duplicates.source.custom.placeholder"))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var sourcePicker: some View {
        Picker(L.t("duplicates.source.title"), selection: sourceSelection) {
            ForEach(DuplicateSearchSource.allCases) { source in
                Text(source.title).tag(source)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 480)
        .disabled(isScanning || isCleaning || isChoosingCustomFolder)
    }

    private var sourceActions: some View {
        HStack(spacing: 10) {
            if source == .custom {
                Button {
                    presentCustomFolderPicker()
                } label: {
                    Label(L.t("duplicates.source.choose"), systemImage: "folder.badge.plus")
                }
                .disabled(isScanning || isCleaning || isChoosingCustomFolder)
            }

            if isScanning {
                Button(role: .cancel) {
                    cancelScan(showMessage: true)
                } label: {
                    Label(L.t("button.cancel"), systemImage: "xmark.circle")
                }
            } else {
                Button {
                    startScan()
                } label: {
                    Label(L.t("duplicates.scan.button"), systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(sourceURL == nil || isCleaning || isChoosingCustomFolder)
            }
        }
    }

    private var scanningPanel: some View {
        InfoPanel {
            HStack(spacing: 14) {
                DiskAnalysisProgressIndicator()

                VStack(alignment: .leading, spacing: 5) {
                    Text(progress?.phase.localizedTitle ?? L.t("duplicates.phase.enumerating"))
                        .font(.headline)
                    Text(L.f(
                        "duplicates.scanning.summary",
                        progress?.discoveredFileCount ?? 0,
                        progress?.candidateFileCount ?? 0,
                        progress?.hashedFileCount ?? 0
                    ))
                    .foregroundStyle(.secondary)

                    if let currentPath = progress?.currentPath {
                        Text(currentPath)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()
            }
        }
    }

    private func summaryPanel(_ report: DuplicateScanReport) -> some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    summaryMetric(L.t("duplicates.summary.groups"), "\(groups.count)", "square.stack.3d.up")
                    Divider().frame(height: 34)
                    summaryMetric(L.t("duplicates.summary.copies"), "\(groups.reduce(0) { $0 + $1.copies.count })", "doc.on.doc")
                    Divider().frame(height: 34)
                    summaryMetric(L.t("duplicates.summary.space"), CleanMacFormatters.bytes(reclaimableBytes), "externaldrive.badge.minus")
                    Divider().frame(height: 34)
                    summaryMetric(L.t("duplicates.summary.files"), "\(report.discoveredFileCount)", "magnifyingglass")
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryMetric(L.t("duplicates.summary.groups"), "\(groups.count)", "square.stack.3d.up")
                    summaryMetric(L.t("duplicates.summary.copies"), "\(groups.reduce(0) { $0 + $1.copies.count })", "doc.on.doc")
                    summaryMetric(L.t("duplicates.summary.space"), CleanMacFormatters.bytes(reclaimableBytes), "externaldrive.badge.minus")
                    summaryMetric(L.t("duplicates.summary.files"), "\(report.discoveredFileCount)", "magnifyingglass")
                }
            }
        }
    }

    private var reclaimableBytes: Int64 {
        groups.reduce(0) { total, group in
            let result = total.addingReportingOverflow(group.reclaimableBytes)
            return result.overflow ? Int64.max : result.partialValue
        }
    }

    private func summaryMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func deferredLargePanel(_ report: DuplicateScanReport) -> some View {
        if !report.deferredLargeCandidates.isEmpty {
            InfoPanel {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "tortoise.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L.t("duplicates.deferred.title"))
                                .font(.headline)
                            Text(L.f(
                                "duplicates.deferred.detail",
                                report.deferredLargeCandidates.count,
                                CleanMacFormatters.bytes(deferredLargeBytes(report))
                            ))
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(L.t("duplicates.deferred.enable")) {
                            includeLargeFiles = true
                        }
                    }

                    ForEach(Array(report.deferredLargeCandidates.prefix(5))) { file in
                        compactFileRow(file)
                    }

                    if report.deferredLargeCandidates.count > 5 {
                        Text(L.f("duplicates.deferred.more", report.deferredLargeCandidates.count - 5))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func deferredLargeBytes(_ report: DuplicateScanReport) -> Int64 {
        report.deferredLargeCandidates.reduce(0) { total, file in
            let result = total.addingReportingOverflow(file.sizeBytes)
            return result.overflow ? Int64.max : result.partialValue
        }
    }

    private func compactFileRow(_ file: DuplicateFile) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(CleanMacFormatters.bytes(file.sizeBytes))
                .font(.caption.weight(.semibold))
        }
    }

    private var selectionPanel: some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    selectionSummary
                    Spacer()
                    selectionActions
                }

                VStack(alignment: .leading, spacing: 12) {
                    selectionSummary
                    selectionActions
                }
            }
        }
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L.f(
                "duplicates.selection.summary",
                selectedCopies.count,
                CleanMacFormatters.bytes(selectedBytes)
            ))
            .font(.headline)
            Text(L.t("duplicates.selection.detail"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var selectionActions: some View {
        HStack(spacing: 10) {
            Button(L.t("button.clearSelection")) {
                selectedCopyIDs.removeAll()
            }
            .disabled(selectedCopyIDs.isEmpty || isCleaning)

            Button(role: .destructive) {
                showingCleanupConfirmation = true
            } label: {
                Label(
                    isCleaning ? L.t("button.cleaning") : L.t("duplicates.cleanup.button"),
                    systemImage: "trash"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCopyIDs.isEmpty || isCleaning || isScanning)
        }
    }

    private var duplicateGroups: some View {
        VStack(spacing: 10) {
            ForEach(groups) { group in
                DuplicateGroupPanel(
                    group: group,
                    isExpanded: expandedGroupIDs.contains(group.id),
                    selectedCopyIDs: $selectedCopyIDs,
                    onToggleExpanded: { toggleExpanded(group.id) }
                )
            }
        }
    }

    private var initialState: some View {
        InfoPanel {
            ContentUnavailableView(
                L.t("duplicates.empty.initial.title"),
                systemImage: "square.on.square",
                description: Text(L.t("duplicates.empty.initial.message"))
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        }
    }

    private var emptyResults: some View {
        InfoPanel {
            ContentUnavailableView(
                L.t("duplicates.empty.results.title"),
                systemImage: "checkmark.circle",
                description: Text(L.t("duplicates.empty.results.message"))
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }

    private var sourceSelection: Binding<DuplicateSearchSource> {
        Binding(
            get: { source },
            set: { newSource in
                guard newSource != source else { return }
                if newSource == .custom, customFolderURL == nil {
                    presentCustomFolderPicker()
                } else {
                    source = newSource
                }
            }
        )
    }

    private func presentCustomFolderPicker() {
        guard !isScanning, !isCleaning, !isChoosingCustomFolder else { return }
        isChoosingCustomFolder = true

        Task { @MainActor in
            await Task.yield()
            let selectedURL = DuplicateWorkspaceService.chooseFolder()
            isChoosingCustomFolder = false
            guard let selectedURL else { return }

            let wasCustomSource = source == .custom
            customFolderURL = selectedURL
            source = .custom
            if wasCustomSource {
                resetResults()
            }
        }
    }

    private func startScan() {
        guard let rootURL = sourceURL, !isScanning, !isCleaning else {
            return
        }

        cancelScan(showMessage: false)
        let scanID = UUID()
        activeScanID = scanID
        isScanning = true
        scanReport = nil
        groups = []
        selectedCopyIDs = []
        expandedGroupIDs = []
        statusMessage = nil
        problemMessage = nil
        progress = DuplicateScanProgress(
            phase: .enumerating,
            currentPath: rootURL.path,
            discoveredFileCount: 0,
            candidateFileCount: 0,
            hashedFileCount: 0
        )

        let mode: DuplicateScanMode = includeLargeFiles ? .includeLargeFiles : .standard
        let progressChannel = AsyncStream.makeStream(
            of: DuplicateScanProgress.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let worker = Task.detached(priority: .utility) {
            defer { progressChannel.continuation.finish() }
            return try await DuplicateFinder().scan(
                root: rootURL,
                options: DuplicateScanOptions(mode: mode, maxConcurrentHashes: 2),
                progress: { progressChannel.continuation.yield($0) }
            )
        }
        workerTask = worker

        coordinatorTask = Task {
            for await event in progressChannel.stream {
                guard activeScanID == scanID, !Task.isCancelled else { return }
                progress = event
            }

            do {
                let completedReport = try await worker.value
                guard activeScanID == scanID, !Task.isCancelled else { return }

                scanReport = completedReport
                groups = completedReport.groups
                selectedCopyIDs = []
                expandedGroupIDs = []
                statusMessage = L.f(
                    "duplicates.status.complete",
                    completedReport.groups.count,
                    completedReport.copyCount,
                    CleanMacFormatters.bytes(completedReport.reclaimableBytes)
                )
                problemMessage = completedReport.issues.isEmpty
                    ? nil
                    : L.f("duplicates.problem.issues", completedReport.issues.count)
                finishScan(scanID: scanID)
            } catch is CancellationError {
                guard activeScanID == scanID else { return }
                finishScan(scanID: scanID)
            } catch let error as DuplicateFinderError {
                guard activeScanID == scanID else { return }
                problemMessage = error.localizedDuplicateMessage
                finishScan(scanID: scanID)
            } catch {
                guard activeScanID == scanID else { return }
                problemMessage = L.f("duplicates.problem.generic", error.localizedDescription)
                finishScan(scanID: scanID)
            }
        }
    }

    private func cancelScan(showMessage: Bool) {
        guard isScanning || workerTask != nil || coordinatorTask != nil else {
            return
        }
        activeScanID = nil
        workerTask?.cancel()
        coordinatorTask?.cancel()
        workerTask = nil
        coordinatorTask = nil
        isScanning = false
        progress = nil
        if showMessage {
            statusMessage = L.t("duplicates.status.cancelled")
        }
    }

    private func finishScan(scanID: UUID) {
        guard activeScanID == scanID else {
            return
        }
        activeScanID = nil
        workerTask = nil
        coordinatorTask = nil
        isScanning = false
        progress = nil
    }

    private func resetResults() {
        cancelScan(showMessage: false)
        scanReport = nil
        groups = []
        selectedCopyIDs = []
        expandedGroupIDs = []
        statusMessage = nil
        problemMessage = nil
    }

    private func toggleExpanded(_ groupID: String) {
        withAnimation(.easeInOut(duration: 0.16)) {
            if expandedGroupIDs.contains(groupID) {
                expandedGroupIDs.remove(groupID)
            } else {
                expandedGroupIDs.insert(groupID)
            }
        }
    }

    private func cleanSelectedCopies() {
        guard let rootURL = sourceURL, !selectedCopyIDs.isEmpty, !isCleaning else {
            return
        }
        isCleaning = true
        statusMessage = nil
        problemMessage = nil
        let groupSnapshot = groups
        let selectionSnapshot = selectedCopyIDs

        Task {
            let cleanupReport = await Task.detached(priority: .userInitiated) {
                let plan = DuplicateCleanupPlanner(root: rootURL).plan(
                    groups: groupSnapshot,
                    selectedCopyIDs: selectionSnapshot
                )
                return DuplicateCleanupExecutor().execute(plan: plan)
            }.value

            let movedIDs = Set(cleanupReport.movedItems.map(\.id))
            let movedBytes = cleanupReport.movedItems.reduce(Int64(0)) { total, item in
                let result = total.addingReportingOverflow(item.item.copy.sizeBytes)
                return result.overflow ? Int64.max : result.partialValue
            }
            groups = groups.compactMap { group in
                let remainingCopies = group.copies.filter { !movedIDs.contains($0.id) }
                guard !remainingCopies.isEmpty else { return nil }
                return DuplicateGroup(
                    fullHash: group.fullHash,
                    original: group.original,
                    copies: remainingCopies
                )
            }
            selectedCopyIDs.subtract(movedIDs)
            isCleaning = false

            if !cleanupReport.movedItems.isEmpty {
                statusMessage = L.f(
                    "duplicates.cleanup.success",
                    cleanupReport.movedItems.count,
                    CleanMacFormatters.bytes(movedBytes)
                )
            }
            let problemCount = cleanupReport.failedItems.count + cleanupReport.rejectedItems.count
            if problemCount > 0 {
                problemMessage = L.f(
                    "duplicates.cleanup.problems",
                    cleanupReport.failedItems.count,
                    cleanupReport.rejectedItems.count
                )
            }
        }
    }
}

private enum DuplicateSearchSource: String, CaseIterable, Identifiable {
    case home
    case downloads
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: L.t("duplicates.source.home")
        case .downloads: L.t("duplicates.source.downloads")
        case .custom: L.t("duplicates.source.custom")
        }
    }
}

private extension DuplicateScanPhase {
    var localizedTitle: String {
        switch self {
        case .enumerating: L.t("duplicates.phase.enumerating")
        case .groupingBySize: L.t("duplicates.phase.grouping")
        case .partialHashing: L.t("duplicates.phase.partial")
        case .fullHashing: L.t("duplicates.phase.full")
        case .finalizing: L.t("duplicates.phase.finalizing")
        case .completed: L.t("duplicates.phase.completed")
        }
    }
}

private extension DuplicateFinderError {
    var localizedDuplicateMessage: String {
        switch self {
        case .rootIsUnavailable: L.t("duplicates.problem.unavailable")
        case .rootIsNotDirectory: L.t("duplicates.problem.notDirectory")
        }
    }
}

private struct DuplicateGroupPanel: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    @Binding var selectedCopyIDs: Set<String>
    let onToggleExpanded: () -> Void

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: onToggleExpanded) {
                    HStack(spacing: 10) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.original.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(L.f(
                                "duplicates.group.summary",
                                group.copies.count + 1,
                                CleanMacFormatters.bytes(group.reclaimableBytes)
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(CleanMacFormatters.bytes(group.original.sizeBytes))
                            .font(.subheadline.weight(.semibold))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                    DuplicateFileRow(file: group.original, role: .original, isSelected: .constant(false))

                    ForEach(group.copies) { copy in
                        DuplicateFileRow(
                            file: copy,
                            role: .copy,
                            isSelected: Binding(
                                get: { selectedCopyIDs.contains(copy.id) },
                                set: { selected in
                                    if selected {
                                        selectedCopyIDs.insert(copy.id)
                                    } else {
                                        selectedCopyIDs.remove(copy.id)
                                    }
                                }
                            )
                        )
                    }
                }
            }
        }
    }
}

private struct DuplicateFileRow: View {
    enum Role {
        case original
        case copy
    }

    let file: DuplicateFile
    let role: Role
    @Binding var isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            if role == .copy {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.green)
                    .frame(width: 16)
            }

            Image(systemName: role == .original ? "doc.badge.checkmark" : "doc.on.doc")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(file.name)
                        .lineLimit(1)
                    Text(role == .original ? L.t("duplicates.role.original") : L.t("duplicates.role.copy"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(role == .original ? .green : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
                Text(file.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(CleanMacFormatters.bytes(file.sizeBytes))
                .font(.caption.weight(.semibold))

            Button {
                Task { await DuplicateWorkspaceService.reveal(file) }
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help(L.t("disk.action.finder"))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

import CleanMacCore
import SwiftUI

struct DiskAnalysisView: View {
    @State private var source: DiskAnalysisSource = .home
    @State private var customFolderURL: URL?
    @State private var mode: DiskAnalysisMode = .map
    @State private var threshold: LargeFileThreshold = .megabytes100
    @State private var sort: LargeFileSort = .size
    @State private var report: DiskAnalysisReport?
    @State private var progress: DiskAnalysisProgress?
    @State private var navigationStack: [DiskAnalysisNode] = []
    @State private var selectedFileID: String?
    @State private var statusMessage: String?
    @State private var problemMessage: String?
    @State private var isScanning = false
    @State private var isChoosingCustomFolder = false
    @State private var activeScanID: UUID?
    @State private var workerTask: Task<DiskAnalysisReport, Error>?
    @State private var coordinatorTask: Task<Void, Never>?

    private var sourceURL: URL? {
        switch source {
        case .wholeDisk:
            URL(fileURLWithPath: "/", isDirectory: true)
        case .home:
            FileManager.default.homeDirectoryForCurrentUser
        case .downloads:
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads", directoryHint: .isDirectory)
        case .custom:
            customFolderURL
        }
    }

    private var currentNode: DiskAnalysisNode? {
        navigationStack.last ?? report?.root
    }

    private var visibleLargeFiles: [DiskAnalysisFile] {
        guard let report else {
            return []
        }

        let filtered = report.largeFiles.filter { $0.sizeBytes >= threshold.bytes }
        switch sort {
        case .size:
            return filtered.sorted {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.sizeBytes > $1.sizeBytes
            }
        case .modified:
            return filtered.sorted {
                let leftDate = $0.modifiedAt ?? .distantPast
                let rightDate = $1.modifiedAt ?? .distantPast
                if leftDate == rightDate {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return leftDate > rightDate
            }
        case .type:
            return filtered.sorted {
                if $0.fileType == $1.fileType {
                    if $0.sizeBytes == $1.sizeBytes {
                        return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                    return $0.sizeBytes > $1.sizeBytes
                }
                return $0.fileType.title.localizedStandardCompare($1.fileType.title) == .orderedAscending
            }
        }
    }

    private var selectedFile: DiskAnalysisFile? {
        guard let selectedFileID else {
            return nil
        }
        return report?.largeFiles.first { $0.id == selectedFileID }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: L.t("disk.title"),
                    subtitle: L.t("disk.subtitle"),
                    systemImage: "chart.pie.fill"
                )

                StatusBanner(
                    title: L.t("disk.safety.title"),
                    message: L.t("disk.safety.message"),
                    systemImage: "eye",
                    tint: .blue
                )

                sourceControls

                if isScanning {
                    scanningPanel
                }

                if let statusMessage {
                    StatusBanner(
                        title: L.t("disk.status.title"),
                        message: statusMessage,
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }

                if let problemMessage {
                    StatusBanner(
                        title: L.t("disk.problem.title"),
                        message: problemMessage,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                }

                if let report {
                    analysisSummary(report)
                    modePicker

                    switch mode {
                    case .map:
                        mapContent
                    case .largeFiles:
                        largeFilesContent
                    }
                } else if !isScanning {
                    emptyState
                }
            }
        }
        .onChange(of: source) { _, _ in
            resetResults()
        }
        .onChange(of: threshold) { _, _ in
            keepOnlyVisibleSelection()
        }
        .onDisappear {
            cancelScan(showMessage: false)
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

                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(sourceURL?.path ?? L.t("disk.source.custom.placeholder"))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var sourcePicker: some View {
        Picker(L.t("disk.source.title"), selection: sourceSelection) {
            ForEach(DiskAnalysisSource.allCases) { source in
                Text(source.title).tag(source)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 560)
        .disabled(isScanning || isChoosingCustomFolder)
    }

    private var sourceActions: some View {
        HStack(spacing: 10) {
            if source == .custom {
                Button {
                    presentCustomFolderPicker()
                } label: {
                    Label(L.t("disk.source.choose"), systemImage: "folder.badge.plus")
                }
                .disabled(isScanning || isChoosingCustomFolder)
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
                    Label(L.t("disk.scan.button"), systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(sourceURL == nil || isChoosingCustomFolder)
            }
        }
    }

    private var scanningPanel: some View {
        InfoPanel {
            HStack(spacing: 14) {
                ModernScanProgressIndicator(
                    systemImage: "chart.pie.fill",
                    accessibilityLabel: L.t("disk.scanning.title")
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(L.t("disk.scanning.title"))
                        .font(.headline)

                    Text(L.f(
                        "disk.scanning.summary",
                        progress?.visitedItemCount ?? 0,
                        CleanMacFormatters.bytes(progress?.measuredSizeBytes ?? 0),
                        progress?.largeFileCount ?? 0
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

    private func analysisSummary(_ report: DiskAnalysisReport) -> some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    summaryMetric(L.t("disk.summary.measured"), CleanMacFormatters.bytes(report.root.sizeBytes), "internaldrive")
                    Divider().frame(height: 34)
                    summaryMetric(L.t("disk.summary.items"), "\(report.visitedItemCount)", "doc.on.doc")
                    Divider().frame(height: 34)
                    summaryMetric(L.t("disk.summary.largeFiles"), "\(report.largeFiles.count)", "arrow.up.right.square")
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryMetric(L.t("disk.summary.measured"), CleanMacFormatters.bytes(report.root.sizeBytes), "internaldrive")
                    summaryMetric(L.t("disk.summary.items"), "\(report.visitedItemCount)", "doc.on.doc")
                    summaryMetric(L.t("disk.summary.largeFiles"), "\(report.largeFiles.count)", "arrow.up.right.square")
                }
            }
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

    private var modePicker: some View {
        Picker(L.t("disk.mode.title"), selection: $mode) {
            ForEach(DiskAnalysisMode.allCases) { mode in
                Label(mode.title, systemImage: mode.systemImage).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 430)
    }

    @ViewBuilder
    private var mapContent: some View {
        if let currentNode {
            InfoPanel {
                VStack(alignment: .leading, spacing: 14) {
                    mapBreadcrumbs

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            DiskSunburstView(node: currentNode, nodeTitle: displayName(for:), onOpenNode: openMapNode)
                                .frame(minWidth: 430, minHeight: 430)

                            mapLegend(for: currentNode)
                                .frame(width: 220)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            DiskSunburstView(node: currentNode, nodeTitle: displayName(for:), onOpenNode: openMapNode)
                                .frame(minHeight: 430)
                            mapLegend(for: currentNode)
                        }
                    }

                    Text(L.t("disk.map.note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mapBreadcrumbs: some View {
        HStack(spacing: 8) {
            Button {
                guard navigationStack.count > 1 else { return }
                navigationStack.removeLast()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .disabled(navigationStack.count <= 1)
            .help(L.t("disk.map.back"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(navigationStack.enumerated()), id: \.element.id) { index, node in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Button(displayName(for: node)) {
                            navigationStack = Array(navigationStack.prefix(index + 1))
                        }
                        .buttonStyle(.plain)
                        .font(.subheadline.weight(index == navigationStack.count - 1 ? .semibold : .regular))
                    }
                }
            }

            Spacer(minLength: 8)

            if let path = currentNode?.path {
                Button {
                    Task { await DiskAnalysisWorkspaceService.reveal(URL(fileURLWithPath: path)) }
                } label: {
                    Label(L.t("disk.action.finder"), systemImage: "folder")
                }
            }
        }
    }

    private func mapLegend(for node: DiskAnalysisNode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayName(for: node))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
            Text(CleanMacFormatters.bytes(node.sizeBytes))
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)

            Divider()

            ForEach(Array(node.children.prefix(9).enumerated()), id: \.element.id) { index, child in
                legendRow(child, colorIndex: index)
            }

            if node.children.isEmpty {
                Text(L.t("disk.map.empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func legendRow(_ child: DiskAnalysisNode, colorIndex: Int) -> some View {
        let row = HStack(spacing: 8) {
            Circle()
                .fill(DiskSunburstPalette.color(index: colorIndex))
                .frame(width: 9, height: 9)
            Text(displayName(for: child))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(CleanMacFormatters.bytes(child.sizeBytes))
                .foregroundStyle(.secondary)
            if child.isDirectory, !child.children.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.caption)
        .contentShape(Rectangle())

        if child.isDirectory, !child.isAggregate, !child.children.isEmpty {
            Button {
                openMapNode(child)
            } label: {
                row
            }
            .buttonStyle(.plain)
            .help(L.t("disk.map.clickHint"))
        } else {
            row
        }
    }

    private var largeFilesContent: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        thresholdPicker
                        Spacer(minLength: 8)
                        sortPicker
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        thresholdPicker
                        sortPicker
                    }
                }

                HStack {
                    Text(L.f("disk.files.count", visibleLargeFiles.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    fileActions
                }

                Divider()

                largeFileHeader

                if visibleLargeFiles.isEmpty {
                    ContentUnavailableView(
                        L.t("disk.files.empty.title"),
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(L.t("disk.files.empty.message"))
                    )
                    .frame(minHeight: 260)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 5) {
                            ForEach(visibleLargeFiles) { file in
                                largeFileRow(file)
                            }
                        }
                    }
                    .frame(minHeight: 300, maxHeight: 470)
                }
            }
        }
    }

    private var thresholdPicker: some View {
        Picker(L.t("disk.files.threshold"), selection: $threshold) {
            ForEach(LargeFileThreshold.allCases) { threshold in
                Text(threshold.title).tag(threshold)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 390)
    }

    private var sortPicker: some View {
        Picker(L.t("disk.files.sort"), selection: $sort) {
            ForEach(LargeFileSort.allCases) { sort in
                Text(sort.title).tag(sort)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 390)
    }

    private var fileActions: some View {
        HStack(spacing: 8) {
            Button {
                guard let selectedFile else { return }
                Task { await DiskAnalysisWorkspaceService.reveal(URL(fileURLWithPath: selectedFile.path)) }
            } label: {
                Label(L.t("disk.action.finder"), systemImage: "folder")
            }
            .disabled(selectedFile == nil)

            Button {
                guard let selectedFile else { return }
                DiskAnalysisWorkspaceService.open(URL(fileURLWithPath: selectedFile.path))
            } label: {
                Label(L.t("disk.action.open"), systemImage: "arrow.up.forward.app")
            }
            .disabled(selectedFile == nil)
        }
    }

    private var largeFileHeader: some View {
        HStack(spacing: 10) {
            Text(L.t("disk.files.column.name"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L.t("disk.files.column.type"))
                .frame(width: 90, alignment: .leading)
            Text(L.t("disk.files.column.modified"))
                .frame(width: 110, alignment: .leading)
            Text(L.t("disk.files.column.size"))
                .frame(width: 90, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
    }

    private func largeFileRow(_ file: DiskAnalysisFile) -> some View {
        let isSelected = selectedFileID == file.id

        return Button {
            selectedFileID = file.id
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(URL(fileURLWithPath: file.path).deletingLastPathComponent().path)
                        .font(.caption.monospaced())
                        .foregroundStyle(isSelected ? Color.white.opacity(0.78) : Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(file.fileType.title)
                    .frame(width: 90, alignment: .leading)
                Text(CleanMacFormatters.relativeDate(file.modifiedAt))
                    .frame(width: 110, alignment: .leading)
                Text(CleanMacFormatters.bytes(file.sizeBytes))
                    .fontWeight(.semibold)
                    .frame(width: 90, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .frame(minHeight: 50)
            .background(
                isSelected ? Color.accentColor : Color.primary.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(L.t("disk.action.finder")) {
                Task { await DiskAnalysisWorkspaceService.reveal(URL(fileURLWithPath: file.path)) }
            }
            Button(L.t("disk.action.open")) {
                DiskAnalysisWorkspaceService.open(URL(fileURLWithPath: file.path))
            }
        }
    }

    private var emptyState: some View {
        InfoPanel {
            ContentUnavailableView(
                L.t("disk.empty.title"),
                systemImage: "chart.pie",
                description: Text(L.t("disk.empty.message"))
            )
            .frame(maxWidth: .infinity, minHeight: 280)
        }
    }

    private var sourceSelection: Binding<DiskAnalysisSource> {
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
        guard !isScanning, !isChoosingCustomFolder else { return }
        isChoosingCustomFolder = true

        Task { @MainActor in
            await Task.yield()
            let selectedURL = DiskAnalysisWorkspaceService.chooseFolder()
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
        guard let rootURL = sourceURL, !isScanning else {
            return
        }

        cancelScan(showMessage: false)
        let scanID = UUID()
        activeScanID = scanID
        isScanning = true
        report = nil
        progress = DiskAnalysisProgress(
            phase: .preparing,
            currentPath: rootURL.path,
            visitedItemCount: 0,
            measuredSizeBytes: 0,
            largeFileCount: 0
        )
        navigationStack = []
        selectedFileID = nil
        statusMessage = nil
        problemMessage = nil

        let minimumLargeFileSize = LargeFileThreshold.megabytes50.bytes
        let progressChannel = AsyncStream.makeStream(
            of: DiskAnalysisProgress.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let worker = Task.detached(priority: .utility) {
            defer { progressChannel.continuation.finish() }
            return try DiskAnalyzer().scan(
                root: rootURL,
                options: DiskAnalysisOptions(minimumLargeFileSizeBytes: minimumLargeFileSize),
                progress: { progressChannel.continuation.yield($0) },
                isCancelled: { Task.isCancelled }
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

                report = completedReport
                navigationStack = [completedReport.root]
                selectedFileID = nil
                statusMessage = L.f(
                    "disk.status.complete",
                    CleanMacFormatters.bytes(completedReport.root.sizeBytes),
                    completedReport.visitedItemCount
                )
                if !completedReport.issues.isEmpty {
                    problemMessage = L.f("disk.problem.issues", completedReport.issues.count)
                }
                finishScan(scanID: scanID)
            } catch is CancellationError {
                guard activeScanID == scanID else { return }
                finishScan(scanID: scanID)
            } catch let error as DiskAnalyzerError {
                guard activeScanID == scanID else { return }
                problemMessage = error.localizedDiskAnalysisMessage
                finishScan(scanID: scanID)
            } catch {
                guard activeScanID == scanID else { return }
                problemMessage = L.f("disk.problem.generic", error.localizedDescription)
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
            statusMessage = L.t("disk.status.cancelled")
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
        report = nil
        navigationStack = []
        selectedFileID = nil
        statusMessage = nil
        problemMessage = nil
    }

    private func openMapNode(_ node: DiskAnalysisNode) {
        guard node.isDirectory, !node.isAggregate, !node.children.isEmpty else {
            return
        }
        navigationStack.append(node)
    }

    private func keepOnlyVisibleSelection() {
        guard let selectedFileID, visibleLargeFiles.contains(where: { $0.id == selectedFileID }) else {
            self.selectedFileID = nil
            return
        }
    }

    private func displayName(for node: DiskAnalysisNode) -> String {
        if node.path == "/" {
            return (try? URL(fileURLWithPath: "/", isDirectory: true)
                .resourceValues(forKeys: [.volumeNameKey]).volumeName)
                ?? L.t("disk.source.wholeDisk")
        }
        if node.id.hasSuffix("#files") {
            return L.t("disk.map.files")
        }
        if node.isAggregate {
            return L.t("disk.map.other")
        }
        return node.name
    }
}

private enum DiskAnalysisSource: String, CaseIterable, Identifiable {
    case wholeDisk
    case home
    case downloads
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wholeDisk: L.t("disk.source.wholeDisk")
        case .home: L.t("disk.source.home")
        case .downloads: L.t("disk.source.downloads")
        case .custom: L.t("disk.source.custom")
        }
    }
}

private enum DiskAnalysisMode: String, CaseIterable, Identifiable {
    case map
    case largeFiles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .map: L.t("disk.mode.map")
        case .largeFiles: L.t("disk.mode.largeFiles")
        }
    }

    var systemImage: String {
        switch self {
        case .map: "chart.pie.fill"
        case .largeFiles: "list.bullet.rectangle"
        }
    }
}

private enum LargeFileThreshold: Int64, CaseIterable, Identifiable {
    case megabytes50 = 52_428_800
    case megabytes100 = 104_857_600
    case megabytes500 = 524_288_000
    case gigabyte1 = 1_073_741_824

    var id: Int64 { rawValue }
    var bytes: Int64 { rawValue }

    var title: String {
        switch self {
        case .megabytes50: L.t("disk.threshold.50")
        case .megabytes100: L.t("disk.threshold.100")
        case .megabytes500: L.t("disk.threshold.500")
        case .gigabyte1: L.t("disk.threshold.1000")
        }
    }
}

private enum LargeFileSort: String, CaseIterable, Identifiable {
    case size
    case modified
    case type

    var id: String { rawValue }

    var title: String {
        switch self {
        case .size: L.t("disk.files.sort.size")
        case .modified: L.t("disk.files.sort.modified")
        case .type: L.t("disk.files.sort.type")
        }
    }
}

private extension DiskAnalysisFileType {
    var title: String {
        switch self {
        case .document: L.t("disk.type.document")
        case .image: L.t("disk.type.image")
        case .video: L.t("disk.type.video")
        case .audio: L.t("disk.type.audio")
        case .archive: L.t("disk.type.archive")
        case .application: L.t("disk.type.application")
        case .code: L.t("disk.type.code")
        case .diskImage: L.t("disk.type.diskImage")
        case .other: L.t("disk.type.other")
        }
    }
}

private extension DiskAnalyzerError {
    var localizedDiskAnalysisMessage: String {
        switch self {
        case .rootUnavailable: L.t("disk.problem.rootUnavailable")
        case .rootIsNotDirectory: L.t("disk.problem.notDirectory")
        case .enumerationFailed: L.t("disk.problem.enumerationFailed")
        }
    }
}

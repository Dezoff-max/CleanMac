import AppKit
import CleanMacCore
import SwiftUI

struct ResultsView: View {
    let results: [ScanResult]
    let report: CleanupScanReport?
    let scanError: String?
    @Binding var selectedResultIDs: Set<String>
    let isCleaning: Bool
    let isRestoring: Bool
    let cleanupStatusMessage: String?
    let cleanupProblemMessage: String?
    let restoreStatusMessage: String?
    let restoreProblemMessage: String?
    let cleanupHistory: [CleanupHistoryItem]
    let onConfirmCleanup: () -> Void
    let onRestoreHistoryItem: (String) -> Void

    @State private var isShowingCleanupConfirmation = false
    @State private var selectedCategory: CleanupCategory?
    @State private var focusedResultID: String?

    private var selectedResults: [ScanResult] {
        results.filter { selectedResultIDs.contains($0.id) }
    }

    private var selectedSizeBytes: Int64 {
        selectedResults.reduce(0) { $0 + $1.sizeBytes }
    }

    private var visibleResults: [ScanResult] {
        guard let selectedCategory else {
            return results
        }
        return results.filter { $0.category == selectedCategory }
    }

    private var focusedResult: ScanResult? {
        if let focusedResultID,
           let result = visibleResults.first(where: { $0.id == focusedResultID }) {
            return result
        }
        return visibleResults.first { selectedResultIDs.contains($0.id) } ?? visibleResults.first
    }

    private var categorySummaries: [ResultCategorySummary] {
        CleanupCategory.allCases.compactMap { category in
            let categoryResults = results.filter { $0.category == category }
            guard !categoryResults.isEmpty else {
                return nil
            }
            return ResultCategorySummary(
                category: category,
                count: categoryResults.count,
                sizeBytes: categoryResults.reduce(0) { $0 + $1.sizeBytes },
                selectedCount: categoryResults.filter { selectedResultIDs.contains($0.id) }.count,
                safeCount: categoryResults.filter { $0.risk == .safe }.count,
                reviewCount: categoryResults.filter { $0.risk == .review }.count
            )
        }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: L.t("results.title"),
                    subtitle: L.t("results.subtitle"),
                    systemImage: "checklist"
                )

                if !results.isEmpty {
                    ResultsHeroSummary(
                        results: results,
                        selectedCount: selectedResults.count,
                        selectedSizeBytes: selectedSizeBytes
                    )
                } else if report != nil {
                    StatusBanner(
                        title: L.t("cleanup.complete.title"),
                        message: L.t("cleanup.complete.message"),
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }

                statusBanners

                if results.isEmpty {
                    emptyResultsPanel
                    cleanupHistoryPanel
                } else {
                    selectionToolbar
                    reviewWorkspace
                    cleanupHistoryPanel
                }
            }
        }
        .alert(L.t("cleanup.confirm.title"), isPresented: $isShowingCleanupConfirmation) {
            Button(L.t("button.cancel"), role: .cancel) {}
            Button(L.t("button.moveToTrash"), role: .destructive) {
                onConfirmCleanup()
            }
        } message: {
            Text(cleanupConfirmationMessage)
        }
    }

    @ViewBuilder
    private var statusBanners: some View {
        if let cleanupStatusMessage {
            StatusBanner(
                title: L.t("cleanup.status.title"),
                message: cleanupStatusMessage,
                systemImage: "trash",
                tint: .green
            )
        }

        if let restoreStatusMessage {
            StatusBanner(
                title: L.t("restore.status.title"),
                message: restoreStatusMessage,
                systemImage: "arrow.uturn.backward.circle",
                tint: .green
            )
        }

        if let cleanupProblemMessage {
            StatusBanner(
                title: L.t("cleanup.problem.title"),
                message: cleanupProblemMessage,
                systemImage: "exclamationmark.triangle",
                tint: .orange
            )
        }

        if let restoreProblemMessage {
            StatusBanner(
                title: L.t("restore.problem.title"),
                message: restoreProblemMessage,
                systemImage: "exclamationmark.triangle",
                tint: .orange
            )
        }

        if let scanError {
            StatusBanner(
                title: L.t("banner.scanIssues.title"),
                message: scanError,
                systemImage: "exclamationmark.triangle",
                tint: .orange
            )
        }
    }

    private var emptyResultsPanel: some View {
        InfoPanel {
            ContentUnavailableView(
                L.t("results.empty.title"),
                systemImage: "doc.text.magnifyingglass",
                description: Text(L.t("results.empty.description"))
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }

    private var selectionToolbar: some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    selectionSummary
                    Spacer()
                    resultSelectionButtons
                    cleanupButton
                }

                VStack(alignment: .leading, spacing: 12) {
                    selectionSummary
                    HStack(spacing: 10) {
                        resultSelectionButtons
                        Spacer()
                        cleanupButton
                    }
                }
            }
        }
    }

    private var selectionSummary: some View {
        Label(
            L.f(
                "results.selected.summary",
                selectedResults.count,
                CleanMacFormatters.bytes(selectedSizeBytes)
            ),
            systemImage: "checkmark.circle"
        )
        .foregroundStyle(.secondary)
    }

    private var resultSelectionButtons: some View {
        HStack(spacing: 8) {
            Button {
                selectedResultIDs = Set(visibleResults.filter { $0.risk == .safe }.map(\.id))
            } label: {
                Label(L.t("button.selectSafe"), systemImage: "checkmark.shield")
            }

            Button {
                selectedResultIDs = Set(visibleResults.map(\.id))
            } label: {
                Label(L.t("button.selectVisible"), systemImage: "checklist.checked")
            }

            Button {
                selectedResultIDs.subtract(visibleResults.map(\.id))
            } label: {
                Label(L.t("button.clearVisible"), systemImage: "xmark.circle")
            }
        }
    }

    private var cleanupButton: some View {
        Button {
            isShowingCleanupConfirmation = true
        } label: {
            Label(isCleaning ? L.t("button.cleaning") : L.t("button.moveToTrash"), systemImage: "trash")
        }
        .buttonStyle(.borderedProminent)
        .disabled(isCleaning || selectedResults.isEmpty)
    }

    private var reviewWorkspace: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryNavigator

            HStack(alignment: .top, spacing: 12) {
                resultList
                    .frame(maxWidth: .infinity)

                detailPanel
                    .frame(width: 290)
            }
        }
    }

    private var categoryNavigator: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(L.t("results.categories.title"), systemImage: "square.grid.2x2")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 210), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    CategorySummaryRow(
                        title: L.t("results.categories.all"),
                        systemImage: "tray.full",
                        count: results.count,
                        sizeBytes: results.reduce(0) { $0 + $1.sizeBytes },
                        selectedCount: selectedResults.count,
                        isActive: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                        focusedResultID = nil
                    }

                    ForEach(categorySummaries) { summary in
                        let area = CleanMacCatalog.area(for: summary.category)
                        CategorySummaryRow(
                            title: area.title,
                            systemImage: area.systemImage,
                            count: summary.count,
                            sizeBytes: summary.sizeBytes,
                            selectedCount: summary.selectedCount,
                            isActive: selectedCategory == summary.category
                        ) {
                            selectedCategory = summary.category
                            focusedResultID = results.first { $0.category == summary.category }?.id
                        }
                    }
                }
            }
        }
    }

    private var resultList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(L.t("results.items.title"), systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Text(L.f("results.items.count", visibleResults.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if visibleResults.isEmpty {
                InfoPanel {
                    ContentUnavailableView(
                        L.t("results.category.empty.title"),
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text(L.t("results.category.empty.description"))
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            } else {
                ForEach(visibleResults) { result in
                    ResultRow(
                        result: result,
                        isFocused: focusedResult?.id == result.id,
                        isSelected: Binding(
                            get: { selectedResultIDs.contains(result.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedResultIDs.insert(result.id)
                                } else {
                                    selectedResultIDs.remove(result.id)
                                }
                            }
                        ),
                        onFocus: {
                            focusedResultID = result.id
                        }
                    )
                }
            }
        }
    }

    private var detailPanel: some View {
        InfoPanel {
            if let focusedResult {
                ResultDetailPanel(result: focusedResult)
            } else {
                ContentUnavailableView(
                    L.t("results.detail.empty.title"),
                    systemImage: "sidebar.right",
                    description: Text(L.t("results.detail.empty.description"))
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
    }

    private var cleanupHistoryPanel: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Label(L.t("history.title"), systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                    Spacer()
                    if !cleanupHistory.isEmpty {
                        Text(L.f("history.count", cleanupHistory.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(L.t("history.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if cleanupHistory.isEmpty {
                    Label(L.t("history.empty"), systemImage: "trash")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(cleanupHistory) { item in
                            CleanupHistoryRow(
                                item: item,
                                isRestoring: isRestoring,
                                onRestore: {
                                    onRestoreHistoryItem(item.id)
                                },
                                onReveal: {
                                    reveal(item.status == .restored ? item.originalPath : item.trashedPath)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var cleanupConfirmationMessage: String {
        L.f(
            "cleanup.confirm.message",
            selectedResults.count,
            CleanMacFormatters.bytes(selectedSizeBytes)
        )
    }

    private func reveal(_ path: String) {
        guard path != L.t("history.trashPath.unknown") else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}

private struct ResultsHeroSummary: View {
    let results: [ScanResult]
    let selectedCount: Int
    let selectedSizeBytes: Int64

    private var totalSizeBytes: Int64 {
        results.reduce(0) { $0 + $1.sizeBytes }
    }

    private var safeCount: Int {
        results.filter { $0.risk == .safe }.count
    }

    private var reviewCount: Int {
        results.filter { $0.risk == .review }.count
    }

    var body: some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    metric(L.t("results.metric.total"), "\(results.count)", "doc.text.magnifyingglass")
                    Divider()
                    metric(L.t("results.metric.space"), CleanMacFormatters.bytes(totalSizeBytes), "externaldrive")
                    Divider()
                    metric(L.t("results.metric.selected"), "\(selectedCount)", "checkmark.circle")
                    Divider()
                    metric(L.t("results.metric.risk"), "\(safeCount) / \(reviewCount)", "shield.lefthalf.filled")
                }

                VStack(alignment: .leading, spacing: 12) {
                    metric(L.t("results.metric.total"), "\(results.count)", "doc.text.magnifyingglass")
                    metric(L.t("results.metric.space"), CleanMacFormatters.bytes(totalSizeBytes), "externaldrive")
                    metric(L.t("results.metric.selected"), "\(selectedCount) · \(CleanMacFormatters.bytes(selectedSizeBytes))", "checkmark.circle")
                    metric(L.t("results.metric.risk"), L.f("results.metric.risk.detail", safeCount, reviewCount), "shield.lefthalf.filled")
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String, _ systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(minWidth: 96, alignment: .leading)
        }
    }
}

private struct ResultCategorySummary: Identifiable {
    let category: CleanupCategory
    let count: Int
    let sizeBytes: Int64
    let selectedCount: Int
    let safeCount: Int
    let reviewCount: Int

    var id: CleanupCategory { category }
}

private struct CategorySummaryRow: View {
    let title: String
    let systemImage: String
    let count: Int
    let sizeBytes: Int64
    let selectedCount: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(L.f("results.category.summary", count, CleanMacFormatters.bytes(sizeBytes)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(isActive ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ResultRow: View {
    let result: ScanResult
    let isFocused: Bool
    @Binding var isSelected: Bool
    let onFocus: () -> Void

    var body: some View {
        InfoPanel {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .padding(.top, 2)

                Image(systemName: result.isDirectory ? "folder" : "doc")
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(result.title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        RiskBadge(risk: result.risk)
                    }

                    Text(result.location)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 12) {
                        Label(result.modified, systemImage: "clock")
                        if result.isSizeEstimate {
                            Label(L.t("results.estimated"), systemImage: "sum")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(result.size)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if isFocused {
                        Image(systemName: "sidebar.right")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onFocus)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isFocused ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1.5)
        }
    }
}

private struct ResultDetailPanel: View {
    let result: ScanResult

    private var area: CleanupArea {
        CleanMacCatalog.area(for: result.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: area.systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(area.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            RiskBadge(risk: result.risk)
            Text(riskDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            DetailRow(title: L.t("results.detail.size"), value: result.size, systemImage: "externaldrive")
            DetailRow(title: L.t("results.detail.modified"), value: result.modified, systemImage: "clock")
            DetailRow(title: L.t("results.detail.type"), value: result.isDirectory ? L.t("results.detail.folder") : L.t("results.detail.file"), systemImage: result.isDirectory ? "folder" : "doc")
            DetailRow(title: L.t("results.detail.cleanup"), value: L.t("results.detail.cleanup.trash"), systemImage: "trash")

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label(L.t("results.detail.path"), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(result.location)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(4)
                    .truncationMode(.middle)
            }
        }
    }

    private var riskDescription: String {
        switch result.risk {
        case .safe:
            L.t("results.risk.safe.detail")
        case .review:
            L.t("results.risk.review.detail")
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .frame(width: 16)
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 10)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}

private struct CleanupHistoryRow: View {
    let item: CleanupHistoryItem
    let isRestoring: Bool
    let onRestore: () -> Void
    let onReveal: () -> Void

    private var canRestore: Bool {
        item.status != .restored
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.status.systemImage)
                    .font(.title3)
                    .frame(width: 24)
                    .foregroundStyle(statusTint)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(item.status.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(statusTint)
                    }

                    Text(item.originalPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(L.f("history.item.detail", item.size, CleanMacFormatters.relativeDate(item.movedAt)))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let message = item.message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onReveal()
                    } label: {
                        Label(L.t("button.reveal"), systemImage: "finder")
                    }

                    Button {
                        onRestore()
                    } label: {
                        Label(isRestoring ? L.t("button.restoring") : L.t("button.restore"), systemImage: "arrow.uturn.backward")
                    }
                    .disabled(isRestoring || !canRestore)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusTint: Color {
        switch item.status {
        case .inTrash:
            .blue
        case .restored:
            .green
        case .restoreFailed:
            .orange
        }
    }
}

import CleanMacCore
import SwiftUI

struct ResultsView: View {
    let results: [ScanResult]
    let report: CleanupScanReport?
    let scanError: String?
    @Binding var selectedResultIDs: Set<String>
    let isCleaning: Bool
    let cleanupStatusMessage: String?
    let cleanupProblemMessage: String?
    let onConfirmCleanup: () -> Void

    @State private var isShowingCleanupConfirmation = false

    private var selectedResults: [ScanResult] {
        results.filter { selectedResultIDs.contains($0.id) }
    }

    private var selectedSizeBytes: Int64 {
        selectedResults.reduce(0) { $0 + $1.sizeBytes }
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
                    ResultsSummaryView(results: results)
                } else if report != nil {
                    StatusBanner(
                        title: L.t("cleanup.complete.title"),
                        message: L.t("cleanup.complete.message"),
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }

                if let cleanupStatusMessage {
                    StatusBanner(
                        title: L.t("cleanup.status.title"),
                        message: cleanupStatusMessage,
                        systemImage: "trash",
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

                if let scanError {
                    StatusBanner(
                        title: L.t("banner.scanIssues.title"),
                        message: scanError,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                }

                if results.isEmpty {
                    InfoPanel {
                        ContentUnavailableView(
                            L.t("results.empty.title"),
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(L.t("results.empty.description"))
                        )
                        .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    selectionToolbar

                    VStack(spacing: 10) {
                        ForEach(results) { result in
                            ResultRow(
                                result: result,
                                isSelected: Binding(
                                    get: { selectedResultIDs.contains(result.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedResultIDs.insert(result.id)
                                        } else {
                                            selectedResultIDs.remove(result.id)
                                        }
                                    }
                                )
                            )
                        }
                    }
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
                selectedResultIDs = Set(results.filter { $0.risk == .safe }.map(\.id))
            } label: {
                Label(L.t("button.selectSafe"), systemImage: "checkmark.shield")
            }

            Button {
                selectedResultIDs = Set(results.map(\.id))
            } label: {
                Label(L.t("button.selectAll"), systemImage: "checklist.checked")
            }

            Button {
                selectedResultIDs.removeAll()
            } label: {
                Label(L.t("button.clearSelection"), systemImage: "xmark.circle")
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

    private var cleanupConfirmationMessage: String {
        L.f(
            "cleanup.confirm.message",
            selectedResults.count,
            CleanMacFormatters.bytes(selectedSizeBytes)
        )
    }
}

private struct ResultsSummaryView: View {
    let results: [ScanResult]

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 10)
    ]

    private var summaries: [(category: CleanupCategory, count: Int, sizeBytes: Int64)] {
        CleanupCategory.allCases.compactMap { category in
            let categoryResults = results.filter { $0.category == category }
            guard !categoryResults.isEmpty else {
                return nil
            }
            return (
                category,
                categoryResults.count,
                categoryResults.reduce(0) { $0 + $1.sizeBytes }
            )
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(summaries, id: \.category) { summary in
                let area = CleanMacCatalog.area(for: summary.category)
                InfoPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(area.title, systemImage: area.systemImage)
                            .font(.headline)
                        Text(CleanMacFormatters.bytes(summary.sizeBytes))
                            .font(.title3.bold())
                        Text(L.f("results.summary.items", summary.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct ResultRow: View {
    let result: ScanResult
    @Binding var isSelected: Bool

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

                Text(result.size)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }
}

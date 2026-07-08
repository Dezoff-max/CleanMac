import CleanMacCore
import SwiftUI

struct ResultsView: View {
    let results: [ScanResult]
    let report: CleanupScanReport?
    let scanError: String?

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: L.t("results.title"),
                    subtitle: L.t("results.subtitle"),
                    systemImage: "checklist"
                )

                if let report {
                    ResultsSummaryView(report: report)
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
                        .frame(maxWidth: .infinity, minHeight: 240)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(results) { result in
                            ResultRow(result: result)
                        }
                    }

                    HStack {
                        Label(L.f("results.readyGroups", results.count), systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                        } label: {
                            Label(L.t("button.cleanSelected"), systemImage: "trash")
                        }
                        .disabled(true)
                        .help(L.t("results.cleanupDisabled.help"))
                    }
                }
            }
        }
    }
}

private struct ResultsSummaryView: View {
    let report: CleanupScanReport

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(report.summaries, id: \.category) { summary in
                let area = CleanMacCatalog.area(for: summary.category)
                InfoPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(area.title, systemImage: area.systemImage)
                            .font(.headline)
                        Text(CleanMacFormatters.bytes(summary.totalSizeBytes))
                            .font(.title3.bold())
                        Text(summary.isAvailable ? L.f("results.summary.items", summary.itemCount) : L.t("results.summary.unavailable"))
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

    var body: some View {
        InfoPanel {
            HStack(alignment: .top, spacing: 12) {
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

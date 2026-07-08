import CleanMacCore
import SwiftUI

struct DashboardView: View {
    let report: CleanupScanReport?
    let resultCount: Int
    let selectedAreaCount: Int
    let selectedAreas: [CleanupArea]
    let isScanning: Bool
    let scanError: String?
    let onStartScan: () -> Void
    let onChooseAreas: () -> Void

    private let metricColumns = [
        GridItem(.adaptive(minimum: 190), spacing: 12)
    ]

    private let selectedAreaColumns = [
        GridItem(.adaptive(minimum: 250), spacing: 12)
    ]

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: L.t("dashboard.title"),
                    subtitle: L.t("dashboard.subtitle"),
                    systemImage: "sparkles"
                )

                if let scanError {
                    StatusBanner(
                        title: L.t("banner.scanIssues.title"),
                        message: scanError,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                } else {
                    StatusBanner(
                        title: report == nil ? L.t("banner.ready.title") : L.t("banner.review.title"),
                        message: report == nil ? L.t("banner.ready.message") : L.t("banner.review.message"),
                        systemImage: report == nil ? "shield.checkered" : "checkmark.circle",
                        tint: report == nil ? .blue : .green
                    )
                }

                LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                    ForEach(CleanMacCatalog.metrics(report: report, selectedAreaCount: selectedAreaCount)) { metric in
                        MetricPanel(metric: metric)
                    }
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(report == nil ? L.t("dashboard.nextScan.title") : L.t("dashboard.lastScan.title"))
                                    .font(.title2.bold())
                                Text(summaryText)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 10) {
                                    chooseAreasButton
                                    startScanButton
                                }

                                VStack(alignment: .trailing, spacing: 8) {
                                    chooseAreasButton
                                    startScanButton
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L.t("dashboard.selectedAreas.title"))
                                .font(.headline)

                            LazyVGrid(columns: selectedAreaColumns, alignment: .leading, spacing: 10) {
                                ForEach(selectedAreas) { area in
                                    SelectedAreaSummary(area: area)
                                }
                            }
                        }
                    }
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L.t("dashboard.safety.title"))
                            .font(.headline)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 18) {
                                safetyLabels
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                safetyLabels
                            }
                        }
                    }
                }
            }
        }
    }

    private var summaryText: String {
        guard let report else {
            return L.f("dashboard.selectedAreas", selectedAreaCount)
        }
        return L.f(
            "dashboard.lastScan.summary",
            resultCount,
            CleanMacFormatters.bytes(report.totalSizeBytes),
            String(format: "%.1f", report.durationSeconds)
        )
    }

    private var chooseAreasButton: some View {
        Button {
            onChooseAreas()
        } label: {
            Label(L.t("button.chooseAreas"), systemImage: "checklist")
        }
    }

    private var startScanButton: some View {
        Button {
            onStartScan()
        } label: {
            Label(isScanning ? L.t("button.scanning") : L.t("button.startScan"), systemImage: "magnifyingglass")
        }
        .buttonStyle(.borderedProminent)
        .disabled(isScanning || selectedAreaCount == 0)
    }

    @ViewBuilder
    private var safetyLabels: some View {
        Label(L.t("dashboard.safety.scanOnly"), systemImage: "eye")
        Label(L.t("dashboard.safety.confirmation"), systemImage: "hand.raised")
        Label(L.t("dashboard.safety.disabledCleanup"), systemImage: "lock")
    }
}

private struct SelectedAreaSummary: View {
    let area: CleanupArea

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: area.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 22)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 3) {
                Text(area.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(area.pathHint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MetricPanel: View {
    let metric: DashboardMetric

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(metric.title, systemImage: metric.systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(metric.value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(metric.footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

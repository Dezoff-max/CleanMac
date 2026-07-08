import CleanMacCore
import SwiftUI

struct DashboardView: View {
    let report: CleanupScanReport?
    let resultCount: Int
    let selectedAreaCount: Int
    let isScanning: Bool
    let scanError: String?
    let onStartScan: () -> Void

    private let metricColumns = [
        GridItem(.adaptive(minimum: 190), spacing: 12)
    ]

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
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
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(report == nil ? L.t("dashboard.nextScan.title") : L.t("dashboard.lastScan.title"))
                                .font(.title2.bold())
                            Text(summaryText)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            onStartScan()
                        } label: {
                            Label(isScanning ? L.t("button.scanning") : L.t("button.startScan"), systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isScanning || selectedAreaCount == 0)
                    }
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.t("dashboard.safety.title"))
                            .font(.headline)

                        Label(L.t("dashboard.safety.scanOnly"), systemImage: "eye")
                        Label(L.t("dashboard.safety.confirmation"), systemImage: "hand.raised")
                        Label(L.t("dashboard.safety.disabledCleanup"), systemImage: "lock")
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
}

private struct MetricPanel: View {
    let metric: DashboardMetric

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 12) {
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

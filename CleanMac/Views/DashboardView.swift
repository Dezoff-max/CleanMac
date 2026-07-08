import SwiftUI

struct DashboardView: View {
    let resultCount: Int
    let selectedAreaCount: Int
    let isScanning: Bool
    let onStartScan: () -> Void

    private let metricColumns = [
        GridItem(.adaptive(minimum: 190), spacing: 12)
    ]

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "CleanMac",
                    subtitle: "System cleanup workspace",
                    systemImage: "sparkles"
                )

                LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                    ForEach(CleanMacCatalog.metrics) { metric in
                        MetricPanel(metric: metric)
                    }
                }

                InfoPanel {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ready")
                                .font(.title2.bold())
                            Text("\(selectedAreaCount) areas selected")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            onStartScan()
                        } label: {
                            Label(isScanning ? "Scanning" : "Start Scan", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isScanning || selectedAreaCount == 0)
                    }
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Results")
                            .font(.headline)

                        HStack {
                            Label("\(resultCount) items", systemImage: "checklist")
                            Spacer()
                            Text(resultCount == 0 ? "No scan yet" : "Ready to review")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct MetricPanel: View {
    let metric: DashboardMetric

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(metric.title, systemImage: metric.systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(metric.value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text(metric.footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

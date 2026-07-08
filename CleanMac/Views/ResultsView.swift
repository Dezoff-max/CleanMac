import SwiftUI

struct ResultsView: View {
    let results: [ScanResult]

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Results",
                    subtitle: "Review items before cleanup",
                    systemImage: "checklist"
                )

                if results.isEmpty {
                    InfoPanel {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Run a scan to review cleanup candidates.")
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
                        Label("\(results.count) groups ready", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                        } label: {
                            Label("Clean Selected", systemImage: "trash")
                        }
                        .disabled(true)
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
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Text(result.title)
                            .font(.headline)
                        RiskBadge(risk: result.risk)
                    }

                    Text(result.location)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(result.size)
                    .font(.headline)
            }
        }
    }
}

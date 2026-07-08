import SwiftUI

struct ScanView: View {
    @Binding var selectedAreaIDs: Set<String>
    let isScanning: Bool
    let onStartScan: () -> Void

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Scan",
                    subtitle: "Choose areas before cleanup review",
                    systemImage: "magnifyingglass"
                )

                VStack(spacing: 10) {
                    ForEach(CleanMacCatalog.cleanupAreas) { area in
                        CleanupAreaRow(
                            area: area,
                            isSelected: Binding(
                                get: { selectedAreaIDs.contains(area.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedAreaIDs.insert(area.id)
                                    } else {
                                        selectedAreaIDs.remove(area.id)
                                    }
                                }
                            )
                        )
                    }
                }

                HStack {
                    Text("\(selectedAreaIDs.count) selected")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        onStartScan()
                    } label: {
                        Label(isScanning ? "Scanning" : "Scan Selected", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning || selectedAreaIDs.isEmpty)
                }
            }
        }
    }
}

private struct CleanupAreaRow: View {
    let area: CleanupArea
    @Binding var isSelected: Bool

    var body: some View {
        InfoPanel {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .padding(.top, 2)

                Image(systemName: area.systemImage)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Text(area.title)
                            .font(.headline)
                        RiskBadge(risk: area.risk)
                    }

                    Text(area.detail)
                        .foregroundStyle(.secondary)

                    Text(area.pathHint)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(area.estimate)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

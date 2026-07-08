import SwiftUI

struct ScanView: View {
    @Binding var selectedAreaIDs: Set<String>
    let isScanning: Bool
    let onStartScan: () -> Void

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: L.t("scan.title"),
                    subtitle: L.t("scan.subtitle"),
                    systemImage: "magnifyingglass"
                )

                if isScanning {
                    StatusBanner(
                        title: L.t("scan.running.title"),
                        message: L.t("scan.running.message"),
                        systemImage: "clock.arrow.circlepath",
                        tint: .blue
                    )
                }

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

                HStack(spacing: 12) {
                    Label(L.f("scan.selected", selectedAreaIDs.count), systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        selectedAreaIDs = Set(CleanMacCatalog.cleanupAreas.map(\.id))
                    } label: {
                        Label(L.t("button.selectAll"), systemImage: "checklist.checked")
                    }

                    Button {
                        onStartScan()
                    } label: {
                        Label(isScanning ? L.t("button.scanning") : L.t("button.scanSelected"), systemImage: "play.fill")
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
                    .symbolRenderingMode(.hierarchical)

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
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Text(isSelected ? L.t("scan.area.enabled") : L.t("scan.area.skipped"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}

import SwiftUI

struct ScanView: View {
    @Binding var selectedAreaIDs: Set<String>
    let isScanning: Bool
    let onStartScan: () -> Void

    @State private var filter: ScanAreaFilter = .all

    private var visibleAreas: [CleanupArea] {
        CleanMacCatalog.cleanupAreas.filter { area in
            switch filter {
            case .all:
                true
            case .safe:
                area.risk == .safe
            case .review:
                area.risk == .review
            }
        }
    }

    private var selectedAreas: [CleanupArea] {
        CleanMacCatalog.cleanupAreas.filter { selectedAreaIDs.contains($0.id) }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: L.t("scan.title"),
                    subtitle: L.t("scan.subtitle"),
                    systemImage: "magnifyingglass"
                )

                if isScanning {
                    ScanActivityView(selectedAreas: selectedAreas)
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                filterPicker
                                Spacer()
                                presetButtons
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                filterPicker
                                presetButtons
                            }
                        }

                        Divider()

                        scanActions
                    }
                }

                VStack(spacing: 10) {
                    ForEach(visibleAreas) { area in
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
            }
        }
    }

    private var filterPicker: some View {
        Picker(L.t("scan.filter.title"), selection: $filter) {
            ForEach(ScanAreaFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 360)
    }

    private var presetButtons: some View {
        HStack(spacing: 8) {
            Button {
                selectedAreaIDs = Set(CleanMacCatalog.cleanupAreas.filter { $0.risk == .safe }.map(\.id))
            } label: {
                Label(L.t("button.selectSafe"), systemImage: "checkmark.shield")
            }

            Button {
                selectedAreaIDs = Set(CleanMacCatalog.cleanupAreas.filter { $0.risk == .review }.map(\.id))
            } label: {
                Label(L.t("button.reviewOnly"), systemImage: "exclamationmark.triangle")
            }

            Button {
                selectedAreaIDs.removeAll()
            } label: {
                Label(L.t("button.clearSelection"), systemImage: "xmark.circle")
            }
        }
    }

    private var scanActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                selectionSummary
                Spacer()
                selectAllButton
                startScanButton
            }

            VStack(alignment: .leading, spacing: 12) {
                selectionSummary
                HStack(spacing: 10) {
                    selectAllButton
                    Spacer()
                    startScanButton
                }
            }
        }
    }

    private var selectionSummary: some View {
        Label(L.f("scan.selected", selectedAreaIDs.count), systemImage: "checkmark.circle")
            .foregroundStyle(.secondary)
    }

    private var selectAllButton: some View {
        Button {
            selectedAreaIDs = Set(CleanMacCatalog.cleanupAreas.map(\.id))
        } label: {
            Label(L.t("button.selectAll"), systemImage: "checklist.checked")
        }
    }

    private var startScanButton: some View {
        Button {
            onStartScan()
        } label: {
            Label(isScanning ? L.t("button.scanning") : L.t("button.scanSelected"), systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(isScanning || selectedAreaIDs.isEmpty)
    }
}

private enum ScanAreaFilter: String, CaseIterable, Identifiable {
    case all
    case safe
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: L.t("scan.filter.all")
        case .safe: L.t("scan.filter.safe")
        case .review: L.t("scan.filter.review")
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

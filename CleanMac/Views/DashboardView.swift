import CleanMacCore
import SwiftUI

struct DashboardView: View {
    let report: CleanupScanReport?
    let resultCount: Int
    let selectedAreaCount: Int
    let selectedAreas: [CleanupArea]
    let isScanning: Bool
    let isOperationBusy: Bool
    let scanError: String?
    let onStartScan: () -> Void
    let onChooseAreas: () -> Void
    let onOpenSection: (CleanMacSection) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsSelectedAreas = false

    private let toolColumns = [GridItem(.adaptive(minimum: 260), spacing: 12)]
    private let areaColumns = [GridItem(.adaptive(minimum: 245), spacing: 12)]

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(
                    title: L.t("dashboard.title"),
                    subtitle: L.t("dashboard.overview.subtitle"),
                    systemImage: "sparkles",
                    imageAssetName: "BrandIcon"
                )

                if let scanError {
                    StatusBanner(
                        title: L.t("banner.scanIssues.title"),
                        message: scanError,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange
                    )
                }

                DashboardHeroPanel {
                    DashboardHeroLayout {
                        scanOverview
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DashboardStorageCard(onOpenAnalysis: { onOpenSection(.diskAnalysis) })
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(L.t("dashboard.tools.title"))
                        .font(.title3.weight(.semibold))

                    LazyVGrid(columns: toolColumns, alignment: .leading, spacing: 12) {
                        toolCard(.diskAnalysis, tint: .blue, detailKey: "dashboard.tools.disk")
                        toolCard(.duplicates, tint: .purple, detailKey: "dashboard.tools.duplicates")
                        toolCard(.applications, tint: .teal, detailKey: "dashboard.tools.applications")
                        toolCard(.systemMaintenance, tint: .orange, detailKey: "dashboard.tools.system")
                        toolCard(.scan, tint: .indigo, detailKey: "dashboard.tools.scan")
                        toolCard(.settings, tint: .secondary, detailKey: "dashboard.tools.settings")
                    }
                }

                InfoPanel {
                    DisclosureGroup(isExpanded: $showsSelectedAreas) {
                        LazyVGrid(columns: areaColumns, alignment: .leading, spacing: 12) {
                            ForEach(selectedAreas) { area in
                                SelectedAreaSummary(area: area)
                            }
                        }
                        .padding(.top, 14)

                        if selectedAreas.isEmpty {
                            Text(L.t("dashboard.overview.noAreas"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                    } label: {
                        Label(L.f("dashboard.selectedAreas", selectedAreaCount), systemImage: "checklist")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .transaction { transaction in
                        if reduceMotion {
                            transaction.animation = nil
                            transaction.disablesAnimations = true
                        }
                }
            }
        }
    }

    private var scanOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L.t("dashboard.overview.scanBadge"), systemImage: "sparkle.magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 7) {
                Text(report == nil ? L.t("dashboard.overview.hero") : CleanMacFormatters.bytes(report?.totalSizeBytes ?? 0))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(report == nil ? L.t("dashboard.overview.description") : L.f("dashboard.overview.found", resultCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    startScanButton
                    secondaryAction
                }
                VStack(alignment: .leading, spacing: 9) {
                    startScanButton
                    secondaryAction
                }
            }

            Label(L.t("dashboard.overview.safety"), systemImage: "checkmark.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let report {
                Text(L.f("dashboard.overview.scannedAt", CleanMacFormatters.relativeDate(report.scannedAt)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var startScanButton: some View {
        Button(action: onStartScan) {
            Label(isScanning ? L.t("button.scanning") : L.t("button.startScan"), systemImage: "magnifyingglass")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isOperationBusy || selectedAreaCount == 0)
    }

    @ViewBuilder
    private var secondaryAction: some View {
        if report != nil {
            Button {
                onOpenSection(.results)
            } label: {
                Text(L.t("dashboard.overview.review"))
            }
            .controlSize(.large)
        } else {
            Button(action: onChooseAreas) {
                Text(L.t("button.chooseAreas"))
            }
            .controlSize(.large)
        }
    }

    private func toolCard(_ section: CleanMacSection, tint: Color, detailKey: String) -> some View {
        DashboardToolCard(section: section, detail: L.t(detailKey), tint: tint) {
            onOpenSection(section)
        }
    }
}

/// Chooses columns from the actual proposed width, rather than the unwrapped
/// headline's ideal width. This keeps the normal window compact and lets text
/// wrap naturally inside its own column without forcing the whole hero to stack.
private struct DashboardHeroLayout: Layout {
    private let storageWidth: CGFloat = 286
    private let minimumOverviewWidth: CGFloat = 250
    private let horizontalSpacing: CGFloat = 24
    private let verticalSpacing: CGFloat = 22

    private var horizontalThreshold: CGFloat {
        minimumOverviewWidth + horizontalSpacing + storageWidth
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = max(proposal.width ?? horizontalThreshold, 0)
        guard subviews.count == 2 else { return CGSize(width: width, height: 0) }

        if width >= horizontalThreshold {
            let overviewSize = subviews[0].sizeThatFits(ProposedViewSize(
                width: width - storageWidth - horizontalSpacing, height: nil
            ))
            let storageSize = subviews[1].sizeThatFits(ProposedViewSize(width: storageWidth, height: nil))
            return CGSize(width: width, height: max(overviewSize.height, storageSize.height))
        }

        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
        return CGSize(width: width, height: sizes[0].height + verticalSpacing + sizes[1].height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }

        if bounds.width >= horizontalThreshold {
            let overviewWidth = bounds.width - storageWidth - horizontalSpacing
            subviews[0].place(
                at: CGPoint(x: bounds.minX, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: overviewWidth, height: nil)
            )
            subviews[1].place(
                at: CGPoint(x: bounds.maxX - storageWidth, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: storageWidth, height: nil)
            )
        } else {
            let childProposal = ProposedViewSize(width: bounds.width, height: nil)
            let overviewSize = subviews[0].sizeThatFits(childProposal)
            subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: childProposal)
            subviews[1].place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + overviewSize.height + verticalSpacing),
                anchor: .topLeading,
                proposal: childProposal
            )
        }
    }
}

private struct DashboardHeroPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.10), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18))
            }
    }
}

private struct DashboardToolCard: View {
    let section: CleanMacSection
    let detail: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: 17, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 2)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(CleanMacCardButtonStyle(tint: tint))
        .accessibilityLabel(section.title)
        .accessibilityHint(detail)
        .help(detail)
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

import CleanMacCore
import SwiftUI

struct ScanActivityView: View {
    let selectedAreas: [CleanupArea]
    let progress: CleanupScanProgress?

    private var visibleAreas: [CleanupArea] {
        Array(selectedAreas.prefix(5))
    }

    private var hiddenAreaCount: Int {
        max(0, selectedAreas.count - visibleAreas.count)
    }

    private var progressFraction: Double {
        progress?.fractionComplete ?? 0
    }

    var body: some View {
        InfoPanel {
            ViewThatFits(in: .horizontal) {
                horizontalLayout
                verticalLayout
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 18) {
            ScanOrbitalIndicator(progress: progressFraction)

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            ScanSignalBars(progress: progressFraction)
                .frame(width: 76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ScanOrbitalIndicator(progress: progressFraction)
                header
            }

            progressTrack
            scanMetrics
            areaRail
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            progressTrack
            scanMetrics
            areaRail
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label(L.t("scan.animation.title"), systemImage: "sparkles")
                    .font(.headline)

                Text(phaseText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Text(L.f("scan.animation.percent", progressPercent))
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.tint)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.tint.opacity(0.12), in: Capsule())
        }
    }

    private var progressTrack: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let filledWidth = max(8, trackWidth * progressFraction)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan, .green.opacity(0.82)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filledWidth)
                    .clipShape(Capsule())
                    .animation(.easeOut(duration: 0.2), value: progressFraction)
            }
        }
        .frame(height: 8)
        .accessibilityLabel(L.f("scan.animation.percent", progressPercent))
    }

    private var scanMetrics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                scanMetric(
                    title: L.t("scan.animation.metric.area"),
                    value: areaProgressText,
                    systemImage: "square.grid.2x2"
                )
                scanMetric(
                    title: L.t("scan.animation.metric.found"),
                    value: L.f("scan.animation.itemsFound", progress?.scannedItemCount ?? 0),
                    systemImage: "doc.text.magnifyingglass"
                )
                scanMetric(
                    title: L.t("scan.animation.metric.size"),
                    value: CleanMacFormatters.bytes(progress?.totalSizeBytes ?? 0),
                    systemImage: "externaldrive"
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                scanMetric(
                    title: L.t("scan.animation.metric.area"),
                    value: areaProgressText,
                    systemImage: "square.grid.2x2"
                )
                scanMetric(
                    title: L.t("scan.animation.metric.found"),
                    value: L.f("scan.animation.itemsFound", progress?.scannedItemCount ?? 0),
                    systemImage: "doc.text.magnifyingglass"
                )
                scanMetric(
                    title: L.t("scan.animation.metric.size"),
                    value: CleanMacFormatters.bytes(progress?.totalSizeBytes ?? 0),
                    systemImage: "externaldrive"
                )
            }
        }
    }

    private func scanMetric(title: String, value: String, systemImage: String) -> some View {
        Label {
            HStack(spacing: 4) {
                Text(title)
                    .foregroundStyle(.secondary)
                Text(value)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
        .font(.caption)
    }

    private var areaRail: some View {
        HStack(spacing: 8) {
            ForEach(visibleAreas) { area in
                ScanAreaChip(area: area, state: chipState(for: area))
            }

            if hiddenAreaCount > 0 {
                Text(L.f("scan.animation.moreAreas", hiddenAreaCount))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var progressPercent: Int {
        let percent = Int((progressFraction * 100).rounded())
        guard let progress, progress.phase != .preparing, progress.phase != .completed else {
            return percent
        }
        return max(1, percent)
    }

    private var areaProgressText: String {
        guard let progress, progress.totalCategoryCount > 0 else {
            return L.f("scan.animation.areaProgress", 0, selectedAreas.count)
        }

        let currentNumber = min(
            progress.totalCategoryCount,
            progress.phase == .completed ? progress.totalCategoryCount : progress.completedCategoryCount + 1
        )
        return L.f("scan.animation.areaProgress", currentNumber, progress.totalCategoryCount)
    }

    private var phaseText: String {
        guard let progress else {
            return L.t("scan.animation.phase.metadata")
        }

        switch progress.phase {
        case .preparing:
            return L.t("scan.animation.phase.preparing")
        case .scanning:
            if let category = progress.currentCategory {
                return L.f("scan.animation.phase.scanningArea", CleanMacCatalog.area(for: category).title)
            }
            return L.t("scan.animation.phase.metadata")
        case .measuring:
            if let currentPath = progress.currentPath {
                return L.f("scan.animation.phase.measuringPath", displayName(for: currentPath))
            }
            return L.t("scan.animation.phase.sizes")
        case .summarizing:
            return L.t("scan.animation.phase.summary")
        case .completed:
            return L.t("scan.animation.phase.completed")
        }
    }

    private func chipState(for area: CleanupArea) -> ScanAreaChipState {
        guard let progress else {
            return .pending
        }

        if progress.phase == .completed {
            return .completed
        }

        if area.category == progress.currentCategory {
            return .current
        }

        guard let areaIndex = selectedAreas.firstIndex(where: { $0.category == area.category }) else {
            return .pending
        }

        return areaIndex < progress.completedCategoryCount ? .completed : .pending
    }

    private func displayName(for path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

}

private struct ScanOrbitalIndicator: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.10))
                .frame(width: 76, height: 76)

            Circle()
                .stroke(.blue.opacity(0.13), lineWidth: 12)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: max(0.04, progress))
                .stroke(
                    LinearGradient(
                        colors: [.blue, .cyan, .green.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: progress)

            ProgressView()
                .controlSize(.small)
                .tint(.blue)
        }
        .frame(width: 82, height: 82)
        .accessibilityHidden(true)
    }
}

private struct ScanSignalBars: View {
    let progress: Double

    private let barCount = 5

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(barColor(for: index))
                    .frame(width: 8, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.2), value: progress)
            }
        }
        .frame(height: 44, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let clampedProgress = min(max(progress, 0.08), 1)
        let step = Double(index + 1) / Double(barCount)
        return CGFloat(12 + 28 * clampedProgress * step)
    }

    private func barColor(for index: Int) -> Color {
        switch index {
        case 0, 1:
            .blue.opacity(0.42)
        case 2, 3:
            .cyan.opacity(0.62)
        default:
            .green.opacity(0.62)
        }
    }
}

private enum ScanAreaChipState {
    case completed
    case current
    case pending

    var systemImage: String {
        switch self {
        case .completed:
            "checkmark.circle.fill"
        case .current:
            "dot.radiowaves.left.and.right"
        case .pending:
            "circle"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .completed:
            .green
        case .current:
            .blue
        case .pending:
            .secondary
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .completed:
            0.14
        case .current:
            0.16
        case .pending:
            0.08
        }
    }
}

private struct ScanAreaChip: View {
    let area: CleanupArea
    let state: ScanAreaChipState

    var body: some View {
        Label(area.title, systemImage: state.systemImage)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .foregroundStyle(state.foregroundStyle)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(state.foregroundStyle.opacity(state.backgroundOpacity), in: Capsule())
    }
}

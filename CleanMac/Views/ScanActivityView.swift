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
            activityIndicator

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
                activityIndicator
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

    private var activityIndicator: some View {
        ModernScanProgressIndicator(
            systemImage: "magnifyingglass",
            accessibilityLabel: L.t("scan.animation.title"),
            progress: progressFraction,
            size: 82
        )
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
        AnimatedScanProgressTrack(
            progress: progressFraction,
            accessibilityLabel: L.f("scan.animation.percent", progressPercent)
        )
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

private struct AnimatedScanProgressTrack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let progress: Double
    let accessibilityLabel: String

    @State private var isShimmering = false

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let filledWidth = max(8, trackWidth * min(max(progress, 0), 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filledWidth)
                    .overlay(alignment: .leading) {
                        if !reduceMotion {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.46), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 48)
                                .offset(x: isShimmering ? filledWidth : -48)
                                .animation(
                                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                                    value: isShimmering
                                )
                        }
                    }
                    .clipShape(Capsule())
                    .animation(.easeOut(duration: 0.24), value: progress)
            }
        }
        .frame(height: 8)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            isShimmering = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, _ in
            isShimmering = !reduceMotion
        }
    }
}

private struct ScanSignalBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let progress: Double

    private let barCount = 5

    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(barColor(for: index))
                    .frame(width: 8, height: barHeight(for: index))
                    .animation(
                        reduceMotion
                            ? .easeOut(duration: 0.2)
                            : .easeInOut(duration: 0.7 + Double(index) * 0.08)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.06),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 44, alignment: .bottom)
        .accessibilityHidden(true)
        .onAppear {
            isAnimating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, _ in
            isAnimating = !reduceMotion
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let clampedProgress = min(max(progress, 0.08), 1)
        let step = Double(index + 1) / Double(barCount)
        let base = CGFloat(12 + 18 * clampedProgress * step)
        guard !reduceMotion else {
            return base
        }
        let amplitude = CGFloat(7 + index * 2)
        return isAnimating ? min(44, base + amplitude) : max(10, base - amplitude * 0.45)
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

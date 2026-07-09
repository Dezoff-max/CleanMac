import CleanMacCore
import SwiftUI

struct ScanActivityView: View {
    let selectedAreas: [CleanupArea]
    let progress: CleanupScanProgress?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0)) { timeline in
            let elapsed = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            InfoPanel {
                ViewThatFits(in: .horizontal) {
                    horizontalLayout(elapsed: elapsed)
                    verticalLayout(elapsed: elapsed)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private func horizontalLayout(elapsed: TimeInterval) -> some View {
        HStack(alignment: .center, spacing: 18) {
            ScanOrbitalIndicator(
                elapsed: elapsed,
                reduceMotion: reduceMotion,
                progress: progressFraction
            )

            content(elapsed: elapsed)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScanSignalBars(elapsed: elapsed, reduceMotion: reduceMotion)
                .frame(width: 76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func verticalLayout(elapsed: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ScanOrbitalIndicator(
                    elapsed: elapsed,
                    reduceMotion: reduceMotion,
                    progress: progressFraction
                )
                header(elapsed: elapsed)
            }

            progressTrack(elapsed: elapsed)
            scanMetrics
            areaRail
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func content(elapsed: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header(elapsed: elapsed)
            progressTrack(elapsed: elapsed)
            scanMetrics
            areaRail
        }
    }

    private func header(elapsed: TimeInterval) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label(L.t("scan.animation.title"), systemImage: "sparkles")
                    .font(.headline)

                Text(phaseText(elapsed: elapsed))
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

    private func progressTrack(elapsed: TimeInterval) -> some View {
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
                    .overlay(alignment: .leading) {
                        if !reduceMotion {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.34), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 54)
                                .offset(x: shimmerOffset(elapsed: elapsed, width: filledWidth))
                        }
                    }
                    .clipShape(Capsule())
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

    private func phaseText(elapsed: TimeInterval) -> String {
        guard let progress else {
            let phases = [
                L.t("scan.animation.phase.metadata"),
                L.t("scan.animation.phase.sizes"),
                L.t("scan.animation.phase.risks"),
                L.t("scan.animation.phase.summary")
            ]
            let index = Int(elapsed / 1.15) % phases.count
            return phases[index]
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

    private func shimmerOffset(elapsed: TimeInterval, width: CGFloat) -> CGFloat {
        guard width > 54 else {
            return 0
        }
        let cycle = elapsed.truncatingRemainder(dividingBy: 1.45) / 1.45
        return CGFloat(cycle) * (width + 54) - 54
    }
}

private struct ScanOrbitalIndicator: View {
    let elapsed: TimeInterval
    let reduceMotion: Bool
    let progress: Double

    private var rotation: Angle {
        .degrees(reduceMotion ? 28 : elapsed * 135)
    }

    private var reverseRotation: Angle {
        .degrees(reduceMotion ? -16 : -elapsed * 82)
    }

    private var pulse: CGFloat {
        guard !reduceMotion else {
            return 1
        }
        return 1 + CGFloat((sin(elapsed * 2.2) + 1) * 0.035)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.10))
                .frame(width: 76, height: 76)

            Circle()
                .stroke(.blue.opacity(0.13), lineWidth: 12)
                .frame(width: 60, height: 60)
                .scaleEffect(pulse)

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

            Circle()
                .trim(from: 0.04, to: 0.38)
                .stroke(
                    AngularGradient(
                        colors: [.blue.opacity(0.12), .cyan, .green.opacity(0.82)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 54, height: 54)
                .rotationEffect(rotation)

            Circle()
                .trim(from: 0.62, to: 0.78)
                .stroke(.blue.opacity(0.34), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(reverseRotation)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 82, height: 82)
        .accessibilityHidden(true)
    }
}

private struct ScanSignalBars: View {
    let elapsed: TimeInterval
    let reduceMotion: Bool

    private let barCount = 5

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(barColor(for: index))
                    .frame(width: 8, height: barHeight(for: index))
            }
        }
        .frame(height: 44, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard !reduceMotion else {
            return CGFloat(16 + index * 4)
        }
        let wave = (sin(elapsed * 3.4 + Double(index) * 0.82) + 1) / 2
        return CGFloat(12 + wave * 28)
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

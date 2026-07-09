import SwiftUI

struct ScanActivityView: View {
    let selectedAreas: [CleanupArea]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var visibleAreas: [CleanupArea] {
        Array(selectedAreas.prefix(4))
    }

    private var hiddenAreaCount: Int {
        max(0, selectedAreas.count - visibleAreas.count)
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
        HStack(alignment: .center, spacing: 16) {
            ScanOrbitalIndicator(elapsed: elapsed, reduceMotion: reduceMotion)

            content(elapsed: elapsed)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScanSignalBars(elapsed: elapsed, reduceMotion: reduceMotion)
                .frame(width: 76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func verticalLayout(elapsed: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ScanOrbitalIndicator(elapsed: elapsed, reduceMotion: reduceMotion)
                content(elapsed: elapsed)
            }

            ScanSignalBars(elapsed: elapsed, reduceMotion: reduceMotion)
                .frame(maxWidth: 130, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func content(elapsed: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Label(L.t("scan.animation.title"), systemImage: "sparkles")
                    .font(.headline)

                Text(phaseText(elapsed: elapsed))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(visibleAreas) { area in
                    ScanAreaChip(area: area)
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
    }

    private func phaseText(elapsed: TimeInterval) -> String {
        let phases = [
            L.t("scan.animation.phase.metadata"),
            L.t("scan.animation.phase.sizes"),
            L.t("scan.animation.phase.risks"),
            L.t("scan.animation.phase.summary")
        ]
        let index = Int(elapsed / 1.15) % phases.count
        return phases[index]
    }
}

private struct ScanOrbitalIndicator: View {
    let elapsed: TimeInterval
    let reduceMotion: Bool

    private var rotation: Angle {
        .degrees(reduceMotion ? 28 : elapsed * 135)
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
                .fill(.blue.opacity(0.11))
                .frame(width: 72, height: 72)

            Circle()
                .stroke(.blue.opacity(0.16), lineWidth: 10)
                .frame(width: 58, height: 58)
                .scaleEffect(pulse)

            Circle()
                .trim(from: 0.04, to: 0.38)
                .stroke(
                    AngularGradient(
                        colors: [.blue.opacity(0.15), .cyan, .green.opacity(0.82)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 58, height: 58)
                .rotationEffect(rotation)

            Circle()
                .trim(from: 0.62, to: 0.78)
                .stroke(.blue.opacity(0.34), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 46, height: 46)
                .rotationEffect(-rotation)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 78, height: 78)
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

private struct ScanAreaChip: View {
    let area: CleanupArea

    var body: some View {
        Label(area.title, systemImage: area.systemImage)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
    }
}

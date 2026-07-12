import SwiftUI

struct DiskAnalysisProgressIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0.15 : timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees(phase.truncatingRemainder(dividingBy: 2.4) / 2.4 * 360)
            let pulse = reduceMotion ? 1.0 : 0.92 + (sin(phase * 3.2) + 1) * 0.04

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.cyan.opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 30
                        )
                    )
                    .scaleEffect(pulse)

                Circle()
                    .stroke(Color.accentColor.opacity(0.14), lineWidth: 5)

                Circle()
                    .trim(from: 0.06, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .cyan, .purple, .blue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(rotation)
                    .shadow(color: Color.accentColor.opacity(0.32), radius: 5)

                Circle()
                    .trim(from: 0.08, to: 0.38)
                    .stroke(
                        Color.white.opacity(0.8),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-rotation.degrees * 0.72))

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .scaleEffect(pulse)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("disk.scanning.title"))
    }
}

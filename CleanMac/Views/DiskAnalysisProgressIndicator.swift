import SwiftUI

struct ModernScanProgressIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let systemImage: String
    let accessibilityLabel: String
    let progress: Double?
    let size: CGFloat

    @State private var isRotating = false
    @State private var isPulsing = false

    init(
        systemImage: String,
        accessibilityLabel: String,
        progress: Double? = nil,
        size: CGFloat = 58
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.progress = progress
        self.size = size
    }

    private var clampedProgress: Double? {
        progress.map { min(max($0, 0.035), 1) }
    }

    private var lineWidth: CGFloat {
        max(4, size * 0.075)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.22),
                            Color.cyan.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.52
                    )
                )
                .scaleEffect(isPulsing ? 1.04 : 0.94)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            Circle()
                .stroke(Color.accentColor.opacity(0.16), lineWidth: lineWidth)
                .padding(size * 0.10)

            if let clampedProgress {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .padding(size * 0.10)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.24), value: clampedProgress)
            }

            Circle()
                .trim(from: 0.04, to: 0.66)
                .stroke(
                    AngularGradient(
                        colors: [.blue.opacity(0.24), .cyan, .mint, .blue.opacity(0.24)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: max(2.5, size * 0.052), lineCap: .round)
                )
                .padding(size * 0.19)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .shadow(color: Color.cyan.opacity(0.28), radius: size * 0.08)
                .animation(
                    reduceMotion
                        ? nil
                        : .linear(duration: 2.2).repeatForever(autoreverses: false),
                    value: isRotating
                )

            Circle()
                .trim(from: 0.08, to: 0.31)
                .stroke(
                    Color.primary.opacity(0.58),
                    style: StrokeStyle(lineWidth: max(1.5, size * 0.028), lineCap: .round)
                )
                .padding(size * 0.27)
                .rotationEffect(.degrees(isRotating ? -360 : 0))
                .animation(
                    reduceMotion
                        ? nil
                        : .linear(duration: 1.65).repeatForever(autoreverses: false),
                    value: isRotating
                )

            Image(systemName: systemImage)
                .font(.system(size: size * 0.27, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .scaleEffect(isPulsing ? 1.04 : 0.96)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: reduceMotion) { _, _ in
            updateAnimationState()
        }
    }

    private func updateAnimationState() {
        isRotating = !reduceMotion
        isPulsing = !reduceMotion
    }
}

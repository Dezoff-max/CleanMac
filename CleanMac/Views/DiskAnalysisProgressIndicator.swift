import SwiftUI

struct DiskAnalysisProgressIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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

            Circle()
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 5)

            if reduceMotion {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            } else {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.accentColor)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("disk.scanning.title"))
    }
}

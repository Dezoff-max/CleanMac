import AppKit
import CleanMacCore
import QuickLookThumbnailing
import SwiftUI

enum ShredderAnimationPhase: Equatable {
    case preparing
    case feeding
    case overwriting
    case finalizing
    case success
    case failure

    var isWorking: Bool {
        self == .overwriting || self == .finalizing
    }

    var releasesFragments: Bool {
        switch self {
        case .overwriting, .finalizing, .success, .failure:
            true
        case .preparing, .feeding:
            false
        }
    }
}

struct ShredderAnimationSession: Identifiable {
    let id = UUID()
    let candidateID: String
    let fileName: String
    let thumbnail: NSImage
    let currentIndex: Int
    let totalCount: Int
    var phase: ShredderAnimationPhase
    var progress: Double
}

@MainActor
enum ShredderPreviewService {
    static func preview(for candidate: SecureDeletionCandidate) async -> NSImage {
        let url = URL(fileURLWithPath: candidate.path)
        let fallback = NSWorkspace.shared.icon(forFile: candidate.path)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 480, height: 320),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: [.thumbnail, .icon]
        )

        guard let representation = try? await QLThumbnailGenerator.shared
            .generateBestRepresentation(for: request) else {
            return fallback
        }
        return representation.nsImage
    }
}

struct ShredderAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let session: ShredderAnimationSession
    let palette: NeoShredderPalette

    @State private var bladesRotated = false

    private let stripCount = 20

    var body: some View {
        VStack(spacing: 14) {
            statusHeader
            animationStage
            progressFooter
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            palette.surface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(stageTint.opacity(0.52))
        }
        .shadow(color: palette.shadow, radius: 18, y: 10)
        .shadow(color: stageTint.opacity(session.phase.isWorking ? 0.24 : 0.12), radius: 22)
        .task(id: session.phase) {
            bladesRotated = false
            guard session.phase.isWorking, !reduceMotion else { return }
            await Task.yield()
            withAnimation(.linear(duration: 0.72).repeatForever(autoreverses: false)) {
                bladesRotated = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L.f(
            "shredder.animation.accessibility",
            session.fileName,
            Int((clampedProgress * 100).rounded())
        ))
    }

    private var statusHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(stageTint.opacity(0.12))
                Image(systemName: phaseIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(stageTint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(phaseTitle)
                    .font(.headline.monospaced())
                    .foregroundStyle(palette.textPrimary)
                Text(session.fileName)
                    .font(.caption.monospaced())
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)

            Text(L.f(
                "shredder.animation.position",
                session.currentIndex,
                session.totalCount
            ))
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(palette.textMuted)
        }
    }

    private var animationStage: some View {
        GeometryReader { proxy in
            let stageWidth = proxy.size.width
            let previewSize = CGSize(
                width: min(188, max(148, stageWidth * 0.28)),
                height: 116
            )
            let machineWidth = min(390, max(280, stageWidth * 0.58))

            ZStack {
                stageBackdrop
                fragmentBin(width: machineWidth * 0.82)
                    .position(x: stageWidth / 2, y: 235)

                fragmentGroup(size: previewSize)
                    .position(x: stageWidth / 2, y: 116)

                filePreview(size: previewSize)
                    .position(x: stageWidth / 2, y: previewY)
                    .opacity(previewOpacity)
                    .scaleEffect(previewScale)
                    .animation(previewAnimation, value: session.phase)

                machineBody(width: machineWidth)
                    .position(x: stageWidth / 2, y: 92)

                outcomeMark
                    .position(x: stageWidth / 2, y: 178)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .frame(height: 276)
    }

    private var stageBackdrop: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.inset.opacity(0.6))

            VStack(spacing: 22) {
                ForEach(0..<10, id: \.self) { _ in
                    Rectangle()
                        .fill(palette.line.opacity(0.38))
                        .frame(height: 1)
                }
            }

            LinearGradient(
                colors: [.clear, stageTint.opacity(0.06), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func machineBody(width: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.textPrimary.opacity(0.92), palette.textPrimary.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.34), radius: 12, y: 8)

            VStack(spacing: 9) {
                HStack(spacing: 9) {
                    Image(systemName: "gearshape.2.fill")
                        .foregroundStyle(stageTint)
                        .rotationEffect(.degrees(bladesRotated ? 360 : 0))

                    Text(L.t("shredder.animation.machine"))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.84))

                    Spacer(minLength: 8)

                    Circle()
                        .fill(stageTint)
                        .frame(width: 7, height: 7)
                        .shadow(color: stageTint, radius: session.phase.isWorking ? 7 : 2)
                }

                Capsule()
                    .fill(Color.black.opacity(0.78))
                    .frame(height: 10)
                    .overlay {
                        Capsule()
                            .strokeBorder(stageTint.opacity(0.52), lineWidth: 1)
                    }
                    .shadow(color: stageTint.opacity(0.3), radius: 6)
            }
            .padding(.horizontal, 18)
        }
        .frame(width: width, height: 78)
    }

    private func fragmentBin(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.surface.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(palette.line)
                }

            Capsule()
                .fill(stageTint.opacity(0.38))
                .frame(width: width * 0.72, height: 3)
                .padding(.top, 8)
        }
        .frame(width: width, height: 68)
    }

    private func filePreview(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))

            Image(nsImage: session.thumbnail)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.66)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(session.fileName)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(8)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.68), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 10, y: 7)
    }

    private func fragmentGroup(size: CGSize) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<stripCount, id: \.self) { index in
                fragment(index: index, size: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(session.phase.releasesFragments ? 1 : 0)
    }

    private func fragment(index: Int, size: CGSize) -> some View {
        let stripWidth = size.width / CGFloat(stripCount)
        let stripCenter = stripWidth * (CGFloat(index) + 0.5)
        let drift = reduceMotion ? 0 : fragmentDrift(index)
        let fall = reduceMotion ? 12 : fragmentFall(index)
        let rotation = reduceMotion ? 0 : fragmentRotation(index)
        let isReleased = session.phase.releasesFragments
        let isGone = session.phase == .success

        return filePreview(size: size)
            .offset(x: size.width / 2 - stripCenter)
            .frame(width: stripWidth + 0.35, height: size.height)
            .clipped()
            .offset(
                x: isReleased ? drift : 0,
                y: isReleased ? fall + (isGone ? 22 : 0) : 0
            )
            .rotationEffect(.degrees(isReleased ? rotation : 0))
            .opacity(isGone ? 0 : (session.phase == .failure ? 0.48 : 0.96))
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.18)
                    : .spring(response: 0.74, dampingFraction: 0.76)
                        .delay(Double(index) * 0.018),
                value: session.phase
            )
    }

    @ViewBuilder
    private var outcomeMark: some View {
        if session.phase == .success || session.phase == .failure {
            ZStack {
                Circle()
                    .fill(palette.surface.opacity(0.92))
                    .overlay {
                        Circle().strokeBorder(stageTint.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: stageTint.opacity(0.34), radius: 18)

                Image(systemName: session.phase == .success ? "checkmark" : "exclamationmark")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(stageTint)
            }
            .frame(width: 58, height: 58)
            .transition(.scale(scale: reduceMotion ? 1 : 0.72).combined(with: .opacity))
        }
    }

    private var progressFooter: some View {
        VStack(spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.inset)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [stageTint.opacity(0.72), stageTint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * clampedProgress))
                        .shadow(color: stageTint.opacity(0.45), radius: 6)
                }
            }
            .frame(height: 8)
            .animation(.easeOut(duration: reduceMotion ? 0.05 : 0.16), value: clampedProgress)

            HStack {
                Text(phaseDetail)
                    .font(.caption.monospaced())
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Text("\(Int((clampedProgress * 100).rounded()))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(stageTint)
            }
        }
    }

    private var previewY: CGFloat {
        switch session.phase {
        case .preparing:
            -78
        case .feeding:
            45
        case .overwriting, .finalizing, .success, .failure:
            72
        }
    }

    private var previewOpacity: Double {
        switch session.phase {
        case .preparing:
            0
        case .feeding:
            1
        case .overwriting, .finalizing, .success, .failure:
            0
        }
    }

    private var previewScale: CGFloat {
        session.phase == .preparing ? 0.94 : 1
    }

    private var previewAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.18)
            : .spring(response: 0.68, dampingFraction: 0.82)
    }

    private var clampedProgress: Double {
        min(1, max(0, session.progress))
    }

    private var stageTint: Color {
        switch session.phase {
        case .failure:
            palette.danger
        case .success:
            palette.success
        default:
            palette.cyan
        }
    }

    private var phaseIcon: String {
        switch session.phase {
        case .preparing: "doc.richtext"
        case .feeding: "arrow.down.to.line.compact"
        case .overwriting: "waveform.path.ecg"
        case .finalizing: "lock.rotation"
        case .success: "checkmark.circle.fill"
        case .failure: "exclamationmark.triangle.fill"
        }
    }

    private var phaseTitle: String {
        switch session.phase {
        case .preparing: L.t("shredder.animation.preparing")
        case .feeding: L.t("shredder.animation.feeding")
        case .overwriting: L.t("shredder.animation.overwriting")
        case .finalizing: L.t("shredder.animation.finalizing")
        case .success: L.t("shredder.animation.success")
        case .failure: L.t("shredder.animation.failure")
        }
    }

    private var phaseDetail: String {
        switch session.phase {
        case .preparing: L.t("shredder.animation.detail.preparing")
        case .feeding: L.t("shredder.animation.detail.feeding")
        case .overwriting: L.t("shredder.animation.detail.overwriting")
        case .finalizing: L.t("shredder.animation.detail.finalizing")
        case .success: L.t("shredder.animation.detail.success")
        case .failure: L.t("shredder.animation.detail.failure")
        }
    }

    private func fragmentDrift(_ index: Int) -> CGFloat {
        CGFloat((index * 37) % 19 - 9) * 1.7
    }

    private func fragmentFall(_ index: Int) -> CGFloat {
        CGFloat(82 + (index * 23) % 42)
    }

    private func fragmentRotation(_ index: Int) -> Double {
        Double((index * 31) % 17 - 8) * 1.8
    }
}

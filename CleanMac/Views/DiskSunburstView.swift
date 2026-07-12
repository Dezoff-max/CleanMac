import CleanMacCore
import SwiftUI

struct DiskSunburstView: View {
    let node: DiskAnalysisNode
    let nodeTitle: (DiskAnalysisNode) -> String
    let onOpenNode: (DiskAnalysisNode) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveredSegmentID: String?
    @State private var hoverLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            let layout = DiskSunburstLayout(node: node, size: geometry.size)
            let hoveredSegment = layout.segments.first { $0.id == hoveredSegmentID }
            let centerAnchor = UnitPoint(
                x: layout.center.x / max(geometry.size.width, 1),
                y: layout.center.y / max(geometry.size.height, 1)
            )

            ZStack {
                Canvas { context, canvasSize in
                    for segment in layout.segments {
                        let path = DiskSunburstSegmentShape(segment: segment, center: layout.center)
                            .path(in: CGRect(origin: .zero, size: canvasSize))
                        context.fill(
                            path,
                            with: .color(
                                DiskSunburstPalette.color(index: segment.branchIndex)
                                    .opacity(max(0.48, 0.92 - Double(segment.depth) * 0.08))
                            )
                        )
                        context.stroke(path, with: .color(.black.opacity(0.24)), lineWidth: 0.7)
                    }
                }

                if let hoveredSegment {
                    let shape = DiskSunburstSegmentShape(segment: hoveredSegment, center: layout.center)
                    shape
                        .fill(
                            DiskSunburstPalette.color(index: hoveredSegment.branchIndex)
                                .opacity(0.98)
                        )
                        .overlay {
                            shape.stroke(Color.white.opacity(0.9), lineWidth: 1.4)
                        }
                        .scaleEffect(1.045, anchor: centerAnchor)
                        .shadow(
                            color: DiskSunburstPalette.color(index: hoveredSegment.branchIndex).opacity(0.42),
                            radius: 10
                        )
                        .transition(
                            .opacity.combined(with: .scale(scale: 0.97, anchor: centerAnchor))
                        )
                        .zIndex(2)
                }

                Circle()
                    .fill(.regularMaterial)
                    .overlay {
                        Circle()
                            .strokeBorder(.separator.opacity(0.8), lineWidth: 1)
                    }
                    .frame(width: layout.innerRadius * 1.72, height: layout.innerRadius * 1.72)
                    .position(layout.center)
                    .zIndex(3)

                VStack(spacing: 3) {
                    Text(nodeTitle(node))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(CleanMacFormatters.bytes(node.sizeBytes))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(width: layout.innerRadius * 1.45)
                .position(layout.center)
                .zIndex(4)

                if let hoveredSegment, let hoverLocation {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(nodeTitle(hoveredSegment.node))
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(gigabytesText(hoveredSegment.node.sizeBytes))
                            .font(.caption2.monospacedDigit().weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                DiskSunburstPalette.color(index: hoveredSegment.branchIndex).opacity(0.55)
                            )
                    }
                    .shadow(color: .black.opacity(0.18), radius: 9, y: 4)
                    .position(tooltipPosition(for: hoverLocation, in: geometry.size))
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .allowsHitTesting(false)
                    .zIndex(5)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let segment = layout.segment(at: location)
                    hoverLocation = location
                    if hoveredSegmentID != segment?.id {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.76)) {
                            hoveredSegmentID = segment?.id
                        }
                    }
                case .ended:
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.14)) {
                        hoveredSegmentID = nil
                        hoverLocation = nil
                    }
                }
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard let selected = layout.segment(at: value.location) else {
                            return
                        }
                        onOpenNode(selected.node)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L.f(
                "disk.map.accessibility",
                nodeTitle(node),
                CleanMacFormatters.bytes(node.sizeBytes)
            ))
        }
    }

    private func gigabytesText(_ bytes: Int64) -> String {
        let gigabytes = Double(max(0, bytes)) / 1_073_741_824
        return L.f("disk.map.tooltip.size", gigabytes)
    }

    private func tooltipPosition(for location: CGPoint, in size: CGSize) -> CGPoint {
        let preferredX = location.x + 82
        let preferredY = location.y - 42
        return CGPoint(
            x: min(max(preferredX, 86), max(86, size.width - 86)),
            y: min(max(preferredY, 34), max(34, size.height - 34))
        )
    }
}

private struct DiskSunburstSegmentShape: Shape {
    let segment: DiskSunburstSegment
    let center: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let innerStart = point(radius: segment.innerRadius, angle: segment.startAngle)
        let innerEnd = point(radius: segment.innerRadius, angle: segment.endAngle)

        path.move(to: innerStart)
        path.addArc(
            center: center,
            radius: segment.outerRadius,
            startAngle: .radians(segment.startAngle),
            endAngle: .radians(segment.endAngle),
            clockwise: false
        )
        path.addLine(to: innerEnd)
        path.addArc(
            center: center,
            radius: segment.innerRadius,
            startAngle: .radians(segment.endAngle),
            endAngle: .radians(segment.startAngle),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }

    private func point(radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

enum DiskSunburstPalette {
    private static let colors: [Color] = [
        Color(red: 0.18, green: 0.72, blue: 0.98),
        Color(red: 0.72, green: 0.94, blue: 0.18),
        Color(red: 0.96, green: 0.33, blue: 0.55),
        Color(red: 0.75, green: 0.25, blue: 0.98),
        Color(red: 1.00, green: 0.72, blue: 0.25),
        Color(red: 0.24, green: 0.90, blue: 0.60),
        Color(red: 0.98, green: 0.48, blue: 0.24),
        Color(red: 0.38, green: 0.47, blue: 0.98),
        Color(red: 0.96, green: 0.90, blue: 0.25),
        Color(red: 0.20, green: 0.86, blue: 0.86)
    ]

    static func color(index: Int) -> Color {
        colors[index % colors.count]
    }
}

private struct DiskSunburstLayout {
    let center: CGPoint
    let innerRadius: CGFloat
    let segments: [DiskSunburstSegment]

    private let startAngle = Double.pi * 0.75
    private let endAngle = Double.pi * 2.25

    init(node: DiskAnalysisNode, size: CGSize) {
        let radius = max(80, min(size.width, size.height) * 0.44)
        self.center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)
        self.innerRadius = max(34, radius * 0.2)

        let maximumDepth = max(1, min(5, Self.maximumDepth(in: node)))
        let ringWidth = (radius - innerRadius) / CGFloat(maximumDepth)
        var builtSegments: [DiskSunburstSegment] = []

        Self.appendChildren(
            of: node,
            startAngle: startAngle,
            endAngle: endAngle,
            depth: 0,
            branchIndex: nil,
            maximumDepth: maximumDepth,
            innerRadius: innerRadius,
            ringWidth: ringWidth,
            segments: &builtSegments
        )

        self.segments = builtSegments
    }

    func segment(at location: CGPoint) -> DiskSunburstSegment? {
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        let radius = hypot(deltaX, deltaY)
        var angle = atan2(deltaY, deltaX)
        if angle < 0 {
            angle += Double.pi * 2
        }
        while angle < startAngle {
            angle += Double.pi * 2
        }

        return segments.reversed().first { segment in
            radius >= segment.innerRadius
                && radius <= segment.outerRadius
                && angle >= segment.startAngle
                && angle <= segment.endAngle
        }
    }

    private static func appendChildren(
        of node: DiskAnalysisNode,
        startAngle: Double,
        endAngle: Double,
        depth: Int,
        branchIndex: Int?,
        maximumDepth: Int,
        innerRadius: CGFloat,
        ringWidth: CGFloat,
        segments: inout [DiskSunburstSegment]
    ) {
        guard depth < maximumDepth, !node.children.isEmpty else {
            return
        }

        let visibleChildren = node.children.filter { $0.sizeBytes > 0 }
        let totalSize = visibleChildren.reduce(Int64(0)) { $0 + $1.sizeBytes }
        guard totalSize > 0 else {
            return
        }

        var cursor = startAngle
        let availableAngle = endAngle - startAngle

        for (index, child) in visibleChildren.enumerated() {
            let fraction = Double(child.sizeBytes) / Double(totalSize)
            let rawEnd = cursor + availableAngle * fraction
            let gap = min(0.012, max(0, (rawEnd - cursor) * 0.08))
            let segmentStart = cursor + gap / 2
            let segmentEnd = rawEnd - gap / 2
            let resolvedBranchIndex = branchIndex ?? index

            if segmentEnd - segmentStart > 0.002 {
                segments.append(DiskSunburstSegment(
                    node: child,
                    depth: depth,
                    branchIndex: resolvedBranchIndex,
                    startAngle: segmentStart,
                    endAngle: segmentEnd,
                    innerRadius: innerRadius + CGFloat(depth) * ringWidth,
                    outerRadius: innerRadius + CGFloat(depth + 1) * ringWidth
                ))

                appendChildren(
                    of: child,
                    startAngle: cursor,
                    endAngle: rawEnd,
                    depth: depth + 1,
                    branchIndex: resolvedBranchIndex,
                    maximumDepth: maximumDepth,
                    innerRadius: innerRadius,
                    ringWidth: ringWidth,
                    segments: &segments
                )
            }

            cursor = rawEnd
        }
    }

    private static func maximumDepth(in node: DiskAnalysisNode) -> Int {
        guard !node.children.isEmpty else {
            return 1
        }

        var deepestChild = 0
        for child in node.children {
            deepestChild = max(deepestChild, maximumDepth(in: child))
        }
        return 1 + deepestChild
    }
}

private struct DiskSunburstSegment {
    let node: DiskAnalysisNode
    let depth: Int
    let branchIndex: Int
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    var id: String {
        "\(node.id)#\(depth)#\(startAngle)"
    }
}

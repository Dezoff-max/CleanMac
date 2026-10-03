import CleanMacCore
import SwiftUI

/// Reads the same volume capacity as the menu bar. "Available" already includes
/// macOS-reclaimable capacity; it is never added to free space a second time.
struct DashboardStorageCard: View {
    let onOpenAnalysis: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // View values are recreated during layout. Never start a filesystem query
    // from a State initial value, even when SwiftUI retains the old state.
    @State private var snapshot = StatusDiskSnapshot.unavailable
    @State private var refreshGeneration = 0

    private struct RefreshID: Equatable {
        let scenePhase: ScenePhase
        let generation: Int
    }

    private var capacity: DiskSpaceBreakdown { snapshot.capacity }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(snapshot.volumeName ?? L.t("dashboard.storage.title"), systemImage: "internaldrive")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 4)

                Button {
                    refreshGeneration &+= 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderless)
                .help(L.t("dashboard.storage.refresh"))
                .accessibilityLabel(L.t("dashboard.storage.refresh"))
            }

            if capacity.isAvailable {
                HStack(alignment: .center, spacing: 15) {
                    storageRing
                        .frame(width: 118, height: 118)

                    VStack(alignment: .leading, spacing: 12) {
                        legendItem("dashboard.storage.used", bytes: capacity.usedBytes, tint: .accentColor)
                        if let reclaimableBytes = capacity.reclaimableBytes {
                            legendItem("dashboard.storage.reclaimable", bytes: reclaimableBytes, tint: .purple)
                        }
                        legendItem(
                            capacity.reclaimableBytes == nil ? "dashboard.storage.available" : "dashboard.storage.free",
                            bytes: capacity.displayedFreeBytes,
                            tint: .teal
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(L.f("dashboard.storage.total", CleanMacFormatters.bytes(capacity.totalBytes)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    Button(action: onOpenAnalysis) {
                        Label(L.t("dashboard.storage.analyze"), systemImage: "arrow.right")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                }

                if snapshot.isLowSpace {
                    Label(L.t("status.lowDisk.title"), systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            } else {
                Label(L.t("dashboard.storage.unavailable"), systemImage: "internaldrive")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 118, alignment: .center)
            }

            Text(L.t("dashboard.storage.explanation"))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task(id: RefreshID(scenePhase: scenePhase, generation: refreshGeneration)) {
            guard scenePhase == .active else { return }
            await refreshWhileVisible()
        }
    }

    private var storageRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: 10)

            ringSegment(from: 0, to: capacity.usedFraction, tint: .accentColor)
            ringSegment(
                from: capacity.usedFraction,
                to: 1 - freeFraction,
                tint: .purple
            )
            ringSegment(from: 1 - freeFraction, to: 1, tint: .teal)

            VStack(spacing: 4) {
                Text(CleanMacFormatters.bytes(capacity.availableBytes))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                Text(L.t("dashboard.storage.available"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
        }
        .padding(6)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: capacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("dashboard.storage.available"))
        .accessibilityValue(L.f(
            "dashboard.storage.accessibility",
            CleanMacFormatters.bytes(capacity.availableBytes),
            CleanMacFormatters.bytes(capacity.totalBytes)
        ))
    }

    private var freeFraction: Double {
        guard capacity.totalBytes > 0 else { return 0 }
        return Double(capacity.displayedFreeBytes) / Double(capacity.totalBytes)
    }

    private func ringSegment(from start: Double, to end: Double, tint: Color) -> some View {
        Circle()
            .trim(from: min(max(start, 0), 1), to: min(max(end, start), 1))
            .stroke(tint.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }

    private func legendItem(_ key: String, bytes: Int64, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
                .padding(.top, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L.t(key))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(CleanMacFormatters.bytes(bytes))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func refreshWhileVisible() async {
        while !Task.isCancelled {
            do {
                let refreshed = try await StatusDiskSnapshotReader.shared.snapshot(forceRefresh: true)
                try Task.checkCancellation()
                snapshot = refreshed
                try await Task.sleep(for: .seconds(30))
            } catch {
                return
            }
        }
    }
}

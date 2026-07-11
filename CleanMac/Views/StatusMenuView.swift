import AppKit
import SwiftUI

struct StatusMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(CleanMacPreferenceKeys.lastScanItemCount) private var lastScanItemCount = 0
    @AppStorage(CleanMacPreferenceKeys.lastScanBytes) private var lastScanBytes = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanTimestamp) private var lastScanTimestamp = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanSource) private var lastScanSource = CleanMacScanSource.manual.rawValue
    @AppStorage(CleanMacPreferenceKeys.autoScanEnabled) private var autoScanEnabled = false
    @AppStorage(CleanMacPreferenceKeys.scanInProgress) private var scanInProgress = false
    @State private var diskUsage = DiskUsageSnapshot.current()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            DiskUsagePanel(snapshot: diskUsage)

            LastScanPanel(
                itemCount: lastScanItemCount,
                bytes: lastScanBytes,
                timestamp: lastScanTimestamp,
                source: CleanMacScanSource(rawValue: lastScanSource) ?? .manual,
                isScanning: scanInProgress,
                isAutoScanEnabled: autoScanEnabled
            )

            HStack(spacing: 8) {
                StatusMenuActionButton(
                    title: L.t("menu.open.short"),
                    systemImage: "macwindow",
                    isPrimary: true
                ) {
                    MainWindowController.show(openWindow: openWindow)
                }

                StatusMenuActionButton(
                    title: L.t("menu.quit"),
                    systemImage: "power",
                    isPrimary: false
                ) {
                    NSApp.terminate(nil)
                }
            }
        }
        .onAppear {
            diskUsage = DiskUsageSnapshot.current()
        }
        .padding(18)
        .frame(width: 330)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.08), lineWidth: 1)
                }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("CleanMac")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(scanInProgress ? L.t("status.scanning") : L.t("status.idle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(scanInProgress ? Color.accentColor : Color.secondary)
            }

            Spacer()
        }
    }
}

private struct DiskUsagePanel: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DiskUsageSnapshot

    private var usedPercent: Int {
        Int((snapshot.usedFraction * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(snapshot.volumeName ?? L.t("status.disk.defaultName"), systemImage: "internaldrive")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Text(L.f("status.disk.percent", usedPercent))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 14) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(usedPercent)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Text(L.t("status.disk.usedLabel"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(CleanMacFormatters.bytes(snapshot.freeBytes))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(L.t("status.disk.freeLabel"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            DiskUsageBar(fraction: snapshot.usedFraction, tint: diskTint)

            Text(L.f(
                "status.disk.usedOfTotal",
                CleanMacFormatters.bytes(snapshot.usedBytes),
                CleanMacFormatters.bytes(snapshot.totalBytes)
            ))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(14)
        .background(
            sectionFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.06), lineWidth: 1)
        }
    }

    private var diskTint: Color {
        if snapshot.usedFraction >= 0.9 {
            return .red
        }
        if snapshot.usedFraction >= 0.75 {
            return .orange
        }
        return .accentColor
    }

    private var sectionFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.58)
    }
}

private struct LastScanPanel: View {
    @Environment(\.colorScheme) private var colorScheme

    let itemCount: Int
    let bytes: Double
    let timestamp: Double
    let source: CleanMacScanSource
    let isScanning: Bool
    let isAutoScanEnabled: Bool

    private var hasScan: Bool {
        timestamp > 0
    }

    private var nextRunDate: Date {
        CleanMacScanSchedule.nextRunDate()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(L.t("status.lastScan.title"), systemImage: "doc.text.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                if isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.65)
                }
            }

            if isScanning {
                Label(L.t("status.autoScan.running"), systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tint)
            }

            if hasScan {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.f("status.lastScan.summary", itemCount, CleanMacFormatters.bytes(Int64(bytes))))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: 6) {
                        Text(source == .scheduled ? L.t("status.lastScan.scheduled") : L.t("status.lastScan.manual"))
                        Text("·")
                        Text(CleanMacFormatters.relativeDate(Date(timeIntervalSince1970: timestamp)))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            } else {
                Text(L.t("status.lastScan.empty"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isAutoScanEnabled {
                Text(L.f(
                    "status.autoScan.next",
                    CleanMacFormatters.time(nextRunDate)
                ))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .background(
            sectionFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.06), lineWidth: 1)
        }
    }

    private var sectionFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.58)
    }
}

private struct DiskUsageBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(proxy.size.width * CGFloat(fraction), fraction > 0 ? 8 : 0))
            }
        }
        .frame(height: 8)
    }
}

private struct StatusMenuActionButton: View {
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(isPrimary ? Color.white : Color.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 10)
                .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var backgroundStyle: some ShapeStyle {
        isPrimary ? Color.accentColor : Color.primary.opacity(0.08)
    }
}

private struct DiskUsageSnapshot: Equatable {
    let volumeName: String?
    let totalBytes: Int64
    let freeBytes: Int64

    var usedBytes: Int64 {
        max(totalBytes - freeBytes, 0)
    }

    var usedFraction: Double {
        guard totalBytes > 0 else {
            return 0
        }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    static func current() -> DiskUsageSnapshot {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let attributes = (try? FileManager.default.attributesOfFileSystem(forPath: homeURL.path)) ?? [:]
        let resourceValues = try? homeURL.resourceValues(forKeys: [
            .volumeLocalizedNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])

        let resourceTotalBytes = Int64(resourceValues?.volumeTotalCapacity ?? 0)
        let systemTotalBytes = numberValue(attributes[.systemSize])
        let totalBytes = resourceTotalBytes > 0 ? resourceTotalBytes : systemTotalBytes

        let importantUsageBytes = resourceValues?.volumeAvailableCapacityForImportantUsage ?? 0
        let availableBytes = Int64(resourceValues?.volumeAvailableCapacity ?? 0)
        let systemFreeBytes = numberValue(attributes[.systemFreeSize])
        let freeBytes = if importantUsageBytes > 0 {
            importantUsageBytes
        } else if availableBytes > 0 {
            availableBytes
        } else {
            systemFreeBytes
        }

        return DiskUsageSnapshot(
            volumeName: resourceValues?.volumeLocalizedName,
            totalBytes: totalBytes,
            freeBytes: min(freeBytes, totalBytes)
        )
    }

    private static func numberValue(_ value: Any?) -> Int64 {
        if let number = value as? NSNumber {
            return max(number.int64Value, 0)
        }
        if let intValue = value as? Int {
            return max(Int64(intValue), 0)
        }
        if let int64Value = value as? Int64 {
            return max(int64Value, 0)
        }
        return 0
    }
}

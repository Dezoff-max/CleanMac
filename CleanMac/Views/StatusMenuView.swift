import AppKit
import SwiftUI

struct StatusMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage(CleanMacPreferenceKeys.lastScanItemCount) private var lastScanItemCount = 0
    @AppStorage(CleanMacPreferenceKeys.lastScanBytes) private var lastScanBytes = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanTimestamp) private var lastScanTimestamp = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanSource) private var lastScanSource = CleanMacScanSource.manual.rawValue
    @AppStorage(CleanMacPreferenceKeys.autoScanEnabled) private var autoScanEnabled = false
    @AppStorage(CleanMacPreferenceKeys.scanInProgress) private var scanInProgress = false
    @State private var diskUsage = DiskUsageSnapshot.current()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image("BrandIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("CleanMac")
                        .font(.headline)
                    Text(scanInProgress ? L.t("status.scanning") : L.t("status.idle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            DiskUsagePanel(snapshot: diskUsage)

            LastScanPanel(
                itemCount: lastScanItemCount,
                bytes: lastScanBytes,
                timestamp: lastScanTimestamp,
                source: CleanMacScanSource(rawValue: lastScanSource) ?? .manual,
                isScanning: scanInProgress,
                isAutoScanEnabled: autoScanEnabled
            )

            Divider()

            Button {
                MainWindowController.show(openWindow: openWindow)
            } label: {
                Label(L.t("menu.open"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Label(L.t("menu.quit"), systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            diskUsage = DiskUsageSnapshot.current()
        }
        .padding(16)
        .frame(width: 300)
    }
}

private struct DiskUsagePanel: View {
    let snapshot: DiskUsageSnapshot

    private var usedPercent: Int {
        Int((snapshot.usedFraction * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(snapshot.volumeName ?? L.t("status.disk.defaultName"), systemImage: "internaldrive")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Text(L.f("status.disk.percent", usedPercent))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: snapshot.usedFraction)
                .progressViewStyle(.linear)
                .tint(diskTint)

            Text(L.f(
                "status.disk.usedOfTotal",
                CleanMacFormatters.bytes(snapshot.usedBytes),
                CleanMacFormatters.bytes(snapshot.totalBytes)
            ))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            Text(L.f("status.disk.free", CleanMacFormatters.bytes(snapshot.freeBytes)))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
}

private struct LastScanPanel: View {
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
        VStack(alignment: .leading, spacing: 7) {
            Label(L.t("status.lastScan.title"), systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))

            if isScanning {
                Label(L.t("status.autoScan.running"), systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }

            if hasScan {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.f("status.lastScan.summary", itemCount, CleanMacFormatters.bytes(Int64(bytes))))
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: 6) {
                        Text(source == .scheduled ? L.t("status.lastScan.scheduled") : L.t("status.lastScan.manual"))
                        Text("·")
                        Text(CleanMacFormatters.relativeDate(Date(timeIntervalSince1970: timestamp)))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            } else {
                Text(L.t("status.lastScan.empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isAutoScanEnabled {
                Text(L.f(
                    "status.autoScan.next",
                    CleanMacFormatters.time(nextRunDate)
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        let totalBytes = numberValue(attributes[.systemSize])
        let freeBytes = numberValue(attributes[.systemFreeSize])
        let resourceValues = try? homeURL.resourceValues(forKeys: [.volumeLocalizedNameKey])

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

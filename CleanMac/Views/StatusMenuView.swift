import AppKit
import SwiftUI

struct StatusMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(CleanMacPreferenceKeys.lastScanItemCount) private var lastScanItemCount = 0
    @AppStorage(CleanMacPreferenceKeys.lastScanBytes) private var lastScanBytes = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanTimestamp) private var lastScanTimestamp = 0.0
    @AppStorage(CleanMacPreferenceKeys.lastScanSource) private var lastScanSource = CleanMacScanSource.manual.rawValue
    @AppStorage(CleanMacPreferenceKeys.scanInProgress) private var scanInProgress = false
    @State private var sampler = StatusSystemSampler()
    @State private var snapshot = StatusSystemSnapshot.initial

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            metricGrid
            networkStrip
            systemPanel
            actions
        }
        .padding(16)
        .frame(width: 350)
        .background {
            ZStack {
                (colorScheme == .dark
                    ? Color(red: 0.12, green: 0.13, blue: 0.14)
                    : Color(nsColor: .windowBackgroundColor))
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(colorScheme == .dark ? 0.16 : 0.08),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .task {
            await refreshMetrics()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                .accessibilityLabel(L.t("app.name"))

            VStack(alignment: .leading, spacing: 2) {
                Text(L.t("app.name"))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(scanInProgress ? L.t("status.scanning") : L.t("status.metrics.subtitle"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(scanInProgress ? Color.accentColor : Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Circle()
                .fill(scanInProgress ? Color.accentColor : Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: (scanInProgress ? Color.accentColor : .green).opacity(0.55), radius: 5)
                .accessibilityHidden(true)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            StatusMetricCard(
                title: L.t("status.metrics.cpu"),
                systemImage: "cpu",
                fraction: snapshot.cpuFraction,
                value: percentText(snapshot.cpuFraction),
                detail: L.t("status.metrics.live")
            )

            StatusMetricCard(
                title: L.t("status.metrics.memory"),
                systemImage: "memorychip",
                fraction: snapshot.memoryFraction,
                value: percentText(snapshot.memoryFraction),
                detail: CleanMacFormatters.bytes(snapshot.memoryUsedBytes)
            )

            StatusMetricCard(
                title: L.t("status.metrics.disk"),
                systemImage: "internaldrive",
                fraction: snapshot.disk.usedFraction,
                value: percentText(snapshot.disk.usedFraction),
                detail: L.f("status.metrics.free", CleanMacFormatters.bytes(snapshot.disk.freeBytes))
            )

            StatusMetricCard(
                title: L.t("status.metrics.battery"),
                systemImage: batterySystemImage,
                fraction: snapshot.battery?.fraction ?? 0,
                value: snapshot.battery.map { percentText($0.fraction) } ?? "—",
                detail: batteryDetail
            )
        }
    }

    private var networkStrip: some View {
        HStack(spacing: 0) {
            networkItem(
                systemImage: "arrow.down",
                value: rateText(snapshot.downloadBytesPerSecond),
                tint: .accentColor
            )

            Divider()
                .padding(.vertical, 9)

            networkItem(
                systemImage: "arrow.up",
                value: rateText(snapshot.uploadBytesPerSecond),
                tint: .orange
            )

            Divider()
                .padding(.vertical, 9)

            networkItem(
                systemImage: "clock",
                value: uptimeText(snapshot.uptime),
                tint: .secondary
            )
        }
        .frame(height: 46)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.7))
        }
    }

    private var systemPanel: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.tint)
                    .frame(width: 20)

                Text(snapshot.disk.volumeName ?? L.t("status.disk.defaultName"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(L.f("status.metrics.free", CleanMacFormatters.bytes(snapshot.disk.freeBytes)))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: scanInProgress ? "arrow.triangle.2.circlepath" : "doc.text.magnifyingglass")
                    .foregroundStyle(scanInProgress ? Color.accentColor : Color.secondary)
                    .frame(width: 20)

                Text(scanSummary)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(scanInProgress ? Color.accentColor : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 6)

                if lastScanTimestamp > 0, !scanInProgress {
                    Text(CleanMacFormatters.relativeDate(Date(timeIntervalSince1970: lastScanTimestamp)))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(13)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.7))
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 44)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(L.t("menu.quit"))
            .accessibilityLabel(L.t("menu.quit"))

            Button {
                MainWindowController.show(openWindow: openWindow)
            } label: {
                Label(L.t("menu.open"), systemImage: "leaf.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var batterySystemImage: String {
        guard let battery = snapshot.battery else {
            return "battery.0percent"
        }
        if battery.isCharging {
            return "battery.100percent.bolt"
        }
        if battery.fraction >= 0.75 {
            return "battery.100percent"
        }
        if battery.fraction >= 0.25 {
            return "battery.50percent"
        }
        return "battery.25percent"
    }

    private var batteryDetail: String {
        guard let battery = snapshot.battery else {
            return L.t("status.metrics.unavailable")
        }
        if battery.isCharging {
            return L.t("status.metrics.charging")
        }
        if battery.isConnectedToPower {
            return L.t("status.metrics.power")
        }
        return L.t("status.metrics.batteryPower")
    }

    private var scanSummary: String {
        if scanInProgress {
            return L.t("status.autoScan.running")
        }
        guard lastScanTimestamp > 0 else {
            return L.t("status.lastScan.empty")
        }
        return L.f(
            "status.lastScan.summary",
            lastScanItemCount,
            CleanMacFormatters.bytes(Int64(lastScanBytes))
        )
    }

    private func networkItem(systemImage: String, value: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(value)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .monospacedDigit()
        .frame(maxWidth: .infinity)
    }

    private func percentText(_ fraction: Double) -> String {
        "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }

    private func rateText(_ bytesPerSecond: Int64) -> String {
        L.f("status.metrics.rate", CleanMacFormatters.bytes(max(bytesPerSecond, 0)))
    }

    private func uptimeText(_ interval: TimeInterval) -> String {
        let totalMinutes = max(Int(interval / 60), 0)
        return L.f("status.metrics.uptime", totalMinutes / 60, totalMinutes % 60)
    }

    private func refreshMetrics() async {
        snapshot = sampler.sample()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            snapshot = sampler.sample()
        }
    }
}

private struct StatusMetricCard: View {
    let title: String
    let systemImage: String
    let fraction: Double
    let value: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: min(max(fraction, 0), 1))
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.accentColor.opacity(0.28), radius: 4)
                    .animation(.easeOut(duration: 0.45), value: fraction)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 70, height: 70)

            Text(detail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 132)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.7))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value), \(detail)")
    }
}

import SwiftUI

struct SystemMaintenanceView: View {
    @State private var activeTask: SystemMaintenanceTask?
    @State private var reports: [SystemMaintenanceTask: SystemMaintenanceReport] = [:]
    @State private var memorySnapshot = StatusMemorySnapshot.current()

    private let service = SystemMaintenanceService()

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(
                    title: L.t("system.title"),
                    subtitle: L.t("system.subtitle"),
                    systemImage: CleanMacSection.systemMaintenance.systemImage
                )

                StatusBanner(
                    title: L.t("system.safety.title"),
                    message: L.t("system.safety.message"),
                    systemImage: "hand.tap",
                    tint: .blue
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 320), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    ForEach(SystemMaintenanceTask.allCases) { task in
                        SystemMaintenanceCard(
                            task: task,
                            isRunning: activeTask == task,
                            isDisabled: activeTask != nil && activeTask != task,
                            report: reports[task],
                            liveMemorySnapshot: task == .memory ? memorySnapshot : nil,
                            action: {
                                perform(task)
                            }
                        )
                    }
                }

                InfoPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(L.t("system.limits.title"), systemImage: "info.circle")
                            .font(.headline)
                        Text(L.t("system.limits.message"))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .task {
            await refreshMemorySnapshot()
        }
    }

    private func perform(_ task: SystemMaintenanceTask) {
        guard activeTask == nil else {
            return
        }

        if task == .memory {
            memorySnapshot = StatusMemorySnapshot.current()
        }
        activeTask = task
        reports.removeValue(forKey: task)

        Task {
            let report = await service.perform(task)
            reports[task] = report
            if let memoryAfter = report.memoryAfter {
                memorySnapshot = memoryAfter
            } else if task == .memory {
                memorySnapshot = StatusMemorySnapshot.current()
            }
            activeTask = nil
        }
    }

    private func refreshMemorySnapshot() async {
        memorySnapshot = StatusMemorySnapshot.current()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            memorySnapshot = StatusMemorySnapshot.current()
        }
    }
}

private struct SystemMaintenanceCard: View {
    let task: SystemMaintenanceTask
    let isRunning: Bool
    let isDisabled: Bool
    let report: SystemMaintenanceReport?
    let liveMemorySnapshot: StatusMemorySnapshot?
    let action: () -> Void

    var body: some View {
        InfoPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: task.systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(task.tint)
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .font(.title3.bold())
                        Text(task.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let liveMemorySnapshot {
                    SystemMemorySnapshotPanel(
                        snapshot: report?.memoryAfter ?? liveMemorySnapshot,
                        report: report,
                        isRunning: isRunning
                    )
                }

                Text(task.commandSummary)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Label(L.t("system.authorization.note"), systemImage: "lock.shield")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)

                Button(action: action) {
                    Label(task.buttonTitle, systemImage: isRunning ? "hourglass" : task.buttonSystemImage)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning || isDisabled)

                if isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L.t("system.status.running"))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }

                if let report {
                    SystemMaintenanceReportView(report: report)
                }
            }
        }
    }
}

private struct SystemMemorySnapshotPanel: View {
    let snapshot: StatusMemorySnapshot
    let report: SystemMaintenanceReport?
    let isRunning: Bool

    private var percentText: String {
        percentText(snapshot.fraction)
    }

    private var beforeAfterText: String? {
        guard let before = report?.memoryBefore, let after = report?.memoryAfter else {
            return nil
        }
        return L.f(
            "system.memory.gauge.beforeAfter",
            percentText(before.fraction),
            percentText(after.fraction)
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.13), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: min(max(snapshot.fraction, 0), 1))
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .purple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .purple.opacity(0.22), radius: 5)
                    .animation(.easeOut(duration: 0.45), value: snapshot.fraction)

                Text(percentText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 7) {
                Label(L.t("system.memory.gauge.title"), systemImage: "memorychip")
                    .font(.subheadline.weight(.bold))

                Text(L.f(
                    "system.memory.gauge.used",
                    CleanMacFormatters.bytes(snapshot.usedBytes),
                    CleanMacFormatters.bytes(snapshot.totalBytes)
                ))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

                if let beforeAfterText {
                    Text(beforeAfterText)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                memoryChangeLabel
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.purple.opacity(0.18))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var memoryChangeLabel: some View {
        if let before = report?.memoryBefore, let after = report?.memoryAfter {
            let deltaBytes = before.usedBytes - after.usedBytes
            if deltaBytes > 64 * 1024 * 1024 {
                Label(L.f("system.memory.gauge.freed", CleanMacFormatters.bytes(deltaBytes)), systemImage: "arrow.down.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            } else if deltaBytes < -(64 * 1024 * 1024) {
                Label(L.f("system.memory.gauge.rose", CleanMacFormatters.bytes(abs(deltaBytes))), systemImage: "arrow.up.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            } else {
                Label(L.t("system.memory.gauge.noChange"), systemImage: "equal.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            }
        } else if isRunning {
            Label(L.t("system.memory.gauge.measuring"), systemImage: "waveform.path.ecg")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
        } else {
            Label(L.t("system.memory.gauge.live"), systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private func percentText(_ fraction: Double) -> String {
        "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }
}

private struct SystemMaintenanceReportView: View {
    let report: SystemMaintenanceReport

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(report.status.title, systemImage: report.status.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(report.status.tint)

            ForEach(report.commandResults) { result in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: result.succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(result.succeeded ? .green : .orange)
                        Text(result.commandLine)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                        Text(exitCodeText(result.exitCode))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    if result.usedAdministratorPrivileges {
                        Label(L.t("system.result.administrator"), systemImage: "lock.open")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    let message = resultMessage(result)
                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding(9)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }

    private func exitCodeText(_ exitCode: Int32?) -> String {
        guard let exitCode else {
            return L.t("system.result.unavailable")
        }
        return L.f("system.result.exitCode", Int(exitCode))
    }

    private func resultMessage(_ result: SystemMaintenanceCommandResult) -> String {
        if !result.errorOutput.isEmpty {
            return result.errorOutput
        }
        if !result.output.isEmpty {
            return result.output
        }
        return result.succeeded ? L.t("system.result.completed") : L.t("system.result.noOutput")
    }
}

private extension SystemMaintenanceTask {
    var title: String {
        switch self {
        case .memory: L.t("system.memory.title")
        case .dnsCache: L.t("system.dns.title")
        }
    }

    var detail: String {
        switch self {
        case .memory: L.t("system.memory.detail")
        case .dnsCache: L.t("system.dns.detail")
        }
    }

    var buttonTitle: String {
        switch self {
        case .memory: L.t("system.memory.button")
        case .dnsCache: L.t("system.dns.button")
        }
    }

    var systemImage: String {
        switch self {
        case .memory: "memorychip"
        case .dnsCache: "network"
        }
    }

    var buttonSystemImage: String {
        switch self {
        case .memory: "bolt.fill"
        case .dnsCache: "arrow.triangle.2.circlepath"
        }
    }

    var commandSummary: String {
        switch self {
        case .memory: "/usr/sbin/purge"
        case .dnsCache: "/usr/bin/dscacheutil -flushcache\n/usr/bin/killall -HUP mDNSResponder"
        }
    }

    var tint: Color {
        switch self {
        case .memory: .purple
        case .dnsCache: .teal
        }
    }
}

private extension SystemMaintenanceReportStatus {
    var title: String {
        switch self {
        case .success: L.t("system.status.success")
        case .partial: L.t("system.status.partial")
        case .failed: L.t("system.status.failed")
        case .unavailable: L.t("system.status.unavailable")
        }
    }

    var systemImage: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .partial: "exclamationmark.circle.fill"
        case .failed: "xmark.octagon.fill"
        case .unavailable: "questionmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: .green
        case .partial: .orange
        case .failed: .red
        case .unavailable: .secondary
        }
    }
}

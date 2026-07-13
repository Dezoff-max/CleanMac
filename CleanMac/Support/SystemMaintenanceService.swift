import Foundation

enum SystemMaintenanceTask: String, CaseIterable, Hashable, Identifiable, Sendable {
    case memory
    case dnsCache

    var id: String { rawValue }
}

enum SystemMaintenanceReportStatus: String, Sendable {
    case success
    case partial
    case failed
    case unavailable
}

struct SystemMaintenanceCommandResult: Identifiable, Sendable {
    let id: String
    let commandLine: String
    let exitCode: Int32?
    let output: String
    let errorOutput: String
    let usedAdministratorPrivileges: Bool

    nonisolated var succeeded: Bool {
        exitCode == 0
    }

    nonisolated var isUnavailable: Bool {
        exitCode == nil
    }
}

struct SystemMaintenanceReport: Identifiable, Sendable {
    let id: String
    let task: SystemMaintenanceTask
    let status: SystemMaintenanceReportStatus
    let commandResults: [SystemMaintenanceCommandResult]
    let memoryBefore: StatusMemorySnapshot?
    let memoryAfter: StatusMemorySnapshot?
    let completedAt: Date
}

struct SystemMaintenanceService: Sendable {
    private struct Command: Sendable {
        let displayCommandLine: String
        let administratorScript: String
        let requiredExecutablePaths: [String]

        nonisolated var commandLine: String {
            displayCommandLine
        }
    }

    nonisolated func perform(_ task: SystemMaintenanceTask) async -> SystemMaintenanceReport {
        let memoryBefore = task == .memory ? StatusMemorySnapshot.current() : nil
        var results: [SystemMaintenanceCommandResult] = []
        for command in commands(for: task) {
            results.append(await run(command))
        }
        let memoryAfter: StatusMemorySnapshot?
        if task == .memory {
            try? await Task.sleep(for: .milliseconds(450))
            memoryAfter = StatusMemorySnapshot.current()
        } else {
            memoryAfter = nil
        }

        let status: SystemMaintenanceReportStatus
        if results.allSatisfy(\.succeeded) {
            status = .success
        } else if results.allSatisfy(\.isUnavailable) {
            status = .unavailable
        } else if results.contains(where: \.succeeded) {
            status = .partial
        } else {
            status = .failed
        }

        return SystemMaintenanceReport(
            id: UUID().uuidString,
            task: task,
            status: status,
            commandResults: results,
            memoryBefore: memoryBefore,
            memoryAfter: memoryAfter,
            completedAt: Date()
        )
    }

    nonisolated private func commands(for task: SystemMaintenanceTask) -> [Command] {
        switch task {
        case .memory:
            [
                Command(
                    displayCommandLine: "/usr/sbin/purge",
                    administratorScript: "/usr/sbin/purge",
                    requiredExecutablePaths: ["/usr/sbin/purge"]
                )
            ]
        case .dnsCache:
            [
                Command(
                    displayCommandLine: "/usr/bin/dscacheutil -flushcache\n/usr/bin/killall -HUP mDNSResponder",
                    administratorScript: """
                    /usr/bin/dscacheutil -flushcache
                    /usr/bin/killall -HUP mDNSResponder
                    """,
                    requiredExecutablePaths: ["/usr/bin/dscacheutil", "/usr/bin/killall"]
                )
            ]
        }
    }

    nonisolated private func run(_ command: Command) async -> SystemMaintenanceCommandResult {
        await Task.detached(priority: .userInitiated) {
            Self.runSynchronously(command)
        }.value
    }

    nonisolated private static func runSynchronously(_ command: Command) -> SystemMaintenanceCommandResult {
        let fileManager = FileManager.default
        if let missingPath = command.requiredExecutablePaths.first(where: { !fileManager.isExecutableFile(atPath: $0) }) {
            return SystemMaintenanceCommandResult(
                id: UUID().uuidString,
                commandLine: command.commandLine,
                exitCode: nil,
                output: "",
                errorOutput: "Required command is unavailable: \(missingPath)",
                usedAdministratorPrivileges: false
            )
        }

        guard fileManager.isExecutableFile(atPath: "/usr/bin/osascript") else {
            return SystemMaintenanceCommandResult(
                id: UUID().uuidString,
                commandLine: command.commandLine,
                exitCode: nil,
                output: "",
                errorOutput: "macOS authorization runner is unavailable.",
                usedAdministratorPrivileges: false
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \(appleScriptString(command.administratorScript)) with administrator privileges"
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return SystemMaintenanceCommandResult(
                id: UUID().uuidString,
                commandLine: command.commandLine,
                exitCode: nil,
                output: "",
                errorOutput: error.localizedDescription,
                usedAdministratorPrivileges: true
            )
        }

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let errorOutput = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        return SystemMaintenanceCommandResult(
            id: UUID().uuidString,
            commandLine: command.commandLine,
            exitCode: process.terminationStatus,
            output: output.trimmingCharacters(in: .whitespacesAndNewlines),
            errorOutput: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines),
            usedAdministratorPrivileges: true
        )
    }

    nonisolated private static func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

import Darwin
import Foundation
import IOKit.ps
import CleanMacCore

struct StatusSystemSnapshot: Equatable {
    let cpuFraction: Double
    let memoryFraction: Double
    let memoryUsedBytes: Int64
    let disk: StatusDiskSnapshot
    let battery: StatusBatterySnapshot?
    let downloadBytesPerSecond: Int64
    let uploadBytesPerSecond: Int64
    let uptime: TimeInterval

    static var initial: StatusSystemSnapshot {
        StatusSystemSnapshot(
            cpuFraction: 0,
            memoryFraction: 0,
            memoryUsedBytes: 0,
            disk: .current(),
            battery: StatusBatterySnapshot.current(),
            downloadBytesPerSecond: 0,
            uploadBytesPerSecond: 0,
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }
}

struct StatusDiskSnapshot: Equatable {
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

    var freeFraction: Double? {
        LowDiskSpaceWarningPolicy.freeFraction(totalBytes: totalBytes, freeBytes: freeBytes)
    }

    var isLowSpace: Bool {
        LowDiskSpaceWarningPolicy.isLowSpace(totalBytes: totalBytes, freeBytes: freeBytes)
    }

    static func current() -> StatusDiskSnapshot {
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

        return StatusDiskSnapshot(
            volumeName: resourceValues?.volumeLocalizedName,
            totalBytes: totalBytes,
            freeBytes: min(max(freeBytes, 0), totalBytes)
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

struct StatusBatterySnapshot: Equatable {
    let fraction: Double
    let isCharging: Bool
    let isConnectedToPower: Bool

    static func current() -> StatusBatterySnapshot? {
        guard
            let powerInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sourceList = IOPSCopyPowerSourcesList(powerInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for source in sourceList {
            guard
                let description = IOPSGetPowerSourceDescription(powerInfo, source)?.takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                let maximumCapacity = description[kIOPSMaxCapacityKey] as? Int,
                maximumCapacity > 0
            else {
                continue
            }

            let state = description[kIOPSPowerSourceStateKey] as? String
            return StatusBatterySnapshot(
                fraction: min(max(Double(currentCapacity) / Double(maximumCapacity), 0), 1),
                isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
                isConnectedToPower: state == kIOPSACPowerValue
            )
        }

        return nil
    }
}

struct StatusSystemSampler {
    private struct CPUTicks {
        let busy: UInt64
        let idle: UInt64
    }

    private struct NetworkCounters {
        let received: UInt64
        let sent: UInt64
    }

    private var previousCPU: CPUTicks?
    private var previousNetwork: (date: Date, counters: NetworkCounters)?

    mutating func sample() -> StatusSystemSnapshot {
        let now = Date()
        let currentCPU = readCPUTicks()
        let cpuFraction = cpuUsage(current: currentCPU, previous: previousCPU)
        previousCPU = currentCPU

        let memory = readMemory()
        let currentNetwork = readNetworkCounters()
        let networkRates = networkRates(current: currentNetwork, at: now, previous: previousNetwork)
        previousNetwork = (now, currentNetwork)

        return StatusSystemSnapshot(
            cpuFraction: cpuFraction,
            memoryFraction: memory.fraction,
            memoryUsedBytes: memory.usedBytes,
            disk: .current(),
            battery: StatusBatterySnapshot.current(),
            downloadBytesPerSecond: networkRates.received,
            uploadBytesPerSecond: networkRates.sent,
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }

    private func readCPUTicks() -> CPUTicks {
        var load = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return CPUTicks(busy: 0, idle: 0)
        }

        let ticks = load.cpu_ticks
        return CPUTicks(
            busy: UInt64(ticks.0) + UInt64(ticks.1) + UInt64(ticks.3),
            idle: UInt64(ticks.2)
        )
    }

    private func cpuUsage(current: CPUTicks, previous: CPUTicks?) -> Double {
        guard let previous else {
            return 0
        }

        let busyDelta = counterDelta(current.busy, previous.busy)
        let idleDelta = counterDelta(current.idle, previous.idle)
        let totalDelta = busyDelta + idleDelta
        guard totalDelta > 0 else {
            return 0
        }

        return min(max(Double(busyDelta) / Double(totalDelta), 0), 1)
    }

    private func readMemory() -> (fraction: Double, usedBytes: Int64) {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard result == KERN_SUCCESS, totalBytes > 0 else {
            return (0, 0)
        }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let usedPages = UInt64(statistics.active_count)
            + UInt64(statistics.wire_count)
            + UInt64(statistics.compressor_page_count)
        let usedBytes = min(usedPages * UInt64(pageSize), totalBytes)

        return (
            min(max(Double(usedBytes) / Double(totalBytes), 0), 1),
            Int64(clamping: usedBytes)
        )
    }

    private func readNetworkCounters() -> NetworkCounters {
        var firstAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddress) == 0, let firstAddress else {
            return NetworkCounters(received: 0, sent: 0)
        }
        defer { freeifaddrs(firstAddress) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var currentAddress: UnsafeMutablePointer<ifaddrs>? = firstAddress

        while let address = currentAddress {
            defer { currentAddress = address.pointee.ifa_next }

            let flags = Int32(address.pointee.ifa_flags)
            guard
                flags & IFF_UP != 0,
                flags & IFF_LOOPBACK == 0,
                let socketAddress = address.pointee.ifa_addr,
                socketAddress.pointee.sa_family == UInt8(AF_LINK),
                let rawData = address.pointee.ifa_data
            else {
                continue
            }

            let interfaceData = rawData.assumingMemoryBound(to: if_data.self).pointee
            received += UInt64(interfaceData.ifi_ibytes)
            sent += UInt64(interfaceData.ifi_obytes)
        }

        return NetworkCounters(received: received, sent: sent)
    }

    private func networkRates(
        current: NetworkCounters,
        at date: Date,
        previous: (date: Date, counters: NetworkCounters)?
    ) -> (received: Int64, sent: Int64) {
        guard let previous else {
            return (0, 0)
        }

        let interval = max(date.timeIntervalSince(previous.date), 0.001)
        return (
            Int64(clamping: UInt64(Double(counterDelta(current.received, previous.counters.received)) / interval)),
            Int64(clamping: UInt64(Double(counterDelta(current.sent, previous.counters.sent)) / interval))
        )
    }

    private func counterDelta(_ current: UInt64, _ previous: UInt64) -> UInt64 {
        current >= previous ? current - previous : current
    }
}

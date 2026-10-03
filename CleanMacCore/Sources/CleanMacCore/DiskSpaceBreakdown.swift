/// A volume's capacity without counting space reclaimable by macOS twice.
///
/// Capacity available for important usage already includes space that macOS can
/// reclaim. It is the preferred available value; physical free space is a subset
/// of that value, rather than an additional amount of available storage.
public struct DiskSpaceBreakdown: Equatable, Sendable {
    public let totalBytes: Int64
    public let availableBytes: Int64
    public let immediatelyAvailableBytes: Int64?
    public let reclaimableBytes: Int64?
    public let isAvailable: Bool

    public var usedBytes: Int64 {
        totalBytes - availableBytes
    }

    /// The free segment of a coherent capacity chart. File-system measurements
    /// can race; cap physical free space to the preferred available measurement
    /// so used, reclaimable and free segments never overlap or exceed capacity.
    /// If physical free space is unknown, show all available space as free.
    public var displayedFreeBytes: Int64 {
        min(immediatelyAvailableBytes ?? availableBytes, availableBytes)
    }

    public var usedFraction: Double {
        guard isAvailable else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    public init(
        totalBytes: Int64,
        importantUsageAvailableBytes: Int64?,
        immediatelyAvailableBytes: Int64?,
        systemFreeBytes: Int64? = nil
    ) {
        self.totalBytes = max(totalBytes, 0)

        guard totalBytes > 0 else {
            availableBytes = 0
            self.immediatelyAvailableBytes = nil
            reclaimableBytes = nil
            isAvailable = false
            return
        }

        // Zero is a valid measurement on a full disk. Negative values indicate
        // unavailable data and must not prevent a valid fallback from being used.
        func validCapacity(_ bytes: Int64?) -> Int64? {
            guard let bytes, bytes >= 0 else { return nil }
            return min(bytes, totalBytes)
        }

        let importantAvailable = validCapacity(importantUsageAvailableBytes)
        let physicalAvailable = validCapacity(immediatelyAvailableBytes)
            ?? validCapacity(systemFreeBytes)
        let available = importantAvailable ?? physicalAvailable

        availableBytes = available ?? 0
        self.immediatelyAvailableBytes = physicalAvailable
        isAvailable = available != nil

        if let importantAvailable, let physicalAvailable {
            reclaimableBytes = max(importantAvailable - physicalAvailable, 0)
        } else {
            // Unknown reclaimable space is different from a measured zero.
            reclaimableBytes = nil
        }
    }
}

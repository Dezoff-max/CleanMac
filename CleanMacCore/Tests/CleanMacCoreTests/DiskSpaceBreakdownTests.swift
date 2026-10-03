import XCTest
@testable import CleanMacCore

final class DiskSpaceBreakdownTests: XCTestCase {
    func testImportantUsageAlreadyIncludesReclaimableSpace() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: 300,
            immediatelyAvailableBytes: 100
        )

        XCTAssertTrue(capacity.isAvailable)
        XCTAssertEqual(capacity.availableBytes, 300)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 100)
        XCTAssertEqual(capacity.displayedFreeBytes, 100)
        XCTAssertEqual(capacity.reclaimableBytes, 200)
        XCTAssertEqual(capacity.usedBytes, 700)
        XCTAssertEqual(capacity.usedFraction, 0.7, accuracy: 0.0001)
        XCTAssertEqual(
            capacity.usedBytes + capacity.immediatelyAvailableBytes! + capacity.reclaimableBytes!,
            capacity.totalBytes
        )
    }

    func testMissingImportantUsageUsesPhysicalSpaceWithoutInventingReclaimableSpace() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: nil,
            immediatelyAvailableBytes: 150,
            systemFreeBytes: 200
        )

        XCTAssertEqual(capacity.availableBytes, 150)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 150)
        XCTAssertNil(capacity.reclaimableBytes)
        XCTAssertEqual(capacity.usedBytes, 850)
    }

    func testMissingPhysicalSpaceUsesFileSystemFallback() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: 300,
            immediatelyAvailableBytes: nil,
            systemFreeBytes: 120
        )

        XCTAssertEqual(capacity.availableBytes, 300)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 120)
        XCTAssertEqual(capacity.reclaimableBytes, 180)
    }

    func testFileSystemFallbackAloneRemainsUsable() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: nil,
            immediatelyAvailableBytes: nil,
            systemFreeBytes: 120
        )

        XCTAssertTrue(capacity.isAvailable)
        XCTAssertEqual(capacity.availableBytes, 120)
        XCTAssertEqual(capacity.usedBytes, 880)
        XCTAssertNil(capacity.reclaimableBytes)
    }

    func testImportantUsageAloneDoesNotInventPhysicalOrReclaimableSpace() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: 300,
            immediatelyAvailableBytes: nil
        )

        XCTAssertTrue(capacity.isAvailable)
        XCTAssertEqual(capacity.availableBytes, 300)
        XCTAssertNil(capacity.immediatelyAvailableBytes)
        XCTAssertNil(capacity.reclaimableBytes)
    }

    func testZeroAvailableIsValidAndDoesNotSelectAFallback() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: 0,
            immediatelyAvailableBytes: 0,
            systemFreeBytes: 200
        )

        XCTAssertTrue(capacity.isAvailable)
        XCTAssertEqual(capacity.availableBytes, 0)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 0)
        XCTAssertEqual(capacity.reclaimableBytes, 0)
        XCTAssertEqual(capacity.usedBytes, 1_000)
        XCTAssertEqual(capacity.usedFraction, 1)
    }

    func testNegativeMeasurementsAreUnknownAndAllowAValidFallback() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: -1,
            immediatelyAvailableBytes: -100,
            systemFreeBytes: 100
        )

        XCTAssertTrue(capacity.isAvailable)
        XCTAssertEqual(capacity.availableBytes, 100)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 100)
        XCTAssertNil(capacity.reclaimableBytes)
    }

    func testMeasurementsCannotExceedVolumeCapacity() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: Int64.max,
            immediatelyAvailableBytes: 1_200
        )

        XCTAssertEqual(capacity.availableBytes, 1_000)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 1_000)
        XCTAssertEqual(capacity.reclaimableBytes, 0)
        XCTAssertEqual(capacity.usedBytes, 0)
        XCTAssertEqual(capacity.usedFraction, 0)
    }

    func testInconsistentSamplesNeverProduceNegativeReclaimableSpace() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: 100,
            immediatelyAvailableBytes: 200
        )

        XCTAssertEqual(capacity.availableBytes, 100)
        XCTAssertEqual(capacity.immediatelyAvailableBytes, 200)
        XCTAssertEqual(capacity.displayedFreeBytes, 100)
        XCTAssertEqual(capacity.reclaimableBytes, 0)
        XCTAssertEqual(capacity.usedBytes, 900)
        XCTAssertEqual(
            capacity.usedBytes + capacity.displayedFreeBytes + (capacity.reclaimableBytes ?? 0),
            capacity.totalBytes
        )
    }

    func testUnknownAvailableSpaceIsNotAValidFullDiskMeasurement() {
        let capacity = DiskSpaceBreakdown(
            totalBytes: 1_000,
            importantUsageAvailableBytes: nil,
            immediatelyAvailableBytes: nil
        )

        XCTAssertFalse(capacity.isAvailable)
        XCTAssertNil(capacity.immediatelyAvailableBytes)
        XCTAssertNil(capacity.reclaimableBytes)
        XCTAssertEqual(capacity.usedFraction, 0)
    }

    func testInvalidVolumeCapacityHasNoUsableBreakdown() {
        for totalBytes: Int64 in [0, -1, Int64.min] {
            let capacity = DiskSpaceBreakdown(
                totalBytes: totalBytes,
                importantUsageAvailableBytes: 300,
                immediatelyAvailableBytes: 100
            )

            XCTAssertFalse(capacity.isAvailable)
            XCTAssertEqual(capacity.totalBytes, 0)
            XCTAssertEqual(capacity.availableBytes, 0)
            XCTAssertEqual(capacity.usedBytes, 0)
            XCTAssertEqual(capacity.usedFraction, 0)
            XCTAssertNil(capacity.immediatelyAvailableBytes)
            XCTAssertNil(capacity.reclaimableBytes)
        }
    }
}

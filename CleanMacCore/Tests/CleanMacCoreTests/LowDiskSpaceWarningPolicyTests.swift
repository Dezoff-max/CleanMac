import XCTest
@testable import CleanMacCore

final class LowDiskSpaceWarningPolicyTests: XCTestCase {
    func testLowSpaceRequiresValidCapacityAndStrictlyLessThanTenPercentFree() {
        XCTAssertFalse(LowDiskSpaceWarningPolicy.isLowSpace(totalBytes: 0, freeBytes: 0))
        XCTAssertFalse(LowDiskSpaceWarningPolicy.isLowSpace(totalBytes: 1_000, freeBytes: 100))
        XCTAssertTrue(LowDiskSpaceWarningPolicy.isLowSpace(totalBytes: 1_000, freeBytes: 99))
    }

    func testNotificationIsLimitedToOncePerTwentyFourHours() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertTrue(LowDiskSpaceWarningPolicy.shouldNotify(
            totalBytes: 1_000,
            freeBytes: 50,
            lastNotificationDate: nil,
            now: now
        ))
        XCTAssertFalse(LowDiskSpaceWarningPolicy.shouldNotify(
            totalBytes: 1_000,
            freeBytes: 50,
            lastNotificationDate: now.addingTimeInterval(-23 * 60 * 60),
            now: now
        ))
        XCTAssertTrue(LowDiskSpaceWarningPolicy.shouldNotify(
            totalBytes: 1_000,
            freeBytes: 50,
            lastNotificationDate: now.addingTimeInterval(-24 * 60 * 60),
            now: now
        ))
    }

    func testRecoveredSpaceSuppressesNotificationRegardlessOfCooldown() {
        XCTAssertFalse(LowDiskSpaceWarningPolicy.shouldNotify(
            totalBytes: 1_000,
            freeBytes: 250,
            lastNotificationDate: nil
        ))
    }
}

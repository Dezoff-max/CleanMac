import XCTest
@testable import CleanMacCore

final class CleanMacCoreTests: XCTestCase {
    func testStatusIsNotEmpty() {
        XCTAssertFalse(CleanMacCoreInfo.status.isEmpty)
    }
}

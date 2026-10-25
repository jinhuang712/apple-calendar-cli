import EventKit
import XCTest

@testable import acal

final class AuthStatusTests: XCTestCase {
    func testMapsEverySystemStatus() {
        XCTAssertEqual(AuthStatus(.fullAccess), .granted)
        XCTAssertEqual(AuthStatus(.writeOnly), .writeOnly)
        XCTAssertEqual(AuthStatus(.denied), .denied)
        XCTAssertEqual(AuthStatus(.restricted), .restricted)
        XCTAssertEqual(AuthStatus(.notDetermined), .notDetermined)
    }

    func testOnlyGrantedHasNoHint() {
        XCTAssertNil(AuthStatus.granted.hint)
        for status in [AuthStatus.denied, .writeOnly, .notDetermined, .restricted] {
            XCTAssertNotNil(status.hint, "\(status) needs a hint")
        }
    }
}

import XCTest
@testable import AuthService

final class AuthServiceTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AuthService().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

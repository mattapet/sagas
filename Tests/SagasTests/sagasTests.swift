import XCTest
@testable import Sagas

final class SagasTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    XCTAssertEqual(Sagas().text, "Hello, World!")
  }

  static var allTests = [
    ("testExample", testExample),
  ]
}

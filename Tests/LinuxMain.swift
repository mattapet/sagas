import XCTest

import SagasTests

var tests = [XCTestCaseEntry]()
tests += SagasTests.allTests()
XCTMain(tests)

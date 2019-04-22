import XCTest

import HttpSagasTests

var tests = [XCTestCaseEntry]()
tests += HttpSagasTests.allTests()
XCTMain(tests)

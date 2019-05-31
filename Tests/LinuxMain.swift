import XCTest

import ConsoleTests

var tests = [XCTestCaseEntry]()
tests += ConsoleTests.__allTests()

XCTMain(tests)

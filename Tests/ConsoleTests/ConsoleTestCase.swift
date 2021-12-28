import Foundation
import XCTest
import Console
import ConsoleTestHelpers

public class ConsoleTestCase: XCTestCase {
    func makeMockConsole(file: StaticString = #file, line: UInt = #line) -> MockConsole {
        MockConsole(
            testAdapter: XCTestMockConsoleTestAdapter(),
            file: file,
            line: line
        )
    }
}

class XCTestMockConsoleTestAdapter: MockConsoleTestAdapterType {
    func recordTestFailure(_ message: String, file: StaticString, line: UInt) {
        XCTFail(message, file: file, line: line)
    }
}

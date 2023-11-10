import XCTest

@testable import Console

class String_ConsoleFormattingTests: XCTestCase {
    func testTerminalFormat() {
        let result = "abc".terminalFormat(.bold)

        XCTAssertEqual(result, "\u{001B}[1mabc\u{001B}[0m")
    }

    func testTerminalFormat_chainedFormats() {
        let result = "abc".terminalFormat(.bold).terminalFormat(.italic)

        XCTAssertEqual(result, "\u{001B}[3m\u{001B}[1mabc\u{001B}[0m\u{001B}[0m")
    }
}

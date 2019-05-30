import XCTest
@testable import Console

class ConsoleTests: XCTestCase {
    func testMeasureString() {
        XCTAssertEqual(Console.measureString(""), 0)
        XCTAssertEqual(Console.measureString("abc"), 3)
        XCTAssertEqual(Console.measureString("abc def gh"), 10)
    }
    
    func testMeasureStringWithTerminalAnsiCodes() {
        XCTAssertEqual(Console.measureString("\u{001B}[30mHello, \u{001B}[30mWorld!\u{001B}[30m"), 13)
    }
}

import XCTest
@testable import Console

class ConsoleTests: XCTestCase {
    func testMeasureString() {
        XCTAssertEqual(Console.measureString(""), 0)
        XCTAssertEqual(Console.measureString("abc"), 3)
        XCTAssertEqual(Console.measureString("abc def g"), 9)
    }
    
    func testMeasureStringTerminalEscapeCharacters() {
        XCTAssertEqual(Console.measureString("\u{001B}[10mHello, \u{001B}[11mWorld!"), 13)
    }
}

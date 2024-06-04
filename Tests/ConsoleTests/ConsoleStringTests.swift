import XCTest

@testable import Console

class ConsoleStringTests: XCTestCase {
    func testInterpolation() {
        let sut: ConsoleString = "a\(0) \(color: .red)abc \(1, color: .blue)"

        XCTAssertEqual(sut.segments, [
            .literal("a"),
            .literal("0"),
            .literal(" "),
            .formatSet(.init(background: nil, foreground: Optional(.red), format: nil)),
            .literal("abc "),
            .formatted("1", .init(background: nil, foreground: Optional(.blue), format: nil)),
            .literal("")
        ])
    }

    func testTerminalFormatted() {
        let sut: ConsoleString = "a\(0) \(color: .red)abc \(1, color: .blue)"

        let result = sut.terminalFormatted()

        XCTAssertEqual(result, "a0 \u{1b}[31mabc \u{1b}[34m1\u{1b}[31m")
    }

    func testTerminalFormatted_usesStartingFormatOnReset() {
        let sut: ConsoleString = "a\(0, color: .blue) \(color: .red)abc \(1, color: .blue)"

        let result = sut.terminalFormatted(
            background: .yellow, format: .light
        )

        XCTAssertEqual(result, "a\u{1b}[34m0\u{1b}[43;2m \u{1b}[31mabc \u{1b}[34m1\u{1b}[31m")
    }

    func testUnformatted() {
        let sut: ConsoleString = "a\(0) \(color: .red)abc \(1, color: .blue)"

        let result = sut.unformatted()

        XCTAssertEqual(result, "a0 abc 1")
    }
}

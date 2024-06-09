import Foundation
import Console

public class MockConsole: Console {
    private var _buffer = OutputBuffer()
    var buffer: String {
        return _buffer.output
    }

    let testAdapter: MockConsoleTestAdapterType

    let file: StaticString
    let line: UInt

    /// Sequence of mock commands
    var commandsInput: [String?] = []

    public init(testAdapter: MockConsoleTestAdapterType, file: StaticString = #file, line: UInt = #line) {
        self.testAdapter = testAdapter
        self.file = file
        self.line = line

        super.init(output: _buffer)
    }

    public func addMockInput(line: String?) {
        commandsInput.append(line)
    }

    public override func readLineWith(
        prompt: String,
        allowEmpty: Bool = true,
        validate: (String) -> Bool = { _ in true }
    ) -> String? {

        let res = super.readLineWith(
            prompt: prompt,
            allowEmpty: allowEmpty
        ) { input in
            if commandsInput.isEmpty {
                testAdapter.recordTestFailure(
                    "Unexpected readLineWith with prompt: \(prompt)",
                    file: file,
                    line: line
                )

                return true
            }

            return validate(input)
        }

        if commandsInput.isEmpty {
            return "0"
        }

        return res
    }

    public override func readSureLineWith(prompt: String) -> String {
        if commandsInput.isEmpty {
            testAdapter.recordTestFailure(
                "Unexpected readLineWith with prompt: \(prompt)",
                file: file,
                line: line
            )

            return "0"
        }

        return super.readSureLineWith(prompt: prompt)
    }

    public override func readLineWith(prompt: String) -> String? {
        if commandsInput.isEmpty {
            testAdapter.recordTestFailure(
                "Unexpected readLineWith with prompt: \(prompt)",
                file: file,
                line: line
            )

            return nil
        }

        let command = commandsInput.removeFirst()

        let ascii = command?.unicodeScalars.map { scalar in
            scalar == "\n" ? "\\n" : scalar.escaped(asASCII: true)
        }.joined(separator: "")

        _buffer.output += "[INPUT] '\(ascii ?? "<nil>")'\n"

        return command
    }

    public override func command(_ command: Terminal.Command) {
        // Consume events
    }

    public override func recordExitCode(_ code: Int) {
        // Trim output so it's easier to test
        _buffer.output =
            _buffer.output
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    public func beginOutputAssertion() -> MockConsoleOutputAsserter {
        return MockConsoleOutputAsserter(testAdapter: testAdapter, output: _buffer.output)
    }

    private class OutputBuffer: ConsoleOutputStream {
        var output = ""

        var capabilityFlags: ConsoleOutputCapabilityFlag = [
            .ansiControlSequences
        ]

        func write(_ string: String) {
            output += string
        }
    }
}

/// Helper assertion class used to assert outputs of console interactions more
/// easily.
public class MockConsoleOutputAsserter {
    let output: String
    var outputIndex: String.Index

    let testAdapter: MockConsoleTestAdapterType

    var didAssert = false

    init(testAdapter: MockConsoleTestAdapterType, output: String) {
        self.testAdapter = testAdapter
        self.output = output
        self.outputIndex = output.startIndex
    }

    /// Asserts that from the current index, a given string can be found.
    /// After asserting successfully, the method skips the index to just after
    /// the string's end on the input buffer.
    ///
    /// - Parameter string: String to verify on the buffer
    @discardableResult
    public func checkNext(
        _ string: String,
        literal: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> MockConsoleOutputAsserter {

        if didAssert { // Ignore further asserts since first assert failed.
            return self
        }

        // Find next
        let range =
            output.range(
                of: string,
                options: literal ? .literal : .caseInsensitive,
                range: outputIndex..<output.endIndex
            )

        if let range = range {
            outputIndex = range.upperBound
        } else {
            let msg = "Did not find expected string '\(string)' from current string offset."
            assert(message: msg, file: file, line: line)
        }

        return self
    }

    /// Asserts that from the current index, a given text input was found.
    /// After asserting successfully, the method skips the index to just after
    /// the input's end on the input buffer.
    ///
    /// - Parameter string: Input to verify on the buffer
    @discardableResult
    public func checkInputEntered(
        _ string: String,
        literal: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> MockConsoleOutputAsserter {

        if didAssert { // Ignore further asserts since first assert failed.
            return self
        }

        let input = "[INPUT] '\(string)'"

        // Find next
        let range =
            output.range(of: input, options: literal ? .literal : .caseInsensitive,
                         range: outputIndex..<output.endIndex)

        if let range = range {
            outputIndex = range.upperBound
        } else {
            let msg = "Did not find expected input '\(string)' from current string offset."
            assert(message: msg, file: file, line: line)
        }

        return self
    }

    /// Asserts that from the current index, a given string cannot be found.
    /// This method does not alter the index.
    ///
    /// - Parameter string: String to verify on the buffer
    @discardableResult
    public func checkNextNot(
        contain string: String,
        literal: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> MockConsoleOutputAsserter {

        let range =
            output.range(of: string, options: literal ? .literal : .caseInsensitive,
                         range: outputIndex..<output.endIndex)

        if range != nil {
            let msg = "Found string '\(string)' from current string offset."
            assert(message: msg, file: file, line: line)
        }

        return self
    }

    /// If the checking asserted, prints the entire output of the buffer being
    /// tested into the standard output for test inspection.
    public func printIfAsserted(file: StaticString = #file, line: UInt = #line) {
        if didAssert {
            assert(message: output, file: file, line: line)
        }
    }

    /// Unconditionally prints the buffer output to the standard output
    public func printOutput() {
        if didAssert {
            print(output)
        }
    }

    private func assert(message: String, file: StaticString, line: UInt) {
        testAdapter.recordTestFailure(message, file: file, line: line)
        didAssert = true
    }
}

import Foundation
import XCTest
import Console

public class ConsoleTestCase: XCTestCase {
    func makeMockConsole(file: StaticString = #file, line: UInt = #line) -> MockConsole {
        return MockConsole(file: file, line: line)
    }
}

class MockConsole: Console {
    private var _buffer = OutputBuffer()
    var buffer: String {
        return _buffer.output
    }
    
    let file: StaticString
    let line: UInt
    
    /// Sequence of mock commands
    var commandsInput: [String?] = []
    
    init(file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
        
        super.init(output: _buffer)
    }
    
    func addMockInput(line: String?) {
        commandsInput.append(line)
    }
    
    override func readLineWith(prompt: String, allowEmpty: Bool = true, validate: (String) -> Bool = { _ in true }) -> String? {
        let res = super.readLineWith(prompt: prompt, allowEmpty: allowEmpty, validate: { input in
            if commandsInput.isEmpty {
                XCTFail("Unexpected readLineWith with prompt: \(prompt)", file: file, line: line)
                return true
            }
            
            return validate(input)
        })
        
        if commandsInput.isEmpty {
            return "0"
        }
        
        return res
    }
    
    override func readSureLineWith(prompt: String) -> String {
        if commandsInput.isEmpty {
            XCTFail("Unexpected readLineWith with prompt: \(prompt)",
                file: file, line: line)
            return "0"
        }
        
        return super.readSureLineWith(prompt: prompt)
    }
    
    override func readLineWith(prompt: String) -> String? {
        if commandsInput.isEmpty {
            XCTFail("Unexpected readLineWith with prompt: \(prompt)",
                file: file, line: line)
            return nil
        }
        
        let command = commandsInput.removeFirst()
        
        let ascii = command?.unicodeScalars.map { scalar in
            scalar == "\n" ? "\\n" : scalar.escaped(asASCII: true)
            }.joined(separator: "")
        
        _buffer.output += "[INPUT] '\(ascii ?? "<nil>")'\n"
        
        return command
    }
    
    override func command(_ command: Terminal.Command) {
        // Consume events
    }
    
    override func recordExitCode(_ code: Int) {
        // Trim output so it's easier to test
        _buffer.output =
            _buffer.output
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public func beginOutputAssertion() -> MockConsoleOutputAsserter {
        return MockConsoleOutputAsserter(output: _buffer.output)
    }
    
    private class OutputBuffer: TextOutputStream {
        var output = ""
        
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
    
    var didAssert = false
    
    init(output: String) {
        self.output = output
        self.outputIndex = output.startIndex
    }
    
    /// Asserts that from the current index, a given string can be found.
    /// After asserting successfully, the method skips the index to just after
    /// the string's end on the input buffer.
    ///
    /// - Parameter string: String to verify on the buffer
    @discardableResult
    func checkNext(_ string: String, literal: Bool = true, file: StaticString = #file, line: UInt = #line) -> MockConsoleOutputAsserter {
        if didAssert { // Ignore further asserts since first assert failed.
            return self
        }
        
        // Find next
        let range =
            output.range(of: string, options: literal ? .literal : .caseInsensitive,
                         range: outputIndex..<output.endIndex)
        
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
    func checkInputEntered(_ string: String, literal: Bool = true, file: StaticString = #file, line: UInt = #line) -> MockConsoleOutputAsserter {
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
    func checkNextNot(contain string: String, literal: Bool = true, file: StaticString = #file, line: UInt = #line) -> MockConsoleOutputAsserter {
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
    func printIfAsserted(file: StaticString = #file, line: UInt = #line) {
        if didAssert {
            assert(message: output, file: file, line: line)
        }
    }
    
    /// Unconditionally prints the buffer output to the standard output
    func printOutput() {
        if didAssert {
            print(output)
        }
    }
    
    private func assert(message: String, file: StaticString, line: UInt) {
        XCTFail(message, file: file, line: line)
        didAssert = true
    }
}

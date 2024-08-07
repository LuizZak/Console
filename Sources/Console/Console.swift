import Foundation

public enum ValueReadResult<T> {
    case success(T)
    case error(String?)
    case abort
}

/// Helper console-interaction interface
open class Console: ConsoleType {
    private let _tputUrl = URL(fileURLWithPath: "/usr/bin/tput")

    private var outputSink: OutputSink

    private var isInAlternativeBuffer = false

    /// Target output stream to print messages to
    public final var output: ConsoleOutputStream

    /// If true, erases scrollback when calling `eraseScreen`.
    /// Defaults to true.
    public var eraseScrollback: Bool = true

    /// Initializes this console class with the default standard output stream
    public convenience init() {
        self.init(output: StandardOutputTextStream())
    }

    /// Initializes this console class with a custom output stream
    public init(output: ConsoleOutputStream) {
        self.output = output
        outputSink = OutputSink(forward: { _ in })

        outputSink = OutputSink { [weak self] str in
            self?.output.write(str)
        }
    }

    /// Displays a table layout list of values on the console.
    ///
    /// The value matrix is interpreted as an array of lines, with an inner array
    /// of elements within.
    ///
    /// The table is automatically adjusted so the columns are spaced evenly
    /// across strings of multiple lengths.
    open func displayTable(withValues values: [[ConsoleString]], separator: ConsoleString) {
        // Measure maximum length of values on each column
        var columnWidths: [Int] = []

        for line in values {
            for (i, cell) in line.enumerated() {
                // Make sure we have the minimum amount of storage for storing
                // this column
                while columnWidths.count <= i {
                    columnWidths.append(0)
                }

                columnWidths[i] = max(columnWidths[i], Console.measureString(cell))
            }
        }

        // Print columns now
        for line in values {
            for (i, row) in line.enumerated() {
                if i < line.count - 1 {
                    let rowLength = Console.measureString(row)
                    let spaces = String(repeating: " ", count: columnWidths[i] - rowLength)

                    printLine("\(formatted: row)\(formatted: separator)\(spaces)", terminator: "")
                } else {
                    printLine(row, terminator: "")
                }
            }
            printLine()
        }
    }

    open func readSureLineWith(prompt: ConsoleString) -> String {
        repeat {
            guard let input = readLineWith(prompt: prompt) else {
                printLine("Invalid input")
                continue
            }

            return input
        } while true
    }

    open func readLineWith(
        prompt: ConsoleString,
        allowEmpty: Bool = true,
        validate: (String) -> Bool = { _ in true }
    ) -> String? {
        repeat {
            let input = readSureLineWith(prompt: prompt)

            if input.isEmpty {
                return allowEmpty ? "" : nil
            }

            if !validate(input) {
                continue
            }

            return input
        } while true
    }

    open func parseLineWith<T>(
        prompt: ConsoleString,
        allowEmpty: Bool,
        parse: (String) -> ValueReadResult<T>
    ) -> T? {
        repeat {
            let input = readSureLineWith(prompt: prompt)

            if allowEmpty && input.isEmpty {
                return nil
            }

            let parsed = parse(input)

            switch parsed {
            case .error(let msg):
                if let msg = msg {
                    printLine(msg)
                }
                continue
            case .success(let value):
                return value
            case .abort:
                return nil
            }
        } while true
    }

    open func readIntWith(
        prompt: ConsoleString,
        validate: (Int) -> Bool = { _ in true }
    ) -> Int? {
        repeat {
            let input = readSureLineWith(prompt: prompt)

            if input.isEmpty {
                return nil
            }
            guard let int = Int(input) else {
                printLine("Please insert a valid digits-only number")
                continue
            }

            if !validate(int) {
                continue
            }

            return int
        } while true
    }

    open func readLineWith(prompt: ConsoleString) -> String? {
        printLine(prompt, terminator: " ")
        return readLine()
    }

    open func printLine() {
        print(to: &outputSink)
    }

    open func printLine(_ line: ConsoleString) {
        _print(line)
    }

    open func printLine(_ line: ConsoleString, terminator: String) {
        _print(line, terminator: terminator)
    }

    open func command(_ command: Terminal.Command) {
        if output.capabilityFlags.contains(.ansiControlSequences) {
            output.write(command.ansi)
        }
    }

    open func clearScreen() {
        command(.eraseScreen)
        command(.moveHome)
        if eraseScrollback {
            command(.eraseScreenAndScrollback)
        }
    }

    open func startAlternativeScreenBuffer() {
        if isInAlternativeBuffer {
            return
        }

        try? _runTPut(arguments: ["smcup"])
        isInAlternativeBuffer = true
    }

    open func stopAlternativeScreenBuffer() {
        if !isInAlternativeBuffer {
            return
        }

        try? _runTPut(arguments: ["rmcup"])
        isInAlternativeBuffer = false
    }

    private func _print(
        _ line: ConsoleString,
        terminator: String = "\n"
    ) {
        if Self.isNoColorSpecified || !output.capabilityFlags.contains(.ansiControlSequences) {
            print(line.unformatted(), terminator: terminator, to: &outputSink)
        } else {
            print(line.terminalFormatted(), terminator: terminator, to: &outputSink)
        }
    }

    private func _runTPut(arguments: [String]) throws {
        #if !Xcode

        #if os(Linux)

        try Process.run(_tputUrl, arguments: arguments).waitUntilExit()

        #elseif os(macOS)

        if #available(macOS 10.13, *) {
            try Process.run(_tputUrl, arguments: arguments).waitUntilExit()
        } else {
            let process =
                Process.launchedProcess(
                    launchPath: "/usr/bin/tput",
                    arguments: arguments
                )

            process.waitUntilExit()
        }

        #endif // os(Linux)

        #endif // !Xcode
    }

    open func recordExitCode(_ code: Int) {
        errno = Int32(code)
    }

    public func makePages() -> Pages {
        return makePages(configuration: Pages.PageDisplayConfiguration())
    }

    public func makePages(configuration: Pages.PageDisplayConfiguration) -> Pages {
        return Pages(console: self, configuration: configuration)
    }

    /// Measures the number of visible characters for a given console string input.
    static func measureString(_ consoleString: ConsoleString) -> Int {
        consoleString.unformatted().count
    }

    /// Measures the number of visible characters for a given console string input.
    static func measureString(_ string: String) -> Int {
        do {
            // Regex to ignore ASCII coloring from string
            let regex = try NSRegularExpression(
                pattern: "\\e\\[(\\d+;)*(\\d+)?[ABCDHJKfmsu]",
                options: []
            )

            let range = NSRange(location: 0, length: (string as NSString).length)

            let results = regex.matches(in: string, options: [], range: range)
            let removed = results.reduce(0) { $0 + $1.range.length }

            return string.count - removed
        } catch {
            return string.count
        }
    }

    /// Helper closure for clarifying behavior of commands and actions that
    /// result in an interaction with the upper menu
    public enum CommandMenuResult {
        /// Loops the menu again
        case loop

        /// Quits the active menu back
        case quit
    }

    public enum ConsoleParseError: Error {
        case invalidInput
    }

    private final class OutputSink: TextOutputStream {
        var forward: (String) -> ()

        init(forward: @escaping (String) -> ()) {
            self.forward = forward
        }

        func write(_ string: String) {
            forward(string)
        }
    }
}

/// Standard output text stream
public class StandardOutputTextStream: ConsoleOutputStream {
    public var capabilityFlags: ConsoleOutputCapabilityFlag {
        #if Xcode
            return []
        #else
            if supportColors {
                return [.ansiControlSequences]
            } else {
                return []
            }
        #endif
    }

    let supportColors: Bool

    public init(supportColors: Bool = true) {
        self.supportColors = supportColors
    }

    public func write(_ string: String) {
        print(string, separator: "", terminator: "")
    }
}

/// Standard error text stream
public class StandardErrorTextStream: ConsoleOutputStream {
    public var capabilityFlags: ConsoleOutputCapabilityFlag {
        #if Xcode
            return []
        #else
            if supportColors {
                return [.ansiControlSequences]
            } else {
                return []
            }
        #endif
    }

    let supportColors: Bool

    public init(supportColors: Bool = true) {
        self.supportColors = supportColors
    }

    public func write(_ string: String) {
        print(string, separator: "", terminator: "", to: &standardError)
    }
}

/// An output stream that discards all print calls.
public class NullOutputStream: ConsoleOutputStream {
    public var capabilityFlags: ConsoleOutputCapabilityFlag { [] }

    public init() {
    }

    public func write(_ string: String) {
    }
}

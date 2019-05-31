#if os(macOS)
import Foundation
#elseif os(Linux)
import Glibc
#endif

/// A publicly-facing protocol for console clients
public protocol ConsoleClient {
    /// Displays an items table on the console.
    func displayTable(withValues values: [[String]], separator: String)
    
    /// Reads a line from the console, re-prompting the user until they enter
    /// a non-empty line.
    ///
    /// - Parameter prompt: Prompt to display to the user
    /// - Returns: Result of the prompt
    func readSureLineWith(prompt: String) -> String
    
    /// Reads a line from the console, performing some validation steps with the
    /// user's input.
    ///
    /// - Parameters:
    ///   - prompt: Textual prompt to present to the user
    ///   - allowEmpty: Whether the method allows empty inputs - empty inputs
    /// finish the console input and return `nil`.
    ///   - validate: A validation method applied to every input attempt by the user.
    /// If the method returns false, the user is re-prompted until a valid input
    /// is provided.
    /// - Returns: First input that was correctly validated, or if `allowEmpty` is
    /// `true`, an empty input line, if the user specified no input.
    func readLineWith(prompt: String, allowEmpty: Bool, validate: (String) -> Bool) -> String?
    
    /// Reads a line from the console, performing a parsing step with the user's
    /// input.
    ///
    /// The method then either returns a non-nil value for the parsing result, or nil,
    /// in case the parsing was aborted/the user entered an empty string with `allowEmpty`
    /// as `true` 
    ///
    /// - Parameters:
    ///   - prompt: Textual prompt to present to the user
    ///   - allowEmpty: Whether the method allows empty inputs - empty inputs
    /// finish the console input and return `nil`.
    ///   - parse: A parsing method that parses the user's input string and returns it.
    /// - Returns: First input value that was correctly parsed, or if `allowEmpty` is
    /// `true`, nil, if the user specified no input.
    func parseLineWith<T>(prompt: String, allowEmpty: Bool, parse: (String) -> ValueReadResult<T>) -> T?
    
    /// Reads a line from the console, showing a given prompt to the user.
    func readLineWith(prompt: String) -> String?
    
    /// Prints an empty line feed into the console
    func printLine()
    
    /// Prints a line into the console's output with a linefeed terminator
    func printLine(_ line: String)
    
    /// Prints a line into the console's output, with a given terminator
    func printLine(_ line: String, terminator: String)
    
    /// Performs a terminal command to navigate/alter the output.
    func command(_ command: Terminal.Command)
    
    /// Clears the entire screen buffer
    func clearScreen()
    
    /// Starts running an alternative screen buffer on which the subsequent output
    /// should be displayed in.
    /// Does nothing if already in alternative screen buffer mode.
    func startAlternativeScreenBuffer()
    
    /// Return from the alternative screen buffer.
    /// Does nothing if not currently in alternative screen buffer mode.
    func stopAlternativeScreenBuffer()
    
    /// Called to record the given exit code for the console's program
    func recordExitCode(_ code: Int)
    
    /// Makes a new paging client
    func makePages() -> Pages
    
    /// Makes a new paging client with a given set of configurations
    func makePages(configuration: Pages.PageDisplayConfiguration) -> Pages
}

public enum ValueReadResult<T> {
    case success(T)
    case error(String?)
    case abort
}

/// Helper console-interation interface
open class Console: ConsoleClient {
    private var outputSink: OutputSink
    
    private var isInAlternativeBuffer = false
    
    /// Target output stream to print messages to
    public final var output: TextOutputStream
    
    /// If true, erases scrollback when calling `eraseScreen`.
    /// Defaults to true.
    public var eraseScrollback: Bool = true
    
    /// Initializes this console class with the default standard output stream
    public convenience init() {
        self.init(output: StandardOutputTextStream())
    }
    
    /// Initializes this console class with a custom output stream
    public init(output: TextOutputStream) {
        self.output = output
        outputSink = OutputSink(forward: { _ in })
        
        outputSink = OutputSink { [weak self] str in
            self?.output.write(str)
        }
    }
    
    /// Displays a table-layouted list of values on the console.
    ///
    /// The value matrix is interpreted as an array of lines, with an inner array
    /// of elements within.
    ///
    /// The table is automatically adjusted so the columns are spaced evenly
    /// across strings of multiple lengths.
    open func displayTable(withValues values: [[String]], separator: String) {
        // Measure maximum length of values on each column
        var columnWidths: [Int] = []
        
        for line in values {
            for (i, cell) in line.enumerated() {
                // Make sure we have the minimum ammount of storage for storing
                // this column
                while(columnWidths.count <= i) {
                    columnWidths.append(0)
                }
                
                columnWidths[i] = max(columnWidths[i], Console.measureString(cell))
            }
        }
        
        // Print columns now
        for line in values {
            for (i, row) in line.enumerated() {
                if(i < line.count - 1) {
                    let rowLength = Console.measureString(row)
                    let spaces = String(repeating: " ", count: columnWidths[i] - rowLength)
                    
                    printLine("\(row)\(separator)\(spaces)", terminator: "")
                } else {
                    printLine(row, terminator: "")
                }
            }
            printLine()
        }
    }
    
    open func readSureLineWith(prompt: String) -> String {
        repeat {
            guard let input = readLineWith(prompt: prompt) else {
                printLine("Invalid input")
                continue
            }
            
            return input
        } while true
    }
    
    open func readLineWith(prompt: String,
                           allowEmpty: Bool = true,
                           validate: (String) -> Bool = { _ in true }) -> String? {
        
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

    open func parseLineWith<T>(prompt: String,
                               allowEmpty: Bool,
                               parse: (String) -> ValueReadResult<T>) -> T? {
        
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
    
    open func readIntWith(prompt: String, validate: (Int) -> Bool = { _ in true }) -> Int? {
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
    
    open func readLineWith(prompt: String) -> String? {
        printLine(prompt, terminator: " ")
        return readLine()
    }
    
    open func printLine() {
        print(to: &outputSink)
    }
    
    open func printLine(_ line: String) {
        print(line, to: &outputSink)
    }
    
    open func printLine(_ line: String, terminator: String) {
        print(line, terminator: terminator, to: &outputSink)
    }

    open func command(_ command: Terminal.Command) {
        #if !Xcode
        printLine(command.ansi, terminator: "")
        #endif
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
        
        #if !Xcode && os(macOS)
        let process =
            Process
                .launchedProcess(launchPath: "/usr/bin/tput",
                                 arguments: ["smcup"])

        process.waitUntilExit()
        #endif
        
        isInAlternativeBuffer = true
    }
    
    open func stopAlternativeScreenBuffer() {
        if !isInAlternativeBuffer {
            return
        }
        
        #if !Xcode && os(macOS)
        let process =
            Process
                .launchedProcess(launchPath: "/usr/bin/tput",
                                 arguments: ["rmcup"])

        process.waitUntilExit()
        #endif
        
        isInAlternativeBuffer = false
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
    
    /// Measures the number of visible characters for a given string input
    static func measureString(_ string: String) -> Int {
        return lengthWithNoAnsiCommands(string)
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
public class StandardOutputTextStream: TextOutputStream {
    public func write(_ string: String) {
        print(string, separator: "", terminator: "")
    }
}


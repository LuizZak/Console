/// A publicly-facing protocol for console clients
public protocol ConsoleType {
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
    ///   - validate: A validation method applied to every input attempt by the
    /// user. If the method returns false, the user is re-prompted until a valid
    /// input is provided.
    /// - Returns: First input that was correctly validated, or if `allowEmpty` is
    /// `true`, an empty input line, if the user specified no input.
    func readLineWith(prompt: String, allowEmpty: Bool, validate: (String) -> Bool) -> String?

    /// Reads a line from the console, performing a parsing step with the user's
    /// input.
    ///
    /// The method then either returns a non-nil value for the parsing result, or
    /// nil, in case the parsing was aborted/the user entered an empty string with
    /// `allowEmpty` as `true`.
    ///
    /// - Parameters:
    ///   - prompt: Textual prompt to present to the user
    ///   - allowEmpty: Whether the method allows empty inputs - empty inputs
    /// finish the console input and return `nil`.
    ///   - parse: A parsing method that parses the user's input string and returns
    /// a result.
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

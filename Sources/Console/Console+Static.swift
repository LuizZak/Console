import Foundation

public extension Console {
    /// Returns `true` if the "NO_COLOR" environment variable is specified, and
    /// has a non-empty string value (a.k.a the ["NO_COLOR" convention]).
    ///
    /// Used internally by Console to force all strings to be emitted free of
    /// console formatting.
    ///
    /// This only applies to ANSI escape sequences that change the formatting of
    /// the text; sequences that contain cursor or display/line commands are still
    /// issued.
    ///
    /// ["NO_COLOR" convention]: https://no-color.org/
    static var isNoColorSpecified: Bool {
        let noColor = ProcessInfo.processInfo.environment["NO_COLOR"]
        return noColor != nil && noColor != ""
    }

    /// Returns `true` if the standard input file descriptor (`stdin`) is a
    /// terminal.
    static func isTerminalStandardInput() -> Bool {
        isatty(fileno(stdin)) == 1
    }

    /// Returns `true` if the standard output file descriptor (`stdout`) is a
    /// terminal.
    static func isTerminalStandardOutput() -> Bool {
        isatty(fileno(stdout)) == 1
    }

    /// Returns `true` if the standard error file descriptor (`stderr`) is a
    /// terminal.
    static func isTerminalStandardError() -> Bool {
        isatty(fileno(stderr)) == 1
    }
}

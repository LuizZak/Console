import Foundation

public extension Console {
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

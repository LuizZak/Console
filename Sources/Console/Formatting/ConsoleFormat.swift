/// A formatting setting for a string to be printed on a terminal.
public enum ConsoleFormat: UInt8 {
    /// A reset console format command that resets all attributes to the default.
    case reset = 0

    /// A bold console format style.
    case bold = 1

    /// A faint/dim/light font weight style.
    case light = 2

    /// An italic text format style.
    case italic = 3

    /// An underlined text format style.
    case underline = 4

    /// Converts this console format command into an ANSI escape command.
    ///
    /// Returns `"\e[\(self)m"`
    public var ansi: String {
        rawValue.ansi
    }
}

extension UInt8 {
    /// Converts a UInt8 to an ANSI code.
    ///
    /// Returns `"\e[\(self)m"`
    public var ansi: String {
        return (self.description + "m").ansi
    }
}

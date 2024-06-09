/// A refinement of `TextOutputStream` that also indicates the capabilities of
/// the text output stream.
public protocol ConsoleOutputStream: TextOutputStream {
    /// Gets the capabilities specified for this text output stream.
    var capabilityFlags: ConsoleOutputCapabilityFlag { get }
}

/// Indicates capabilities for `ConsoleOutputStream` types.
public struct ConsoleOutputCapabilityFlag: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    //

    /// Specifies that the output stream supports ANSI control sequences for
    /// changing formatting of the text displayed or moving the cursor/screen.
    public static let ansiControlSequences: Self = Self(rawValue: 1 << 0)
}

// MARK: - Default conformances

extension String: ConsoleOutputStream {
    public var capabilityFlags: ConsoleOutputCapabilityFlag { [] }
}

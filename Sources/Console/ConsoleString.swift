/// A string structure that supports interpolating values with console formatting
/// commands.
public struct ConsoleString: Hashable, ExpressibleByStringInterpolation {
    /// The segments that form this string.
    public var segments: [Segment]

    public init(stringLiteral value: String) {
        self.segments = [.literal(value)]
    }

    public init(stringInterpolation: Interpolation) {
        self.segments = stringInterpolation.segments
    }

    /// Initializes this console string with a string, stripping it of ANSI
    /// escape sequences in the process.
    public init(stripping string: String) {
        self.segments = [
            .literal(string.stripTerminalFormatting())
        ]
    }

    /// Initializes a console string with a given set of segments.
    public init(segments: [Segment]) {
        self.segments = segments
    }

    /// Returns a string that contains the ANSI escape sequences for formatting
    /// the segments of this console string, with a set of default background,
    /// foreground, and format settings for the base text.
    public func terminalFormatted(
        background: ConsoleColor? = nil,
        foreground: ConsoleColor? = nil,
        format: ConsoleFormat? = nil
    ) -> String {
        var result = ""
        var current: SegmentFormatting = .init(
            background: background,
            foreground: foreground,
            format: format
        )

        for segment in segments {
            switch segment {
            case .literal(let value):
                result += value

            case .formatted(let value, let format):
                result += format.ansi
                result += value
                result += current.ansi

            case .formatSet(let format):
                current = format
                result += current.ansi

            case .consoleString(let value):
                result += value.terminalFormatted(
                    background: current.background,
                    foreground: current.foreground,
                    format: current.format
                )
                result += current.ansi
            }
        }

        return result
    }

    /// Returns a string that contains the raw string literals without extra
    /// terminal formatting ANSI escape sequences added in.
    ///
    /// - note: If literal string segments themselves contain ANSI escape sequences,
    /// the method still returns them as-is.
    public func unformatted() -> String {
        var result = ""

        for segment in segments {
            switch segment {
            case .literal(let value):
                result += value

            case .formatted(let value, _):
                result += value

            case .consoleString(let value):
                result += value.unformatted()

            case .formatSet:
                break
            }
        }

        return result
    }

    /// A segment of a console string.
    public enum Segment: Hashable {
        /// An unformatted segment.
        case literal(String)

        /// A segment string that has color and formatting information.
        ///
        /// Overrides preceding `formatSet()` segments temporarily.
        case formatted(String, SegmentFormatting)

        /// A non-content segment that indicates a change of the formatting
        /// for the remainder of the string.
        case formatSet(SegmentFormatting)

        /// A nested console string segment.
        case consoleString(ConsoleString)
    }

    /// Holds formatting information about a console string's segment.
    public struct SegmentFormatting: Hashable {
        /// A background to apply.
        public var background: ConsoleColor?

        /// A foreground to apply.
        public var foreground: ConsoleColor?

        /// A font formatting to apply.
        public var format: ConsoleFormat?

        /// Returns an ANSI console command code for this formatting specifier.
        ///
        /// Returns `"\e[<background>;<foreground>;<format>m"`, omitting each
        /// element if they are `nil`.
        ///
        /// If all values are `nil`, the command returned is `"\e[m"`, which
        /// equates to a full color/format reset.
        public var ansi: String {
            var args: [String] = []
            if let background = background {
                args.append(background.terminalBackground.description)
            }
            if let foreground = foreground {
                args.append(foreground.terminalForeground.description)
            }
            if let format {
                args.append(format.rawValue.description)
            }

            let command = args.joined(separator: ";") + "m"
            return command.ansi
        }

        public init(
            background: ConsoleColor? = nil,
            foreground: ConsoleColor? = nil,
            format: ConsoleFormat? = nil
        ) {
            self.background = background
            self.foreground = foreground
            self.format = format
        }
    }
}

extension ConsoleString {
    /// An interpolation constructor for console strings.
    public struct Interpolation: StringInterpolationProtocol {
        public typealias StringLiteralType = String
        var segments: [Segment] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            segments = []
        }

        /// Appends a segment as an unformatted literal.
        public mutating func appendLiteral(_ literal: String) {
            segments.append(.literal(literal))
        }

        /// Appends an unformatted interpolation of a given string-convertible
        /// value.
        public mutating func appendInterpolation(_ value: any CustomStringConvertible) {
            appendLiteral(value.description)
        }

        /// Appends a console string as an interpolation into this string.
        public mutating func appendInterpolation(formatted: ConsoleString) {
            segments.append(.consoleString(formatted))
        }

        /// Appends a formatted interpolation of a given string-convertible
        /// value with a given color.
        public mutating func appendInterpolation(
            _ value: any CustomStringConvertible,
            color: ConsoleColor? = nil,
            backgroundColor: ConsoleColor? = nil,
            format: ConsoleFormat? = nil
        ) {
            let format = SegmentFormatting(
                background: backgroundColor,
                foreground: color,
                format: format
            )

            segments.append(.formatted(value.description, format))
        }

        /// Appends a formatted interpolation of a given string-convertible
        /// value with a given format.
        public mutating func appendInterpolation(
            _ value: any CustomStringConvertible,
            format: ConsoleFormat
        ) {
            segments.append(.formatted(value.description, .init(format: format)))
        }

        /// Appends an interpolation that indicates that the string should have
        /// a given console color and text formatting from then on.
        public mutating func appendInterpolation(
            color: ConsoleColor? = nil,
            backgroundColor: ConsoleColor? = nil,
            format: ConsoleFormat? = nil
        ) {
            let format = SegmentFormatting(
                background: backgroundColor,
                foreground: color,
                format: format
            )

            segments.append(.formatSet(format))
        }
    }
}

// MARK: - Operators

public extension ConsoleString {
    /// Concatenates two console string values, returning a single console string
    /// containing both of the string's segments in sequence.
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(segments: lhs.segments + rhs.segments)
    }

    /// Concatenates a string literal and a console string value, returning a
    /// single console string containing both of the string's segments in
    /// sequence.
    static func + (lhs: String, rhs: Self) -> Self {
        .init(segments: [.literal(lhs)] + rhs.segments)
    }

    /// Concatenates a console string and a string literal value, returning a
    /// single console string containing both of the string's segments in
    /// sequence.
    static func + (lhs: Self, rhs: String) -> Self {
        .init(segments: lhs.segments + [.literal(rhs)])
    }

    /// Concatenates two console string values into `lhs`, assigning it a console
    /// string containing both of the string's segments in sequence.
    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Concatenates a string segment into a console string, assigning it a console
    /// string containing both of the string's segments in sequence.
    static func += (lhs: inout Self, rhs: String) {
        lhs = lhs + rhs
    }
}

// This code is based off Vapor's Console library
//
// http://github.com/vapor/console
//

/// Underlying colors for console styles.
public enum ConsoleColor {
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case `default`
}

extension ConsoleColor {
    /// Returns the foreground terminal color code for the `ConsoleColor`.
    public var terminalForeground: UInt8 {
        switch self {
        case .black:
            return 30
        case .red:
            return 31
        case .green:
            return 32
        case .yellow:
            return 33
        case .blue:
            return 34
        case .magenta:
            return 35
        case .cyan:
            return 36
        case .white:
            return 37
        case .default:
            return 39
        }
    }

    /// Returns the background terminal color code for the `ConsoleColor`.
    public var terminalBackground: UInt8 {
        switch self {
        case .black:
            return 40
        case .red:
            return 41
        case .green:
            return 42
        case .yellow:
            return 43
        case .blue:
            return 44
        case .magenta:
            return 45
        case .cyan:
            return 46
        case .white:
            return 47
        case .default:
            return 49
        }
    }
}

// This code is based off Vapor's Console library
//
// http://github.com/vapor/console
//

public enum Terminal {

}

public extension Terminal {
    /// Available terminal commands.
    enum Command {
        /// Move home command (`\e[2J`)
        public static let moveHome = move(.home)

        /// Erase screen control sequence (`\e[2J`)
        public static let eraseScreen = eraseInScreen(.all)

        /// Erase screen and all scroll control sequence (`\e[3J`)
        public static let eraseScreenAndScrollback = eraseInScreen(.allAndScrollback)

        /// Erase entire line control sequence (`\e[2K`)
        public static let eraseLine = eraseInLine(.all)

        /// Move cursor command (`\e[..;..H`)
        case move(Position)

        /// Erase screen control sequence (`\e[..J`)
        case eraseInScreen(EraseInDisplay)

        /// Erase in Line control sequence (`\e[..K`)
        case eraseInLine(EraseInLine)

        /// Move cursor up control sequence (`\e[..A`)
        case cursorUp(Int = 1)

        /// Move cursor down control sequence (`\e[..B`)
        case cursorDown(Int = 1)

        /// Move cursor forward control sequence (`\e[..C`)
        case cursorForward(Int = 1)

        /// Move cursor back control sequence (`\e[..D`)
        case cursorBack(Int = 1)
    }
}

public extension Terminal.Command {
    /// Arguments for a Cursor Position (`Command.move`, `\e[..;..H`) command.
    ///
    /// - note: Positions are 1-based, i.e. row 1 column 1 is the top-left of the
    /// terminal.
    enum Position {
        /// Move home, or top-left ("`\e[H`")
        case home

        /// Move to a given row, on the left column ("`\e[<row>;H`")
        case row(Int)

        /// Move to a given column, on the topmost row ("`\e[;<column>H`")
        case column(Int)

        /// Move to a given column/row ("`\e[<row>;<column>H`")
        case rowAndColumn(Int, Int)

        /// Converts this value into its ansi values.
        public var ansiValues: String {
            switch self {
            case .home:
                return ""
            case .row(let row):
                return "\(row);"
            case .column(let column):
                return ";\(column)"
            case .rowAndColumn(let row, let column):
                return "\(row);\(column)"
            }
        }
    }

    /// Arguments for a cursor Erase in Display (`Command.eraseInLine`, `\e[..J`)
    /// command.
    enum EraseInDisplay {
        /// Erases from the cursor's position to the end of the display.
        case toEnd

        /// Erases from the cursor's position to the beginning of the display.
        case toBeginning

        /// Erases the entire display.
        case all

        /// Erases the entire display, and all scrollback.
        case allAndScrollback

        /// Converts this value into its ansi values.
        public var ansiValues: String {
            switch self {
            case .toEnd: "0"
            case .toBeginning: "1"
            case .all: "2"
            case .allAndScrollback: "3"
            }
        }
    }

    /// Arguments for a cursor Erase in Line (`Command.eraseInLine`, `\e[..K`)
    /// command.
    enum EraseInLine {
        /// Erases entire line.
        case all

        /// Erases from cursor's position to the beginning of the line.
        case toBeginning

        /// Erases from cursor's position to the end of the line.
        case toEnd

        /// Converts this value into its ansi values.
        public var ansiValues: String {
            switch self {
            case .all: "2"
            case .toBeginning: "1"
            case .toEnd: "0"
            }
        }
    }
}

public extension Terminal.Command {
    /// Converts the command to its ansi code.
    /// Returns `"\033[\(self)"`
    var ansi: String {
        switch self {
        case .move(let args):
            return "\(args.ansiValues)H".ansi

        case .eraseInScreen(let args):
            return "\(args.ansiValues)J".ansi

        case .eraseInLine(let args):
            return "\(args.ansiValues)K".ansi

        case .cursorUp(let count):
            return "\(count)A".ansi

        case .cursorDown(let count):
            return "\(count)B".ansi

        case .cursorForward(let count):
            return "\(count)C".ansi

        case .cursorBack(let count):
            return "\(count)D".ansi
        }
    }
}

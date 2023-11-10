import Foundation

// This code is based off Vapor's Console library
//
// http://github.com/vapor/console
//

extension String {
    /// Wraps this string in the format attribute indicated by the given
    /// terminal format code.
    public func terminalFormat(_ style: ConsoleFormat) -> String {
        #if !Xcode
            return style.rawValue.ansi + self + ConsoleFormat.reset.ansi
        #else
            return self
        #endif
    }

    /**
     Wraps a string in the color indicated
     by the UInt8 terminal color code.
     */
    public func terminalColorize(_ color: ConsoleColor) -> String {
        #if !Xcode
            return color.terminalForeground.ansi + self + UInt8(0).ansi
        #else
            return self
        #endif
    }

    /// Strings this entire string of terminal formatting commands.
    public func stripTerminalFormatting() -> String {
        #if !Xcode
            guard let regex = try? NSRegularExpression(pattern: "\\e\\[(\\d+;)*(\\d+)?[ABCDHJKfmsu]", options: []) else {
                return self
            }
            
            let results = regex
                .matches(
                    in: self,
                    options: [],
                    range: NSRange(location: 0, length: self.utf16.count)
                )
            //let removed = results.reduce(0) { $0 + $1.range.length }
            
            // Remove ranges in descending order
            
            var output = self
            
            for res in results.sorted(by: { $0.range.location > $1.range.location }) {
                let startIndex = output.index(
                    output.startIndex,
                    offsetBy: res.range.location
                )
                let endIndex = output.index(
                    output.startIndex,
                    offsetBy: res.range.location + res.range.length
                )
                
                output.removeSubrange(startIndex..<endIndex)
            }
            
            return output
        #else
            return self
        #endif
    }
    
    /**
     Strips this entire string of terminal color commands
     */
    @available(*, renamed: "stripTerminalFormatting()")
    public func stripTerminalColors() -> String {
        stripTerminalFormatting()
    }
}

extension String {
    /**
     Converts a String to a full ANSI command.
     */
    public var ansi: String {
        return "\u{001B}[" + self
    }
}

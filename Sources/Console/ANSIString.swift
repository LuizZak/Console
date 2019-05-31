#if os(macOS)
import Foundation
#elseif os(Linux)
import Glibc
#endif

func stripAnsiCommands(_ string: String) throws -> String {
    #if os(macOS)
    
    guard let regex = try? NSRegularExpression(pattern: "\\e\\[(\\d+;)*(\\d+)?[ABCDHJKfmsu]", options: []) else {
        return string
    }
    
    let results = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
    
    // Remove ranges in descending order
    var output = string
    
    for res in results.sorted(by: { $0.range.location > $1.range.location }) {
        let startIndex = output.index(output.startIndex, offsetBy: res.range.location)
        let endIndex = output.index(output.startIndex, offsetBy: res.range.location + res.range.length)
        
        output.removeSubrange(startIndex..<endIndex)
    }
    
    return output
    
    #else
    
    let matches = try regexpMatches(regex: "\u{001B}\\[([0-9]]+;)*([0-9]+)?[ABCDHJKfmsu]", in: string)
    var result = string
    
    for match in matches.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
        result.removeSubrange(match.range)
    }
    
    return result
    
    #endif
}

func lengthWithNoAnsiCommands(_ string: String) -> Int {
    return (try? stripAnsiCommands(string).count) ?? string.count
}

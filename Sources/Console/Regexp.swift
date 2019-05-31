#if os(macOS)
import Darwin.C
#elseif os(Linux)
import Glibc
#endif

struct RegexpMatch {
    var range: Range<String.Index>
}

func regexpMatches(regex regexString: String, in string: String) throws -> [RegexpMatch] {
    guard let cString = string.cString(using: .utf8) else {
        return []
    }
    
    let cStringBuffer = UnsafeBufferPointer(start: cString, count: cString.count)
    guard let cStringPointer = cStringBuffer.baseAddress else {
        return []
    }
    
    var cPointerOffset = 0
    
    let maxMatches = 1024
    
    var result: [RegexpMatch] = []
    var matches: [regmatch_t] = [regmatch_t](repeating: regmatch_t(), count: 1)
    var regex = regex_t()
    
    if regexString.withCString({ cString in regcomp(&regex, cString, REG_EXTENDED) }) != 0 {
        throw RegexError.invalidRegexString
    }
    
    for _ in 0..<maxMatches {
        if cPointerOffset >= cStringBuffer.count {
            break
        }
        
        #if os(Linux)
        if regexec(&regex, cStringPointer + cPointerOffset, 1, &matches, 0) == Int32(REG_NOMATCH.rawValue) {
            break
        }
        #else
        if regexec(&regex, cStringPointer + cPointerOffset, 1, &matches, 0) == REG_NOMATCH {
            break
        }
        #endif
        
        var matched: Bool = false
        
        for match in matches where match.rm_so != -1 {
            let start = string.index(string.startIndex, offsetBy: cPointerOffset + Int(match.rm_so))
            let end = string.index(string.startIndex, offsetBy: cPointerOffset + Int(match.rm_eo))
            
            cPointerOffset += Int(match.rm_eo)
            
            result.append(RegexpMatch(range: start..<end))
            
            matched = true
        }
        
        if !matched {
            break
        }
    }
    
    return result
}

enum RegexError: Error {
    case invalidRegexString
}

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
    
    let maxMatches = 1024
    
    var result: [RegexpMatch] = []
    var matches: [regmatch_t] = [regmatch_t](repeating: regmatch_t(), count: maxMatches)
    var regex = regex_t()
    
    if regexString.withCString({ cString in regcomp(&regex, cString, Int32(strlen(cString))) }) != 0 {
        throw RegexError.invalidRegexString
    }
    
    #if os(Linux)
    if regexec(&regex, cString, maxMatches, &matches, 0) == Int32(REG_NOMATCH.rawValue) {
        return []
    }
    #else
    if regexec(&regex, cString, maxMatches, &matches, 0) == REG_NOMATCH {
        return []
    }
    #endif
    
    for match in matches where match.rm_so != -1 {
        let start = string.index(string.startIndex, offsetBy: Int(match.rm_so))
        let end = string.index(string.startIndex, offsetBy: Int(match.rm_eo))
        
        result.append(RegexpMatch(range: start..<end))
    }
    
    return result
}

enum RegexError: Error {
    case invalidRegexString
}

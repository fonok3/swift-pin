/// - `"AppComponent"` → `"appComponent"`
/// - `"AFNetworkClient"` → `"afNetworkClient"`
/// - `"URLSession"` → `"urlSession"`
/// - `"URL"` → `"url"`
public func lowercasePrefix(_ string: String) -> String {
    let chars = Array(string)
    guard !chars.isEmpty else {
        return string
    }

    var uppercaseCount = 0
    for char in chars {
        guard char.isUppercase else {
            break
        }
        uppercaseCount += 1
    }

    guard uppercaseCount > 0 else {
        return string
    }

    if uppercaseCount == chars.count {
        return string.lowercased()
    }

    if uppercaseCount == 1 {
        return chars[0].lowercased() + String(chars[1...])
    }

    let lowered = String(chars[0..<(uppercaseCount - 1)]).lowercased()
    let rest = String(chars[(uppercaseCount - 1)...])
    return lowered + rest
}

private enum SwiftKeywords {
    static let all: Set<String> = [
        // Declarations
        "associatedtype", "class", "deinit", "enum", "extension",
        "fileprivate", "func", "import", "init", "inout", "internal",
        "let", "open", "operator", "private", "precedencegroup",
        "protocol", "public", "rethrows", "static", "struct",
        "subscript", "typealias", "var",
        // Statements
        "break", "case", "catch", "continue", "default", "defer",
        "do", "else", "fallthrough", "for", "guard", "if", "in",
        "repeat", "return", "switch", "throw", "where", "while",
        // Expressions & types
        "as", "any", "false", "is", "nil", "super",
        "self", "Self", "throws", "true", "try",
        // Patterns
        "_"
    ]
}

public func escapedIfKeyword(_ name: String) -> String {
    SwiftKeywords.all.contains(name) ? "`\(name)`" : name
}

/// Does not handle backtick-escaped keywords such as `` `default` ``.
public func isValidSwiftIdentifier(_ string: String) -> Bool {
    guard let first = string.first,
        first == "_" || first.isLetter
    else {
        return false
    }
    return string.dropFirst().allSatisfy { $0 == "_" || $0.isLetter || $0.isNumber }
}

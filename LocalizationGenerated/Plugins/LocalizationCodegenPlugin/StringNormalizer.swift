import Foundation

/// Utility for normalizing strings to valid Swift identifiers
enum StringNormalizer {

  /// Convert a localization key to a valid Swift identifier
  /// - Parameter key: Original localization key (e.g., "Day 1", "Code of Conduct")
  /// - Returns: Valid Swift identifier (e.g., "day1", "codeOfConduct")
  ///
  /// Rules:
  /// - Converts to camelCase
  /// - Removes special characters
  /// - Starts with lowercase letter
  /// - Falls back to generic name if conversion fails
  static func toSwiftIdentifier(_ key: String) -> String {
    // Remove leading/trailing whitespace
    var identifier = key.trimmingCharacters(in: .whitespacesAndNewlines)

    // If empty, use placeholder
    if identifier.isEmpty {
      return "empty"
    }

    // Split into words
    let words = identifier.components(separatedBy: .whitespaces)
      .map { word in
        // Remove non-alphanumeric characters
        word.unicodeScalars
          .filter { CharacterSet.alphanumerics.contains($0) }
          .map { String($0) }
          .joined()
      }
      .filter { !$0.isEmpty }

    // Convert to camelCase
    guard !words.isEmpty else {
      // Fallback: hash the original string
      return "string\(abs(key.hashValue))"
    }

    let camelCase = words.enumerated().map { index, word in
      if index == 0 {
        return word.lowercased()
      } else {
        return word.prefix(1).uppercased() + word.dropFirst().lowercased()
      }
    }.joined()

    // Ensure it starts with a letter (not a number)
    if let firstChar = camelCase.first, firstChar.isNumber {
      return "string" + camelCase.capitalized
    }

    // Ensure it's not a Swift keyword
    if SwiftKeywords.contains(camelCase) {
      return "`\(camelCase)`"
    }

    return camelCase.isEmpty ? "string\(abs(key.hashValue))" : camelCase
  }

  /// Common Swift keywords that need escaping
  private static let SwiftKeywords: Set<String> = [
    "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
    "func", "import", "init", "inout", "internal", "let", "open", "operator",
    "private", "precedencegroup", "protocol", "public", "rethrows", "static",
    "struct", "subscript", "typealias", "var", "break", "case", "catch",
    "continue", "default", "defer", "do", "else", "fallthrough", "for",
    "guard", "if", "in", "repeat", "return", "throw", "switch", "where",
    "while", "as", "false", "is", "nil", "self", "Self", "super", "throws",
    "true", "try", "await", "async",
  ]
}

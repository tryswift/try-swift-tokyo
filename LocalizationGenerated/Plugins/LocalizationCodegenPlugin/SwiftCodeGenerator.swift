import Foundation

/// Generates Swift code from parsed localization entries
struct SwiftCodeGenerator {

  /// Generate Swift source code for a feature's localized strings
  /// - Parameters:
  ///   - featureName: Name of the feature (e.g., "Schedule", "TrySwift")
  ///   - entries: Parsed localization entries
  /// - Returns: Generated Swift source code as String
  static func generate(featureName: String, entries: [XCStringsParser.LocalizedEntry]) -> String {
    var output = """
      // Auto-generated from \(featureName)Feature/Localizable.xcstrings
      // DO NOT EDIT MANUALLY - Changes will be overwritten on next build
      // Generated on: \(ISO8601DateFormatter().string(from: Date()))

      import SharedModels

      public enum \(featureName)Strings {

      """

    // Group entries by heuristic: simple UI strings vs dynamic content
    let (simpleStrings, dynamicStrings) = categorize(entries: entries)

    // Generate static properties for simple strings
    if !simpleStrings.isEmpty {
      output += "\n    // MARK: - Simple Localized Strings\n\n"
      for entry in simpleStrings {
        let identifier = StringNormalizer.toSwiftIdentifier(entry.key)
        output += "    public static let \(identifier) = LocalizedString(\n"
        output += "        en: \(escape(entry.english)),\n"
        output += "        ja: \(escape(entry.japaneseOrEnglish))\n"
        output += "    )\n\n"
      }
    }

    // Generate dictionary-based lookup for ALL strings
    // This allows dynamic lookup via subscript for both simple and dynamic strings
    output += "    // MARK: - Dynamic Content Lookup\n\n"
    output += "    public static subscript(key: String) -> LocalizedString? {\n"
    output += "        stringMap[key]\n"
    output += "    }\n\n"
    output += "    private static let stringMap: [String: LocalizedString] = [\n"

    // Include ALL entries (both simple and dynamic) in the dictionary
    for entry in entries {
      output += "        \(escape(entry.key)): LocalizedString(\n"
      output += "            en: \(escape(entry.english)),\n"
      output += "            ja: \(escape(entry.japaneseOrEnglish))\n"
      output += "        ),\n"
    }

    output += "    ]\n"

    output += "}\n"

    return output
  }

  /// Categorize entries into simple strings (static properties) vs dynamic content (dictionary)
  /// Simple: Short strings (< 50 chars), likely UI labels
  /// Dynamic: Long strings, speaker bios, session descriptions
  private static func categorize(entries: [XCStringsParser.LocalizedEntry]) -> (
    simple: [XCStringsParser.LocalizedEntry], dynamic: [XCStringsParser.LocalizedEntry]
  ) {
    // If too many entries (> 100), use dictionary for everything
    if entries.count > 100 {
      return (simple: [], dynamic: entries)
    }

    var simple: [XCStringsParser.LocalizedEntry] = []
    var dynamic: [XCStringsParser.LocalizedEntry] = []

    for entry in entries {
      // Keys with hyphens (e.g., "akio-itaya-bio") should use dictionary lookup
      // to preserve the original key format for JSON compatibility
      let isDynamicKey = entry.key.contains("-") || entry.key.contains("_")

      // Heuristic: Simple strings are short and likely UI labels
      // Dynamic: Long strings, keys with special characters, speaker bios, session descriptions
      if !isDynamicKey && entry.key.count < 50 && !entry.key.contains("\n") {
        simple.append(entry)
      } else {
        dynamic.append(entry)
      }
    }

    return (simple: simple, dynamic: dynamic)
  }

  /// Escape string for Swift string literal
  /// Handles quotes, newlines, backslashes, etc.
  private static func escape(_ string: String) -> String {
    // Use multiline literal for strings with newlines
    if string.contains("\n") {
      let escaped =
        string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"\"\"", with: "\\\"\\\"\\\"")
      return "\"\"\"\n\(escaped)\n\"\"\""
    }

    // Single-line literal
    let escaped =
      string
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\t", with: "\\t")
      .replacingOccurrences(of: "\r", with: "\\r")

    return "\"\(escaped)\""
  }
}

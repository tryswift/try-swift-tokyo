import Foundation

/// Parser for .xcstrings (String Catalog) JSON format
struct XCStringsParser {

    /// Parsed localized string entry
    struct LocalizedEntry {
        let key: String
        let english: String
        let japanese: String?

        var japaneseOrEnglish: String {
            japanese ?? english
        }
    }

    /// Parse .xcstrings file and extract localized strings
    /// - Parameter fileURL: URL to .xcstrings file
    /// - Returns: Array of localized entries
    /// - Throws: DecodingError if JSON is invalid
    static func parse(fileURL: URL) throws -> [LocalizedEntry] {
        let data = try Data(contentsOf: fileURL)
        let catalog = try JSONDecoder().decode(StringCatalog.self, from: data)

        return catalog.strings.map { key, value in
            // English is the source language (key itself or explicit localization)
            let english = value.localizations?["en"]?.stringUnit?.value ?? key

            // Japanese translation (if available)
            let japanese = value.localizations?["ja"]?.stringUnit?.value

            return LocalizedEntry(
                key: key,
                english: english,
                japanese: japanese
            )
        }
        .sorted { $0.key < $1.key } // Sort for consistent output
    }
}

// MARK: - Codable Models for .xcstrings JSON

private struct StringCatalog: Codable {
    let sourceLanguage: String
    let strings: [String: StringEntry]
}

private struct StringEntry: Codable {
    let extractionState: String?
    let localizations: [String: Localization]?
}

private struct Localization: Codable {
    let stringUnit: StringUnit?
    let variations: Variations?

    struct StringUnit: Codable {
        let state: String?
        let value: String
    }

    struct Variations: Codable {
        // Placeholder for plural/device variations (not needed for current use case)
    }
}

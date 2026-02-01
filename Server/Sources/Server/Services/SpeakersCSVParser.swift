import Foundation
import SharedModels

/// Represents a parsed row from Google Form speaker candidate CSV
struct SpeakerCandidate: Sendable {
  let timestamp: String
  let email: String
  let name: String
  let sns: String
  let github: String
  let bio: String
  let expertise: String
  let speakingExperience: String
  let location: String
  let companySupport: String
  let title: String
  let summary: String
  let talkDetail: String
  let additionalNotes: String
}

/// Parser for Google Form speaker candidate CSV exports
enum SpeakersCSVParser {
  enum ParseError: Error, LocalizedError {
    case invalidHeader(actual: String)
    case invalidFormat(reason: String)
    case emptyFile

    var errorDescription: String? {
      switch self {
      case .invalidHeader(let actual):
        return "Invalid CSV header. Expected Google Form speaker candidate format. Got: \(actual)"
      case .invalidFormat(let reason):
        return "Invalid CSV format: \(reason)"
      case .emptyFile:
        return "CSV file is empty"
      }
    }
  }

  /// Expected CSV header prefix (Google Form)
  private static let expectedHeaderPrefix = "タイムスタンプ,Email,Your Name"

  /// Parse CSV content into SpeakerCandidate array
  static func parse(_ content: String) throws -> [SpeakerCandidate] {
    // Split by newlines but handle quoted fields that may contain newlines
    let records = splitCSVRecords(content)
    guard !records.isEmpty else {
      throw ParseError.emptyFile
    }

    // Validate header
    let header = records[0]
    guard header.hasPrefix(expectedHeaderPrefix) else {
      let preview = String(header.prefix(80))
      throw ParseError.invalidHeader(actual: preview)
    }

    guard records.count > 1 else {
      return []
    }

    var candidates: [SpeakerCandidate] = []

    for (index, record) in records.dropFirst().enumerated() {
      let trimmedRecord = record.trimmingCharacters(in: .whitespaces)
      guard !trimmedRecord.isEmpty else { continue }

      let columns = parseCSVLine(record)
      guard columns.count >= 15 else {
        throw ParseError.invalidFormat(
          reason:
            "Row \(index + 2) has insufficient columns (\(columns.count), expected at least 15)"
        )
      }

      // Skip rows without a talk title (incomplete submissions)
      let title = columns[12].trimmingCharacters(in: .whitespaces)
      guard !title.isEmpty else { continue }

      let candidate = SpeakerCandidate(
        timestamp: columns[0].trimmingCharacters(in: .whitespaces),
        email: columns[1].trimmingCharacters(in: .whitespaces),
        name: columns[2].trimmingCharacters(in: .whitespaces),
        sns: columns[5].trimmingCharacters(in: .whitespaces),
        github: columns[6].trimmingCharacters(in: .whitespaces),
        bio: columns[7].trimmingCharacters(in: .whitespaces),
        expertise: columns[8].trimmingCharacters(in: .whitespaces),
        speakingExperience: columns[9].trimmingCharacters(in: .whitespaces),
        location: columns[10].trimmingCharacters(in: .whitespaces),
        companySupport: columns[11].trimmingCharacters(in: .whitespaces),
        title: title,
        summary: columns[13].trimmingCharacters(in: .whitespaces),
        talkDetail: columns[14].trimmingCharacters(in: .whitespaces),
        additionalNotes: columns.count > 20
          ? columns[20].trimmingCharacters(in: .whitespaces)
          : ""
      )
      candidates.append(candidate)
    }

    return candidates
  }

  /// Build notes string from additional candidate info
  static func buildNotes(from candidate: SpeakerCandidate) -> String {
    var parts: [String] = []

    if !candidate.sns.isEmpty {
      parts.append("SNS: \(candidate.sns)")
    }
    if !candidate.expertise.isEmpty {
      parts.append("Expertise: \(candidate.expertise)")
    }
    if !candidate.speakingExperience.isEmpty {
      parts.append("Speaking Experience: \(candidate.speakingExperience)")
    }
    if !candidate.location.isEmpty {
      parts.append("Location: \(candidate.location)")
    }
    if !candidate.companySupport.isEmpty {
      parts.append("Company Travel Support: \(candidate.companySupport)")
    }
    if !candidate.additionalNotes.isEmpty {
      parts.append("Additional Notes: \(candidate.additionalNotes)")
    }

    return parts.joined(separator: "\n")
  }

  /// Build icon URL from GitHub username
  static func githubAvatarURL(from github: String) -> String? {
    let username =
      github
      .replacingOccurrences(of: "https://github.com/", with: "")
      .replacingOccurrences(of: "http://github.com/", with: "")
      .replacingOccurrences(of: "@", with: "")
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard !username.isEmpty else { return nil }
    return "https://github.com/\(username).png"
  }

  /// Extract GitHub username from various formats
  static func extractGitHubUsername(from github: String) -> String {
    github
      .replacingOccurrences(of: "https://github.com/", with: "")
      .replacingOccurrences(of: "http://github.com/", with: "")
      .replacingOccurrences(of: "@", with: "")
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  }

  // MARK: - CSV Parsing Helpers

  /// Split CSV content into records, handling quoted fields with embedded newlines
  private static func splitCSVRecords(_ content: String) -> [String] {
    var records: [String] = []
    var current = ""
    var inQuotes = false

    for char in content {
      if char == "\"" {
        inQuotes.toggle()
        current.append(char)
      } else if (char == "\n" || char == "\r") && !inQuotes {
        if char == "\r" { continue }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
          records.append(current)
        }
        current = ""
      } else {
        current.append(char)
      }
    }
    if !current.trimmingCharacters(in: .whitespaces).isEmpty {
      records.append(current)
    }
    return records
  }

  /// Parse a single CSV line handling quoted fields with embedded commas
  private static func parseCSVLine(_ line: String) -> [String] {
    var result: [String] = []
    var current = ""
    var inQuotes = false
    let chars = Array(line)
    var i = 0

    while i < chars.count {
      let char = chars[i]

      if char == "\"" {
        if inQuotes {
          if i + 1 < chars.count && chars[i + 1] == "\"" {
            current.append("\"")
            i += 1
          } else {
            inQuotes = false
          }
        } else {
          inQuotes = true
        }
      } else if char == "," && !inQuotes {
        result.append(current)
        current = ""
      } else {
        current.append(char)
      }

      i += 1
    }
    result.append(current)

    return result
  }
}

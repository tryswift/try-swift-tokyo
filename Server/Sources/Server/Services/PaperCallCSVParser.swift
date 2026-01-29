import Foundation
import SharedModels

/// Represents a parsed row from PaperCall CSV export
struct PaperCallProposal: Sendable {
  let id: String
  let title: String
  let abstract: String
  let talkDetails: String
  let duration: String
  let speakerName: String
  let speakerEmail: String
  let speakerUsername: String
  let bio: String
  let iconURL: String?
  let notes: String?
  let conference: String
  let submittedAt: String
}

/// Parser for PaperCall CSV exports
enum PaperCallCSVParser {
  enum ParseError: Error, LocalizedError {
    case invalidHeader(actual: String)
    case missingRequiredField(field: String, row: Int)
    case invalidFormat(reason: String)
    case emptyFile

    var errorDescription: String? {
      switch self {
      case .invalidHeader(let actual):
        return
          "Invalid CSV header. Expected: ID,Title,Abstract,Talk Details,Duration,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At. Got: \(actual)"
      case .missingRequiredField(let field, let row):
        return "Missing required field '\(field)' at row \(row)"
      case .invalidFormat(let reason):
        return "Invalid CSV format: \(reason)"
      case .emptyFile:
        return "CSV file is empty"
      }
    }
  }

  /// Expected CSV header
  private static let expectedHeader =
    "ID,Title,Abstract,Talk Details,Duration,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At"

  /// Parse CSV content into PaperCallProposal array
  static func parse(_ content: String) throws -> [PaperCallProposal] {
    let lines = content.components(separatedBy: .newlines)
    guard !lines.isEmpty else {
      throw ParseError.emptyFile
    }

    // Validate header
    let header = lines[0].trimmingCharacters(in: .whitespaces)
    guard header == expectedHeader else {
      throw ParseError.invalidHeader(actual: header)
    }

    guard lines.count > 1 else {
      return []
    }

    var proposals: [PaperCallProposal] = []

    for (index, line) in lines.dropFirst().enumerated() {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)
      guard !trimmedLine.isEmpty else { continue }

      let columns = parseCSVLine(line)
      guard columns.count >= 13 else {
        throw ParseError.invalidFormat(
          reason: "Row \(index + 2) has insufficient columns (\(columns.count), expected 13)")
      }

      let proposal = PaperCallProposal(
        id: columns[0].trimmingCharacters(in: .whitespaces),
        title: columns[1].trimmingCharacters(in: .whitespaces),
        abstract: columns[2].trimmingCharacters(in: .whitespaces),
        talkDetails: columns[3].trimmingCharacters(in: .whitespaces),
        duration: columns[4].trimmingCharacters(in: .whitespaces),
        speakerName: columns[5].trimmingCharacters(in: .whitespaces),
        speakerEmail: columns[6].trimmingCharacters(in: .whitespaces),
        speakerUsername: columns[7].trimmingCharacters(in: .whitespaces),
        bio: columns[8].trimmingCharacters(in: .whitespaces),
        iconURL: columns[9].trimmingCharacters(in: .whitespaces).isEmpty
          ? nil : columns[9].trimmingCharacters(in: .whitespaces),
        notes: columns[10].trimmingCharacters(in: .whitespaces).isEmpty
          ? nil : columns[10].trimmingCharacters(in: .whitespaces),
        conference: columns[11].trimmingCharacters(in: .whitespaces),
        submittedAt: columns[12].trimmingCharacters(in: .whitespaces)
      )
      proposals.append(proposal)
    }

    return proposals
  }

  /// Parse a single CSV line handling quoted fields with embedded commas and newlines
  private static func parseCSVLine(_ line: String) -> [String] {
    var result: [String] = []
    var current = ""
    var inQuotes = false
    var chars = Array(line)
    var i = 0

    while i < chars.count {
      let char = chars[i]

      if char == "\"" {
        if inQuotes {
          // Check for escaped quote (two consecutive quotes)
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

// MARK: - TalkDuration Extension

extension TalkDuration {
  /// Map PaperCall duration string to TalkDuration
  static func fromPaperCall(_ duration: String) -> TalkDuration {
    let normalized = duration.lowercased().trimmingCharacters(in: .whitespaces)

    switch normalized {
    case "5", "5 min", "5 minutes", "lightning", "lt", "lightning talk":
      return .lightning
    case "20", "20 min", "20 minutes", "regular", "standard":
      return .regular
    case "invited", "keynote", "invited talk":
      return .invited
    default:
      // Default to regular if unknown
      return .regular
    }
  }
}

import Foundation
import SharedModels

/// Represents a parsed proposal from PaperCall export
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

/// Parser for PaperCall JSON exports
enum PaperCallJSONParser {
  enum ParseError: Error, LocalizedError {
    case invalidJSON(underlying: String)
    case emptyFile
    case emptyArray

    var errorDescription: String? {
      switch self {
      case .invalidJSON(let underlying):
        return "Invalid JSON format: \(underlying)"
      case .emptyFile:
        return "JSON file is empty"
      case .emptyArray:
        return "JSON file contains no proposals"
      }
    }
  }

  /// Decodable struct matching PaperCall.io JSON export format
  private struct PaperCallJSONEntry: Decodable {
    let name: String
    let email: String
    let avatar: String?
    let location: String?
    let bio: String?
    let twitter: String?
    let url: String?
    let organization: String?
    let shirt_size: String?
    let talk_format: String?
    let title: String
    let abstract: String?
    let description: String?
    let notes: String?
    let audience_level: String?
    let tags: [String]?
    let rating: Double?
    let state: String?
    let confirmed: Bool?
    let created_at: String?
    let additional_info: String?
  }

  /// Parse JSON content into PaperCallProposal array
  static func parse(_ content: String) throws -> [PaperCallProposal] {
    let data = Data(content.utf8)
    guard !data.isEmpty else {
      throw ParseError.emptyFile
    }

    let entries: [PaperCallJSONEntry]
    do {
      entries = try JSONDecoder().decode([PaperCallJSONEntry].self, from: data)
    } catch {
      throw ParseError.invalidJSON(underlying: error.localizedDescription)
    }

    guard !entries.isEmpty else {
      throw ParseError.emptyArray
    }

    return entries.map { entry in
      // Generate a unique ID from email+title
      let id = "\(entry.email)-\(entry.title)".hashValue.description

      return PaperCallProposal(
        id: id,
        title: entry.title,
        abstract: entry.abstract ?? "",
        talkDetails: entry.description ?? "",
        duration: entry.talk_format ?? "",
        speakerName: entry.name,
        speakerEmail: entry.email,
        speakerUsername: entry.twitter ?? "",
        bio: entry.bio ?? "",
        iconURL: entry.avatar?.isEmpty == true ? nil : entry.avatar,
        notes: entry.notes?.isEmpty == true ? nil : entry.notes,
        conference: "PaperCall Import",
        submittedAt: entry.created_at ?? ""
      )
    }
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
      // Handle PaperCall JSON formats like "Lightning Talk (5min)", "Talk (20 minutes)"
      if normalized.contains("lightning") {
        return .lightning
      } else if normalized.contains("keynote") || normalized.contains("invited") {
        return .invited
      }
      return .regular
    }
  }
}

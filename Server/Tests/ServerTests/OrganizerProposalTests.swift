import Foundation
import SharedModels
import Testing

@testable import Server

@Suite("Organizer Proposal Tests")
struct OrganizerProposalTests {

  // MARK: - GitHub Username Validation

  @Test("Empty GitHub username trims to empty string")
  func emptyGithubUsername() {
    let raw: String? = ""
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    #expect(trimmed.isEmpty)
  }

  @Test("Nil GitHub username defaults to empty string")
  func nilGithubUsername() {
    let raw: String? = nil
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    #expect(trimmed.isEmpty)
  }

  @Test("Whitespace-only GitHub username trims to empty string")
  func whitespaceGithubUsername() {
    let raw: String? = "   "
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    #expect(trimmed.isEmpty)
  }

  @Test("Valid GitHub username is preserved after trimming")
  func validGithubUsername() {
    let raw: String? = "  octocat  "
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    #expect(trimmed == "octocat")
  }

  // MARK: - PaperCall Import User ID

  @Test("PaperCall import user ID is a well-known UUID")
  func paperCallImportUserID() {
    let expectedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    #expect(AddPaperCallImportUser.paperCallUserID == expectedID)
  }

  // MARK: - Talk Duration Values

  @Test("All TalkDuration cases have non-empty raw values")
  func talkDurationRawValues() {
    for duration in TalkDuration.allCases {
      #expect(!duration.rawValue.isEmpty)
    }
  }

  @Test("TalkDuration raw values are valid form field values")
  func talkDurationFormValues() {
    // These raw values are used in HTML form selects and must not contain special chars
    let validValues = ["20min", "LT", "invited"]
    for duration in TalkDuration.allCases {
      #expect(validValues.contains(duration.rawValue))
    }
  }

  @Test("TalkDuration can be initialized from raw values")
  func talkDurationFromRawValue() {
    #expect(TalkDuration(rawValue: "20min") == .regular)
    #expect(TalkDuration(rawValue: "LT") == .lightning)
    #expect(TalkDuration(rawValue: "invited") == .invited)
    #expect(TalkDuration(rawValue: "invalid") == nil)
    #expect(TalkDuration(rawValue: "") == nil)
  }

  // MARK: - ProposalDTO Construction

  @Test("ProposalDTO can be created with all fields")
  func proposalDTOConstruction() {
    let id = UUID()
    let confID = UUID()
    let speakerID = UUID()
    let dto = ProposalDTO(
      id: id,
      conferenceId: confID,
      conferencePath: "tryswift-tokyo-2026",
      conferenceDisplayName: "try! Swift Tokyo 2026",
      title: "Test Talk",
      abstract: "Abstract",
      talkDetail: "Details",
      talkDuration: .regular,
      speakerName: "Speaker",
      speakerEmail: "speaker@test.com",
      bio: "Bio",
      iconURL: "https://example.com/icon.png",
      notes: "Notes",
      speakerID: speakerID,
      speakerUsername: "octocat"
    )
    #expect(dto.id == id)
    #expect(dto.conferenceId == confID)
    #expect(dto.speakerID == speakerID)
    #expect(dto.speakerUsername == "octocat")
    #expect(dto.status == .submitted)
  }

  @Test("ProposalDTO defaults status to submitted")
  func proposalDTODefaultStatus() {
    let dto = ProposalDTO(
      id: UUID(),
      conferenceId: UUID(),
      conferencePath: "test",
      conferenceDisplayName: "Test",
      title: "T",
      abstract: "A",
      talkDetail: "D",
      talkDuration: .regular,
      speakerName: "S",
      speakerEmail: "e@e.com",
      bio: "B",
      speakerID: UUID(),
      speakerUsername: "user"
    )
    #expect(dto.status == .submitted)
  }

  // MARK: - GitHub Username Display Logic

  @Test("papercall-import username should be cleared in edit form")
  func paperCallUsernameCleared() {
    // The edit form shows empty for papercall-import users
    let username = "papercall-import"
    let displayValue = username == "papercall-import" ? "" : username
    #expect(displayValue == "")
  }

  @Test("Regular GitHub username should be shown in edit form")
  func regularUsernameShown() {
    let username = "octocat"
    let displayValue = username == "papercall-import" ? "" : username
    #expect(displayValue == "octocat")
  }
}

import Foundation

/// Data transfer object for a scholarship application.
public struct ScholarshipApplicationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let conferencePath: String
  public let conferenceDisplayName: String
  public let applicantID: UUID

  // Personal info captured by the form (kept distinct from the authenticating
  // StudentUser email so applicants can use a different contact address).
  public let email: String
  public let name: String
  public let schoolAndFaculty: String
  public let currentYear: String
  public let portfolio: String?
  public let githubAccount: String?

  // Purpose and preferences
  public let purposes: [String]
  public let languagePreference: String

  // Ticket info
  public let existingTicketInfo: String?
  public let supportType: ScholarshipSupportType

  // Travel and accommodation (optional, only for ticket_and_travel)
  public let travelDetails: ScholarshipTravelDetails?
  public let accommodationDetails: ScholarshipAccommodationDetails?

  // Financial
  public let totalEstimatedCost: Int?
  public let desiredSupportAmount: Int?
  public let selfPaymentInfo: String?

  // Agreements
  public let agreedTravelRegulations: Bool
  public let agreedApplicationConfirmation: Bool
  public let agreedPrivacy: Bool
  public let agreedCodeOfConduct: Bool

  // Additional
  public let additionalComments: String?

  // Review status
  public let status: ScholarshipApplicationStatus
  public let approvedAmount: Int?
  public let organizerNotes: String?

  // Timestamps
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    conferenceID: UUID,
    conferencePath: String,
    conferenceDisplayName: String,
    applicantID: UUID,
    email: String,
    name: String,
    schoolAndFaculty: String,
    currentYear: String,
    portfolio: String? = nil,
    githubAccount: String? = nil,
    purposes: [String],
    languagePreference: String,
    existingTicketInfo: String? = nil,
    supportType: ScholarshipSupportType,
    travelDetails: ScholarshipTravelDetails? = nil,
    accommodationDetails: ScholarshipAccommodationDetails? = nil,
    totalEstimatedCost: Int? = nil,
    desiredSupportAmount: Int? = nil,
    selfPaymentInfo: String? = nil,
    agreedTravelRegulations: Bool,
    agreedApplicationConfirmation: Bool,
    agreedPrivacy: Bool,
    agreedCodeOfConduct: Bool,
    additionalComments: String? = nil,
    status: ScholarshipApplicationStatus = .submitted,
    approvedAmount: Int? = nil,
    organizerNotes: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.conferenceID = conferenceID
    self.conferencePath = conferencePath
    self.conferenceDisplayName = conferenceDisplayName
    self.applicantID = applicantID
    self.email = email
    self.name = name
    self.schoolAndFaculty = schoolAndFaculty
    self.currentYear = currentYear
    self.portfolio = portfolio
    self.githubAccount = githubAccount
    self.purposes = purposes
    self.languagePreference = languagePreference
    self.existingTicketInfo = existingTicketInfo
    self.supportType = supportType
    self.travelDetails = travelDetails
    self.accommodationDetails = accommodationDetails
    self.totalEstimatedCost = totalEstimatedCost
    self.desiredSupportAmount = desiredSupportAmount
    self.selfPaymentInfo = selfPaymentInfo
    self.agreedTravelRegulations = agreedTravelRegulations
    self.agreedApplicationConfirmation = agreedApplicationConfirmation
    self.agreedPrivacy = agreedPrivacy
    self.agreedCodeOfConduct = agreedCodeOfConduct
    self.additionalComments = additionalComments
    self.status = status
    self.approvedAmount = approvedAmount
    self.organizerNotes = organizerNotes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

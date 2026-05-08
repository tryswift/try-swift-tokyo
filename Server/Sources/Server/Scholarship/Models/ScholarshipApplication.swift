import Fluent
import SharedModels
import Vapor

/// One scholarship application per (conference, applicant) pair.
final class ScholarshipApplication: Model, Content, @unchecked Sendable {
  static let schema = "scholarship_applications"

  @ID(key: .id) var id: UUID?

  @Parent(key: "conference_id") var conference: Conference
  @Parent(key: "applicant_id") var applicant: StudentUser

  // MARK: Personal info

  @Field(key: "email") var email: String
  @Field(key: "name") var name: String
  @Field(key: "school_and_faculty") var schoolAndFaculty: String
  @Field(key: "current_year") var currentYear: String
  @OptionalField(key: "portfolio") var portfolio: String?
  @OptionalField(key: "github_account") var githubAccount: String?

  // MARK: Purpose & language

  @Field(key: "purposes") var purposes: ScholarshipPurposeList
  @Field(key: "language_preference") var languagePreference: String

  // MARK: Ticket

  @OptionalField(key: "existing_ticket_info") var existingTicketInfo: String?
  @Field(key: "support_type") var supportType: ScholarshipSupportType

  // MARK: Travel & accommodation (conditional on supportType)

  @OptionalField(key: "travel_details") var travelDetails: ScholarshipTravelDetails?
  @OptionalField(key: "accommodation_details")
  var accommodationDetails: ScholarshipAccommodationDetails?

  // MARK: Financial

  @OptionalField(key: "total_estimated_cost") var totalEstimatedCost: Int?
  @OptionalField(key: "desired_support_amount") var desiredSupportAmount: Int?
  @OptionalField(key: "self_payment_info") var selfPaymentInfo: String?

  // MARK: Agreements

  @Field(key: "agreed_travel_regulations") var agreedTravelRegulations: Bool
  @Field(key: "agreed_application_confirmation") var agreedApplicationConfirmation: Bool
  @Field(key: "agreed_privacy") var agreedPrivacy: Bool
  @Field(key: "agreed_code_of_conduct") var agreedCodeOfConduct: Bool

  // MARK: Additional

  @OptionalField(key: "additional_comments") var additionalComments: String?

  // MARK: Review

  @Field(key: "status") var status: ScholarshipApplicationStatus
  @OptionalField(key: "approved_amount") var approvedAmount: Int?
  @OptionalField(key: "organizer_notes") var organizerNotes: String?

  // MARK: Timestamps

  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    conferenceID: UUID,
    applicantID: UUID,
    email: String,
    name: String,
    schoolAndFaculty: String,
    currentYear: String,
    portfolio: String? = nil,
    githubAccount: String? = nil,
    purposes: ScholarshipPurposeList,
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
    organizerNotes: String? = nil
  ) {
    self.id = id
    self.$conference.id = conferenceID
    self.$applicant.id = applicantID
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
  }

  func toDTO(conference: Conference) throws -> ScholarshipApplicationDTO {
    guard let id else {
      throw Abort(.internalServerError, reason: "ScholarshipApplication missing id")
    }
    guard let conferenceID = conference.id else {
      throw Abort(.internalServerError, reason: "Conference missing id")
    }
    return ScholarshipApplicationDTO(
      id: id,
      conferenceID: conferenceID,
      conferencePath: conference.path,
      conferenceDisplayName: conference.displayName,
      applicantID: $applicant.id,
      email: email,
      name: name,
      schoolAndFaculty: schoolAndFaculty,
      currentYear: currentYear,
      portfolio: portfolio,
      githubAccount: githubAccount,
      purposes: purposes.items,
      languagePreference: languagePreference,
      existingTicketInfo: existingTicketInfo,
      supportType: supportType,
      travelDetails: travelDetails,
      accommodationDetails: accommodationDetails,
      totalEstimatedCost: totalEstimatedCost,
      desiredSupportAmount: desiredSupportAmount,
      selfPaymentInfo: selfPaymentInfo,
      agreedTravelRegulations: agreedTravelRegulations,
      agreedApplicationConfirmation: agreedApplicationConfirmation,
      agreedPrivacy: agreedPrivacy,
      agreedCodeOfConduct: agreedCodeOfConduct,
      additionalComments: additionalComments,
      status: status,
      approvedAmount: approvedAmount,
      organizerNotes: organizerNotes,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

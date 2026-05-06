import Foundation

/// Form POST body for the scholarship application form.
/// Field names match the HTML `name` attributes (snake_case URL-encoded).
public struct ScholarshipFormPayload: Codable, Sendable, Equatable {
  // Personal info
  public let email: String
  public let name: String
  public let schoolAndFaculty: String
  public let currentYear: String
  public let portfolio: String?
  public let githubAccount: String?

  // Purpose and preferences
  public let purposes: [String]
  public let languagePreference: String

  // Ticket
  public let existingTicketInfo: String?
  public let supportType: ScholarshipSupportType

  // Travel (optional, conditional on supportType)
  public let originCity: String?
  public let transportationMethods: [ScholarshipTransportMethod]?
  public let estimatedRoundTripCost: Int?

  // Accommodation (optional, conditional on supportType)
  public let accommodationType: ScholarshipAccommodationType?
  public let reservationStatus: ScholarshipReservationStatus?
  public let accommodationName: String?
  public let accommodationAddress: String?
  public let checkInDate: String?
  public let checkOutDate: String?
  public let estimatedAccommodationCost: Int?

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

  // CSRF token paired with the cookie
  public let csrfToken: String

  // Map snake_case form keys to Swift camelCase fields.
  enum CodingKeys: String, CodingKey {
    case email
    case name
    case schoolAndFaculty = "school_and_faculty"
    case currentYear = "current_year"
    case portfolio
    case githubAccount = "github_account"
    case purposes
    case languagePreference = "language_preference"
    case existingTicketInfo = "existing_ticket_info"
    case supportType = "support_type"
    case originCity = "origin_city"
    case transportationMethods = "transportation_methods"
    case estimatedRoundTripCost = "estimated_round_trip_cost"
    case accommodationType = "accommodation_type"
    case reservationStatus = "reservation_status"
    case accommodationName = "accommodation_name"
    case accommodationAddress = "accommodation_address"
    case checkInDate = "check_in_date"
    case checkOutDate = "check_out_date"
    case estimatedAccommodationCost = "estimated_accommodation_cost"
    case totalEstimatedCost = "total_estimated_cost"
    case desiredSupportAmount = "desired_support_amount"
    case selfPaymentInfo = "self_payment_info"
    case agreedTravelRegulations = "agreed_travel_regulations"
    case agreedApplicationConfirmation = "agreed_application_confirmation"
    case agreedPrivacy = "agreed_privacy"
    case agreedCodeOfConduct = "agreed_code_of_conduct"
    case additionalComments = "additional_comments"
    case csrfToken = "_csrf"
  }

  public init(
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
    originCity: String? = nil,
    transportationMethods: [ScholarshipTransportMethod]? = nil,
    estimatedRoundTripCost: Int? = nil,
    accommodationType: ScholarshipAccommodationType? = nil,
    reservationStatus: ScholarshipReservationStatus? = nil,
    accommodationName: String? = nil,
    accommodationAddress: String? = nil,
    checkInDate: String? = nil,
    checkOutDate: String? = nil,
    estimatedAccommodationCost: Int? = nil,
    totalEstimatedCost: Int? = nil,
    desiredSupportAmount: Int? = nil,
    selfPaymentInfo: String? = nil,
    agreedTravelRegulations: Bool,
    agreedApplicationConfirmation: Bool,
    agreedPrivacy: Bool,
    agreedCodeOfConduct: Bool,
    additionalComments: String? = nil,
    csrfToken: String
  ) {
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
    self.originCity = originCity
    self.transportationMethods = transportationMethods
    self.estimatedRoundTripCost = estimatedRoundTripCost
    self.accommodationType = accommodationType
    self.reservationStatus = reservationStatus
    self.accommodationName = accommodationName
    self.accommodationAddress = accommodationAddress
    self.checkInDate = checkInDate
    self.checkOutDate = checkOutDate
    self.estimatedAccommodationCost = estimatedAccommodationCost
    self.totalEstimatedCost = totalEstimatedCost
    self.desiredSupportAmount = desiredSupportAmount
    self.selfPaymentInfo = selfPaymentInfo
    self.agreedTravelRegulations = agreedTravelRegulations
    self.agreedApplicationConfirmation = agreedApplicationConfirmation
    self.agreedPrivacy = agreedPrivacy
    self.agreedCodeOfConduct = agreedCodeOfConduct
    self.additionalComments = additionalComments
    self.csrfToken = csrfToken
  }
}

/// Magic-link login request POST body.
public struct ScholarshipLoginRequestPayload: Codable, Sendable, Equatable {
  public let email: String
  public let csrfToken: String

  enum CodingKeys: String, CodingKey {
    case email
    case csrfToken = "_csrf"
  }

  public init(email: String, csrfToken: String) {
    self.email = email
    self.csrfToken = csrfToken
  }
}

/// Organizer approve action POST body.
public struct ScholarshipApproveActionPayload: Codable, Sendable, Equatable {
  public let approvedAmount: Int
  public let organizerNotes: String?
  public let csrfToken: String

  enum CodingKeys: String, CodingKey {
    case approvedAmount = "approved_amount"
    case organizerNotes = "organizer_notes"
    case csrfToken = "_csrf"
  }

  public init(approvedAmount: Int, organizerNotes: String?, csrfToken: String) {
    self.approvedAmount = approvedAmount
    self.organizerNotes = organizerNotes
    self.csrfToken = csrfToken
  }
}

/// Organizer reject action POST body.
public struct ScholarshipRejectActionPayload: Codable, Sendable, Equatable {
  public let organizerNotes: String?
  public let csrfToken: String

  enum CodingKeys: String, CodingKey {
    case organizerNotes = "organizer_notes"
    case csrfToken = "_csrf"
  }

  public init(organizerNotes: String?, csrfToken: String) {
    self.organizerNotes = organizerNotes
    self.csrfToken = csrfToken
  }
}

/// Organizer budget upsert POST body.
public struct ScholarshipBudgetUpdatePayload: Codable, Sendable, Equatable {
  public let totalBudget: Int
  public let notes: String?
  public let csrfToken: String

  enum CodingKeys: String, CodingKey {
    case totalBudget = "total_budget"
    case notes
    case csrfToken = "_csrf"
  }

  public init(totalBudget: Int, notes: String?, csrfToken: String) {
    self.totalBudget = totalBudget
    self.notes = notes
    self.csrfToken = csrfToken
  }
}

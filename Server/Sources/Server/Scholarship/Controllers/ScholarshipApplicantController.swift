import Elementary
import Fluent
import Foundation
import SharedModels
import Vapor
import WebScholarship

/// Authenticated applicant routes: apply form, my-application view,
/// withdraw, and the public /api/travel-cost endpoint used by the apply page.
struct ScholarshipApplicantController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("apply", use: renderApply)
    routes.post("apply", use: submit)
    routes.get("my-application", use: myApplication)
    routes.post("my-application", "withdraw", use: withdraw)
  }

  // The travel-cost lookup is mounted unauthenticated by ScholarshipRoutes
  // (the apply form needs to call it before the user is logged in only if
  // they reload mid-flight, but most callers will be on /apply where they
  // already have a session).
  static func registerTravelCost(on routes: RoutesBuilder) {
    routes.get("api", "travel-cost", use: ScholarshipApplicantController().travelCost)
  }

  // MARK: Apply

  func renderApply(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }

    return respond(
      ApplyPage(
        locale: req.studentLocale,
        csrfToken: req.csrfToken,
        prefilledEmail: user.email,
        prefilledName: user.displayName ?? "",
        datalistHTML: TravelCostCalculator.datalistHTML,
        educationalSuffixesJS: EducationalDomainValidator.jsSuffixArray
      )
    )
  }

  func submit(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(ScholarshipFormPayload.self)

    guard let conference = try await currentConference(on: req.db) else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting applications")
    }
    let conferenceID = try conference.requireID()
    let applicantID = try user.requireID()

    // Reject duplicate applications per (conference, applicant). The DB also
    // enforces this with a UNIQUE index, but checking explicitly lets us
    // return a friendlier error.
    if (try await ScholarshipApplication.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$applicant.$id == applicantID)
      .first()) != nil
    {
      throw Abort(.conflict, reason: "You have already submitted an application")
    }

    let travelDetails: ScholarshipTravelDetails?
    let accommodationDetails: ScholarshipAccommodationDetails?
    if payload.supportType == .ticketAndTravel {
      if let originCity = payload.originCity, !originCity.isEmpty,
        let methods = payload.transportationMethods,
        let trip = payload.estimatedRoundTripCost
      {
        travelDetails = ScholarshipTravelDetails(
          originCity: originCity,
          transportationMethods: methods,
          estimatedRoundTripCost: trip
        )
      } else {
        travelDetails = nil
      }
      if let type = payload.accommodationType,
        let status = payload.reservationStatus,
        let cost = payload.estimatedAccommodationCost
      {
        accommodationDetails = ScholarshipAccommodationDetails(
          accommodationType: type,
          reservationStatus: status,
          accommodationName: payload.accommodationName,
          accommodationAddress: payload.accommodationAddress,
          checkInDate: payload.checkInDate,
          checkOutDate: payload.checkOutDate,
          estimatedCost: cost
        )
      } else {
        accommodationDetails = nil
      }
    } else {
      travelDetails = nil
      accommodationDetails = nil
    }

    let application = ScholarshipApplication(
      conferenceID: conferenceID,
      applicantID: applicantID,
      email: payload.email,
      name: payload.name,
      schoolAndFaculty: payload.schoolAndFaculty,
      currentYear: payload.currentYear,
      portfolio: payload.portfolio,
      githubAccount: payload.githubAccount,
      purposes: ScholarshipPurposeList(payload.purposes),
      languagePreference: payload.languagePreference,
      existingTicketInfo: payload.existingTicketInfo,
      supportType: payload.supportType,
      travelDetails: travelDetails,
      accommodationDetails: accommodationDetails,
      totalEstimatedCost: payload.totalEstimatedCost,
      desiredSupportAmount: payload.desiredSupportAmount,
      selfPaymentInfo: payload.selfPaymentInfo,
      agreedTravelRegulations: payload.agreedTravelRegulations,
      agreedApplicationConfirmation: payload.agreedApplicationConfirmation,
      agreedPrivacy: payload.agreedPrivacy,
      agreedCodeOfConduct: payload.agreedCodeOfConduct,
      additionalComments: payload.additionalComments
    )
    try await application.save(on: req.db)

    // Persist the typed name on the StudentUser record so future emails can
    // address the applicant correctly.
    if user.displayName == nil || user.displayName?.isEmpty == true {
      user.displayName = payload.name
      try await user.save(on: req.db)
    }

    let mail = ScholarshipEmailTemplates.render(
      .applicationReceived(conferenceName: conference.displayName),
      locale: req.studentLocale,
      recipientName: payload.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: payload.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyNewApplication(
      name: payload.name,
      school: payload.schoolAndFaculty,
      supportType: payload.supportType.displayName,
      client: req.client,
      logger: req.logger
    )

    return req.redirect(to: "/my-application")
  }

  // MARK: My application

  func myApplication(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let applicantID = try user.requireID()
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$applicant.$id == applicantID)
      .with(\.$conference)
      .sort(\.$createdAt, .descending)
      .first()

    let dto: ScholarshipApplicationDTO?
    if let application {
      dto = try application.toDTO(conference: application.conference)
    } else {
      dto = nil
    }

    let flash = req.query[String.self, at: "flash"]
    return respond(
      MyApplicationPage(
        locale: req.studentLocale,
        csrfToken: req.csrfToken,
        application: dto,
        flash: flash
      )
    )
  }

  func withdraw(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let applicantID = try user.requireID()
    guard
      let application = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$applicant.$id == applicantID)
        .filter(\.$status == .submitted)
        .first()
    else {
      throw Abort(.conflict, reason: "No active application to withdraw")
    }
    application.status = .withdrawn
    try await application.save(on: req.db)
    return req.redirect(to: "/my-application")
  }

  // MARK: Travel-cost API

  func travelCost(_ req: Request) async throws -> Response {
    guard let from = req.query[String.self, at: "from"], !from.isEmpty else {
      throw Abort(.badRequest, reason: "Missing 'from' query parameter")
    }
    guard let estimate = TravelCostCalculator.estimate(from: from) else {
      throw Abort(.notFound, reason: "City not found")
    }
    let response = Response(status: .ok)
    try response.content.encode(estimate)
    return response
  }

  // MARK: Helpers

  private func currentConference(on db: Database) async throws -> Conference? {
    try await Conference.query(on: db)
      .sort(\.$year, .descending)
      .first()
  }

  private func respond<Page: HTML>(_ page: Page) -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}

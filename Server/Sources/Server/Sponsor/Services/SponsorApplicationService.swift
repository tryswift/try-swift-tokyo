import Fluent
import Foundation
import SharedModels
import Vapor

enum SponsorApplicationService {
  static func approve(
    applicationID: UUID, decidedByUserID: UUID,
    on db: Database, client: Client, logger: Logger
  ) async throws -> SponsorApplication {
    let application = try await SponsorApplication.query(on: db)
      .filter(\.$id == applicationID)
      .with(\.$organization)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first()
    guard let application else { throw Abort(.notFound) }

    application.status = .approved
    application.decidedAt = Date()
    application.decidedByUserID = decidedByUserID
    try await application.save(on: db)

    let planName =
      application.plan.localizations
      .first(where: { $0.locale == application.payload.locale })?.name ?? application.plan.slug
    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let nextStepsURL = URL(string: "\(baseURL)/applications/\(application.id?.uuidString ?? "")")!
    let mail = SponsorEmailTemplates.render(
      .applicationApproved(planName: planName, nextStepsURL: nextStepsURL),
      locale: application.payload.locale,
      recipientName: application.payload.billingContactName)
    let from =
      Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.payload.billingEmail, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: client, logger: logger
    )
    await SponsorSlackNotifier.notifyDecision(
      orgName: application.organization.displayName,
      planName: planName, decision: "approved",
      client: client, logger: logger
    )
    return application
  }

  static func reject(
    applicationID: UUID, reason: String, decidedByUserID: UUID,
    on db: Database, client: Client, logger: Logger
  ) async throws -> SponsorApplication {
    let application = try await SponsorApplication.query(on: db)
      .filter(\.$id == applicationID)
      .with(\.$organization)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first()
    guard let application else { throw Abort(.notFound) }

    application.status = .rejected
    application.decisionNote = reason
    application.decidedAt = Date()
    application.decidedByUserID = decidedByUserID
    try await application.save(on: db)

    let planName =
      application.plan.localizations
      .first(where: { $0.locale == application.payload.locale })?.name ?? application.plan.slug
    let mail = SponsorEmailTemplates.render(
      .applicationRejected(planName: planName, reason: reason),
      locale: application.payload.locale,
      recipientName: application.payload.billingContactName)
    let from =
      Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.payload.billingEmail, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: client, logger: logger
    )
    await SponsorSlackNotifier.notifyDecision(
      orgName: application.organization.displayName,
      planName: planName, decision: "rejected",
      client: client, logger: logger
    )
    return application
  }
}

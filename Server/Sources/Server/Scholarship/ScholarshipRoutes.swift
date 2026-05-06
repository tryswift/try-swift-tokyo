import Vapor

/// Aggregates all student.tryswift.jp routes.
///
/// Public, applicant-authenticated, and organizer routes share a host filter
/// (`StudentHostOnlyMiddleware`) so requests targeting any other host
/// (api.tryswift.jp, sponsor.tryswift.jp, cfp.tryswift.jp) can't reach this
/// tree. Locale resolution and CSRF protection are shared across the group.
struct ScholarshipRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let studentOnly = routes.grouped(StudentHostOnlyMiddleware())
      .grouped(StudentLocaleMiddleware())
      .grouped(CSRFMiddleware())

    try studentOnly.register(collection: ScholarshipPublicController())

    // Travel-cost JSON endpoint sits under the student host but does not
    // require a session — applicants may probe it from the apply page before
    // their cookie is fully refreshed.
    ScholarshipApplicantController.registerTravelCost(on: studentOnly)

    let auth = studentOnly.grouped(StudentAuthMiddleware())
    try auth.register(collection: ScholarshipApplicantController())

    let organizer = studentOnly.grouped(OrganizerOnlyMiddleware())
    try organizer.register(collection: OrganizerScholarshipController())
  }
}

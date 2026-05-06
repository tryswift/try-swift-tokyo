import Elementary
import SharedModels

public struct ApplicationDetailPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let csrfToken: String
  public let application: ScholarshipApplicationDTO

  public init(
    locale: ScholarshipPortalLocale,
    csrfToken: String,
    application: ScholarshipApplicationDTO
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.application = application
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgDetailTitle, locale),
      locale: locale,
      isAuthenticated: true,
      isOrganizer: true,
      csrfToken: csrfToken
    ) {
      h1 { ScholarshipStrings.t(.orgDetailTitle, locale) }
      readOnlyDetails
      decisionForms
    }
  }

  private var readOnlyDetails: some HTML {
    section(.class("application-detail")) {
      dl {
        dt { ScholarshipStrings.t(.myAppStatusLabel, locale) }
        dd { StatusBadge(status: application.status, locale: locale) }
        dt { ScholarshipStrings.t(.applyEmailLabel, locale) }
        dd { application.email }
        dt { ScholarshipStrings.t(.applyNameLabel, locale) }
        dd { application.name }
        dt { ScholarshipStrings.t(.applySchoolLabel, locale) }
        dd { application.schoolAndFaculty }
        dt { ScholarshipStrings.t(.applyYearLabel, locale) }
        dd { application.currentYear }
        dt { ScholarshipStrings.t(.applySupportTypeLabel, locale) }
        dd {
          locale == .ja
            ? application.supportType.displayNameJa : application.supportType.displayName
        }
        dt { ScholarshipStrings.t(.applyTotalCostLabel, locale) }
        dd { application.totalEstimatedCost.map { "¥\($0)" } ?? "—" }
        dt { ScholarshipStrings.t(.applyDesiredAmountLabel, locale) }
        dd { application.desiredSupportAmount.map { "¥\($0)" } ?? "—" }
        if let portfolio = application.portfolio, !portfolio.isEmpty {
          dt { ScholarshipStrings.t(.applyPortfolioLabel, locale) }
          dd { portfolio }
        }
        if let comments = application.additionalComments, !comments.isEmpty {
          dt { ScholarshipStrings.t(.applyAdditionalCommentsLabel, locale) }
          dd { comments }
        }
      }
    }
  }

  private var decisionForms: some HTML {
    section(.class("decision")) {
      // Approve
      form(.method(.post), .action("/organizer/\(application.id.uuidString)/approve")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(
          label: ScholarshipStrings.t(.orgApprovedAmountLabel, locale),
          name: "approved_amount",
          value: application.approvedAmount.map { String($0) } ?? "",
          inputType: "number",
          isRequired: true
        )
        FormTextArea(
          label: ScholarshipStrings.t(.orgNotesLabel, locale),
          name: "organizer_notes",
          value: application.organizerNotes ?? ""
        )
        button(.type(.submit), .class("primary")) {
          ScholarshipStrings.t(.orgApprove, locale)
        }
      }

      // Reject
      form(.method(.post), .action("/organizer/\(application.id.uuidString)/reject")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormTextArea(
          label: ScholarshipStrings.t(.orgNotesLabel, locale),
          name: "organizer_notes",
          value: application.organizerNotes ?? ""
        )
        button(.type(.submit), .class("danger")) {
          ScholarshipStrings.t(.orgReject, locale)
        }
      }

      // Revert (only when not submitted)
      if application.status != .submitted {
        form(.method(.post), .action("/organizer/\(application.id.uuidString)/revert")) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit)) { ScholarshipStrings.t(.orgRevert, locale) }
        }
      }
    }
  }
}

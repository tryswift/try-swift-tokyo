import Elementary
import SharedModels

/// Organizer detail shell. The page lives at `/organizer/detail/index.html`
/// and is rewritten from `/organizer/<id>` by Cloudflare Pages; JS reads the
/// `<id>` from `window.location.pathname` and fetches the application.
public struct ApplicationDetailPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgDetailTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "organizer-detail"
    ) {
      h1 { ScholarshipStrings.t(.orgDetailTitle, locale) }

      section(.id("application-detail")) {}

      // Approve form
      form(.method(.post), .id("approve-form"), .class("hidden")) {
        FormField(
          label: ScholarshipStrings.t(.orgApprovedAmountLabel, locale),
          name: "approved_amount",
          inputType: "number",
          isRequired: true
        )
        FormTextArea(
          label: ScholarshipStrings.t(.orgNotesLabel, locale),
          name: "organizer_notes"
        )
        button(.type(.submit), .class("primary")) {
          ScholarshipStrings.t(.orgApprove, locale)
        }
      }

      // Reject form
      form(.method(.post), .id("reject-form"), .class("hidden")) {
        FormTextArea(
          label: ScholarshipStrings.t(.orgNotesLabel, locale),
          name: "organizer_notes"
        )
        button(.type(.submit), .class("danger")) {
          ScholarshipStrings.t(.orgReject, locale)
        }
      }

      // Revert form (only shown by JS when status != submitted)
      form(.method(.post), .id("revert-form"), .class("hidden")) {
        button(.type(.submit)) { ScholarshipStrings.t(.orgRevert, locale) }
      }
    }
  }
}

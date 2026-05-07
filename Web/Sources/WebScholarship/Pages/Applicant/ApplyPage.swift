import Elementary
import SharedModels

/// 7-section apply form. The form posts to api.tryswift.jp; pre-fill of
/// email/name happens via `scholarship.js`, which fetches `/api/v1/scholarship/me`
/// on page load and populates the inputs.
public struct ApplyPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.applyTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "apply"
    ) {
      h1 { ScholarshipStrings.t(.applyTitle, locale) }

      HTMLRaw(TravelCostDatalistHTML.render())

      form(
        .method(.post),
        .action("\(apiBaseURL)/api/v1/scholarship/apply"),
        .id("apply-form")
      ) {
        section1
        section2
        section3
        section4
        section5
        section6
        section7

        FormTextArea(
          label: ScholarshipStrings.t(.applyAdditionalCommentsLabel, locale),
          name: "additional_comments",
          rows: 3
        )

        button(.type(.submit), .class("primary")) {
          ScholarshipStrings.t(.applySubmit, locale)
        }
      }
    }
  }

  // MARK: Sections

  private var section1: some HTML {
    fieldset {
      legend { ScholarshipStrings.t(.applySection1, locale) }
      FormField(
        label: ScholarshipStrings.t(.applyEmailLabel, locale),
        name: "email",
        inputType: "email",
        isRequired: true
      )
      div(.id("email-domain-hint"), .class("hint hidden")) {
        ScholarshipStrings.t(.applyEducationalEmailHint, locale)
      }
      FormField(
        label: ScholarshipStrings.t(.applyNameLabel, locale),
        name: "name",
        isRequired: true
      )
      FormField(
        label: ScholarshipStrings.t(.applySchoolLabel, locale),
        name: "school_and_faculty",
        isRequired: true
      )
      FormField(
        label: ScholarshipStrings.t(.applyYearLabel, locale),
        name: "current_year",
        isRequired: true
      )
    }
  }

  private var section2: some HTML {
    fieldset {
      legend { ScholarshipStrings.t(.applySection2, locale) }
      FormTextArea(
        label: ScholarshipStrings.t(.applyPortfolioLabel, locale),
        name: "portfolio",
        rows: 3
      )
      FormField(
        label: ScholarshipStrings.t(.applyGitHubLabel, locale),
        name: "github_account"
      )
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applyLanguageLabel, locale) }
        Elementary.label {
          input(
            .type(.radio), .name("language_preference"), .value("ja"), .required, .checked
          )
          " " + ScholarshipStrings.t(.applyLanguageJa, locale)
        }
        Elementary.label {
          input(
            .type(.radio), .name("language_preference"), .value("en"), .required
          )
          " " + ScholarshipStrings.t(.applyLanguageEn, locale)
        }
      }
    }
  }

  private var section3: some HTML {
    fieldset {
      legend { ScholarshipStrings.t(.applySection3, locale) }
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applyPurposeLabel, locale) }
        for purpose in ScholarshipPurpose.allCases {
          Elementary.label {
            input(.type(.checkbox), .name("purposes"), .value(purpose.rawValue))
            " " + (locale == .ja ? purpose.displayNameJa : purpose.displayName)
          }
        }
      }
    }
  }

  private var section4: some HTML {
    fieldset {
      legend { ScholarshipStrings.t(.applySection4, locale) }
      FormTextArea(
        label: ScholarshipStrings.t(.applyTicketInfoLabel, locale),
        name: "existing_ticket_info",
        rows: 2
      )
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applySupportTypeLabel, locale) }
        Elementary.label {
          input(
            .type(.radio),
            .name("support_type"),
            .value(ScholarshipSupportType.ticketOnly.rawValue),
            .required,
            .checked
          )
          " "
            + (locale == .ja
              ? ScholarshipSupportType.ticketOnly.displayNameJa
              : ScholarshipSupportType.ticketOnly.displayName)
        }
        Elementary.label {
          input(
            .type(.radio),
            .name("support_type"),
            .value(ScholarshipSupportType.ticketAndTravel.rawValue)
          )
          " "
            + (locale == .ja
              ? ScholarshipSupportType.ticketAndTravel.displayNameJa
              : ScholarshipSupportType.ticketAndTravel.displayName)
        }
      }
    }
  }

  private var section5: some HTML {
    fieldset(.id("section-travel"), .class("hidden")) {
      legend { ScholarshipStrings.t(.applySection5, locale) }
      FormField(
        label: ScholarshipStrings.t(.applyOriginCityLabel, locale),
        name: "origin_city"
      )
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applyTransportLabel, locale) }
        for method in ScholarshipTransportMethod.allCases {
          Elementary.label {
            input(.type(.checkbox), .name("transportation_methods"), .value(method.rawValue))
            " " + (locale == .ja ? method.displayNameJa : method.displayName)
          }
        }
      }
      FormField(
        label: ScholarshipStrings.t(.applyTripCostLabel, locale),
        name: "estimated_round_trip_cost",
        inputType: "number"
      )
      button(.type(.button), .id("estimate-travel-button")) {
        ScholarshipStrings.t(.applyEstimateButton, locale)
      }
      div(.id("travel-estimate-result"), .class("hint")) {}
    }
  }

  private var section6: some HTML {
    fieldset(.id("section-accommodation"), .class("hidden")) {
      legend { ScholarshipStrings.t(.applySection6, locale) }
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applyAccommodationLabel, locale) }
        for type in ScholarshipAccommodationType.allCases {
          Elementary.label {
            input(.type(.radio), .name("accommodation_type"), .value(type.rawValue))
            " " + (locale == .ja ? type.displayNameJa : type.displayName)
          }
        }
      }
      div(.class("form-field")) {
        Elementary.label { ScholarshipStrings.t(.applyReservationLabel, locale) }
        for status in ScholarshipReservationStatus.allCases {
          Elementary.label {
            input(.type(.radio), .name("reservation_status"), .value(status.rawValue))
            " " + (locale == .ja ? status.displayNameJa : status.displayName)
          }
        }
      }
      FormField(
        label: ScholarshipStrings.t(.applyAccommodationNameLabel, locale),
        name: "accommodation_name"
      )
      FormField(
        label: ScholarshipStrings.t(.applyAccommodationAddressLabel, locale),
        name: "accommodation_address"
      )
      FormField(
        label: ScholarshipStrings.t(.applyCheckInLabel, locale),
        name: "check_in_date",
        inputType: "date"
      )
      FormField(
        label: ScholarshipStrings.t(.applyCheckOutLabel, locale),
        name: "check_out_date",
        inputType: "date"
      )
      FormField(
        label: ScholarshipStrings.t(.applyAccommodationCostLabel, locale),
        name: "estimated_accommodation_cost",
        inputType: "number"
      )
      FormField(
        label: ScholarshipStrings.t(.applyTotalCostLabel, locale),
        name: "total_estimated_cost",
        inputType: "number"
      )
      FormField(
        label: ScholarshipStrings.t(.applyDesiredAmountLabel, locale),
        name: "desired_support_amount",
        inputType: "number"
      )
      FormTextArea(
        label: ScholarshipStrings.t(.applySelfPaymentLabel, locale),
        name: "self_payment_info",
        rows: 2
      )
    }
  }

  private var section7: some HTML {
    fieldset {
      legend { ScholarshipStrings.t(.applySection7, locale) }
      AgreementCheckbox(
        label: ScholarshipStrings.t(.applyAgreeTravelRegs, locale),
        name: "agreed_travel_regulations"
      )
      AgreementCheckbox(
        label: ScholarshipStrings.t(.applyAgreeApplicationConfirmation, locale),
        name: "agreed_application_confirmation"
      )
      AgreementCheckbox(
        label: ScholarshipStrings.t(.applyAgreePrivacy, locale),
        name: "agreed_privacy"
      )
      AgreementCheckbox(
        label: ScholarshipStrings.t(.applyAgreeCodeOfConduct, locale),
        name: "agreed_code_of_conduct"
      )
    }
  }
}

/// Pre-rendered datalist for the city autocomplete. Keys come from a
/// canonical list embedded at build time so the static page works without
/// hitting the API for completion options.
private enum TravelCostDatalistHTML {
  static let cities: [(en: String, ja: String)] = [
    ("Chiba", "千葉"), ("Fukuoka", "福岡"), ("Hiroshima", "広島"), ("Kagoshima", "鹿児島"),
    ("Kanazawa", "金沢"), ("Kobe", "神戸"), ("Kumamoto", "熊本"), ("Kyoto", "京都"),
    ("Matsuyama", "松山"), ("Nagano", "長野"), ("Nagoya", "名古屋"), ("Naha", "那覇"),
    ("Niigata", "新潟"), ("Okayama", "岡山"), ("Osaka", "大阪"), ("Saitama", "さいたま"),
    ("Sapporo", "札幌"), ("Sendai", "仙台"), ("Shizuoka", "静岡"), ("Yokohama", "横浜"),
  ]

  static func render() -> String {
    var html = "<datalist id=\"cityList\">"
    for city in cities {
      html += "<option value=\"\(city.en)\">"
      html += "<option value=\"\(city.ja)\">"
    }
    html += "</datalist>"
    return html
  }
}

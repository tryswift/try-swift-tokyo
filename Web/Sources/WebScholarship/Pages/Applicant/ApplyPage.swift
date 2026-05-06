import Elementary
import SharedModels

/// 7-section apply form. Sections 5 (travel) and 6 (accommodation) are toggled
/// on the client by inline JavaScript when the support type radio changes.
public struct ApplyPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let csrfToken: String
  public let prefilledEmail: String
  public let prefilledName: String
  public let datalistHTML: String
  public let educationalSuffixesJS: String
  public let errorMessage: String?

  public init(
    locale: ScholarshipPortalLocale,
    csrfToken: String,
    prefilledEmail: String,
    prefilledName: String,
    datalistHTML: String,
    educationalSuffixesJS: String,
    errorMessage: String? = nil
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.prefilledEmail = prefilledEmail
    self.prefilledName = prefilledName
    self.datalistHTML = datalistHTML
    self.educationalSuffixesJS = educationalSuffixesJS
    self.errorMessage = errorMessage
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.applyTitle, locale),
      locale: locale,
      isAuthenticated: true,
      flash: errorMessage,
      csrfToken: csrfToken
    ) {
      h1 { ScholarshipStrings.t(.applyTitle, locale) }

      HTMLRaw(datalistHTML)

      form(.method(.post), .action("/apply"), .id("apply-form")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))

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

      script {
        HTMLRaw(applyFormJS)
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
        value: prefilledEmail,
        inputType: "email",
        isRequired: true
      )
      div(.id("email-domain-hint"), .class("hint hidden")) {
        ScholarshipStrings.t(.applyEducationalEmailHint, locale)
      }
      FormField(
        label: ScholarshipStrings.t(.applyNameLabel, locale),
        name: "name",
        value: prefilledName,
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
            .type(.radio),
            .name("language_preference"),
            .value("ja"),
            .required,
            locale == .ja ? .checked : .checked
          )
          " " + ScholarshipStrings.t(.applyLanguageJa, locale)
        }
        Elementary.label {
          input(
            .type(.radio),
            .name("language_preference"),
            .value("en"),
            .required
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
            input(
              .type(.checkbox),
              .name("purposes"),
              .value(purpose.rawValue)
            )
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
            .checked,
            .custom(name: "onchange", value: "toggleTravelSections(this.value)")
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
            .value(ScholarshipSupportType.ticketAndTravel.rawValue),
            .custom(name: "onchange", value: "toggleTravelSections(this.value)")
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
            input(
              .type(.checkbox),
              .name("transportation_methods"),
              .value(method.rawValue)
            )
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

  // MARK: Inline JS

  private var applyFormJS: String {
    """
    const EDU_SUFFIXES = \(educationalSuffixesJS);

    function toggleTravelSections(value) {
      const showTravel = value === 'ticket_and_travel';
      const t = document.getElementById('section-travel');
      const a = document.getElementById('section-accommodation');
      if (t) t.classList.toggle('hidden', !showTravel);
      if (a) a.classList.toggle('hidden', !showTravel);
    }
    document.querySelectorAll("[name='support_type']").forEach(el => {
      if (el.checked) toggleTravelSections(el.value);
    });

    function checkEmailDomain(value) {
      const at = value.lastIndexOf('@');
      if (at < 0) return;
      const domain = value.slice(at).toLowerCase();
      const ok = EDU_SUFFIXES.some(s => domain.endsWith(s));
      const hint = document.getElementById('email-domain-hint');
      if (hint) hint.classList.toggle('hidden', ok);
    }
    const emailInput = document.querySelector("[name='email']");
    if (emailInput) {
      emailInput.addEventListener('input', e => checkEmailDomain(e.target.value));
      checkEmailDomain(emailInput.value);
    }

    function recalcTotal() {
      const tripEl = document.querySelector("[name='estimated_round_trip_cost']");
      const accomEl = document.querySelector("[name='estimated_accommodation_cost']");
      const totalEl = document.querySelector("[name='total_estimated_cost']");
      if (!totalEl) return;
      const t = Number(tripEl?.value || 0);
      const a = Number(accomEl?.value || 0);
      totalEl.value = String(t + a);
    }
    document.querySelector("[name='estimated_round_trip_cost']")?.addEventListener('input', recalcTotal);
    document.querySelector("[name='estimated_accommodation_cost']")?.addEventListener('input', recalcTotal);

    document.getElementById('estimate-travel-button')?.addEventListener('click', async () => {
      const cityEl = document.querySelector("[name='origin_city']");
      const out = document.getElementById('travel-estimate-result');
      if (!cityEl || !out) return;
      const city = cityEl.value;
      if (!city) { out.textContent = ''; return; }
      try {
        const res = await fetch(`/api/travel-cost?from=${encodeURIComponent(city)}`);
        if (!res.ok) { out.textContent = '—'; return; }
        const data = await res.json();
        const parts = [];
        if (data.bulletTrain != null) parts.push(`新幹線 ¥${data.bulletTrain}`);
        if (data.airplane != null) parts.push(`飛行機 ¥${data.airplane}`);
        if (data.bus != null) parts.push(`バス ¥${data.bus}`);
        if (data.train != null) parts.push(`電車 ¥${data.train}`);
        out.textContent = parts.length ? parts.join(' / ') : '—';
      } catch (_) {
        out.textContent = '—';
      }
    });
    """
  }
}

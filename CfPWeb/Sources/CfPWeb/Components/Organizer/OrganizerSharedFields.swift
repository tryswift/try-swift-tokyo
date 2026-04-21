import Elementary

struct SubmitCoInstructorFields: HTML, Sendable {
  let language: AppLanguage
  let prefix: String

  var body: some HTML {
    div(.class("submit-form-full co-instructor-fields")) {
      h4 { HTMLText(language == .ja ? "共同講師" : "Co-Instructor") }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "名前" : "Name") }
        input(.type(.text), .name("\(prefix)Name"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("Email") }
        input(.type(.email), .name("\(prefix)Email"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("GitHub") }
        input(.type(.text), .name("\(prefix)GithubUsername"))
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText("Bio") }
        textarea(.name("\(prefix)Bio"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("SNS") }
        input(.type(.url), .name("\(prefix)Sns"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
        input(.type(.url), .name("\(prefix)IconURL"))
      }
    }
  }
}

struct OrganizerWorkshopDetailFields: HTML, Sendable {
  let sectionID: String
  let coInstructor1Prefix: String
  let coInstructor2Prefix: String
  let language: AppLanguage
  let includeJapanese: Bool

  var body: some HTML {
    div(.id(sectionID), .class("submit-workshop-section submit-form-full"), .hidden) {
      h4 { HTMLText(language == .ja ? "ワークショップ詳細" : "Workshop Details") }

      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "言語" : "Language") }
        select(.name("workshopLanguage")) {
          option(.value("english")) { HTMLText(language == .ja ? "英語" : "English") }
          option(.value("japanese")) { HTMLText(language == .ja ? "日本語" : "Japanese") }
          option(.value("bilingual")) { HTMLText(language == .ja ? "バイリンガル" : "Bilingual") }
        }
      }

      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "講師数" : "Number of Tutors") }
        input(
          .type(.number), .name("workshopNumberOfTutors"), .custom(name: "min", value: "1"),
          .value("1"))
      }

      textareaField(
        name: "workshopKeyTakeaways", labelJa: "学べること", labelEn: "Key Takeaways", rows: "4")
      textareaField(
        name: "workshopPrerequisites", labelJa: "前提知識", labelEn: "Prerequisites", rows: "3")
      textareaField(
        name: "workshopAgendaSchedule", labelJa: "アジェンダ", labelEn: "Agenda / Schedule", rows: "5")
      textareaField(
        name: "workshopParticipantRequirements", labelJa: "持ち物", labelEn: "What to Bring", rows: "3"
      )
      textareaField(
        name: "workshopRequiredSoftware", labelJa: "必要なソフトウェア", labelEn: "Required Software",
        rows: "3")
      textareaField(
        name: "workshopNetworkRequirements", labelJa: "ネットワーク要件", labelEn: "Network Requirements",
        rows: "3")
      textareaField(name: "workshopMotivation", labelJa: "企画意図", labelEn: "Motivation", rows: "3")
      textareaField(name: "workshopUniqueness", labelJa: "独自性", labelEn: "Uniqueness", rows: "3")
      textareaField(
        name: "workshopPotentialRisks", labelJa: "懸念点", labelEn: "Potential Risks", rows: "3")

      div(.class("submit-form-full workshop-facilities")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "必要設備" : "Required Facilities") }
        label {
          input(.type(.checkbox), .name("workshopFacilityProjector"))
          HTMLText(language == .ja ? "プロジェクター" : "Projector")
        }
        label {
          input(.type(.checkbox), .name("workshopFacilityMicrophone"))
          HTMLText(language == .ja ? "マイク" : "Microphone")
        }
        label {
          input(.type(.checkbox), .name("workshopFacilityWhiteboard"))
          HTMLText(language == .ja ? "ホワイトボード" : "Whiteboard")
        }
        label {
          input(.type(.checkbox), .name("workshopFacilityPowerStrips"))
          HTMLText(language == .ja ? "電源タップ" : "Power Strips")
        }
      }

      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "その他設備" : "Other Facilities") }
        input(.type(.text), .name("workshopFacilityOther"))
      }

      if includeJapanese {
        h5 { HTMLText(language == .ja ? "日本語版の内容（任意）" : "Japanese Translations (Optional)") }
        textareaField(
          name: "workshopKeyTakeawaysJa", labelJa: "学べること (JA)", labelEn: "Key Takeaways (JA)",
          rows: "4")
        textareaField(
          name: "workshopPrerequisitesJa", labelJa: "前提知識 (JA)", labelEn: "Prerequisites (JA)",
          rows: "3")
        textareaField(
          name: "workshopAgendaScheduleJa", labelJa: "アジェンダ (JA)",
          labelEn: "Agenda / Schedule (JA)", rows: "5")
        textareaField(
          name: "workshopParticipantRequirementsJa", labelJa: "持ち物 (JA)",
          labelEn: "What to Bring (JA)", rows: "3")
        textareaField(
          name: "workshopRequiredSoftwareJa", labelJa: "必要なソフトウェア (JA)",
          labelEn: "Required Software (JA)", rows: "3")
        textareaField(
          name: "workshopNetworkRequirementsJa", labelJa: "ネットワーク要件 (JA)",
          labelEn: "Network Requirements (JA)", rows: "3")
      }

      SubmitCoInstructorFields(language: language, prefix: coInstructor1Prefix)
      SubmitCoInstructorFields(language: language, prefix: coInstructor2Prefix)
    }
  }

  @HTMLBuilder
  private func textareaField(name: String, labelJa: String, labelEn: String, rows: String)
    -> some HTML
  {
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? labelJa : labelEn) }
      textarea(.name(name), .custom(name: "rows", value: rows)) {}
    }
  }
}

import Ignite
import SharedModels

enum PrivacyPolicySectionType: String, SectionDefinition {
  case announcementForUS = "" // Untitled
  case definition = "Definintions"
  case collectionOfPersonalData = "Information You Provide to Us"
  case useOfPersonalData = "Use of Information"
  case managementOfPersonalData = "Manage of Information"
  case disclosureAndCorrection = "Disclosure and correction of information"
  case changesToPolicy = "Changes"
  case contactForInquiries = "Contact us"
}

extension PrivacyPolicySectionType {
  var description: String {
    switch self {
    case .announcementForUS: "This translation is not an official one. Only the Japanese version is legally responsible. This English translation is intended to assist in understanding the [Japanese version of the Privacy Policy](/privacy-policy)."
    case .definition: "1. The \"Corporation\" means try Swift Tokyo Association.\n2. The term \"Personal information\" refers to information about living individuals (including name, address, phone number, etc.) and information that can identify specific individuals (including e-mail addresses and SNS accounts) as defined in Japan's \"Act on the Protection of Personal Information\" (Act No. 57 of 2003)."
    case .collectionOfPersonalData: "The Corporation will collect information registered when using the services provided by the Corporation, such as events sponsored by the Corporation, to the extent necessary. In principle, the collection of personal information shall be based on the provider's intention."
    case .useOfPersonalData: "The Corporation will use the personal information provided by you within the scope of the following purposes.\n1. Identification, provision of services related to applications for use, billing of usage fees, and notification of changes, suspension, discontinuation, or cancellation of the terms and conditions of service provision.\n2. Providing necessary information related to event management, such as event announcements, distribution and use of official applications, etc.\n3. In addition to the above, to provide information on various services of the Corporation and to conduct surveys for service improvement\n\nIn addition, in any of the following cases, personal information may be used or disclosed and provided for purposes other than those described above.\n\n1. When required by law\n2. When there is the consent of the person providing the information.\n3. When all or part of the handling of personal information is outsourced to the extent necessary to achieve the business purpose (for example, when services such as delivery are outsourced)"
    case .managementOfPersonalData: "The Corporation will make every effort to properly manage the personal information it collects."
    case .disclosureAndCorrection: "When a provider of personal information requests disclosure of their own personal information, the Corporation will, in principle, disclose the information without delay. When a provider of personal information requests correction of their own personal information, the Corporation will, in principle, make such correction without delay."
    case .changesToPolicy: "The Corporation may revise its privacy policy without prior notice. Any revision of the privacy policy will be posted on the website operated by the Corporation without delay."
    case .contactForInquiries: "If you have any questions about Privacy Policy, please contact us at <a href=\"mailto:tokyo@tryswift.jp\">tokyo@tryswift.jp</a>."
    }
  }
}

struct PrivacyPolicy: StaticPage {
  let language: SupportedLanguage
  let title: String

  var path: String {
    generatePath(language: language)
  }

  init(language: SupportedLanguage) {
    self.language = language
    self.title = String("Privacy Policy", language: language)
  }

  var body: some HTML {
    MainNavigationBar(
      path: { generatePath(language: $1) },
      sections: HomeSectionType.navigationItems(for: .latest),
      year: .latest,
      language: language
    )

    Text(String("Last Update: Oct.10, 2023", language: language))
      .horizontalAlignment(.trailing)
      .font(.body)
      .foregroundStyle(.dimGray)
      .margin(.top, .px(100))

    let sectionTypes = PrivacyPolicySectionType.allCases.filter { section in
      switch language {
      case .ja: section != .announcementForUS
      case .en: true
      }
    }
    SectionListComponent(title: title, dataSource: sectionTypes, language: language)
      .margin(.top, .px(40))

    MainFooterWithBackground(year: .latest, language: language)
      .margin(.top, .px(160))
  }

  private func generatePath(language: SupportedLanguage) -> String {
    switch language {
    case .ja: "/privacy-policy"
    case .en: "/privacy-policy_en"
    }
  }
}

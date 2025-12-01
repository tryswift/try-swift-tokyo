import Ignite
import SharedModels

enum FAQSectionType: String, SectionDefinition {
  case aboutTrySwift = "Q. What's try! Swift?"
  case conferenceLanguages = "Q. In which languages will the conference be held?"
  case ticketCancellationPolicy = "Q. What is ticket cancellation policy?"
  case ticketTransfer = "Q. Can tickets be transferred?"
  case receiptAndInvoice = "Q. Can you issue a receipt and invoice?"
  case visaSupport = "Q. Do you provide tourist visa support?"
  case beginnerParticipation = "Q. Can beginners participate?"
  case preparationBeforeEvent = "Q. Is there anything I need to do before the day of the event?"
}

extension FAQSectionType {
  var description: String {
    switch self {
    case .aboutTrySwift: "try! Swift is an international Swift conference that started in Tokyo in 2016. In addition to Tokyo, the conference has been held in New York, Bangalore, and San Jose, and in 2018, Apple's SwiftNIO team was the first in the world to present SwiftNIO, and in 2019, try! Swift was introduced to the Swift community at WWDC.<br><br>The conference will bring together selected experts from around the world to give 20-minute presentations on topics related to Swift. iOS, iPadOS, SwiftUI, and visionOS, as well as Apple Platform topics including Swift, Open-Source Swift, Swift on Server, and many other Swift topics.<br><br>In addition, try! Swift will have office hours where you can ask one-on-one questions to the speakers and ask any questions you may have had about the content of their talks."
    case .conferenceLanguages: "try! Swift Tokyo operates primarily in Japanese and English, with all venue announcements made in both languages. We also provide AI-powered translation tools, allowing participants to follow sessions in their native language."
    case .ticketCancellationPolicy: "Ticket cancellations are accepted up until 30 days before the event, specifically by Thursday, March 12 (JST).<br>After canceling via Luma, please contact the organizers. No cancellations will be accepted after this deadline.<br><br>Regardless of ticket type, a 10% processing fee will be deducted from the refund amount. The refund processing time will depend on the payment service’s policies."
    case .ticketTransfer: "Unfortunately, ticket transfers are not permitted due to system limitations."
    case .receiptAndInvoice: "You can create a receipt by opening the <a href=\"https://luma.com/settings/payment\" target=\"_blank\">Luma payment history page</a> and selecting the menu icon (three dots) displayed on the right side of the payment history. If you want to customize the name on the receipt, you can temporarily change your account name in the <a href=\"https://luma.com/settings\" target=\"_blank\">Luma settings</a>."
    case .visaSupport: "Some countries and regions require an application for a tourist VISA in order to enter Japan.<br>Depending on the country of residence you selected when you purchased your ticket, we will ask you if you need assistance with VISA application documents.<br>To find out if you reside in a country that requires a VISA, please visit the <a href=\"https://www.mofa.go.jp/j_info/visit/visa/index.html\" target=\"_blank\">Ministry of Foreign Affairs website</a>."
    case .beginnerParticipation: "Yes, there is no limit to the level of participation. However, you may find the talks difficult.Most of the topics discussed at \"try! Swift\" are about cutting edge technology and techniques. You may not understand it on the spot, but we believe that being aware of what you don't understand, discussing it with others, and asking the speakers directly is an important value at the conference. Please come to the venue with an eagerness to learn and understand something new."
    case .preparationBeforeEvent: "Yes, you are welcome to join the Discord. Ticket purchasers will receive an invitation link to the Discord, where various topics related to Swift and development will be discussed, so please try to interact with each other before the event. You can get to know each other well before the event, and you may end up going out to dinner on the day of the event, or you may meet each other again after a long time at a conference outside of your country."
    }
  }
}

struct FAQ: StaticPage {
  let language: SupportedLanguage
  let title: String

  var path: String {
    generatePath(language: language)
  }

  init(language: SupportedLanguage) {
    self.language = language
    self.title = String("FAQ", language: language)
  }

  var body: some HTML {
    MainNavigationBar(
      path: { generatePath(language: $1) },
      sections: HomeSectionType.navigationItems(for: .latest),
      year: .latest,
      language: language
    )

    let sectionTypes = FAQSectionType.allCases.filter { section in
      switch language {
      case .ja: section != .visaSupport
      case .en: true
      }
    }
    SectionListComponent(title: title, dataSource: sectionTypes, language: language)
      .margin(.top, .px(140))

    MainFooterWithBackground(year: .latest, language: language)
      .margin(.top, .px(160))
  }

  private func generatePath(language: SupportedLanguage) -> String {
    switch language {
    case .ja: "/faq"
    case .en: "/faq_en"
    }
  }
}

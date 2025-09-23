import Ignite

enum CodeOfConductSectionType: String, SectionDefinition {
  case communityParticipation = "Participation in the Community"
  case harassmentFree = "For Harassment-free"
  case forSpeakers = "For Speakers"
  case forAttendees = "For Attendees"
  case reportingMisconduct = "Action"
  case license = "License"
}

extension CodeOfConductSectionType {
  var description: String {
    switch self {
    case .communityParticipation: "In order to provide a safe and secure event experience for everyone in the community and at community-sponsored events, all participants, regardless of their role as a speaker, participant, or staff member, are required to abide by the Code of Conduct as described herein. If you do not agree, you will not be allowed to participate in the event.<br><br>In addition, there is a purpose for holding the event. Please do not behave in a manner that is incompatible with the purpose of the event."
    case .harassmentFree: "This community is dedicated to providing a harassment-free conference experience for everyone, regardless of gender, sexual orientation, disability, physical appearance, body size, race, or religion. We do not tolerate harassment of conference participants in any form. Sexual language and imagery is not appropriate for any conference venue, including talks, workshops, parties, Twitter and other online media. Conference participants violating these rules may be sanctioned or expelled from the conference without a refund at the discretion of the conference organizers.<br><br>We don’t want anyone to be excluded due to age, gender, sexual orientation, mental or physical impairments, appearance or skin colour, national or religious background. We hope to see the same attitude with our attendees, and look forward to experiencing a non-violent and peaceful event with you."
    case .forSpeakers: "It is not appropriate to use images or text in presentations or slides that violate the above. In addition, sexist, racist, or other references to the above are not acceptable, even if the person is joking in talk.<br><br>If you have any questions during the preparation of your presentation, please let us know."
    case .forAttendees: "Harassment includes offensive verbal comments related to gender, sexual orientation, disability, physical appearance, body size, race, religion, sexual images in public spaces, deliberate intimidation, stalking, following, harassing photography or recording, sustained disruption of talks or other events, inappropriate physical contact, and unwelcome sexual attention.<br><br>However, taking pictures or recording a speaker's talk is allowed with permission from the presenter or organizer. Shooting includes screen captures."
    case .reportingMisconduct: "If you are being harassed, notice someone else that is being harassed, or have any other concerns, please contact a member of organizers or volunteers immediately."
    case .license: "This Code of Conduct is released under a <a href=\"https://creativecommons.org/publicdomain/zero/1.0/deed.en\" target=\"_blank\">Creative Commons Zero license</a>."
    }
  }
}

struct CodeOfConduct: StaticPage {
  let language: SupportedLanguage
  let title: String

  var path: String {
    generatePath(language: language)
  }

  init(language: SupportedLanguage) {
    self.language = language
    self.title = String("Code of Conduct", language: language)
  }

  var body: some HTML {
    MainNavigationBar(
      path: { generatePath(language: $1) },
      sections: HomeSectionType.navigationItems(for: .latest),
      year: .latest,
      language: language
    )

    let sectionTypes = CodeOfConductSectionType.allCases
    SectionListComponent(title: title, dataSource: sectionTypes, language: language)
      .margin(.top, .px(140))

    MainFooterWithBackground(language: language)
      .margin(.top, .px(160))
  }

  private func generatePath(language: SupportedLanguage) -> String {
    switch language {
    case .ja: "/code-of-conduct"
    case .en: "/code-of-conduct_en"
    }
  }
}

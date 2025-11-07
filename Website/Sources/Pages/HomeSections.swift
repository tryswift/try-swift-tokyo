import DataClient
import Foundation
import Ignite
import SharedModels

enum HomeSectionType: String, CaseIterable {
  case about = "About"
  case outline = "Outline"
  case speaker = "Speaker"
  case tickets = "Tickets"
  case meetTheHosts = "Meet the Hosts"
  case timetable = "Timetable"
  case sponsor = "Sponsor"
  case meetTheOrganizers = "Meet the Organizers"
  case access = "Access"
}

extension HomeSectionType {
  var htmlId: String {
    rawValue
      .lowercased()
      .replacingOccurrences(of: " ", with: "-")
  }

  func isAvailable(for year: ConferenceYear) -> Bool {
    switch year {
    case .year2025: true
    case .year2026: [.about, .outline, .access].contains(self)
    }
  }

  static func navigationItems(for year: ConferenceYear) -> [Self] {
    allCases.filter {
      $0.isAvailable(for: year)
        && ![.meetTheHosts, .meetTheOrganizers].contains($0)
    }
  }
}

extension HomeSectionType {
  @MainActor
  @HTMLBuilder
  func generateContents(for year: ConferenceYear, language: SupportedLanguage, dataClient: DataClient) -> some HTML {
    switch self {
    case .about:
      HeaderComponent(language: language)
        .ignorePageGutters()
        .id(htmlId)

      let text = switch year {
      case .year2025: String(
        "Developers from all over the world gather<br>for tips and tricks and the latest case studies of development using Swift.<br>Developers from all over the world will gather here.<br>Swift and to showcase our Swift knowledge and skills, and to collaborate with each other,<br>The event will be held for three days from April 9 - 11, 2025!",
        language: language
      )
      case .year2026: String(
        "Developers from all over the world gather<br>for tips and tricks and the latest case studies of development using Swift.<br>Developers from all over the world will gather here.<br>Swift and to showcase our Swift knowledge and skills, and to collaborate with each other,<br>The event will be held for three days from April 12 - 14, 2026!",
        language: language
      )}
      Text(text)
        .horizontalAlignment(.center)
        .font(.lead)
        .foregroundStyle(.dimGray)
        .margin(.top, .px(20))
        .margin(.horizontal, .px(50))
    case .outline:
      SectionHeader(type: self, language: language)
      OutlineComponent(year: year, language: language)
        .padding(.bottom, .px(32))
    case .tickets:
      SectionHeader(type: self, language: language)
      TicketsComponent(language: language)
    case .speaker:
      SectionHeader(type: self, language: language)

      let speakers = try! dataClient.fetchSpeakers()
      CenterAlignedGrid(speakers, columns: 4) { speaker in
        SpeakerComponent(speaker: speaker)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: speaker.modalId)
          }
      }

      Alert {
        ForEach(speakers) { speaker in
          SpeakerModal(speaker: speaker, language: language)
        }
      }
    case .meetTheHosts:
      SectionHeader(type: self, language: language)

      let hosts = try! dataClient.fetchOrganizers()
        .filter { [6, 11].contains($0.id) }
      CenterAlignedGrid(hosts, columns: hosts.count) { organizer in
        OrganizerComponent(organizer: organizer)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: organizer.modalId)
          }
      }
    case .timetable:
      SectionHeader(type: self, language: language)

      let day1 = try! dataClient.fetchDay1()
      let day2 = try! dataClient.fetchDay2()
      let day3 = try! dataClient.fetchDay3()

      Accordion {
        Item(day1.date.formattedDateString(language: language), startsOpen: false) {
          Section {
            TimetableComponent(conference: day1, language: language)
          }
        }
        Item(day2.date.formattedDateString(language: language), startsOpen: false) {
          Section {
            TimetableComponent(conference: day2, language: language)
          }
        }
        Item(day3.date.formattedDateString(language: language), startsOpen: false) {
          Section {
            TimetableComponent(conference: day3, language: language)
          }
        }
      }

      Alert {
        let sessions = [day1, day2, day3]
          .flatMap { $0.schedules.flatMap(\.sessions) }
          .filter(\.hasDescription)
        ForEach(sessions) { session in
          SessionDetailModal(session: session, language: language)
        }
      }
    case .sponsor:
      SectionHeader(type: self, language: language)

      let sponsors = try! dataClient.fetchSponsors()
      ForEach(Plan.allCases) { plan in
        if let sponsors = sponsors.allPlans[plan], !sponsors.isEmpty {
          Text(plan.rawValue.localizedCapitalized.uppercased())
            .horizontalAlignment(.center)
            .font(.title1)
            .fontWeight(.bold)
            .foregroundStyle(plan.titleColor)
            .margin(.all, .px(32))

          CenterAlignedGrid(sponsors, columns: plan.columnCount) { sponsor in
            Section {
              SponsorComponent(sponsor: sponsor, size: plan.maxSize, language: language)
            }
          }.margin(.bottom, .px(160))
        }
      }
    case .meetTheOrganizers:
      SectionHeader(type: self, language: language)

      let organizers = try! dataClient.fetchOrganizers()
      CenterAlignedGrid(organizers, columns: 4) { organizer in
        OrganizerComponent(organizer: organizer)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: organizer.modalId)
          }
      }

      Alert {
        ForEach(organizers) { organizer in
          OrganizerModel(organizer: organizer, language: language)
        }
      }
    case .access:
      AccessComponent(year: year, language: language)
        .ignorePageGutters()
        .id(htmlId)
    }
  }
}

private extension Plan {
  var columnCount: Int {
    switch self {
    case .platinum, .gold:
      return 3
    case .silver:
      return 4
    case .bronze, .diversityAndInclusion, .community, .student:
      return 5
    case .individual:
      return 6
    }
  }

  var maxSize: CGSize {
    switch self {
    case .platinum:
      return .init(width: 260, height: 146)
    case .gold:
      return .init(width: 200, height: 112)
    case .silver:
      return .init(width: 160, height: 90)
    case .bronze, .diversityAndInclusion, .community, .student:
      return .init(width: 130, height: 72)
    case .individual:
      return .init(width: 100, height: 100)
    }
  }

  var titleColor: Color {
    switch self {
    case .platinum: .lightSlateGray
    case .gold: .goldenrod
    case .silver: .silver
    case .bronze: .saddleBrown
    case .diversityAndInclusion, .student, .community, .individual: .steelBlue
    }
  }
}

import DataClient
import Foundation
import Ignite
import SharedModels

enum HomeSectionType: String, CaseIterable {
  case about = "About"
  case outline = "Outline"
  case tickets = "Tickets"
  case cfp = "Call for Proposals"
  case speaker = "Speaker"
  case workshop = "Workshop"
  case timetable = "Timetable"
  case sponsor = "Sponsor"
  case meetTheHosts = "Meet the Hosts"
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
    case .year2025: [.about, .outline, .speaker, .timetable, .sponsor, .meetTheHosts, .meetTheOrganizers, .access].contains(self)
    case .year2026: [.about, .outline, .tickets, .cfp, .speaker, .workshop, .sponsor, .meetTheHosts, .meetTheOrganizers, .access].contains(self)
    }
  }

  static func navigationItems(for year: ConferenceYear) -> [Self] {
    allCases.filter {
      $0.isAvailable(for: year)
        && ![.tickets, .meetTheHosts, .meetTheOrganizers].contains($0)
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

      let speakers = try! dataClient.fetchSpeakers(year: year)
      CenterAlignedGrid(speakers, columns: 4) { speaker in
        SpeakerComponent(speaker: speaker)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: speaker.modalId)
          }
      }

      if year == .year2026 {
        Text("And more...!")
          .horizontalAlignment(.center)
          .font(.title3)
          .foregroundStyle(.dimGray)
          .margin(.top, .px(32))
      }

      Alert {
        ForEach(speakers) { speaker in
          SpeakerModal(year: year, speaker: speaker, language: language)
        }
      }
    case .workshop:
      SectionHeader(type: self, language: language)

      let workshops = try! dataClient.fetchDay1(year: .year2026)
        .schedules
        .flatMap(\.sessions)
        .filter { $0.speakers?.isEmpty == false }

      WorkshopComponent(workshops: workshops, year: year, language: language)

      Text("And more...!")
        .horizontalAlignment(.center)
        .font(.title3)
        .foregroundStyle(.dimGray)
        .margin(.top, .px(32))
    case .cfp:
      SectionHeader(type: self, language: language)
      CallForProposalComponent(language: language)
    case .meetTheHosts:
      let hosts = try! dataClient.fetchOrganizers(year: year)
        .filter { [6, 11].contains($0.id) }

      SectionHeader(type: self, language: language)
      CenterAlignedGrid(hosts, columns: hosts.count) { organizer in
        OrganizerComponent(organizer: organizer)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: organizer.modalId)
          }
      }
    case .timetable:
      SectionHeader(type: self, language: language)

      let day1 = try! dataClient.fetchDay1(year)
      let day2 = try! dataClient.fetchDay2(year)
      let day3 = try! dataClient.fetchDay3(year)

      Grid(alignment: .top, spacing: 16) {
        ForEach([day1, day2, day3]) { data in
          Section {
            TimetableComponent(conference: data, language: language)
          }
        }
      }
      .columns(3)

      Alert {
        let sessions = [day1, day2, day3]
          .flatMap { $0.schedules.flatMap(\.sessions) }
          .filter(\.hasDescription)
        ForEach(sessions) { session in
          SessionDetailModal(year: year, session: session, language: language)
        }
      }
    case .sponsor:
      let sponsors = try! dataClient.fetchSponsors(year)

      SectionHeader(type: self, language: language)
      ForEach(Plan.allCases) { plan in
        if let sponsors = sponsors.allPlans[plan], !sponsors.isEmpty {
          Text(plan.rawValue.localizedCapitalized.uppercased())
            .horizontalAlignment(.center)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(plan.titleColor)
            .background(plan.titleBackgroundColor)
            .cornerRadius(.px(16))
            .margin(.bottom, .px(48))

            Grid(alignment: .center, spacing: 48) {
                ForEach(sponsors) { sponsor in
                    SponsorComponent(sponsor: sponsor, size: plan.maxSize, language: language)
                }
            }
            .columns(plan.columnCount)
            .horizontalAlignment(.center)
            .margin(.bottom, .px(96))
        }
      }

      if year == ConferenceYear.latest {
        CallForSponsorsComponent(language: language)
          .margin(.top, .px(32))
      }
    case .meetTheOrganizers:
      let organizers = try! dataClient.fetchOrganizers(year: year)

      SectionHeader(type: self, language: language)
      CenterAlignedGrid(organizers, columns: 4) { organizer in
        OrganizerComponent(organizer: organizer)
          .margin(.bottom, .px(32))
          .onClick {
            ShowModal(id: organizer.modalId)
          }
      }

      Alert {
        ForEach(organizers) { organizer in
          OrganizerModel(year: year, organizer: organizer, language: language)
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
    case .platinum: 1
    case .gold: 2
    case .silver: 3
    case .bronze: 4
    case .diversityAndInclusion, .community, .student: 5
    case .individual: 6
    }
  }

  var maxSize: CGSize {
    switch self {
    case .platinum:
      return .init(width: 400, height: 224)
    case .gold:
        return .init(width: 320, height: 179)
    case .silver:
      return .init(width: 220, height: 124)
    case .bronze, .diversityAndInclusion, .student, .community:
      return .init(width: 200, height: 112)
    case .individual:
      return .init(width: 130, height: 73)
    }
  }

  var titleColor: Color {
    switch self {
    case .platinum: .init(hex: "#657E8C")
    case .gold: .init(hex: "#5E532A")
    case .silver: .init(hex: "#657E8C")
    case .bronze: .init(hex: "#AD5523")
    case .diversityAndInclusion, .student: .init(hex: "#1B849B")
    case .community, .individual: .init(hex: "#6B3EAF")
    }
  }

    var titleBackgroundColor: Color {
        switch self {
        case .platinum: .init(hex: "#D0E1EA")
        case .gold: .init(hex: "#EFE4B9")
        case .silver: .init(hex: "#E5E5E5")
        case .bronze: .init(hex: "#F3E0D5")
        case .diversityAndInclusion, .student: .init(hex: "#C4F0F2")
        case .community, .individual: .init(hex: "#EBDFFF")
        }
    }
}

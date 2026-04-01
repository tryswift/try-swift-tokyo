import DataClient
import Dependencies
import Foundation
import Ignite
import SharedModels

struct Home2016: StaticPage {
  let language: SupportedLanguage
  var title = ""

  var path: String {
    Home.generatePath(for: .year2016, language: language)
  }

  @Dependency(DataClient.self) var dataClient

  var body: some HTML {
    // Navigation bar
    Retro2016NavigationBar(language: language)

    // Header / About section
    Retro2016HeaderComponent(language: language)
      .id("about")

    // About text
    Text(String("hero-text-past", language: language))
      .horizontalAlignment(.center)
      .font(.lead)
      .foregroundStyle(.dimGray)
      .margin(.top, .px(20))
      .margin(.horizontal, .px(50))

    // Outline section
    Retro2016SectionHeader(title: "Outline", htmlId: "outline", language: language)
    OutlineComponent(year: .year2016, language: language)
      .padding(.bottom, .px(32))

    // Speaker section
    Retro2016SectionHeader(title: "Speaker", htmlId: "speaker", language: language)

    let speakers = try! dataClient.fetchSpeakers(year: .year2016)
    CenterAlignedGrid(speakers, columns: 4) { speaker in
      Retro2016SpeakerComponent(speaker: speaker)
        .margin(.bottom, .px(32))
        .onClick {
          ShowModal(id: speaker.modalId)
        }
    }

    // Speaker modals
    Alert {
      ForEach(speakers) { speaker in
        SpeakerModal(year: .year2016, speaker: speaker, language: language)
      }
    }

    // Timetable section - all 3 days
    Retro2016SectionHeader(title: "Timetable", htmlId: "timetable", language: language)

    let day1 = try! dataClient.fetchDay1(.year2016)
    let day2 = try! dataClient.fetchDay2(.year2016)
    let day3 = try! dataClient.fetchDay3(.year2016)

    let allDays = [day1, day2, day3]

    Grid(alignment: .top, spacing: 16) {
      ForEach(allDays) { data in
        Section {
          TimetableComponent(conference: data, language: language)
        }
      }
    }
    .columns(3)

    // Session detail modals
    Alert {
      let sessions =
        allDays
        .flatMap { $0.schedules.flatMap(\.sessions) }
        .filter(\.hasDescription)
      ForEach(sessions) { session in
        SessionDetailModal(year: .year2016, session: session, language: language)
      }
    }

    // Access section (reuse existing - includes footer)
    AccessComponent(year: .year2016, language: language)
      .ignorePageGutters()
      .id("access")
  }
}

// MARK: - Retro 2016 Section Header

private struct Retro2016SectionHeader: HTML {
  let title: String
  let htmlId: String
  let language: SupportedLanguage

  var body: some HTML {
    ZStack(alignment: .center) {
      Text(String(title, language: language))
        .horizontalAlignment(.center)
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.init(hex: "#444444"))
    }
    .padding(.top, .px(80))
    .padding(.bottom, .px(32))
    .margin(.bottom, .px(54))
    .border(.init(hex: "#cccccc"), width: 1, edges: .bottom)
    .id(htmlId)
  }
}

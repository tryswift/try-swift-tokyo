import Ignite
import SharedModels

struct WorkshopComponent: HTML {
  let workshops: [Session]
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    ForEach(workshops) { workshop in
      Section {
        Section {
          HStack {
            contents(workshop: workshop)
          }
        }
        .hidden(.responsive(true, medium: true, large: false, xLarge: false, xxLarge: false))

        Section {
          VStack(spacing: .small) {
            contents(workshop: workshop)
          }
        }
        .hidden(.responsive(false, medium: false, large: true, xLarge: true, xxLarge: true))
      }
      .padding(.bottom, .px(32))
    }

    let speakers = workshops.flatMap { $0.speakers! }
    Alert {
      ForEach(speakers) { speaker in
        SpeakerModal(year: year, speaker: speaker, language: language)
      }
    }
  }

  @HTMLBuilder
  private func contents(workshop: Session) -> some HTML {
    HStack(spacing: 0) {
      let speakerImageSize = workshop.speakers!.count > 1 ? 115 : 230
      ForEach(workshop.speakers!) { speaker in
        Image(speaker.imageFilename, description: speaker.name)
          .resizable()
          .frame(maxWidth: speakerImageSize, maxHeight: speakerImageSize)
          .cornerRadius(speakerImageSize / 2)
          .onClick {
            ShowModal(id: speaker.modalId)
          }
      }
    }
    Section {
      Text(workshop.title)
        .font(.title4)
        .fontWeight(.medium)
        .foregroundStyle(.orangeRed)

      Text(workshop.speakers!.map(\.name).joined(separator: ", "))
        .font(.lead)
        .fontWeight(.thin)
        .foregroundStyle(.dimGray)

      let localizedDescription = String(workshop.description!, bundle: .scheduleFeature, language: language)
        .convertNewlines()
      Text(markdown: localizedDescription)
        .font(.lead)
        .fontWeight(.thin)
        .foregroundStyle(.dimGray)
        .padding(.leading, .px(16))
    }
    .horizontalAlignment(.leading)
  }
}

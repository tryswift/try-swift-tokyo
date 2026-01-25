import Foundation
import Ignite
import SharedModels

struct TimetableComponent: HTML {
  let conference: Conference
  let language: SupportedLanguage
  private let imageSize = 50

  var body: some HTML {
    Text(conference.title)
      .font(.title2)
      .fontWeight(.bold)
      .foregroundStyle(.bootstrapPurple)

    Table {
      for schedule in conference.schedules {
        for session in schedule.sessions {
          if session.shouldShowInTimetable {
            Row {
              Column {
                Text(schedule.time.formattedTimeString())
                  .foregroundStyle(.dimGray)
              }

              Column {
                if let speakers = session.speakers {
                  VStack(alignment: .leading, spacing: 8) {
                    for speaker in speakers {
                      Image(speaker.imageFilename, description: speaker.name)
                        .resizable()
                        .frame(maxWidth: imageSize, maxHeight: imageSize)
                        .cornerRadius(imageSize / 2)
                    }
                  }
                  .padding(.all, .px(8))
                } else {
                  Image.defaultImage
                    .resizable()
                    .frame(maxWidth: imageSize, maxHeight: imageSize)
                    .cornerRadius(imageSize / 2)
                }
              }
              .verticalAlignment(.middle)

              Column {
                SessionTitleComponent(session: session, language: language)
                  .foregroundStyle(.dimGray)
                  .padding(.all, .px(8))
                  .onClick {
                    ShowModal(id: session.modalId)
                  }
              }
              .verticalAlignment(.middle)
            }
          }
        }
      }
    }
    .margin(.bottom, .px(8))
  }
}

private struct SessionTitleComponent: HTML {
  let session: Session
  let language: SupportedLanguage

  var body: some HTML {
    let titleHTML = Span(Localization.schedule(session.title, language: language))
      .font(.lead)
      .fontWeight(.bold)

    if session.hasDescription {
      Underline(titleHTML)
    } else {
      titleHTML
    }
  }
}

struct SessionDetailModal: HTML {
  let year: ConferenceYear
  let session: Session
  let language: SupportedLanguage

  var body: some HTML {
    Modal(
      id: session.modalId,
      body: {
        if let description = session.description, !description.isEmpty {
          Text(Localization.schedule(description, language: language).convertNewlines())
            .font(.lead)
            .foregroundStyle(.dimGray)
            .margin(.horizontal, .px(16))
        }
        if let speakers = session.speakers {
          ForEach(speakers) { speaker in
            SpeakerDetailComponent(speaker: speaker, language: language)
              .background(.lightGray)
              .cornerRadius(8)
              .margin(.bottom, .px(8))
          }
        }
        ModalFooterComponent(year: year, modalId: session.modalId, language: language)
          .padding(.all, .px(16))
      },
      header: {
        Text(Localization.schedule(session.title, language: language))
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
      }
    ).size(.large)
  }
}

extension Session {
  var modalId: String {
    title.replacingOccurrences(of: "'", with: "")
  }

  var hasDescription: Bool {
    !(description ?? "").isEmpty
  }

  var shouldShowInTimetable: Bool {
    title != "Office hour"
  }
}

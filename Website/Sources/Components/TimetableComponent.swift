import Foundation
import Ignite
import SharedModels

struct TimetableComponent: DocumentElement {
  let conference: Conference
  let language: SupportedLanguage
  private let imageSize = 50

  var body: some HTML {
    Text(conference.title)
      .font(.title2)
      .fontWeight(.bold)
      .foregroundStyle(.bootstrapPurple)

    ForEach(conference.schedules) { schedule in
      Card {
        ForEach(schedule.sessions) { session in
          ZStack(alignment: .topLeading) {
            if let speakers = session.speakers {
              ForEach(speakers) { speaker in
                Image(speaker.imageFilename, description: speaker.name)
                  .resizable()
                  .frame(maxWidth: imageSize, maxHeight: imageSize)
                  .cornerRadius(imageSize / 2)
              }
            } else {
              Image.defaultImage
                .resizable()
                .frame(maxWidth: imageSize, maxHeight: imageSize)
                .cornerRadius(imageSize / 2)
            }

            SessionTitleComponent(session: session, language: language)
              .foregroundStyle(.dimGray)
              .margin(.leading, .px(imageSize + 20))
              .margin(.vertical, .px(8))
          }
          .padding(.all, .px(8))
          .onClick {
            ShowModal(id: session.modalId)
          }
        }
      } header: {
        schedule.time.formattedTimeString()
      }
    }.margin(.bottom, .px(8))
  }
}

private struct SessionTitleComponent: HTML {
  let session: Session
  let language: SupportedLanguage

  var body: some HTML {
    let titleHTML = Text(String(session.title, bundle: .scheduleFeature, language: language))
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
  let session: Session
  let language: SupportedLanguage

  var body: some HTML {
    Modal(
      id: session.modalId,
      body: {
        if let description = session.description, !description.isEmpty {
          Text(String(description, bundle: .scheduleFeature, language: language))
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
        ModalFooterComponent(modalId: session.modalId, language: language)
          .padding(.all, .px(16))
      },
      header: {
        Text(String(session.title, bundle: .scheduleFeature, language: language))
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
}

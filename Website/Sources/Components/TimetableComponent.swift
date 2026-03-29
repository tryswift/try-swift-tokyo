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
                Text(
                  schedule.endTime.map {
                    "\(schedule.time.formattedTimeString()) 〜 \($0.formattedTimeString())"
                  }
                    ?? schedule.time.formattedTimeString()
                )
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
                  .onClick {
                    ShowModal(id: session.modalId)
                  }
                if let sponsor = session.sponsor {
                  Span("Sponsored by \(sponsor)")
                    .font(.small)
                    .fontWeight(.regular)
                    .foregroundStyle(.dimGray)
                }
              }
              .verticalAlignment(.middle)
              .padding(.all, .px(8))
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
    let titleHTML = Span(session.localizedTitle(for: language))
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
        if let description = session.localizedDescription(for: language), !description.isEmpty {
          Text(markdown: description.convertNewlines())
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
        Text(session.localizedTitle(for: language))
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
      }
    ).size(.large)
  }
}

extension Session {
  var modalId: String {
    // Generate a compact, unique ID using FNV-1a (64-bit) hash of title + description.
    let combined = title + (description ?? "")
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in combined.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 1_099_511_628_211
    }
    return "modal-\(String(hash, radix: 16))"
  }

  var hasDescription: Bool {
    !(description ?? "").isEmpty
  }

  var shouldShowInTimetable: Bool {
    title != "Office hour"
  }
}

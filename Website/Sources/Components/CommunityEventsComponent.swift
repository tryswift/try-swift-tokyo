import Ignite
import SharedModels

struct CommunityEventsComponent: HTML {
  struct Event {
    let name: String
    let imageName: String
    let url: String

    var imageFilename: String {
      "/images/events/\(imageName).png"
    }
  }

  let year: ConferenceYear
  let events: [Event]

  init(year: ConferenceYear, language: SupportedLanguage) {
    self.year = year

    events =
      switch year {
      case .year2026:
        [
          Event(
            name: String("try! Swift Tokyo 2026 Hackathon for Students", language: language),
            imageName: "event-2026-1",
            url: "https://connpass.com/event/383016/"
          ),
          Event(
            name: String("Sakura.swift #1", language: language),
            imageName: "event-2026-2",
            url: "https://sakuraswift.connpass.com/event/385856/"
          ),
        ]
      default: []
      }
  }

  var body: some HTML {
    CenterAlignedGrid(events, columns: 2) { event in
      VStack(alignment: .center) {
        let image = Image(event.imageFilename, description: event.name)
          .resizable()
          .frame(maxWidth: 307, maxHeight: 230)
          .cornerRadius(20)
          .margin(.bottom, .px(16))

        Link(image, target: event.url)
          .target(.newWindow)
        Link(event.name, target: event.url)
          .target(.newWindow)
          .font(.title4)
          .fontWeight(.medium)
          .foregroundStyle(.orangeRed)
      }
      .margin(.bottom, .px(32))
    }
  }
}

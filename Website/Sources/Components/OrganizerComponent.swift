import Ignite
import SharedModels

struct OrganizerComponent: HTML {
  let organizer: Organizer

  var body: some HTML {
    Section {
      Image(organizer.imageFilename, description: organizer.name)
        .resizable()
        .frame(maxWidth: 230, maxHeight: 230)
        .cornerRadius(115)
        .margin(.bottom, .px(16))
      Text(organizer.name)
        .font(.title4)
        .fontWeight(.medium)
        .foregroundStyle(.orangeRed)
    }
    .horizontalAlignment(.center)
  }
}

struct OrganizerModel: HTML {
  let year: ConferenceYear
  let organizer: Organizer
  let language: SupportedLanguage
  private let imageSize = 75

  var body: some HTML {
    Modal(id: organizer.modalId) {
      ZStack(alignment: .topLeading) {
        Image(organizer.imageFilename, description: organizer.name)
          .resizable()
          .frame(maxWidth: imageSize, maxHeight: imageSize)
          .cornerRadius(imageSize / 2)

        Section {
          Text(organizer.name)
            .font(.title2)
            .foregroundStyle(.bootstrapPurple)

          let bio = organizer.localizedBio(for: language).convertNewlines()
          Text(markdown: bio)
            .font(.body)
            .fontWeight(.regular)
            .foregroundStyle(.dimGray)
          if let links = organizer.links {
            Section {
              ForEach(links) { link in
                Link(link.name, target: link.url)
                  .target(.newWindow)
                  .role(.secondary)
                  .margin(.trailing, .px(4))
              }
            }
          }
        }.margin(.leading, .px(imageSize + 20))
      }.padding(.all, .px(16))

      ModalFooterComponent(
        year: year,
        modalId: organizer.modalId,
        language: language
      )
      .padding(.all, .px(16))
    }.size(.large)
  }
}

extension Organizer {
  var imageFilename: String {
    "/images/from_app/\(imageName).png"
  }

  var modalId: String {
    name.replacingOccurrences(of: "'", with: "")
  }
}

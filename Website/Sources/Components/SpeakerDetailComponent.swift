import Ignite
import SharedModels

struct SpeakerDetailComponent: HTML {
  let speaker: Speaker
  let language: SupportedLanguage
  private let imageSize = 75

  var body: some HTML {
    ZStack(alignment: .topLeading) {
      Image(speaker.imageFilename, description: speaker.name)
        .resizable()
        .frame(maxWidth: imageSize, maxHeight: imageSize)
        .cornerRadius(imageSize / 2)

      Section {
        Text(speaker.name)
          .font(.title2)
          .foregroundStyle(.bootstrapPurple)

        if let bio = speaker.bio {
          let localizedBio = String(bio, bundle: .scheduleFeature, language: language)
            .convertNewlines()
          Text(markdown: localizedBio)
            .font(.body)
            .fontWeight(.regular)
            .foregroundStyle(.dimGray)
        }
        if let links = speaker.links {
          Row {
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
  }
}

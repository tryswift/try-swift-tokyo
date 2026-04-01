import Ignite
import SharedModels

struct Retro2016SpeakerComponent: HTML {
  let speaker: Speaker
  let language: SupportedLanguage

  var body: some HTML {
    Section {
      Image(speaker.imageFilename, description: speaker.name)
        .resizable()
        .frame(maxWidth: 230, maxHeight: 230)
        .cornerRadius(115)
        .border(.init(hex: "#FC983B"), width: 4)
        .margin(.bottom, .px(16))
      Text(speaker.name)
        .font(.title4)
        .fontWeight(.bold)
        .foregroundStyle(.init(hex: "#FC983B"))
      if let link = speaker.links?.first {
        Link(link.name, target: link.url)
          .target(.newWindow)
          .role(.secondary)
          .font(.body)
      }
      if let bio = speaker.localizedBio(for: language) {
        Text(markdown: bio.convertNewlines())
          .font(.body)
          .foregroundStyle(.init(hex: "#59595A"))
          .margin(.top, .px(8))
      }
    }
    .horizontalAlignment(.center)
    .class("retro-2016-speaker")
  }
}

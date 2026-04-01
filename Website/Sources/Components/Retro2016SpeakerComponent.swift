import Ignite
import SharedModels

struct Retro2016SpeakerComponent: HTML {
  let speaker: Speaker

  var body: some HTML {
    Section {
      Image(speaker.imageFilename, description: speaker.name)
        .resizable()
        .frame(maxWidth: 230, maxHeight: 230)
        .cornerRadius(115)
        .margin(.bottom, .px(16))
      Text(speaker.name)
        .font(.title4)
        .fontWeight(.medium)
        .foregroundStyle(.init(hex: "#333333"))
      if let link = speaker.links?.first {
        Link(link.name, target: link.url)
          .target(.newWindow)
          .role(.secondary)
          .font(.body)
      }
    }
    .horizontalAlignment(.center)
  }
}

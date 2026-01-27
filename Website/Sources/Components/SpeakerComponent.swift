import Ignite
import SharedModels

struct SpeakerComponent: HTML {
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
        .foregroundStyle(.orangeRed)
      if let jobTitle = speaker.jobTitle {
        Text(jobTitle)
          .font(.body)
          .fontWeight(.thin)
          .foregroundStyle(.gray)
      }
    }
    .horizontalAlignment(.center)
  }
}

struct SpeakerModal: HTML {
  let year: ConferenceYear
  let speaker: Speaker
  let language: SupportedLanguage

  var body: some HTML {
    Modal(id: speaker.modalId) {
      SpeakerDetailComponent(speaker: speaker, language: language)
      ModalFooterComponent(year: year, modalId: speaker.modalId, language: language)
        .padding(.all, .px(16))
    }.size(.large)
  }
}

extension Speaker {
  var imageFilename: String {
    ImagePath.resolve(imageName)
  }

  var modalId: String {
    name.replacingOccurrences(of: "'", with: "")
  }
}

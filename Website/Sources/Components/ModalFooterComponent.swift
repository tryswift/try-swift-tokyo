import Ignite
import SharedModels

struct ModalFooterComponent: HTML {
  let year: ConferenceYear
  let modalId: String
  let language: SupportedLanguage

  var body: some HTML {
    Grid {
      Button(String("Close", language: language)) {
        DismissModal(id: modalId)
      }
      .role(.light)
      .foregroundStyle(.dimGray)

      Text("try! Swift Tokyo \(year.rawValue)")
        .horizontalAlignment(.trailing)
        .font(.body)
        .fontWeight(.bold)
        .foregroundStyle(.dimGray)
    }.columns(2)
  }
}

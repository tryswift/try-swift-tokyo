import Ignite

struct SectionHeader: HTML {
  let type: HomeSectionType
  let language: SupportedLanguage

  var body: some HTML {
    ZStack(alignment: .center) {
      Text(String(type.rawValue, language: language))
        .horizontalAlignment(.center)
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.bootstrapPurple)
    }
    .padding(.top, .px(80))
    .padding(.bottom, .px(32))
    .margin(.bottom, .px(32))
    .border(.bootstrapPurple, width: 2, edges: .bottom)
    .id(type.htmlId)
  }
}

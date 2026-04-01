import Ignite

struct Retro2016HeaderComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Section {
      Image("/images/title.png", description: "title image")
        .resizable()
        .aspectRatio(260 / 100, contentMode: .fit)
        .frame(width: .percent(50%))
        .margin(.top, .px(100))
        .margin(.horizontal, .percent(25%))

      Text("March 2-4, 2016")
        .horizontalAlignment(.center)
        .font(.title3)
        .foregroundStyle(.init(hex: "#555555"))
        .margin(.top, .px(16))

      Text(String("About", language: language))
        .horizontalAlignment(.center)
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.init(hex: "#444444"))
        .margin(.top, .px(40))
    }
    .background(.white)
  }
}

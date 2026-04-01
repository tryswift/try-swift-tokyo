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
        .foregroundStyle(.white.opacity(0.8))
        .margin(.top, .px(16))

      Text(String("About", language: language))
        .horizontalAlignment(.center)
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.init(hex: "#FC983B"))
        .class("retro-2016-heading")
        .margin(.top, .px(40))
    }
    .background(.init(hex: "#282B35"))
  }
}

import Ignite

struct MainFooterWithBackground: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    ZStack(alignment: .bottom) {
      Section {
        Spacer()
        Image("/images/footer.png", description: "background image of footer")
          .resizable()
          .frame(width: .percent(100%))
      }
      Section {
        MainFooter(year: year, language: language)
          .foregroundStyle(.white)
        IgniteFooter()
          .foregroundStyle(.white)
      }
      .horizontalAlignment(.center)
      .margin(.top, .px(160))
      .frame(width: .percent(100%))
    }
    .ignorePageGutters()
    .background(
      Gradient(
        colors: [.limeGreen, .skyBlue],
        type: .linear(angle: 0)
      )
    )
  }
}

import Ignite

struct HeaderComponent: DocumentElement {
  let language: SupportedLanguage

  var body: some HTML {
    ZStack(alignment: .bottom) {
      Image("/images/head.png", description: "background image of header")
        .resizable()
        .aspectRatio(178 / 100, contentMode: .fit)
        .frame(width: .percent(100%), height: .percent(100%))
        .ignorePageGutters(false)
      Section {
        Image("/images/title.png", description: "title image")
          .resizable()
          .aspectRatio(260 / 100, contentMode: .fit)
          .frame(width: .percent(50%))
          .margin(.top, .px(100))
          .margin(.horizontal, .percent(25%))
          .ignorePageGutters(false)

        ZStack(alignment: .bottom) {
          Section {
            Spacer()
            Image("/images/intersect.svg", description: "decoration image of header")
              .resizable()
              .margin(.bottom, .px(-1))
          }
          Text(String("About", language: language))
            .font(.title1)
            .fontWeight(.bold)
            .foregroundStyle(.bootstrapPurple)
            .margin(.bottom, .percent(2%))
        }
        .frame(alignment: .init(horizontal: .center))
        .ignorePageGutters(false)
      }
    }.background(.darkBlue)
  }
}

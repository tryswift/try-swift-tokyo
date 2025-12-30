import Ignite

struct TicketsComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Section {
      Text(
        markdown: String(
          "You can get ticket from <a href=\"https://luma.com/qydkgwtf\" target=\"_blank\">Luma</a> or get from below.<br>Before getting ticket please read [FAQ](/faq_en).",
          language: language
        )
      )
      .font(.lead)
      .foregroundStyle(.dimGray)
      .margin(.bottom, .px(20))

      Section {
        // It specifies the optimal size according to the screen size, but since the method to directly specify MediaQuery is unclear, it is being handled by branching.

        // for xLarge, xxLarge
        Section {
          Embed(
            title: String("Tickets", language: language),
            url: "https://luma.com/embed/event/evt-WHT17EaVs2of1Gs/simple"
          )
          .aspectRatio(1.1)
        }
        .hidden(.responsive(true, xLarge: false))

        // for large
        Section {
          Embed(
            title: String("Tickets", language: language),
            url: "https://luma.com/embed/event/evt-WHT17EaVs2of1Gs/simple"
          )
          .aspectRatio(0.95)
        }
        .hidden(.responsive(true, large: false, xLarge: true))

        // for medium
        Section {
          Embed(
            title: String("Tickets", language: language),
            url: "https://luma.com/embed/event/evt-WHT17EaVs2of1Gs/simple"
          )
          .aspectRatio(0.65)
        }
        .hidden(.responsive(true, medium: false, large: true))

        // for xSmall, small
        Section {
          Embed(
            title: String("Tickets", language: language),
            url: "https://luma.com/embed/event/evt-WHT17EaVs2of1Gs/simple"
          )
          .aspectRatio(0.3)
        }
        .hidden(.responsive(false, medium: true))
      }
      .margin(.bottom, .px(96))

      Text(String("The latest information is announced on X", language: language))
        .font(.title3)
        .foregroundStyle(.dimGray)
        .margin(.bottom, .px(16))

      Link(
        String("Check updates on X", language: language),
        target: "https://x.com/tryswiftconf"
      )
      .target(.newWindow)
      .linkStyle(.button)
      .role(.light)
      .font(.lead)
      .fontWeight(.medium)
      .foregroundStyle(.orangeRed)
    }.horizontalAlignment(.center)
  }
}

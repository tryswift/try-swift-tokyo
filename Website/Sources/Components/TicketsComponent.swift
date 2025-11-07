import Ignite

struct TicketsComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Section {
        Text(markdown: String(
            "You can get ticket from <a href=\"https://lu.ma/qydkgwtf\" target=\"_blank\">Luma</a> or get from below.<br>Before getting ticket please read [FAQ](/faq_en).",
            language: language
        ))
        .font(.lead)
        .foregroundStyle(.dimGray)
        .margin(.bottom, .px(20))
      Embed(
        title: String("Tickets", language: language),
        url: "https://lu.ma/embed/event/evt-iaERdyhafeQdV5f/simple"
      )
      .aspectRatio(0.75)
      .frame(height: .px(1_800))
      .margin(.bottom, .px(120))
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

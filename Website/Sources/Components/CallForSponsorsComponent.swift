import Ignite

struct CallForSponsorsComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Section {
      Link(
        String("Sponsor Inquiry Form", language: language),
        target: "https://forms.gle/K6naVR6vMb6kxshW6"
      )
      .target(.newWindow)
      .linkStyle(.button)
      .role(.primary)
    }.horizontalAlignment(.center)
  }
}

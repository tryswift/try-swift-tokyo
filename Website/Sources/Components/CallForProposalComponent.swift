import Ignite

struct CallForProposalComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Section {
      Link(
        String("Speaker Application Form", language: language),
        target: "https://forms.gle/FH8EWnPBBF7ziUGDA"
      )
      .target(.newWindow)
      .linkStyle(.button)
      .role(.primary)

      Link(
        String("Workshop Proposal Form", language: language),
        target: "https://forms.gle/Qe1z9Mi4yrqBMdYt9"
      )
      .target(.newWindow)
      .linkStyle(.button)
      .role(.primary)
    }.horizontalAlignment(.center)
  }
}

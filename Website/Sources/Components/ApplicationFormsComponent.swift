import Ignite

struct ApplicationFormsComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Grid {
      Card {
        Text {
          String("We are seeking sponsors to help make try! Swift Tokyo a success!<br>If you are interested, please contact us here.<br>We will send you the relevant materials in due course.", language: language)
            .foregroundStyle(.dimGray)
        }
        Text {
          Link(
            String("Sponsor Inquiry Form", language: language),
            target: "https://forms.gle/K6naVR6vMb6kxshW6"
          )
          .target(.newWindow)
          .linkStyle(.button)
          .role(.primary)
        }
      } header: {
        Text(String("Call for Sponsors", language: language))
          .font(.title4)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
      }

      Card {
        Text {
          String("try! Swift Tokyo is looking for speakers who can share new discoveries and learnings with developers around the world! You can apply for your own talk or recommend someone you’d love to hear on stage.", language: language)
            .foregroundStyle(.dimGray)
        }
        Text {
          Link(
            String("Speaker Application Form", language: language),
            target: "https://forms.gle/FH8EWnPBBF7ziUGDA"
          )
          .target(.newWindow)
          .linkStyle(.button)
          .role(.primary)
        }
      } header: {
        Text(String("Apply or Recommend a Speaker", language: language))
          .font(.title4)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
      }
    }.columns(2)
  }
}

import Ignite

struct ApplicationFormsComponent: HTML {
  let language: SupportedLanguage

  var body: some HTML {
    Grid {
      Card {
        Text {
          String("We are seeking sponsors to help make try! Swift Tokyo a success!<br>If you are interested, please contact us here. We will send you the relevant materials in due course.", language: language)
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
          String("We are looking for speakers to showcase their valuable experiences and captivating skills! Would you like to share your favorite technologies with the world? We look forward to receiving your applications here.", language: language)
            .foregroundStyle(.dimGray)
        }
        Text {
          Link(
            String("Speaker Submission Form", language: language),
            target: "https://forms.gle/FH8EWnPBBF7ziUGDA"
          )
          .target(.newWindow)
          .linkStyle(.button)
          .role(.primary)
        }
      } header: {
        Text(String("Call for Speakers", language: language))
          .font(.title4)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
      }
    }.columns(2)
  }
}

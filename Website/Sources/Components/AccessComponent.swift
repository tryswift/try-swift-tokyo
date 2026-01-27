import Ignite
import SharedModels

struct AccessComponent: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  private var venueData: VenueData {
    switch year {
    case .year2024: .shibuyaStream
    case .year2025, .year2026: .tachikawa
    }
  }

  var body: some HTML {
    ZStack(alignment: .bottom) {
      Section {
        Spacer()
        Image("/images/footer.png", description: "background image of footer")
          .resizable()
          .frame(width: .percent(100%))
      }
      VStack {
        Text(String("Access", language: language))
          .horizontalAlignment(.center)
          .font(.title1)
          .foregroundStyle(.white)
          .padding(.top, .px(80))

        Section {
          Text(String(venueData.name, language: language))
            .font(.title3)
            .foregroundStyle(.white)
          Text(String(venueData.address, language: language))
            .font(.lead)
            .foregroundStyle(.white)
        }
        .horizontalAlignment(.leading)
        .margin(.top, .px(32))

        Embed(title: "map", url: venueData.mapUrl)
          .aspectRatio(.r4x3)
          .margin(.bottom, .px(16))
          .margin(.vertical, .px(8))
          .frame(width: .percent(50%))

        if let accommodationMapUrl = venueData.accommodationMapUrl {
          Text(String("Suggested Nearby Accommodation", language: language))
            .horizontalAlignment(.center)
            .font(.title1)
            .foregroundStyle(.white)
            .margin(.top, .px(80))

          Embed(title: "Suggested Nearby Accommodation", url: accommodationMapUrl)
            .aspectRatio(.r4x3)
            .margin(.bottom, .px(16))
            .margin(.vertical, .px(8))
            .frame(width: .percent(50%))
        }

        Section {
          MainFooter(year: year, language: language)
            .foregroundStyle(.white)
          IgniteFooter()
            .foregroundStyle(.white)
        }
        .margin(.top, .px(160))
        .frame(width: .percent(100%))
      }
      .frame(width: .percent(100%))
      .ignorePageGutters(false)
    }
    .background(
      Gradient(
        colors: [.limeGreen, .skyBlue],
        type: .linear(angle: 0)
      )
    )
  }
}

private struct VenueData {
  let name: String
  let address: String
  let mapUrl: String
  let accommodationMapUrl: String?

  static let shibuyaStream = VenueData(
    name: "Shibuya Stream Hall",
    address: "3-21-3 Shibuya, Shibuya-ku, Tokyo",
    mapUrl: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3241.8477454787366!2d139.70066847677584!3d35.65608333092953!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x60188b5927f8acb3%3A0x7d15e2c2f3b7b0e7!2sShibuya%20Stream%20Hall!5e0!3m2!1sen!2sjp!4v1704067200000!5m2!1sen!2sjp",
    accommodationMapUrl: nil
  )

  static let tachikawa = VenueData(
    name: "TACHIKAWA STAGE GARDEN",
    address: "N1, 3-3, Midori-cho, Tachikawa, Tokyo<br>190-0014",
    mapUrl: "https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d12959.484415464616!2d139.4122493!3d35.7047894!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x6018e16a387013a3%3A0xcd9c50e33a16ff6b!2sTachikawa%20Stage%20Garden!5e0!3m2!1sen!2sjp!4v1720059016768!5m2!1sen!2sjp",
    accommodationMapUrl: "https://www.google.com/maps/d/u/0/embed?mid=1mBsqxzE2L_guJrg7nE96dJBlJUrZVoA&ehbc=2E312F&noprof=1"
  )
}

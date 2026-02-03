import Ignite
import SharedModels

struct OutlineComponent: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    let data: OutlineData =
      switch year {
      case .year2017: .year2017
      case .year2018: .year2018
      case .year2019: .year2019
      case .year2020: .year2020
      case .year2024: .year2024
      case .year2025: .year2025
      case .year2026: .year2026
      }

    Table {
      Row {
        Column {
          String(data.firstLabel, language: language)
            .foregroundStyle(.dimGray)
        }
        .font(.lead)
        .fontWeight(.bold)
        Column {
          String(data.firstValue, language: language)
            .foregroundStyle(.dimGray)
        }
        .font(.lead)
      }
      Row {
        Column {
          String(data.secondLabel, language: language)
            .foregroundStyle(.dimGray)
        }
        .font(.lead)
        .fontWeight(.bold)
        Column {
          String(data.secondValue, language: language)
            .foregroundStyle(.dimGray)
        }
        .font(.lead)
      }
    }
  }
}

private struct OutlineData {
  let firstLabel, firstValue, secondLabel, secondValue: String

  static let year2017 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Mar. 2nd - 4th, 2017",
    secondLabel: "Venue",
    secondValue: "Bellesalle Shinjuku Grand<br>Nishi-Shinjuku, Shinjuku-ku, Tokyo"
  )

  static let year2018 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Mar. 1st - 3rd, 2018",
    secondLabel: "Venue",
    secondValue: "Bellesalle Shinjuku Grand<br>Nishi-Shinjuku, Shinjuku-ku, Tokyo"
  )

  static let year2019 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Mar. 21st - 23rd, 2019",
    secondLabel: "Venue",
    secondValue: "Bellesalle Shinjuku Grand<br>Nishi-Shinjuku, Shinjuku-ku, Tokyo"
  )

  static let year2020 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Mar. 18th - 20th, 2020 (Cancelled)",
    secondLabel: "Venue",
    secondValue: "Bellesalle Shinjuku Grand<br>Nishi-Shinjuku, Shinjuku-ku, Tokyo"
  )

  static let year2024 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Mar. 22nd - 24th, 2024",
    secondLabel: "Venue",
    secondValue: "Shibuya Stream Hall<br>3-21-3 Shibuya, Shibuya-ku, Tokyo"
  )

  static let year2025 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Apr. 9th - 11th, 2025",
    secondLabel: "Venue",
    secondValue: "TACHIKAWA STAGE GARDEN<br>N1, 3-3, Midori-cho, Tachikawa, Tokyo 190-0014"
  )

  static let year2026 = OutlineData(
    firstLabel: "Date and time",
    firstValue:
      "Apr. 12th – 14th, 2026 (JST)<br><br>Apr. 12: Workshop & TBD<br>Apr. 13 - 14: Conference",
    secondLabel: "Venue",
    secondValue:
      "Apr. 12: Tachikawa City, Tokyo, Japan<br>Apr. 13 - 14: <a href=\"#access\">TACHIKAWA STAGE GARDEN</a>"
  )
}

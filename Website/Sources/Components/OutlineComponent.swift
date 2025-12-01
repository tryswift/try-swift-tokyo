import Ignite
import SharedModels

struct OutlineComponent: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    let data: OutlineData = switch year {
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
    ApplicationFormsComponent(language: language)
  }
}

private struct OutlineData {
  let firstLabel, firstValue, secondLabel, secondValue: String

  static let year2025 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Apr. 9th - 11th, 2025",
    secondLabel: "Venue",
    secondValue: "TACHIKAWA STAGE GARDEN<br>N1, 3-3, Midori-cho, Tachikawa, Tokyo 190-0014"
  )

  static let year2026 = OutlineData(
    firstLabel: "Date and time",
    firstValue: "Apr. 12th – 14th, 2026 (JST)<br><br>Apr. 12: Workshop & TBD<br>Apr. 13 - 14: Conference",
    secondLabel: "Venue",
    secondValue: "Apr. 12: Tachikawa City, Tokyo, Japan<br>Apr. 13 - 14: <a href=\"#access\">TACHIKAWA STAGE GARDEN</a>"
  )
}

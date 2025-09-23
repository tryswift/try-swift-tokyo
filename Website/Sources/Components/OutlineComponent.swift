import Ignite

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
        }
        .fontWeight(.bold)
        .foregroundStyle(.dimGray)
        Column {
          String(data.firstValue, language: language)
        }
        .foregroundStyle(.dimGray)
      }
      Row {
        Column {
          String(data.secondLabel, language: language)
        }
        .fontWeight(.bold)
        .foregroundStyle(.dimGray)
        Column {
          String(data.secondValue, language: language)
        }
        .foregroundStyle(.dimGray)
      }
    }
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
    firstLabel: "Workshop",
    firstValue: "Apr. 12th, 2026 (JST)<br><br>Venue:<br>Tokyo, Japan",
    secondLabel: "Conference",
    secondValue: "Apr. 13th – 14th, 2026 (JST)<br><br>Venue:<br>TACHIKAWA STAGE GARDEN<br>N1, 3-3, Midori-cho, Tachikawa, Tokyo 190-0014"
  )
}

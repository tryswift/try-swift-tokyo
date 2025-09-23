import Ignite

struct OutlineComponent: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    Table {
      Row {
        Column {
          switch year {
          case .year2025:
            String("Date and time", language: language)
          case .year2026:
            String("Workshop", language: language)
          }
        }
        .fontWeight(.bold)
        .foregroundStyle(.dimGray)
        Column {
          switch year {
          case .year2025:
            String("Apr. 9th - 11th, 2025", language: language)
          case .year2026:
            String("Apr. 12th, 2026 (JST)<br><br>Venue:<br>Tokyo, Japan", language: language)
          }
        }
        .foregroundStyle(.dimGray)
      }
      Row {
        Column {
          switch year {
          case .year2025:
            String("Venue", language: language)
          case .year2026:
            String("Conference", language: language)
          }
        }
        .fontWeight(.bold)
        .foregroundStyle(.dimGray)
        Column {
          switch year {
          case .year2025:
            String("TACHIKAWA STAGE GARDEN<br>N1, 3-3, Midori-cho, Tachikawa, Tokyo 190-0014", language: language)
          case .year2026:
            String("Apr. 13th – 14th, 2026 (JST)<br><br>Venue:<br>TACHIKAWA STAGE GARDEN<br>N1, 3-3, Midori-cho, Tachikawa, Tokyo 190-0014", language: language)
          }
        }
        .foregroundStyle(.dimGray)
      }
    }
  }
}

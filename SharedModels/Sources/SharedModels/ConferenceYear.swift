public enum ConferenceYear: Int, CaseIterable, Codable, Sendable {
  case year2017 = 2017
  case year2018 = 2018
  case year2019 = 2019
  case year2020 = 2020
  case year2024 = 2024
  case year2025 = 2025
  case year2026 = 2026

  public static var latest: Self {
    Self.allCases.max(by: { $0.rawValue < $1.rawValue })!
  }
}

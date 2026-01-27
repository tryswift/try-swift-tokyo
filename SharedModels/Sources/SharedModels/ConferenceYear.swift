public enum ConferenceYear: Int, CaseIterable {
  case year2024 = 2024
  case year2025 = 2025
  case year2026 = 2026

  public static var latest: Self {
    Self.allCases.max(by: { $0.rawValue < $1.rawValue })!
  }
}

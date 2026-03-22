import Vapor

/// Service for estimating travel costs to Tokyo
/// Uses a combination of static lookup table (for shinkansen, airplane, bus)
/// and the ODPT API (for local railway fares)
enum TravelCostCalculator {

  /// Approximate round-trip costs to Tokyo in yen
  struct CostEstimate: Content, Sendable {
    let city: String
    let cityJa: String
    let bulletTrain: Int?
    let airplane: Int?
    let bus: Int?
    let train: Int?
  }

  /// Static lookup table of approximate round-trip costs from major cities to Tokyo
  static let costTable: [String: CostEstimate] = {
    let entries: [(String, CostEstimate)] = [
      (
        "sapporo",
        CostEstimate(city: "Sapporo", cityJa: "札幌", bulletTrain: 54_000, airplane: 35_000, bus: nil, train: nil)
      ),
      (
        "sendai",
        CostEstimate(city: "Sendai", cityJa: "仙台", bulletTrain: 22_000, airplane: nil, bus: 6_000, train: nil)
      ),
      (
        "niigata",
        CostEstimate(city: "Niigata", cityJa: "新潟", bulletTrain: 22_000, airplane: 25_000, bus: 6_000, train: nil)
      ),
      (
        "kanazawa",
        CostEstimate(city: "Kanazawa", cityJa: "金沢", bulletTrain: 28_000, airplane: nil, bus: 8_000, train: nil)
      ),
      (
        "nagoya",
        CostEstimate(city: "Nagoya", cityJa: "名古屋", bulletTrain: 22_000, airplane: nil, bus: 6_000, train: nil)
      ),
      (
        "kyoto",
        CostEstimate(city: "Kyoto", cityJa: "京都", bulletTrain: 27_000, airplane: nil, bus: 8_000, train: nil)
      ),
      (
        "osaka",
        CostEstimate(city: "Osaka", cityJa: "大阪", bulletTrain: 27_000, airplane: 20_000, bus: 8_000, train: nil)
      ),
      (
        "kobe",
        CostEstimate(city: "Kobe", cityJa: "神戸", bulletTrain: 29_000, airplane: 22_000, bus: 9_000, train: nil)
      ),
      (
        "hiroshima",
        CostEstimate(city: "Hiroshima", cityJa: "広島", bulletTrain: 36_000, airplane: 28_000, bus: 12_000, train: nil)
      ),
      (
        "matsuyama",
        CostEstimate(
          city: "Matsuyama", cityJa: "松山", bulletTrain: nil, airplane: 30_000, bus: 12_000, train: nil)
      ),
      (
        "fukuoka",
        CostEstimate(city: "Fukuoka", cityJa: "福岡", bulletTrain: 46_000, airplane: 30_000, bus: 16_000, train: nil)
      ),
      (
        "kumamoto",
        CostEstimate(
          city: "Kumamoto", cityJa: "熊本", bulletTrain: 48_000, airplane: 32_000, bus: 16_000, train: nil)
      ),
      (
        "kagoshima",
        CostEstimate(
          city: "Kagoshima", cityJa: "鹿児島", bulletTrain: 52_000, airplane: 35_000, bus: 18_000, train: nil)
      ),
      (
        "naha",
        CostEstimate(city: "Naha", cityJa: "那覇", bulletTrain: nil, airplane: 50_000, bus: nil, train: nil)
      ),
      (
        "yokohama",
        CostEstimate(city: "Yokohama", cityJa: "横浜", bulletTrain: nil, airplane: nil, bus: nil, train: 1_200)
      ),
      (
        "chiba",
        CostEstimate(city: "Chiba", cityJa: "千葉", bulletTrain: nil, airplane: nil, bus: nil, train: 1_400)
      ),
      (
        "saitama",
        CostEstimate(city: "Saitama", cityJa: "さいたま", bulletTrain: nil, airplane: nil, bus: nil, train: 1_000)
      ),
      (
        "shizuoka",
        CostEstimate(
          city: "Shizuoka", cityJa: "静岡", bulletTrain: 12_000, airplane: nil, bus: 5_000, train: nil)
      ),
      (
        "nagano",
        CostEstimate(city: "Nagano", cityJa: "長野", bulletTrain: 16_000, airplane: nil, bus: 5_000, train: nil)
      ),
      (
        "okayama",
        CostEstimate(city: "Okayama", cityJa: "岡山", bulletTrain: 34_000, airplane: 26_000, bus: 11_000, train: nil)
      ),
    ]
    return Dictionary(uniqueKeysWithValues: entries)
  }()

  /// Japanese city name lookup for matching
  static let japaneseCityMap: [String: String] = {
    var map: [String: String] = [:]
    for (key, estimate) in costTable {
      map[estimate.cityJa] = key
    }
    return map
  }()

  /// Look up estimated travel cost by city name (English or Japanese)
  static func estimate(from origin: String) -> CostEstimate? {
    let normalized = origin.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    // Try direct English lookup
    if let result = costTable[normalized] {
      return result
    }

    // Try Japanese city name lookup
    let trimmed = origin.trimmingCharacters(in: .whitespacesAndNewlines)
    if let key = japaneseCityMap[trimmed] {
      return costTable[key]
    }

    return nil
  }

  /// Get all available city names for autocomplete (datalist)
  static var allCities: [(english: String, japanese: String)] {
    costTable.values
      .sorted { $0.city < $1.city }
      .map { (english: $0.city, japanese: $0.cityJa) }
  }

  /// Pre-rendered HTML datalist for city autocomplete
  static var datalistHTML: String {
    var html = "<datalist id=\"cityList\">"
    for city in allCities {
      html += "<option value=\"\(city.english)\">"
      html += "<option value=\"\(city.japanese)\">"
    }
    html += "</datalist>"
    return html
  }

  // MARK: - ODPT API Integration

  /// Fetch railway fare from ODPT API
  /// Returns the IC card fare in yen, or nil if not available
  static func fetchODPTFare(
    fromStation: String,
    toStation: String,
    client: Client,
    logger: Logger
  ) async -> Int? {
    guard let apiKey = Environment.get("ODPT_API_KEY") else {
      logger.debug("ODPT_API_KEY not configured, skipping ODPT fare lookup")
      return nil
    }

    guard
      let encodedFrom = fromStation.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let encodedTo = toStation.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      logger.warning("Failed to percent-encode station names")
      return nil
    }

    let url =
      "https://api-public.odpt.org/api/v4/odpt:RailwayFare?odpt:fromStation=\(encodedFrom)&odpt:toStation=\(encodedTo)&acl:consumerKey=\(apiKey)"

    do {
      let response = try await client.get(URI(string: url))
      guard response.status == .ok else {
        logger.warning("ODPT API returned status \(response.status.code)")
        return nil
      }

      let fares = try response.content.decode([ODPTFareResponse].self)
      return fares.first?.icCardFare
    } catch {
      logger.warning("ODPT API request failed: \(error)")
      return nil
    }
  }
}

/// ODPT RailwayFare API response structure
private struct ODPTFareResponse: Codable {
  let icCardFare: Int?
  let ticketFare: Int?

  enum CodingKeys: String, CodingKey {
    case icCardFare = "odpt:icCardFare"
    case ticketFare = "odpt:ticketFare"
  }
}

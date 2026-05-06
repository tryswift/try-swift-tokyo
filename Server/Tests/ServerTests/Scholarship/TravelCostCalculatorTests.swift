import Testing

@testable import Server

@Suite("TravelCostCalculator")
struct TravelCostCalculatorTests {
  @Test("static lookup returns shinkansen + airplane + bus for Osaka")
  func osaka() {
    let estimate = TravelCostCalculator.estimate(from: "osaka")
    #expect(estimate?.bulletTrain == 27_000)
    #expect(estimate?.airplane == 20_000)
    #expect(estimate?.bus == 8_000)
    #expect(estimate?.train == nil)
  }

  @Test("Yokohama returns local-train fare only")
  func yokohama() {
    let estimate = TravelCostCalculator.estimate(from: "yokohama")
    #expect(estimate?.train == 1_200)
    #expect(estimate?.bulletTrain == nil)
    #expect(estimate?.airplane == nil)
  }

  @Test("Japanese name lookup also works")
  func japaneseName() {
    let estimate = TravelCostCalculator.estimate(from: "大阪")
    #expect(estimate?.city == "Osaka")
  }

  @Test("trims whitespace and lowercases the input")
  func normalisation() {
    let a = TravelCostCalculator.estimate(from: "  Osaka  ")
    let b = TravelCostCalculator.estimate(from: "OSAKA")
    #expect(a?.city == "Osaka")
    #expect(b?.city == "Osaka")
  }

  @Test("unknown cities return nil")
  func unknown() {
    #expect(TravelCostCalculator.estimate(from: "atlantis") == nil)
  }

  @Test("datalist HTML contains every English and Japanese city option")
  func datalist() {
    let html = TravelCostCalculator.datalistHTML
    #expect(html.contains("<datalist id=\"cityList\">"))
    #expect(html.contains("<option value=\"Osaka\">"))
    #expect(html.contains("<option value=\"大阪\">"))
    #expect(html.hasSuffix("</datalist>"))
  }

  @Test("allCities is sorted alphabetically by English name")
  func sortedCities() {
    let names = TravelCostCalculator.allCities.map(\.english)
    #expect(names == names.sorted())
  }
}

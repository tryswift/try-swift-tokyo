import Ignite

struct BoothMap: StaticPage {
  let title = "Booth Map"
  var path = "/booth-map"

  var body: some HTML {
    Section {
      Image("/images/booth-map.png", description: "Booth Map")
        .resizable()
        .frame(width: .percent(100%), height: .percent(100%))
        .style(.objectFit, "contain")
    }
    .ignorePageGutters()
    .frame(height: .vh(100%))
    .style(.display, "flex")
    .style(.alignItems, "flex-start")
    .style(.justifyContent, "center")
    .background(
      Gradient(
        colors: [.init(hex: "#BDA4C4"), .init(hex: "#B29AC2"), .init(hex: "#9881BF")],
        type: .linear(angle: 180))
    )
  }
}

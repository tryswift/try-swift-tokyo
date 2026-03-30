import Ignite

struct BoothMap: StaticPage {
  let title = "Booth Map"
  var path = "/booth-map"

  var body: some HTML {
    Image("/images/booth-map.png", description: "Booth Map")
      .resizable()
      .frame(maxWidth: .percent(100%))
  }
}

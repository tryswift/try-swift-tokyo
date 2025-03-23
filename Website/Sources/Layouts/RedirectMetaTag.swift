import Ignite

struct RedirectMetaTag: HeadElement, Sendable {
  let to: URL
  var body: some HTML { self }

  func render() -> String {
    """
    <meta http-equiv="refresh" content="0;url=\(to.absoluteString)">
    """
  }
}

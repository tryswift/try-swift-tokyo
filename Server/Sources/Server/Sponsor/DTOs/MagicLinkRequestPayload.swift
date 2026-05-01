import Vapor

struct MagicLinkRequestPayload: Content {
  let email: String
}

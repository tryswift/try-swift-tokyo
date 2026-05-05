import Vapor

struct OrganizerRejectPayload: Content {
  let reason: String
}

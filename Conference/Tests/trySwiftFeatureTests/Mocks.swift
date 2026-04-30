import Foundation
import SharedModels

extension Organizer {
  static let alice = Self(
    id: 1,
    name: "alice",
    imageName: "Alice",
    bio: "",
    links: [
      Link(
        name: "@alice",
        url: URL(string: "https://example.com/alice")!
      )
    ]
  )

  static let bob = Self(
    id: 2,
    name: "bob",
    imageName: "Bob",
    bio: "",
    links: [
      Link(
        name: "@bob",
        url: URL(string: "https://example.com/bob")!
      )
    ]
  )
}

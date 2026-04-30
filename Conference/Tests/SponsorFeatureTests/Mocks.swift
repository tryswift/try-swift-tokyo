import Foundation
import SharedModels

extension Sponsors {
  static let mock = Self(
    platinum: [.platinumMock],
    gold: [.goldMock],
    silver: [],
    bronze: [],
    diversity: [],
    student: [],
    community: [],
    individual: []
  )
}

extension Sponsor {
  static let platinumMock = Self(
    id: 1,
    name: "platinaum sponsor",
    imageName: "platinum_image",
    link: URL(string: "https://example.com/platinum")!
  )

  static let goldMock = Self(
    id: 2,
    name: "gold sponsor",
    imageName: "gold_image",
    link: URL(string: "https://example.com/gold")!
  )
}

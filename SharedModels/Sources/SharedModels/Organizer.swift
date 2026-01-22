import Foundation

public struct Organizer: Codable, Equatable, Hashable, Sendable, Identifiable {
  public var id: Int
  public var name: String
  public var imageName: String
  public var bio: String
  public var links: [Link]?

  public struct Link: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var url: URL

    public init(name: String, url: URL) {
      self.name = name
      self.url = url
    }
  }

  public init(id: Int, name: String, imageName: String, bio: String, links: [Link]? = nil) {
    self.id = id
    self.name = name
    self.imageName = imageName
    self.bio = bio
    self.links = links
  }
}

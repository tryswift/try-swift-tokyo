import Foundation
import IdentifiedCollections
import MapKit
import SwiftUI

enum Lines: Equatable, Identifiable, CaseIterable {
  var id: Self { self }

  case tachikawa
  case haneda
  case tokyo

  var localizedKey: LocalizedStringKey {
    switch self {
    case .tachikawa:
      return "Tachikawa St."
    case .haneda:
      return "Haneda Airport"
    case .tokyo:
      return "Tokyo St."
    }
  }

  var region: MKCoordinateRegion {
    switch self {
    case .tachikawa:
      return .init(
        center: .init(latitude: 35.657892, longitude: 139.703748),
        span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
    case .haneda:
      return .init(
        center: .init(latitude: 35.658575, longitude: 139.701499),
        span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
    case .tokyo:
      return .init(
        center: .init(latitude: 35.665222, longitude: 139.712543),
        span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
  }

  var searchQuery: String {
    switch self {
    case .tachikawa:
      return "JR 立川駅"
    case .haneda:
      return "羽田空港"
    case .tokyo:
      return "東京駅"
    }
  }

  var exitName: LocalizedStringKey {
    switch self {
    case .tachikawa:
      return "North Exit"
    case .haneda:
      return "Arrival Erea"
    case .tokyo:
      return "Chuo line"
    }
  }

  var originTitle: LocalizedStringKey {
    switch self {
    case .tachikawa:
      return "Tachikawa Station"
    case .haneda:
      return "Haneda Airport"
    case .tokyo:
      return "Tokyo Station"
    }
  }

  var itemColor: Color {
    switch self {
    case .tachikawa:
      return Color.red
    case .haneda:
      return Color.green
    case .tokyo:
      return Color.purple
    }
  }

  var directions: IdentifiedArrayOf<Direction> {
    switch self {
    case .tachikawa:
      return [
        .init(order: 1, description: "tachikawa-1", imageName: "")
      ]
    case .haneda:
      return [
        .init(order: 1, description: "haneda-1", imageName: "")
      ]
    case .tokyo:
      return [
        .init(order: 1, description: "tokyo-1", imageName: "")
      ]
    }
  }

  var duration: Duration {
    switch self {
    case .tachikawa:
      return .seconds(11 * 60)
    case .haneda:
      return .seconds(140 * 60)
    case .tokyo:
      return .seconds(42 * 60)
    }
  }

  struct Direction: Equatable, Identifiable {
    var id: UUID { .init() }
    var order: Int
    var description: LocalizedStringKey
    var imageName: String
  }
}

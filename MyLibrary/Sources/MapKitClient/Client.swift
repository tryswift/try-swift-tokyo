import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation
import MapKit
import SharedModels

@DependencyClient
public struct MapKitClient: Sendable {
  public var mapRoute: @Sendable (MKMapItem, MKMapItem) async throws -> MKRoute?
  public var lookAround: @Sendable (MKMapItem) async throws -> MKLookAroundScene?
  public var reverseGeocodeLocation: @Sendable (CLLocationCoordinate2D) async throws -> [MKPlacemark]
  public var localSearch: @Sendable (String, MKCoordinateRegion) async throws -> [MKMapItem]
}

extension MapKitClient: DependencyKey {
  public static let liveValue: Self = .init(
    mapRoute: { starting, ending in
      let directionsRequest = MKDirections.Request()
      directionsRequest.source = starting
      directionsRequest.destination = ending
      directionsRequest.transportType = [.transit, .walking]

      let directionsService = MKDirections(request: directionsRequest)
      let response = try await directionsService.calculate()
      let route = response.routes.first
      return route
    },
    lookAround: { mapItem in
      let sceneRequest = MKLookAroundSceneRequest(mapItem: mapItem)
      return try await sceneRequest.scene
    },
    reverseGeocodeLocation: { location in
      let geoCoder = CLGeocoder()
      return try await geoCoder.reverseGeocodeLocation(
        .init(latitude: location.latitude, longitude: location.longitude)
      )
      .map(MKPlacemark.init(placemark:))
    },
    localSearch: { naturalLanguageQuery, region in
      let request = MKLocalSearch.Request()
      request.region = region
      request.naturalLanguageQuery = naturalLanguageQuery
      request.resultTypes = .pointOfInterest
      return try await MKLocalSearch(request: request).start().mapItems
    }
  )
}

import CoreLocation
import Foundation
import MapKit

extension MKPolyline {
  var coords: [CLLocationCoordinate2D] {
    var coords = [CLLocationCoordinate2D](
      repeating: kCLLocationCoordinate2DInvalid,
      count: pointCount
    )
    getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
    return coords
  }
}

import ComposableArchitecture
import CoreLocation
import DependencyExtra
import Foundation
@preconcurrency import MapKit
import MapKitClient
import SwiftUI
import WebKit
import os

private let logger = Logger(subsystem: "jp.tryswift.tokyo.App", category: "Guidance")

enum VenueTab: Equatable, Hashable, Sendable {
  case access
  case boothGuide
}

@Reducer
public struct Guidance: Sendable {

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    var selectedTab: VenueTab = .access
    var lines: Lines = .tachikawa
    var boothGuideURL: URL = URL(string: "https://tryswift.jp/booth-map/")!
    var route: MKRoute?
    var origin: MKMapItem?
    var originTitle: LocalizedStringKey { lines.originTitle }
    var destinationItem: MKMapItem?
    @ObservationStateIgnored var cameraPosition: MapCameraPosition = .automatic
    var isLookAroundPresented: Bool = false
    var lookAround: MKLookAroundScene?

    var routeOrigin: CLLocationCoordinate2D? {
      guard let route = route else { return nil }
      let pointCount = route.polyline.pointCount
      var coords = [CLLocationCoordinate2D](
        repeating: kCLLocationCoordinate2DInvalid,
        count: pointCount
      )
      route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
      return coords.first
    }
    public init() {}
  }

  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case view(View)
    case initialResponse(Result<(MKMapItem, MKMapItem, MKRoute, MKLookAroundScene?)?, Error>)
    case updateResponse(Result<(MKMapItem, MKRoute, MKLookAroundScene?)?, Error>)

    public enum View {
      case onAppear
      case openMapTapped
    }
  }

  @Dependency(MapKitClient.self) var mapKitClient
  @Dependency(\.safari) var safari

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        return .run { [state] send in
          await send(
            .initialResponse(
              Result {
                try await onAppear(lines: state.lines)
              }
            )
          )
        }
      case .initialResponse(.success(let response)):
        guard let response = response else { return .none }
        let route = response.2

        state.origin = response.0
        state.destinationItem = response.1
        state.route = route
        state.lookAround = response.3
        //TODO: Calculate distance from 2 CLLocation
        state.cameraPosition = .camera(
          .init(centerCoordinate: route.polyline.coordinate, distance: route.distance * 2))
        return .none

      case .initialResponse(.failure(let error)):
        logger.error("Initial response failed: \(error)")
        return .none

      case .updateResponse(.success(let response)):
        guard let response = response else { return .none }
        let route = response.1
        state.origin = response.0
        state.route = route
        state.lookAround = response.2
        //TODO: Calculate distance from 2 CLLocation
        state.cameraPosition = .camera(
          .init(centerCoordinate: route.polyline.coordinate, distance: route.distance * 2))
        return .none

      case .updateResponse(.failure(let error)):
        logger.error("Update response failed: \(error)")
        return .none

      case .binding(\.lines):
        guard let destination = state.destinationItem else { return .none }
        return .run { [state] send in
          await send(
            .updateResponse(
              Result {
                try await update(with: state.lines, destination: destination)
              }
            )
          )
        }

      case .view(.openMapTapped):
        return .run { [state] _ in
          state.destinationItem?.openInMaps()
        }
      case .binding:
        return .none
      }
    }
  }

  func onAppear(lines: Lines) async throws -> (MKMapItem, MKMapItem, MKRoute, MKLookAroundScene?)? {
    let items = try await withThrowingTaskGroup(
      of: (Int, MKMapItem?).self, returning: (MKMapItem?, MKMapItem?).self
    ) { group in
      group.addTask {
        (0, try await mapKitClient.localSearch(lines.searchQuery, lines.region).first)
      }
      group.addTask {
        (1, try await mapKitClient.localSearch("立川ステージガーデン", hallLocation).first)
      }
      var result: [Int: MKMapItem?] = [:]
      for try await (index, element) in group {
        result[index] = element
      }
      return (result[0]!, result[1]!)
    }
    guard let origin = items.0, let destination = items.1 else { return nil }
    guard let route = try await mapKitClient.mapRoute(origin, destination) else { return nil }
    let polylineOrigin = route.polyline.coords.first!
    guard
      let geoLocation = try await mapKitClient.reverseGeocodeLocation(
        .init(latitude: polylineOrigin.latitude, longitude: polylineOrigin.longitude)
      ).first
    else {
      return nil
    }
    guard let lookAroundScene = try await mapKitClient.lookAround(geoLocation)
    else {
      return (origin, destination, route, nil)
    }
    return (origin, destination, route, lookAroundScene)
  }

  func update(with lines: Lines, destination: MKMapItem) async throws -> (
    MKMapItem, MKRoute, MKLookAroundScene?
  )? {
    let origin = try await mapKitClient.localSearch(lines.searchQuery, lines.region).first
    guard let origin = origin else { return nil }
    guard let route = try await mapKitClient.mapRoute(origin, destination) else {
      logger.error("Route not found: \(origin) to \(destination)")
      return nil
    }
    let polylineOrigin = route.polyline.coords.first!
    guard
      let geoLocation = try await mapKitClient.reverseGeocodeLocation(
        .init(latitude: polylineOrigin.latitude, longitude: polylineOrigin.longitude)
      ).first
    else {
      logger.error(
        "[Error] Reverse Geocode failed (\(polylineOrigin.latitude), \(polylineOrigin.longitude))")
      return nil
    }
    guard let lookAroundScene = try await mapKitClient.lookAround(geoLocation)
    else {
      logger.warning("Look around scene not found: \(geoLocation)")
      return (origin, route, nil)
    }
    return (origin, route, lookAroundScene)
  }
}

@ViewAction(for: Guidance.self)
public struct GuidanceView: View {

  @Bindable public var store: StoreOf<Guidance>

  public init(store: StoreOf<Guidance>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      Group {
        switch store.selectedTab {
        case .access: accessContent
        case .boothGuide: boothGuideContent
        }
      }
      .animation(.default, value: store.selectedTab)
      .navigationTitle(Text("Tachikawa Stage Garden", bundle: .module))
      #if os(macOS) || os(visionOS)
        .toolbar {
          ToolbarItem(placement: .principal) {
            sectionPicker
            .frame(width: 240)
          }
        }
      #else
        .safeAreaInset(edge: .top) {
          sectionPicker
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
          .background(.ultraThinMaterial)
        }
        .toolbar {
          ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
              Text("Tachikawa Stage Garden", bundle: .module)
              .font(.headline)
              Text("Tachikawa Stage Garden address", bundle: .module)
              .font(.caption2)
              .foregroundStyle(.secondary)
            }
          }
        }
        .toolbarTitleDisplayMode(.inline)
      #endif
    }
    #if os(iOS) || os(visionOS)
      .lookAroundViewer(isPresented: $store.isLookAroundPresented, scene: $store.lookAround)
    #endif
    .onAppear {
      send(.onAppear)
    }
  }

  @ViewBuilder
  var sectionPicker: some View {
    Picker("Lines", selection: $store.selectedTab) {
      Text("Access", bundle: .module).tag(VenueTab.access)
      Text("Booth Guide", bundle: .module).tag(VenueTab.boothGuide)
    }
    .pickerStyle(.segmented)
    .labelsHidden()
  }

  @ViewBuilder
  var accessContent: some View {
    #if os(macOS) || os(visionOS)
      HStack(spacing: 0) {
        map
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Tachikawa Stage Garden", bundle: .module)
                .font(.headline)
              Text("Tachikawa Stage Garden address", bundle: .module)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 12))
            .padding(12)
          }
          .frame(maxHeight: .infinity)
          .padding(.leading)
          .padding(.vertical, 8)

        ScrollView {
          routeCards
            .padding(.vertical)

          openMapButton

          directions
        }
        .frame(width: 320)
      }
    #else
      ScrollView {
        map
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .padding(.horizontal)
          .padding(.top, 8)

        routeCards
          .padding(.vertical)

        openMapButton

        directions
      }
    #endif
  }

  @ViewBuilder
  var openMapButton: some View {
    Button {
      send(.openMapTapped)
    } label: {
      Label {
        Text("Open Map", bundle: .module)
      } icon: {
        Image(systemName: "map")
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
    .glassProminentIfAvailable()
    .buttonBorderShape(.capsule)
  }

  @ViewBuilder
  var routeCards: some View {
    HStack(spacing: 12) {
      ForEach(Lines.allCases) { line in
        routeCard(for: line)
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  func routeCard(for line: Lines) -> some View {
    let isSelected = store.lines == line
    Button {
      $store.lines.wrappedValue = line
    } label: {
      VStack(spacing: 6) {
        Image(systemName: line.systemImage)
          .font(.title2)
        Text(line.localizedKey, bundle: .module)
          .font(.subheadline.bold())
          .lineLimit(1)
          .minimumScaleFactor(0.5)
        Text(line.formattedDuration)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 90)
    }
    .buttonStyle(.plain)
    .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
    .overlay {
      if isSelected {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(Color.accentColor, lineWidth: 2)
      }
    }
  }

  @ViewBuilder
  var boothGuideContent: some View {
    WebView(url: store.boothGuideURL)
  }

  @ViewBuilder
  var map: some View {
    ZStack(alignment: .bottomLeading) {
      Map(position: $store.cameraPosition) {
        if let item = store.origin {
          Marker(item: item)
            .tint(store.lines.itemColor)
        }
        if let route = store.route {
          if let origin = store.routeOrigin {
            Marker(store.lines.exitName, coordinate: origin)
          }
          MapPolyline(route.polyline)
            .stroke(Color.accentColor, style: .init(lineWidth: 8))
        }
        if let item = store.destinationItem {
          Marker(item: item)
            .tint(.blue)
        }
      }
      .mapStyle(
        .standard(
          elevation: .realistic, emphasis: .automatic,
          pointsOfInterest: .including([.publicTransport]), showsTraffic: false)
      )
      .mapControlVisibility(.automatic)
      #if os(macOS) || os(visionOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      #else
        .frame(height: 240)
      #endif

      if store.lookAround != nil {
        LookAroundPreview(scene: $store.lookAround)
          .frame(width: 120, height: 80, alignment: .bottomLeading)
          .glassEffectIfAvailable(.clear, in: .rect(cornerRadius: 12))
          .padding()
      }
    }
  }

  @ViewBuilder
  var directions: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Directions", bundle: .module)
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
        .padding(.horizontal)
      ForEach(store.lines.directions) { direction in
        VStack {
          Text(direction.description, bundle: .module)
            .frame(maxWidth: .infinity, alignment: .leading)
          if let imageName = direction.imageName {
            Image(imageName, bundle: .module)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: 400)
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
        .padding()
        .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
      }
    }
    .padding()
    .glassEffectContainerIfAvailable()
  }
}

var hallLocation: MKCoordinateRegion {
  .init(
    center: .init(latitude: 35.704748, longitude: 139.411955),
    span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
}

#Preview {
  GuidanceView(
    store: .init(initialState: .init()) {
      Guidance()
    })
}

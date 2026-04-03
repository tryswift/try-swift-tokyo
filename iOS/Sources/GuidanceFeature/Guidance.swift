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
  case floorGuide
}

@Reducer
public struct Guidance: Sendable {

  public struct LineRouteData: Equatable, @unchecked Sendable {
    var origin: MKMapItem
    var route: MKRoute
    var lookAround: MKLookAroundScene?
  }

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    var selectedTab: VenueTab = .access
    var lines: Lines = .tachikawa
    var floorGuideURL: URL = URL(string: "https://tryswift.jp/booth-map/")!
    var route: MKRoute?
    var origin: MKMapItem?
    var originTitle: LocalizedStringKey { lines.originTitle }
    var destinationItem: MKMapItem?
    @ObservationStateIgnored var cameraPosition: MapCameraPosition = .automatic
    var isLookAroundPresented: Bool = false
    var lookAround: MKLookAroundScene?
    @ObservationStateIgnored var cachedLineData: [Lines: LineRouteData] = [:]

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
    case initialResponse(Result<(MKMapItem, [Lines: LineRouteData])?, Error>)

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
        guard state.cachedLineData.isEmpty else { return .none }
        return .run { send in
          await send(
            .initialResponse(
              Result {
                try await fetchAllRoutes()
              }
            )
          )
        }
      case .initialResponse(.success(let response)):
        guard let (destination, lineData) = response else { return .none }
        state.destinationItem = destination
        state.cachedLineData = lineData
        if let data = lineData[state.lines] {
          state.origin = data.origin
          state.route = data.route
          state.lookAround = data.lookAround
          state.cameraPosition = .camera(
            .init(
              centerCoordinate: data.route.polyline.coordinate,
              distance: data.route.distance * 2))
        }
        return .none

      case .initialResponse(.failure(let error)):
        logger.error("Initial response failed: \(error)")
        return .none

      case .binding(\.lines):
        guard let data = state.cachedLineData[state.lines] else {
          state.origin = nil
          state.route = nil
          state.lookAround = nil
          return .none
        }
        state.origin = data.origin
        state.route = data.route
        state.lookAround = data.lookAround
        state.cameraPosition = .camera(
          .init(
            centerCoordinate: data.route.polyline.coordinate,
            distance: data.route.distance * 2))
        return .none

      case .view(.openMapTapped):
        return .run { [state] _ in
          state.destinationItem?.openInMaps()
        }
      case .binding:
        return .none
      }
    }
  }

  func fetchAllRoutes() async throws -> (MKMapItem, [Lines: LineRouteData])? {
    guard
      let destination = try await mapKitClient.localSearch("立川ステージガーデン", hallLocation)
        .first
    else { return nil }

    let lineData = await withTaskGroup(
      of: (Lines, LineRouteData?).self,
      returning: [Lines: LineRouteData].self
    ) { group in
      for line in Lines.allCases {
        group.addTask {
          do {
            return (line, try await self.fetchLineData(line: line, destination: destination))
          } catch {
            logger.error("Failed to fetch route for \(String(describing: line)): \(error)")
            return (line, nil)
          }
        }
      }
      var result: [Lines: LineRouteData] = [:]
      for await (line, data) in group {
        if let data { result[line] = data }
      }
      return result
    }

    return (destination, lineData)
  }

  func fetchLineData(line: Lines, destination: MKMapItem) async throws -> LineRouteData? {
    guard let origin = try await mapKitClient.localSearch(line.searchQuery, line.region).first
    else { return nil }
    guard let route = try await mapKitClient.mapRoute(origin, destination, line.transportType)
    else { return nil }
    guard let polylineOrigin = route.polyline.coords.first,
      let geoLocation = try await mapKitClient.reverseGeocodeLocation(
        .init(latitude: polylineOrigin.latitude, longitude: polylineOrigin.longitude)
      ).first
    else {
      return LineRouteData(origin: origin, route: route, lookAround: nil)
    }
    let lookAround = try? await mapKitClient.lookAround(geoLocation)
    return LineRouteData(origin: origin, route: route, lookAround: lookAround)
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
        case .floorGuide: WebView(url: store.floorGuideURL)
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
    Picker("Section", selection: $store.selectedTab) {
      Text("Access", bundle: .module).tag(VenueTab.access)
      Text("Floor Guide", bundle: .module).tag(VenueTab.floorGuide)
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

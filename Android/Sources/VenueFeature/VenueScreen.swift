import SwiftUI

public enum TransportOption: String, CaseIterable, Identifiable {
  case tachikawa = "Tachikawa Station"
  case haneda = "Haneda Airport"
  case tokyo = "Tokyo Station"

  public var id: String { rawValue }

  var duration: String {
    switch self {
    case .tachikawa: return "11 min"
    case .haneda: return "2h 20min"
    case .tokyo: return "42 min"
    }
  }

  var directions: [String] {
    switch self {
    case .tachikawa:
      return [
        "Exit from the North Exit of JR Tachikawa Station",
        "Walk straight towards Tachikawa Stage Garden",
        "The venue is about 10 minutes walk from the station",
      ]
    case .haneda:
      return [
        "Take the Tokyo Monorail to Hamamatsucho Station",
        "Transfer to JR Yamanote Line to Tokyo Station",
        "Take JR Chuo Line to Tachikawa Station",
        "Walk from Tachikawa Station North Exit",
      ]
    case .tokyo:
      return [
        "Take the JR Chuo Line (Rapid) from Tokyo Station",
        "Get off at Tachikawa Station",
        "Exit from the North Exit",
        "Walk to Tachikawa Stage Garden",
      ]
    }
  }

  var lineColor: Color {
    switch self {
    case .tachikawa: return Color.red
    case .haneda: return Color.green
    case .tokyo: return Color.purple
    }
  }
}

public struct VenueScreen: View {
  @State private var selectedOption: TransportOption = .tachikawa

  public init() {}

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          transportPicker

          venueMapPlaceholder

          openInMapsButton

          directionsSection

          venueInfoSection
        }
        .padding()
      }
      .navigationTitle("Venue")
    }
  }

  private var transportPicker: some View {
    Picker("From", selection: $selectedOption) {
      ForEach(TransportOption.allCases) { option in
        Text(option.rawValue).tag(option as TransportOption)
      }
    }
    .pickerStyle(.segmented)
  }

  private var venueMapPlaceholder: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.2))
        .aspectRatio(1.6, contentMode: ContentMode.fit)

      VStack(spacing: 8) {
        Image(systemName: "map")
          .font(Font.largeTitle)
          .foregroundStyle(Color.secondary)

        Text("Tachikawa Stage Garden")
          .font(Font.headline)

        Text("〒190-0014 Tokyo, Tachikawa, Midoricho, 3 Chome−3−20")
          .font(Font.caption)
          .foregroundStyle(Color.secondary)
          .multilineTextAlignment(TextAlignment.center)
          .padding(Edge.Set.horizontal)
      }
    }
  }

  private var openInMapsButton: some View {
    Button {
      openInMaps()
    } label: {
      Label("Open in Maps", systemImage: "map")
    }
    .buttonStyle(.borderedProminent)
  }

  private var directionsSection: some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
      HStack {
        Text("Directions from \(selectedOption.rawValue)")
          .font(Font.headline)

        Spacer()

        Text(selectedOption.duration)
          .font(Font.subheadline)
          .foregroundStyle(Color.secondary)
      }

      ForEach(Array(selectedOption.directions.enumerated()), id: \.offset) { (index: Int, direction: String) in
        HStack(alignment: VerticalAlignment.top, spacing: 12) {
          Circle()
            .fill(selectedOption.lineColor)
            .frame(width: 24, height: 24)
            .overlay {
              Text("\(index + 1)")
                .font(Font.caption.bold())
                .foregroundStyle(Color.white)
            }

          Text(direction)
            .font(Font.body)
        }
        .padding(Edge.Set.vertical, 4)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var venueInfoSection: some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      Text("Tachikawa Stage Garden")
        .font(Font.title2.bold())

      Text("3-3-20 Midoricho, Tachikawa City, Tokyo 190-0014")
        .font(Font.body)
        .foregroundStyle(Color.secondary)

      Link(destination: URL(string: "https://www.tachikawasg.com")!) {
        Label("Visit Website", systemImage: "globe")
      }
      .padding(Edge.Set.top, 4)
    }
    .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
    .padding()
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private func openInMaps() {
    // Coordinates for Tachikawa Stage Garden
    let latitude = 35.704748
    let longitude = 139.411955

    // Create a Google Maps URL for Android
    let googleMapsURL = URL(
      string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")!

    #if os(iOS)
      // On iOS, we could use Apple Maps
      // Skip will handle this for Android using Google Maps
    #endif

    // For now, just print - Skip will handle platform-specific behavior
    print("Opening maps at: \(latitude), \(longitude)")
  }
}

#if !SKIP
#Preview {
  VenueScreen()
}
#endif

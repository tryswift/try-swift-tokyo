import SharedModels
import SharedViews
import SwiftUI

/// Sponsors screen for Android.
/// Uses shared SponsorGridView component - identical SwiftUI code on both platforms.
public struct SponsorsScreen: View {
  @State private var viewModel = SponsorsViewModel()
  @Environment(\.openURL) private var openURL

  public init() {}

  public var body: some View {
    NavigationStack {
      content
        .navigationTitle("Sponsors")
    }
    .onAppear {
      viewModel.loadSponsors()
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading {
      ProgressView()
    } else if let error = viewModel.errorMessage {
      Text(error)
        .foregroundStyle(.red)
        .padding()
    } else if let sponsors = viewModel.sponsors {
      // Uses shared SponsorGridView - identical code on iOS and Android
      SponsorGridView(sponsors: sponsors) { sponsor in
        if let url = sponsor.link {
          openURL(url)
        }
      }
    } else {
      ContentUnavailableView(
        "No Sponsors",
        systemImage: "building.2",
        description: Text("Sponsor information is not available")
      )
    }
  }
}

#Preview {
  SponsorsScreen()
}

import SharedModels
import SwiftUI

/// Sponsors screen for Android.
public struct SponsorsScreen: View {
  @State private var viewModel = SponsorsViewModel()
  @Environment(\.openURL) private var openURL

  public init() {}

  public var body: some View {
    NavigationStack {
      content
        .navigationTitle("Sponsors")
        .background(Color(red: 0.98, green: 0.97, blue: 0.96))
    }
    .onAppear {
      viewModel.loadSponsors()
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let error = viewModel.errorMessage {
      Text(error)
        .foregroundStyle(Color.red)
        .padding()
    } else if let sponsors = viewModel.sponsors {
      SponsorGridView(sponsors: sponsors) { sponsor in
        if let url = sponsor.link {
          openURL(url)
        }
      }
    } else {
      VStack(spacing: 16) {
        Image(systemName: "star.fill")
          .font(Font.system(size: 48))
          .foregroundStyle(Color.secondary)
        Text("No Sponsors")
          .font(Font.headline)
        Text("Sponsor information is not available")
          .font(Font.subheadline)
          .foregroundStyle(Color.secondary)
      }
      .padding()
    }
  }
}

#if !SKIP
  #Preview {
    SponsorsScreen()
  }
#endif

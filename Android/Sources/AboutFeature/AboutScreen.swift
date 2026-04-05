import SharedModels
import SwiftUI

public struct AboutScreen: View {
  @State private var viewModel = AboutViewModel()
  @Environment(\.openURL) private var openURL

  public init() {}

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          heroSection
          linkGroups
          organizersSection
        }
        .padding()
      }
      .background(Color(red: 0.98, green: 0.97, blue: 0.96))
      .navigationTitle("try! Swift")
      .sheet(item: $viewModel.selectedOrganizer) { organizer in
        OrganizerDetailSheet(organizer: organizer)
      }
    }
    .onAppear {
      viewModel.loadOrganizers()
    }
  }

  private var heroSection: some View {
    VStack(spacing: 16) {
      ZStack {
        RoundedRectangle(cornerRadius: 28)
          .fill(
            LinearGradient(
              colors: [
                Color(red: 1.0, green: 0.44, blue: 0.22),
                Color(red: 0.98, green: 0.69, blue: 0.23),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(height: 180)

        VStack(spacing: 12) {
          Text("try! Swift")
            .font(Font.largeTitle.bold())
            .foregroundStyle(Color.white)
          Text("TOKYO 2026")
            .font(Font.title3.bold())
            .tracking(2)
            .foregroundStyle(Color.white.opacity(0.95))
        }
      }

      Text(
        "try! Swift Tokyo is an international community gathering about the latest advancements in Swift Development. The event takes place in Tokyo, Japan."
      )
      .font(Font.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(Color.secondary)
    }
    .padding()
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }

  private var linkGroups: some View {
    VStack(spacing: 12) {
      aboutLinkRow(
        title: "Code of Conduct",
        systemImage: "info.circle",
        urlString: "https://tryswift.jp/code-of-conduct"
      )
      aboutLinkRow(
        title: "Privacy Policy",
        systemImage: "lock",
        urlString: "https://tryswift.jp/privacy"
      )
      aboutLinkRow(
        title: "Get Tickets (Luma)",
        systemImage: "cart.fill",
        urlString: "https://lu.ma/tryswifttokyo2026"
      )
      aboutLinkRow(
        title: "Visit Website",
        systemImage: "arrow.forward.square",
        urlString: "https://tryswift.jp"
      )
    }
  }

  private var organizersSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Organizers")
        .font(Font.title2.bold())

      if viewModel.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
      } else if !viewModel.organizers.isEmpty {
        LazyVStack(spacing: 12) {
          ForEach(viewModel.organizers) { organizer in
            Button {
              viewModel.selectedOrganizer = organizer
            } label: {
              organizerRow(organizer: organizer)
            }
            .buttonStyle(.plain)
          }
        }
      } else if let error = viewModel.errorMessage {
        Text(error)
          .font(Font.subheadline)
          .foregroundStyle(Color.red)
      } else {
        Text("Organizer information is not available")
          .font(Font.subheadline)
          .foregroundStyle(Color.secondary)
      }
    }
  }

  private func aboutLinkRow(
    title: String,
    systemImage: String,
    urlString: String
  ) -> some View {
    Button {
      if let url = URL(string: urlString) {
        openURL(url)
      }
    } label: {
      HStack(spacing: 14) {
        Image(systemName: systemImage)
          .font(Font.headline)
          .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.20))
          .frame(width: 28)

        Text(title)
          .font(Font.body.weight(.semibold))
          .foregroundStyle(Color.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(Font.subheadline.weight(.semibold))
          .foregroundStyle(Color.secondary)
      }
      .padding()
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    .buttonStyle(.plain)
  }

  private func organizerRow(organizer: Organizer) -> some View {
    HStack(spacing: 14) {
      AvatarBadge(name: organizer.name, diameter: 54)

      VStack(alignment: .leading, spacing: 4) {
        Text(organizer.name)
          .font(Font.body.weight(.semibold))
          .foregroundStyle(Color.primary)
        Text(organizer.bio)
          .font(Font.caption)
          .foregroundStyle(Color.secondary)
          .lineLimit(2)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(Font.subheadline.weight(.semibold))
        .foregroundStyle(Color.secondary)
    }
    .padding()
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}

struct OrganizerDetailSheet: View {
  let organizer: Organizer
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          AvatarBadge(name: organizer.name, diameter: 120)

          Text(organizer.name)
            .font(Font.title.bold())

          Text(organizer.bio)
            .font(Font.body)
            .multilineTextAlignment(TextAlignment.center)
            .foregroundStyle(Color.secondary)
            .padding(.horizontal)

          if let links = organizer.links, !links.isEmpty {
            VStack(spacing: 12) {
              Text("Links")
                .font(Font.headline)

              ForEach(links, id: \.url) { link in
                Button {
                  openURL(link.url)
                } label: {
                  Label(link.name, systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
              }
            }
            .padding(.top)
          }
        }
        .padding()
      }
      .background(Color(red: 0.98, green: 0.97, blue: 0.96))
      .navigationTitle("Profile")
      #if os(iOS) || SKIP
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        .toolbar {
          ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
      #else
        .toolbar {
          ToolbarItem(placement: ToolbarItemPlacement.automatic) {
            Button("Done") {
              dismiss()
            }
          }
        }
      #endif
    }
  }
}

private struct AvatarBadge: View {
  let name: String
  let diameter: CGFloat

  var body: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [
            Color(red: 1.0, green: 0.61, blue: 0.35),
            Color(red: 0.92, green: 0.33, blue: 0.34),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: diameter, height: diameter)
      .overlay {
        Text(String(name.prefix(1)))
          .font(diameter > 80 ? Font.largeTitle.bold() : Font.title3.bold())
          .foregroundStyle(Color.white)
      }
  }
}

#if !SKIP
  #Preview {
    AboutScreen()
  }
#endif

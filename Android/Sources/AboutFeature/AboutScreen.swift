import SharedModels
import SwiftUI

public struct AboutScreen: View {
  @State private var viewModel = AboutViewModel()
  @State private var showOrganizers = false
  @State private var selectedOrganizer: Organizer?
  @Environment(\.openURL) private var openURL

  public init() {}

  public var body: some View {
    NavigationStack {
      List {
        logoSection

        descriptionSection

        linksSection

        organizersSection

        externalLinksSection
      }
      .navigationTitle("try! Swift")
      .sheet(item: $selectedOrganizer) { organizer in
        OrganizerDetailSheet(organizer: organizer)
      }
    }
    .onAppear {
      viewModel.loadOrganizers()
    }
  }

  private var logoSection: some View {
    Section {
      HStack {
        Spacer()
        // Placeholder for try! Swift logo
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.orange.opacity(0.2))
          .frame(width: 200, height: 100)
          .overlay {
            Text("try! Swift Tokyo")
              .font(.title2.bold())
              .foregroundStyle(.orange)
          }
        Spacer()
      }
      .listRowBackground(Color.clear)
    }
  }

  private var descriptionSection: some View {
    Section {
      Text(
        "try! Swift Tokyo is an international community gathering about the latest advancements in Swift Development. The event takes place in Tokyo, Japan."
      )
      .font(.body)
    }
  }

  private var linksSection: some View {
    Section {
      Button {
        openURL(URL(string: "https://tryswift.jp/code-of-conduct")!)
      } label: {
        Label("Code of Conduct", systemImage: "doc.text")
      }

      Button {
        openURL(URL(string: "https://tryswift.jp/privacy")!)
      } label: {
        Label("Privacy Policy", systemImage: "hand.raised")
      }
    }
  }

  private var organizersSection: some View {
    Section("Organizers") {
      if viewModel.isLoading {
        ProgressView()
      } else if !viewModel.organizers.isEmpty {
        ForEach(viewModel.organizers) { organizer in
          Button {
            selectedOrganizer = organizer
          } label: {
            HStack {
              Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                  Text(String(organizer.name.prefix(1)))
                    .foregroundStyle(.blue)
                }

              Text(organizer.name)
                .foregroundStyle(.primary)

              Spacer()

              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  private var externalLinksSection: some View {
    Section {
      Button {
        openURL(URL(string: "https://lu.ma/tryswifttokyo2026")!)
      } label: {
        Label("Get Tickets (Luma)", systemImage: "ticket")
      }

      Button {
        openURL(URL(string: "https://tryswift.jp")!)
      } label: {
        Label("Visit Website", systemImage: "globe")
      }
    }
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
          // Profile image placeholder
          Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 120, height: 120)
            .overlay {
              Text(String(organizer.name.prefix(1)))
                .font(.largeTitle)
                .foregroundStyle(.blue)
            }

          Text(organizer.name)
            .font(.title.bold())

          Text(organizer.bio)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

          if let links = organizer.links, !links.isEmpty {
            VStack(spacing: 12) {
              Text("Links")
                .font(.headline)

              ForEach(links, id: \.url) { link in
                Button {
                  openURL(link.url)
                } label: {
                  Label(link.name, systemImage: "link")
                }
                .buttonStyle(.bordered)
              }
            }
            .padding(.top)
          }
        }
        .padding()
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  AboutScreen()
}

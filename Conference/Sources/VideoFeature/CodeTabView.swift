import DependencyExtra
import SharedModels
import SwiftUI

struct CodeTabView: View {
  let codeResources: [CodeResource]
  var onResourceTapped: (URL) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Code")
          .font(.headline)
          .foregroundStyle(.secondary)

        if codeResources.isEmpty {
          ContentUnavailableView(
            "No Code Resources",
            systemImage: "curlybraces",
            description: Text("No code samples are available for this talk.")
          )
        } else {
          ForEach(codeResources, id: \.self) { resource in
            Button {
              onResourceTapped(resource.url)
            } label: {
              HStack(spacing: 12) {
                Image(systemName: iconName(for: resource.kind))
                  .font(.title3)
                  .foregroundStyle(Color.accentColor)
                  .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                  Text(resource.title)
                    .font(.headline)
                  Text(resource.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding()
              .glassEffectIfAvailable()
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func iconName(for kind: CodeResource.Kind?) -> String {
    switch kind {
    case .github: "chevron.left.forwardslash.chevron.right"
    case .gist: "doc.text"
    case .playground: "swift"
    case .other, .none: "link"
    }
  }
}

import SharedModels
import SwiftUI

struct SummaryTabView: View {
  let summary: String

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Summary")
          .font(.headline)
          .foregroundStyle(.secondary)

        Text(summary)
          .font(.body)
      }
      .padding(.horizontal)
      .padding(.bottom)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

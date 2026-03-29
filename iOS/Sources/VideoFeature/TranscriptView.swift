import SharedModels
import SwiftUI

struct TranscriptView: View {
  let transcript: [TranscriptEntry]
  let activeEntryId: Int?
  var onEntryTapped: (TranscriptEntry) -> Void

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(transcript) { entry in
            Button {
              onEntryTapped(entry)
            } label: {
              transcriptRow(entry: entry)
            }
            .buttonStyle(.plain)
            .id(entry.id)
          }
        }
        .padding(.horizontal)
        .padding(.bottom)
      }
      .onChange(of: activeEntryId) { _, newValue in
        if let id = newValue {
          withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(id, anchor: .center)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func transcriptRow(entry: TranscriptEntry) -> some View {
    let isActive = entry.id == activeEntryId

    HStack(alignment: .top, spacing: 12) {
      Text(formattedTime(entry.startTime))
        .font(.caption.monospaced())
        .foregroundStyle(isActive ? Color.accentColor : .secondary)
        .frame(width: 50, alignment: .leading)

      Text(entry.text)
        .font(.subheadline)
        .foregroundStyle(isActive ? .primary : .secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 8)
    .background(
      isActive
        ? Color.accentColor.opacity(0.1)
        : Color.clear,
      in: RoundedRectangle(cornerRadius: 8)
    )
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
  }

  private func formattedTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, secs)
  }
}

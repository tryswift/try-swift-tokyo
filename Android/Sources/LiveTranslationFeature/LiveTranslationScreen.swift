import SwiftUI

public struct LiveTranslationScreen: View {
  @State private var viewModel = LiveTranslationViewModel()

  private let scrollContentBottomID: String = "atBottom"

  public init() {}

  public var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            if viewModel.roomNumber.isEmpty {
              unavailableView("Room is unavailable", icon: "text.page.slash.fill")
            } else if viewModel.chatMessages.isEmpty {
              unavailableView("Not started yet", icon: "text.page.slash.fill")
            } else {
              translationContents
              Color.clear
                .id(scrollContentBottomID)
                .frame(height: 1)
            }
          }
          .onChange(of: viewModel.chatMessages.count) { oldCount, newCount in
            guard newCount > 0 else { return }
            guard oldCount == 0 || viewModel.isShowingLastMessage else { return }

            withAnimation {
              proxy.scrollTo(scrollContentBottomID, anchor: .bottom)
            }
          }
        }
        if viewModel.isShowingSpeedControl {
          speedControlView
        }
      }
      .onAppear {
        viewModel.onAppear()
      }
      .onDisappear {
        viewModel.disconnect()
        viewModel.cleanup()
      }
      .navigationTitle("Live Translation")
      #if os(iOS) || SKIP
      .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
      #endif
      #if os(iOS) || SKIP
      .toolbar {
        if !viewModel.isConnected && !viewModel.roomNumber.isEmpty {
          ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
            Button {
              viewModel.connect()
            } label: {
              Image(systemName: "arrow.trianglehead.2.clockwise")
            }
          }
        }
        ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
          HStack {
            Button {
              viewModel.isShowingSpeedControl = !viewModel.isShowingSpeedControl
            } label: {
              Image(systemName: "speedometer")
            }
            Button {
              viewModel.isShowingLanguageSheet = true
            } label: {
              Text(viewModel.selectedLangTitle)
              Image(systemName: "globe")
            }
          }
        }
      }
      #endif
      .sheet(isPresented: $viewModel.isShowingLanguageSheet) {
        SelectLanguageSheet(
          languages: viewModel.supportedLanguages,
          onSelect: { langCode, title in
            viewModel.selectLanguage(langCode, title: title)
            viewModel.isShowingLanguageSheet = false
          }
        )
      }
    }
  }

  @ViewBuilder
  private func unavailableView(_ message: String, icon: String) -> some View {
    VStack(spacing: 16) {
      Spacer()
        .frame(height: 80)
      Image(systemName: icon)
        .font(Font.system(size: 48))
        .foregroundStyle(Color.secondary)
      Text(message)
        .font(Font.title3)
        .foregroundStyle(Color.secondary)
      Spacer()
      flittoLogo
    }
    .frame(maxWidth: .infinity)
    .padding()
  }

  @ViewBuilder
  private var speedControlView: some View {
    VStack(spacing: 8) {
      HStack {
        Text("Speech Speed")
          .font(Font.subheadline)
        Spacer()
        Text(speedLabel)
          .font(Font.subheadline)
          .foregroundStyle(Color.secondary)
      }
      Slider(
        value: $viewModel.speechRate,
        in: 0.1...1.0,
        step: 0.1
      )
    }
    .padding()
    .background(Color(white: 0.95))
  }

  private var speedLabel: String {
    let rate = viewModel.speechRate
    if rate <= 0.3 {
      return "Slow"
    } else if rate <= 0.6 {
      return "Normal"
    } else {
      return "Fast"
    }
  }

  @ViewBuilder
  private var translationContents: some View {
    LazyVStack(spacing: 12) {
      ForEach(viewModel.chatMessages) { item in
        HStack(alignment: VerticalAlignment.top, spacing: 8) {
          Text(item.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(TextAlignment.leading)
          Button {
            if viewModel.speakingItemId == item.id {
              viewModel.stopSpeaking()
            } else {
              viewModel.speakText(item.text, itemId: item.id)
            }
          } label: {
            Image(
              systemName: viewModel.speakingItemId == item.id
                ? "stop.circle.fill" : "speaker.wave.2"
            )
            .foregroundStyle(
              viewModel.speakingItemId == item.id ? Color.red : Color.accentColor
            )
          }
          .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
          guard item == viewModel.chatMessages.last else { return }
          viewModel.isShowingLastMessage = true
        }
        .onDisappear {
          guard item == viewModel.chatMessages.last else { return }
          viewModel.isShowingLastMessage = false
        }
      }
    }
    .padding(Edge.Set.horizontal)
  }

  @ViewBuilder
  private var flittoLogo: some View {
    HStack {
      Spacer()
      Text("Powered by Flitto")
        .font(Font.caption)
        .foregroundStyle(Color.secondary)
      Spacer()
    }
    .padding(Edge.Set.vertical, 8)
    .padding(Edge.Set.horizontal)
  }
}

#if !SKIP
#Preview {
  LiveTranslationScreen()
}
#endif

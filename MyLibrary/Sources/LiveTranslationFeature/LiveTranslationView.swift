import LiveTranslationSDK_iOS
import SwiftUI

public struct LiveTranslationView: View {
  let viewModel: ViewModel
  @State var isSelectedLanguageSheet: Bool = false
  @State var isShowingLastChat: Bool = false

  @Environment(\.scenePhase) var scenePhase

  private let scrollContentBottomID: String = "atBottom"

  public init(
    roomNumber: String = ProcessInfo.processInfo.environment["LIVE_TRANSLATION_KEY"]
      ?? (Bundle.main.infoDictionary?["Live translation room number"] as? String) ?? ""
  ) {
    print(roomNumber)
    self.viewModel = ViewModel(roomNumber: roomNumber)
  }

  public var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { reader in
          ScrollView {
            if self.viewModel.roomNumber.isEmpty {
              ContentUnavailableView("Room is unavailable", systemImage: "text.page.slash.fill")
              Spacer()
            } else if viewModel.chatList.isEmpty {
              ContentUnavailableView("Not started yet", systemImage: "text.page.slash.fill")
              Spacer()
            } else {
              LazyVStack {
                ForEach(viewModel.chatList) { item in
                  Text(item.trItem?.content ?? item.item.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .onAppear {
                      guard item == viewModel.chatList.last else { return }
                      isShowingLastChat = true
                    }
                    .onDisappear {
                      guard item == viewModel.chatList.last else { return }
                      isShowingLastChat = false
                    }
                }
              }
            }

            HStack {
              Spacer()
              Text("Powered by", bundle: .module)
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
              Image(.flitto)
                .resizable()
                .offset(x: -10)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 30)
              Spacer()
            }
            .id(scrollContentBottomID)
            .padding(.bottom, 16)
          }
          .onChange(of: viewModel.chatList.last) { old, new in
            guard old != .none else {
              reader.scrollTo(scrollContentBottomID, anchor: .bottom)
              return
            }

            guard isShowingLastChat else { return }

            guard new != .none else { return }
            withAnimation(.interactiveSpring) {
              reader.scrollTo(scrollContentBottomID, anchor: .center)
            }
          }
        }
      }
      .task {
        viewModel.send(.onAppearedPage)
        viewModel.send(.connectChatStream)
      }
      .onChange(of: scenePhase) {
        switch scenePhase {
        case .inactive: break
        case .active:
          viewModel.send(.connectChatStream)
        case .background:
          viewModel.send(.disconnectChatStream)
        @unknown default: break
        }
      }
      .navigationTitle(Text("Live translation", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isSelectedLanguageSheet.toggle()
          } label: {
            let selectedLanguage =
              viewModel.langSet?.langCodingKey(viewModel.selectedLangCode) ?? ""
            Text(selectedLanguage)
            Image(systemName: "globe")
          }
          .sheet(isPresented: $isSelectedLanguageSheet) {
            SelectLanguageSheet(
              languageList: viewModel.langList,
              langSet: viewModel.langSet,
              selectedLanguageAction: { langCode in
                viewModel.send(.changeLangCode(langCode))
                isSelectedLanguageSheet = false
              }
            )
            .presentationDetents([.medium, .large])
          }
        }
      }
    }
  }
}

#Preview {
  LiveTranslationView(roomNumber: "490294")
}

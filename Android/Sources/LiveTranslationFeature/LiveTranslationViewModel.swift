import Foundation
import SkipModel

#if SKIP
  import com.flitto.livetranslation.sdk.chatguest.ChatGuestSdk
  import com.flitto.livetranslation.sdk.chatguest.model.ChatDataEntity
  import com.flitto.livetranslation.sdk.chatguest.model.ChatHistoryItemEntity
  import com.flitto.livetranslation.sdk.chatguest.model.LanguageInfoEntity
  import android.speech.tts.TextToSpeech
  import kotlinx.coroutines.CoroutineScope
  import kotlinx.coroutines.Dispatchers
  import kotlinx.coroutines.SupervisorJob
  import kotlinx.coroutines.Job
  import kotlinx.coroutines.launch
  import kotlinx.coroutines.cancel
  import kotlinx.coroutines.flow.collectLatest
#endif

public struct ChatMessage: Identifiable, Equatable {
  public var id: String
  public var text: String
  public var isRealTime: Bool

  public init(id: String, text: String, isRealTime: Bool = false) {
    self.id = id
    self.text = text
    self.isRealTime = isRealTime
  }
}

public struct LanguageItem: Identifiable, Equatable {
  public var id: String { langCode }
  public var langCode: String
  public var langTitle: String

  public init(langCode: String, langTitle: String) {
    self.langCode = langCode
    self.langTitle = langTitle
  }
}

@Observable
public final class LiveTranslationViewModel {
  public var chatMessages: [ChatMessage] = []
  public var supportedLanguages: [LanguageItem] = []
  public var selectedLangCode: String = "en"
  public var selectedLangTitle: String = "English"
  public var roomName: String = ""
  public var isConnected: Bool = false
  public var isShowingLanguageSheet: Bool = false
  public var isShowingLastMessage: Bool = false
  public var speechRate: Double = 0.5
  public var speakingItemId: String? = nil
  public var isShowingSpeedControl: Bool = false
  public var roomNumber: String = ""
  public var messagesType: String = ""

  #if SKIP
    private let scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var chatJob: Job? = nil
    private var connectionStateJob: Job? = nil
    private var languagesJob: Job? = nil
    private var tts: TextToSpeech? = nil
    private var ttsReady: Bool = false
  #endif

  public init() {}

  public func onAppear() {
    loadRoomNumber()
    guard !roomNumber.isEmpty else { return }
    connect()
  }

  public func connect() {
    #if SKIP
      // Guard against duplicate connections
      if chatJob != nil { return }

      let vm = self

      // Observe connection state
      connectionStateJob?.cancel()
      connectionStateJob = scope.launch {
        ChatGuestSdk.isConnected.collectLatest { connected in
          vm.isConnected = connected
        }
      }

      // Observe supported languages
      languagesJob?.cancel()
      languagesJob = scope.launch {
        ChatGuestSdk.supportLanguages.collectLatest { languages in
          var langs: [LanguageItem] = []
          for lang in languages {
            langs.append(LanguageItem(langCode: lang.languageCode, langTitle: lang.languageLocal))
          }
          vm.supportedLanguages = langs
          // Validate selected language
          if languages.size > 0 {
            let isValid = languages.any { $0.languageCode == vm.selectedLangCode }
            if !isValid {
              let deviceLang = java.util.Locale.getDefault().language
              let hasDeviceLang = languages.any { $0.languageCode == deviceLang }
              vm.selectedLangCode = hasDeviceLang ? deviceLang : "en"
              vm.selectedLangTitle =
                languages.first { $0.languageCode == vm.selectedLangCode }?.languageLocal
                ?? "English"
            }
          }
        }
      }

      // Connect to room
      scope.launch {
        do {
          let name = ChatGuestSdk.connectChat(
            roomCode: roomNumber, initialLangCode: selectedLangCode)
          vm.roomName = name
        } catch {
          print("connectChat error: \(error)")
        }
      }

      // Observe messages
      chatJob = scope.launch {
        ChatGuestSdk.observeMessages().collectLatest { data in
          vm.handleChatData(data)
        }
      }
    #endif
  }

  public func disconnect() {
    #if SKIP
      chatJob?.cancel()
      chatJob = nil
      connectionStateJob?.cancel()
      connectionStateJob = nil
      languagesJob?.cancel()
      languagesJob = nil
      tts?.stop()
      ChatGuestSdk.disconnectChat()
    #endif
    isConnected = false
    speakingItemId = nil
  }

  public func selectLanguage(_ langCode: String, title: String) {
    selectedLangCode = langCode
    selectedLangTitle = title
    #if SKIP
      scope.launch {
        ChatGuestSdk.requestTranslate(languageCode: langCode)
      }
    #endif
  }

  public func speakText(_ text: String, itemId: String) {
    #if SKIP
      if tts == nil {
        let textToSpeak = text
        let itemIdToSpeak = itemId
        let context = ProcessInfo.processInfo.androidContext
        tts = TextToSpeech(context) { status in
          if status == TextToSpeech.SUCCESS {
            self.ttsReady = true
            self.speakingItemId = itemIdToSpeak
            self.performSpeak(textToSpeak, langCode: self.selectedLangCode, rate: self.speechRate)
          } else {
            self.ttsReady = false
            self.speakingItemId = nil
          }
        }
      } else if ttsReady {
        speakingItemId = itemId
        performSpeak(text, langCode: selectedLangCode, rate: speechRate)
      }
    #else
      speakingItemId = itemId
    #endif
  }

  public func stopSpeaking() {
    #if SKIP
      tts?.stop()
    #endif
    speakingItemId = nil
  }

  public func cleanup() {
    #if SKIP
      chatJob?.cancel()
      chatJob = nil
      ChatGuestSdk.disconnectChat()
      tts?.shutdown()
      tts = nil
      scope.cancel()
    #endif
  }

  #if SKIP
    private func performSpeak(_ text: String, langCode: String, rate: Double) {
      tts?.setLanguage(java.util.Locale(langCode))
      tts?.setSpeechRate(Float(rate))

      let utteranceId = "tts_\(System.currentTimeMillis())"
      let vm = self
      let listener = TTSListener { vm.speakingItemId = nil }
      tts?.setOnUtteranceProgressListener(listener)
      tts?.speak(text, TextToSpeech.QUEUE_FLUSH, nil, utteranceId)
    }

    // Named listener class to avoid anonymous object transpilation issues
    private class TTSListener: android.speech.tts.UtteranceProgressListener {
      private let onComplete: () -> Void
      init(_ onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
      }
      override func onStart(_ utteranceId: String) {}
      override func onDone(_ utteranceId: String) { onComplete() }
      override func onError(_ utteranceId: String) { onComplete() }
    }

    private func handleChatData(_ data: ChatDataEntity) {
      switch data {
      case let historyData as ChatDataEntity.ChatHistoryDataEntity:
        let items = historyData.chatList
        let listType = historyData.listType

        switch listType {
        case "renew":
          var newMessages: [ChatMessage] = []
          for item in items {
            let msg = ChatMessage(
              id: item.chatId ?? java.util.UUID.randomUUID().toString(),
              text: item.text ?? "",
              isRealTime: item.isRealTime
            )
            if !msg.text.isEmpty {
              newMessages.append(msg)
            }
          }
          self.chatMessages = newMessages

        case "append":
          for item in items {
            let id = item.chatId ?? java.util.UUID.randomUUID().toString()
            let text = item.text ?? ""
            guard !text.isEmpty else { continue }

            if let existingIndex = self.chatMessages.lastIndex(where: { $0.id == id }) {
              self.chatMessages.remove(at: existingIndex)
            }
            self.chatMessages.append(ChatMessage(id: id, text: text, isRealTime: item.isRealTime))
          }
          // Keep last 100 messages
          if self.chatMessages.count > 100 {
            self.chatMessages = Array(self.chatMessages.suffix(100))
          }

        case "realtime":
          for item in items {
            let id = item.chatId ?? java.util.UUID.randomUUID().toString()
            let text = item.text ?? ""

            if let existingIndex = self.chatMessages.lastIndex(where: { $0.id == id }) {
              self.chatMessages.remove(at: existingIndex)
            }
            self.chatMessages.append(ChatMessage(id: id, text: text, isRealTime: item.isRealTime))
          }

        case "update":
          for item in items {
            let id = item.chatId ?? java.util.UUID.randomUUID().toString()
            let text = item.text ?? ""

            if let existingIndex = self.chatMessages.firstIndex(where: { $0.id == id }) {
              if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                self.chatMessages.remove(at: existingIndex)
              } else {
                self.chatMessages[existingIndex] = ChatMessage(
                  id: id, text: text, isRealTime: item.isRealTime)
              }
            }
          }

        case "translation":
          for item in items {
            let id = item.chatId ?? java.util.UUID.randomUUID().toString()
            let text = item.text ?? ""
            if !text.isEmpty,
              let existingIndex = self.chatMessages.firstIndex(where: { $0.id == id })
            {
              self.chatMessages[existingIndex] = ChatMessage(id: id, text: text, isRealTime: false)
            }
          }

        default:
          break
        }

        self.messagesType = listType ?? ""

      case is ChatDataEntity.ErrorEntity:
        print("Chat error: \(data)")

      default:
        break
      }
    }
  #endif

  private func loadRoomNumber() {
    #if SKIP
      let context = ProcessInfo.processInfo.androidContext
      // Try to read from BuildConfig or resources
      // For now, check system property or use environment variable pattern
      let envKey = System.getenv("LIVE_TRANSLATION_KEY")
      if let key = envKey, !key.isEmpty {
        roomNumber = key
      } else {
        // Try reading from Android string resources
        let resId = context.resources.getIdentifier(
          "live_translation_key", "string", context.packageName)
        if resId != 0 {
          roomNumber = context.getString(resId)
        }
      }
    #else
      roomNumber = ProcessInfo.processInfo.environment["LIVE_TRANSLATION_KEY"] ?? ""
    #endif
  }
}

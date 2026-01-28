# try! Swift Tokyo App

This is the official app for try! Swift Tokyo 2024/2026.

## Features

We've submitted the app to the App Store as MVP, and it's currently under review. Here's a list of features that are currently available and those that are planned for future releases:

- [x] View the schedule
- [x] View the sponsors
- [ ] Check your favorite sessions
- [ ] Receive notifications for upcoming sessions
- [x] Localize the app in English and Japanese (partially done)
- [ ] macOS support
- [ ] watchOS support
- [ ] tvOS support
- [x] visionOS support
- [x] Android support (via Skip framework)

## Requirements

### iOS
- Xcode 15.3 and later (Swift 5.10 and later)

### Android
- [Skip](https://skip.tools) framework
- Android Studio
- JDK 17 or later

## Installation

Available on the App Store soon, or you can build the app yourself. See the [Getting Started](#getting-started) section for more information.

## Getting Started

### iOS

1. Clone the repository
2. Open `trySwiftTokyo.xcworkspace` in Xcode
3. Build and run the app

### Android (Skip)

The Android version uses [Skip](https://skip.tools) to transpile Swift/SwiftUI to Kotlin/Jetpack Compose.

1. Install Skip following the [official instructions](https://skip.tools/docs/)
2. Navigate to the Android directory:
   ```bash
   cd Android
   ```
3. Build the project:
   ```bash
   swift build
   ```
4. Run on Android emulator or device:
   ```bash
   cd .build/plugins/outputs/skipstone/AndroidApp/skipstone
   ./gradlew installDebug
   ```

#### Android Features

The Android version includes:
- Schedule viewing (Day 1, Day 2, Day 3)
- Sponsors listing
- Venue information with directions
- About section with organizer information

Note: Some iOS-specific features are not available on Android:
- Live Translation (requires iOS SDK)
- MapKit integration (uses static venue information instead)

## Preview the Website

1. Install the Ignite command-line tool by following the instructions at [twostraws/Ignite](https://github.com/twostraws/Ignite)
2. Open `trySwiftTokyo.xcworkspace` in Xcode
3. Select the `Website` scheme in Xcode
4. Run the project (⌘+R) and verify the build succeeds in the console
5. Run `ignite run --preview` from the command line

## Contributing

We welcome contributions to the app! Please refer to the [Contributing Guidelines](CONTRIBUTING.md) for more information.

## Code Sharing between iOS and Android

This project demonstrates how Skip enables code sharing between iOS and Android with nearly identical SwiftUI syntax.

### Shared Components

The `Shared/` module contains UI components that work on both platforms:

- `SessionRowView` - Session list item
- `SessionDetailView` - Session detail screen
- `SponsorGridView` - Sponsor grid layout
- `SpeakerAvatarView` - Speaker avatar component

### Architecture Comparison

| Aspect | iOS | Android (Skip) |
|--------|-----|----------------|
| UI Framework | SwiftUI | SwiftUI → Jetpack Compose |
| State Management | TCA (`@Reducer`) | `@Observable` ViewModel |
| Navigation | `NavigationStack` | `NavigationStack` |
| Data Models | `SharedModels` | `SharedModels` |

### Example: Identical SwiftUI Code

```swift
// This code runs on BOTH iOS and Android
ForEach(conference.schedules, id: \.time) { schedule in
    Text(schedule.time, style: .time)
        .font(.subheadline.bold())

    ForEach(schedule.sessions, id: \.title) { session in
        SessionRowView(session: session)
    }
}
```

## Project Structure

```
try-swift-tokyo/
├── App/                    # Xcode project wrapper
├── iOS/                    # iOS app (SwiftUI + TCA)
│   └── Sources/
│       ├── AppFeature/
│       ├── ScheduleFeature/
│       ├── SponsorFeature/
│       ├── GuidanceFeature/
│       ├── LiveTranslationFeature/
│       └── trySwiftFeature/
├── Android/                # Android app (Skip)
│   └── Sources/
│       ├── AndroidApp/
│       ├── ScheduleFeature/
│       ├── SponsorFeature/
│       ├── VenueFeature/
│       └── AboutFeature/
├── Shared/                 # Shared UI components (iOS + Android)
│   └── Sources/
│       └── SharedViews/
├── SharedModels/           # Shared data models
├── DataClient/             # Data fetching client
├── Server/                 # Vapor backend
└── Website/                # Ignite static site
```

## History of try! Swift App

The first try! Swift app (a repository named final) was released in 2016. At the time, it was written in Swift 3. Now is a good time for a new app, so We rebuilt it based on TCA and SwiftUI. Please take a look and enjoy.
https://github.com/tryswift/trySwiftAppFinal

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

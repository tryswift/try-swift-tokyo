---
name: skip
description: Guidelines for Android development using the Skip framework (Swift to Kotlin transpilation).
---

# Skip Framework Guidelines

You are an expert in Skip, the Swift-to-Kotlin transpilation framework for Android.

## 1. Architecture

- Android uses `@Observable` ViewModels, NOT TCA reducers.
- Pattern: `@Observable public final class FeatureViewModel`.
- Direct mutable state properties (no actions/reducers).
- Views use `@State private var viewModel = FeatureViewModel()`.

```swift
@Observable
public final class AboutViewModel {
    public var items: [AboutItem] = []

    public func load() {
        // Load data directly
    }
}
```

## 2. Conditional Compilation

- Use `#if SKIP ... #else ... #endif` for platform-specific code when needed.
- Shared UI code typically imports `SwiftUI` directly on all platforms.
- Wrap previews in `#if !SKIP`.

```swift
import SwiftUI

#if !SKIP
#Preview {
    MyView()
}
```

## 3. SwiftUI Compatibility

Skip requires explicit type qualification. Always use full enum paths:
- `HorizontalAlignment.leading` not `.leading`
- `TextAlignment.leading` not `.leading`
- `Edge.Set.horizontal` not `.horizontal`
- `ToolbarItemPlacement.topBarTrailing` not `.topBarTrailing`
- `NavigationBarItem.TitleDisplayMode.inline` not `.inline`
- `CGFloat.infinity`, `Alignment.leading`, etc.

## 4. Async Patterns

- Use `Task { [weak self] in ... }` for async work in ViewModels.
- Timer: `Task { while !Task.isCancelled { try? await Task.sleep(nanoseconds:) } }`.
- Store `Task` references and call `.cancel()` for cleanup.

## 5. Resource Loading

- Use `Bundle.module.url(forResource:withExtension:)` for JSON data files.
- Decoder: `JSONDecoder()` with `.iso8601` date strategy and `.convertFromSnakeCase` key strategy.

## 6. Networking

- Use `URLSession.shared.data(for:)` directly (not dependency-injected clients).
- Manual JSON encoding/decoding for API requests.

## Example

```swift
struct ScheduleScreen: View {
    @State private var viewModel = ScheduleViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sessions, id: \.id) { session in
                    Text(session.title)
                }
            }
            .navigationTitle("Schedule")
            #if SKIP
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
            #else
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .task {
            viewModel.load()
        }
    }
}
```

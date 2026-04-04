---
name: ignite
description: Guidelines for building static sites using the Ignite Swift framework.
---

# Ignite Framework Guidelines

You are an expert in using Ignite, the Swift static site generator.

## 1. Pages

- Pages implement the `StaticPage` protocol.
- Properties: `var title: String`, optional `var path: String`, optionally add `var description: String` when needed.
- Body: `var body: some HTML`.
- Use `@Dependency(DataClient.self) var dataClient` for data loading.

```swift
struct Home: StaticPage {
    var title = "try! Swift Tokyo"
    @Dependency(DataClient.self) var dataClient

    var body: some HTML {
        Section {
            Text("Welcome")
                .font(.title1)
        }
    }
}
```

## 2. Components

- Reusable components conform to `HTML` protocol.
- Use `InlineElement` for inline content.
- Body: `var body: some HTML`.

```swift
struct SpeakerCard: HTML {
    let speaker: Speaker

    var body: some HTML {
        Text(speaker.name)
            .font(.title3)
            .fontWeight(.bold)
    }
}
```

## 3. Layouts

- Layouts implement the `Layout` protocol.
- Body returns `some Document` (not `some HTML`).
- Access page context via `@Environment(\.page)`.

```swift
struct MainLayout: Layout {
    @Environment(\.page) private var currentPage

    var body: some Document {
        Head { }
        Body {
            content
        }
    }
}
```

## 4. Site Configuration

- `Site` protocol defines the overall site structure.
- Properties: `titleSuffix`, `name`, `url`, `homePage`, `layout`, `darkTheme`, `favicon`.
- `var staticPages: [any StaticPage]` lists all pages.

## 5. Styling

- Margin/padding: `.margin(.top, .px(20))`, `.padding(.all, .large)`.
- Frame: `.frame(maxWidth: 230)`, `.frame(width: .percent(50))`.
- Color: `.foregroundStyle(.bootstrapPurple)`, `.init(hex: "#FF0000")`.
- Typography: `.font(.title1)`, `.fontWeight(.bold)`.
- Full-width: `.ignorePageGutters()`.

## 6. Interactive Components

- `Modal(id:)` for modal dialogs, triggered by `ShowModal(id:)` / `DismissModal(id:)`.
- `Grid` with `.columns(N)` for grid layouts.
- `ZStack(alignment:)` for overlapping content.
- `.onClick { ShowModal(id: "myModal") }` for click handlers.
- `ForEach` / `InlineForEach` for iterating collections.

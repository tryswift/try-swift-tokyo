---
name: swift-concurrency
description: Definitive guide for Swift 6+ Concurrency, strictly enforcing Sendable, Actors, and Structured Concurrency.
---

# Swift Concurrency Best Practices (Swift 6+)

## 1. Structured Concurrency

- **Prefer `async let`** for parallel tasks when the number of tasks is known.
- **Use `TaskGroup`** for a dynamic number of parallel tasks.
- **Avoid `Task { ... }` (unstructured)** unless bridging from synchronous code (e.g., UI event handlers) or firing background work that outlives the scope.

## 2. Actors & Isolation

- **Default to `@MainActor`** for all UI-related classes (ViewModels, SwiftUI Views).
- Use `actor` for shared mutable state that is *not* UI-related (e.g., caching, database managers).
- **Global Actors:** Use `@MainActor` or custom global actors to synchronize access across different types.

## 3. Sendability

- **Strict Concurrency Checking:** Assume `Strict Concurrency` is ON.
- Mark immutable structs/enums as `Sendable` (often implicit, but be explicit if public).
- For classes, use `final` and `@unchecked Sendable` *only* if you are manually managing thread safety (locks/queues). Ideally, use `actor`.
- **Closures:** Ensure closures passed between contexts are `@Sendable`.
- TCA types: State and Reducer structs should conform to `Sendable`.

## 4. Observable Pattern

- **Prefer `@Observable`** (Observation framework) over `ObservableObject` + `@Published`.
- Pattern: `@Observable public final class ViewModel`.
- Combine `@Observable` with `@MainActor` when accessing UI state from async contexts.

## 5. Migration from Combine/Closures

- Replace `DispatchQueue.main.async` with `await MainActor.run { ... }` or isolate the function itself.
- Replace `Future`/`Promise` with direct `async throws` functions.
- Use `AsyncStream` to replace simple Combine `PassthroughSubject` scenarios.

## Example: Safe ViewModel

```swift
@Observable
@MainActor
final class UserViewModel {
    var users: [User] = []

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func load() async {
        do {
            self.users = try await client.fetchUsers()
        } catch {
            print(error)
        }
    }
}
```

---
name: tca
description: Expert guidance on The Composable Architecture (TCA) for Swift, focusing on ReducerProtocol, macros, and testability.
---

# The Composable Architecture (TCA) Guidelines

You are an expert in Point-Free's Composable Architecture. When writing or refactoring TCA code, adhere to these rules:

## 1. Reducer Structure

- ALWAYS use the `@Reducer` macro.
- State and Action must be nested types within the Reducer struct.
- State uses `@ObservableState` macro: `@ObservableState public struct State: Equatable`.
- Actions should be separated into:
  - `case view(View)`: User interactions (`@CasePathable public enum View`).
  - `case delegate(Delegate)`: Communication with parent reducers.
  - `case internal(InternalAction)`: Side-effect results.

## 2. View Integration

- Use `@ViewAction(for: Feature.self)` macro on view structs.
- Store reference: `@Bindable var store: StoreOf<Feature>`.
- Actions from views: `send(.actionName)` shorthand (provided by `@ViewAction`).
- Child stores: `store.scope(state: \.child, action: \.child)`.

## 3. Bindings

- Conform Action to `BindableAction`: `enum Action: BindableAction, ViewAction`.
- Add `case binding(BindingAction<State>)` to Action.
- Add `BindingReducer()` in the reducer body composition.
- Two-way binding in views: `$store.searchText`, `$store.isPresented`.

## 4. Navigation

**Stack-based:**
- State: `var path = StackState<Path.State>()`.
- Action: `case path(StackActionOf<Path>)`.
- Define: `@Reducer public enum Path { case detail(ScheduleDetail) }`.
- Reducer body: `.forEach(\.path, action: \.path)`.
- View: `NavigationStack(path: $store.scope(state: \.path, action: \.path))`.

**Presentation (sheets/alerts):**
- State: `@Presents var destination: Destination.State?`.
- Reducer body: `.ifLet(\.$destination, action: \.destination)`.
- View: `.sheet(item: $store.scope(state: \.destination?.detail, action: \.destination.detail))`.

## 5. Dependencies

- Use the `@Dependency(\.clientName)` or `@Dependency(ClientType.self)` pattern.
- NEVER reach out to global singletons.
- Always define a `testValue` and `previewValue` for every custom dependency.

## 6. Effects & Concurrency

- Use `.run { send in ... }` for asynchronous side effects.
- Ensure all loops in effects handle cancellation properly via `.cancellable(id:)`.

## 7. Testing

- Use `TestStore` for all logic verification.
- Enforce exhaustivity: `store.exhaustivity = .on`.
- Mock all dependencies in tests using `withDependencies`.

## Example

```swift
@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        var count = 0
        var isLoading = false
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case incrementButtonTapped
        }
        enum Delegate: Equatable {
            case countChanged(Int)
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .send(.delegate(.countChanged(state.count)))
            case .binding, .delegate:
                return .none
            }
        }
    }
}

@ViewAction(for: Feature.self)
struct FeatureView: View {
    @Bindable var store: StoreOf<Feature>

    var body: some View {
        Button("Increment") {
            send(.incrementButtonTapped)
        }
    }
}
```

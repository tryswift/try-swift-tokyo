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
- Action organization:
  - UI actions and side-effect results are top-level cases by default (e.g. `case incrementButtonTapped`, `case fetchResponse(Result<Data, Error>)`).
  - `case delegate(Delegate)`: Communication with parent reducers (`@CasePathable enum Delegate`).
  - `case destination(PresentationAction<Destination.Action>)`: For presentation-based navigation.
- **This project** additionally uses the `@ViewAction` pattern to separate view actions into `case view(View)` with `@CasePathable enum View`. This is an optional advanced pattern.

## 2. View Integration

- Store reference: `@Bindable var store: StoreOf<Feature>`.
- Send actions: `store.send(.actionName)`.
- Child stores: `store.scope(state: \.child, action: \.child)`.
- **This project** uses `@ViewAction(for: Feature.self)` macro on view structs, enabling `send(.actionName)` shorthand (auto-wraps in `.view(...)`).

## 3. Bindings

- Conform Action to `BindableAction`: `enum Action: BindableAction`.
- Add `case binding(BindingAction<State>)` to Action. (When using `@ViewAction`, also conform to `ViewAction`.)
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
- Action: `case destination(PresentationAction<Destination.Action>)`.
- Reducer body: `.ifLet(\.$destination, action: \.destination)`.
- View (1.25+ enum scope): `.sheet(item: $store.scope(state: \.$destination, action: \.destination).edit) { ... }`.
- Use `@ReducerCaseIgnored` for non-reducer data (e.g. `AlertState`) in `Destination`.

## 5. Dependencies

- Use the `@Dependency(\.clientName)` or `@Dependency(ClientType.self)` pattern.
- NEVER reach out to global singletons.
- Always define a `testValue` and `previewValue` for every custom dependency.

## 6. Effects & Concurrency

- Use `.run { send in ... }` for asynchronous side effects.
- Ensure all loops in effects handle cancellation properly via `.cancellable(id:)`.

## 7. Testing

- Use `TestStore` for all logic verification.
- Enforce exhaustivity: `store.exhaustivity = .on` (default). Use `.off` for partial tests.
- Mock all dependencies: `TestStore(initialState:) { Reducer() } withDependencies: { ... }`.
- Receive actions with case key paths: `await store.receive(\.delegate.startMeeting)`.
- Stack path actions: `store.send(\.path[id: 0].feature.action)`.

## Example (standard pattern)

```swift
@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action {
        case incrementButtonTapped
        case fetchResponse(Result<Int, any Error>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case countChanged(Int)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .send(.delegate(.countChanged(state.count)))
            case .fetchResponse, .delegate:
                return .none
            }
        }
    }
}

struct FeatureView: View {
    @Bindable var store: StoreOf<Feature>

    var body: some View {
        Button("Increment") {
            store.send(.incrementButtonTapped)
        }
    }
}
```

## Example (this project's @ViewAction pattern)

```swift
@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case incrementButtonTapped
        }
        @CasePathable
        enum Delegate {
            case countChanged(Int)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .send(.delegate(.countChanged(state.count)))
            case .delegate:
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

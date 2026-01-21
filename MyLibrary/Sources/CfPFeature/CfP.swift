import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct CfP {
  @ObservableState
  public struct State: Equatable {
    var currentUser: UserDTO?
    var proposals: [ProposalDTO] = []
    var isLoading: Bool = false
    var isLoggedIn: Bool = false
    
    @Presents var destination: Destination.State?
    @Presents var alert: AlertState<Action.Alert>?
    
    public init() {}
  }
  
  @Reducer
  public enum Destination {
    case form(CfPForm)
  }
  
  public enum Action {
    case onAppear
    case loginButtonTapped
    case loginResponse(Result<AuthResponse, Error>)
    case loadProposals
    case proposalsResponse(Result<[ProposalDTO], Error>)
    case newProposalButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case alert(PresentationAction<Alert>)
    case logoutButtonTapped
    
    public enum Alert: Equatable {}
  }
  
  @Dependency(\.cfpClient) var cfpClient
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Check if user is already logged in
        guard !state.isLoggedIn else { return .none }
        return .none
        
      case .loginButtonTapped:
        state.isLoading = true
        return .run { send in
          await send(.loginResponse(Result {
            try await cfpClient.login()
          }))
        }
        
      case let .loginResponse(.success(authResponse)):
        state.isLoading = false
        state.isLoggedIn = true
        state.currentUser = authResponse.user
        return .send(.loadProposals)
        
      case let .loginResponse(.failure(error)):
        state.isLoading = false
        state.alert = AlertState {
          TextState("Login Failed")
        } actions: {
          ButtonState(role: .cancel) {
            TextState("OK")
          }
        } message: {
          TextState(error.localizedDescription)
        }
        return .none
        
      case .loadProposals:
        state.isLoading = true
        return .run { send in
          await send(.proposalsResponse(Result {
            try await cfpClient.getMyProposals()
          }))
        }
        
      case let .proposalsResponse(.success(proposals)):
        state.isLoading = false
        state.proposals = proposals
        return .none
        
      case let .proposalsResponse(.failure(error)):
        state.isLoading = false
        state.alert = AlertState {
          TextState("Error")
        } actions: {
          ButtonState(role: .cancel) {
            TextState("OK")
          }
        } message: {
          TextState(error.localizedDescription)
        }
        return .none
        
      case .newProposalButtonTapped:
        state.destination = .form(CfPForm.State())
        return .none
        
      case let .destination(.presented(.form(.delegate(.proposalSubmitted(proposal))))):
        state.proposals.insert(proposal, at: 0)
        state.destination = nil
        return .none
        
      case .destination:
        return .none
        
      case .alert:
        return .none
        
      case .logoutButtonTapped:
        state.isLoggedIn = false
        state.currentUser = nil
        state.proposals = []
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$alert, action: \.alert)
  }
}

public struct CfPView: View {
  @Bindable var store: StoreOf<CfP>
  
  public init(store: StoreOf<CfP>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      Group {
        if store.isLoggedIn {
          loggedInView
        } else {
          loginView
        }
      }
      .navigationTitle("Call for Proposals")
      .navigationDestination(
        item: $store.scope(state: \.destination?.form, action: \.destination.form)
      ) { formStore in
        CfPFormView(store: formStore)
      }
      .alert($store.scope(state: \.alert, action: \.alert))
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
  
  @ViewBuilder
  private var loginView: some View {
    VStack(spacing: 24) {
      Image(systemName: "person.crop.circle.badge.questionmark")
        .font(.system(size: 80))
        .foregroundStyle(.secondary)
      
      Text("Sign in with GitHub")
        .font(.title2)
        .fontWeight(.semibold)
      
      Text("Connect your GitHub account to submit proposals for try! Swift Tokyo.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
      
      Button {
        store.send(.loginButtonTapped)
      } label: {
        HStack {
          if store.isLoading {
            ProgressView()
              .progressViewStyle(.circular)
              .tint(.white)
          }
          Image(systemName: "apple.logo")
          Text("Sign in with GitHub")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.black)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .disabled(store.isLoading)
      .padding(.horizontal, 32)
    }
    .padding()
  }
  
  @ViewBuilder
  private var loggedInView: some View {
    List {
      if let user = store.currentUser {
        Section {
          HStack {
            if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
              AsyncImage(url: url) { image in
                image
                  .resizable()
                  .scaledToFill()
              } placeholder: {
                Image(systemName: "person.circle.fill")
                  .font(.largeTitle)
              }
              .frame(width: 50, height: 50)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
              Text(user.username)
                .font(.headline)
              Text(user.role.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Logout") {
              store.send(.logoutButtonTapped)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
          }
        }
      }
      
      Section {
        if store.isLoading {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        } else if store.proposals.isEmpty {
          ContentUnavailableView {
            Label("No Proposals", systemImage: "doc.text")
          } description: {
            Text("You haven't submitted any proposals yet.")
          } actions: {
            Button("Submit Proposal") {
              store.send(.newProposalButtonTapped)
            }
            .buttonStyle(.borderedProminent)
          }
        } else {
          ForEach(store.proposals) { proposal in
            ProposalRowView(proposal: proposal)
          }
        }
      } header: {
        HStack {
          Text("My Proposals")
          Spacer()
          if !store.proposals.isEmpty {
            Button {
              store.send(.newProposalButtonTapped)
            } label: {
              Image(systemName: "plus.circle.fill")
            }
          }
        }
      }
    }
    .refreshable {
      store.send(.loadProposals)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.newProposalButtonTapped)
        } label: {
          Image(systemName: "plus")
        }
      }
    }
  }
}

struct ProposalRowView: View {
  let proposal: ProposalDTO
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(proposal.title)
          .font(.headline)
        Spacer()
        Text(proposal.talkDuration.rawValue)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(proposal.talkDuration == .regular ? Color.blue : Color.orange)
          .foregroundStyle(.white)
          .clipShape(Capsule())
      }
      
      Text(proposal.abstract)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
      
      if let createdAt = proposal.createdAt {
        Text("Submitted \(createdAt, style: .relative) ago")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview("Logged Out") {
  CfPView(
    store: Store(initialState: CfP.State()) {
      CfP()
    } withDependencies: {
      $0.cfpClient = .previewValue
    }
  )
}

#Preview("Logged In") {
  CfPView(
    store: Store(
      initialState: {
        var state = CfP.State()
        state.isLoggedIn = true
        state.currentUser = UserDTO(
          id: UUID(),
          githubID: 12345,
          username: "swiftdev",
          role: .speaker,
          avatarURL: nil
        )
        state.proposals = [
          ProposalDTO(
            id: UUID(),
            title: "Building Modern iOS Apps with Swift 6",
            abstract: "Learn how to leverage the latest Swift 6 features to build robust iOS applications.",
            talkDetail: "This talk will cover...",
            talkDuration: .regular,
            bio: "iOS Developer",
            speakerID: UUID(),
            speakerUsername: "swiftdev",
            createdAt: Date()
          ),
          ProposalDTO(
            id: UUID(),
            title: "Quick Tips for SwiftUI",
            abstract: "5 tips to improve your SwiftUI code.",
            talkDetail: "Lightning talk covering...",
            talkDuration: .lightning,
            bio: "iOS Developer",
            speakerID: UUID(),
            speakerUsername: "swiftdev",
            createdAt: Date().addingTimeInterval(-86400)
          )
        ]
        return state
      }()
    ) {
      CfP()
    } withDependencies: {
      $0.cfpClient = .previewValue
    }
  )
}

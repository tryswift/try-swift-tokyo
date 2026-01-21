import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct CfPForm {
  @ObservableState
  public struct State: Equatable {
    var title: String = ""
    var abstract: String = ""
    var talkDetail: String = ""
    var talkDuration: TalkDuration = .regular
    var bio: String = ""
    var iconURL: String = ""
    var notes: String = ""
    
    var isSubmitting: Bool = false
    var validationErrors: [String] = []
    
    @Presents var alert: AlertState<Action.Alert>?
    
    public init() {}
    
    public init(proposal: ProposalDTO) {
      self.title = proposal.title
      self.abstract = proposal.abstract
      self.talkDetail = proposal.talkDetail
      self.talkDuration = proposal.talkDuration
      self.bio = proposal.bio
      self.iconURL = proposal.iconURL ?? ""
      self.notes = proposal.notes ?? ""
    }
    
    var isValid: Bool {
      !title.isEmpty && !abstract.isEmpty && !talkDetail.isEmpty && !bio.isEmpty
    }
    
    var canSubmit: Bool {
      isValid && !isSubmitting
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case submitButtonTapped
    case submitResponse(Result<ProposalDTO, Error>)
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    
    public enum Alert: Equatable {}
    
    public enum Delegate: Equatable {
      case proposalSubmitted(ProposalDTO)
    }
  }
  
  @Dependency(\.cfpClient) var cfpClient
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        state.validationErrors = []
        return .none
        
      case .submitButtonTapped:
        var errors: [String] = []
        if state.title.isEmpty {
          errors.append("Title is required")
        }
        if state.abstract.isEmpty {
          errors.append("Abstract is required")
        }
        if state.talkDetail.isEmpty {
          errors.append("Talk detail is required")
        }
        if state.bio.isEmpty {
          errors.append("Bio is required")
        }
        
        if !errors.isEmpty {
          state.validationErrors = errors
          return .none
        }
        
        state.isSubmitting = true
        
        let request = CreateProposalRequest(
          title: state.title,
          abstract: state.abstract,
          talkDetail: state.talkDetail,
          talkDuration: state.talkDuration,
          bio: state.bio,
          iconURL: state.iconURL.isEmpty ? nil : state.iconURL,
          notes: state.notes.isEmpty ? nil : state.notes
        )
        
        let cfpClient = cfpClient
        return .run { send in
          await send(.submitResponse(Result {
            try await cfpClient.createProposal(request)
          }))
        }
        
      case let .submitResponse(.success(proposal)):
        state.isSubmitting = false
        state.alert = AlertState {
          TextState("Success!")
        } actions: {
          ButtonState(action: .send(.none)) {
            TextState("OK")
          }
        } message: {
          TextState("Your proposal has been submitted successfully.")
        }
        return .send(.delegate(.proposalSubmitted(proposal)))
        
      case let .submitResponse(.failure(error)):
        state.isSubmitting = false
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
        
      case .alert:
        return .none
        
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

public struct CfPFormView: View {
  @Bindable var store: StoreOf<CfPForm>
  
  public init(store: StoreOf<CfPForm>) {
    self.store = store
  }
  
  public var body: some View {
    Form {
      Section {
        TextField("Title", text: $store.title)
        #if os(iOS)
          .textInputAutocapitalization(.words)
        #endif
        
        VStack(alignment: .leading, spacing: 4) {
          Text("Abstract")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextEditor(text: $store.abstract)
            .frame(minHeight: 100)
        }
      } header: {
        Text("Talk Information")
      } footer: {
        Text("The abstract will be shown publicly if your talk is accepted.")
      }
      
      Section {
        VStack(alignment: .leading, spacing: 4) {
          Text("Talk Detail")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextEditor(text: $store.talkDetail)
            .frame(minHeight: 150)
        }
        
        Picker("Duration", selection: $store.talkDuration) {
          ForEach(TalkDuration.allCases, id: \.self) { duration in
            Text(duration.displayName).tag(duration)
          }
        }
      } header: {
        Text("Talk Details (For Reviewers)")
      } footer: {
        Text("Provide detailed information about your talk. This will only be visible to organizers.")
      }
      
      Section {
        VStack(alignment: .leading, spacing: 4) {
          Text("Bio")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextEditor(text: $store.bio)
            .frame(minHeight: 80)
        }
        
        TextField("Icon URL", text: $store.iconURL)
        #if os(iOS)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
        #endif
          .autocorrectionDisabled()
      } header: {
        Text("Speaker Information")
      }
      
      Section {
        VStack(alignment: .leading, spacing: 4) {
          Text("Notes for Organizers")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextEditor(text: $store.notes)
            .frame(minHeight: 60)
        }
      } header: {
        Text("Additional Notes")
      } footer: {
        Text("Any additional information you'd like to share with the organizers (e.g., scheduling constraints, accessibility needs).")
      }
      
      if !store.validationErrors.isEmpty {
        Section {
          ForEach(store.validationErrors, id: \.self) { error in
            Label(error, systemImage: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
          }
        }
      }
      
      Section {
        Button {
          store.send(.submitButtonTapped)
        } label: {
          HStack {
            if store.isSubmitting {
              ProgressView()
                .progressViewStyle(.circular)
            }
            Text(store.isSubmitting ? "Submitting..." : "Submit Proposal")
              .frame(maxWidth: .infinity)
          }
        }
        .disabled(!store.canSubmit)
        .buttonStyle(.borderedProminent)
        .listRowBackground(Color.clear)
      }
    }
    .navigationTitle("Submit Proposal")
    .navigationBarTitleDisplayMode(.large)
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview {
  NavigationStack {
    CfPFormView(
      store: Store(initialState: CfPForm.State()) {
        CfPForm()
      } withDependencies: {
        $0.cfpClient = .previewValue
      }
    )
  }
}

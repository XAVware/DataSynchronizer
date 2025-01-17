//
//  ViewModels.swift
//  GameArchitecture
//
//  Created by Ryan Smetana on 1/7/25.
//

import SwiftUI
import Combine

@MainActor
final class AuthViewClusterModel: AuthViewModeling {
    @Published var currentState: AuthState = .loginEmail
    private let authService: AuthenticationService
    private let loadingTask: LoadingOperations.Type
    
    init(loadingTask: LoadingOperations.Type = LoadingTask.self) {
        self.authService = AuthService.shared
        self.loadingTask = loadingTask
    }
    
    func createUser(withEmail email: String, password: String) async {
        await LoadingTask.executeWithErrorHandling {
            guard !email.isEmpty else { throw AppAuthError.invalidEmail }
            guard password.count >= 6 else { throw AppAuthError.invalidPasswordLength }
            let _ = try await AuthService.shared.createUser(email: email, password: password)
        }
    }
    
    func login(withEmail email: String, password: String) async {
        let _ = await LoadingTask.executeWithErrorHandling {
            try await AuthService.shared.login(withEmail: email, password: password)
        }
    }
    
    func sendResetPasswordEmail(to email: String) async {
        await LoadingTask.executeWithErrorHandling {
            try await AuthService.shared.sendResetPasswordLink(toEmail: email)
        }
    }
    
}

@MainActor
final class ProfileViewModel: ProfileViewModeling {
    @Published var user: User?
    @Published var currentState: ProfileState = .viewProfile
    @Published var reauthenticationRequired = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationService
    private let loadingTask: LoadingOperations.Type
    
    init(loadingTask: LoadingOperations.Type = LoadingTask.self) {
        self.authService = AuthService.shared
        self.loadingTask = loadingTask
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        guard let publisher = authService as? AuthService else { return }
        publisher.$user
            .receive(on: RunLoop.main)
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
    }
    
    func changeView(to newState: ProfileState) {
        currentState = newState
    }
    
    func updateDisplayName(to name: String) async {
        await LoadingTask.executeWithErrorHandling {
            try await AuthService.shared.updateDisplayName(to: name)
            self.changeView(to: .viewProfile)
        }
    }
    
    func updateEmail(to email: String) async {
        await LoadingTask.executeWithErrorHandling {
            try await AuthService.shared.updateEmail(to: email)
            self.reauthenticationRequired = true
        }
    }
}

// MARK: - Menu View Model
@MainActor final class MenuViewModel: ObservableObject {
    @Published var remindersOn: Bool = true
    @Published var soundOn: Bool = true
    @Published var hapticsOn: Bool = true
    @Published var accLabelsOn: Bool = true
    
    @Binding var navPath: [ViewPath]
    
    init(navPath: Binding<[ViewPath]>) {
        self._navPath = navPath
    }
    
    func pushView(_ viewPath: ViewPath) {
        navPath.append(viewPath)
    }
    
    func logOut() {
        AuthService.shared.signout()
        navPath.removeAll()
        
        // TODO: Toggle Onboarding?
    }
}

// MARK: - Onboarding View Model

@MainActor class OnboardingViewModel: ObservableObject {
    enum ViewState { case microphone, pushNotifications }
    @Published var currentState: ViewState = .microphone
    
    func incrementPage() {
        switch currentState {
        case .microphone:
            currentState = .pushNotifications
        case .pushNotifications:
            finish()
        }
    }
    
    func finish() {
        SessionManager.shared.toggleOnboarding()
    }
    
    func nextTapped() {
        switch currentState {
        case .microphone:
            incrementPage()
        case .pushNotifications:
            // Request push notification access
            finish()
        }
    }
}

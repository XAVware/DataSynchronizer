//
//  AuthService.swift
//  FireImp
//
//  Created by Ryan Smetana on 2/27/24.
//
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthService: ObservableObject, AuthenticationService {
    @Published private(set) var user: User?
    private let cloudService: CloudDataServiceProtocol
    private let sessionManager: SessionCoordinator
    
    static let shared = AuthService(
        cloudService: CloudDataService.shared,
        sessionManager: SessionManager.shared
    )
    
    init(cloudService: CloudDataServiceProtocol,
         sessionManager: SessionCoordinator) {
        self.cloudService = cloudService
        self.sessionManager = sessionManager
        refreshUser()
    }
    
    func login(withEmail email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = try await cloudService.handleLogin(authUser: result.user)
        self.user = user
        return user
    }
    
    // TODO: Handle error if user tries to create account with email that already exists.
    func createUser(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let newUser = User(
            uid: result.user.uid,
            email: result.user.email ?? "ERR",
            displayName: result.user.displayName,
            dateCreated: result.user.metadata.creationDate ?? Date()
        )
        
        try await cloudService.createUserDoc(newUser: newUser)
        self.user = newUser
        try await result.user.sendEmailVerification()
        return newUser
    }
    
    func refreshUser() {
        if let authUser = Auth.auth().currentUser {
            self.user = User(uid: authUser.uid,
                             email: authUser.email ?? "ERR",
                             displayName: authUser.displayName,
                             dateCreated: authUser.metadata.creationDate ?? Date(),
                             emailVerified: authUser.isEmailVerified)
        } else {
            self.user = nil
        }
    }
    
    // TODO: Handle error if non existing email is entered. Right now its generic error.
    func sendResetPasswordLink(toEmail email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            sessionManager.showAlert(.success, "Email sent. Please check your inbox.")
        } catch {
            sessionManager.showAlert(.error, authError(error).localizedDescription)
        }
        sessionManager.stopLoading()
    }
    
    func updateEmail(to email: String) async throws {
        guard let authUser = Auth.auth().currentUser else { return }
        
        do {
            try await authUser.sendEmailVerification(beforeUpdatingEmail: email)
            
            var updatedUser = user
            updatedUser?.email = email
            try await cloudService.updateUserData(updatedUser!)
            
            sessionManager.showAlert(.success, "Email sent. Please check your inbox.")
            signout()
        } catch {
            sessionManager.showAlert(.error, authError(error).localizedDescription)
        }
        
        sessionManager.stopLoading()
    }
    
    func updateDisplayName(to name: String) async throws {
        guard let authUser = Auth.auth().currentUser else { return }
        do {
            let changeRequest = authUser.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            var updatedUser = user
            updatedUser?.displayName = name
            try await cloudService.updateUserData(updatedUser!)
        } catch {
            sessionManager.showAlert(.error, authError(error).localizedDescription)
        }
        refreshUser()
        sessionManager.stopLoading()
    }
    
    func signout() {
        do {
            try Auth.auth().signOut()
            self.refreshUser()
        } catch {
            print(">>> Error signing out: \(error)")
        }
    }
    
}

@MainActor
final class CloudDataService: CloudDataServiceProtocol {
    static let shared = CloudDataService()
    private let db = Firestore.firestore()
    private let userCollection = Firestore.firestore().collection("users")
    
    enum UserDocumentKey: String, Hashable {
        case email = "email"
        case emailVerified = "emailVerified"
        case displayname = "displayName"
    }
    
    func createUserDoc(newUser: User) async throws {
        try userCollection.document(newUser.uid).setData(from: newUser)
    }
    
    func fetchUser(withUid uid: String) async throws -> User {
        let user = try await userCollection.document(uid).getDocument(as: User.self)
        return user
    }
    
//    @MainActor
//    func updateDisplayName(uid: String, newName: String) async throws {
//        try await Task { @MainActor in
//            try await userCollection.document(uid).updateData([
//                "displayName": newName
//            ])
//        }.value
//    }
//    
//    @MainActor
//    func updateEmail(uid: String, newEmail: String) async throws {
//        try await userCollection.document(uid).updateData([
//            "email": newEmail
//        ])
//    }
    
    func updateUserData(_ user: User) async throws {
        try userCollection.document(user.uid).setData(from: user)
    }
    
    func handleLogin(authUser: FirebaseAuth.User) async throws -> User {
        let localUser = User(
            uid: authUser.uid,
            email: authUser.email ?? "ERR",
            displayName: authUser.displayName,
            dateCreated: authUser.metadata.creationDate ?? Date(),
            emailVerified: authUser.isEmailVerified
        )
        
        let dbUser = try await fetchUser(withUid: localUser.uid)
        
        if localUser != dbUser {
            try await updateUserData(localUser)
        }
        
        return localUser
    }
}

import SwiftUI

@MainActor
final class SessionManager: ObservableObject, SessionCoordinator {
    @Published var alert: AlertModel?
    @Published var isLoading: Bool = false
    @AppStorage("isOnboarding") var isOnboarding: Bool = false
    
    static let shared = SessionManager()
    
    private init() {}
    
    func toggleOnboarding() {
        self.isOnboarding.toggle()
    }
    
    nonisolated func removeAlert() {
        Task { @MainActor in
            self.alert = nil
        }
    }
    
    func showAlert(_ type: AlertModel.AlertType, _ message: String) {
        self.alert = AlertModel(type: type, message: message)
    }
    
    func startLoading() {
        self.isLoading = true
    }
    
    func stopLoading() {
        self.isLoading = false
    }
}

@MainActor
enum LoadingTask: LoadingOperations {
    /// Executes an async operation while managing loading state
    /// - Parameter operation: The async operation to perform
    /// - Returns: The result of the operation
    static func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        let sessionManager = SessionManager.shared
        sessionManager.startLoading()
        defer { sessionManager.stopLoading() }
        return try await operation()
    }
    
    /// Executes an async operation while managing loading state and handling errors
    /// - Parameters:
    ///   - operation: The async operation to perform
    ///   - errorHandler: Optional custom error handler
    /// - Returns: The result of the operation or nil if an error occurred
    static func executeWithErrorHandling<T>(_ operation: @escaping () async throws -> T,
                                            errorHandler: ((Error) -> Void)? = nil) async -> T? {
        do {
            return try await execute(operation)
        } catch {
            errorHandler?(error)
            SessionManager.shared.showAlert(.error, error.localizedDescription)
            return nil
        }
    }
    
}

// MARK: - Auth Error
extension AuthService {
    private func authError(_ origError: Error) -> AppAuthError {
        if let error = origError as? AuthErrorCode {
            return switch error.code {
            case .emailAlreadyInUse:                    AppAuthError.emailAlreadyInUse
            case .invalidEmail:                         AppAuthError.invalidEmail
            case .wrongPassword:                        AppAuthError.invalidPassword
            case .tooManyRequests:                      AppAuthError.networkError
            case .networkError:                         AppAuthError.networkError
            case .weakPassword:                         AppAuthError.weakPassword
            case .invalidCredential:                    AppAuthError.invalidCredential
            case .userDisabled:                         AppAuthError.userDisabled
            case .userNotFound:                         AppAuthError.userNotFound
            case .accountExistsWithDifferentCredential: AppAuthError.accountExistsWithDifferentCredential
            case .credentialAlreadyInUse:               AppAuthError.credentialAlreadyInUse
            case .invalidPhoneNumber:                   AppAuthError.invalidPhoneNumber
            case .nullUser:                             AppAuthError.nullUser
            case .rejectedCredential:                   AppAuthError.rejectedCredential
            case .requiresRecentLogin:                  AppAuthError.reauthenticationRequired
            default:                                    AppAuthError.otherError(origError)
            }
        } else {
            return AppAuthError.otherError(origError)
        }
    }
}

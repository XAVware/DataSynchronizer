//
//  AppAuthError.swift
//  FireImp
//
//  Created by Ryan Smetana on 12/24/23.
//

import SwiftUI
import FirebaseAuth

// MARK: - Authentication Protocols

/**
 * Protocol defining core authentication operations.
 * Manages user authentication state and operations like login, signup, and password reset.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should maintain current user state
 * - Must handle all authentication errors appropriately
 */
@MainActor
protocol AuthenticationService: AnyObject {
    /// Current authenticated user, if any
    var user: User? { get }
    
    /// Authenticates a user with email and password
    /// - Parameters:
    ///   - withEmail: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated User object
    /// - Throws: AppAuthError for authentication failures
    func login(withEmail: String, password: String) async throws -> User
    
    /// Creates a new user account
    /// - Parameters:
    ///   - email: New user's email address
    ///   - password: New user's password
    /// - Returns: Newly created User object
    /// - Throws: AppAuthError for account creation failures
    func createUser(email: String, password: String) async throws -> User
    
    /// Signs out the current user
    func signout()
    
    /// Updates cached user information from authentication provider
    func refreshUser()
    
    /// Sends a password reset link to the specified email
    /// - Parameter toEmail: Email address for password reset
    /// - Throws: AppAuthError for email sending failures
    func sendResetPasswordLink(toEmail: String) async throws
    
    /// Updates the user's email address
    /// - Parameter to: New email address
    /// - Throws: AppAuthError for email update failures
    func updateEmail(to: String) async throws
    
    /// Updates the user's display name
    /// - Parameter to: New display name
    /// - Throws: AppAuthError for display name update failures
    func updateDisplayName(to: String) async throws
}

/**
 * Protocol for cloud-based data operations related to user management.
 * Handles user document creation, retrieval, and updates in the cloud database.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle network errors appropriately
 * - Must maintain data consistency with authentication service
 */
@MainActor
protocol CloudDataServiceProtocol {
    /// Creates a new user document in the cloud database
    /// - Parameter newUser: User object to create
    /// - Throws: FirestoreError for database operation failures
    func createUserDoc(newUser: User) async throws
    
    /// Retrieves a user document from the cloud database
    /// - Parameter withUid: User ID to fetch
    /// - Returns: User object if found
    /// - Throws: FirestoreError for database operation failures
    func fetchUser(withUid: String) async throws -> User
    
    /// Updates an existing user document
    /// - Parameter user: Updated User object
    /// - Throws: FirestoreError for database operation failures
    func updateUserData(_ user: User) async throws
    
    /// Handles post-login operations for user data synchronization
    /// - Parameter authUser: Authenticated user from Firebase
    /// - Returns: Synchronized User object
    /// - Throws: FirestoreError for database operation failures
    func handleLogin(authUser: FirebaseAuth.User) async throws -> User
}

/**
 * Protocol for managing application session state.
 * Coordinates loading states, alerts, and onboarding flow.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should manage global application state
 * - Must handle state transitions smoothly
 */
@MainActor
protocol SessionCoordinator: AnyObject {
    /// Current alert being displayed, if any
    var alert: AlertModel? { get set }
    
    /// Whether the application is in a loading state
    var isLoading: Bool { get set }
    
    /// Whether the user is in the onboarding flow
    var isOnboarding: Bool { get set }
    
    /// Toggles the onboarding state
    func toggleOnboarding()
    
    /// Removes the current alert
    func removeAlert()
    
    /// Displays a new alert
    /// - Parameters:
    ///   - type: Type of alert to show
    ///   - message: Alert message
    func showAlert(_ type: AlertModel.AlertType, _ message: String)
    
    /// Begins a loading operation
    func startLoading()
    
    /// Ends a loading operation
    func stopLoading()
}

/**
 * Protocol for handling loading operations with error handling.
 * Provides standardized way to execute async operations with loading states.
 *
 * Implementation requirements:
 * - Must handle loading state management
 * - Should provide error handling capabilities
 * - Must be type-safe for operation results
 */
protocol LoadingOperations {
    /// Executes an async operation with loading state management
    /// - Parameter operation: Async operation to execute
    /// - Returns: Operation result of type T
    /// - Throws: Any errors from the operation
    static func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T
    
    /// Executes an async operation with custom error handling
    /// - Parameters:
    ///   - operation: Async operation to execute
    ///   - errorHandler: Optional custom error handler
    /// - Returns: Operation result of type T or nil if operation failed
    static func executeWithErrorHandling<T>(_ operation: @escaping () async throws -> T,
                                            errorHandler: ((Error) -> Void)?) async -> T?
}

/**
 * Protocol for presenting alerts in the application.
 * Standardizes alert presentation and management.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle alert queuing if needed
 * - Must manage alert lifecycle
 */
@MainActor
protocol AlertPresenter {
    /// Current alert being displayed, if any
    var alert: AlertModel? { get set }
    
    /// Removes the current alert
    func removeAlert()
    
    /// Displays a new alert
    /// - Parameters:
    ///   - type: Type of alert to show
    ///   - message: Alert message
    func showAlert(_ type: AlertModel.AlertType, _ message: String)
}

// MARK: - View Model Protocols

/**
 * Protocol for authentication view model functionality.
 * Manages authentication UI state and operations.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle all auth states
 * - Must coordinate with AuthenticationService
 */
@MainActor
protocol AuthViewModeling: ObservableObject {
    /// Current authentication UI state
    var currentState: AuthState { get set }
    
    /// Creates a new user account
    /// - Parameters:
    ///   - withEmail: New user's email
    ///   - password: New user's password
    func createUser(withEmail: String, password: String) async
    
    /// Logs in an existing user
    /// - Parameters:
    ///   - withEmail: User's email
    ///   - password: User's password
    func login(withEmail: String, password: String) async
    
    /// Sends password reset email
    /// - Parameter to: Email address for reset
    func sendResetPasswordEmail(to: String) async
}

/**
 * Protocol for profile view model functionality.
 * Manages user profile UI state and operations.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle profile editing states
 * - Must coordinate with AuthenticationService
 */
@MainActor
protocol ProfileViewModeling: ObservableObject {
    /// Current profile view state
    var currentState: ProfileState { get set }
    
    /// Currently authenticated user
    var user: User? { get }
    
    /// Whether reauthentication is required for sensitive operations
    var reauthenticationRequired: Bool { get set }
    
    /// Changes the current view state
    /// - Parameter to: New profile state
    func changeView(to: ProfileState)
    
    /// Updates user's display name
    /// - Parameter to: New display name
    func updateDisplayName(to: String) async
    
    /// Updates user's email address
    /// - Parameter to: New email address
    func updateEmail(to: String) async
}

/**
 * Protocol for root view model functionality.
 * Manages application navigation and user state.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle navigation state
 * - Must coordinate with AuthenticationService
 */
@MainActor
protocol RootViewModeling: ObservableObject {
    /// Currently authenticated user
    var currentUser: User? { get }
    
    /// Current navigation path
    var navPath: [ViewPath] { get set }
    
    /// Pushes a new view onto the navigation stack
    /// - Parameter viewPath: View to push
    func pushView(_ viewPath: ViewPath)
}

// MARK: - ENUMS

enum AuthState {
    case loginEmail
    case signUpEmail
    case forgotPassword
}

enum ProfileState {
    case viewProfile
    case editDisplayName
    case editEmail
}

enum UserDocumentKey: String {
    case email
    case emailVerified
    case displayName
}

enum AppAuthError: Error {
    case accountExistsWithDifferentCredential
    case credentialAlreadyInUse
    case emailAlreadyInUse
    case invalidCredential
    case invalidEmail
    case invalidFirstName
    case invalidPassword
    case invalidPasswordLength
    case invalidPhoneNumber
    case networkError
    case nullUser
    case otherError(Error) // If a different error is thrown, pass it's localized description to the enum.
    case passwordsDoNotMatch
    case reauthenticationRequired
    case rejectedCredential
    case userDisabled
    case userNotFound
    case weakPassword
    
    // Custom errors not directly related to FIRAuthErrors provided by Firebase
    case nullUserAfterSignIn
    
    var localizedDescription: String {
        switch self {
        case .accountExistsWithDifferentCredential: "Account exists with different credentials"
        case .credentialAlreadyInUse:               "Credential already in use"
        case .emailAlreadyInUse:                    "An account already exists with this email."
        case .invalidCredential:                    "Invalid credentials"
        case .invalidEmail:                         "Please enter a valid email."
        case .invalidFirstName:                     "Please enter a valid first name."
        case .invalidPassword:                      "Password was incorrect."
        case .invalidPasswordLength:                "Please make sure password is longer than 7 characters."
        case .invalidPhoneNumber:                   "Invalid phone number"
        case .networkError:                         "There was an issue with your connection. Please try again."
        case .nullUser:                             "Null user"
        case .otherError(let err):                  "AppAuthError.. An unknown error was thrown: \(err.localizedDescription)"
        case .passwordsDoNotMatch:                  "Passwords do not match."
        case .reauthenticationRequired:             "Reauthentication required for this action."
        case .rejectedCredential:                   "Rejected credentials"
        case .userDisabled:                         "User disabled"
        case .userNotFound:                         "User not found"
        case .weakPassword:                         "Weak password"
            
        case .nullUserAfterSignIn:                  "Auth user returned null after successful sign in."
        }
    }
}

enum ViewPath: Identifiable, Hashable {
    var id: ViewPath { return self }
    case landing, login, signUp, homepage, menuView, profileView
    case gameType(GameType)
    case level(Level)
    case game(Game)
}

// MARK: - User Model
import Firebase

struct User: Codable {
    let uid: String
    var email: String
    var displayName: String?
    let dateCreated: Date
    var emailVerified: Bool = false
    var finishedOnboarding: Bool = false
}

extension User: Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid
    }
}


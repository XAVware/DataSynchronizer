//
//  ContentView.swift
//  FireImp
//
//  Created by Ryan Smetana on 2/27/24.
//

import SwiftUI
import Foundation
import FirebaseAuth
import Combine


/// SessionManager --
/// If the view that is overlaying the alert is presented in a sheet, `.ignoresSafeArea(.all)` needs to be added to the AlertView, like this:
///
/// `.overlay(taskFeedbackService.alert != nil ? AlertView(alert: taskFeedbackService.alert!).ignoresSafeArea(.all) : nil, alignment: .top)`
///
/// Otherwise, if the view is presented in a FullScreenCover, the overlay should be the following:
///
///`.overlay(taskFeedbackService.alert != nil ? AlertView(alert: taskFeedbackService.alert!).ignoresSafeArea(.all) : nil, alignment: .top)`
///
// MARK: - Auth Funnel View
struct AuthFunnelView: View {
    @StateObject var vm = AuthViewClusterModel()
    @State private var email = ""
    
    var body: some View {
        NavigationStack {
            switch vm.currentState {
            case .loginEmail:       LoginView(email: $email)
            case .signUpEmail:      SignUpView(email: $email)
            case .forgotPassword:   ResetPasswordView(email: $email)
            }
        }
        .background(Color.bg100)
        .environmentObject(vm)
    }
    
}

#Preview {
    AuthFunnelView()
}

// MARK: - Login View
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AuthViewClusterModel
    
    @Binding private var email: String
    @State private var password = ""
    @State private var showPassword = false
    
    @FocusState private var focusField: FocusText?
    enum FocusText { case email, password }
    
    init(email: Binding<String>) {
        self._email = email
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            VStack(spacing: 16) {
                ThemeField(placeholder: "Email", boundTo: $email, iconName: "envelope")
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusField, equals: .email)
                    .onTapGesture { focusField = .email }
                    .onSubmit { focusField = nil }
                
                ThemeField(placeholder: "Password", boundTo: $password, iconName: "lock")
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.continue)
                    .focused($focusField, equals: .password)
                    .onTapGesture { focusField = .password }
                    .onSubmit { focusField = nil }
                
                HStack {
                    Spacer()
                    Button("Forgot Password?", action: forgotPasswordTapped)
                        .padding(.horizontal)
                } //: HStack
                .padding(.vertical, 8)
                
            } //: VStack
            .padding(.vertical)
            
            Button("Login", action: loginTapped)
                .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
            
            Divider()
            
            Button("Create an account", action: createAccountTapped)
                .ignoresSafeArea(.keyboard)
            
        } //: VStack
        .padding()
        .navigationTitle("Sign in")
        .tint(.accent)
        // If you want to making logging in optional:
        //        .toolbar(content: {
        //            ToolbarItem(placement: .topBarLeading) {
        //                Button("", systemImage: "xmark") {
        //                    dismiss()
        //                }
        //            }
        //        })
    } //: Body
    
    // MARK: - Functions
    private func loginTapped() {
        Task {
            await vm.login(withEmail: email, password: password)
        }
    }
    
    private func createAccountTapped() {
        vm.currentState = .signUpEmail
    }
    
    private func forgotPasswordTapped() {
        vm.currentState = .forgotPassword
    }
}

// MARK: - Reset Password View
struct ResetPasswordView: View {
    @EnvironmentObject var vm: AuthViewClusterModel
    @Binding private var email: String
    
    @FocusState private var focusField: FocusText?
    enum FocusText { case email }
    
    init(email: Binding<String>) {
        self._email = email
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ThemeField(placeholder: "Email", boundTo: $email, iconName: "envelope")
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
                .focused($focusField, equals: .email)
                .onTapGesture { focusField = .email }
                .onSubmit {
                    focusField = nil
                }
                .padding(.vertical)
            
            Spacer()
            
            Button("Send reset link", action: sendLinkTapped)
                .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
        } //: VStack
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Reset password")
        .tint(Color.accent)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemImage: "xmark", action: backTapped)
            }
        }
    } //: Body
    
    // MARK: - Functions
    private func sendLinkTapped() {
        SessionManager.shared.startLoading()
        Task {
            await vm.sendResetPasswordEmail(to: email)
            SessionManager.shared.stopLoading()
        }
    }
    
    private func backTapped() {
        vm.currentState = .loginEmail
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @Binding private var email: String
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @EnvironmentObject var vm: AuthViewClusterModel
    @FocusState private var focusField: FocusText?
    enum FocusText { case email, password, confirmPassword }
    
    init(email: Binding<String>) {
        self._email = email
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ThemeField(placeholder: "Email", boundTo: $email, iconName: "envelope")
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusField, equals: .email)
                    .onTapGesture { focusField = .email }
                    .onSubmit {
                        focusField = nil
                    }
                
                ThemeField(placeholder: "Password", boundTo: $password, iconName: "lock")
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusField, equals: .password)
                    .onTapGesture { focusField = .password }
                    .onSubmit {
                        focusField = .confirmPassword
                    }
                
                ThemeField(placeholder: "Confirm Password", boundTo: $confirmPassword, iconName: "lock")
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.continue)
                    .focused($focusField, equals: .confirmPassword)
                    .onTapGesture { focusField = .confirmPassword }
                    .onSubmit { createUser() }
            } //: VStack
            .padding(.vertical)
            
            Button("Create Account", action: createUser)
                .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
            
            Divider()
            
            Button("Back to sign in", action: backTapped)
                .buttonStyle(.borderless)
        } //: VStack
        .navigationTitle("Sign up")
        .tint(.accent)
        
    } //: Body
    
    // MARK: - Functions
    private func createUser() {
        Task {
            await vm.createUser(withEmail: email, password: password)
        }
    }
    
    private func backTapped() {
        vm.currentState = .loginEmail
    }
}


// MARK: - Profile View
import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject var vm: ProfileViewModel = ProfileViewModel()
    @Binding var navPath: [ViewPath]
    
    @State var user: User?
    
    var navTitleText: String {
        switch vm.currentState {
        case .viewProfile:      return "Profile"
        case .editDisplayName:  return "Edit Display Name"
        case .editEmail:        return "Edit Email"
        }
    }
    
    var body: some View {
        VStack {
            switch vm.currentState {
            case .viewProfile:
                profileView
                
            case .editDisplayName:
                EditDisplayNameView()
                    .environmentObject(vm)
                
            case .editEmail:
                EditEmailView()
                    .environmentObject(vm)
                    .padding()
            }
            Spacer()
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg100)
        .navigationTitle(navTitleText)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.large)
        .toolbar() {
            if vm.currentState == .viewProfile {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left", action: backTapped)
                    
                        .foregroundStyle(Color.accent)
                        .opacity(0.8)
                }
            }
        } //: Toolbar
        .onReceive(vm.$user) { newUser in
            user = newUser
        }
        .onReceive(vm.$reauthenticationRequired) { reqReauth in
            if reqReauth == true {
                vm.currentState = .viewProfile
                navPath.removeAll()
                AuthService.shared.signout()
            }
        }
    } //: Body
    
    private var profileView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Display Name:")
                .font(.headline)
            
            HStack {
                Text(vm.user?.displayName ?? "")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Add", systemImage: "plus", action: addDisplayNameTapped)
                    .opacity(0.6)
            } //: HStack
            
            Divider()
            
            HStack {
                let isVerified = vm.user?.emailVerified ?? false
                Text("Email:")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Image(systemName: isVerified ? "checkmark.circle.fill" : "slash.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                    
                    Text(isVerified ? "Verified" : "Not Verified")
                        .font(.caption)
                } //: HStack
                .foregroundStyle(isVerified ? .green : .gray)
            } //: HStack
            
            HStack {
                Text(verbatim: vm.user?.email ?? "")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Edit", action: editTapped)
                    .font(.callout)
                    .fontWeight(.light)
            } //: HStack
        } //: VStack
        .padding()
        .modifier(SubViewStyleMod())
        .foregroundStyle(.black)
        
    } //: Profile View
    
    // MARK: - Functions
    private func addDisplayNameTapped() {
        vm.changeView(to: .editDisplayName)
    }
    
    private func editTapped() {
        vm.changeView(to: .editEmail)
    }
    
    private func backTapped() {
        navPath.removeLast()
    }
}

#Preview {
    NavigationStack {
        ProfileView(navPath: .constant([]))
    }
}

// MARK: - Edit Email View
// TODO: Update email in Firestore after new email becomes verified.
// TODO: If user tries changing email to an email that already exists, don't sign the user out. Handle the error.
struct EditEmailView: View {
    @EnvironmentObject var vm: ProfileViewModel
    enum FocusText { case email }
    @FocusState private var focusField: FocusText?
    @State private var email: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            ThemeField(placeholder: "Email", boundTo: $email, iconName: "envelope")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.return)
                .focused($focusField, equals: .email)
                .onSubmit { focusField = nil }
                .onTapGesture { focusField = .email }
            
            Spacer()
            
            Button("Save", action: saveTapped)
                .buttonStyle(PrimaryButtonStyle())
            
            Button("Cancel", action: cancelTapped)
                .underline()
                .foregroundStyle(Color.textDark)
        } //: VStack
        .navigationTitle("Email")
    } //: Body
    
    // MARK: - Functions
    private func saveTapped() {
        Task {
            await vm.updateEmail(to: email)
        }
    }
    
    private func cancelTapped() {
        vm.changeView(to: .viewProfile)
    }
}

// MARK: - Edit Display Name View
// TODO: Display current name when view appears
struct EditDisplayNameView: View {
    @EnvironmentObject var vm: ProfileViewModel
    enum FocusText { case displayName }
    @FocusState private var focusField: FocusText?
    @State private var displayName: String = ""
    
    var body: some View {
        VStack {
            ThemeField(placeholder: "Display Name", boundTo: $displayName, iconName: "person.fill")
                .autocorrectionDisabled()
                .scrollDismissesKeyboard(.interactively)
                .textInputAutocapitalization(.words)
                .submitLabel(.return)
                .focused($focusField, equals: .displayName)
                .onSubmit { focusField = nil }
                .onTapGesture { focusField = .displayName }
            
            Spacer()
            
            Button("Save", action: saveTapped)
                .buttonStyle(PrimaryButtonStyle())
            
            Button("Cancel", action: cancelTapped)
                .underline()
                .padding(.vertical)
        } //: VStack
        .foregroundStyle(Color.textDark)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Display name")
    } //: Body
    
    // MARK: - Functions
    private func saveTapped() {
        Task {
            await vm.updateDisplayName(to: displayName)
        }
    }
    
    private func cancelTapped() {
        vm.changeView(to: .viewProfile)
    }
}

// MARK: - Theme Field

struct ThemeField: View {
    private let CORNER_RADIUS: CGFloat = 8
    
    private enum Focus { case secure, text }
    @FocusState private var focus: Focus?
    
    let placeholder: String
    let isSecure: Bool
    
    @Binding var boundTo: String
    @State var showPassword: Bool
    
    var iconName: String?
    
    init(placeholder: String, isSecure: Bool = false, boundTo: Binding<String>, iconName: String? = nil) {
        self.placeholder = placeholder
        self.isSecure = isSecure
        self._boundTo = boundTo
        self.iconName = iconName
        showPassword = !isSecure
    }
    
    private func toggleDisplayPassword() {
        showPassword.toggle()
        focus = isSecure ? .text : .secure
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.accent)
                } else {
                    Spacer()
                }
            }
            .frame(width: 16, height: 16)
            .padding(.horizontal)
            
            Group {
                if showPassword {
                    TextField(placeholder, text: $boundTo)
                } else {
                    SecureField(placeholder, text: $boundTo)
                }
            } //: Group
            .focused($focus, equals: showPassword ? .text : .secure)
            .foregroundStyle(Color.textDark)
            .padding(.vertical, 12)
            
            Group {
                if isSecure {
                    Button {
                        toggleDisplayPassword()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(Color.shadow300)
                    }
                } else {
                    Spacer()
                }
            }
            .frame(width: 16, height: 16)
            .padding(.horizontal)
            .padding(.trailing, 4)
        } //: HStack
        .frame(maxWidth: 360, maxHeight: 48)
        .background(Color.textLight)
        .clipShape(RoundedRectangle(cornerRadius: CORNER_RADIUS))
        .overlay(
            RoundedRectangle(cornerRadius: CORNER_RADIUS)
                .stroke(lineWidth: 0.5)
                .foregroundStyle(Color.shadow300)
        )
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Loading...")
                .font(.headline)
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg100)
    }
}

// MARK: - Onboarding View

import SwiftUI
import Speech
import AVFoundation

struct OnboardingView: View {
    @StateObject var vm: OnboardingViewModel = OnboardingViewModel()
    
    private var title: String {
        return switch vm.currentState {
        case .microphone: "Microphone"
        case .pushNotifications: "Push Notifications"
        }
    }
    
    private var description: String {
        return switch vm.currentState {
        case .microphone: "Please allow microphone access"
        case .pushNotifications: "Please allow push notifications."
        }
    }
    
    private var imageUrl: String {
        return switch vm.currentState {
        case .microphone: "AccessVoice"
        case .pushNotifications: "website"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 32) {
                Text(title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(imageUrl)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                
                Text(description)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            } //: VStack
            .padding(.top)
            
            Spacer()
            
            Button("Request Access", action: vm.nextTapped)
                .buttonStyle(PrimaryButtonStyle())
            
            Button("Not now", action: vm.incrementPage)
                .buttonStyle(.borderless)
        } //: VStack
        .padding()
        .background(Color.bg100)
    } //: Body
}


// MARK: - Menu View

struct MenuView: View {
    /// Menu components are equally spaced, `COMONENT_SPACING` ('x' from now on) away from eachother. The stack has 2x spacing. Stacked components (i.e. the Toggle label) have vertical padding of x.  The label in each component has x vertical padding.
    let COMPONENT_SPACING: CGFloat = 6
    @StateObject private var vm: MenuViewModel
    @StateObject var ENV: SessionManager = SessionManager.shared
    
    init(navPath: Binding<[ViewPath]>) {
        self._vm = StateObject(wrappedValue: MenuViewModel(navPath: navPath))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // 1. Account -- Only included if logged in, otherwise login/sign up button.
            VStack(spacing: COMPONENT_SPACING) {
                Button {
                    vm.pushView(.profileView)
                } label: {
                    Image(systemName: "person.fill")
                    Text("Profile")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, COMPONENT_SPACING)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .padding(.vertical, COMPONENT_SPACING)
            } //: VStack
            .padding(.horizontal)
            .padding(.vertical, 12)
            .modifier(SubViewStyleMod())
            
            Spacer()
            
            // 4. Sign Out
            Button("Sign Out", systemImage: "arrow.left.to.line.compact", action: vm.logOut)
                .foregroundStyle(Color.textDark)
                .padding()
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.textDark)
        .background(Color.bg100)
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    vm.navPath.removeLast()
                }
            } //: Toolbar Item
        } //: Toolbar
    } //: Body
    
}

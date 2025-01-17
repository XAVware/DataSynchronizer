/**
 * Fluency App Game Architecture
 *
 * A SwiftUI application for word and category-based verbal fluency games. The app supports
 * two main game types:
 * 1. Word Games - where users find words based on letter patterns (start with, end with, contains)
 * 2. Category Games - where users provide words that belong to specific categories
 *
 * The app uses Firebase Firestore for data storage and follows MVVM architecture.
 */

import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftData
import Combine


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct VerbalFluencyApp: App {
    let container: ModelContainer
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {        
        do {
            let schema = Schema([
                LocalGameType.self,
                LocalLevel.self,
                LocalGame.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = GameViewModel()

    @StateObject var vm = RootViewModel()
    @State var showLogin: Bool = AuthService.shared.user == nil
    @StateObject var session = SessionManager.shared
    
    var body: some View {
        ZStack {
            if session.isOnboarding == false {
                NavigationStack(path: $vm.navPath) {
                    GameTypeListView(gameTypes: viewModel.gameTypes, navPath: $vm.navPath)
                        .navigationDestination(for: ViewPath.self, destination: { gameDestination(for: $0) })
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Menu", systemImage: "line.horizontal.3", action: menuTapped)
                                    .buttonStyle(.borderless)
                                    .labelStyle(.iconOnly)
                            }
                        }
                        .navigationTitle("Home")
                } //: Navigation Stack
                .onAppear {
//                    clearLocalData()
                    Task { await refreshData() }
                }
            } else {
                LoadingView()
            }
            
        } //: ZStack
        .background(Color.bg100)
        .defaultAppStorage(.standard)
        .sheet(isPresented: $session.isOnboarding) {
            OnboardingView()
        }
        .onReceive(vm.$currentUser) { user in
            withAnimation {
                showLogin = user == nil
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { vm.currentUser == nil },
            set: { _ in }
        )) {
            AuthFunnelView()
                .overlay(session.isLoading ? LoadingView() : nil)
                .overlay(session.alert != nil ? AlertView(alert: session.alert!) : nil, alignment: .top)
        }
        
    } //: Body
    
    // MARK: - Functions
    private func menuTapped() {
        vm.pushView(.menuView)
    }
    
    private func refreshData() async {
        if viewModel.gameTypes.isEmpty {
            await viewModel.refreshGameData(context: modelContext)
        }
    }
    
    private func clearLocalData() {
        do {
            try LocalStorageManager().clearLocalGameTypes(context: modelContext)
            print("Local game types cleared")
        } catch {
            print("Error clearing local game types: \(error.localizedDescription)")
        }
    }
}

extension RootView {
    @ViewBuilder
    func gameDestination(for path: ViewPath) -> some View {
        switch path {
        case .menuView: MenuView(navPath: $vm.navPath)
        case .profileView: ProfileView(navPath: $vm.navPath)
        case .gameType(let gameType): LevelListView(gameType: gameType, navPath: $vm.navPath)
        case .level(let level): GameListView(level: level, navPath: $vm.navPath)
        case .game(let game): GamePlayView(game: game)
        default:
            Text("Error")
        }
    }
}

#Preview {
    RootView()
}

// MARK: - Root View Model
@MainActor
final class RootViewModel: RootViewModeling {
    @Published private(set) var currentUser: User?
    @Published var navPath: [ViewPath] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationService
    
    init() {
        self.authService = AuthService.shared
        self.currentUser = authService.user
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        guard let publisher = authService as? AuthService else { return }
        publisher.$user
            .receive(on: RunLoop.main)
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
    
    func pushView(_ viewPath: ViewPath) {
        navPath.append(viewPath)
    }
    
    func popView() {
        _ = navPath.popLast()
    }
}

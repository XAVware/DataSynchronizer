//
//  SyncApp.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/18/25.
//

// TODO: Right now games are being fetched every time the root appears, it should only be the first time, not when the menu closes back to Home

import Firebase
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SyncApp: App {
    let container: ModelContainer
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        do {
            let schema = Schema([
                LocalGameMode.self,
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

// New
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = SyncManager()
    @State private var localGameModes: [LocalGameMode] = []
    @State private var localGames: [LocalGame] = []
//    @StateObject private var viewModel = GameViewModel()
    
    @StateObject var vm = RootViewModel()
    @State var showLogin: Bool = AuthService.shared.user == nil
    @StateObject var session = SessionManager.shared
    
    var body: some View {
        Group {
            if session.isOnboarding == false {
                
                NavigationStack(path: $vm.navPath) {
                    GameModeListView(navPath: $vm.navPath)
                        .navigationDestination(for: ViewPath.self) { path in
                            gameDestination(for: path)
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Menu", systemImage: "line.horizontal.3", action: menuTapped)
                                    .buttonStyle(.borderless)
                                    .labelStyle(.iconOnly)
                            }
                        }
                    .navigationTitle("Local Data")
                    .task {
                        do {
                            let data = try await syncManager.fetchNewData()
                            let gameModes = data.0
                            let games = data.1
                            
                            print("\(games.count) updated since last sync:")
                            for game in games {
                                print(game.name)
                            }
                            
                            // Save gameModes (including child Level data) locally
                            try saveGameModes(gameModes)
                            
                            // Save games locally
                            try saveGames(games)
                        } catch {
                            print("Error syncing: \(error)")
                        }
                        await loadLocalData()

                    }
                }
            } else {
                LoadingView()
            }
        } //: Group
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
    }
    
    private func loadLocalData() async {
        do {
            // Fetch game modes
            let gameModeDescriptor = FetchDescriptor<LocalGameMode>()
            localGameModes = try modelContext.fetch(gameModeDescriptor)
            
            // Fetch games
            let gameDescriptor = FetchDescriptor<LocalGame>()
            localGames = try modelContext.fetch(gameDescriptor)
        } catch {
            print("Error loading local data: \(error)")
        }
    }
    
    private func saveGameModes(_ gameModes: [GameMode]) throws {
        // Clear existing game modes first
        try clearLocalGameTypes(context: modelContext)
        
        // Add new game modes and their levels
        for gameMode in gameModes {
            let localGameMode = LocalGameMode(from: gameMode)
            
            for level in gameMode.levels {
                let localLevel = LocalLevel(from: level)
                localLevel.gameMode = localGameMode
                localGameMode.levels.append(localLevel)
            }
            
            modelContext.insert(localGameMode)
        }
        try modelContext.save()
    }
    
    private func saveGames(_ games: [Game]) throws {
        for game in games {
            let fetchDescriptor = FetchDescriptor<LocalGame>(predicate: #Predicate { $0.id == game.id })
            if let existingGame = try? modelContext.fetch(fetchDescriptor).first {
                // Update existing game
                existingGame.name = game.name
                existingGame.locDescription = game.description
                existingGame.instructions = game.instructions
                existingGame.timeLimit = game.timeLimit ?? 60
                existingGame.type = game.mode.rawValue
                existingGame.gameModeId = game.gameModeId
                existingGame.levelId = game.levelId
                existingGame.updatedAt = game.updatedAt?.dateValue() ?? Date()
                if let wordGame = game as? WordGame {
                    existingGame.letterPosition = wordGame.letterPosition.rawValue
                    existingGame.targetLetter = wordGame.targetLetter
                } else if let categoryGame = game as? CategoryGame {
                    existingGame.answerBank = categoryGame.answerBank
                }
            } else {
                // Insert new game
                let localGame = LocalGame(from: game)
                modelContext.insert(localGame)
            }
        }
        try modelContext.save()
    }
    
    private func menuTapped() {
        vm.pushView(.menuView)
    }
    
    private func clearLocalGameTypes(context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalGameMode>()
        let existingGameModes = try context.fetch(descriptor)
        for gameMode in existingGameModes {
            context.delete(gameMode)
        }
        try context.save()
    }
}


extension RootView {
    @ViewBuilder
    func gameDestination(for path: ViewPath) -> some View {
        switch path {
        case .menuView:
            MenuView(navPath: $vm.navPath)
        case .profileView:
            ProfileView(navPath: $vm.navPath)
        case .gameMode(let gameMode):
            LevelListView(gameMode: gameMode, navPath: $vm.navPath)
        case .level(let level):
            GameListView(level: level, navPath: $vm.navPath)
        case .game(let game):
            GamePlayView(game: game)
        default:
            Text("Error")
        }
    }
}

#Preview {
    RootView()
}

import Combine

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


class SyncManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // Return the gameModes, levels, and games that need to be saved to modelContext
    func fetchNewData() async throws -> ([GameMode], [Game]) {
        let lastSyncDate = UserDefaults.standard.object(forKey: "mostRecentSync") as? Date
        // Fetch current GameModes and Levels data
        let gameModes: [GameMode] = await fetchGameModes()
        // Fetch games that have been updated after lastSyncDate. If lastSyncDate is nil, all games will be returned
        let games = try await fetchGames(since: lastSyncDate)
            
        // Once finished, update mostRecentSync in UserDefaults
        UserDefaults.standard.set(Date(), forKey: "mostRecentSync")
        
        return (gameModes, games)
    }
    
    func fetchGames(since lastSync: Date?) async throws -> [Game] {
        // Define a default date if `lastSync` is nil
        let defaultDateString = "01/01/2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        guard let defaultDate = formatter.date(from: defaultDateString) else {
            throw NSError(domain: "DateParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse default date"])
        }
        
        let date = lastSync ?? defaultDate
        print("Fetching games since: \(date)")
        
        var games: [Game] = []
        
        let snapshot = try await db.collection("games")
            .whereField("updatedAt", isGreaterThan: date)
            .getDocuments()
        
        for doc in snapshot.documents {
            let game = try convertGame(from: doc)
            games.append(game)
        }
        
        return games
    }

    func fetchGameModes() async -> [GameMode] {
        var gameModes: [GameMode] = []
        do {
            let snapshot = try await db.collection("gameModes").getDocuments()
            
            for document in snapshot.documents {
                let gameMode = try document.data(as: GameMode.self)
                gameMode.id = document.documentID
                gameMode.levels = try await fetchLevels(for: document.documentID)
                gameModes.append(gameMode)
            }
        } catch {
            print("Error fetching gameModes: \(error)")
        }
        return gameModes
    }
    
    func fetchLevels(for gameModeId: String) async throws -> [Level] {
        let snapshot = try await db.collection("gameModes")
            .document(gameModeId)
            .collection("levels")
            .getDocuments()
        
        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            levels.append(level)
        }
        return levels
    }
    
    func fetchGames(from refs: [DocumentReference]) async throws -> [Game] {
        var games: [Game] = []
        
        for ref in refs {
            let doc = try await ref.getDocument()
            let game = try convertGame(from: doc)
            games.append(game)
        }
        
        return games
    }
    
    func convertGame(from doc: DocumentSnapshot) throws -> Game  {
        guard let data = doc.data() else {
            print("Game document conversion error")
            throw URLError(.badURL)
        }
        
        let gameType = data["mode"] as? String ?? "unknown"
        
        let game: Game
        switch gameType {
        case "word":
            let wordGame = WordGame()
            wordGame.letterPosition = WordGame.LetterPosition(rawValue: data["letterPosition"] as? String ?? "start") ?? .start
            wordGame.targetLetter = data["targetLetter"] as? String ?? ""
            game = wordGame
            
        case "category":
            let categoryGame = CategoryGame()
            categoryGame.answerBank = data["answerBank"] as? [String] ?? []
            game = categoryGame
            
        default:
            game = Game()
        }
        
        game.id = doc.documentID
        game.name = data["name"] as? String ?? ""
        game.description = data["description"] as? String ?? ""
        game.instructions = data["instructions"] as? String ?? ""
        game.timeLimit = data["timeLimit"] as? Int ?? 60
        game.gameModeId = data["gameModeId"] as? String ?? ""
        game.levelId = data["levelId"] as? String ?? ""
        
        return game
    }
}

struct GameModeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List {
            ForEach(fetchGameModes()) { gameMode in
                Button {
                    navPath.append(.gameMode(gameMode))
                } label: {
                    VStack(alignment: .leading) {
                        Text(gameMode.name)
                            .font(.headline)
                        Text(gameMode.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Levels: \(gameMode.levels.count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Game Modes")
    }
    
    private func fetchGameModes() -> [LocalGameMode] {
        let descriptor = FetchDescriptor<LocalGameMode>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct LevelListView: View {
    let gameMode: LocalGameMode
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List {
            ForEach(gameMode.levels) { level in
                Button {
                    navPath.append(.level(level))
                } label: {
                    VStack(alignment: .leading) {
                        Text(level.name)
                            .font(.headline)
                        Text(level.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Time Limit: \(level.sugTimeLimit)s")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(gameMode.name)
    }
}

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    let level: LocalLevel
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List {
            ForEach(fetchGames()) { game in
                Button {
                    navPath.append(.game(game))
                } label: {
                    VStack(alignment: .leading) {
                        Text(game.name)
                            .font(.headline)
                        Text(game.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Time: \(game.timeLimit)s")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(level.name)
    }
    
    private func fetchGames() -> [LocalGame] {
        let levelId = level.id
        let descriptor = FetchDescriptor<LocalGame>(
            predicate: #Predicate<LocalGame> { game in
                game.levelId == levelId
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

//
//  RootView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
protocol NavigationManager: ObservableObject {
    func configureNavigation()
//    var navPath: [NavPath] { get set } // Try removing set
}

enum NavCommand: Identifiable, Hashable {
    var id: NavCommand { return self }
    case toRoot, popView
}

enum NavPath: Identifiable, Hashable {
    var id: NavPath { return self }
    case landing, login, signUp, homepage, menuView, profileView
    case gameMode(LocalGameMode)
    case level(LocalLevel)
    case game(LocalGame)
}

class NavService {
    let pathView = PassthroughSubject<NavPath, Never>()
    let commands = PassthroughSubject<NavCommand, Never>()
    static let shared = NavService()
    
    func push(newDisplay: NavPath) {
        pathView.send(newDisplay)
    }
    
    func popView() {
        commands.send(.popView)
    }
    
    func toRoot() {
        commands.send(.toRoot)
    }
}

extension RootViewModel: NavigationManager {
    func configureNavigation() {
        navService.commands
            .sink { [weak self] c in
                self?.handleCommand(c)
            }.store(in: &cancellables)
        
        navService.pathView
            .sink { [weak self] p in
                self?.pushView(p)
            }.store(in: &cancellables)
    }
    
    private func pushView(_ p: NavPath) {
        navPath.append(p)
    }
    
    private func handleCommand(_ command: NavCommand) {
        switch command {
        case .toRoot:
            navPath = .init()
        case .popView:
            popView()
        }
    }
    
    private func popView() {
        _ = navPath.removeLast()
    }
}

// MARK: - Root View Model
@MainActor
final class RootViewModel: RootViewModeling {
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationService
    @Published private(set) var currentUser: User?
    
    // Navigation Manager Properties
    private let navService = NavService.shared
    @Published var navPath: NavigationPath = .init()
    
    init() {
        self.authService = AuthService.shared
        self.currentUser = authService.user
        setupSubscribers()
        configureNavigation()
    }
    
    private func setupSubscribers() {
        guard let publisher = authService as? AuthService else { return }
        publisher.$user
            .receive(on: RunLoop.main)
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
}


// MARK: - Root View
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = SyncManager()
    @StateObject var vm = RootViewModel()
    @State var showLogin: Bool = AuthService.shared.user == nil
    @StateObject var session = SessionManager.shared
    @Query var gameModes: [LocalGameMode]
    @Query var localGames: [LocalGame]
    
    var body: some View {
        NavigationStack(path: $vm.navPath) {
            List {
                ForEach(gameModes) { gameMode in
                    Button {
                        NavService.shared.push(newDisplay: NavPath.gameMode(gameMode))
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
            .navigationDestination(for: NavPath.self) { path in
                gameDestination(for: path)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Menu", systemImage: "line.horizontal.3", action: menuTapped)
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                }
            }
            .task {
//                clearLocalData()
//                
                do {
                    let lastSyncDate = UserDefaults.standard.object(forKey: "mostRecentSync") as? Date
//                    let lastSyncDate = Date.earliestDate
                    
                    let data = try await syncManager.fetchData(since: lastSyncDate)
                    let dbGameModes = data.0
                    let gameResults = data.1
                    
                    // Save gameModes (including child Level data) locally
                    try saveGameModes(dbGameModes)
                    
                    // Save games locally
                    print("\(gameResults.count) updated since last sync:")
                    for game in gameResults {
                        print("Game requires update: \(game.name)")
                        if doesLocalGameExist(id: game.id ?? "") {
                            try updateGame(game: game)
                        } else {
                            try addGame(game: game)
                        }
                    }
                    
                } catch {
                    print("Error syncing: \(error)")
                }
            }
        }
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
    
    
    func doesLocalGameExist(id: String) -> Bool {
        let fetchRequest = FetchDescriptor<LocalGame>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let results = try modelContext.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Failed to fetch LocalGame: \(error)")
            return false
        }
    }
    
    private func saveGameModes(_ gameModes: [GameMode]) throws {
        let existingGameModes = try modelContext.fetch(FetchDescriptor<LocalGameMode>())
        for gameMode in existingGameModes {
            modelContext.delete(gameMode)
        }
        
        for gameMode in gameModes {
            let localGameMode = LocalGameMode(from: gameMode)
            modelContext.insert(localGameMode)
            
            for level in gameMode.levels {
                let localLevel = LocalLevel(from: level, gameMode: localGameMode)
                localGameMode.levels.append(localLevel)
            }
        }
        
        try modelContext.save()
    }
    
    private func addGame(game: Game) throws {
        let localGame = LocalGame(from: game)
        modelContext.insert(localGame)
        try modelContext.save()
    }
    
    private func updateGame(game: Game) throws {
        guard let id = game.id else {
            print("No ID found")
            return
        }
        
        let descriptor = FetchDescriptor<LocalGame>(predicate: #Predicate { $0.id == id })
        
        guard let existingGame = try modelContext.fetch(descriptor).first else {
            print("Error finding local game")
            return
        }
        print("Updating game: \(existingGame.name)")
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
    }
    
    
    private func menuTapped() {
        NavService.shared.push(newDisplay: NavPath.menuView)
    }
    
    private func clearLocalData() {
        do {
            let existingGameModes = try modelContext.fetch(FetchDescriptor<LocalGameMode>())
            for gameMode in existingGameModes {
                modelContext.delete(gameMode)
            }
            
            let existingGames = try modelContext.fetch(FetchDescriptor<LocalGame>())
            for game in existingGames {
                modelContext.delete(game)
            }
            
            try modelContext.save()
        } catch {
            print("Error clearing local data \(error)")
        }
    }
}


extension RootView {
    @ViewBuilder
    func gameDestination(for path: NavPath) -> some View {
        switch path {
        case .menuView:
            MenuView()
        case .profileView:
            ProfileView()
        case .gameMode(let gameMode):
            LevelListView(gameMode: gameMode)
        case .level(let level):
            GameListView(level: level)
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

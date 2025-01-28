//
//  RootView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData
import Combine


// MARK: - Root View
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = SyncManager()
    @Query var gameModes: [LocalGameMode]
    @Query var localGames: [LocalGame]
    
    @State var navigationService: NavigationService = NavigationService()
    
    var body: some View {
        NavigationStack(path: $navigationService.path) {
            List {
                ForEach(gameModes) { gameMode in
                    Button {
                        navigationService.push(NavPath.gameMode(gameMode))
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
                    Button("Menu", systemImage: "line.horizontal.3", action: { navigationService.push(.menu) })
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                }
            }
            .task {
//                clearLocalData()
                
               await refresh()
            }
        }
        .background(Color.bg100)
        .defaultAppStorage(.standard)
        .environment(navigationService)
    }
    
    func refresh() async {
        do {
            // Get last sync from UserDefaults
            let lastSyncDate = UserDefaults.standard.object(forKey: "mostRecentSync") as? Date
            
            // Passing Date.initialSync will fetch all games
            let data = try await syncManager.fetchData(since: lastSyncDate ?? Date.initialSync)
            let dbGameModes = data.0
            let gameResults = data.1
            
            // Once finished, update mostRecentSync in UserDefaults
            UserDefaults.standard.set(Date(), forKey: "mostRecentSync")
            
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
    
    // Check local database if game exists
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
    
    // Save game modes to local database
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
    
    // Add new game to local
    private func addGame(game: Game) throws {
        let localGame = LocalGame(from: game)
        modelContext.insert(localGame)
        try modelContext.save()
    }
    
    // Update existing local game
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
        case .gameMode(let gameMode):   LevelListView(gameMode: gameMode)
        case .level(let level):         GameListView(level: level)
        case .game(let game):           GamePlayView(game: game)
        case .soundTest:
            SoundView()
        case .menu: MenuView()
        default:
            Text("Error")
        }
    }
}

#Preview {
    RootView()
}

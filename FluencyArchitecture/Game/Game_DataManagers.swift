/*
import SwiftUI
import FirebaseFirestore
import SwiftData

@MainActor
final class GameDataService: GameDataServiceProtocol {
    static let shared = GameDataService()
    private let db = Firestore.firestore()
    
    func fetchGameTypes() async throws -> [GameType] {
        let snapshot = try await db.collection("gameTypes").getDocuments()
        var gameTypes: [GameType] = []
        
        for document in snapshot.documents {
            let gameType = try document.data(as: GameType.self)
            gameType.id = document.documentID
            gameType.levels = try await fetchLevels(for: document.documentID)
            gameTypes.append(gameType)
        }
        
        return gameTypes
    }
    
    func fetchLevels(for gameTypeId: String) async throws -> [Level] {
        print("Fetching levels for gameType: \(gameTypeId)")
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .getDocuments()
        
        print("Found \(snapshot.documents.count) levels")
        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            print("Level \(level.name) has \(level.gameRefs.count) game refs")
            level.games = try await fetchGames(from: level.gameRefs)
            print("Fetched \(level.games.count) games for level \(level.name)")
            levels.append(level)
        }
        return levels
    }
    
    func fetchGames(from refs: [DocumentReference]) async throws -> [Game] {
        var games: [Game] = []
        
        for ref in refs {
            let doc = try await ref.getDocument()
            if let data = doc.data() {
                let gameType = data["type"] as? String
                
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
                game.gameTypeId = data["gameTypeId"] as? String ?? ""
                game.levelId = data["levelId"] as? String ?? ""
                
                games.append(game)
            }
        }
        
        return games
    }
    
    func fetchUpdatedGames(since date: Date) async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("updatedAt", isGreaterThan: date)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let game = try? document.data(as: Game.self)
            game?.id = document.documentID
            return game
        }
    }
    
    func fetchCategoryAnswers(gameId: String) async throws -> [String] {
        let snapshot = try await db.collection("games")
            .document(gameId)
            .getDocument()
        
        guard let data = snapshot.data(),
              let answerBank = data["answerBank"] as? [String] else {
            throw NSError(domain: "GameDataService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid answer bank data"])
        }
        
        return answerBank
    }
}

extension GameDataService {
    func createGameFromDocument(_ document: QueryDocumentSnapshot) throws -> Game {
        let data = document.data()
        let gameType = data["type"] as? String
        
        let game: Game
        switch gameType {
        case "word":
            let wordGame = WordGame()
            if let positionStr = data["letterPosition"] as? String,
               let position = WordGame.LetterPosition(rawValue: positionStr) {
                wordGame.letterPosition = position
            }
            wordGame.targetLetter = data["targetLetter"] as? String ?? ""
            game = wordGame
            
        case "category":
            let categoryGame = CategoryGame()
            categoryGame.answerBank = data["answerBank"] as? [String] ?? []
            game = categoryGame
            
        default:
            game = Game()
        }
        
        game.id = document.documentID
        game.name = data["name"] as? String ?? ""
        game.description = data["description"] as? String ?? ""
        game.instructions = data["instructions"] as? String ?? ""
        game.timeLimit = data["timeLimit"] as? Int ?? 60
        game.caseSensitive = data["caseSensitive"] as? Bool ?? false
        game.gameTypeId = data["gameTypeId"] as? String ?? ""
        game.levelId = data["levelId"] as? String ?? ""
        game.createdAt = data["createdAt"] as? Timestamp
        game.updatedAt = data["updatedAt"] as? Timestamp
        
        return game
    }
}

final class LocalStorageManager: LocalStorageProtocol {
    func saveGameTypes(_ gameTypes: [GameType], context: ModelContext) throws {
        for gameType in gameTypes {
            print("Saving gameType: \(gameType.name) with \(gameType.levels.count) levels")
            let localGameType = LocalGameType(from: gameType)
            localGameType.levels = gameType.levels.map { level in
                print("Converting level: \(level.name) with \(level.games.count) games")
                let localLevel = LocalLevel(from: level)
                localLevel.gameType = localGameType
                
                localLevel.games = level.games.map { game in
                    let localGame = LocalGame(from: game)
                    localGame.level = localLevel
                    return localGame
                }
                
                return localLevel
            }
            context.insert(localGameType)
        }
        try context.save()
    }
    
    func saveGame(_ game: Game, context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalLevel>(
            predicate: #Predicate<LocalLevel> { $0.id == game.levelId }
        )
        
        guard let level = try context.fetch(descriptor).first else { return }
        
        if let existingGame = level.games.first(where: { $0.id == game.id }) {
            updateLocalGame(existingGame, with: game)
        } else {
            let localGame = createLocalGame(from: game, level: level)
            level.games.append(localGame)
        }
    }
    
    private func createLocalGameType(from gameType: GameType) -> LocalGameType {
        let localGameType = LocalGameType(from: gameType)
        localGameType.levels = gameType.levels.map { level in
            let localLevel = LocalLevel(from: level)
            localLevel.gameType = localGameType
            
            localLevel.games = level.games.map { game in
                let localGame = LocalGame(from: game)
                localGame.level = localLevel
                return localGame
            }
            
            return localLevel
        }
        return localGameType
    }
    
    private func createLocalGame(from game: Game, level: LocalLevel) -> LocalGame {
        let localGame = LocalGame()
        updateLocalGame(localGame, with: game)
        localGame.level = level
        return localGame
    }
    
    private func updateLocalGame(_ localGame: LocalGame, with game: Game) {
        localGame.id = game.id ?? UUID().uuidString
        localGame.name = game.name
        localGame.locDescription = game.description
        localGame.instructions = game.instructions
        localGame.timeLimit = game.timeLimit
        localGame.type = game.type.rawValue
        localGame.gameTypeId = game.gameTypeId
        localGame.levelId = game.levelId
        localGame.updatedAt = game.updatedAt?.dateValue() ?? Date()
        localGame.createdAt = game.createdAt?.dateValue() ?? Date()
        
        if let wordGame = game as? WordGame {
            localGame.letterPosition = wordGame.letterPosition.rawValue
            localGame.targetLetter = wordGame.targetLetter
            localGame.answerBank = nil
        } else if let categoryGame = game as? CategoryGame {
            localGame.letterPosition = nil
            localGame.targetLetter = nil
            localGame.answerBank = categoryGame.answerBank
        }
    }
    
    func clearLocalGameTypes(context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalGameType>()
        let existingGames = try context.fetch(descriptor)
        existingGames.forEach { context.delete($0) }
        try context.save()
    }
}

@MainActor
final class GameSyncService: GameSyncServiceProtocol {
    static let shared = GameSyncService()
    private let gameDataService: GameDataServiceProtocol
    private let localStorage: LocalStorageProtocol
    private let defaults = UserDefaults.standard
    
    private enum DefaultsKeys {
        static let lastSyncDate = "mostRecentSync"
    }
    
    init() {
        self.gameDataService = GameDataService.shared
        self.localStorage = LocalStorageManager()
    }
    
    func syncIfNeeded(context: ModelContext) async throws {
        let lastSync = defaults.object(forKey: DefaultsKeys.lastSyncDate) as? Date
        
        if lastSync == nil {
            // First time sync - download everything
            try await performFullSync(context: context)
        } else {
            // Incremental sync based on updatedAt timestamp
            try await checkForUpdates(since: lastSync!, context: context)
        }
        
        // Update sync timestamp
        defaults.set(Date(), forKey: DefaultsKeys.lastSyncDate)
    }
    
    func performFullSync(context: ModelContext) async throws {
        // Download all game types with their levels
        let gameTypes = try await gameDataService.fetchGameTypes()
        
        // Save to SwiftData
        try localStorage.saveGameTypes(gameTypes, context: context)
    }
    
    func checkForUpdates(since date: Date, context: ModelContext) async throws {
        let updatedGames = try await gameDataService.fetchUpdatedGames(since: date)
        print("Updated game results (\(updatedGames.count)): \(updatedGames)")
        
        if !updatedGames.isEmpty {
            // If there are updates, refresh all GameTypes and Levels first
            let gameTypes = try await gameDataService.fetchGameTypes()
            try localStorage.saveGameTypes(gameTypes, context: context)
            
            // Then update the specific games
            for game in updatedGames {
                try localStorage.saveGame(game, context: context)
            }
        }
    }
    
    private func fetchGameTypeForGame(_ game: Game) async throws -> GameType? {
        let gameTypes = try await gameDataService.fetchGameTypes()
        return gameTypes.first { $0.id == game.gameTypeId }
    }
}
*/

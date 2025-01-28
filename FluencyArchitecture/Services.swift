
import SwiftUI
import FirebaseFirestore

class SyncManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // Return the gameModes, levels, and games that need to be saved to modelContext
    func fetchData(since lastSyncDate: Date) async throws -> ([GameMode], [Game]) {
        // Fetch current GameModes and Levels data
        let gameModes: [GameMode] = await fetchGameModes()
        
        // Fetch games that have been updated after lastSyncDate. If lastSyncDate is nil, all games will be returned
        let games = try await fetchGames(since: lastSyncDate)
        
        return (gameModes, games)
    }
    
    // Fetch game modes from cloud DB
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
    
    // Fetch levels from cloud DB
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
    
    // Fetch games from Firestore that have been updated since the last local update.
    // If it's the user's first time, last sync will be Date.initialSync
    func fetchGames(since lastSync: Date) async throws -> [Game] {
        print("Fetching games since: \(lastSync)")
        // The above should be separated out of Cloud data service
        var games: [Game] = []
        
        let snapshot = try await db.collection("games")
            .whereField("updatedAt", isGreaterThan: lastSync)
            .getDocuments()
        
        for doc in snapshot.documents {
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

extension Date {
    static var initialSync: Date = {
        // Define a default date if `lastSync` is nil
        let defaultDateString = "01/01/2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: defaultDateString)!
    }()
}

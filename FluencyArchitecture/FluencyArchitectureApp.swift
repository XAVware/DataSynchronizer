
// TODO: Right now games are being fetched every time the root appears, it should only be the first time, not when the menu closes back to Home


/*
 sqlite3 "/Users/ryan/Library/Developer/CoreSimulator/Devices/2BFDF53A-1663-48C4-A8BE-354B165CFB35/data/Containers/Data/Application/A4217FA4-1BBE-4821-830E-34C635D6624B/Library/Application Support/default.store"
 */
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
struct FluencyArchitectureApp: App {
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




class SyncManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // Return the gameModes, levels, and games that need to be saved to modelContext
    func fetchData(since lastSyncDate: Date? = nil) async throws -> ([GameMode], [Game]) {
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

extension Date {
    static var earliestDate: Date = {
        // Define a default date if `lastSync` is nil
        let defaultDateString = "01/01/2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: defaultDateString)!
    }()
}

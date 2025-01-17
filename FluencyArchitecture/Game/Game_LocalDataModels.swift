import SwiftUI
import SwiftData
import FirebaseFirestore

/// Local storage model for game levels
@Model
final class LocalLevel {
    var id: String               // Unique identifier matching Firestore
    var name: String             // Level name (e.g., "Easy")
    var locDescription: String   // Level description
    var difficulty: Int          // Numeric difficulty rating
    var createdAt: Date
    var updatedAt: Date
    
    // Games available in this level
    @Relationship(deleteRule: .cascade) var games: [LocalGame]
    @Relationship(inverse: \LocalGameType.levels) var gameType: LocalGameType?
    
    /// Creates a local level from a Firestore model
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.difficulty = 1
        self.createdAt = Date()
        self.updatedAt = Date()
        self.games = []
    }
    
    convenience init(from level: Level) {
        self.init()
        self.id = level.id ?? UUID().uuidString
        self.name = level.name
        self.locDescription = level.description
        self.difficulty = level.difficulty
        self.createdAt = level.createdAt?.dateValue() ?? Date()
        self.updatedAt = level.updatedAt?.dateValue() ?? Date()
        self.games = []
    }
}

/// Local storage model for game types, used for offline caching
@Model
final class LocalGameType: Identifiable {
    var id: String                  // Unique identifier matching Firestore
    var name: String                // Display name (e.g., "Word Games")
    var locDescription: String      // Game type description
    var createdAt: Date
    var updatedAt: Date
    var lastSynced: Date
    
    // Collection of difficulty levels
    @Relationship(deleteRule: .cascade) var levels: [LocalLevel]
    
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastSynced = Date()
        self.levels = []
    }
    
    /// Creates a local game type from a Firestore model
    convenience init(from gameType: GameType) {
        self.init()
        self.id = gameType.id ?? UUID().uuidString
        self.name = gameType.name
        self.locDescription = gameType.description
        self.createdAt = gameType.createdAt?.dateValue() ?? Date()
        self.updatedAt = gameType.updatedAt?.dateValue() ?? Date()
        self.lastSynced = Date()
        self.levels = []
    }
}

extension LocalGameType: Hashable {
    static func == (lhs: LocalGameType, rhs: LocalGameType) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A SwiftData model representing a game stored locally on device
@Model
final class LocalGame: Identifiable {
    /// Unique identifier matching Firestore document ID
    var id: String
    
    /// Display name of the game
    var name: String
    
    /// Detailed description of the game
    var locDescription: String
    
    /// Instructions shown to player before starting
    var instructions: String
    
    /// Game duration in seconds
    var timeLimit: Int
    
    /// Whether answers should match case exactly
    var caseSensitive: Bool
    
    /// Type of game - either "word" or "category"
    var type: String
    
    /// When the game was first created
    var createdAt: Date
    
    /// When the game was last modified
    var updatedAt: Date
    
    /// For word games: where the target letter should appear (start/end/contains)
    var letterPositionString: String?
    
    /// For word games: the specific letter players need to use
    var targetLetter: String?
    
    /// Raw data storage for answer bank, encoded as JSON
    private var storedAnswerBankData: Data
    
    /// Whether the answer bank has been fetched from Firestore
    var answerBankLoaded: Bool
    
    /// When the answer bank was last updated from Firestore
    var answerBankLastUpdated: Date?
    
    /// Reference to parent level containing this game
    @Relationship var level: LocalLevel?
    
    /// Answer bank for category games, stored as encoded JSON data
    /// Provides array interface while storing as Data for SwiftData compatibility
    var storedAnswerBank: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: storedAnswerBankData)) ?? []
        }
        set {
            storedAnswerBankData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    /// Creates a new empty game with default values
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.instructions = ""
        self.timeLimit = 60
        self.caseSensitive = false
        self.type = "word"
        self.createdAt = Date()
        self.updatedAt = Date()
        self.storedAnswerBankData = Data()
        self.answerBankLoaded = false
    }
    
    /// Creates a local game from a Firestore Game model
    /// - Parameter game: Source game from Firestore
    convenience init(from game: Game) {
        self.init()
        self.id = game.id ?? UUID().uuidString
        self.name = game.name
        self.locDescription = game.description
        self.instructions = game.instructions
        self.timeLimit = game.timeLimit
        self.caseSensitive = game.caseSensitive
        self.type = game.type.rawValue
        self.createdAt = game.createdAt?.dateValue() ?? Date()
        self.updatedAt = game.updatedAt?.dateValue() ?? Date()
        
        if let wordGame = game as? WordGame {
            self.letterPositionString = wordGame.letterPosition.rawValue
            self.targetLetter = wordGame.targetLetter
            self.storedAnswerBank = []
        } else if let categoryGame = game as? CategoryGame {
            self.storedAnswerBank = categoryGame.answerBank
        } else {
            self.storedAnswerBank = []
        }
    }
}

extension LocalGame: Hashable {
    static func == (lhs: LocalGame, rhs: LocalGame) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

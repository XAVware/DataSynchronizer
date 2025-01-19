
/*
import SwiftUI
import FirebaseFirestore
import SwiftData

// MARK: - Firestore Models

class GameType: Identifiable, Codable {
    @DocumentID var id: String?              // Firestore document ID
    var name: String                         // Display name (e.g., "Word Games")
    var description: String                  // Game type description
    var levels: [Level] = []                 // Collection of difficulty levels
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.levels = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        levels = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
    
}


class Level: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var sugTimeLimit: Int
    var games: [Game] = []
    var gameRefs: [DocumentReference] = []
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, sugTimeLimit, gameRefs
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.sugTimeLimit = 60  // Default value
        self.games = []
        self.gameRefs = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Handle sugTimeLimit more flexibly
        if let timeLimit = try? container.decode(Int.self, forKey: .sugTimeLimit) {
            sugTimeLimit = timeLimit
        } else if let timeLimitString = try? container.decode(String.self, forKey: .sugTimeLimit),
                  let timeLimit = Int(timeLimitString) {
            sugTimeLimit = timeLimit
        } else {
            sugTimeLimit = 60  // Default value if parsing fails
        }
        
        gameRefs = try container.decode([DocumentReference].self, forKey: .gameRefs)
        games = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(sugTimeLimit, forKey: .sugTimeLimit)
        try container.encode(gameRefs, forKey: .gameRefs)
    }
}

class Game: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var instructions: String
    var timeLimit: Int
//    var caseSensitive: Bool
    var type: GameType
    var gameTypeId: String
    var levelId: String
    weak var level: Level?
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    enum GameType: String, Codable {
        case word, category
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.instructions = ""
        self.timeLimit = 60
//        self.caseSensitive = false
        self.type = .word
        self.gameTypeId = ""
        self.levelId = ""
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decodeIfPresent(String.self, forKey: .id)
//        name = try container.decode(String.self, forKey: .name)
//        description = try container.decode(String.self, forKey: .description)
//        instructions = try container.decode(String.self, forKey: .instructions)
//        timeLimit = try container.decode(Int.self, forKey: .timeLimit)
//        caseSensitive = try container.decodeIfPresent(Bool.self, forKey: .caseSensitive) ?? false
//        type = try container.decode(GameType.self, forKey: .type)
//        gameTypeId = try container.decode(String.self, forKey: .gameTypeId)
//        levelId = try container.decode(String.self, forKey: .levelId)
//        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt)
//        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
//    }
}

class WordGame: Game {
    var letterPosition: LetterPosition       // Where target letter should appear
    var targetLetter: String                 // The letter to match
    
    enum LetterPosition: String, Codable {
        case start, end, contains
    }
    
    // Additional coding keys for WordGame-specific properties
    private enum WordGameCodingKeys: String, CodingKey {
        case letterPosition, targetLetter
    }
    
    required init() {
        self.letterPosition = .start
        self.targetLetter = ""
        super.init()
        self.type = .word
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: WordGameCodingKeys.self)
        letterPosition = try container.decode(LetterPosition.self, forKey: .letterPosition)
        targetLetter = try container.decode(String.self, forKey: .targetLetter)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: WordGameCodingKeys.self)
        try container.encode(letterPosition, forKey: .letterPosition)
        try container.encode(targetLetter, forKey: .targetLetter)
    }
}

/**
 * Specific implementation for category-based games.
 * Players must enter words that belong to the specified category.
 */
class CategoryGame: Game {
    var answerBank: [String]                // Valid answers for the category
    
    private enum CategoryGameCodingKeys: String, CodingKey {
        case answerBank
    }
    
    required init() {
        self.answerBank = []
        super.init()
        self.type = .category
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CategoryGameCodingKeys.self)
        answerBank = try container.decode([String].self, forKey: .answerBank)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CategoryGameCodingKeys.self)
        try container.encode(answerBank, forKey: .answerBank)
    }
}


// MARK: - Local SwiftData Models
/// Local storage model for game types, used for offline caching
@Model
final class LocalGameType: Identifiable {
    var id: String                  // Unique identifier matching Firestore
    var name: String                // Display name (e.g., "Word Games")
    var locDescription: String      // Game type description
    
    // Collection of difficulty levels
    @Relationship(deleteRule: .cascade) var levels: [LocalLevel]
    
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.levels = []
    }
    
    /// Creates a local game type from a Firestore model
    convenience init(from gameType: GameType) {
        self.init()
        self.id = gameType.id ?? UUID().uuidString
        self.name = gameType.name
        self.locDescription = gameType.description
        self.levels = []
    }
}

@Model
final class LocalLevel {
    var id: String
    var name: String
    var locDescription: String
    var sugTimeLimit: Int
    @Relationship(deleteRule: .cascade) var games: [LocalGame]
    @Relationship(inverse: \LocalGameType.levels) var gameType: LocalGameType?
    
//    init(id: String, name: String, description: String, sugTimeLimit: Int) {
//        self.id = id
//        self.name = name
//        self.locDescription = description
//        self.sugTimeLimit = sugTimeLimit
//        self.games = []
//    }
    
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.sugTimeLimit = 60
        self.games = []
    }
    
    convenience init(from level: Level) {
        self.init()
        self.id = level.id ?? UUID().uuidString
        self.name = level.name
        self.locDescription = level.description
        self.sugTimeLimit = level.sugTimeLimit
        self.games = []
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
    
    /// Type of game - either "word" or "category"
    var type: String
    
    var gameTypeId: String
    var levelId: String
    
    
    /// When the game was first created
    var createdAt: Date
    
    /// When the game was last modified
    var updatedAt: Date
    
    /// For word games: where the target letter should appear (start/end/contains)
    var letterPosition: String?
    
    /// For word games: the specific letter players need to use
    var targetLetter: String?
    
    /// Raw data storage for answer bank, encoded as JSON
    private var storedAnswerBankData: Data
    
    /// Reference to parent level containing this game
    @Relationship var level: LocalLevel?
    
    var answerBank: [String]? {
        get { try? JSONDecoder().decode([String].self, from: storedAnswerBankData) }
        set { storedAnswerBankData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    
    // Previously...
    /// Answer bank for category games, stored as encoded JSON data
    /// Provides array interface while storing as Data for SwiftData compatibility
//    var storedAnswerBank: [String] {
//        get {
//            (try? JSONDecoder().decode([String].self, from: storedAnswerBankData)) ?? []
//        }
//        set {
//            storedAnswerBankData = (try? JSONEncoder().encode(newValue)) ?? Data()
//        }
//    }
//
   
    
//    init(id: String, name: String, description: String?, instructions: String,
//         timeLimit: Int?, type: String, gameTypeId: String, levelId: String,
//         createdAt: Date, updatedAt: Date) {
//        self.id = id
//        self.name = name
//        self.description = description
//        self.instructions = instructions
//        self.timeLimit = timeLimit
//        self.type = type
//        self.gameTypeId = gameTypeId
//        self.levelId = levelId
//        self.createdAt = createdAt
//        self.updatedAt = updatedAt
//        self.storedAnswerBankData = Data()
//    }
    
    
    /// Creates a new empty game with default values
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.instructions = ""
        self.timeLimit = 60
        self.type = "word"
        self.gameTypeId = ""
        self.levelId = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.storedAnswerBankData = Data()
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
        self.type = game.type.rawValue
        self.gameTypeId = game.gameTypeId
        self.levelId = game.levelId
        self.createdAt = game.createdAt?.dateValue() ?? Date()
        self.updatedAt = game.updatedAt?.dateValue() ?? Date()
        
        if let wordGame = game as? WordGame {
            self.letterPosition = wordGame.letterPosition.rawValue
            self.targetLetter = wordGame.targetLetter
        } else if let categoryGame = game as? CategoryGame {
            self.answerBank = categoryGame.answerBank
        }
    }
}


// MARK: - Firestore Model Equatable & Hashable Conformance
/*
 In order to be passed through `ViewPath`, the models need to be Hashable and Equatable.
 
 Since the DocumentIDs are optional Strings, I took a few extra precautions with the Hashable functions.
 
 Though Option A would cover most scenarios, I went with Option B. Using `Game` as an example,
 
 Option A:
 ```swift
 extension Game: Equatable, Hashable {
 func hash(into hasher: inout Hasher) {
 hasher.combine(id ?? UUID().uuidString) // Fallback to UUID if id is nil
 }
 
 static func == (lhs: Game, rhs: Game) -> Bool {
 let lhsId = lhs.id ?? UUID().uuidString
 let rhsId = rhs.id ?? UUID().uuidString
 return lhsId == rhsId
 }
 }
 ```
 
 Option B:
 ```swift
 extension Game: Equatable, Hashable {
 func hash(into hasher: inout Hasher) {
 hasher.combine(id ?? "")
 hasher.combine(name)
 hasher.combine(instructions)
 hasher.combine(gameTypeId)
 hasher.combine(levelId)
 hasher.combine(type)
 }
 
 // Equatable
 static func == (lhs: Game, rhs: Game) -> Bool {
 return lhs.id == rhs.id &&
 lhs.name == rhs.name &&
 lhs.instructions == rhs.instructions &&
 lhs.gameTypeId == rhs.gameTypeId &&
 lhs.levelId == rhs.levelId &&
 lhs.type == rhs.type
 }
 }
 ```
 
 Option A could cause unexpected behavior if there were a case like the following:
 
 ```swift
 let game1 = Game(id: nil)
 let game2 = Game(id: nil)
 print(game1 == game2) // false (unexpected)
 ```
 
 or even
 
 ```swift
 let game1 = Game(id: nil, name: "Only Game", createdAt: "2025-01-17 10:30:00")
 let game2 = Game(id: nil, name: "Only Game", createdAt: "2025-01-17 10:30:00")
 print(game1 == game2) // false (unexpected)
 ```
 
 With Option B, two Game objects are considered equal if all relevant properties are the same. Properties included in the equation can be easily ignored if needed in the future. To keep nil IDs consistent, an empty string is used as the fallback instead of a random ID.
 
 Though there is more code up front, Option B ensures that behavior is consistent, predictable, and customizable.
 */
extension GameType: Equatable, Hashable {
    static func == (lhs: GameType, rhs: GameType) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(description)
    }
}

extension Level: Equatable, Hashable {
    static func == (lhs: Level, rhs: Level) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.sugTimeLimit == rhs.sugTimeLimit
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(sugTimeLimit)
    }
}

extension Game: Equatable, Hashable {
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.instructions == rhs.instructions &&
        lhs.gameTypeId == rhs.gameTypeId &&
        lhs.levelId == rhs.levelId &&
        lhs.type == rhs.type
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(instructions)
        hasher.combine(gameTypeId)
        hasher.combine(levelId)
        hasher.combine(type)
    }
}
*/

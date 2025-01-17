
import Foundation
import FirebaseFirestore

// MARK: - Firestore Error
/**
 * Custom error types for Firestore operations:
 * - fetchError: Problems retrieving data from Firestore
 * - decodingError: Problems converting Firestore data to model objects
 * - invalidGameType: When game type data is malformed or unsupported
 */
enum FirestoreError: Error {
    case fetchError(String)
    case decodingError(String)
    case invalidGameType(String)
}


// MARK: - Game Type Model - Firestore
/**
 * Base class for game types (Word Games or Category Games).
 * Contains collections of levels and basic metadata.
 */
class GameType: Identifiable, Hashable, Codable {
    @DocumentID var id: String?              // Firestore document ID
    var name: String                         // Display name (e.g., "Word Games")
    var description: String                  // Game type description
    var levels: [Level] = []                 // Collection of difficulty levels
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, createdAt, updatedAt
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.levels = []
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) ?? Timestamp()
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) ?? Timestamp()
        levels = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // Hashable conformance for NavigationStack
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GameType, rhs: GameType) -> Bool {
        lhs.id == rhs.id
    }
}


/**
 * Represents a difficulty level within a game type.
 * Contains a collection of specific games at that difficulty.
 */
class Level: Identifiable, Hashable, Codable {
    @DocumentID var id: String?
    var name: String                        // Level name (e.g., "Easy")
    var description: String                 // Level description
    var difficulty: Int                     // Numeric difficulty (1 = Easy)
    var games: [Game] = []                  // Games at this level
    weak var gameType: GameType?
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, difficulty, createdAt, updatedAt
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.difficulty = 1
        self.games = []
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) ?? Timestamp()
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) ?? Timestamp()
        games = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Level, rhs: Level) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * Base class for individual games. Subclassed by WordGame and CategoryGame
 * to provide specific game mechanics.
 */
class Game: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var instructions: String                 // Player instructions
    var timeLimit: Int                       // Game duration in seconds
    var caseSensitive: Bool                  // Whether answers are case-sensitive
    var type: GameType                       // Word or Category game
    weak var level: Level?
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    enum GameType: String, Codable {
        case word, category
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, instructions, timeLimit, caseSensitive, type, createdAt, updatedAt
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.instructions = ""
        self.timeLimit = 60
        self.caseSensitive = false
        self.type = .word
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        instructions = try container.decode(String.self, forKey: .instructions)
        timeLimit = try container.decode(Int.self, forKey: .timeLimit)
        caseSensitive = try container.decode(Bool.self, forKey: .caseSensitive)
        type = try container.decode(GameType.self, forKey: .type)
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) ?? Timestamp()
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) ?? Timestamp()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(timeLimit, forKey: .timeLimit)
        try container.encode(caseSensitive, forKey: .caseSensitive)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? UUID().uuidString) // Fallback to UUID if id is nil
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        let lhsId = lhs.id ?? UUID().uuidString
        let rhsId = rhs.id ?? UUID().uuidString
        return lhsId == rhsId
    }
}

/**
 * Specific implementation for letter-based word games.
 * Players must enter words that match letter position rules.
 */
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

import FirebaseFirestore
import CryptoKit

struct GameMetadata: Codable {
    @DocumentID var id: String?
    let version: Int
    let lastModified: Timestamp
    let checksum: String
    let childrenCount: Int
    
    static func calculateChecksum(for games: [Game]) -> String {
        let gameString = games.map { game in
            "\(game.id ?? "")\(game.name)\(game.description)\(game.updatedAt?.seconds ?? 0)"
        }.sorted().joined()
        
        if let data = gameString.data(using: .utf8) {
            let digest = SHA256.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
}

struct LevelMetadata: Codable {
    @DocumentID var id: String?
    let version: Int
    let lastModified: Timestamp
    let checksum: String
    let childrenCount: Int
    let gameTypeId: String
    
    static func calculateChecksum(for level: Level) -> String {
        let levelString = "\(level.id ?? "")\(level.name)\(level.description)\(level.difficulty)"
        + level.games.map { game in
            "\(game.id ?? "")\(game.name)\(game.description)\(game.updatedAt?.seconds ?? 0)"
        }.sorted().joined()
        
        if let data = levelString.data(using: .utf8) {
            let digest = SHA256.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
}

struct GameTypeMetadata: Codable {
    @DocumentID var id: String?
    let version: Int
    let lastModified: Timestamp
    let checksum: String
    let childrenCount: Int
    
    static func calculateChecksum(for gameType: GameType) -> String {
        // Include base properties
        var contentToHash = "\(gameType.id ?? "")\(gameType.name)\(gameType.description)"
        
        // Include level data
        for level in gameType.levels.sorted(by: { ($0.id ?? "") < ($1.id ?? "") }) {
            contentToHash += "\(level.id ?? "")\(level.name)\(level.description)\(level.difficulty)"
            
            // Include game data
            for game in level.games.sorted(by: { ($0.id ?? "") < ($1.id ?? "") }) {
                contentToHash += "\(game.id ?? "")\(game.name)\(game.description)\(game.instructions)"
                
                // Include game-specific data
                if let categoryGame = game as? CategoryGame {
                    contentToHash += categoryGame.answerBank.sorted().joined()
                } else if let wordGame = game as? WordGame {
                    contentToHash += "\(wordGame.letterPosition.rawValue)\(wordGame.targetLetter)"
                }
            }
        }
        
        if let data = contentToHash.data(using: .utf8) {
            let digest = SHA256.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
}

/*
import Foundation
import FirebaseFirestore

 MARK: - GameDataModels
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

 MARK: - Local DataModels
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



extension LocalGame: Hashable {
    static func == (lhs: LocalGame, rhs: LocalGame) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

 MARK: - Protocols

import SwiftUI
import SwiftData
import Firebase

/**
 * Protocol for game data fetching operations.
 * Responsible for retrieving game data from cloud storage.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle network errors appropriately
 * - Must maintain consistent data structure
 */
@MainActor
protocol GameDataServiceProtocol {
    /// Fetches all available game types
    /// - Returns: Array of GameType objects
    /// - Throws: FirestoreError for fetch failures
    func fetchGameTypes() async throws -> [GameType]

    /// Fetches all levels for a specific game type
    /// - Parameter gameTypeId: ID of the game type
    /// - Returns: Array of Level objects
    /// - Throws: FirestoreError for fetch failures
    func fetchLevels(for gameTypeId: String) async throws -> [Level]

    /// Fetches all games for a specific level
    /// - Parameters:
    ///   - levelId: ID of the level
    ///   - gameTypeId: ID of the game type
    /// - Returns: Array of Game objects
    /// - Throws: FirestoreError for fetch failures
    func fetchGames(for levelId: String, gameTypeId: String) async throws -> [Game]

    func fetchUpdatedGames(since date: Timestamp) async throws -> [GameType]

    func fetchGameTypeMetadata() async throws -> [GameTypeMetadata]
    func fetchLevelMetadata(for gameTypeId: String) async throws -> [LevelMetadata]
    func fetchGameType(id: String) async throws -> GameType?
}

/**
 * Protocol for managing game data synchronization.
 * Coordinates between cloud and local storage for offline access.
 *
 * Implementation requirements:
 * - Must be MainActor compliant for UI updates
 * - Should handle sync scheduling
 * - Must maintain data consistency
 */
@MainActor
protocol GameSyncServiceProtocol {
    /// Checks and performs sync if needed based on timing or data state
    /// - Parameter context: SwiftData ModelContext for persistence
    /// - Throws: Error for sync failures
    func syncIfNeeded(context: ModelContext) async throws

    /// Forces a full sync of game data
    /// - Parameter context: SwiftData ModelContext for persistence
    /// - Throws: Error for sync failures
//    func sync(context: ModelContext) async throws
}

// MARK: - Game View Model Protocols

/**
 * Protocol for game list view model functionality.
 * Manages the display and refresh of available games.
 *
 * Implementation requirements:
 * - Must be ObservableObject for SwiftUI binding
 * - Should handle data refresh operations
 * - Must coordinate with GameSyncServiceProtocol
 */
@MainActor
protocol GameViewModeling: ObservableObject {
    /// Available game types
    var gameTypes: [GameType] { get set }

    /// Refreshes game data from storage
    /// - Parameter context: SwiftData ModelContext for persistence
    func refreshGameData(context: ModelContext) async
}

/**
 * Protocol for gameplay view model functionality.
 * Manages active game state and user interactions.
 *
 * Implementation requirements:
 * - Must be ObservableObject for SwiftUI binding
 * - Should handle game timing
 * - Must validate user input
 */
@MainActor
protocol GamePlayViewModeling: ObservableObject {
    /// Current user input text
    var userInput: String { get set }

    /// Remaining game time in seconds
    var timeRemaining: Int { get set }

    /// Whether a game is currently active
    var isGameActive: Bool { get set }

    /// List of valid answers provided by user
    var currentAnswers: [String] { get set }

    /// Starts a new game session
    func startGame()

    /// Ends the current game session
    func endGame()

    /// Processes a user-submitted answer
    func submitAnswer()

    /// Validates a potential answer
    /// - Parameter answer: Answer to validate
    /// - Returns: Whether the answer is valid
    func validateAnswer(_ answer: String) -> Bool
}

// MARK: - Game Model Protocols

/**
 * Protocol for game type model functionality.
 * Defines the structure for different categories of games.
 *
 * Implementation requirements:
 * - Must be Identifiable for SwiftUI lists
 * - Should be Codable for persistence
 * - Must maintain levels hierarchy
 */
protocol GameTypeProtocol: Identifiable, Hashable, Codable {
    /// Unique identifier
    var id: String? { get set }

    /// Display name
    var name: String { get set }

    /// Game type description
    var description: String { get set }

    /// Available difficulty levels
    var levels: [Level] { get set }

    var createdAt: Timestamp? { get set }
    var updatedAt: Timestamp? { get set }
}

/**
 * Protocol for game level model functionality.
 * Defines the structure for difficulty levels within game types.
 *
 * Implementation requirements:
 * - Must be Identifiable for SwiftUI lists
 * - Should be Codable for persistence
 * - Must maintain games collection
 */
protocol LevelProtocol: Identifiable, Hashable, Codable {
    /// Unique identifier
    var id: String? { get set }

    /// Level name
    var name: String { get set }

    /// Level description
    var description: String { get set }

    /// Difficulty rating
    var difficulty: Int { get set }

    /// Games available at this level
    var games: [Game] { get set }

    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

/**
 * Protocol for individual game model functionality.
 * Defines the base structure for all game types.
 *
 * Implementation requirements:
 * - Must be Identifiable for SwiftUI lists
 * - Should be Codable for persistence
 * - Must support game type differentiation
 */
protocol GameProtocol: Identifiable, Codable, Hashable {
    /// Unique identifier
    var id: String? { get set }

    /// Game name
    var name: String { get set }

    /// Game description
    var description: String { get set }

    /// Player instructions
    var instructions: String { get set }

    /// Time limit in seconds
    var timeLimit: Int { get set }

    /// Whether answers are case-sensitive
    var caseSensitive: Bool { get set }

    /// Type of game (word or category)
    var type: Game.GameType { get set }

    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

/**
 * Protocol for word-based game functionality.
 * Extends GameProtocol with word-specific features.
 *
 * Implementation requirements:
 * - Must implement GameProtocol
 * - Should handle letter positioning
 * - Must validate word-specific rules
 */
protocol WordGameProtocol: GameProtocol {
    /// Position rule for target letter
    var letterPosition: WordGame.LetterPosition { get set }

    /// Letter to match in words
    var targetLetter: String { get set }
}

/**
 * Protocol for category-based game functionality.
 * Extends GameProtocol with category-specific features.
 *
 * Implementation requirements:
 * - Must implement GameProtocol
 * - Should maintain answer bank
 * - Must validate category-specific rules
 */
protocol CategoryGameProtocol: GameProtocol {
    /// Valid answers for the category
    var answerBank: [String] { get set }
}

// MARK: - Storage Protocols

/**
 * Protocol for local data persistence operations.
 * Manages game data storage in SwiftData.
 *
 * Implementation requirements:
 * - Must handle SwiftData operations
 * - Should maintain data integrity
 * - Must support data migration
 */
protocol LocalStorageProtocol {
    /// Saves game types to local storage
    /// - Parameters:
    ///   - gameTypes: Game types to save
    ///   - context: SwiftData ModelContext
    /// - Throws: Error for save failures
    func saveGameTypes(_ gameTypes: [GameType], context: ModelContext) throws

    /// Fetches game types from local storage
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of locally stored game types
    /// - Throws: Error for fetch failures
    func fetchLocalGameTypes(context: ModelContext) throws -> [LocalGameType]

    /// Removes all game types from local storage
    /// - Parameter context: SwiftData ModelContext
    /// - Throws: Error for delete failures
    func clearLocalGameTypes(context: ModelContext) throws
}

 MARK: - ViewModels

@MainActor
final class GamePlayViewModel: GamePlayViewModeling {
    @Published var userInput = ""
    @Published var timeRemaining: Int
    @Published var isGameActive = false
    @Published var currentAnswers: [String] = []

    private let game: Game
    private var timer: Timer?

    init(game: Game) {
        self.game = game
        self.timeRemaining = game.timeLimit
    }

    func startGame() {
        isGameActive = true
        currentAnswers = []
        startTimer()
    }

    func endGame() {
        isGameActive = false
        timer?.invalidate()
    }

    func submitAnswer() {
        guard !userInput.isEmpty else { return }

        let answer = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if validateAnswer(answer) {
            currentAnswers.append(answer)
        }
        userInput = ""
    }

    func validateAnswer(_ answer: String) -> Bool {
        if let wordGame = game as? WordGame {
            return validateWordGameAnswer(answer, wordGame: wordGame)
        } else if let categoryGame = game as? CategoryGame {
            return validateCategoryGameAnswer(answer, categoryGame: categoryGame)
        }
        return false
    }

    private func validateWordGameAnswer(_ answer: String, wordGame: WordGame) -> Bool {
        let processedAnswer = wordGame.caseSensitive ? answer : answer.lowercased()
        let processedTarget = wordGame.caseSensitive ? wordGame.targetLetter : wordGame.targetLetter.lowercased()

        return switch wordGame.letterPosition {
        case .start:    processedAnswer.hasPrefix(processedTarget)
        case .end:      processedAnswer.hasSuffix(processedTarget)
        case .contains: processedAnswer.contains(processedTarget)
        }
    }

    private func validateCategoryGameAnswer(_ answer: String, categoryGame: CategoryGame) -> Bool {
        let processedAnswer = categoryGame.caseSensitive ? answer : answer.lowercased()
        let processedBank = categoryGame.answerBank.map {
            categoryGame.caseSensitive ? $0 : $0.lowercased()
        }
        return processedBank.contains(processedAnswer)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if self.timeRemaining > 0 && self.isGameActive {
                    self.timeRemaining -= 1
                } else {
                    timer.invalidate()
                    if self.timeRemaining == 0 {
                        self.endGame()
                    }
                }
            }
        }
    }
}

 MARK: - DataManagers

import SwiftUI
import FirebaseFirestore
import SwiftData

// MARK: - Game Data Service
/**
 * Manages Firestore fetch operations for the app.
 * Handles fetching and caching of game data.
 */
@MainActor
final class GameDataService: GameDataServiceProtocol {
    static let shared = GameDataService()
    private let db = Firestore.firestore()

    /**
     * Fetches all game types and their associated levels and games.
     * Data is fetched hierarchically:
     * GameTypes -> Levels -> Games
     */
    func fetchGameTypes() async throws -> [GameType] {
        let snapshot = try await db.collection("gameTypes").getDocuments()
        var gameTypes: [GameType] = []

        for document in snapshot.documents {
            do {
                let gameType = try document.data(as: GameType.self)
                gameType.id = document.documentID
                gameType.levels = try await fetchLevels(for: document.documentID)
                gameTypes.append(gameType)
            } catch {
                throw FirestoreError.decodingError("Failed to decode game type: \(error.localizedDescription)")
            }
        }

        return gameTypes
    }

    func fetchUpdatedGames(since timestamp: Timestamp) async throws -> [GameType] {
        let snapshot = try await db.collection("gameTypes")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()

        var updatedGames: [GameType] = []

        for document in snapshot.documents {
            let gameType = try document.data(as: GameType.self)
            gameType.id = document.documentID
            gameType.levels = try await fetchUpdatedLevels(for: document.documentID, since: timestamp)
            updatedGames.append(gameType)
        }

        return updatedGames
    }

    func fetchUpdatedLevels(for gameTypeId: String, since timestamp: Timestamp) async throws -> [Level] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()

        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            level.games = try await fetchUpdatedGames(for: gameTypeId,
                                                      levelId: document.documentID,
                                                      since: timestamp)
            levels.append(level)
        }
        return levels
    }

    private func fetchUpdatedGames(for gameTypeId: String,
                                   levelId: String,
                                   since timestamp: Timestamp) async throws -> [Game] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            let gameType = try document.data(as: Game.self).type
            var game: Game?

            switch gameType {
            case .word:
                let wordGame = try document.data(as: WordGame.self)
                wordGame.id = document.documentID
                game = wordGame
            case .category:
                let categoryGame = try document.data(as: CategoryGame.self)
                categoryGame.id = document.documentID
                game = categoryGame
            }

            return game
        }
    }

    /**
     * Fetches all levels for a specific game type.
     * Each level includes its collection of games.
     */
    func fetchLevels(for gameTypeId: String) async throws -> [Level] {
        guard !gameTypeId.isEmpty else { return [] }

        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .getDocuments()

        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            level.games = try await fetchGames(for: document.documentID, gameTypeId: gameTypeId)
            levels.append(level)
        }
        return levels


    }

    /**
     * Fetches games for a specific level.
     * Handles both WordGame and CategoryGame types through polymorphic decoding.
     */
    func fetchGames(for levelId: String, gameTypeId: String) async throws -> [Game] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            let gameType = try document.data(as: Game.self).type
            var game: Game?

            switch gameType {
            case .word:
                let wordGame = try document.data(as: WordGame.self)
                wordGame.id = document.documentID
                game = wordGame
            case .category:
                let categoryGame = try document.data(as: CategoryGame.self)
                categoryGame.id = document.documentID
                game = categoryGame
            }

            return game
        }
    }

    func fetchGameTypeMetadata() async throws -> [GameTypeMetadata] {
        let snapshot = try await db.collection("gameTypes").getDocuments()
        var metadata: [GameTypeMetadata] = []

        for document in snapshot.documents {
            let metadataSnapshot = try await document.reference
                .collection("metadata")
                .document("info")
                .getDocument()

            if var data = try? metadataSnapshot.data(as: GameTypeMetadata.self) {
                data.id = document.documentID  // Set the parent gameType ID
                metadata.append(data)
            }
        }

        return metadata
    }

    func fetchLevelMetadata(for gameTypeId: String) async throws -> [LevelMetadata] {
        var metadata: [LevelMetadata] = []
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .getDocuments()

        for document in snapshot.documents {
            let metadataSnapshot = try await document.reference
                .collection("metadata")
                .document("info")
                .getDocument()

            if let data = try? metadataSnapshot.data(as: LevelMetadata.self) {
                metadata.append(data)
            }
        }

        return metadata
    }

    func fetchGameType(id: String) async throws -> GameType? {
        let document = try await db.collection("gameTypes").document(id).getDocument()

        guard document.exists, let data = document.data() else {
            print("DEBUG: No data found for game type \(id)")
            return nil
        }

        let gameType = GameType()
        gameType.id = document.documentID
        gameType.name = data["name"] as? String ?? ""
        gameType.description = data["description"] as? String ?? ""
        gameType.createdAt = data["createdAt"] as? Timestamp ?? Timestamp()
        gameType.updatedAt = data["updatedAt"] as? Timestamp ?? Timestamp()
        gameType.levels = try await fetchLevels(for: document.documentID)

        return gameType
    }

    func fetchAnswerBank(for gameId: String, levelId: String, gameTypeId: String) async throws -> [String]? {
        let document = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .document(gameId)
            .getDocument()

        if let categoryGame = try? document.data(as: CategoryGame.self) {
            return categoryGame.answerBank
        }
        return nil
    }
}



final class LocalStorageManager: LocalStorageProtocol {
    func saveGameTypes(_ gameTypes: [GameType], context: ModelContext) throws {
        for gameType in gameTypes {
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
            context.insert(localGameType)
        }
        try context.save()
    }

    func fetchLocalGameTypes(context: ModelContext) throws -> [LocalGameType] {
        let descriptor = FetchDescriptor<LocalGameType>()
        return try context.fetch(descriptor)
    }

    func clearLocalGameTypes(context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalGameType>()
        let existingGames = try context.fetch(descriptor)
        existingGames.forEach { context.delete($0) }
        try context.save()
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

}

@MainActor
final class GameSyncService: GameSyncServiceProtocol {
    static let shared = GameSyncService()
    private let gameDataService: GameDataServiceProtocol
    private let localStorage: LocalStorageProtocol
    private let defaults = UserDefaults.standard

    private enum DefaultsKeys {
        static let lastSyncDate = "lastSyncDate"
        static let gameTypeChecksums = "gameTypeChecksums"
        static let levelChecksums = "levelChecksums"
    }

    init(localStorage: LocalStorageProtocol = LocalStorageManager()) {
        self.gameDataService = GameDataService.shared
        self.localStorage = localStorage
    }

    func syncIfNeeded(context: ModelContext) async throws {
        let localGames = try localStorage.fetchLocalGameTypes(context: context)

        if localGames.isEmpty {
            log("No local games found - performing full sync")
            try await performFullSync(context: context)
            return
        }

        // Check if we have stored checksums
        let storedChecksums = defaults.dictionary(forKey: DefaultsKeys.gameTypeChecksums) as? [String: String]
        if storedChecksums == nil {
            log("No stored checksums found - performing full sync")
            try await performFullSync(context: context)
            return
        }

        // Get metadata for all game types
        let gameTypeMetadata = try await gameDataService.fetchGameTypeMetadata()

        var needsSync = false
        for metadata in gameTypeMetadata {
            if storedChecksums![metadata.id ?? ""] != metadata.checksum {
                log("Checksum mismatch detected for game type \(metadata.id ?? "")")
                needsSync = true
                break
            }
        }

        if needsSync {
            log("Changes detected - performing incremental sync")
            try await performIncrementalSync(context: context)
        } else {
            log("No changes detected - skipping sync")
        }
    }

    private func performFullSync(context: ModelContext) async throws {
        try localStorage.clearLocalGameTypes(context: context)
        let gameTypes = try await gameDataService.fetchGameTypes()
        try localStorage.saveGameTypes(gameTypes, context: context)

        var checksums: [String: String] = [:]
        for gameType in gameTypes {
            if let id = gameType.id {
                checksums[id] = GameTypeMetadata.calculateChecksum(for: gameType)
            }
        }

        defaults.set(checksums, forKey: DefaultsKeys.gameTypeChecksums)
        defaults.set(Date(), forKey: DefaultsKeys.lastSyncDate)
    }

    private func updateLocalGameType(_ gameType: GameType, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<LocalGameType>(
            predicate: #Predicate<LocalGameType> { localType in
                localType.id == (gameType.id ?? "")
            }
        )

        let existingGame = try context.fetch(descriptor).first

        if let existing = existingGame {
            existing.name = gameType.name
            existing.locDescription = gameType.description
            try await updateLocalLevels(gameType.levels, for: existing)
        } else {
            let localGame = LocalGameType(from: gameType)
            context.insert(localGame)
        }

        try context.save()
    }

    private func updateLocalLevels(_ levels: [Level], for localGameType: LocalGameType) async throws {
        let levelMetadata = try await gameDataService.fetchLevelMetadata(for: localGameType.id)
        let storedLevelChecksums = defaults.dictionary(forKey: DefaultsKeys.levelChecksums) as? [String: String] ?? [:]

        for level in levels {
            if let id = level.id,
               let levelMeta = levelMetadata.first(where: { $0.id == id }),
               storedLevelChecksums[id] != levelMeta.checksum {
                if let existingLevel = localGameType.levels.first(where: { $0.id == id }) {
                    existingLevel.name = level.name
                    existingLevel.locDescription = level.description
                    existingLevel.difficulty = level.difficulty
                    updateLocalGames(level.games, for: existingLevel)
                } else {
                    let newLevel = LocalLevel(from: level)
                    newLevel.gameType = localGameType
                    newLevel.games = level.games.map { game in
                        let localGame = LocalGame(from: game)
                        localGame.level = newLevel
                        return localGame
                    }
                    localGameType.levels.append(newLevel)
                }
            }
        }

        var newLevelChecksums = storedLevelChecksums
        for metadata in levelMetadata {
            if let id = metadata.id {
                newLevelChecksums[id] = metadata.checksum
            }
        }
        defaults.set(newLevelChecksums, forKey: DefaultsKeys.levelChecksums)
    }

    private func updateLocalGames(_ games: [Game], for level: LocalLevel) {
        for game in games {
            if let id = game.id, let existingGame = level.games.first(where: { $0.id == id }) {
                existingGame.name = game.name
                existingGame.locDescription = game.description
                existingGame.instructions = game.instructions
                existingGame.timeLimit = game.timeLimit
                existingGame.caseSensitive = game.caseSensitive

                if let wordGame = game as? WordGame {
                    existingGame.letterPositionString = wordGame.letterPosition.rawValue
                    existingGame.targetLetter = wordGame.targetLetter
                } else if let categoryGame = game as? CategoryGame {
                    existingGame.storedAnswerBank = categoryGame.answerBank
                }
            } else {
                level.games.append(LocalGame(from: game))
            }
        }
    }
}

extension GameSyncService {
    private func log(_ message: String) {
        print("🔄 [GameSync] \(message)")
    }

    private func performIncrementalSync(context: ModelContext) async throws {
        log("Starting incremental sync")
        let gameTypeMetadata = try await gameDataService.fetchGameTypeMetadata()
        log("Firestore Metadata: \(gameTypeMetadata)")

        let storedChecksums = defaults.dictionary(forKey: DefaultsKeys.gameTypeChecksums) as? [String: String] ?? [:]

        log("Found \(gameTypeMetadata.count) game types in metadata")

        var newChecksums: [String: String] = [:]
        var downloadedGameTypes = 0
        var skippedGameTypes = 0

        for metadata in gameTypeMetadata {
            guard let metadataId = metadata.id?.replacingOccurrences(of: "/metadata/info", with: "") else { continue }
            print(metadata)

            if storedChecksums[metadataId] != metadata.checksum {
                log("📥 Game type \(metadataId) needs update - stored checksum: \(storedChecksums[metadataId] ?? "none"), new checksum: \(metadata.checksum)")
                if let gameType = try await gameDataService.fetchGameType(id: metadataId) {
                    try await updateLocalGameType(gameType, context: context)
                    newChecksums[metadataId] = metadata.checksum
                    downloadedGameTypes += 1
                }
            } else {
                log("⏭️ Skipping game type \(metadataId) - checksum unchanged")
                newChecksums[metadataId] = storedChecksums[metadataId]
                skippedGameTypes += 1
            }
        }

        log("Sync complete - Downloaded: \(downloadedGameTypes), Skipped: \(skippedGameTypes)")
        defaults.set(newChecksums, forKey: DefaultsKeys.gameTypeChecksums)
        defaults.set(Date(), forKey: DefaultsKeys.lastSyncDate)
    }
}


// Add UserDefaults extension for last sync management
extension UserDefaults {
    private enum Keys {
        static let lastSyncTimestamp = "lastSyncTimestamp"
        static let syncBackupTimestamp = "syncBackupTimestamp"
    }

    var lastSyncDate: Date? {
        get { date(forKey: Keys.lastSyncTimestamp) }
        set { set(newValue, forKey: Keys.lastSyncTimestamp) }
    }

    var backupSyncDate: Date? {
        get { date(forKey: Keys.syncBackupTimestamp) }
        set { set(newValue, forKey: Keys.syncBackupTimestamp) }
    }

    func updateSyncDates() {
        let now = Date()
        lastSyncDate = now
        backupSyncDate = now
    }
}

extension UserDefaults {
    func date(forKey key: String) -> Date? {
        return object(forKey: key) as? Date
    }
}
*/

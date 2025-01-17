//
//  Game_Protocols.swift
//  GameArchitecture
//
//  Created by Ryan Smetana on 1/7/25.
//

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

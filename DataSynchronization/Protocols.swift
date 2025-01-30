//
//  Protocols.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/28/25.
//

import SwiftUI
import FirebaseFirestore
import SwiftData

/// Defines the core functionality for data synchronization operations
@MainActor
protocol DataSyncProtocol {
    /// Synchronizes data with the remote source if needed
    /// - Returns: Void
    /// - Throws: DataSyncError
    func syncIfNeeded() async throws
    
    /// Forces an immediate data synchronization
    /// - Returns: Void
    /// - Throws: DataSyncError
    func forceSync() async throws
}

/// Defines error types for data synchronization
enum DataSyncError: Error {
    case contextUnavailable
    case networkError
    case invalidData
    case syncFailed(String)
}

// MARK: - Remote Data Service Protocols

/// Defines the interface for fetching data from remote sources
@MainActor
protocol RemoteDataServiceProtocol: ObservableObject {
    /// Fetches updated data since a specific date
    /// - Parameter lastSyncDate: Date of last successful sync
    /// - Returns: Tuple containing game modes and game documents
    func fetchData(since lastSyncDate: Date) async throws -> ([GameMode], [QueryDocumentSnapshot])
    
    /// Fetches all game modes from the remote source
    /// - Returns: Array of GameMode objects
    func fetchGameModes() async throws -> [GameMode]
    
    /// Fetches levels for a specific game mode
    /// - Parameter gameModeId: ID of the game mode
    /// - Returns: Array of Level objects
    func fetchLevels(for gameModeId: String) async throws -> [Level]
}

// MARK: - Local Data Service Protocols

/// Defines the interface for local data operations
@MainActor
protocol LocalDataServiceProtocol: ObservableObject {
    /// Sets the model context for local data operations
    /// - Parameter context: SwiftData ModelContext
    func setModelContext(_ context: ModelContext)
    
    /// Checks if a game exists locally
    /// - Parameter id: Game identifier
    /// - Returns: Boolean indicating existence
    func doesLocalGameExist(id: String) -> Bool
    
    /// Synchronizes a game with local storage
    /// - Parameter game: Game to synchronize
    func syncGame(game: Game)
    
    /// Saves game modes to local storage
    /// - Parameter gameModes: Array of GameMode objects
    /// - Throws: LocalDataError
    func saveGameModes(_ gameModes: [GameMode]) throws
    
    /// Clears all local data
    func clearLocalData()
}

/// Defines error types for local data operations
enum LocalDataError: Error {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case invalidModel
}

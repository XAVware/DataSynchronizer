//
//  GameDataService.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/22/25.
//

import SwiftUI
import FirebaseFirestore

class GameDataService: RemoteDataServiceProtocol {
    private let db = Firestore.firestore()
    static let shared = GameDataService()
    private init() { }
    
    func fetchData(since lastSyncDate: Date) async throws -> ([GameMode], [QueryDocumentSnapshot]) {
        let gameModes: [GameMode] = await fetchGameModes()
        let games = try await fetchGames(since: lastSyncDate)
        return (gameModes, games)
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
    
    // Fetch games from Firestore that have been updated since the last local update.
    // If it's the user's first time, last sync will be Date.initialSync
    private func fetchGames(since lastSync: Date) async throws -> [QueryDocumentSnapshot] {
        print("Fetching games since: \(lastSync)")
        let snapshot = try await db.collection("games")
            .whereField("updatedAt", isGreaterThan: lastSync)
            .getDocuments()
        
        return snapshot.documents
    }
}

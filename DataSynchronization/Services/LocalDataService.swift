//
//  LocalDataService.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/25/25.
//

import SwiftData
import SwiftUI

@MainActor
class LocalDataService: LocalDataServiceProtocol {
    static let shared = LocalDataService()
    private var modelContext: ModelContext?
    
    private init() { }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func doesLocalGameExist(id: String) -> Bool {
        guard let modelContext = modelContext else {
            print("Model context not available.")
            return false
        }
        
        let fetchRequest = FetchDescriptor<LocalGame>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let results = try modelContext.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Failed to fetch LocalGame: \(error)")
            return false
        }
    }
    
    func syncGame(game: Game) {
        do {
            if doesLocalGameExist(id: game.id ?? "") {
                try updateGame(game: game)
            } else {
                try addGame(game: game)
            }
            
        } catch {
            print("Error LocalDataService.syncGame: \(error)")
        }
    }
    
    private func addGame(game: Game) throws {
        guard let modelContext = modelContext else {
            print("addGame - Model context not available.")
            return
        }
        
        let localGame = LocalGame(from: game)
        modelContext.insert(localGame)
        try modelContext.save()
    }
    
    private func updateGame(game: Game) throws {
        guard let modelContext = modelContext else {
            print("updateGame - Model context not available.")
            return
        }
        
        guard let id = game.id else {
            print("No ID found")
            return
        }
        
        let descriptor = FetchDescriptor<LocalGame>(predicate: #Predicate { $0.id == id })
        
        guard let existingGame = try modelContext.fetch(descriptor).first else {
            print("Error finding local game")
            return
        }
        
        print("Updating game: \(existingGame.name)")
        existingGame.name = game.name
        existingGame.locDescription = game.description
        existingGame.instructions = game.instructions
        existingGame.timeLimit = game.timeLimit ?? 60
        existingGame.gameModeId = game.gameModeId
        existingGame.levelId = game.levelId
        existingGame.updatedAt = game.updatedAt?.dateValue() ?? Date()
        if let wordGame = game as? WordGame {
            existingGame.letterPosition = wordGame.letterPosition.rawValue
            existingGame.targetLetter = wordGame.targetLetter
        } else if let categoryGame = game as? CategoryGame {
            existingGame.answerBank = categoryGame.answerBank
        }
    }
    
    func saveGameModes(_ gameModes: [GameMode]) throws {
        guard let modelContext = modelContext else {
            print("saveGameModes - Model context not available.")
            return
        }
        
        let existingGameModes = try modelContext.fetch(FetchDescriptor<LocalGameMode>())
        for gameMode in existingGameModes {
            modelContext.delete(gameMode)
        }
        
        for gameMode in gameModes {
            let localGameMode = LocalGameMode(from: gameMode)
            modelContext.insert(localGameMode)
            
            for level in gameMode.levels {
                let localLevel = LocalLevel(from: level, gameMode: localGameMode)
                localGameMode.levels.append(localLevel)
            }
        }
        
        try modelContext.save()
    }
    
    func clearLocalData() {
        guard let modelContext = modelContext else {
            print("clearLocalData - Model context not available.")
            return
        }
        
        do {
            let existingGameModes = try modelContext.fetch(FetchDescriptor<LocalGameMode>())
            for gameMode in existingGameModes {
                modelContext.delete(gameMode)
            }
            
            let existingGames = try modelContext.fetch(FetchDescriptor<LocalGame>())
            for game in existingGames {
                modelContext.delete(game)
            }
            
            try modelContext.save()
        } catch {
            print("Error clearing local data \(error)")
        }
    }
}

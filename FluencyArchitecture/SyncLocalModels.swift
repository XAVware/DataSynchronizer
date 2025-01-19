//
//  SyncLocalModels.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/18/25.
//

import Foundation
import SwiftData

@Model
final class LocalGameMode: Identifiable {
    var id: String
    var name: String
    var locDescription: String
    
    @Relationship(deleteRule: .cascade) var levels: [LocalLevel]
    
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.levels = []
    }
    
    convenience init(from gameMode: GameMode) {
        self.init()
        self.id = gameMode.id ?? UUID().uuidString
        self.name = gameMode.name
        self.locDescription = gameMode.description
        self.levels = []
    }
}
@Model
final class LocalLevel {
    var id: String
    var name: String
    var locDescription: String
    var sugTimeLimit: Int
    
    private var storedGameRefs: Data
    @Relationship(inverse: \LocalGameMode.levels) var gameMode: LocalGameMode?
    
    // Computed property to access `gameRefs` as [String] - Resolves "Could not materialize Objective-C class named "Array" from declared attribute value type "Array<String>" of attribute named gameRefs" error
    var gameRefs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: storedGameRefs)) ?? []
        }
        set {
            storedGameRefs = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.sugTimeLimit = 60
        self.storedGameRefs = Data()
    }
    
    convenience init(from level: Level) {
        self.init()
        self.id = level.id ?? UUID().uuidString
        self.name = level.name
        self.locDescription = level.description
        self.sugTimeLimit = level.sugTimeLimit
        // Convert DocumentReference to strings (e.g., document IDs or paths)
        self.gameRefs = level.gameRefs.map { $0.documentID }
    }
}


@Model
final class LocalGame: Identifiable {
    var id: String
    var name: String
    var locDescription: String
    var instructions: String
    var timeLimit: Int
    /// Type of game - either "word" or "category"
    var type: String
    var gameModeId: String
    var levelId: String
    var createdAt: Date
    var updatedAt: Date
    
    /// For word games: where the target letter should appear (start/end/contains)
    var letterPosition: String?
    
    /// For word games: the specific letter players need to use
    var targetLetter: String?
    
    /// Raw data storage for answer bank, encoded as JSON
    private var storedAnswerBankData: Data
    
    var answerBank: [String]? {
        get { try? JSONDecoder().decode([String].self, from: storedAnswerBankData) }
        set { storedAnswerBankData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    /// Creates a new empty game with default values
    init() {
        self.id = UUID().uuidString
        self.name = ""
        self.locDescription = ""
        self.instructions = ""
        self.timeLimit = 60
        self.type = ""
        self.gameModeId = ""
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
        self.timeLimit = game.timeLimit ?? 77
        self.type = game.mode.rawValue
        self.gameModeId = game.gameModeId
        self.levelId = game.levelId
        self.createdAt = game.createdAt?.dateValue() ?? Date()
        self.updatedAt = game.updatedAt?.dateValue() ?? Date()
        
        if let wordGame = game as? WordGame {
            self.type = "word"
            self.letterPosition = wordGame.letterPosition.rawValue
            self.targetLetter = wordGame.targetLetter
        } else if let categoryGame = game as? CategoryGame {
            self.type = "category"
            self.answerBank = categoryGame.answerBank
        }
    }
}

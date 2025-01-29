//
//  LocalGame.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftData
import Foundation

@Model
final class LocalGame: Identifiable {
    var id: String
    var name: String
    var locDescription: String
    var instructions: String
    var timeLimit: Int
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
        self.id = ""
        self.name = ""
        self.locDescription = ""
        self.instructions = ""
        self.timeLimit = 60
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
        self.id = game.id!
        self.name = game.name
        self.locDescription = game.description
        self.instructions = game.instructions
        self.timeLimit = game.timeLimit ?? 77
        self.gameModeId = game.gameModeId
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

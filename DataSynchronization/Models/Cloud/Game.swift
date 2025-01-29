//
//  Game.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import FirebaseFirestore

class Game: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var instructions: String
    var timeLimit: Int?
    var mode: GameMode
    var gameModeId: String
    var levelId: String
    weak var level: Level?
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    enum GameMode: String, Codable {
        case word, category
    }
    
    required init() {
        self.name = ""
        self.description = ""
        self.instructions = ""
        self.timeLimit = 15
        self.mode = .word
        self.gameModeId = ""
        self.levelId = ""
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
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
        self.mode = .word
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

class CategoryGame: Game {
    var answerBank: [String]
    
    private enum CategoryGameCodingKeys: String, CodingKey {
        case answerBank
    }
    
    required init() {
        self.answerBank = []
        super.init()
        self.mode = .category
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

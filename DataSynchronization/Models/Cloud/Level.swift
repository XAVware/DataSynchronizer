//
//  Level.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import FirebaseFirestore

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
        self.sugTimeLimit = 60
        self.games = []
        self.gameRefs = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        sugTimeLimit = try container.decode(Int.self, forKey: .sugTimeLimit)
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

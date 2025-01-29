//
//  GameMode.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/18/25.
//

import SwiftUI
import FirebaseFirestore

class GameMode: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var levels: [Level]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, levels
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        let levelsDict = try container.decodeIfPresent([String: Level].self, forKey: .levels) ?? [:]
        levels = levelsDict.map { $0.value }
    }
}


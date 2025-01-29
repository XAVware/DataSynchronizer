//
//  LocalGameMode.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftData
import Foundation

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





//
//  LocalLevel.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftData
import Foundation

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
extension LocalLevel {
    convenience init(from level: Level, gameMode: LocalGameMode) {
        self.init()
        self.id = level.id ?? UUID().uuidString
        self.name = level.name
        self.locDescription = level.description
        self.sugTimeLimit = level.sugTimeLimit
        self.gameRefs = level.gameRefs.map { $0.documentID }
        self.gameMode = gameMode
    }
}

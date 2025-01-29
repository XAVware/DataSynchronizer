//
//  DataSynchronizer.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/26/25.
//

import SwiftUI
import FirebaseFirestore
import SwiftData

@MainActor
class DataSynchronizer {
    static let shared = DataSynchronizer()
    
    private let cloudService: GameDataService
    private let localService: LocalDataService
    
    private init() {
        self.cloudService = GameDataService.shared
        self.localService = LocalDataService.shared
    }
    
    func syncIfNeeded() async {
        do {
            let lastSyncDate = UserDefaults.standard.object(forKey: "mostRecentSync") as? Date
            // Check if lastSync was today - only allow one sync per day
            //            guard !Calendar.current.isDateInToday(lastSync) else {
            //                print("Already synced today")
            //                return
            //            }
            
            let (gameModes, gameDocuments) = try await cloudService.fetchData(since: lastSyncDate ?? .initialSync)
            let games = try gameDocuments.map({ try convertGame(from: $0) })
            
            try localService.saveGameModes(gameModes)
            
            for game in games {
                localService.syncGame(game: game)
            }
            
            UserDefaults.standard.set(Date(), forKey: "mostRecentSync")
        } catch {
            print("Error performing initial sync: \(error)")
        }
    }
    
    private func convertGame(from doc: DocumentSnapshot) throws -> Game  {
        guard let data = doc.data() else {
            print("Game document conversion error")
            throw URLError(.badURL)
        }
        
        let gameType = data["gameModeId"] as? String ?? "unknown"
        print("Game Type: \(gameType)")
        let game: Game
        switch gameType {
        case "word_game":
            let wordGame = WordGame()
            wordGame.letterPosition = WordGame.LetterPosition(rawValue: data["letterPosition"] as? String ?? "start") ?? .start
            wordGame.targetLetter = data["targetLetter"] as? String ?? ""
            game = wordGame
            
        case "category_game":
            let categoryGame = CategoryGame()
            categoryGame.answerBank = data["answerBank"] as? [String] ?? []
            game = categoryGame
            
        default:
            game = Game()
        }
        
        game.id = doc.documentID
        game.name = data["name"] as? String ?? ""
        game.description = data["description"] as? String ?? ""
        game.instructions = data["instructions"] as? String ?? ""
        game.timeLimit = data["timeLimit"] as? Int ?? 60
        game.gameModeId = data["gameModeId"] as? String ?? ""
        game.levelId = data["levelId"] as? String ?? ""
        
        return game
    }
    
    func forceSync() async {
        await syncIfNeeded()
    }
}

extension ModelContext {
    var sqliteCommand: String {
        if let url = container.configurations.first?.url.path(percentEncoded: false) {
            "sqlite3 \"\(url)\""
        } else {
            "No SQLite database found."
        }
    }
}

//
//  GameModeListView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData

struct LevelListView: View {
    let gameMode: LocalGameMode
    
    var body: some View {
        List {
            ForEach(gameMode.levels) { level in
                Button {
                    NavService.shared.push(newDisplay: NavPath.level(level))
                } label: {
                    VStack(alignment: .leading) {
                        Text(level.name)
                            .font(.headline)
                        Text(level.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Time Limit: \(level.sugTimeLimit)s")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(gameMode.name)
    }
}

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    let level: LocalLevel
    
    @Query var games: [LocalGame]
    
    init(level: LocalLevel) {
        self.level = level
    }
    
    var body: some View {
        List {
            ForEach(games.filter({ $0.levelId == level.id })) { game in
                Button {
                    NavService.shared.push(newDisplay: NavPath.game(game))
                } label: {
                    VStack(alignment: .leading) {
                        Text(game.name)
                            .font(.headline)
                        Text(game.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Time: \(game.timeLimit)s")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        } //: List
        .navigationTitle(level.name)
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

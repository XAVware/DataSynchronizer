//
//  GameListView.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData

struct GameListView: View {
    let level: LocalLevel
    @Query var games: [LocalGame]
    @Environment(NavigationService.self) var navigationService
    
    init(level: LocalLevel) {
        self.level = level
    }
    
    var body: some View {
        List {
            ForEach(games.filter({ $0.levelId == level.id })) { game in
                Button {
                    
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

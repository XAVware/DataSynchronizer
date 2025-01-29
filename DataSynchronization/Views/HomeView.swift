//
//  HomeView.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query var gameModes: [LocalGameMode]
    @Query var localGames: [LocalGame]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationService.self) var navigationService
    
    var body: some View {
        List {
            ForEach(gameModes) { gameMode in
                Button {
                    navigationService.push(NavPath.gameMode(gameMode))
                } label: {
                    VStack(alignment: .leading) {
                        Text(gameMode.name)
                            .font(.headline)
                        Text(gameMode.locDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Levels: \(gameMode.levels.count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } //: VStack
                }
            }
        } //: List
        .navigationTitle("Game Modes")
        .navigationDestination(for: NavPath.self) { path in
            gameDestination(for: path)
        }
    }
    
    @ViewBuilder
    func gameDestination(for path: NavPath) -> some View {
        switch path {
        case .gameMode(let gameMode):   LevelListView(gameMode: gameMode)
        case .level(let level):         GameListView(level: level)
        default: Text("fin")
        }
    }
}

#Preview {
    HomeView()
}

//
//  LevelListView.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI
import SwiftData

struct LevelListView: View {
    @Environment(NavigationService.self) var navigationService
    let gameMode: LocalGameMode
    
    var body: some View {
        List {
            ForEach(gameMode.levels) { level in
                Button {
                    navigationService.push(NavPath.level(level))
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
        } //: List
        .navigationTitle(gameMode.name)
    }
}





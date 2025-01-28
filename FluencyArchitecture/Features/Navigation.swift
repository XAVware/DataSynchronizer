//
//  Navigation.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/20/25.
//

import SwiftUI

enum NavPath: Identifiable, Hashable {
    var id: NavPath { return self }
    case landing, login, signUp, homepage, menuView, profileView
    case gameMode(LocalGameMode)
    case level(LocalLevel)
    case game(LocalGame)
}


@Observable
final class NavigationService {
    var path: [NavPath] = []
    
    func push(_ destination: NavPath) {
        path.append(destination)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
}

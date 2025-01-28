//
//  Navigation.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/20/25.
//

import SwiftUI

enum NavPath: Identifiable, Hashable {
    var id: NavPath { return self }
//    case landing, login, signUp, homepage, menuView, profileView
    case gameMode(LocalGameMode)
    case level(LocalLevel)
    case game(LocalGame)
    case soundTest
    case menu
}


@Observable
final class NavigationService {
    var path: [NavPath] = []
    
    func push(_ destination: NavPath, sender: NavPath? = nil) {
        if let sender = sender {
            print("NavigationService: \(sender) is pushing \(destination)")
        }
        path.append(destination)
    }
    
    func pop(sender: NavPath? = nil) {
        if let sender = sender {
            print("NavigationService: \(sender) is popping the current view.")
        }
            
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot(sender: NavPath? = nil) {
        if let sender = sender {
            print("NavigationService: \(sender) is popping to root.")
        }
        path.removeAll()
    }
}

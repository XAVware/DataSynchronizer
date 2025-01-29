//
//  DataSynchronizationApp.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/19/25.
//

import Firebase
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct DataSynchronizationApp: App {
    let container: ModelContainer
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var navigationService: NavigationService = NavigationService()
    
    init() {
        do {
            let schema = Schema([
                LocalGameMode.self,
                LocalLevel.self,
                LocalGame.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
            
            LocalDataService.shared.setModelContext(container.mainContext)
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationService.path) {
                HomeView()
            }
            .background(Color.bg100)
            .defaultAppStorage(.standard)
            .environment(navigationService)
            .task {
                await DataSynchronizer.shared.syncIfNeeded()
            }
        }
        .modelContainer(container)
    }
}



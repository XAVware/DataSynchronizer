
// TODO: Right now games are being fetched every time the root appears, it should only be the first time, not when the menu closes back to Home

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
struct FluencyArchitectureApp: App {
    let container: ModelContainer
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        do {
            let schema = Schema([
                LocalGameMode.self,
                LocalLevel.self,
                LocalGame.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
            
            // Preload sounds
            SoundService.shared.preloadSounds()
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}



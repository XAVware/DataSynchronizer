//
//  Sound.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/21/25.
//

import AVFoundation
import SwiftUI

/// Centralized service for managing and playing sounds throughout the app
final class SoundService {
    // MARK: - Singleton
    static let shared = SoundService()
    private init() { }
    
    // MARK: - Properties
    /// Dictionary to cache sound players for reuse
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    /// Current state of sound effects (enabled/disabled)
    private var isSoundEnabled: Bool = true
    
    // MARK: - Sound Effect Types
    enum SoundEffect: String {
        case wordSubmit = "word_submit"     // When a word is successfully submitted
        case wordInvalid = "word_invalid"   // When an invalid word is submitted
        case gameStart = "game_start"       // When a game begins
        case gameEnd = "game_end"           // When a game ends
        case buttonTap = "button_tap"       // General button tap sound
        case timerTick = "timer_tick"       // Timer countdown sound
        case levelComplete = "level_complete" // Level completion sound
    }
    
    // MARK: - Public Methods
    
    /// Plays a sound effect if sound is enabled
    /// - Parameter effect: The type of sound effect to play
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        if let player = audioPlayers[effect] {
            // Reuse existing player
            player.currentTime = 0
            player.play()
        } else {
            // Create and cache new player
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    audioPlayers[effect] = player
                    player.prepareToPlay()
                    player.play()
                } catch {
                    print("Error loading sound effect: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Enables or disables all sound effects
    /// - Parameter enabled: Whether sounds should be enabled
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "SoundEnabled")
    }
    
    /// Returns whether sound effects are currently enabled
    func isSoundEffectsEnabled() -> Bool {
        isSoundEnabled
    }
    
    /// Preloads all sound effects into memory
    func preloadSounds() {
        SoundEffect.allCases.forEach { effect in
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    audioPlayers[effect] = player
                    player.prepareToPlay()
                } catch {
                    print("Error preloading sound: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Releases all cached audio players to free up memory
    func cleanup() {
        audioPlayers.removeAll()
    }
}

// MARK: - CaseIterable Extension
extension SoundService.SoundEffect: CaseIterable { }

// MARK: - View Extension
extension View {
    /// Convenience method to play sounds from SwiftUI views
    func playSound(_ effect: SoundService.SoundEffect) {
        SoundService.shared.playSound(effect)
    }
}

// MARK: - Settings View Model Extension
/// Example of how to integrate with app settings
class SettingsViewModel: ObservableObject {
    @Published var isSoundEnabled: Bool {
        didSet {
            SoundService.shared.setSoundEnabled(isSoundEnabled)
        }
    }
    
    init() {
        self.isSoundEnabled = UserDefaults.standard.bool(forKey: "SoundEnabled")
    }
}

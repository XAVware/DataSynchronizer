//
//  SoundView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/21/25.
//

import SwiftUI

struct SoundView: View {
    @State private var isSoundEnabled: Bool = UserDefaults.standard.bool(forKey: "SoundEnabled")
    
    var body: some View {
        List {
            Section("Settings") {
                Toggle("Enable Sounds", isOn: $isSoundEnabled)
                    .onChange(of: isSoundEnabled) { newValue in
                        SoundService.shared.setSoundEnabled(newValue)
                    }
            }
            
            Section("Test Sounds") {
                ForEach(SoundService.SoundEffect.allCases, id: \.self) { effect in
                    Button {
                        SoundService.shared.playSound(effect)
                    } label: {
                        HStack {
                            Text(effect.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            Spacer()
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Section("Sound Combinations") {
                Button("Play Game Sequence") {
                    Task {
                        SoundService.shared.playSound(.gameStart)
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        SoundService.shared.playSound(.timerTick)
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        SoundService.shared.playSound(.wordSubmit)
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        SoundService.shared.playSound(.gameEnd)
                    }
                }
            }
        }
        .navigationTitle("Sound Test")
    }
}

#Preview {
    NavigationStack {
        SoundView()
    }
}

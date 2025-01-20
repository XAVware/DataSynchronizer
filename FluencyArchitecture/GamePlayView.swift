//
//  GamePlayView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/18/25.
//

import SwiftUI

class GameState: ObservableObject {
    @Published var score = 0
    @Published var currentAnswers: [Answer] = []
    @Published var timeRemaining: Int
    @Published var isActive = false
    @Published var showResults = false
    
    let game: LocalGame
    private var timer: Timer?
    
    struct Answer: Identifiable {
        let id = UUID()
        let text: String
        let isValid: Bool
        let timestamp: Date
    }
    
    init(game: LocalGame) {
        self.game = game
        self.timeRemaining = game.timeLimit
    }
    
    func startGame() {
        isActive = true
        score = 0
        currentAnswers = []
        timeRemaining = game.timeLimit
        startTimer()
    }
    
    func endGame() {
        isActive = false
        timer?.invalidate()
        showResults = true
    }
    
    func submitAnswer(_ answer: String) {
        let isValid = validateAnswer(answer)
        score += isValid ? 1 : 0
        
        currentAnswers.append(Answer(
            text: answer,
            isValid: isValid,
            timestamp: Date()
        ))
        
        UINotificationFeedbackGenerator().notificationOccurred(
            isValid ? .success : .error
        )
    }
    
    private func validateAnswer(_ answer: String) -> Bool {
        let processedAnswer = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't allow duplicate answers
        if currentAnswers.contains(where: { $0.text.lowercased() == processedAnswer }) {
            return false
        }
        
        if game.type == "word" {
            guard let targetLetter = game.targetLetter?.lowercased(), let position = game.letterPosition else { return false }
            
            return switch position {
            case "start":       processedAnswer.hasPrefix(targetLetter)
            case "end":         processedAnswer.hasSuffix(targetLetter)
            case "contains":    processedAnswer.contains(targetLetter)
            default:            false
            }
        } else {
            guard let answerBank = game.answerBank else { return false }
            return answerBank.map { $0.lowercased() }
                .contains(processedAnswer)
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 && self.isActive {
                self.timeRemaining -= 1
                if self.timeRemaining % 10 == 0 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } else {
                timer.invalidate()
                if self.timeRemaining == 0 {
                    self.endGame()
                }
            }
        }
    }
}

struct GameResultsView: View {
    let gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Complete!")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Score: \(gameState.score)")
                    .font(.headline)
                
                Text("Answers:")
                    .font(.headline)
                
                ForEach(gameState.currentAnswers) { answer in
                    HStack {
                        Image(systemName: answer.isValid ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(answer.isValid ? .green : .red)
                        Text(answer.text)
                    }
                }
            }
            .padding()
            
            Button("Play Again") {
                gameState.showResults = false
                gameState.startGame()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Exit") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct GamePlayView: View {
    let game: LocalGame
    @StateObject private var gameState: GameState
    @State private var userInput = ""
    @Environment(\.dismiss) private var dismiss
    
    init(game: LocalGame) {
        self.game = game
        _gameState = StateObject(wrappedValue: GameState(game: game))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            gameHeader
            timerView
            gameContent
            inputArea
            answersGrid
            gameControlButton
            CustomKeyboard { key in
                handleKeyPress(key)
            }
            .frame(maxHeight: 280)
        }
        .padding()
        .background(Color.bg500)
        .sheet(isPresented: $gameState.showResults) {
            GameResultsView(gameState: gameState)
        }
    }
    
    private var gameHeader: some View {
        VStack {
            Text(game.name)
                .font(.title)
            Text(game.instructions)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    private var timerView: some View {
        HStack {
            Text(timeString(from: gameState.timeRemaining))
                .font(.largeTitle)
                .monospacedDigit()
            
            if gameState.isActive {
                Text("Score: \(gameState.score)")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
    }
    
    @ViewBuilder
    private var gameContent: some View {
        if game.type == "word" {
            WordGameContent(
                targetLetter: game.targetLetter ?? "",
                letterPosition: game.letterPosition ?? "start"
            )
        } else {
            CategoryGameContent(
                answerCount: game.answerBank?.count ?? 0
            )
        }
    }
    
    private var inputArea: some View {
        HStack {
            Spacer()
            Text(userInput)
                .frame(width: 260, height: 42)
                .background(Color.bg300)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.shadow300, lineWidth: 1.0))
                .disabled(!gameState.isActive)
            
            Spacer()
            Button("Submit") {
                submitAnswer()
            }
            .disabled(!gameState.isActive || userInput.isEmpty)
            Spacer()
        }
        .padding()
    }
    
    private var answersGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(gameState.currentAnswers) { answer in
                    Text(answer.text)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(answer.isValid ?
                                    Color.green.opacity(0.2) :
                                        Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 120)
    }
    
    private var gameControlButton: some View {
        Button(gameState.isActive ? "End Game" : "Start Game") {
            if gameState.isActive {
                gameState.endGame()
            } else {
                gameState.startGame()
            }
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
    
    private func handleKeyPress(_ key: String) {
        if key == "DELETE" {
            if !userInput.isEmpty {
                userInput.removeLast()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else {
            userInput += key
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func submitAnswer() {
        guard !userInput.isEmpty else { return }
        let answer = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        gameState.submitAnswer(answer)
        userInput = ""
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct WordGameContent: View {
    let targetLetter: String
    let letterPosition: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Target Letter: \(targetLetter)")
                .font(.title2)
            Text("Position: \(letterPosition.capitalized)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct CategoryGameContent: View {
    let answerCount: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Category Game")
                .font(.title2)
            Text("\(answerCount) possible answers")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

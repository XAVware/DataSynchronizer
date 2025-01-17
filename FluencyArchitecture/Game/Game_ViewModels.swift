//
//  Game_ViewModels.swift
//  GameArchitecture
//
//  Created by Ryan Smetana on 1/7/25.
//

import SwiftUI
import SwiftData
import FirebaseFirestore
/**
 * ViewModel that manages the game data state and refreshing:
 * - Maintains the list of available game types
 * - Handles data fetching from GameDataManager
 * - Updates the UI when new data is available
 */
@MainActor
final class GameViewModel: GameViewModeling {
    @Published var gameTypes: [GameType] = []
    private let syncService: GameSyncServiceProtocol
    
    init() {
        self.syncService = GameSyncService.shared
    }
    
    func refreshGameData(context: ModelContext) async {
        do {
            try await syncService.syncIfNeeded(context: context)
            let descriptor = FetchDescriptor<LocalGameType>()
            let localGames = try context.fetch(descriptor)
            gameTypes = localGames.compactMap(localToGameType)
        } catch {
            print("Error refreshing game data: \(error)")
        }
    }
    
    private func localToGameType(_ local: LocalGameType) -> GameType {
        let gameType = GameType()
        gameType.id = local.id
        gameType.name = local.name
        gameType.description = local.locDescription
        gameType.createdAt = Timestamp(date: local.createdAt)
        gameType.updatedAt = Timestamp(date: local.updatedAt)
        
        gameType.levels = local.levels.map { localLevel -> Level in
            let level = Level()
            level.id = localLevel.id
            level.name = localLevel.name
            level.description = localLevel.locDescription
            level.difficulty = localLevel.difficulty
            level.createdAt = Timestamp(date: localLevel.createdAt)
            level.updatedAt = Timestamp(date: localLevel.updatedAt)
            
            level.games = localLevel.games.compactMap { localGame -> Game in
                let baseGame: Game
                switch localGame.type {
                case "word":
                    let wordGame = WordGame()
                    wordGame.letterPosition = WordGame.LetterPosition(rawValue: localGame.letterPositionString ?? "start") ?? .start
                    wordGame.targetLetter = localGame.targetLetter ?? ""
                    baseGame = wordGame
                case "category":
                    let categoryGame = CategoryGame()
                    categoryGame.answerBank = localGame.storedAnswerBank
                    baseGame = categoryGame
                default:
                    let game = Game()
                    game.type = .word
                    baseGame = game
                }
                
                baseGame.id = localGame.id
                baseGame.name = localGame.name
                baseGame.description = localGame.locDescription
                baseGame.instructions = localGame.instructions
                baseGame.timeLimit = localGame.timeLimit
                baseGame.caseSensitive = localGame.caseSensitive
                baseGame.createdAt = Timestamp(date: localGame.createdAt)
                baseGame.updatedAt = Timestamp(date: localGame.updatedAt)
                
                return baseGame
            }
            
            return level
        }
        
        return gameType
    }
}
@MainActor
final class GamePlayViewModel: GamePlayViewModeling {
    @Published var userInput = ""
    @Published var timeRemaining: Int
    @Published var isGameActive = false
    @Published var currentAnswers: [String] = []
    
    private let game: Game
    private var timer: Timer?
    
    init(game: Game) {
        self.game = game
        self.timeRemaining = game.timeLimit
    }
    
    func startGame() {
        isGameActive = true
        currentAnswers = []
        startTimer()
    }
    
    func endGame() {
        isGameActive = false
        timer?.invalidate()
    }
    
    func submitAnswer() {
        guard !userInput.isEmpty else { return }
        
        let answer = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if validateAnswer(answer) {
            currentAnswers.append(answer)
        }
        userInput = ""
    }
    
    func validateAnswer(_ answer: String) -> Bool {
        if let wordGame = game as? WordGame {
            return validateWordGameAnswer(answer, wordGame: wordGame)
        } else if let categoryGame = game as? CategoryGame {
            return validateCategoryGameAnswer(answer, categoryGame: categoryGame)
        }
        return false
    }
    
    private func validateWordGameAnswer(_ answer: String, wordGame: WordGame) -> Bool {
        let processedAnswer = wordGame.caseSensitive ? answer : answer.lowercased()
        let processedTarget = wordGame.caseSensitive ? wordGame.targetLetter : wordGame.targetLetter.lowercased()
        
        return switch wordGame.letterPosition {
        case .start:    processedAnswer.hasPrefix(processedTarget)
        case .end:      processedAnswer.hasSuffix(processedTarget)
        case .contains: processedAnswer.contains(processedTarget)
        }
    }
    
    private func validateCategoryGameAnswer(_ answer: String, categoryGame: CategoryGame) -> Bool {
        let processedAnswer = categoryGame.caseSensitive ? answer : answer.lowercased()
        let processedBank = categoryGame.answerBank.map {
            categoryGame.caseSensitive ? $0 : $0.lowercased()
        }
        return processedBank.contains(processedAnswer)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 && self.isGameActive {
                    self.timeRemaining -= 1
                } else {
                    timer.invalidate()
                    if self.timeRemaining == 0 {
                        self.endGame()
                    }
                }
            }
        }
    }
}

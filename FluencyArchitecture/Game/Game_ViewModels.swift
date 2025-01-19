/*
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
            print("Starting refreshGameData...")
            try await syncService.syncIfNeeded(context: context)
            
            print("Fetching local game types...")
            let descriptor = FetchDescriptor<LocalGameType>()
            let localGames = try context.fetch(descriptor)
            print("Found \(localGames.count) local game types")
            
            if localGames.isEmpty {
                print("Performing full sync...")
                try await syncService.performFullSync(context: context)
                let updatedLocalGames = try context.fetch(descriptor)
                print("After full sync: Found \(updatedLocalGames.count) local game types")
                gameTypes = updatedLocalGames.compactMap(localToGameType)
            } else {
                gameTypes = localGames.compactMap(localToGameType)
            }
        } catch {
            print("Error refreshing game data: \(error)")
        }
    }
    
    private func localToGameType(_ local: LocalGameType) -> GameType {
        print("Converting local game type: \(local.name)")
        let gameType = GameType()
        gameType.id = local.id
        gameType.name = local.name
        gameType.description = local.locDescription
        
        gameType.levels = local.levels.map { localLevel -> Level in
            let level = Level()
            level.id = localLevel.id
            level.name = localLevel.name
            level.description = localLevel.locDescription
            level.sugTimeLimit = localLevel.sugTimeLimit
            
            level.games = localLevel.games.map { localGame -> Game in
                return convertLocalGameToGame(localGame)
            }
            
            return level
        }
        
        return gameType
    }
    
    private func convertLocalGameToGame(_ localGame: LocalGame) -> Game {
        let game: Game
        // Check actual type from stored data
        if localGame.type == "category" {
            let categoryGame = CategoryGame()
            categoryGame.answerBank = localGame.answerBank ?? []
            game = categoryGame
        } else {
            let wordGame = WordGame()
            wordGame.letterPosition = WordGame.LetterPosition(rawValue: localGame.letterPosition ?? "start") ?? .start
            wordGame.targetLetter = localGame.targetLetter ?? ""
            game = wordGame
        }
        
        print("Creating Game: \(game.gameTypeId)-\(game.levelId)- \(game.name)")
        
        game.id = localGame.id
        game.name = localGame.name
        game.description = localGame.locDescription
        game.instructions = localGame.instructions
        game.timeLimit = localGame.timeLimit
        game.gameTypeId = localGame.gameTypeId
        game.levelId = localGame.levelId
        game.type = localGame.type == "category" ? .category : .word
        
        return game
    }
}

import SwiftUI
import FirebaseFirestore

@MainActor
final class GamePlayViewModel: ObservableObject {
    @Published var userInput = ""
    @Published var timeRemaining: Int
    @Published var isGameActive = false
    @Published var currentAnswers: [String] = []
    @Published var isLoadingAnswers = false
    @Published var loadError: String?
    
    private let game: Game
    private var timer: Timer?
    
    init(game: Game) {
        self.game = game
        self.timeRemaining = game.timeLimit
    }
    
    func loadAnswers() async {
        guard let categoryGame = game as? CategoryGame else { return }
        
        isLoadingAnswers = true
        do {
            let answerBank = try await GameDataService.shared.fetchCategoryAnswers(gameId: game.id ?? "")
            categoryGame.answerBank = answerBank
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingAnswers = false
    }
    
    func startGame() {
        isGameActive = true
        timeRemaining = game.timeLimit
        currentAnswers = []
        startTimer()
    }
    
    func endGame() {
        isGameActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func submitAnswer() {
        guard !userInput.isEmpty else { return }
        
        let answer = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if validateAnswer(answer) && !currentAnswers.contains(answer) {
            currentAnswers.append(answer)
        } else {
        }
        userInput = ""
    }
    
    func handleKeyPress(_ key: String) {
        guard isGameActive else { return }
        
        if key == "DELETE" {
            if !userInput.isEmpty {
                userInput.removeLast()
            }
        } else {
            userInput += key
        }
    }
    
    private func validateAnswer(_ answer: String) -> Bool {
        if let wordGame = game as? WordGame {
            return validateWordGameAnswer(answer, wordGame: wordGame)
        } else if let categoryGame = game as? CategoryGame {
            return validateCategoryGameAnswer(answer, categoryGame: categoryGame)
        }
        return false
    }
    
    private func validateWordGameAnswer(_ answer: String, wordGame: WordGame) -> Bool {
        let processedAnswer = answer.lowercased()
        let processedTarget = wordGame.targetLetter.lowercased()
        
        return switch wordGame.letterPosition {
        case .start:    processedAnswer.hasPrefix(processedTarget)
        case .end:      processedAnswer.hasSuffix(processedTarget)
        case .contains: processedAnswer.contains(processedTarget)
        }
    }
    
    private func validateCategoryGameAnswer(_ answer: String, categoryGame: CategoryGame) -> Bool {
        let processedAnswer = answer.lowercased()
        let processedBank = categoryGame.answerBank.map { $0.lowercased() }
        return processedBank.contains(processedAnswer)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 && self.isGameActive {
                    self.timeRemaining -= 1
                    if self.timeRemaining == 0 {
                        self.endGame()
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
*/

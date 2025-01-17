
import SwiftUI
import SwiftData

/**
 * Displays the list of available game types (Word Games, Category Games).
 */
struct GameTypeListView: View {
    let gameTypes: [GameType]
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List(gameTypes) { gameType in
            Button {
                navPath.append(.gameType(gameType))
            } label: {
                VStack(alignment: .leading) {
                    Text(gameType.name)
                        .font(.headline)
                    Text(gameType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/**
 * Displays available levels (Easy, Medium, Hard) for a selected game type.
 */
struct LevelListView: View {
    let gameType: GameType
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List(gameType.levels) { level in
            Button {
                navPath.append(.level(level))
            } label: {
                VStack(alignment: .leading) {
                    Text(level.name)
                        .font(.headline)
                    Text("Difficulty: \(level.difficulty)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(gameType.name)
    }
}

/**
 * Displays individual games available at the selected difficulty level.
 */
struct GameListView: View {
    let level: Level
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List(level.games) { game in
            Button {
                navPath.append(.game(game))
            } label: {
                VStack(alignment: .leading) {
                    Text(game.name)
                        .font(.headline)
                    Text(game.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(level.name)
    }
}


// MARK: - Game Play View
struct GamePlayViewTest: View {
    // Create sample games for preview
    static var sampleWordGame: WordGame {
        let game = WordGame()
        game.id = "test-word-game"
        game.name = "Start with 'S'"
        game.description = "Find words that start with the letter S"
        game.instructions = "Enter words that begin with the letter S"
        game.timeLimit = 60
        game.caseSensitive = false
        game.type = .word
        game.letterPosition = .start
        game.targetLetter = "S"
        return game
    }
    
    static var sampleCategoryGame: CategoryGame {
        let game = CategoryGame()
        game.id = "test-category-game"
        game.name = "Animals"
        game.description = "Name different animals"
        game.instructions = "Enter names of different animals"
        game.timeLimit = 60
        game.caseSensitive = false
        game.type = .category
        game.answerBank = ["dog", "cat", "elephant", "giraffe", "lion", "tiger"]
        return game
    }
    
    var body: some View {
        // You can switch between word and category game previews here
        GamePlayView(game: Self.sampleWordGame)
            .background(Color.bg100)
    }
}

#Preview {
    GamePlayViewTest()
}


/**
 * GamePlayView manages the core gameplay experience for both word and category games.
 * It handles user input, timing, answer validation, and score tracking in a unified interface
 * while supporting game-specific mechanics through polymorphism.
 *
 * The view maintains several pieces of state:
 * - userInput: Current text being entered by the user
 * - timeRemaining: Countdown timer for the game session
 * - isGameActive: Whether a game is currently in progress
 * - currentAnswers: List of valid answers provided by the user
 */
struct GamePlayView: View {
    let game: Game
    @State private var userInput = ""
    @State private var timeRemaining: Int
    @State private var isGameActive = false
    @State private var currentAnswers: [String] = []
    @State private var isLoadingAnswers = false
    @State private var loadError: String?
    
    init(game: Game) {
        self.game = game
        _timeRemaining = State(initialValue: game.timeLimit)
    }
    
    var body: some View {
        Group {
            if isLoadingAnswers {
                ProgressView("Loading answers...")
            } else if let error = loadError {
                Text("Error: \(error)")
            } else {
                gameContent
            }
        }
        .task {
            if let _ = game as? CategoryGame {
                isLoadingAnswers = true
                do {
                    try await loadAnswerBank()
                } catch {
                    loadError = error.localizedDescription
                }
                isLoadingAnswers = false
            }
        }
    }
    
    private func loadAnswerBank() async throws {
        if let categoryGame = game as? CategoryGame,
           let levelId = game.level?.id,
           let gameTypeId = game.level?.gameType?.id {
            let answerBank = try await GameDataService.shared.fetchAnswerBank(
                for: game.id ?? "",
                levelId: levelId,
                gameTypeId: gameTypeId
            )
            if let answerBank = answerBank {
                categoryGame.answerBank = answerBank
            }
        }
    }
    
    private var gameContent: some View {
        VStack(spacing: 12) {
            // Game Header section displays the title and instructions
            VStack {
                Text(game.name)
                    .font(.title)
                Text(game.instructions)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            // Timer Display shows remaining time in MM:SS format
            Text(timeString(from: timeRemaining))
                .font(.largeTitle)
                .monospacedDigit()
            
            // Polymorphic game content based on game type
            /**
             * Determines which game-specific content to display based on the game type.
             * Uses type casting to provide appropriate UI for word or category games.
             */
            if let wordGame = game as? WordGame {
                WordGameContent(game: wordGame)
            } else if let categoryGame = game as? CategoryGame {
                CategoryGameContent(game: categoryGame)
            }
            
            // Input Area for user answers
            HStack {
                Spacer()
                Text(userInput)
                    .frame(width: 260, height: 42)
                    .background(Color.bg300)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.shadow300, lineWidth: 1.0))
                    .disabled(!isGameActive)
                
                Spacer()
                Button("Submit") {
                    submitAnswer()
                }
                .disabled(!isGameActive || userInput.isEmpty)
                Spacer()
            }
            .padding()
            
            // Grid display of accepted answers
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(currentAnswers, id: \.self) { answer in
                    Text(answer)
                        .padding(8)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 120)
            
            // Game control button
            Button(isGameActive ? "End Game" : "Start Game") {
                if isGameActive {
                    endGame()
                } else {
                    startGame()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Spacer()
            
            CustomKeyboard { key in
                if key == "DELETE" {
                    if !userInput.isEmpty {
                        userInput.removeLast()
                    }
                } else {
                    userInput += key
                }
            }
            .frame(maxHeight: 280)

        }
        .padding()
        .background(Color.bg500)
    }
    
    /**
     * Initiates a new game session:
     * - Activates the game state
     * - Clears previous answers
     * - Starts the countdown timer
     */
    private func startGame() {
        isGameActive = true
        currentAnswers = []
        startTimer()
    }
    
    /**
     * Ends the current game session.
     * TODO: Implement score saving and game statistics tracking
     */
    private func endGame() {
        isGameActive = false
    }
    
    /**
     * Processes a user-submitted answer:
     * 1. Trims whitespace
     * 2. Validates against game rules
     * 3. Adds to accepted answers if valid
     */
    private func submitAnswer() {
        guard !userInput.isEmpty else { return }
        
        let answer = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if validateAnswer(answer) {
            currentAnswers.append(answer)
        }
        userInput = ""
    }
    
    /**
     * Validates an answer based on the specific game type rules.
     * Delegates to appropriate validation method based on game type.
     */
    private func validateAnswer(_ answer: String) -> Bool {
        if let wordGame = game as? WordGame {
            return validateWordGameAnswer(answer, wordGame: wordGame)
        } else if let categoryGame = game as? CategoryGame {
            return validateCategoryGameAnswer(answer, categoryGame: categoryGame)
        }
        return false
    }
    
    /**
     * Validates answers for word games based on letter position rules:
     * - Handles case sensitivity
     * - Checks if the word matches the target letter rule (start, end, contains)
     */
    private func validateWordGameAnswer(_ answer: String, wordGame: WordGame) -> Bool {
        let processedAnswer = wordGame.caseSensitive ? answer : answer.lowercased()
        let processedTarget = wordGame.caseSensitive ? wordGame.targetLetter : wordGame.targetLetter.lowercased()
        
        return switch wordGame.letterPosition {
        case .start:    processedAnswer.hasPrefix(processedTarget)
        case .end:      processedAnswer.hasSuffix(processedTarget)
        case .contains: processedAnswer.contains(processedTarget)
        }
    }
    
    /**
     * Validates answers for category games:
     * - Handles case sensitivity
     * - Checks if the answer exists in the category's answer bank
     */
    private func validateCategoryGameAnswer(_ answer: String, categoryGame: CategoryGame) -> Bool {
        let processedAnswer = categoryGame.caseSensitive ? answer : answer.lowercased()
        let processedBank = categoryGame.answerBank.map {
            categoryGame.caseSensitive ? $0 : $0.lowercased()
        }
        return processedBank.contains(processedAnswer)
    }
    
    /**
     * Manages the game countdown timer:
     * - Updates every second
     * - Automatically ends game when time expires
     * - Stops if game is manually ended
     */
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 && isGameActive {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                if timeRemaining == 0 {
                    endGame()
                }
            }
        }
    }
    
    /**
     * Converts seconds into a formatted MM:SS string
     * Example: 90 seconds becomes "01:30"
     */
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

/**
 * Displays game-specific content for word games:
 * - Shows the target letter
 * - Indicates where the letter should appear in valid answers
 */
struct WordGameContent: View {
    let game: WordGame
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Target Letter: \(game.targetLetter)")
                .font(.title2)
            
            Text("Position: \(game.letterPosition.rawValue.capitalized)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * Displays game-specific content for category games:
 * - Shows the category name
 * - Indicates how many possible answers exist
 */
struct CategoryGameContent: View {
    let game: CategoryGame
    @State private var answerCount: Int = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Category Game")
                .font(.title2)
            
            if game.answerBank.isEmpty {
                ProgressView("Loading answers...")
            } else {
                Text("\(game.answerBank.count) possible answers")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/*
import SwiftUI
import SwiftData


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
    
    /// Initializes the view with a specific game and sets up the initial timer
    init(game: Game) {
        self.game = game
        _timeRemaining = State(initialValue: game.timeLimit)
    }
    
    var body: some View {
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
            gameContent
            
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
     * Determines which game-specific content to display based on the game type.
     * Uses type casting to provide appropriate UI for word or category games.
     */
    @ViewBuilder
    private var gameContent: some View {
        if let wordGame = game as? WordGame {
            WordGameContent(game: wordGame)
        } else if let categoryGame = game as? CategoryGame {
            CategoryGameContent(game: categoryGame)
        }
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
        let processedAnswer = answer.lowercased()
        let processedTarget = wordGame.targetLetter.lowercased()
        
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
        let processedAnswer = answer.lowercased()
        let processedBank = categoryGame.answerBank.map { $0.lowercased() }
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
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Category Game")
                .font(.title2)
            
            Text("\(game.answerBank.count) possible answers")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}


import SwiftUI
import SwiftData

struct GameTypeListView: View {
    let gameTypes: [GameType]
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        List {
            ForEach(gameTypes) { gameType in
                GameTypeCard(gameType: gameType)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navPath.append(.gameType(gameType))
                    }
            }
        }
        .listStyle(.plain)
        .background(Color.bg100)
    }
}

struct GameTypeCard: View {
    let gameType: GameType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gameType.name)
                .font(.title3.bold())
                .foregroundColor(.textDark)
            
            Text(gameType.description)
                .font(.subheadline)
                .foregroundColor(.textDark)
                .lineLimit(2)
            
            HStack {
                Label("\(gameType.levels.count) Levels", systemImage: "speedometer")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.footnote)
            .foregroundColor(.textDark)
        }
        .padding()
        .background(Color.bg200)
        .cornerRadius(12)
        .shadow(color: .shadow300.opacity(0.1), radius: 4, y: 2)
    }
}

struct LevelListView: View {
    let gameType: GameType
    @Binding var navPath: [ViewPath]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(gameType.levels) { level in
                    LevelCard(level: level)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navPath.append(.level(level))
                        }
                }
            }
            .padding()
        }
        .background(Color.bg100)
        .navigationTitle(gameType.name)
    }
}

struct LevelCard: View {
    let level: Level
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(level.name)
                    .font(.title3.bold())
                Spacer()
                DifficultyBadge(level: level.name.lowercased())
            }
            
            Text(level.description)
                .font(.subheadline)
                .foregroundColor(.textDark)
            
            HStack {
                Label("\(level.games.count) Games", systemImage: "gamecontroller")
                Spacer()
                Label("\(level.sugTimeLimit)s", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundColor(.textDark)
        }
        .padding()
        .background(Color.bg200)
        .cornerRadius(12)
        .shadow(color: .shadow300.opacity(0.1), radius: 4, y: 2)
    }
}

struct DifficultyBadge: View {
    let level: String
    
    var color: Color {
        switch level {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .blue
        }
    }
    
    var body: some View {
        Text(level.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct GameListView: View {
    @Environment(\.modelContext) private var context
    let level: Level
    @Binding var navPath: [ViewPath]
    @State private var games: [Game] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading games...")
            } else if let error = error {
                VStack {
                    Text("Error loading games")
                    Text(error.localizedDescription)
                        .font(.caption)
                }
            } else if games.isEmpty {
                Text("No games available")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(games) { game in
                            GameCard(game: game)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("Game selected:")
                                    print(game)
                                    navPath.append(.game(game))
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.bg100)
        .navigationTitle(level.name)
        .task {
            await loadGames()
        }
    }
    
    private func loadGames() async {
        do {
            isLoading = true
            let descriptor = FetchDescriptor<LocalLevel>(
                predicate: #Predicate<LocalLevel> { $0.id == level.id ?? "" }
            )
            
            if let localLevel = try context.fetch(descriptor).first {
                games = localLevel.games.map { localGame in
                    let game: Game
                    
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
                    
                    game.id = localGame.id
                    game.name = localGame.name
                    game.description = localGame.locDescription
                    game.instructions = localGame.instructions
                    game.timeLimit = localGame.timeLimit
                    game.type = localGame.type == "category" ? .category : .word
                    game.gameTypeId = localGame.gameTypeId
                    game.levelId = localGame.levelId
                    
                    return game
                }
            }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

struct GameCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(game.name)
                .font(.title3.bold())
            
            Text(game.description)
                .font(.subheadline)
                .foregroundColor(.textDark)
            
            HStack {
                Label("\(game.timeLimit)s", systemImage: "clock")
                Spacer()
                if let wordGame = game as? WordGame {
                    WordGameBadge(game: wordGame)
                } else if game is CategoryGame {
                    CategoryGameBadge()
                }
            }
            .font(.footnote)
            .foregroundColor(.textDark)
        }
        .padding()
        .background(Color.bg200)
        .cornerRadius(12)
        .shadow(color: .shadow300.opacity(0.1), radius: 4, y: 2)
    }
}

struct WordGameBadge: View {
    let game: WordGame
    
    var body: some View {
        Label(game.letterPosition.rawValue.capitalized, systemImage: "textformat.abc")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

struct CategoryGameBadge: View {
    var body: some View {
        Label("Category", systemImage: "folder")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .clipShape(Capsule())
    }
}
*/

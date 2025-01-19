
/*
import SwiftUI
import SwiftData
import Firebase

@MainActor
protocol GameDataServiceProtocol {
    func fetchGameTypes() async throws -> [GameType]
    func fetchLevels(for gameTypeId: String) async throws -> [Level]
    func fetchGames(from refs: [DocumentReference]) async throws -> [Game]
    func fetchUpdatedGames(since date: Date) async throws -> [Game]
}

@MainActor
protocol GameSyncServiceProtocol {
    func syncIfNeeded(context: ModelContext) async throws
    func performFullSync(context: ModelContext) async throws
}

protocol LocalStorageProtocol {
    func saveGameTypes(_ gameTypes: [GameType], context: ModelContext) throws
    func fetchLocalGameTypes(context: ModelContext) throws -> [LocalGameType]
    func updateGame(_ game: Game, context: ModelContext) async throws
    func deleteAllGameTypes(context: ModelContext) throws
}

@MainActor
protocol GameViewModeling: ObservableObject {
    var gameTypes: [GameType] { get set }
    func refreshGameData(context: ModelContext) async
}

@MainActor
protocol GamePlayViewModeling: ObservableObject {
    var userInput: String { get set }
    var timeRemaining: Int { get set }
    var isGameActive: Bool { get set }
    var currentAnswers: [String] { get set }
    
    func startGame()
    func endGame()
    func submitAnswer()
    func validateAnswer(_ answer: String) -> Bool
}

protocol GameTypeProtocol: Identifiable, Codable {
    var id: String? { get set }
    var name: String { get set }
    var description: String { get set }
    var levels: [Level] { get set }
}

protocol LevelProtocol: Identifiable, Codable {
    var id: String? { get set }
    var name: String { get set }
    var description: String { get set }
    var sugTimeLimit: Int { get set }
    var gameRefs: [DocumentReference] { get set }
    var games: [Game] { get set }
}

protocol GameProtocol: Identifiable, Codable {
    var id: String? { get set }
    var name: String { get set }
    var description: String? { get set }
    var instructions: String { get set }
    var timeLimit: Int? { get set }
    var type: Game.GameType { get set }
    var gameTypeId: String { get set }
    var levelId: String { get set }
    var createdAt: Timestamp? { get set }
    var updatedAt: Timestamp? { get set }
}
*/

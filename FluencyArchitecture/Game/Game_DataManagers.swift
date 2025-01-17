
import SwiftUI
import FirebaseFirestore
import SwiftData

// MARK: - Game Data Service
/**
 * Manages Firestore fetch operations for the app.
 * Handles fetching and caching of game data.
 */
@MainActor
final class GameDataService: GameDataServiceProtocol {
    static let shared = GameDataService()
    private let db = Firestore.firestore()
    
    /**
     * Fetches all game types and their associated levels and games.
     * Data is fetched hierarchically:
     * GameTypes -> Levels -> Games
     */
    func fetchGameTypes() async throws -> [GameType] {
        let snapshot = try await db.collection("gameTypes").getDocuments()
        var gameTypes: [GameType] = []
        
        for document in snapshot.documents {
            do {
                let gameType = try document.data(as: GameType.self)
                gameType.id = document.documentID
                gameType.levels = try await fetchLevels(for: document.documentID)
                gameTypes.append(gameType)
            } catch {
                throw FirestoreError.decodingError("Failed to decode game type: \(error.localizedDescription)")
            }
        }
        
        return gameTypes
    }
    
    func fetchUpdatedGames(since timestamp: Timestamp) async throws -> [GameType] {
        let snapshot = try await db.collection("gameTypes")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()
        
        var updatedGames: [GameType] = []
        
        for document in snapshot.documents {
            let gameType = try document.data(as: GameType.self)
            gameType.id = document.documentID
            gameType.levels = try await fetchUpdatedLevels(for: document.documentID, since: timestamp)
            updatedGames.append(gameType)
        }
        
        return updatedGames
    }
    
    func fetchUpdatedLevels(for gameTypeId: String, since timestamp: Timestamp) async throws -> [Level] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()
        
        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            level.games = try await fetchUpdatedGames(for: gameTypeId,
                                                      levelId: document.documentID,
                                                      since: timestamp)
            levels.append(level)
        }
        return levels
    }
    
    private func fetchUpdatedGames(for gameTypeId: String,
                                   levelId: String,
                                   since timestamp: Timestamp) async throws -> [Game] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let gameType = try document.data(as: Game.self).type
            var game: Game?
            
            switch gameType {
            case .word:
                let wordGame = try document.data(as: WordGame.self)
                wordGame.id = document.documentID
                game = wordGame
            case .category:
                let categoryGame = try document.data(as: CategoryGame.self)
                categoryGame.id = document.documentID
                game = categoryGame
            }
            
            return game
        }
    }
    
    /**
     * Fetches all levels for a specific game type.
     * Each level includes its collection of games.
     */
    func fetchLevels(for gameTypeId: String) async throws -> [Level] {
        guard !gameTypeId.isEmpty else { return [] }
        
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .getDocuments()
        
        var levels: [Level] = []
        for document in snapshot.documents {
            let level = try document.data(as: Level.self)
            level.id = document.documentID
            level.games = try await fetchGames(for: document.documentID, gameTypeId: gameTypeId)
            levels.append(level)
        }
        return levels
        
    
    }
    
    /**
     * Fetches games for a specific level.
     * Handles both WordGame and CategoryGame types through polymorphic decoding.
     */
    func fetchGames(for levelId: String, gameTypeId: String) async throws -> [Game] {
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let gameType = try document.data(as: Game.self).type
            var game: Game?
            
            switch gameType {
            case .word:
                let wordGame = try document.data(as: WordGame.self)
                wordGame.id = document.documentID
                game = wordGame
            case .category:
                let categoryGame = try document.data(as: CategoryGame.self)
                categoryGame.id = document.documentID
                game = categoryGame
            }
            
            return game
        }
    }
    
    func fetchGameTypeMetadata() async throws -> [GameTypeMetadata] {
        let snapshot = try await db.collection("gameTypes").getDocuments()
        var metadata: [GameTypeMetadata] = []
        
        for document in snapshot.documents {
            let metadataSnapshot = try await document.reference
                .collection("metadata")
                .document("info")
                .getDocument()
            
            if var data = try? metadataSnapshot.data(as: GameTypeMetadata.self) {
                data.id = document.documentID  // Set the parent gameType ID
                metadata.append(data)
            }
        }
        
        return metadata
    }
    
    func fetchLevelMetadata(for gameTypeId: String) async throws -> [LevelMetadata] {
        var metadata: [LevelMetadata] = []
        let snapshot = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .getDocuments()
        
        for document in snapshot.documents {
            let metadataSnapshot = try await document.reference
                .collection("metadata")
                .document("info")
                .getDocument()
            
            if let data = try? metadataSnapshot.data(as: LevelMetadata.self) {
                metadata.append(data)
            }
        }
        
        return metadata
    }
    
    func fetchGameType(id: String) async throws -> GameType? {
        let document = try await db.collection("gameTypes").document(id).getDocument()
        
        guard document.exists, let data = document.data() else {
            print("DEBUG: No data found for game type \(id)")
            return nil
        }
        
        let gameType = GameType()
        gameType.id = document.documentID
        gameType.name = data["name"] as? String ?? ""
        gameType.description = data["description"] as? String ?? ""
        gameType.createdAt = data["createdAt"] as? Timestamp ?? Timestamp()
        gameType.updatedAt = data["updatedAt"] as? Timestamp ?? Timestamp()
        gameType.levels = try await fetchLevels(for: document.documentID)
        
        return gameType
    }
    
    func fetchAnswerBank(for gameId: String, levelId: String, gameTypeId: String) async throws -> [String]? {
        let document = try await db.collection("gameTypes")
            .document(gameTypeId)
            .collection("levels")
            .document(levelId)
            .collection("games")
            .document(gameId)
            .getDocument()
        
        if let categoryGame = try? document.data(as: CategoryGame.self) {
            return categoryGame.answerBank
        }
        return nil
    }
}



final class LocalStorageManager: LocalStorageProtocol {
    func saveGameTypes(_ gameTypes: [GameType], context: ModelContext) throws {
        for gameType in gameTypes {
            let localGameType = LocalGameType(from: gameType)
            localGameType.levels = gameType.levels.map { level in
                let localLevel = LocalLevel(from: level)
                localLevel.gameType = localGameType
                
                localLevel.games = level.games.map { game in
                    let localGame = LocalGame(from: game)
                    localGame.level = localLevel
                    return localGame
                }
                
                return localLevel
            }
            context.insert(localGameType)
        }
        try context.save()
    }
    
    func fetchLocalGameTypes(context: ModelContext) throws -> [LocalGameType] {
        let descriptor = FetchDescriptor<LocalGameType>()
        return try context.fetch(descriptor)
    }
    
    func clearLocalGameTypes(context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalGameType>()
        let existingGames = try context.fetch(descriptor)
        existingGames.forEach { context.delete($0) }
        try context.save()
    }
    
    private func createLocalGameType(from gameType: GameType) -> LocalGameType {
        let localGameType = LocalGameType(from: gameType)
        localGameType.levels = gameType.levels.map { level in
            let localLevel = LocalLevel(from: level)
            localLevel.gameType = localGameType
            
            localLevel.games = level.games.map { game in
                let localGame = LocalGame(from: game)
                localGame.level = localLevel
                return localGame
            }
            
            return localLevel
        }
        return localGameType
    }
    
}

@MainActor
final class GameSyncService: GameSyncServiceProtocol {
    static let shared = GameSyncService()
    private let gameDataService: GameDataServiceProtocol
    private let localStorage: LocalStorageProtocol
    private let defaults = UserDefaults.standard
    
    private enum DefaultsKeys {
        static let lastSyncDate = "lastSyncDate"
        static let gameTypeChecksums = "gameTypeChecksums"
        static let levelChecksums = "levelChecksums"
    }
    
    init(localStorage: LocalStorageProtocol = LocalStorageManager()) {
        self.gameDataService = GameDataService.shared
        self.localStorage = localStorage
    }
    
    func syncIfNeeded(context: ModelContext) async throws {
        let localGames = try localStorage.fetchLocalGameTypes(context: context)
        
        if localGames.isEmpty {
            log("No local games found - performing full sync")
            try await performFullSync(context: context)
            return
        }
        
        // Check if we have stored checksums
        let storedChecksums = defaults.dictionary(forKey: DefaultsKeys.gameTypeChecksums) as? [String: String]
        if storedChecksums == nil {
            log("No stored checksums found - performing full sync")
            try await performFullSync(context: context)
            return
        }
        
        // Get metadata for all game types
        let gameTypeMetadata = try await gameDataService.fetchGameTypeMetadata()
        
        var needsSync = false
        for metadata in gameTypeMetadata {
            if storedChecksums![metadata.id ?? ""] != metadata.checksum {
                log("Checksum mismatch detected for game type \(metadata.id ?? "")")
                needsSync = true
                break
            }
        }
        
        if needsSync {
            log("Changes detected - performing incremental sync")
            try await performIncrementalSync(context: context)
        } else {
            log("No changes detected - skipping sync")
        }
    }
    
    private func performFullSync(context: ModelContext) async throws {
        try localStorage.clearLocalGameTypes(context: context)
        let gameTypes = try await gameDataService.fetchGameTypes()
        try localStorage.saveGameTypes(gameTypes, context: context)
        
        var checksums: [String: String] = [:]
        for gameType in gameTypes {
            if let id = gameType.id {
                checksums[id] = GameTypeMetadata.calculateChecksum(for: gameType)
            }
        }
        
        defaults.set(checksums, forKey: DefaultsKeys.gameTypeChecksums)
        defaults.set(Date(), forKey: DefaultsKeys.lastSyncDate)
    }
    
    private func updateLocalGameType(_ gameType: GameType, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<LocalGameType>(
            predicate: #Predicate<LocalGameType> { localType in
                localType.id == (gameType.id ?? "")
            }
        )
        
        let existingGame = try context.fetch(descriptor).first
        
        if let existing = existingGame {
            existing.name = gameType.name
            existing.locDescription = gameType.description
            try await updateLocalLevels(gameType.levels, for: existing)
        } else {
            let localGame = LocalGameType(from: gameType)
            context.insert(localGame)
        }
        
        try context.save()
    }
    
    private func updateLocalLevels(_ levels: [Level], for localGameType: LocalGameType) async throws {
        let levelMetadata = try await gameDataService.fetchLevelMetadata(for: localGameType.id)
        let storedLevelChecksums = defaults.dictionary(forKey: DefaultsKeys.levelChecksums) as? [String: String] ?? [:]
        
        for level in levels {
            if let id = level.id,
               let levelMeta = levelMetadata.first(where: { $0.id == id }),
               storedLevelChecksums[id] != levelMeta.checksum {
                if let existingLevel = localGameType.levels.first(where: { $0.id == id }) {
                    existingLevel.name = level.name
                    existingLevel.locDescription = level.description
                    existingLevel.difficulty = level.difficulty
                    updateLocalGames(level.games, for: existingLevel)
                } else {
                    let newLevel = LocalLevel(from: level)
                    newLevel.gameType = localGameType
                    newLevel.games = level.games.map { game in
                        let localGame = LocalGame(from: game)
                        localGame.level = newLevel
                        return localGame
                    }
                    localGameType.levels.append(newLevel)
                }
            }
        }
        
        var newLevelChecksums = storedLevelChecksums
        for metadata in levelMetadata {
            if let id = metadata.id {
                newLevelChecksums[id] = metadata.checksum
            }
        }
        defaults.set(newLevelChecksums, forKey: DefaultsKeys.levelChecksums)
    }
    
    private func updateLocalGames(_ games: [Game], for level: LocalLevel) {
        for game in games {
            if let id = game.id, let existingGame = level.games.first(where: { $0.id == id }) {
                existingGame.name = game.name
                existingGame.locDescription = game.description
                existingGame.instructions = game.instructions
                existingGame.timeLimit = game.timeLimit
                existingGame.caseSensitive = game.caseSensitive
                
                if let wordGame = game as? WordGame {
                    existingGame.letterPositionString = wordGame.letterPosition.rawValue
                    existingGame.targetLetter = wordGame.targetLetter
                } else if let categoryGame = game as? CategoryGame {
                    existingGame.storedAnswerBank = categoryGame.answerBank
                }
            } else {
                level.games.append(LocalGame(from: game))
            }
        }
    }
}

extension GameSyncService {
    private func log(_ message: String) {
        print("🔄 [GameSync] \(message)")
    }
    
    private func performIncrementalSync(context: ModelContext) async throws {
        log("Starting incremental sync")
        let gameTypeMetadata = try await gameDataService.fetchGameTypeMetadata()
        log("Firestore Metadata: \(gameTypeMetadata)")
        
        let storedChecksums = defaults.dictionary(forKey: DefaultsKeys.gameTypeChecksums) as? [String: String] ?? [:]
        
        log("Found \(gameTypeMetadata.count) game types in metadata")
        
        var newChecksums: [String: String] = [:]
        var downloadedGameTypes = 0
        var skippedGameTypes = 0
        
        for metadata in gameTypeMetadata {
            guard let metadataId = metadata.id?.replacingOccurrences(of: "/metadata/info", with: "") else { continue }
            print(metadata)
            
            if storedChecksums[metadataId] != metadata.checksum {
                log("📥 Game type \(metadataId) needs update - stored checksum: \(storedChecksums[metadataId] ?? "none"), new checksum: \(metadata.checksum)")
                if let gameType = try await gameDataService.fetchGameType(id: metadataId) {
                    try await updateLocalGameType(gameType, context: context)
                    newChecksums[metadataId] = metadata.checksum
                    downloadedGameTypes += 1
                }
            } else {
                log("⏭️ Skipping game type \(metadataId) - checksum unchanged")
                newChecksums[metadataId] = storedChecksums[metadataId]
                skippedGameTypes += 1
            }
        }
        
        log("Sync complete - Downloaded: \(downloadedGameTypes), Skipped: \(skippedGameTypes)")
        defaults.set(newChecksums, forKey: DefaultsKeys.gameTypeChecksums)
        defaults.set(Date(), forKey: DefaultsKeys.lastSyncDate)
    }
}


// Add UserDefaults extension for last sync management
extension UserDefaults {
    private enum Keys {
        static let lastSyncTimestamp = "lastSyncTimestamp"
        static let syncBackupTimestamp = "syncBackupTimestamp"
    }
    
    var lastSyncDate: Date? {
        get { date(forKey: Keys.lastSyncTimestamp) }
        set { set(newValue, forKey: Keys.lastSyncTimestamp) }
    }
    
    var backupSyncDate: Date? {
        get { date(forKey: Keys.syncBackupTimestamp) }
        set { set(newValue, forKey: Keys.syncBackupTimestamp) }
    }
    
    func updateSyncDates() {
        let now = Date()
        lastSyncDate = now
        backupSyncDate = now
    }
}

extension UserDefaults {
    func date(forKey key: String) -> Date? {
        return object(forKey: key) as? Date
    }
}

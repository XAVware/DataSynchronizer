# Data Models

High level information about the app's data structure.
The source of truth for games is in the cloud - Firebase Firestore - but the game data is fetched and stored locally with SwiftData to allow the app to run flawlessly without internet connection. Using Firestore as the source of truth allows us to remotely add and update games. Since these changes shouldn't be urgent, we can sync changes down to client devices as infrequently as we would like (i.e. once a week).


## Managers
    - `SyncManager`: Manages synchronization between Firestore and local storage
    - `GameDataManager`: Manages Firestore fetch operations for the app.

## Managing Game Data
The root view needs to display the highest level game types (Word or Category) for the user to choose. Game data is stored in `viewModel.gameTypes`. 

When the view appears
    - If `viewModel.gameTypes` is already populated, nothing happens.
        - This ensures that data won't be unnecissarily loaded if the user comes back out to the home screen.
    - If `viewModel.gameTypes` is empty, the model context (containing locally stored SwiftData games) is passed into the viewModel's `refreshGameData` function

### refreshGameData
1. Calls syncManager.syncIfNeeded. Once this finishes running we can be sure that local data is up to date.
    - Fetches games from Firestore if there are no local games OR if the last sync was more than 24 hours ago.
        - Each time `sync` is called, local data is erased, `GameDataManager.fetchGameTypes()` is called, the response is converted to `LocalGameType` and saved into the `context` (local storage)
2. Fetches local game data from storage (as type `LocalGameType`)
3. Converts the array of type `LocalGameType` into the `gameTypes` array of type `GameType` which is required for the app's navigational structure and game play to work properly.

## ERD Class Diagram
classDiagram
class GameType {
    +@DocumentID id: String?
    +name: String
    +description: String
    +levels: [Level]
}

class Level {
    +@DocumentID id: String?
    +name: String
    +description: String
    +difficulty: Int
    +games: [Game]
}

class Game {
    +@DocumentID id: String?
    +name: String
    +description: String
    +instructions: String
    +timeLimit: Int
    +caseSensitive: Bool
    +type: GameType
    +encode()
}

class WordGame {
    +letterPosition: LetterPosition
    +targetLetter: String
}

class CategoryGame {
    +answerBank: [String]
}

GameType "1" --> "*" Level : contains
Level "1" --> "*" Game : contains
Game <|-- WordGame : extends
Game <|-- CategoryGame : extends

note for GameType "Fetched directly from Firestore\nLevels loaded separately"
note for Level "Games loaded after level fetch"
note for Game "Base class for all games\nType determines specific implementation"


## Firestore Schema

gameModes/
├─ {gameModeId}/           # Document containing basic game type info
│  ├─ name: string
│  └─ description: string
│
│  └─ levels/              # Subcollection of levels
│      ├─ {levelId}/       # Document containing level information
│      │  ├─ name: string
│      │  ├─ description: string
│      │  ├─ difficulty: number
│      │  └─ gameRefs: [GameId]
│      │
games/           # Collection of games
│  └─ {gameId}/    # Document containing game information
│     ├─ name: string
│     ├─ description: string
│     ├─ instructions: string
│     ├─ timeLimit: number
│     ├─ caseSensitive: boolean
│     ├─ type: "word" | "category"
│     │
│     # Word Game specific fields (when type is "word")
│     ├─ letterPosition: "start" | "end" | "contains"
│     ├─ targetLetter: string
│     │
│     # Category Game specific fields (when type is "category")
│     └─ answerBank: string[]

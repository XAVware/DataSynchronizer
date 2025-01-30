# Data Synchronization

My goal here was to sync data stored in Firestore, the source of truth, with a local SwiftData database.

I wanted to give my client the ability to update their data remotely, as needed, while ensuring users experience minimal performance impacts. In addition, I wanted to avoid unnecessary Firestore charges by only fetching the updated data.

I use `games` for this example. A `GameMode` contains `[Levels]`, each Level contain `[Games]`. Though `GameMode` and `Level` data can change `Game` data changes frequently.

## Python Script

Python script allows my client to publish data to Firestore via a CSV file. It gives them the flexibility to upload a file with full or partial data.

When a new game is added to the spreadsheet, it does not have an ID. Firestore creates the DocumentID and the script adds it to the spreadsheet so it can be updated later. In Firestore, the `createdAt` an `updatedAt` properties are created with a server timestamp. 

Each time the game is included in an upload following its initial creation the script compares the game's Firestore data to what is in the spreadsheet. It updates the updatedAt property only if data has changed. Uploading the same exact file multiple times will not change any `updatedAt` properties.

## iOS

`GameDataService` manages Firestore
`LocalDataService` manages SwiftData
`DataSynchronizer`, coordinates `GameDataService` and `LocalDataService`

When the app launches `DataSynchronizer` checks `UserDefaults` for `mostRecentSync` date. If it doesn't exist, this is because it's the user's first time launching the app - all data needs to be downloaded. 

`mostRecentSync` is updated each time the process has finished whether or not it downloaded any data.

After the initial download, each time the app launches `mostRecentSync` is used to fetch games from Firestore that have been updated after it. Games that are returned are passed to `LocalDataService`, converted to swift models and saved locally.

The app therefore relies on local data for anything that the users interacting with.

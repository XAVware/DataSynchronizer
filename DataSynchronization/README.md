# Background
- gameStructure refers to the GameMode and Level data found in gameStructure.csv
- games refers to the Game data found in games.csv
- Game IDs are created by Firestore then added to the spreadsheet.
- Game createdAt property should not change after initial creation.

onAdd:
A new document should be created in Firestore with the game data.
The new game's ID should be added to the spreadsheet.
The game's document reference should be added to the corresponding Level's gameRefs array
Set both createdAt and updatedAt timestamps to the current time

onModify:
The game's updatedAt property should be updated.

# Test Cases and Expectations
1. Initial run: Firestore is empty, games.csv does not contain any IDs
Expected: 
    gameStructure and all games are published. Game createdAt and updatedAt are equivalent.
--PASSED--


2. Running with unchanged data
Expected: 
    When you run publishGames.py with the same games.csv content, the script checks if each game already exists by looking for its ID. 
    For existing games with no changes, it should:
    Not update the Firestore documents at all
    Leave the updatedAt timestamp unchanged
--PASSED--


3. Running with full CSV data, but only one game has been modified
Expected: 
    Only the modified game should have it's updatedAt property updated to reflect the current time. All other games should remain unchanged.
--PASSED--


4. Running with full CSV data, but one game has been added
Expected: 
    Only the new game should be created. All other games should remain unchanged.
--PASSED--


5. Running with only a single row containing a new game, while Firestore is fully populated
Expected: 
    Only the new game should be created. All other games should remain unchanged.
--PASSED--

6. Running with only a single row containing a modified game, while Firestore is fully populated
Expected: 
    Only the modified game should have it's updatedAt property updated. 
    All other games should remain unchanged.
--PASSED--

7. Multiple Changes - Running with a combination of:
    Unchanged existing games
    Modified existing games
    New games 
Expected:
    No timestamp changes for unchanged games
    New updatedAt timestamps only for modified games
    Both createdAt and updatedAt timestamps for new games
--PASSED--

    
8. Empty CSV:
Expected:
    Log a warning about no games to process
    Not modify any Firestore documents
--PASSED--

    
Updating the data in gameStructure.csv for either the GameMode or Level should not lose any information related to its children.
--PASSED--

Updating a field in Level won't erase the gameRefs array
--PASSED--


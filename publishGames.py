
import csv
import firebase_admin
from firebase_admin import credentials, firestore

def initialize_firestore(cred_path):
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()


def read_csv(filepath):
    with open(filepath, 'r') as file:
        reader = csv.DictReader(file)
        return list(reader)

def write_csv(filepath, data, fieldnames):
    with open(filepath, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

def fetch_existing_games(db):
    return {doc.id: doc.to_dict() for doc in db.collection('games').stream()}

def has_game_changed(existing_game, new_game_data):
    keys_to_check = ['description', 'instructions', 'timeLimit', 'gameModeId', 'levelId', 'letterPosition', 'targetLetter', 'answerBank']
    for key in keys_to_check:
        if existing_game.get(key) != new_game_data.get(key):
            return True
    return False

def build_game_data(game, game_mode_id, level_id):
    return {
        'name': game['name'],
        'description': game.get('description'),
        'instructions': game['instructions'],
        'timeLimit': float(game['timeLimit']) if game['timeLimit'] else None,
        'gameModeId': game_mode_id,
        'levelId': level_id,
        'letterPosition': game.get('letterPosition'),
        'targetLetter': game.get('targetLetter'),
        'answerBank': [ans.strip() for ans in game['answerBank'].split(',')] if game['answerBank'] else None
    }

def upload_games_from_csv(games_path, structure_path, cred_path):
    db = initialize_firestore(cred_path)
    games_csv = read_csv(games_path)
    structure_csv = read_csv(structure_path)

    if not games_csv:
        print("Warning: games.csv is empty. No games to process.")
        return

    if not structure_csv:
        print("Warning: gameStructure.csv is empty. No structures to process.")
        return

    batch = db.batch()
    for structure in structure_csv:
        game_mode_id = structure['id']
        level_id = structure['levelId']

        game_mode_ref = db.collection('gameModes').document(game_mode_id)
        level_ref = game_mode_ref.collection('levels').document(level_id)

        game_mode_data = {
            'name': structure['name'],
            'description': structure['description']
        }
        if game_mode_ref.get().exists:
            batch.update(game_mode_ref, game_mode_data)
        else:
            batch.set(game_mode_ref, game_mode_data)
            print(f"Creating gameMode: {game_mode_id}")

        level_data = {
            'name': structure['levelName'],
            'description': structure['levelDescription'],
            'sugTimeLimit': int(structure['levelSuggestedTimeLimit']) if structure['levelSuggestedTimeLimit'].isdigit() else None
        }
        if level_ref.get().exists:
            batch.update(level_ref, level_data)
        else:
            existing_level = level_ref.get().to_dict() or {}
            level_data['gameRefs'] = existing_level.get('gameRefs', [])
            batch.set(level_ref, level_data)
            print(f"Creating level: {level_id} under gameMode {game_mode_id}")

    updated_games_csv = []
    existing_games = fetch_existing_games(db)

    for game in games_csv:
        try:
            game_id = game.get('id')
            level_id = game['levelId']
            game_mode_id = game['gameModeId']

            game_mode_ref = db.collection('gameModes').document(game_mode_id)
            level_ref = game_mode_ref.collection('levels').document(level_id)

            if not game_id:
                new_doc_ref = db.collection('games').document()
                game_data = build_game_data(game, game_mode_id, level_id)
                game_data.update({
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP
                })
                batch.set(new_doc_ref, game_data)

                batch.update(level_ref, {
                    'gameRefs': firestore.ArrayUnion([new_doc_ref])
                })

                game['id'] = new_doc_ref.id
                print(f"New game created and linked to level: {new_doc_ref.id}")
            else:
                existing_game = existing_games.get(game_id)
                if existing_game:
                    game_data = build_game_data(game, game_mode_id, level_id)
                    if has_game_changed(existing_game, game_data):
                        game_data.update({
                            'updatedAt': firestore.SERVER_TIMESTAMP
                        })
                        batch.update(db.collection('games').document(game_id), game_data)
                        print(f"Game updated: {game_id}")
                    else:
                        print(f"No changes detected for game: {game_id}")
                else:
                    print(f"Game ID {game_id} not found in Firestore. Skipping.")

            updated_games_csv.append(game)

        except KeyError as e:
            print(f"Missing required field {e} in row: {game}. Skipping.")

    batch.commit()
    print("All updates committed.")

    fieldnames = games_csv[0].keys()
    write_csv(games_path, updated_games_csv, fieldnames)


if __name__ == "__main__":
    import K 
    upload_games_from_csv(
        games_path="games.csv",
        structure_path="gameStructure.csv",
        cred_path=K.path_to_key
    )

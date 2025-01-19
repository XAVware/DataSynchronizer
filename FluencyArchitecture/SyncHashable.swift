
//
//
//// MARK: - Firestore Model Equatable & Hashable Conformance
///*
// In order to be passed through `ViewPath`, the models need to be Hashable and Equatable.
//
// Since the DocumentIDs are optional Strings, I took a few extra precautions with the Hashable functions.
//
// Though Option A would cover most scenarios, I went with Option B. Using `Game` as an example,
//
// Option A:
// ```swift
// extension Game: Equatable, Hashable {
// func hash(into hasher: inout Hasher) {
// hasher.combine(id ?? UUID().uuidString) // Fallback to UUID if id is nil
// }
//
// static func == (lhs: Game, rhs: Game) -> Bool {
// let lhsId = lhs.id ?? UUID().uuidString
// let rhsId = rhs.id ?? UUID().uuidString
// return lhsId == rhsId
// }
// }
// ```
//
// Option B:
// ```swift
// extension Game: Equatable, Hashable {
// func hash(into hasher: inout Hasher) {
// hasher.combine(id ?? "")
// hasher.combine(name)
// hasher.combine(instructions)
// hasher.combine(gameTypeId)
// hasher.combine(levelId)
// hasher.combine(type)
// }
//
// // Equatable
// static func == (lhs: Game, rhs: Game) -> Bool {
// return lhs.id == rhs.id &&
// lhs.name == rhs.name &&
// lhs.instructions == rhs.instructions &&
// lhs.gameTypeId == rhs.gameTypeId &&
// lhs.levelId == rhs.levelId &&
// lhs.type == rhs.type
// }
// }
// ```
//
// Option A could cause unexpected behavior if there were a case like the following:
//
// ```swift
// let game1 = Game(id: nil)
// let game2 = Game(id: nil)
// print(game1 == game2) // false (unexpected)
// ```
//
// or even
//
// ```swift
// let game1 = Game(id: nil, name: "Only Game", createdAt: "2025-01-17 10:30:00")
// let game2 = Game(id: nil, name: "Only Game", createdAt: "2025-01-17 10:30:00")
// print(game1 == game2) // false (unexpected)
// ```
//
// With Option B, two Game objects are considered equal if all relevant properties are the same. Properties included in the equation can be easily ignored if needed in the future. To keep nil IDs consistent, an empty string is used as the fallback instead of a random ID.
//
// Though there is more code up front, Option B ensures that behavior is consistent, predictable, and customizable.
// */

import Foundation

extension GameMode: Equatable, Hashable {
    static func == (lhs: GameMode, rhs: GameMode) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(description)
    }
}

extension Level: Equatable, Hashable {
    static func == (lhs: Level, rhs: Level) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.sugTimeLimit == rhs.sugTimeLimit
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(sugTimeLimit)
    }
}

extension Game: Equatable, Hashable {
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.instructions == rhs.instructions &&
        lhs.gameModeId == rhs.gameModeId &&
        lhs.levelId == rhs.levelId &&
        lhs.mode == rhs.mode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? "")
        hasher.combine(name)
        hasher.combine(instructions)
        hasher.combine(gameModeId)
        hasher.combine(levelId)
        hasher.combine(mode)
    }
}

//
//  ExerciseEntry.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

import Foundation

struct ExerciseEntry: Codable {
    let name: String
    var sets: [ExerciseSet]
}

struct ExerciseSet: Codable {
    var weight: String
    var reps: String
}

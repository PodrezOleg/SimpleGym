//
//  Workout.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

import Foundation

struct Workout: Codable {
    let name: String
    let reps: Int
    let weight: Int
    let date: Date
}

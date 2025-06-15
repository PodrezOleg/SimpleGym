//
//  WorkoutFileStorage.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 14.06.25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

struct WorkoutData: Codable {
    let date: String
    let entries: [ExerciseEntry]
}

class WorkoutFileStorage {
    static let shared = WorkoutFileStorage()

    private init() {}

    private let fileName = "workouts.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - EXPORT
    func exportWorkouts(from controller: UIViewController) {
        let allData = ExerciseStorage.shared.load()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(allData)
            try data.write(to: fileURL)
            print("✅ Workouts exported to: \(fileURL)")

            // 👉 Запускаем шаринг сразу
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            controller.present(activityVC, animated: true)

        } catch {
            print("❌ Failed to export workouts: \(error)")
        }
    }

    // MARK: - IMPORT
    func importWorkouts(from data: Data) throws {
        let decoded = try JSONDecoder().decode([String: [ExerciseEntry]].self, from: data)

        for (date, entries) in decoded {
            let key = "exercises-\(date)"
            ExerciseStorage.shared.update(for: key, exercises: entries)
        }
        print("✅ Workouts imported successfully.")
    }

    // MARK: - Sharing
    func shareExportedFile(from controller: UIViewController) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ Workout file not found.")
            return
        }
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.present(activityVC, animated: true)
    }
}

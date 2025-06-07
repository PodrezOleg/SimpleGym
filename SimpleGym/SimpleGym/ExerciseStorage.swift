//
//  ExerciseStorage.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

// Новый способ хранения упражнений через FileManager + JSON

import Foundation

class ExerciseStorage {
    static let shared = ExerciseStorage()

    private init() {}

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("exercises.json")
    }

    func save(_ exercisesByDate: [String: [ExerciseEntry]]) {
        do {
            let data = try JSONEncoder().encode(exercisesByDate)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("❌ Ошибка при сохранении: \(error)")
        }
    }

    func load() -> [String: [ExerciseEntry]] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:] // Нет файла — возвращаем пустой словарь
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: [ExerciseEntry]].self, from: data)
            return decoded
        } catch {
            print("❌ Ошибка при загрузке: \(error)")
            return [:]
        }
    }

    func delete(for dateKey: String) {
        var all = load()
        all.removeValue(forKey: dateKey)
        save(all)
    }

    func update(for dateKey: String, exercises: [ExerciseEntry]) {
        var all = load()
        all[dateKey] = exercises
        save(all)
    }

    func load(for dateKey: String) -> [ExerciseEntry] {
        let all = load()
        return all[dateKey] ?? []
    }
    
    func loadExercises(forKey key: String) -> [ExerciseEntry] {
        return load(for: key)
    }
}

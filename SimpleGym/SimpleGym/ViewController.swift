//
//  ViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

//  GymTrackerApp
//  Minimal UIKit app for old iPhone

import UIKit
import FSCalendar

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var setsPerDay: [String: Int] = [:]
    var workouts: [Workout] = []
    let tableView = UITableView()
    let statsLabel = UILabel()
    let calendar = FSCalendar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "💪 Gym Tracker"
        view.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.1)
        
        loadWorkouts()
        loadSetsCountFromStorage()
        
        setupCalendar()
        setupTableView()
        setupAddButton()
        setupStatsLabel()
        updateStats()
    }
    func setupCalendar() {
        calendar.frame = CGRect(x: 0, y: 140, width: view.frame.width, height: 300)
        calendar.dataSource = self
        calendar.delegate = self
        view.addSubview(calendar)
    }
    
    func setupTableView() {
        tableView.frame = CGRect(x: 0, y: 150, width: view.frame.width, height: view.frame.height - 150)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        view.addSubview(tableView)
    }
    
    func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        navigationItem.rightBarButtonItem = addButton
    }
    
    func setupStatsLabel() {
        statsLabel.frame = CGRect(x: 20, y: 80, width: view.frame.width - 40, height: 50)
        statsLabel.textAlignment = .center
        statsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        statsLabel.textColor = .systemPurple
        statsLabel.backgroundColor = UIColor.systemGray6
        view.addSubview(statsLabel)
    }
    
    @objc func addWorkout() {
        let alert = UIAlertController(title: "New Workout", message: "Enter name and reps", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Workout name" }
        alert.addTextField {
            $0.placeholder = "повторения"
            $0.keyboardType = .numberPad
        }
        alert.addTextField {
            $0.placeholder = "Вес (kg)"
            $0.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let repsText = alert.textFields?[1].text, let reps = Int(repsText),
                  let weightText = alert.textFields?[2].text, let weight = Int(weightText) else { return }
            
            let workout = Workout(name: name, reps: reps, weight: weight, date: Date())
            self.workouts.append(workout)
            self.saveWorkouts()
            self.updateStats()
            self.tableView.reloadData()
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let workout = workouts[indexPath.row]
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        cell.textLabel?.text = "\(workout.name) – \(workout.reps) reps, \(workout.weight) kg"
        cell.detailTextLabel?.text = formatter.string(from: workout.date)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            workouts.remove(at: indexPath.row)
            saveWorkouts()
            updateStats()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func saveWorkouts() {
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: "workouts")
        }
    }
    
    func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: "workouts"),
           let saved = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = saved
        }
    }
    
    func updateStats() {
        let total = workouts.reduce(0) { $0 + $1.reps }
        statsLabel.text = "Total reps: \(total)"
    }
    
    
    func loadSetsCountFromStorage() {
        let defaults = UserDefaults.standard
        setsPerDay = [:]
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.starts(with: "exercises-"),
               let data = value as? Data,
               let decoded = try? JSONDecoder().decode([ExerciseEntry].self, from: data) {
                let totalSets = decoded.reduce(0) { $0 + $1.sets.count }
                setsPerDay[key] = totalSets
            }
        }
    }
    func formattedDateKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "exercises-\(formatter.string(from: date))"
    }
    func defaultExercises() -> [ExerciseEntry] {
        return [
            ExerciseEntry(name: "Жим лежа", sets: [ExerciseSet(weight: "10", reps: "20"), ExerciseSet(weight: "15", reps: "15")]),
            ExerciseEntry(name: "Т-гриф", sets: [ExerciseSet(weight: "4", reps: "15"), ExerciseSet(weight: "5", reps: "10"), ExerciseSet(weight: "6", reps: "6")]),
            ExerciseEntry(name: "Жим ногами", sets: [ExerciseSet(weight: "-", reps: "15"), ExerciseSet(weight: "20", reps: "20"), ExerciseSet(weight: "30", reps: "15")]),
            ExerciseEntry(name: "Жим сидя гантелей", sets: [ExerciseSet(weight: "4", reps: "15"), ExerciseSet(weight: "6", reps: "15"), ExerciseSet(weight: "6", reps: "10"), ExerciseSet(weight: "7", reps: "15")]),
            ExerciseEntry(name: "Тяга верх блока", sets: [ExerciseSet(weight: "4", reps: "15"), ExerciseSet(weight: "5", reps: "20"), ExerciseSet(weight: "6", reps: "10")]),
            ExerciseEntry(name: "Гиперэкстензия (7 выс.)", sets: [ExerciseSet(weight: "0", reps: "15"), ExerciseSet(weight: "10", reps: "20"), ExerciseSet(weight: "10", reps: "20")]),
            ExerciseEntry(name: "Икры стоя", sets: [ExerciseSet(weight: "-", reps: "20"), ExerciseSet(weight: "-", reps: "15")]),
            ExerciseEntry(name: "Тяга гантелей к поясу", sets: [ExerciseSet(weight: "6", reps: "20"), ExerciseSet(weight: "7", reps: "20")]),
            ExerciseEntry(name: "Сгибание ног лёжа", sets: [ExerciseSet(weight: "4", reps: "15"), ExerciseSet(weight: "5", reps: "15"), ExerciseSet(weight: "6", reps: "7")])
        ]
    }
}

// MARK: - FSCalendar DataSource & Delegate for highlighting workout dates
extension ViewController: FSCalendarDataSource, FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let calendar = Calendar.current
        return workouts.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) ? 1 : 0
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "exercises-\(formatter.string(from: date))"
        if setsPerDay[key] != nil {
            return [UIColor.systemGreen]
        }
        return nil
    }
}

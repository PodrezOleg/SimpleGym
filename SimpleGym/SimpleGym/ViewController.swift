//
//  ViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//
//
//  ViewController.swift
//  SimpleGym
//
//  Updated with warm pink theme and purple highlights

import UIKit
import FSCalendar

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var setsPerDay: [String: Int] = [:]
    var workouts: [Workout] = []
    let tableView = UITableView()
    let statsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "💪 Gym Tracker"
        view.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0) // warm pink

        loadWorkouts()
        loadSetsCountFromStorage()

        let alert = UIAlertController(title: "🎉 Ты крутыха!", message: "Как будешь жать 25кг, приложение можно удалять)))", preferredStyle: .alert)
        self.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
        setupTableView()
        setupAddButton()
        setupStatsLabel()
        updateStats()
        setupRingChart()
        setupWeeklyBarChart()
        setupBadgesSection()
    }

    func setupTableView() {
        tableView.frame = CGRect(x: 0, y: 450, width: view.frame.width, height: view.frame.height - 450)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0) // lighter pink
        view.addSubview(tableView)
    }

    func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        addButton.tintColor = .purple
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
        let streak = currentStreak()
        let weekly = setsThisWeek()
        statsLabel.text = "Total reps: \(total) • Week: \(weekly) • 🔥\(streak)-day streak"
    }

    func setupRingChart() {
        let ring = UIProgressView(progressViewStyle: .bar)
        ring.frame = CGRect(x: 20, y: statsLabel.frame.maxY + 20, width: view.frame.width - 40, height: 20)
        ring.progressTintColor = .systemPurple
        ring.trackTintColor = .systemGray4
        ring.progress = progressThisMonth()
        ring.layer.cornerRadius = 10
        ring.clipsToBounds = true
        view.addSubview(ring)

        let label = UILabel(frame: CGRect(x: 20, y: ring.frame.maxY, width: view.frame.width - 40, height: 20))
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.text = "Прогресс за месяц"
        view.addSubview(label)
    }

    func setupWeeklyBarChart() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        let barStack = UIStackView(frame: CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 50))
        barStack.axis = .horizontal
        barStack.distribution = .fillEqually
        barStack.spacing = 4

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let dayLabel = UILabel()
            let reps = workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
                               .reduce(0) { $0 + $1.reps }

            let bar = UIView()
            let height = CGFloat(reps) * 0.5
            bar.backgroundColor = reps > 0 ? .purple : .systemGray4
            bar.heightAnchor.constraint(equalToConstant: height).isActive = true
            bar.layer.cornerRadius = 4

            let container = UIStackView(arrangedSubviews: [bar, dayLabel])
            container.axis = .vertical
            container.alignment = .center
            container.spacing = 2

            let formatter = DateFormatter()
            guard let shortWeekdays = formatter.shortWeekdaySymbols else { return }
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            dayLabel.text = shortWeekdays[weekdayIndex]
            dayLabel.font = UIFont.systemFont(ofSize: 10)

            barStack.addArrangedSubview(container)
        }

        if let ring = view.subviews.first(where: { $0 is UIProgressView }) {
            barStack.frame.origin.y = ring.frame.maxY + 30
        } else {
            barStack.frame.origin.y = statsLabel.frame.maxY + 70
        }

        view.addSubview(barStack)
    }

    func setupBadgesSection() {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 30))
        label.text = "🏅 Достижения"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        view.addSubview(label)

        let badges = UIStackView(frame: CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 30))
        badges.axis = .horizontal
        badges.spacing = 10

        let streak = currentStreak()
        let weekSets = setsThisWeek()

        if streak >= 3 {
            badges.addArrangedSubview(makeBadge(title: "🔥 3 дня подряд"))
        }
        if weekSets >= 100 {
            badges.addArrangedSubview(makeBadge(title: "💯 повторений на неделе"))
        }
        if workouts.count >= 10 {
            badges.addArrangedSubview(makeBadge(title: "🎉 10 тренировок"))
        }

        let candidateStacks = view.subviews.compactMap { $0 as? UIStackView }
        if let barStack = candidateStacks.first(where: { $0.axis == .horizontal && $0.spacing == 4 }) {
            label.frame.origin.y = barStack.frame.maxY + 30
        } else if let ring = view.subviews.first(where: { $0 is UIProgressView }) {
            label.frame.origin.y = ring.frame.maxY + 60
        } else {
            label.frame.origin.y = statsLabel.frame.maxY + 100
        }

        badges.frame.origin.y = label.frame.maxY + 8

        view.addSubview(badges)
    }

    func makeBadge(title: String) -> UIView {
        let badge = UILabel()
        badge.text = title
        badge.font = UIFont.systemFont(ofSize: 12)
        badge.textAlignment = .center
        badge.textColor = .white
        badge.backgroundColor = .systemPurple
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        badge.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        badge.heightAnchor.constraint(equalToConstant: 24).isActive = true
        badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        return badge
    }

    func progressThisMonth() -> Float {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let totalDays = calendar.range(of: .day, in: .month, for: now)?.count else {
            return 0.0
        }
        let activeDays = Set(workouts.filter { monthInterval.contains($0.date) }.map {
            calendar.startOfDay(for: $0.date)
        }).count
        return Float(activeDays) / Float(totalDays)
    }

    func currentStreak() -> Int {
        let calendar = Calendar.current
        let sortedDates = workouts.map { calendar.startOfDay(for: $0.date) }.sorted(by: >)
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            if date == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if date < expectedDate {
                break
            }
        }
        return streak
    }

    func setsThisWeek() -> Int {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return workouts.filter { weekInterval.contains($0.date) }
                       .reduce(0) { $0 + $1.reps }
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

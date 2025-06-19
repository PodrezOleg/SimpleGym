//
//  HistoryCalendarViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

import UIKit
import FSCalendar

class HistoryCalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UITableViewDataSource {

    let calendar = FSCalendar()
    let tableView = UITableView()
    var selectedDate: Date = Date()
    var exercises: [ExerciseEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "История"
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.2, blue: 0.4, alpha: 1.0) // фиолетовый для тёмной темы
                : UIColor(red: 1.0, green: 0.94, blue: 0.94, alpha: 1.0) // светло-розовый для светлой
        }

        calendar.dataSource = self
        calendar.delegate = self

        // Calendar appearance customization
        calendar.appearance.eventDefaultColor = UIColor.purple
        calendar.appearance.todayColor = UIColor(red: 1.0, green: 0.85, blue: 0.95, alpha: 1.0)
        calendar.appearance.selectionColor = UIColor.purple
        calendar.appearance.titleTodayColor = .black
        calendar.appearance.titleDefaultColor = .black
        calendar.appearance.titleWeekendColor = UIColor(red: 0.7, green: 0.6, blue: 0.6, alpha: 1.0)
        calendar.appearance.borderRadius = 0.9
        calendar.appearance.caseOptions = [.weekdayUsesSingleUpperCase, .headerUsesUpperCase]
        calendar.appearance.headerDateFormat = "MMMM yyyy"
        calendar.appearance.weekdayTextColor = UIColor.purple
        calendar.appearance.headerTitleColor = UIColor.purple
        calendar.appearance.titleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        calendar.appearance.weekdayFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        calendar.appearance.headerTitleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        calendar.firstWeekday = 2

        calendar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self

        view.addSubview(calendar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar.heightAnchor.constraint(equalToConstant: 300),

            tableView.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        loadExercises(for: selectedDate)
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        loadExercises(for: date)
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let key = formattedDateKey(for: date)
        let stored = ExerciseStorage.shared.load(for: key)
        return stored.isEmpty ? 0 : 1
    }

    func loadExercises(for date: Date) {
        let key = formattedDateKey(for: date)
        exercises = ExerciseStorage.shared.loadExercises(forKey: key)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let exercise = exercises[indexPath.row]
        cell.textLabel?.text = exercise.name
        let totalSets = exercise.sets.map { "\($0.weight)кг x \($0.reps)" }.joined(separator: ", ")
        cell.detailTextLabel?.text = totalSets
        cell.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.25, blue: 0.5, alpha: 1.0)
                : UIColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0)
        }
        cell.textLabel?.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.purple
        }
        cell.detailTextLabel?.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.purple
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exercise = exercises[indexPath.row]
        let message = exercise.sets.map { "\($0.weight) кг x \($0.reps)" }.joined(separator: "\n")
        
        let alert = UIAlertController(title: exercise.name, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func formattedDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "exercises-\(formatter.string(from: date))"
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        let key = formattedDateKey(for: date)
        let stored = ExerciseStorage.shared.load(for: key)
        return stored.isEmpty ? nil : UIColor.systemGreen.withAlphaComponent(0.3)
    }
}

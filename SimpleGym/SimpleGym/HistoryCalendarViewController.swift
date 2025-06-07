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
        view.backgroundColor = .white

        calendar.frame = CGRect(x: 0, y: 100, width: view.frame.width, height: 300)
        calendar.dataSource = self
        calendar.delegate = self
        // Calendar appearance customization
        calendar.appearance.eventDefaultColor = .systemGreen
        calendar.appearance.todayColor = .clear
        calendar.appearance.selectionColor = .systemGreen
        calendar.appearance.titleTodayColor = .black
        calendar.appearance.titleDefaultColor = .black
        calendar.appearance.titleWeekendColor = .lightGray
        calendar.appearance.borderRadius = 0.9
        calendar.appearance.caseOptions = [.weekdayUsesSingleUpperCase, .headerUsesUpperCase]
        calendar.appearance.headerDateFormat = "MMMM yyyy"
        calendar.appearance.weekdayTextColor = .darkGray
        calendar.appearance.headerTitleColor = .black
        calendar.appearance.titleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        calendar.firstWeekday = 2
        view.addSubview(calendar)

        tableView.frame = CGRect(x: 0, y: 410, width: view.frame.width, height: view.frame.height - 410)
        tableView.dataSource = self
        view.addSubview(tableView)

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
        tableView.reloadData()
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
        return cell
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

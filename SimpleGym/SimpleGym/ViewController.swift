//
//  ViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.




import UIKit
import FSCalendar

enum ProgressChartType {
    case weight
    case reps
}

enum TimeRange {
    case week, month, threeMonths, sixMonths, year
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    enum TimeRange {
        case week, month, threeMonths, sixMonths, year
    }

    var setsPerDay: [String: Int] = [:]
    var workouts: [Workout] = []
    let tableView = UITableView()
    let statsLabel = UILabel()
    var selectedExercise: String?
    var chartType: ProgressChartType = .weight // old
    var selectedRange: TimeRange = .month
    var chartMode: ChartMode = .sets // NEW: default to sets
    var progressLabel: UILabel? // NEW: for progress/regress
    
    enum ChartMode {
        case sets, weight, reps
    }
    
    class ProgressChartView: UIView {
        var values: [Int] = [] // NEW: for sets
        var weightValues: [Int] = []
        var repValues: [Int] = []
        var topLabels: [String] = [] // NEW: labels above bars
        var barColors: [UIColor] = [] // Цвета для столбцов
        var totalValue: Int = 0 // Сумма для подписи
        var totalLabel: String = ""

        func setData(sets: [Int], topLabels: [String]? = nil, barColors: [UIColor]? = nil, totalValue: Int = 0, totalLabel: String = "") {
            values = sets
            self.totalValue = totalValue
            self.totalLabel = totalLabel
            if let topLabels = topLabels {
                self.topLabels = topLabels
            } else {
                self.topLabels = []
            }
            if let barColors = barColors {
                self.barColors = barColors
            } else {
                self.barColors = Array(repeating: UIColor.systemPurple, count: sets.count)
            }
            setNeedsDisplay()
        }
        func setData(weight: [Int], reps: [Int], topLabels: [String]? = nil) {
            weightValues = weight
            repValues = reps
            if let topLabels = topLabels {
                self.topLabels = topLabels
            } else {
                self.topLabels = []
            }
            setNeedsDisplay()
        }

        override func draw(_ rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()
            // Очищаем фон графика
            context?.clear(rect)
            if !values.isEmpty {
                let maxVal = CGFloat(values.max() ?? 1)
                let barMaxHeight = rect.height * 0.75 // 75% высоты
                let barWidth = rect.width / CGFloat(max(values.count, 1)) * 0.7
                let labelFont = UIFont.systemFont(ofSize: 12, weight: .bold)
                for (i, val) in values.enumerated() {
                    let x = CGFloat(i) * rect.width / CGFloat(values.count)
                    let barHeight = maxVal > 0 ? CGFloat(val) / maxVal * barMaxHeight : 0
                    let barRect = CGRect(x: x + barWidth*0.15, y: rect.height - barHeight, width: barWidth, height: barHeight)
                    let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 3)
                    (i < barColors.count ? barColors[i] : UIColor.systemPurple).setFill()
                    barPath.fill()
                    // Draw top label if present
                    if i < topLabels.count, !topLabels[i].isEmpty {
                        let label = topLabels[i] as NSString
                        let labelSize = label.size(withAttributes: [.font: labelFont])
                        let labelX = x + barWidth*0.15 + (barWidth-labelSize.width)/2
                        let labelY = rect.height - barHeight - labelSize.height - 2
                        label.draw(at: CGPoint(x: labelX, y: max(0, labelY)), withAttributes: [
                            .font: labelFont,
                            .foregroundColor: UIColor.systemRed
                        ])
                    }
                }
                // Общая сумма веса/повторов сверху графика
                if !totalLabel.isEmpty && totalLabel != "Всего подходов: 0" {
                    let totalFont = UIFont.boldSystemFont(ofSize: 16)
                    let totalStr = totalLabel as NSString
                    let size = totalStr.size(withAttributes: [.font: totalFont])
                    let x = (rect.width - size.width) / 2
                    let y: CGFloat = 4
                    // Очищаем область перед рисованием новой суммы
                    UIColor.clear.setFill()
                    context?.fill(CGRect(x: 0, y: 0, width: rect.width, height: size.height + 8))
                    totalStr.draw(at: CGPoint(x: x, y: y), withAttributes: [
                        .font: totalFont,
                        .foregroundColor: UIColor.systemGray
                    ])
                }
                return
            }
            // scale both series to same max
            let maxWeight = CGFloat(weightValues.max() ?? 1)
            let maxReps = CGFloat(repValues.max() ?? 1)
            let maxValue = max(maxWeight, maxReps)
            let count = max(weightValues.count, repValues.count)
            let stepX = rect.width / CGFloat(max(count - 1, 1))

            // draw weight line
            let weightPath = UIBezierPath()
            for (i, val) in weightValues.enumerated() {
                let x = CGFloat(i) * stepX
                let y = rect.height - CGFloat(val) / maxValue * rect.height
                if i == 0 { weightPath.move(to: CGPoint(x: x, y: y)) }
                else      { weightPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            UIColor.systemPurple.setStroke()
            weightPath.lineWidth = 2
            weightPath.stroke()

            // draw reps line
            let repsPath = UIBezierPath()
            for (i, val) in repValues.enumerated() {
                let x = CGFloat(i) * stepX
                let y = rect.height - CGFloat(val) / maxValue * rect.height
                if i == 0 { repsPath.move(to: CGPoint(x: x, y: y)) }
                else      { repsPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            UIColor.systemGreen.setStroke()
            repsPath.lineWidth = 2
            repsPath.stroke()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "💪 Gym Tracker"
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.0, blue: 0.3, alpha: 1.0) // dark purple
                : UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0) // warm pink
        }

        loadWorkouts()
        loadSetsCountFromStorage()

        let alert = UIAlertController(title: "🎉 Ты крутыха!", message: "Как будешь жать 25кг, приложение можно удалять)))", preferredStyle: .alert)
        DispatchQueue.main.async {
            self.present(alert, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
      
        setupAddButton()
        setupStatsLabel()
        updateStats()
        setupRingChart()
        setupWeeklyBarChart()
        setupBadgesSection()
    }


    func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        addButton.tintColor = .purple
        navigationItem.rightBarButtonItem = addButton
    }

    func setupStatsLabel() {
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsLabel)
        NSLayoutConstraint.activate([
            statsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
        statsLabel.textAlignment = .center
        statsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        statsLabel.textColor = .systemPurple
        statsLabel.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.0, blue: 0.4, alpha: 1.0)
                : UIColor.systemGray6
        }
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
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
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
        workouts = []
        let all = ExerciseStorage.shared.load()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for (key, entries) in all {
            // key is like "exercises-YYYY-MM-DD"
            // extract the date part after the first "-"
            let parts = key.split(separator: "-")
            guard parts.count > 1 else { continue }
            let datePart = parts.dropFirst().joined(separator: "-")
            guard let date = formatter.date(from: datePart) else { continue }

            for entry in entries {
                for set in entry.sets {
                    if let reps = Int(set.reps), let weight = Int(set.weight) {
                        workouts.append(Workout(name: entry.name, reps: reps, weight: weight, date: date))
                    }
                }
            }
        }
    }

    func updateStats() {
        let total = workouts.reduce(0) { $0 + $1.reps }
        let streak = currentStreak()
        let weekly = setsThisWeek()
        let avgReps = workouts.isEmpty ? 0 : total / workouts.count
        let avgWeight = workouts.isEmpty ? 0 : workouts.reduce(0) { $0 + $1.weight } / workouts.count
        statsLabel.text = "Total reps: \(total) • Avg: \(avgReps)x\(avgWeight) • Week: \(weekly) • 🔥\(streak)-day streak"
    }

    func setupRingChart() {
        let ring = UIProgressView(progressViewStyle: .bar)
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.progressTintColor = .systemPurple
        ring.trackTintColor = .systemGray4
        ring.progress = progressThisMonth()
        ring.layer.cornerRadius = 10
        ring.clipsToBounds = true
        // Content hugging & compression resistance
        ring.setContentHuggingPriority(.defaultHigh, for: .vertical)
        ring.setContentCompressionResistancePriority(.required, for: .vertical)
        view.addSubview(ring)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .lightGray : .darkGray
        }
        label.text = "Прогресс за месяц"
        // Content hugging & compression resistance
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 20),
            ring.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ring.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ring.heightAnchor.constraint(equalToConstant: 20),

            label.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: ring.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: ring.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func setupWeeklyBarChart() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        let barStack = UIStackView()
        barStack.translatesAutoresizingMaskIntoConstraints = false
        barStack.axis = .horizontal
        barStack.distribution = .fillEqually
        barStack.spacing = 4
        // Content hugging & compression resistance
        barStack.setContentHuggingPriority(.defaultHigh, for: .vertical)
        barStack.setContentCompressionResistancePriority(.required, for: .vertical)

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

        view.addSubview(barStack)

        if let ring = view.subviews.first(where: { $0 is UIProgressView }) {
            NSLayoutConstraint.activate([
                barStack.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 30),
                barStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                barStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                barStack.heightAnchor.constraint(equalToConstant: 50)
            ])
        } else {
            NSLayoutConstraint.activate([
                barStack.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 70),
                barStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                barStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                barStack.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }

    func setupBadgesSection() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(container)

        // Time range selector
        let rangeSegment = UISegmentedControl(items: ["Неделя","Месяц","3М","6М","Год"])
        rangeSegment.translatesAutoresizingMaskIntoConstraints = false
        rangeSegment.selectedSegmentIndex = 1
        rangeSegment.addTarget(self, action: #selector(rangeChanged(_:)), for: .valueChanged)
        container.addSubview(rangeSegment)

        // Заголовок
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "📈 Средний прогресс по упражнениям"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        container.addSubview(label)

        // Legend: purple = weight, green = reps
        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 12
        legendStack.alignment = .center
        legendStack.translatesAutoresizingMaskIntoConstraints = false

        let purpleDot = UIView()
        purpleDot.backgroundColor = .systemPurple
        purpleDot.layer.cornerRadius = 5
        purpleDot.translatesAutoresizingMaskIntoConstraints = false
        purpleDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        purpleDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let purpleLabel = UILabel()
        purpleLabel.text = "Вес"
        purpleLabel.font = UIFont.systemFont(ofSize: 12)

        let greenDot = UIView()
        greenDot.backgroundColor = .systemGreen
        greenDot.layer.cornerRadius = 5
        greenDot.translatesAutoresizingMaskIntoConstraints = false
        greenDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        greenDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let greenLabel = UILabel()
        greenLabel.text = "Повторы"
        greenLabel.font = UIFont.systemFont(ofSize: 12)

        legendStack.addArrangedSubview(purpleDot)
        legendStack.addArrangedSubview(purpleLabel)
        legendStack.addArrangedSubview(greenDot)
        legendStack.addArrangedSubview(greenLabel)
        container.addSubview(legendStack)

        // Picker для выбора упражнения
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.dataSource = self
        picker.delegate = self
        container.addSubview(picker)

        // График прогресса
        let chartView = ProgressChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chartView)
        self.chartView = chartView // сохраним для обновления

        // NEW: Progress label
        let progressLabel = UILabel()
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.textAlignment = .center
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        container.addSubview(progressLabel)
        self.progressLabel = progressLabel

        // Данные для picker'а
        let exerciseNames = Array(Set(workouts.map { $0.name })).sorted()
        self.exerciseNames = exerciseNames

        // Стартовые значения
        selectedExercise = exerciseNames.first
        updateChart(for: selectedExercise ?? "")

        // Constraints
        let bottomView = view.subviews.first(where: { $0 is UIStackView && ($0 as! UIStackView).axis == .horizontal })!
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            container.topAnchor.constraint(equalTo: scrollView.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            rangeSegment.topAnchor.constraint(equalTo: container.topAnchor),
            rangeSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rangeSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rangeSegment.heightAnchor.constraint(equalToConstant: 32),

            label.topAnchor.constraint(equalTo: rangeSegment.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 30),

            label.bottomAnchor.constraint(equalTo: legendStack.topAnchor, constant: -8),
            legendStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            legendStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            legendStack.heightAnchor.constraint(equalToConstant: 18),

            legendStack.bottomAnchor.constraint(equalTo: picker.topAnchor, constant: -8),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 100),

            chartView.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chartView.heightAnchor.constraint(equalToConstant: 200),
            progressLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progressLabel.heightAnchor.constraint(equalToConstant: 20),
            progressLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
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
    // Для работы Picker и графика
    var exerciseNames: [String] = []
    var chartView: ProgressChartView!

    // UIPickerViewDataSource & Delegate
    @objc func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    @objc func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return exerciseNames.count
    }
    @objc func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return exerciseNames[row]
    }
    @objc func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedExercise = exerciseNames[row]
        updateChart(for: selectedExercise ?? "")
    }

    // Сегмент выбора типа -- removed

    // Time range segmented control handler
    @objc func rangeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: selectedRange = .week
        case 1: selectedRange = .month
        case 2: selectedRange = .threeMonths
        case 3: selectedRange = .sixMonths
        case 4: selectedRange = .year
        default: selectedRange = .month
        }
        updateChart(for: selectedExercise ?? "")
    }

    func filteredSessions(_ sessions: [Workout]) -> [Workout] {
        let now = Date()
        let calendar = Calendar.current
        let cutoff: Date
        switch selectedRange {
        case .week: cutoff = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month: cutoff = calendar.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths: cutoff = calendar.date(byAdding: .month, value: -3, to: now)!
        case .sixMonths: cutoff = calendar.date(byAdding: .month, value: -6, to: now)!
        case .year: cutoff = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        return sessions.filter { $0.date >= cutoff }
    }

    // Обновление графика
    func updateChart(for exercise: String) {
        if chartMode == .sets {
            let (setsPerDay, progressText, topLabels, barColors, totalValue, totalLabel) = setsChartDataWithProgress(for: selectedRange, exercise: selectedExercise)
            chartView.setData(sets: setsPerDay, topLabels: topLabels, barColors: barColors, totalValue: totalValue, totalLabel: totalLabel)
            progressLabel?.text = progressText
        } else {
            let allSessions = workouts.filter { $0.name == exercise }.sorted { $0.date < $1.date }
            let recent = filteredSessions(allSessions)
            let weightSeries = recent.map { $0.weight }
            let repsSeries   = recent.map { $0.reps }
            let (topLabels, _) = weightAndSetsDiffLabels(for: recent)
            chartView.setData(weight: weightSeries, reps: repsSeries, topLabels: topLabels)
            progressLabel?.text = nil
        }
    }
    // Новый метод: абсолютные значения, цвет, общая сумма
    func setsChartDataWithProgress(for range: TimeRange, exercise: String?) -> ([Int], String, [String], [UIColor], Int, String) {
        let calendar = Calendar.current
        let now = Date()
        var days: [Date] = []
        var label = ""
        switch range {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: now)!
            days = (0...6).map { calendar.date(byAdding: .day, value: $0, to: start)! }
            label = "неделю"
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            let daysCount = calendar.dateComponents([.day], from: start, to: now).day ?? 30
            days = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: start)! }
            label = "месяц"
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            let daysCount = calendar.dateComponents([.day], from: start, to: now).day ?? 90
            days = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: start)! }
            label = "3 месяца"
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            let daysCount = calendar.dateComponents([.day], from: start, to: now).day ?? 180
            days = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: start)! }
            label = "6 месяцев"
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            let daysCount = calendar.dateComponents([.day], from: start, to: now).day ?? 365
            days = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: start)! }
            label = "год"
        }
        let filteredWorkouts = workouts.filter { exercise == nil || $0.name == exercise }
        var setsByDay: [Date: Int] = [:]
        for day in days {
            let count = filteredWorkouts.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            setsByDay[calendar.startOfDay(for: day)] = count
        }
        let setsPerDay = days.map { setsByDay[calendar.startOfDay(for: $0)] ?? 0 }
        // Цвета: если больше предыдущего — зелёный, меньше — красный, иначе фиолетовый
        var barColors: [UIColor] = []
        for i in 0..<setsPerDay.count {
            if i == 0 {
                barColors.append(.systemPurple)
            } else if setsPerDay[i] > setsPerDay[i-1] {
                barColors.append(.systemGreen)
            } else if setsPerDay[i] < setsPerDay[i-1] {
                barColors.append(.systemRed)
            } else {
                barColors.append(.systemPurple)
            }
        }
        // Общая сумма подходов
        let total = setsPerDay.reduce(0, +)
        let totalLabel = "Всего подходов: \(total)"
        // Прогресс/регресс по сравнению с предыдущим периодом
        let prevDays: [Date]
        switch range {
        case .week:
            let prevStart = calendar.date(byAdding: .day, value: -13, to: now)!
            prevDays = (0...6).map { calendar.date(byAdding: .day, value: $0, to: prevStart)! }
        case .month:
            let prevStart = calendar.date(byAdding: .month, value: -2, to: now)!
            let daysCount = days.count
            prevDays = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: prevStart)! }
        case .threeMonths:
            let prevStart = calendar.date(byAdding: .month, value: -6, to: now)!
            let daysCount = days.count
            prevDays = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: prevStart)! }
        case .sixMonths:
            let prevStart = calendar.date(byAdding: .month, value: -12, to: now)!
            let daysCount = days.count
            prevDays = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: prevStart)! }
        case .year:
            let prevStart = calendar.date(byAdding: .year, value: -2, to: now)!
            let daysCount = days.count
            prevDays = (0..<daysCount).map { calendar.date(byAdding: .day, value: $0, to: prevStart)! }
        }
        let prevSets = prevDays.map { day in
            filteredWorkouts.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
        }
        let prevTotal = prevSets.reduce(0, +)
        let diff = total - prevTotal
        let progressText: String
        if diff > 0 {
            progressText = "↑ +\(diff) подходов vs прошлый \(label)"
        } else if diff < 0 {
            progressText = "↓ \(abs(diff)) подходов vs прошлый \(label)"
        } else {
            progressText = "= Без изменений vs прошлый \(label)"
        }
        // Подписи над столбцами: разница с предыдущим днём
        var topLabels: [String] = []
        for i in 0..<setsPerDay.count {
            let prevVal = i > 0 ? setsPerDay[i-1] : 0
            let diff = setsPerDay[i] - prevVal
            topLabels.append(diff > 0 ? "+\(diff)" : (diff < 0 ? "\(diff)" : ""))
        }
        return (setsPerDay, progressText, topLabels, barColors, total, totalLabel)
    }
    // Для weight/reps графика: прирост веса и подходов
    func weightAndSetsDiffLabels(for sessions: [Workout]) -> ([String], [String]) {
        var weightLabels: [String] = []
        var setsLabels: [String] = []
        for i in 0..<sessions.count {
            let prevW = i > 0 ? sessions[i-1].weight : 0
            let diffW = sessions[i].weight - prevW
            weightLabels.append(diffW > 0 ? "+\(diffW)" : (diffW < 0 ? "\(diffW)" : ""))
            // Для подходов: считаем по дате
            let prevDate = i > 0 ? sessions[i-1].date : nil
            let prevSets = prevDate != nil ? workouts.filter { $0.name == sessions[i].name && Calendar.current.isDate($0.date, inSameDayAs: prevDate!) }.count : 0
            let currSets = workouts.filter { $0.name == sessions[i].name && Calendar.current.isDate($0.date, inSameDayAs: sessions[i].date) }.count
            let diffSets = currSets - prevSets
            setsLabels.append(diffSets > 0 ? "+\(diffSets)" : (diffSets < 0 ? "\(diffSets)" : ""))
        }
        // Для weight графика используем weightLabels
        return (weightLabels, setsLabels)
    }
}

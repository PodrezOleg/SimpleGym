//
//  WorkoutDetailViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

import UIKit
import FSCalendar

class WorkoutDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDelegate, FSCalendarDataSource {
    let popularExerciseNames: [String] = [
        "Жим лежа", "Приседания со штангой", "Становая тяга", "Армейский жим",
        "Подтягивания", "Отжимания", "Сгибание рук со штангой", "Французский жим",
        "Тяга штанги в наклоне", "Тяга верхнего блока", "Тяга нижнего блока",
        "Разводка гантелей лёжа", "Пуловер", "Жим гантелей на наклонной",
        "Разгибание ног", "Сгибание ног лёжа", "Махи в стороны", "Махи назад",
        "Планка", "Скручивания", "Обратные скручивания", "Подъем ног в висе",
        "Жим платформы", "Подъем на носки сидя", "Гиперэкстензия",
        "Тяга гантели одной рукой", "Тяга Т-грифа", "Жим штанги узким хватом",
        "Шраги", "Отведение ноги назад в тренажёре"
    ]
    let tableView = UITableView()
    var exercises: [ExerciseEntry] = []
    var currentDate: Date = Date()
    let weekCalendar = FSCalendar()
    
    var savedExerciseNames: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: "savedExerciseNames") ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "savedExerciseNames")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExercises(for: currentDate)
        if savedExerciseNames.isEmpty {
            savedExerciseNames = defaultExercises().map { $0.name }
        }
        saveExercises(for: currentDate)
        title = "Workout"
        view.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.94, alpha: 1.0) // теплый розовый
        
        let dateLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateLabel.text = "Сегодня: \(dateFormatter.string(from: Date()))"
        dateLabel.textColor = .purple
        dateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        dateLabel.textAlignment = .center
        dateLabel.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.88, alpha: 1.0) // чуть темнее розового
        dateLabel.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 50, width: view.frame.width, height: 30)
        view.addSubview(dateLabel)
        
        tableView.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 88, width: view.frame.width, height: view.frame.height - (view.safeAreaInsets.top + 88))
        tableView.dataSource = self
        tableView.delegate = self
        //        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExercise))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.purple
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Популярные", style: .plain, target: self, action: #selector(showPopularExercises))
        navigationItem.leftBarButtonItem?.tintColor = UIColor.purple
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exercises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        let entry = exercises[indexPath.row]
        cell.textLabel?.text = entry.name
        let totalSets = entry.sets.enumerated().map { index, set in
            return "Подход \(index + 1): \(set.weight)кг x \(set.reps)"
        }.joined(separator: "\n")
        cell.detailTextLabel?.text = totalSets
        // Custom cell appearance
        cell.backgroundColor = UIColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0) // светло-розовый
        cell.textLabel?.textColor = UIColor.purple
        cell.detailTextLabel?.textColor = UIColor.purple
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = exercises[indexPath.row]
        
        let editorVC = SetEditorViewController()
        editorVC.exerciseName = entry.name
        editorVC.sets = entry.sets
        editorVC.exerciseIndex = indexPath.row
        editorVC.onSave = { updatedSets in
            if updatedSets.isEmpty {
                self.exercises.remove(at: indexPath.row) // ❗️Удаляем упражнение
            } else {
                self.exercises[indexPath.row].sets = updatedSets
            }
            self.tableView.reloadData() // ✅ Обновляем таблицу
            self.saveExercises(for: self.currentDate)
        }
        navigationController?.pushViewController(editorVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func formattedDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "exercises-\(formatter.string(from: date))"
    }
    
    func saveExercises(for date: Date) {
        let key = formattedDateKey(for: date)
        ExerciseStorage.shared.update(for: key, exercises: exercises)
    }
    
    func loadExercises(for date: Date) {
        let key = formattedDateKey(for: date)
        exercises = ExerciseStorage.shared.load(for: key)
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
    
    @objc func addExercise() {
        let alert = UIAlertController(title: "Новое упражнение", message: "Выберите или введите", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Название"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .sentences
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        
        alert.addAction(UIAlertAction(title: "Добавить", style: .default, handler: { _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            if !self.savedExerciseNames.contains(name) {
                self.savedExerciseNames.append(name)
            }
            self.exercises.append(ExerciseEntry(name: name, sets: [ExerciseSet(weight: "0", reps: "0")]))
            self.tableView.reloadData()
            self.saveExercises(for: self.currentDate)
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let input = textField.text?.lowercased(), !input.isEmpty else { return }
        
        if let match = savedExerciseNames.first(where: { $0.lowercased().hasPrefix(input) }) {
            let currentText = textField.text ?? ""
            if match != currentText {
                textField.text = match
                if let startPosition = textField.position(from: textField.beginningOfDocument, offset: input.count),
                   let endPosition = textField.position(from: startPosition, offset: match.count - input.count) {
                    textField.selectedTextRange = textField.textRange(from: startPosition, to: endPosition)
                }
            }
        }
    }
    
    @objc func showPopularExercises() {
        let alert = UIAlertController(title: "Популярные упражнения", message: "Выберите одно", preferredStyle: .actionSheet)
        for name in self.popularExerciseNames {
            alert.addAction(UIAlertAction(title: name, style: .default, handler: { _ in
                if !self.savedExerciseNames.contains(name) {
                    self.savedExerciseNames.append(name)
                }
                self.exercises.append(ExerciseEntry(name: name, sets: [ExerciseSet(weight: "0", reps: "0")]))
                self.tableView.reloadData()
                self.saveExercises(for: self.currentDate)
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        self.present(alert, animated: true)
    }
}

extension WorkoutDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return savedExerciseNames.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return savedExerciseNames[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 999,
           let alert = presentedViewController as? UIAlertController,
           let textField = alert.textFields?.first {
            textField.text = savedExerciseNames[row]
        }
    }
}

extension WorkoutDetailViewController {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        currentDate = date
        loadExercises(for: currentDate)
        tableView.reloadData()
    }
}

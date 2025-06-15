//
//  SetEditorViewController.swift
//  SimpleGym
//
//  Created by Oleg Podrez on 7.06.25.
//

import UIKit

final class SetEditorViewController: UIViewController {

    var exerciseName: String = ""
    var sets: [ExerciseSet] = []
    var onSave: (([ExerciseSet]) -> Void)?
    var exerciseIndex: Int?
    
    private let stackView = UIStackView()
    private let scrollView = UIScrollView()
    private var nextTagIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.13, blue: 0.33, alpha: 1.0) // тёмно-фиолетовый, как в WorkoutDetailViewController
                : UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1.0) // розовый для светлой
        }
        title = exerciseName

        setupLayout()
        loadSetFields()
        setupSaveButton()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    private func loadSetFields() {
        nextTagIndex = sets.count * 2
        for (index, set) in sets.enumerated() {
            let container = UIStackView()
            container.axis = .vertical
            container.spacing = 8

            let title = UILabel()
            title.text = "Подход \(index + 1)"
            title.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            title.textColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0) // Бежевый для тёмной темы
                    : UIColor.purple // Фиолетовый для светлой темы
            }
            container.addArrangedSubview(title)

            let weightRow = UIStackView()
            weightRow.axis = .horizontal
            weightRow.spacing = 8
            weightRow.distribution = .fill
            let weightLabel = UILabel()
            weightLabel.text = "Вес:"
            weightLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
            weightLabel.textColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                    : UIColor.purple
            }
            weightLabel.setContentHuggingPriority(.required, for: .horizontal)
            let weightField = UITextField()
            weightField.placeholder = "Вес (кг)"
            weightField.text = set.weight
            weightField.borderStyle = .roundedRect
            weightField.keyboardType = .decimalPad
            weightField.tag = index * 2
            weightField.textColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? .white
                    : UIColor.purple
            }
            weightField.translatesAutoresizingMaskIntoConstraints = false
            weightField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            weightRow.addArrangedSubview(weightLabel)
            weightRow.addArrangedSubview(weightField)
            container.addArrangedSubview(weightRow)

            let repsRow = UIStackView()
            repsRow.axis = .horizontal
            repsRow.spacing = 8
            repsRow.distribution = .fill
            let repsLabel = UILabel()
            repsLabel.text = "Повт:"
            repsLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
            repsLabel.textColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                    : UIColor.purple
            }
            repsLabel.setContentHuggingPriority(.required, for: .horizontal)
            let repsField = UITextField()
            repsField.placeholder = "Повторения"
            repsField.text = set.reps
            repsField.borderStyle = .roundedRect
            repsField.keyboardType = .numberPad
            repsField.tag = index * 2 + 1
            repsField.textColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark
                    ? .white
                    : UIColor.purple
            }
            repsField.translatesAutoresizingMaskIntoConstraints = false
            repsField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            repsRow.addArrangedSubview(repsLabel)
            repsRow.addArrangedSubview(repsField)
            container.addArrangedSubview(repsRow)

            stackView.addArrangedSubview(container)
        }
    }

    private func setupSaveButton() {
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Удалить упражнение", for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteExerciseTapped), for: .touchUpInside)
        stackView.addArrangedSubview(deleteButton)

        let button = UIButton(type: .system)
        button.setTitle("Сохранить", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.6, green: 0.8, blue: 0.6, alpha: 1.0) // бледно-зелёный для тёмной темы
                : UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0) // бледно-зелёный для светлой темы
        }
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stackView.addArrangedSubview(button)

        let addSetButton = UIButton(type: .system)
        addSetButton.setTitle("Добавить подход", for: .normal)
        addSetButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addSetButton.setTitleColor(UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                : UIColor.purple
        }, for: .normal)
        addSetButton.addTarget(self, action: #selector(addSetTapped), for: .touchUpInside)
        stackView.insertArrangedSubview(addSetButton, at: stackView.arrangedSubviews.count - 1)
    }

    @objc private func saveTapped() {
        var updatedSets: [ExerciseSet] = []

        for arranged in stackView.arrangedSubviews {
            guard let container = arranged as? UIStackView else { continue }
            let fields = container.arrangedSubviews.compactMap { subview -> UITextField? in
                if let stack = subview as? UIStackView {
                    return stack.arrangedSubviews.compactMap { $0 as? UITextField }.first
                }
                return nil
            }
            if fields.count == 2 {
                let weight = fields[0].text ?? "0"
                let reps = fields[1].text ?? "0"
                updatedSets.append(ExerciseSet(weight: weight, reps: reps))
            }
        }

        onSave?(updatedSets)
        navigationController?.popViewController(animated: true)
    }

    @objc private func addSetTapped() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let title = UILabel()
        title.text = "Подход \(stackView.arrangedSubviews.count - 1 + 1)"
        title.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        title.textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                : UIColor.purple
        }
        container.addArrangedSubview(title)

        let weightRow = UIStackView()
        weightRow.axis = .horizontal
        weightRow.spacing = 8
        weightRow.distribution = .fill
        let weightLabel = UILabel()
        weightLabel.text = "Вес:"
        weightLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        weightLabel.textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                : UIColor.purple
        }
        weightLabel.setContentHuggingPriority(.required, for: .horizontal)
        let weightField = UITextField()
        weightField.placeholder = "Вес (кг)"
        weightField.borderStyle = .roundedRect
        weightField.keyboardType = .decimalPad
        weightField.tag = nextTagIndex
        weightField.textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? .white
                : UIColor.purple
        }
        weightField.translatesAutoresizingMaskIntoConstraints = false
        weightField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nextTagIndex += 1
        weightRow.addArrangedSubview(weightLabel)
        weightRow.addArrangedSubview(weightField)
        container.addArrangedSubview(weightRow)

        let repsRow = UIStackView()
        repsRow.axis = .horizontal
        repsRow.spacing = 8
        repsRow.distribution = .fill
        let repsLabel = UILabel()
        repsLabel.text = "Повт:"
        repsLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        repsLabel.textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.87, blue: 0.74, alpha: 1.0)
                : UIColor.purple
        }
        repsLabel.setContentHuggingPriority(.required, for: .horizontal)
        let repsField = UITextField()
        repsField.placeholder = "Повторения"
        repsField.borderStyle = .roundedRect
        repsField.keyboardType = .numberPad
        repsField.tag = nextTagIndex
        repsField.textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? .white
                : UIColor.purple
        }
        repsField.translatesAutoresizingMaskIntoConstraints = false
        repsField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nextTagIndex += 1
        repsRow.addArrangedSubview(repsLabel)
        repsRow.addArrangedSubview(repsField)
        container.addArrangedSubview(repsRow)

        stackView.insertArrangedSubview(container, at: stackView.arrangedSubviews.count - 1)
    }

    @objc private func deleteExerciseTapped() {
        let alert = UIAlertController(title: "Удалить упражнение", message: "Вы уверены, что хотите удалить это упражнение?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { _ in
            self.onSave?([])
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    // MARK: - Keyboard Handling

    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottomInset = keyboardFrame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset + 16
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset + 16
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - WorkoutFileStorage importWorkouts(from data:) refactor
// Replace or add the following method to WorkoutFileStorage.swift:
/*
func importWorkouts(from data: Data) throws {
    let decoded = try JSONDecoder().decode([String: [ExerciseEntry]].self, from: data)
    for (date, entries) in decoded {
        let key = "exercises-\(date)"
        ExerciseStorage.shared.update(for: key, exercises: entries)
    }
    print("✅ Workouts imported from file successfully.")
}
*/

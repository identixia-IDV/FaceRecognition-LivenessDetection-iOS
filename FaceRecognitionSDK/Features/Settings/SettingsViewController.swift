import UIKit
import FaceRecognitionKit

/// Android `SettingsActivity` + labels from `strings.xml` / `root_preferences.xml`.
final class SettingsViewController: UIViewController {
    private struct ThresholdRow {
        let title: String
        let key: String
        let min: Float
        let max: Float
    }

    private struct PickerConfig {
        let title: String
        let key: String
        let options: [(String, String)]
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var valueLabels: [String: UILabel] = [:]
    private var pickerConfigs: [String: PickerConfig] = [:]
    private var thresholdRowsByKey: [String: ThresholdRow] = [:]

    private let thresholdRows: [ThresholdRow] = [
        ThresholdRow(title: "Identity hold (sec)", key: "identity_hold_duration", min: 0.1, max: 5),
        ThresholdRow(title: "Liveness", key: "liveness_threshold", min: 0, max: 1),
        ThresholdRow(title: "Identify", key: "identify_threshold", min: 0, max: 1),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        for row in thresholdRows { thresholdRowsByKey[row.key] = row }

        view.backgroundColor = IXColor.bg
        title = "Settings"
        ScreenChrome.showInnerBar(on: self)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
        ])

        contentStack.addArrangedSubview(cameraSection())
        contentStack.addArrangedSubview(identitySection())
        contentStack.addArrangedSubview(thresholdsSection())
        contentStack.addArrangedSubview(resetSection())
        refreshAllValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
        refreshAllValues()
    }

    private func cameraSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(sectionTitle("Camera"))
        stack.addArrangedSubview(pickerRow(PickerConfig(
            title: "Camera lens",
            key: "camera_lens",
            options: [("Front", "front"), ("Back", "back")]
        )))
        stack.addArrangedSubview(pickerRow(PickerConfig(
            title: "Landmark mode",
            key: "landmark_mode",
            options: [("14 points", "14"), ("68 points", "68")]
        )))
        return wrapCard(stack)
    }

    private func identitySection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.addArrangedSubview(sectionTitle("Identity capture"))
        for key in ["identity_hold_duration"] {
            if let row = thresholdRowsByKey[key] {
                stack.addArrangedSubview(thresholdRow(row))
            }
        }
        return wrapCard(stack)
    }

    private func thresholdsSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.addArrangedSubview(sectionTitle("Thresholds"))
        for key in ["liveness_threshold", "identify_threshold"] {
            if let row = thresholdRowsByKey[key] {
                stack.addArrangedSubview(thresholdRow(row))
            }
        }
        return wrapCard(stack)
    }

    private func resetSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(sectionTitle("Reset"))

        let restore = makeActionButton(title: "Restore default settings", filled: true)
        restore.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        stack.addArrangedSubview(restore)

        let clear = makeActionButton(title: "Clear all person", filled: false)
        clear.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        stack.addArrangedSubview(clear)

        return wrapCard(stack)
    }

    private func pickerRow(_ config: PickerConfig) -> UIView {
        pickerConfigs[config.key] = config
        let valueLabel = UILabel()
        valueLabel.textColor = IXColor.muted
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textAlignment = .right
        valueLabels[config.key] = valueLabel

        let button = UIButton(type: .system)
        button.accessibilityIdentifier = config.key
        button.addTarget(self, action: #selector(pickerRowTapped(_:)), for: .touchUpInside)
        return tappableRow(title: config.title, valueLabel: valueLabel, button: button)
    }

    private func thresholdRow(_ row: ThresholdRow) -> UIView {
        let valueLabel = UILabel()
        valueLabel.textColor = IXColor.muted
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textAlignment = .right
        valueLabels[row.key] = valueLabel

        let button = UIButton(type: .system)
        button.accessibilityIdentifier = row.key
        button.addTarget(self, action: #selector(thresholdRowTapped(_:)), for: .touchUpInside)
        return tappableRow(title: row.title, valueLabel: valueLabel, button: button)
    }

    private func tappableRow(title: String, valueLabel: UILabel, button: UIButton) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = IXColor.text
        titleLabel.font = .systemFont(ofSize: 15)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = IXColor.muted
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel, chevron])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.isUserInteractionEnabled = false

        button.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.addSubview(row)
        container.addSubview(button)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func makeActionButton(title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(filled ? IXColor.onAccent : IXColor.accent, for: .normal)
        button.backgroundColor = filled ? IXColor.accent : IXColor.surfaceAlt
        button.layer.cornerRadius = 10
        button.layer.borderWidth = filled ? 0 : 1
        button.layer.borderColor = IXColor.stroke.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }

    private func wrapCard(_ stack: UIStackView) -> UIView {
        let card = UIView()
        card.backgroundColor = IXColor.surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = IXColor.stroke.cgColor
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = IXColor.text
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }

    private func refreshAllValues() {
        valueLabels["camera_lens"]?.text = displayValue(for: "camera_lens")
        valueLabels["landmark_mode"]?.text = displayValue(for: "landmark_mode")
        for row in thresholdRows {
            valueLabels[row.key]?.text = storedString(for: row.key)
        }
    }

    private func storedString(for key: String) -> String {
        UserDefaults.standard.string(forKey: key) ?? defaultValue(for: key)
    }

    private func displayValue(for key: String) -> String {
        let raw = storedString(for: key)
        switch key {
        case "camera_lens": return raw == "back" ? "Back" : "Front"
        case "landmark_mode": return raw == "14" ? "14 points" : "68 points"
        default: return raw
        }
    }

    private func defaultValue(for key: String) -> String {
        switch key {
        case "camera_lens": return AppSettings.defaultCameraLens
        case "landmark_mode": return AppSettings.defaultLandmarkMode
        case "liveness_threshold": return AppSettings.defaultLivenessThreshold
        case "identify_threshold": return AppSettings.defaultIdentifyThreshold
        case "identity_hold_duration": return AppSettings.defaultIdentityHoldDuration
        default: return ""
        }
    }

    @objc private func pickerRowTapped(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier,
              let config = pickerConfigs[key] else { return }
        let alert = UIAlertController(title: config.title, message: nil, preferredStyle: .actionSheet)
        for (label, value) in config.options {
            alert.addAction(UIAlertAction(title: label, style: .default) { [weak self] _ in
                UserDefaults.standard.set(value, forKey: key)
                self?.refreshAllValues()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(alert, animated: true)
    }

    @objc private func thresholdRowTapped(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier,
              let row = thresholdRowsByKey[key] else { return }
        let alert = UIAlertController(title: row.title, message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = self.storedString(for: row.key)
            field.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self,
                  let text = alert.textFields?.first?.text,
                  let value = Float(text),
                  value >= row.min, value <= row.max else {
                self?.presentToast("Invalid value")
                return
            }
            UserDefaults.standard.set(text, forKey: row.key)
            self.refreshAllValues()
        })
        present(alert, animated: true)
    }

    @objc private func restoreTapped() {
        AppSettings.restoreDefaults()
        refreshAllValues()
        presentToast("Restored default settings")
    }

    @objc private func clearTapped() {
        FaceRecognitionClient.shared.clearEnrolled()
        presentToast("Cleared all person")
    }

    private func presentToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { alert.dismiss(animated: true) }
    }
}

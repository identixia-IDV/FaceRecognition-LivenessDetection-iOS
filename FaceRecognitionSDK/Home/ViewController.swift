import UIKit
import FaceRecognitionKit

/// Android `MainActivity` — Attribute & Liveness / Identity / Settings+About.
final class ViewController: UIViewController {
    /// Demo license for bundle id `com.identixia.facerecognitionsdk.app`.
    private let licenseKey =
        "pyyR2AEC7zN9Wyn4DBl07NPyfaywEidEJ5iCMkvLK4NNlWEAAAAKsSdB19zDzr1Vb0Joycs44e7Xoj1qDdD9jAxxAnUjTrtkMinvn6ocX55WUWLDe+oUOWLFfXwj/TmcgPrH6TqP06K52Il6WcH6tdYpdWKwhvwtSlhavSoYCWv/vQ1DwX+LZwAwZQIwLo5QslAL/4V5OmHqaTblNmOLnu+0dpiPpn6PJCPB7SNUuzTpO1gk46nJInIaqbSqAjEAs0lliuO0Ecgj+Op5hJkye7wU/QS16TC+7EgNjnq4ibKC/a7RlFYLFg+MLS1MJNyM"

    private let licenseChip = UILabel()
    private let statusChip = UILabel()
    private let warningLabel = UILabel()
    private var modeButtons: [UIControl] = []
    private var sdkReady = false
    private var sdkLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        AppSettings.applyEngineDefaults()
        view.backgroundColor = IXColor.bg
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        activateSDK()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        view.addSubview(scroll)

        styleChip(licenseChip, text: "License…")
        styleChip(statusChip, text: "Loading…")
        statusChip.font = .systemFont(ofSize: 13, weight: .bold)
        let licensePad = padChip(licenseChip)
        let statusPad = padChip(statusChip)
        let chips = UIStackView(arrangedSubviews: [licensePad, statusPad])
        chips.axis = .horizontal
        chips.spacing = 12
        chips.distribution = .fill
        licensePad.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusPad.setContentHuggingPriority(.required, for: .horizontal)

        let attrModes: [FaceMode] = [
            .faceDetect, .faceAttribute, .imageQuality, .landmarks, .match, .liveness,
        ]
        let attrButtons = attrModes.map { makeModeCell($0) }
        modeButtons.append(contentsOf: attrButtons)
        let attrRow1 = equalRow(Array(attrButtons.prefix(3)))
        let attrRow2 = equalRow(Array(attrButtons.suffix(3)))
        let attrPanel = cardStack([attrRow1, attrRow2], spacing: 8)

        let idModes: [FaceMode] = [.enroll, .identity, .enrolledList]
        let idButtons = idModes.map { makeModeTile($0, emphasized: $0 == .identity) }
        modeButtons.append(contentsOf: idButtons)
        let idRow = equalRow(idButtons, height: 112)

        let settings = makeUtilityTile(title: "Settings", systemImage: "gearshape", action: #selector(openSettings))
        let about = makeUtilityTile(title: "About", systemImage: "info.circle", action: #selector(openAbout))
        let utilRow = equalRow([settings, about], height: 112)

        warningLabel.text = "Starting SDK…"
        warningLabel.textColor = IXColor.text
        warningLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        warningLabel.textAlignment = .center
        warningLabel.backgroundColor = IXColor.surface
        warningLabel.layer.cornerRadius = 10
        warningLabel.layer.borderWidth = 1
        warningLabel.layer.borderColor = IXColor.stroke.cgColor
        warningLabel.clipsToBounds = true
        warningLabel.numberOfLines = 0

        let brand = UIButton(type: .system)
        brand.setTitle("identixia.com", for: .normal)
        brand.setTitleColor(IXColor.muted, for: .normal)
        brand.titleLabel?.font = .systemFont(ofSize: 14)
        brand.addTarget(self, action: #selector(openBrand), for: .touchUpInside)

        content.addArrangedSubview(chips)
        content.addArrangedSubview(sectionLabel("Attribute & Liveness"))
        content.addArrangedSubview(attrPanel)
        content.addArrangedSubview(sectionLabel("Identity"))
        content.addArrangedSubview(idRow)
        content.addArrangedSubview(utilRow)
        content.addArrangedSubview(warningLabel)
        content.addArrangedSubview(brand)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            attrRow1.heightAnchor.constraint(equalToConstant: 96),
            attrRow2.heightAnchor.constraint(equalToConstant: 96),
            warningLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        setModesEnabled(false)
    }

    private func styleChip(_ label: UILabel, text: String) {
        label.text = text
        label.textColor = IXColor.text
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    private func padChip(_ label: UILabel) -> UIView {
        let box = UIView()
        box.backgroundColor = IXColor.surface
        box.layer.cornerRadius = 10
        box.layer.borderWidth = 1
        box.layer.borderColor = IXColor.stroke.cgColor
        box.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10),
        ])
        return box
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = IXColor.muted
        label.font = .systemFont(ofSize: 13, weight: .bold)
        return label
    }

    private func cardStack(_ rows: [UIView], spacing: CGFloat) -> UIView {
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = spacing
        let card = UIView()
        card.backgroundColor = IXColor.surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = IXColor.stroke.cgColor
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    private func equalRow(_ views: [UIView], height: CGFloat? = nil) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        if let height {
            row.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        return row
    }

    private func makeModeCell(_ mode: FaceMode) -> UIControl {
        let button = ModeTileControl(
            title: mode.title,
            systemImage: mode.systemImage,
            emphasized: false,
            compact: true
        )
        button.accessibilityIdentifier = mode.rawValue
        button.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeModeTile(_ mode: FaceMode, emphasized: Bool) -> UIControl {
        let button = ModeTileControl(
            title: mode.title,
            systemImage: mode.systemImage,
            emphasized: emphasized,
            compact: false
        )
        button.accessibilityIdentifier = mode.rawValue
        button.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeUtilityTile(title: String, systemImage: String, action: Selector) -> UIControl {
        let button = ModeTileControl(
            title: title,
            systemImage: systemImage,
            emphasized: false,
            compact: false
        )
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func modeTapped(_ sender: UIControl) {
        guard let id = sender.accessibilityIdentifier else { return }
        openMode(FaceMode.fromName(id))
    }

    private func openMode(_ mode: FaceMode) {
        guard ensureReady(mode) else { return }
        if mode == .enrolledList {
            navigationController?.pushViewController(EnrolledListViewController(), animated: true)
            return
        }
        navigationController?.pushViewController(ModeCameraViewController(mode: mode), animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func openAbout() {
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }

    @objc private func openBrand() {
        guard let url = URL(string: "https://identixia.com") else { return }
        UIApplication.shared.open(url)
    }

    private func activateSDK() {
        sdkLoading = true
        setModesEnabled(false)
        warningLabel.isHidden = false
        warningLabel.text = "Starting SDK…"
        licenseChip.text = "License…"
        statusChip.text = "Loading…"
        FaceRecognitionClient.shared.activate(license: licenseKey) { [weak self] code in
            guard let self else { return }
            self.sdkLoading = false
            self.sdkReady = code == 0
            if self.sdkReady {
                FaceRecognitionClient.shared.loadDatabase()
                self.applyReady()
            } else {
                self.setModesEnabled(false)
                let status = FaceRecognitionClient.shared.getLicenseStatus()
                self.licenseChip.text = status.label.isEmpty ? "No license" : status.label
                self.statusChip.text = "Failed"
                self.warningLabel.isHidden = false
                self.warningLabel.text = switch code {
                case 1: "Invalid license!"
                case 2: "License expired"
                case 3: "No activated!"
                default: "Init error!"
                }
            }
        }
    }

    private func applyReady() {
        setModesEnabled(true)
        let status = FaceRecognitionClient.shared.getLicenseStatus()
        licenseChip.text = status.label.isEmpty ? "Ready" : status.label
        statusChip.text = "Ready"
        if let missing = status.missingDatabasesMessage() {
            warningLabel.isHidden = false
            warningLabel.text = missing
            presentToast(missing)
        } else {
            warningLabel.isHidden = true
        }
    }

    private func setModesEnabled(_ enabled: Bool) {
        for button in modeButtons {
            button.isEnabled = enabled
            button.isUserInteractionEnabled = enabled
            button.alpha = enabled ? 1 : 0.45
        }
    }

    private func ensureReady(_ mode: FaceMode) -> Bool {
        if !sdkReady {
            presentToast(sdkLoading ? "Starting SDK…" : "SDK is not ready")
            return false
        }
        let license = FaceRecognitionClient.shared.getLicenseStatus()
        if mode.needsRecognition && !license.recognition {
            presentToast("This license does not include recognition")
            return false
        }
        if mode.needsLiveness && !license.liveness {
            presentToast("This license does not include liveness")
            return false
        }
        return true
    }

    private func presentToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

private final class ModeTileControl: UIControl {
    private let icon = UIImageView()
    private let caption = UILabel()

    init(title: String, systemImage: String, emphasized: Bool, compact: Bool) {
        super.init(frame: .zero)
        backgroundColor = emphasized ? IXColor.accent : IXColor.surfaceAlt
        layer.cornerRadius = 12
        layer.borderWidth = emphasized ? 0 : 1
        layer.borderColor = IXColor.stroke.cgColor
        clipsToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: compact ? 22 : 28, weight: .regular)
        icon.image = UIImage(systemName: systemImage, withConfiguration: config)
        icon.tintColor = emphasized ? IXColor.onAccent : IXColor.accent
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false

        caption.text = title
        caption.textColor = emphasized ? IXColor.onAccent : IXColor.text
        caption.font = .systemFont(ofSize: compact ? 12 : 14, weight: .semibold)
        caption.textAlignment = .center
        caption.numberOfLines = 2
        caption.adjustsFontSizeToFitWidth = true
        caption.minimumScaleFactor = 0.75
        caption.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [icon, caption])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = compact ? 8 : 10
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            icon.widthAnchor.constraint(equalToConstant: compact ? 28 : 36),
            icon.heightAnchor.constraint(equalToConstant: compact ? 28 : 36),
        ])

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    required init?(coder: NSCoder) { nil }

    @objc private func touchDown() { alpha = 0.75 }
    @objc private func touchUp() { alpha = isEnabled ? 1 : 0.45 }
}

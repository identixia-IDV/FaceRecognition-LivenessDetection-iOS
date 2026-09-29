import AVFoundation
import PhotosUI
import UIKit
import FaceRecognitionKit

/// Android `ModeCameraActivity` — still modes + identity hold circle.
final class ModeCameraViewController: BaseCameraViewController {
    private let mode: FaceMode
    private let overlay = FaceIdentifyOverlayView()
    private let identityGuide = IdentityGuideView()
    private let hintLabel = UILabel()
    private let identityHint = UILabel()
    private let captureButton = UIButton(type: .system)
    private let galleryButton = UIButton(type: .system)
    private let flipButton = UIButton(type: .system)
    private let bottomBar = UIStackView()

    private let overlayFlags: FaceRecognitionDetectFlags = [.pose, .eyes, .landmarks]
    private var resultOpened = false
    private var frameBusy = false
    private var confirming = false
    private var enrollPromptOpen = false
    private var captureArmed = false
    private var oddImage: UIImage?
    private var lastFrame: UIImage?
    private var identityOkSince: TimeInterval = 0
    private var lastIdentityState: FaceCaptureState = .noFace

    init(mode: FaceMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.title
        FaceRecognitionClient.shared.loadDatabase()
        setupChrome()
        if mode == .identity {
            overlay.isHidden = true
            identityGuide.isHidden = false
            bottomBar.isHidden = true
            galleryButton.isHidden = true
            identityHint.isHidden = false
            identityHint.text = IdentityCapture.message(for: .noFace)
            identityGuide.setGuideState(.noFace, progress: 0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mode == .identity && !resultOpened {
            confirming = false
            identityOkSince = 0
            lastIdentityState = .noFace
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if mode == .identity {
            identityOkSince = 0
            identityGuide.setGuideState(.noFace, progress: 0)
        }
    }

    private func setupChrome() {
        overlay.translatesAutoresizingMaskIntoConstraints = false
        identityGuide.translatesAutoresizingMaskIntoConstraints = false
        identityGuide.isHidden = true
        view.addSubview(overlay)
        view.addSubview(identityGuide)

        hintLabel.text = mode == .match ? "Capture face 1" : "Align your face, then tap capture"
        hintLabel.textColor = .white
        hintLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        identityHint.textColor = .white
        identityHint.font = .systemFont(ofSize: 17, weight: .semibold)
        identityHint.textAlignment = .center
        identityHint.numberOfLines = 2
        identityHint.isHidden = true
        identityHint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(identityHint)

        configureCircleButton(captureButton, systemName: "circle.fill", size: 64)
        captureButton.tintColor = IXColor.accent
        captureButton.addTarget(self, action: #selector(onCapture), for: .touchUpInside)

        configureCircleButton(galleryButton, systemName: "photo.on.rectangle", size: 44)
        galleryButton.addTarget(self, action: #selector(onGallery), for: .touchUpInside)

        configureCircleButton(flipButton, systemName: "arrow.triangle.2.circlepath.camera", size: 44)
        flipButton.addTarget(self, action: #selector(onFlip), for: .touchUpInside)

        bottomBar.axis = .horizontal
        bottomBar.alignment = .center
        bottomBar.distribution = .equalCentering
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addArrangedSubview(galleryButton)
        bottomBar.addArrangedSubview(captureButton)
        bottomBar.addArrangedSubview(flipButton)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: cameraView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            identityGuide.topAnchor.constraint(equalTo: cameraView.topAnchor),
            identityGuide.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            identityGuide.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            identityGuide.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            hintLabel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -16),
            identityHint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            identityHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            identityHint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            bottomBar.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    private func configureCircleButton(_ button: UIButton, systemName: String, size: CGFloat) {
        let config = UIImage.SymbolConfiguration(pointSize: size == 64 ? 54 : 22, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
    }

    @objc private func onFlip() {
        flipCamera()
        identityOkSince = 0
    }

    @objc private func onGallery() {
        guard mode != .identity else { return }
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            presentToast("Photo picker requires iOS 14+")
        }
    }

    @objc private func onCapture() {
        guard mode != .identity, !resultOpened else { return }
        if frameBusy {
            captureArmed = true
            return
        }
        guard let buffered = lastFrame else {
            captureArmed = true
            return
        }
        frameBusy = true
        beginSDKWork()
        FaceRecognitionClient.shared.async { [weak self] in
            defer {
                self?.frameBusy = false
                self?.endSDKWork()
            }
            self?.onStableFace(buffered)
        }
    }

    override func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        guard !resultOpened else { return }
        guard let prepared = CameraFrameUtils.liveEngineImage(
            from: sampleBuffer,
            frontCamera: useFrontCamera
        ) else { return }

        if mode == .identity {
            analyzeIdentityFrame(prepared)
        } else {
            analyzeStillMode(prepared)
        }
    }

    private func analyzeStillMode(_ bitmap: UIImage) {
        guard !frameBusy else { return }
        frameBusy = true
        beginSDKWork()
        FaceRecognitionClient.shared.async { [weak self] in
            guard let self else { return }
            defer {
                self.frameBusy = false
                self.endSDKWork()
            }
            guard !self.resultOpened else { return }
            let json = FaceRecognitionClient.shared.detect(bitmap, crop: false, flags: self.overlayFlags)
            let faces = json.map { FaceJSON.parseDetect($0, source: bitmap) } ?? []
            DispatchQueue.main.async {
                self.overlay.update(faces: faces, frameSize: bitmap.size, mirror: self.useFrontCamera)
            }
            self.lastFrame = bitmap
            if self.captureArmed {
                self.captureArmed = false
                self.onStableFace(bitmap)
            }
        }
    }

    private func analyzeIdentityFrame(_ bitmap: UIImage) {
        guard !frameBusy, !confirming, !resultOpened else { return }
        frameBusy = true
        beginSDKWork()
        FaceRecognitionClient.shared.async { [weak self] in
            guard let self else { return }
            defer {
                self.frameBusy = false
                self.endSDKWork()
            }
            guard !self.resultOpened, !self.confirming else { return }
            let json = FaceRecognitionClient.shared.detect(bitmap, crop: false, flags: self.overlayFlags)
            let faces = json.map { FaceJSON.parseDetect($0, source: bitmap) } ?? []
            let state = IdentityCapture.evaluate(faces: faces, frameSize: bitmap.size)
            let now = Date().timeIntervalSince1970 * 1000
            let holdMs = AppSettings.identityHoldDurationMs
            self.lastFrame = bitmap

            var progress: CGFloat = 0
            var shouldCapture = false
            if state == .captureOk {
                if self.identityOkSince == 0 || self.lastIdentityState != .captureOk {
                    self.identityOkSince = now
                }
                let elapsed = now - self.identityOkSince
                progress = CGFloat(min(1, max(0, elapsed / holdMs)))
                if elapsed >= holdMs { shouldCapture = true }
            } else {
                self.identityOkSince = 0
                progress = 1
            }
            self.lastIdentityState = state

            DispatchQueue.main.async {
                guard !self.resultOpened else { return }
                self.identityGuide.setGuideState(state, progress: progress)
                self.identityHint.text = IdentityCapture.message(for: state)
                self.identityHint.textColor = {
                    switch state {
                    case .captureOk: return IXColor.statusOk
                    case .noFace: return .white
                    case .multipleFaces, .faceOccluded, .spoofedFace: return IXColor.statusError
                    default: return UIColor(red: 0.706, green: 0.325, blue: 0.035, alpha: 1)
                    }
                }()
            }

            if shouldCapture && !self.confirming {
                self.confirming = true
                guard let capture = self.lastFrame else {
                    self.confirming = false
                    self.identityOkSince = 0
                    return
                }
                DispatchQueue.main.async {
                    self.identityHint.text = "Capturing…"
                    self.identityGuide.setGuideState(.captureOk, progress: 1)
                }
                self.finishIdentityCapture(capture, faces: faces)
            }
        }
    }

    private func onStableFace(_ bitmap: UIImage) {
        guard !resultOpened else { return }
        switch mode {
        case .match:
            handleMatch(bitmap)
        case .enroll:
            handleEnroll(bitmap)
        case .landmarks:
            handleLandmarks(bitmap)
        case .faceDetect, .faceAttribute, .imageQuality, .liveness:
            guard !resultOpened else { return }
            resultOpened = true
            let json = FaceRecognitionSDKQueue.analyzeMode(
                mode.analysisMode,
                image: bitmap,
                landmarkMode: AppSettings.landmarkMode
            )
            let thumb = cropLargestFace(bitmap) ?? bitmap
            openResult(json: json, thumb: thumb)
        case .identity, .enrolledList:
            break
        }
    }

    private func handleLandmarks(_ bitmap: UIImage) {
        guard !resultOpened else { return }
        resultOpened = true
        let json = FaceRecognitionSDKQueue.analyzeMode(
            .landmarks,
            image: bitmap,
            landmarkMode: AppSettings.landmarkMode
        )
        let faces = json.map { FaceJSON.parseDetect($0, source: bitmap) } ?? []
        let best = faces.max(by: { $0.region.width * $0.region.height < $1.region.width * $1.region.height })
        let crop = best.flatMap { FaceUtils.cropFace(from: bitmap, face: $0) } ?? bitmap
        let landmarks = best.map { FaceUtils.mapLandmarksToCrop(face: $0, cropSize: crop.size) } ?? []
        openResult(json: json, thumb: crop, landmarks: landmarks)
    }

    private func handleMatch(_ bitmap: UIImage) {
        if oddImage == nil {
            oddImage = bitmap
            DispatchQueue.main.async { self.hintLabel.text = "Capture face 2" }
            return
        }
        guard !resultOpened, let odd = oddImage else { return }
        resultOpened = true
        let json = FaceRecognitionSDKQueue.analyzeMode(.match, image: bitmap, odd: odd)
        let thumb1 = cropLargestFace(odd) ?? odd
        let thumb2 = cropLargestFace(bitmap) ?? bitmap
        oddImage = nil
        openResult(json: json, thumb: thumb1, thumb2: thumb2)
    }

    private func handleEnroll(_ bitmap: UIImage) {
        guard !enrollPromptOpen, !resultOpened else { return }
        let featureJson = FaceRecognitionSDKQueue.analyzeMode(.enroll, image: bitmap)
        let feature = featureJson.flatMap { FaceJSON.parseFeatureData($0) }
        guard let feature, !feature.isEmpty else {
            DispatchQueue.main.async { self.presentToast("Enrollment failed") }
            return
        }
        enrollPromptOpen = true
        let crop = cropLargestFace(bitmap) ?? bitmap
        DispatchQueue.main.async { self.promptEnrollName(feature: feature, thumb: crop) }
    }

    private func promptEnrollName(feature: Data, thumb: UIImage) {
        let alert = UIAlertController(title: "Person name", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.enrollPromptOpen = false
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            self.enrollPromptOpen = false
            let name = alert.textFields?.first?.text ?? ""
            guard let person = FaceRecognitionClient.shared.enroll(
                name: name.isEmpty ? "Person\(Int.random(in: 10000..<20000))" : name,
                feature: feature,
                thumbnail: thumb
            ) else {
                self.presentToast("Enrollment failed")
                return
            }
            guard !self.resultOpened else { return }
            self.resultOpened = true
            let payload: [String: Any] = [
                "success": true,
                "mode": FaceMode.enroll.rawValue,
                "id": person.id,
                "name": person.name,
                "createdAt": person.createdAt.timeIntervalSince1970,
            ]
            let json = (try? JSONSerialization.data(withJSONObject: payload)).flatMap {
                String(data: $0, encoding: .utf8)
            }
            self.openResult(json: json, thumb: thumb)
        })
        present(alert, animated: true)
    }

    private func finishIdentityCapture(_ bitmap: UIImage, faces: [DetectedFace]) {
        guard !resultOpened else {
            confirming = false
            return
        }
        resultOpened = true
        let feature = FaceRecognitionClient.shared.extractFeature(from: bitmap)
        let threshold = AppSettings.identifyThreshold
        let best = feature.flatMap { FaceRecognitionClient.shared.bestMatch(for: $0, threshold: threshold) }
        let cropFace = faces.max(by: { $0.region.width * $0.region.height < $1.region.width * $1.region.height })
        let thumb = cropFace.flatMap { FaceUtils.cropFace(from: bitmap, face: $0) } ?? bitmap
        let enrolledThumb = best.flatMap { FaceRecognitionClient.shared.thumbnail(for: $0.person) }
        var payload: [String: Any] = [
            "success": best != nil,
            "mode": FaceMode.identity.rawValue,
            "matched": best != nil,
        ]
        if let best {
            payload["name"] = best.person.name
            payload["id"] = best.person.id
            payload["score"] = best.score
        }
        let json = (try? JSONSerialization.data(withJSONObject: payload)).flatMap {
            String(data: $0, encoding: .utf8)
        }
        openResult(json: json, thumb: thumb, thumb2: enrolledThumb, title: "Identify Result")
    }
}

@available(iOS 14.0, *)
extension ModeCameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        handlePicked(results: results, picker: picker)
    }
}

extension ModeCameraViewController {
    @available(iOS 14.0, *)
    fileprivate func handlePicked(results: [PHPickerResult], picker: PHPickerViewController) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            let prepared = CameraFrameUtils.enginePreparedImage(image)
            FaceRecognitionClient.shared.async {
                switch self.mode {
                case .match: self.handleMatch(prepared)
                case .enroll: self.handleEnroll(prepared)
                case .landmarks: self.handleLandmarks(prepared)
                case .identity:
                    let faces = FaceRecognitionClient.shared.faceDetection(
                        from: prepared,
                        purpose: .fullAttributes
                    )
                    self.finishIdentityCapture(prepared, faces: faces)
                default:
                    guard !self.resultOpened else { return }
                    self.resultOpened = true
                    let json = FaceRecognitionSDKQueue.analyzeMode(
                        self.mode.analysisMode,
                        image: prepared,
                        landmarkMode: AppSettings.landmarkMode
                    )
                    let thumb = self.cropLargestFace(prepared) ?? prepared
                    self.openResult(json: json, thumb: thumb)
                }
            }
        }
    }

    private func openResult(
        json: String?,
        thumb: UIImage?,
        thumb2: UIImage? = nil,
        landmarks: [CGPoint] = [],
        title: String? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let nav = self.navigationController else { return }
            let vc = ModeResultViewController(
                titleText: title ?? self.mode.title,
                mode: self.mode,
                json: json ?? #"{"success":false,"message":"empty"}"#,
                thumb: thumb,
                thumb2: thumb2,
                landmarks: landmarks
            )
            var stack = nav.viewControllers.filter { $0 !== self }
            stack.append(vc)
            nav.setViewControllers(stack, animated: true)
        }
    }

    private func cropLargestFace(_ bitmap: UIImage) -> UIImage? {
        let json = FaceRecognitionClient.shared.detect(bitmap, crop: false, flags: [.pose])
        let faces = json.map { FaceJSON.parseDetect($0, source: bitmap) } ?? []
        guard let best = faces.max(by: {
            $0.region.width * $0.region.height < $1.region.width * $1.region.height
        }) else { return nil }
        return FaceUtils.cropFace(from: bitmap, face: best)
    }

    private func presentToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

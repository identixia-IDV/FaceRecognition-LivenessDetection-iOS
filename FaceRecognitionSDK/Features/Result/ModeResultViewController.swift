import UIKit
import FaceRecognitionKit

/// Android `ModeResultActivity` — single-scroll friendly result + raw JSON drawer.
final class ModeResultViewController: UIViewController {
    private let titleText: String
    private let mode: FaceMode
    private let json: String
    private let thumb: UIImage?
    private let thumb2: UIImage?
    private let landmarks: [CGPoint]

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let statusLabel = UILabel()
    private let summaryLabel = UILabel()
    private let scoreLabel = UILabel()
    private let fieldsStack = UIStackView()
    private let rawToggle = UIButton(type: .system)
    private let rawLabel = UILabel()

    init(
        titleText: String,
        mode: FaceMode,
        json: String,
        thumb: UIImage?,
        thumb2: UIImage?,
        landmarks: [CGPoint]
    ) {
        self.titleText = titleText
        self.mode = mode
        self.json = json
        self.thumb = thumb
        self.thumb2 = thumb2
        self.landmarks = landmarks
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = IXColor.bg
        title = titleText
        ScreenChrome.showInnerBar(on: self)

        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        let viewModel = buildFriendlyView()
        let statusCard = UIView()
        statusCard.backgroundColor = IXColor.surface
        statusCard.layer.cornerRadius = 16
        statusCard.layer.borderWidth = 1
        statusCard.layer.borderColor = IXColor.stroke.cgColor

        statusLabel.text = viewModel.status
        statusLabel.font = .systemFont(ofSize: 22, weight: .heavy)
        statusLabel.textColor = viewModel.ok ? IXColor.accent : IXColor.statusError
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        summaryLabel.text = viewModel.summary
        summaryLabel.font = .systemFont(ofSize: 14)
        summaryLabel.textColor = IXColor.muted
        summaryLabel.textAlignment = .center
        summaryLabel.numberOfLines = 0

        let statusStack = UIStackView(arrangedSubviews: [statusLabel, summaryLabel])
        statusStack.axis = .vertical
        statusStack.spacing = 6
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(statusStack)
        NSLayoutConstraint.activate([
            statusStack.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            statusStack.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            statusStack.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            statusStack.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -16),
        ])

        scoreLabel.text = viewModel.scoreLabel
        scoreLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        scoreLabel.textColor = IXColor.text
        scoreLabel.isHidden = viewModel.scoreLabel == nil

        fieldsStack.axis = .vertical
        fieldsStack.spacing = 0
        bindFields(viewModel.fields)

        rawToggle.setTitle("Show raw JSON", for: .normal)
        rawToggle.setTitleColor(IXColor.accent, for: .normal)
        rawToggle.contentHorizontalAlignment = .leading
        rawToggle.addTarget(self, action: #selector(toggleRaw), for: .touchUpInside)

        rawLabel.text = prettyJSON(json)
        rawLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        rawLabel.textColor = IXColor.muted
        rawLabel.numberOfLines = 0
        rawLabel.isHidden = true
        rawLabel.isUserInteractionEnabled = true

        content.addArrangedSubview(statusCard)
        content.addArrangedSubview(scoreLabel)
        if let media = buildMedia(ok: viewModel.ok) {
            content.addArrangedSubview(media)
        }
        content.addArrangedSubview(cardWrap(fieldsStack))
        content.addArrangedSubview(rawToggle)
        content.addArrangedSubview(rawLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
    }

    @objc private func toggleRaw() {
        let open = rawLabel.isHidden
        rawLabel.isHidden = !open
        rawToggle.setTitle(open ? "Hide raw JSON" : "Show raw JSON", for: .normal)
    }

    private func buildMedia(ok: Bool) -> UIView? {
        if mode == .landmarks, let thumb {
            let image = LandmarkImageView()
            image.setContent(thumb, landmarks: landmarks)
            image.heightAnchor.constraint(equalToConstant: 220).isActive = true
            return cardWrap(image)
        }
        if mode == .match || mode == .identity {
            guard let thumb else { return nil }
            let leftLabel = mode == .match ? "Face 1" : "Identified"
            let rightLabel = mode == .match ? "Face 2" : "Enrolled"
            let left = labeledThumb(image: thumb, caption: leftLabel)
            let symbol = UILabel()
            symbol.text = ok ? "=" : "≠"
            symbol.font = .systemFont(ofSize: 28, weight: .bold)
            symbol.textColor = ok ? IXColor.accent : IXColor.statusError
            let right = labeledThumb(
                image: thumb2 ?? UIImage(systemName: "person.crop.circle"),
                caption: rightLabel
            )
            let row = UIStackView(arrangedSubviews: [left, symbol, right])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 16
            row.distribution = .fillEqually
            return cardWrap(row)
        }
        if let thumb {
            let caption = mode == .enroll ? "Enrolled" : "Captured face"
            return cardWrap(labeledThumb(image: thumb, caption: caption, tall: true))
        }
        return nil
    }

    private func labeledThumb(image: UIImage?, caption: String, tall: Bool = false) -> UIView {
        let img = UIImageView(image: image)
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.layer.cornerRadius = 12
        img.tintColor = IXColor.accent
        img.backgroundColor = IXColor.surface
        img.translatesAutoresizingMaskIntoConstraints = false
        img.heightAnchor.constraint(equalToConstant: tall ? 180 : 120).isActive = true

        let label = UILabel()
        label.text = caption
        label.font = .systemFont(ofSize: 12)
        label.textColor = IXColor.muted
        label.textAlignment = .center

        let col = UIStackView(arrangedSubviews: [img, label])
        col.axis = .vertical
        col.spacing = 6
        col.alignment = .fill
        return col
    }

    private func cardWrap(_ child: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = IXColor.surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = IXColor.stroke.cgColor
        child.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            child.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            child.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            child.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    private func bindFields(_ fields: [(String, String)]) {
        fieldsStack.arrangedSubviews.forEach {
            fieldsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if fields.isEmpty {
            let empty = UILabel()
            empty.text = "No fields"
            empty.textColor = IXColor.muted
            fieldsStack.addArrangedSubview(empty)
            return
        }
        for (label, value) in fields {
            if label == ResultDetails.section {
                let header = UILabel()
                header.text = value.uppercased()
                header.font = .systemFont(ofSize: 12, weight: .semibold)
                header.textColor = IXColor.accent
                header.layoutMargins = UIEdgeInsets(top: 14, left: 4, bottom: 4, right: 4)
                fieldsStack.addArrangedSubview(pad(header, top: 14, bottom: 4))
                continue
            }
            let title = UILabel()
            title.text = label
            title.font = .systemFont(ofSize: 12)
            title.textColor = IXColor.muted
            let body = UILabel()
            body.text = value
            body.font = .systemFont(ofSize: 15)
            body.textColor = IXColor.text
            body.numberOfLines = 0
            let col = UIStackView(arrangedSubviews: [title, body])
            col.axis = .vertical
            col.spacing = 2
            fieldsStack.addArrangedSubview(pad(col, top: 8, bottom: 8))
        }
    }

    private func pad(_ view: UIView, top: CGFloat, bottom: CGFloat) -> UIView {
        let box = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: box.topAnchor, constant: top),
            view.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 4),
            view.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -4),
            view.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -bottom),
        ])
        return box
    }

    private struct FriendlyView {
        let ok: Bool
        let status: String
        let summary: String
        let scoreLabel: String?
        let fields: [(String, String)]
    }

    private func buildFriendlyView() -> FriendlyView {
        guard let root = parseRoot(json) else {
            return FriendlyView(
                ok: false,
                status: "Failed",
                summary: "No face detected",
                scoreLabel: nil,
                fields: []
            )
        }
        let faces = facesOf(root)
        let score = extractScore(root)
        var fields: [(String, String)] = []
        let threshold = Double(AppSettings.identifyThreshold)

        switch mode {
        case .identity:
            let matched = (root["matched"] as? Bool)
                ?? ((root["name"] as? String)?.isEmpty == false && score != nil)
            let name = (root["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "—"
            if let score { fields.append(("Similarity", formatScore(score))) }
            if let id = root["id"] { fields.append(("Person id", "\(id)")) }
            fields.append(("Name", name))
            return FriendlyView(
                ok: matched,
                status: matched ? "Identified" : "No match",
                summary: matched ? "Matched \(name)" : "No enrolled person matched this face",
                scoreLabel: score.map { "Score \(formatScore($0))" },
                fields: fields
            )
        case .enroll:
            let name = (root["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "—"
            fields.append(("Name", name))
            if let id = root["id"] { fields.append(("Person id", "\(id)")) }
            return FriendlyView(
                ok: (root["success"] as? Bool) ?? true,
                status: "Enrolled",
                summary: "Saved \(name)",
                scoreLabel: nil,
                fields: fields
            )
        case .match:
            let same: Bool
            if let s = root["same"] as? Bool {
                same = s
            } else if let m = root["matched"] as? Bool {
                same = m
            } else if let score {
                same = score >= threshold
            } else {
                same = false
            }
            if let score {
                fields.append((ResultDetails.section, "Match"))
                fields.append(("Similarity", formatScore(score)))
                fields.append(("Threshold", formatScore(threshold)))
                fields.append(("Verdict", same ? "Same person" : "Different person"))
            }
            appendFaceFields(&fields, faces: faces)
            return FriendlyView(
                ok: same,
                status: same ? "Same person" : "Different person",
                summary: score.map { "Similarity \(formatScore($0))" } ?? "No face detected",
                scoreLabel: score.map { "Score \(formatScore($0))" },
                fields: fields
            )
        case .landmarks:
            let count = (faces?.first?["landmarks"] as? [[String: Any]])?.count
                ?? (faces?.first?["facePoints"] as? [[String: Any]])?.count
                ?? 0
            appendFaceFields(&fields, faces: faces)
            return FriendlyView(
                ok: count > 0 || (faces?.count ?? 0) > 0,
                status: "Landmarks",
                summary: count > 0 ? "\(count) points" : "One face",
                scoreLabel: nil,
                fields: fields
            )
        case .liveness:
            let auth = authenticityFromFaces(faces)
            appendFaceFields(&fields, faces: faces, preferAuthenticity: true)
            return FriendlyView(
                ok: auth.ok,
                status: auth.heading,
                summary: (faces?.count ?? 0) > 0 ? "One face" : "No face detected",
                scoreLabel: nil,
                fields: fields
            )
        default:
            let count = faces?.count ?? 0
            let ok = (root["success"] as? Bool)
                ?? (count > 0 || root["result"] != nil || score != nil)
            appendFaceFields(&fields, faces: faces)
            return FriendlyView(
                ok: ok,
                status: ok ? "OK" : "Failed",
                summary: count == 1 ? "One face" : (count > 1 ? "\(count) faces" : "No face detected"),
                scoreLabel: score.map { "Score \(formatScore($0))" },
                fields: fields
            )
        }
    }

    private struct AuthView { let ok: Bool; let heading: String }

    private func authenticityFromFaces(_ faces: [[String: Any]]?) -> AuthView {
        guard let face = faces?.first else { return AuthView(ok: false, heading: "FAKE") }
        let traits = face["traits"] as? [String: Any] ?? face["attributes"] as? [String: Any]
        guard let traits else { return AuthView(ok: false, heading: "FAKE") }
        let live = traits["liveness2d"] as? [String: Any]
            ?? traits["Liveness2D"] as? [String: Any]
            ?? traits["liveness"] as? [String: Any]
        let df = traits["deepfake"] as? [String: Any] ?? traits["Deepfake"] as? [String: Any]
        let liveLabel = live?["value"] as? String ?? ""
        let liveScore = floatValue(live?["confidence"]) ?? 0
        let dfRaw = deepfakeRaw(df)
        let heading = ResultDetails.authenticityHeading(
            score: liveScore,
            liveLabel: liveLabel,
            deepfakeRaw: dfRaw
        )
        return AuthView(ok: heading == "REAL", heading: heading)
    }

    private func appendFaceFields(
        _ fields: inout [(String, String)],
        faces: [[String: Any]]?,
        preferAuthenticity: Bool = false
    ) {
        guard let faces, !faces.isEmpty else { return }
        for (i, face) in faces.enumerated() {
            fields.append((ResultDetails.section, faces.count == 1 ? "Face" : "Face \(i + 1)"))
            if let region = face["box"] as? [String: Any]
                ?? face["faceRegion"] as? [String: Any]
                ?? face["region"] as? [String: Any],
               let box = parseBox(region) {
                fields.append(("Box", "\(box.0), \(box.1) · \(box.2)×\(box.3)"))
            }
            if let pose = face["pose"] as? [String: Any] ?? face["facePose"] as? [String: Any] {
                let yaw = floatValue(pose["yaw"]) ?? 0
                let roll = floatValue(pose["roll"]) ?? 0
                let pitch = floatValue(pose["pitch"]) ?? 0
                fields.append((
                    "Pose",
                    String(format: "yaw %.1f°  roll %.1f°  pitch %.1f°", yaw, roll, pitch)
                ))
            }
            if let traits = face["traits"] as? [String: Any] ?? face["attributes"] as? [String: Any] {
                if preferAuthenticity {
                    appendAuthenticityTraits(&fields, traits: traits)
                }
                for key in traits.keys.sorted() {
                    let lower = key.lowercased()
                    if preferAuthenticity && (lower.contains("liveness") || lower.contains("deepfake")) {
                        continue
                    }
                    let shown: String
                    if lower.contains("deepfake") {
                        shown = ResultDetails.deepfakeText(deepfakeRaw(traits[key]))
                    } else {
                        shown = traitValue(traits[key])
                    }
                    if !shown.isEmpty {
                        fields.append((humanize(key), shown))
                    }
                }
            }
            if let lm = face["landmarks"] as? [[String: Any]] ?? face["facePoints"] as? [[String: Any]],
               !lm.isEmpty {
                fields.append(("Landmarks", "\(lm.count) points"))
            }
        }
    }

    private func appendAuthenticityTraits(_ fields: inout [(String, String)], traits: [String: Any]) {
        let live = traits["liveness2d"] as? [String: Any]
            ?? traits["Liveness2D"] as? [String: Any]
            ?? traits["liveness"] as? [String: Any]
        let df = traits["deepfake"] as? [String: Any] ?? traits["Deepfake"] as? [String: Any]
        let liveLabel = live?["value"] as? String ?? ""
        let liveScore = floatValue(live?["confidence"]) ?? 0
        let dfRaw = deepfakeRaw(df)
        let verdict = ResultDetails.authenticityHeading(
            score: liveScore,
            liveLabel: liveLabel,
            deepfakeRaw: dfRaw
        )
        fields.append((ResultDetails.section, "Authenticity"))
        fields.append(("Verdict", verdict))
        if live != nil {
            fields.append((
                "Liveness",
                ResultDetails.livenessText(
                    score: liveScore,
                    threshold: AppSettings.livenessThreshold,
                    label: liveLabel
                )
            ))
        }
        let dfText = ResultDetails.deepfakeText(dfRaw)
        if !dfText.isEmpty { fields.append(("Deepfake", dfText)) }
    }

    private func deepfakeRaw(_ value: Any?) -> String {
        if let obj = value as? [String: Any] {
            let raw: String
            if let b = obj["value"] as? Bool {
                raw = b ? "true" : "false"
            } else {
                raw = "\(obj["value"] ?? "")"
            }
            if let conf = obj["confidence"] as? NSNumber, !raw.isEmpty {
                return "\(raw) (\(conf))"
            }
            return raw
        }
        if let s = value as? String { return s }
        return ""
    }

    private func facesOf(_ root: [String: Any]) -> [[String: Any]]? {
        if let faces = root["faces"] as? [[String: Any]] { return faces }
        if let result = root["result"] as? [String: Any],
           let faces = result["faces"] as? [[String: Any]] { return faces }
        if let data = root["data"] as? [[String: Any]] { return data }
        if let detects = root["detects"] as? [[String: Any]] {
            var merged: [[String: Any]] = []
            for d in detects {
                if let faces = d["faces"] as? [[String: Any]] {
                    merged.append(contentsOf: faces)
                }
            }
            return merged.isEmpty ? nil : merged
        }
        return nil
    }

    private func extractScore(_ root: [String: Any]) -> Double? {
        if let s = doubleValue(root["score"]) { return s }
        if let s = doubleValue(root["similarity"]) { return s }
        for key in ["pairs", "match"] {
            if let arr = root[key] as? [[String: Any]], let first = arr.first {
                if let s = doubleValue(first["score"]) ?? doubleValue(first["similarity"]) {
                    return s
                }
            }
        }
        return nil
    }

    private func traitValue(_ value: Any?) -> String {
        guard let value, !(value is NSNull) else { return "" }
        if let obj = value as? [String: Any] {
            if let v = obj["value"] as? String, !v.isEmpty { return v }
            if let l = obj["label"] as? String, !l.isEmpty { return l }
            if let c = doubleValue(obj["confidence"]) { return formatScore(c) }
            return "\(obj)"
        }
        if let n = value as? NSNumber {
            let d = n.doubleValue
            if d >= 0 && d <= 1 { return formatScore(d) }
            return String(format: "%.1f", d)
        }
        if let b = value as? Bool { return b ? "Yes" : "No" }
        return "\(value)"
    }

    private func formatScore(_ score: Double) -> String {
        let pct = Int((score * 100).rounded())
        return String(format: "%d%% (%.3f)", max(0, min(100, pct)), score)
    }

    private func humanize(_ key: String) -> String {
        let spaced = key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }

    private func parseRoot(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj
        }
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return ["faces": arr]
        }
        return nil
    }

    private func prettyJSON(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
              let text = String(data: pretty, encoding: .utf8) else {
            return raw.isEmpty ? "{}" : raw
        }
        return text
    }

    private func doubleValue(_ any: Any?) -> Double? {
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private func floatValue(_ any: Any?) -> Float? {
        doubleValue(any).map { Float($0) }
    }

    /// Android ModeResultActivity.parseBox — (x, y, w, h).
    private func parseBox(_ region: [String: Any]) -> (Int, Int, Int, Int)? {
        if region["width"] != nil || region["height"] != nil || region["x"] != nil || region["y"] != nil {
            let x = Int((doubleValue(region["x"]) ?? 0).rounded())
            let y = Int((doubleValue(region["y"]) ?? 0).rounded())
            let w = Int((doubleValue(region["width"]) ?? 0).rounded())
            let h = Int((doubleValue(region["height"]) ?? 0).rounded())
            if w > 0 && h > 0 { return (x, y, w, h) }
        }
        guard let l = doubleValue(region["left"]) ?? doubleValue(region["x1"]),
              let t = doubleValue(region["top"]) ?? doubleValue(region["y1"]),
              let r = doubleValue(region["right"]) ?? doubleValue(region["x2"]),
              let b = doubleValue(region["bottom"]) ?? doubleValue(region["y2"]) else {
            return nil
        }
        let li = Int(l.rounded())
        let ti = Int(t.rounded())
        let w = Int(r.rounded()) - li
        let h = Int(b.rounded()) - ti
        if w <= 0 || h <= 0 { return nil }
        return (li, ti, w, h)
    }
}

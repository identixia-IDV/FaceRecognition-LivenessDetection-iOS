import Foundation

/// Eye openness from engine traits — Android `EyeOpenness`.
public enum EyeOpenness {
    /// Closed-eye score in 0…1 for thresholding, or nil when unknown.
    public static func closedScore(label: String?, confidence: String?) -> Float? {
        let lower = (label ?? "").lowercased()
        if lower.isEmpty { return nil }
        let conf = confidence.flatMap { Float($0) }
        if lower.contains("closed") || (lower.contains("close") && !lower.contains("closer")) {
            guard let conf else { return 0.9 }
            if conf < 0 { return 0.9 }
            if conf > 1 { return 1 }
            return conf
        }
        if lower.contains("open") { return 0 }
        return nil
    }

    public static func closedScore(_ attr: FaceAttribute?) -> Float? {
        guard let attr else { return nil }
        return closedScore(label: attr.value, confidence: attr.confidence)
    }

    public static func isClosed(
        left: FaceAttribute?,
        right: FaceAttribute?,
        threshold: Float
    ) -> Bool {
        let leftScore = closedScore(left)
        let rightScore = closedScore(right)
        if leftScore == nil && rightScore == nil { return false }
        if let leftScore, leftScore > threshold { return true }
        if let rightScore, rightScore > threshold { return true }
        return false
    }
}

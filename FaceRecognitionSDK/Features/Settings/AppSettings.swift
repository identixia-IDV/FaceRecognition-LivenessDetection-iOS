import AVFoundation
import Foundation

/// Mirrors Android `SettingsActivity` preference keys and defaults (schema VW = 4).
enum AppSettings {
    static let defaults = UserDefaults.standard

    static let defaultCameraLens = "front"
    static let defaultLivenessThreshold = "0.5"
    static let defaultIdentifyThreshold = "0.67"
    static let defaultYawThreshold = "40.0"
    static let defaultRollThreshold = "40.0"
    static let defaultPitchThreshold = "40.0"
    static let defaultEyecloseThreshold = "0.5"
    static let defaultIdentityHoldDuration = "0.5"
    static let defaultLandmarkMode = "68"

    private static let prefsSchemaKey = "prefs_schema"
    /// Android `PREFS_SCHEMA_VW` — identity_hold_duration + landmark_mode; drops liveness_level.
    private static let prefsSchemaVW = 4

    /// Write Face SDK defaults once so capture is not stuck on the old 10° / 0.7 prefs.
    static func applyEngineDefaults() {
        if defaults.integer(forKey: prefsSchemaKey) >= prefsSchemaVW { return }
        defaults.set(defaultCameraLens, forKey: "camera_lens")
        defaults.set(defaultLivenessThreshold, forKey: "liveness_threshold")
        defaults.set(defaultIdentifyThreshold, forKey: "identify_threshold")
        defaults.set(defaultYawThreshold, forKey: "yaw_threshold")
        defaults.set(defaultRollThreshold, forKey: "roll_threshold")
        defaults.set(defaultPitchThreshold, forKey: "pitch_threshold")
        defaults.set(defaultEyecloseThreshold, forKey: "eyeclose_threshold")
        defaults.set(defaultIdentityHoldDuration, forKey: "identity_hold_duration")
        defaults.set(defaultLandmarkMode, forKey: "landmark_mode")
        defaults.removeObject(forKey: "liveness_level")
        defaults.set(prefsSchemaVW, forKey: prefsSchemaKey)
    }

    static var useFrontCamera: Bool {
        get { (defaults.string(forKey: "camera_lens") ?? defaultCameraLens) != "back" }
        set { defaults.set(newValue ? "front" : "back", forKey: "camera_lens") }
    }

    static var cameraPosition: AVCaptureDevice.Position {
        useFrontCamera ? .front : .back
    }

    static var livenessThreshold: Float {
        floatPref("liveness_threshold", default: defaultLivenessThreshold)
    }

    static var identifyThreshold: Float {
        floatPref("identify_threshold", default: defaultIdentifyThreshold)
    }

    /// Always High Accuracy (2d_ensemble_heavy). Light model is not shipped.
    static var livenessLevel: Int { 0 }

    static var landmarkMode: Int {
        Int(defaults.string(forKey: "landmark_mode") ?? defaultLandmarkMode) ?? 68
    }

    static var yawThreshold: Float {
        floatPref("yaw_threshold", default: defaultYawThreshold)
    }

    static var rollThreshold: Float {
        floatPref("roll_threshold", default: defaultRollThreshold)
    }

    static var pitchThreshold: Float {
        floatPref("pitch_threshold", default: defaultPitchThreshold)
    }

    static var eyecloseThreshold: Float {
        floatPref("eyeclose_threshold", default: defaultEyecloseThreshold)
    }

    /// Seconds the face must stay valid while the green ring flows before capture.
    static var identityHoldDurationSec: Float {
        let raw = floatPref("identity_hold_duration", default: defaultIdentityHoldDuration)
        return min(5, max(0.1, raw))
    }

    static var identityHoldDurationMs: TimeInterval {
        Double(max(100, identityHoldDurationSec * 1000))
    }

    /// Real vs spoof for Identify / Capture / overlay. Spoof labels always fail.
    static func livenessPassed(score: Float, label: String?) -> Bool {
        let lower = (label ?? "").lowercased()
        if lower.contains("spoof") || lower.contains("fake") { return false }
        return score >= livenessThreshold
    }

    static func restoreDefaults() {
        defaults.set(defaultCameraLens, forKey: "camera_lens")
        defaults.set(defaultLivenessThreshold, forKey: "liveness_threshold")
        defaults.set(defaultIdentifyThreshold, forKey: "identify_threshold")
        defaults.set(defaultYawThreshold, forKey: "yaw_threshold")
        defaults.set(defaultRollThreshold, forKey: "roll_threshold")
        defaults.set(defaultPitchThreshold, forKey: "pitch_threshold")
        defaults.set(defaultEyecloseThreshold, forKey: "eyeclose_threshold")
        defaults.set(defaultIdentityHoldDuration, forKey: "identity_hold_duration")
        defaults.set(defaultLandmarkMode, forKey: "landmark_mode")
        defaults.removeObject(forKey: "liveness_level")
        defaults.set(prefsSchemaVW, forKey: prefsSchemaKey)
    }

    private static func floatPref(_ key: String, default defaultValue: String) -> Float {
        Float(defaults.string(forKey: key) ?? defaultValue) ?? 0
    }
}

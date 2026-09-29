import Foundation

/// Auto-capture gate: single face, pose within thresholds, eyes open, held briefly.
public final class StableFaceGate {
    public struct Thresholds {
        public var yawMax: Float
        public var rollMax: Float
        public var pitchMax: Float
        public var eyeClose: Float
        public var holdSec: Float

        public init(
            yawMax: Float = 40,
            rollMax: Float = 40,
            pitchMax: Float = 40,
            eyeClose: Float = 0.5,
            holdSec: Float = 0.5
        ) {
            self.yawMax = yawMax
            self.rollMax = rollMax
            self.pitchMax = pitchMax
            self.eyeClose = eyeClose
            self.holdSec = holdSec
        }
    }

    private var thresholds: Thresholds
    private var stableSinceMs: TimeInterval = 0
    private var lastOk = false

    public init(thresholds: Thresholds = Thresholds()) {
        self.thresholds = thresholds
    }

    public func update(_ thresholds: Thresholds) {
        self.thresholds = thresholds
    }

    public func reset() {
        stableSinceMs = 0
        lastOk = false
    }

    /// True when the frame should be processed for the current mode.
    public func shouldCapture(faces: [DetectedFace], nowMs: TimeInterval = Date().timeIntervalSince1970 * 1000) -> Bool {
        guard faces.count == 1 else {
            reset()
            return false
        }
        let face = faces[0]
        let poseOk =
            abs(Float(face.yaw)) <= thresholds.yawMax
            && abs(Float(face.roll)) <= thresholds.rollMax
            && abs(Float(face.pitch)) <= thresholds.pitchMax
        let left = face.attributes["EyesLeft"] ?? face.attributes["eyesLeft"] ?? face.attributes["eyeLeft"]
        let right = face.attributes["EyesRight"] ?? face.attributes["eyesRight"] ?? face.attributes["eyeRight"]
        let eyesOk = !EyeOpenness.isClosed(left: left, right: right, threshold: thresholds.eyeClose)
        let ok = poseOk && eyesOk
        if !ok {
            reset()
            return false
        }
        if !lastOk {
            stableSinceMs = nowMs
            lastOk = true
            return false
        }
        let holdMs = Double(max(0.1, min(5, thresholds.holdSec))) * 1000
        if nowMs - stableSinceMs >= holdMs {
            reset()
            return true
        }
        return false
    }
}

import CoreGraphics
import Foundation
import FaceRecognitionKit

enum IdentityCapture {
    static func message(for state: FaceCaptureState) -> String {
        switch state {
        case .noFace: return "Look at the camera"
        case .multipleFaces: return "Only one face"
        case .fitInCircle: return "Fit your face in the circle"
        case .moveCloser: return "Move closer"
        case .noFront: return "Face the camera"
        case .faceOccluded: return "Remove mask / occlusion"
        case .eyeClosed: return "Open your eyes"
        case .mouthOpened: return "Close your mouth"
        case .spoofedFace: return "Spoof detected"
        case .captureOk: return "Hold still…"
        }
    }

    static func evaluate(faces: [DetectedFace], frameSize: CGSize) -> FaceCaptureState {
        if faces.isEmpty { return .noFace }
        if faces.count > 1 { return .multipleFaces }
        return evaluateFace(faces[0], frameSize: frameSize)
    }

    static func roiInFrame(_ frameSize: CGSize) -> CGRect {
        let margin = frameSize.width / 6
        let side = frameSize.width - 2 * margin
        let top = (frameSize.height - side) / 2
        return CGRect(x: margin, y: top, width: side, height: side)
    }

    private static func evaluateFace(_ face: DetectedFace, frameSize: CGSize) -> FaceCaptureState {
        let region = face.region
        var faceLeft = region.minX
        var faceRight = region.maxX
        var faceBottom = region.maxY
        if face.landmarks.count >= 5 {
            faceLeft = face.landmarks.map(\.x).min() ?? faceLeft
            faceRight = face.landmarks.map(\.x).max() ?? faceRight
            faceBottom = face.landmarks.map(\.y).max() ?? faceBottom
        }
        let roi = roiInFrame(frameSize)
        let centerY = region.midY
        let topY = centerY - region.height * 2 / 3
        let interX = max(0, roi.minX - faceLeft) + max(0, faceRight - roi.maxX)
        let interY = max(0, roi.minY - topY) + max(0, faceBottom - roi.maxY)
        if interX / roi.width > 0.03 || interY / roi.height > 0.03 {
            return .fitInCircle
        }
        if region.width * region.height < roi.width * roi.height * 0.30 {
            return .moveCloser
        }
        if abs(face.yaw) > Double(AppSettings.yawThreshold)
            || abs(face.roll) > Double(AppSettings.rollThreshold)
            || abs(face.pitch) > Double(AppSettings.pitchThreshold)
        {
            return .noFront
        }
        let mask = (face.attributes["mask"]?.value
            ?? face.attributes["medicalMask"]?.value
            ?? "").lowercased()
        if mask.contains("yes") || mask.contains("masked") {
            return .faceOccluded
        }
        let left = face.attributes["EyesLeft"] ?? face.attributes["eyesLeft"] ?? face.attributes["eyeLeft"]
        let right = face.attributes["EyesRight"] ?? face.attributes["eyesRight"] ?? face.attributes["eyeRight"]
        if EyeOpenness.isClosed(left: left, right: right, threshold: AppSettings.eyecloseThreshold) {
            return .eyeClosed
        }
        return .captureOk
    }
}

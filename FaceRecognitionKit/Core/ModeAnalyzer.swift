import UIKit

/// Per-mode still analysis — Android `ModeAnalyzer` / Windows Gradio tab mapping.
public enum ModeAnalyzer {
    public enum Mode: String {
        case faceDetect = "FACE_DETECT"
        case faceAttribute = "FACE_ATTRIBUTE"
        case imageQuality = "IMAGE_QUALITY"
        case landmarks = "LANDMARKS"
        case match = "MATCH"
        case liveness = "LIVENESS"
        case enroll = "ENROLL"
        case identity = "IDENTITY"
        case enrolledList = "ENROLLED_LIST"
    }

    private static let faceDetectFlags: FaceRecognitionDetectFlags = [.pose]
    private static let faceAttributeFlags: FaceRecognitionDetectFlags = [
        .pose, .age, .gender, .emotion, .mask, .glasses, .eyes,
    ]
    private static let imageQualityFlags: FaceRecognitionDetectFlags = [
        .pose, .quality, .faceQuality,
    ]
    private static let landmarksFlags: FaceRecognitionDetectFlags = [.pose, .landmarks]

    /// Call on the SDK queue (or via `FaceRecognitionSDKQueue.sync`).
    public static func analyze(
        mode: Mode,
        image: UIImage,
        odd: UIImage? = nil,
        landmarkMode: Int = 68
    ) -> String? {
        switch mode {
        case .faceDetect:
            return FaceRecognitionSDK.detect(image, crop: false, flags: faceDetectFlags)
        case .faceAttribute:
            return FaceRecognitionSDK.detect(image, crop: false, flags: faceAttributeFlags)
        case .imageQuality:
            return FaceRecognitionSDK.qualityImage(image, crop: false)
                ?? FaceRecognitionSDK.detect(image, crop: false, flags: imageQualityFlags)
        case .landmarks:
            _ = FaceRecognitionSDK.setLandmarkMode(Int32(landmarkMode))
            return FaceRecognitionSDK.detect(image, crop: false, flags: landmarksFlags)
        case .match:
            guard let odd else { return nil }
            return FaceRecognitionSDK.matchImage1(odd, image2: image, crop: false)
        case .liveness:
            return FaceRecognitionSDK.livenessAllImage(image)
        case .enroll:
            return FaceRecognitionSDK.extractFeature(from: image)
        case .identity, .enrolledList:
            return FaceRecognitionSDK.detect(image, crop: false, flags: faceDetectFlags)
        }
    }

    public static func analyze(
        modeName: String,
        image: UIImage,
        odd: UIImage? = nil,
        landmarkMode: Int = 68
    ) -> String? {
        guard let mode = Mode(rawValue: modeName) else { return nil }
        return analyze(mode: mode, image: image, odd: odd, landmarkMode: landmarkMode)
    }
}

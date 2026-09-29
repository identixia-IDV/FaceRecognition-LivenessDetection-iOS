import Foundation
import FaceRecognitionKit

/// Demo modes — Android `FaceMode` / FaceRecognition-LivenessDetection-Windows Gradio tabs.
enum FaceMode: String, CaseIterable {
    case faceDetect = "FACE_DETECT"
    case faceAttribute = "FACE_ATTRIBUTE"
    case imageQuality = "IMAGE_QUALITY"
    case landmarks = "LANDMARKS"
    case match = "MATCH"
    case liveness = "LIVENESS"
    case enroll = "ENROLL"
    case identity = "IDENTITY"
    case enrolledList = "ENROLLED_LIST"

    var title: String {
        switch self {
        case .faceDetect: return "Face detect"
        case .faceAttribute: return "Face attribute"
        case .imageQuality: return "Image quality"
        case .landmarks: return "Landmarks"
        case .match: return "Match"
        case .liveness: return "Liveness"
        case .enroll: return "Enroll"
        case .identity: return "Identity"
        case .enrolledList: return "Enrolled list"
        }
    }

    var needsRecognition: Bool {
        switch self {
        case .liveness: return false
        default: return true
        }
    }

    var needsLiveness: Bool {
        self == .liveness
    }

    var analysisMode: ModeAnalyzer.Mode {
        ModeAnalyzer.Mode(rawValue: rawValue) ?? .faceDetect
    }

    var systemImage: String {
        switch self {
        case .faceDetect: return "camera.viewfinder"
        case .faceAttribute: return "person.crop.rectangle"
        case .imageQuality: return "slider.horizontal.3"
        case .landmarks: return "point.3.connected.trianglepath.dotted"
        case .match: return "person.2"
        case .liveness: return "faceid"
        case .enroll: return "person.badge.plus"
        case .identity: return "person.fill.viewfinder"
        case .enrolledList: return "list.bullet"
        }
    }

    static func fromName(_ name: String?) -> FaceMode {
        FaceMode(rawValue: name ?? "") ?? .faceDetect
    }
}

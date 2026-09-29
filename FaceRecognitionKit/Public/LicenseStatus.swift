import Foundation

/// Parsed FaceRecognitionSDK.getLicenseStatus JSON.
public struct LicenseStatus: Equatable {
    public let licensed: Bool
    public let level: Int
    public let levelName: String
    public let recognition: Bool
    public let liveness: Bool
    public let label: String
    public let missingDatabases: [String]

    public static let notLicensed = LicenseStatus(
        licensed: false,
        level: -1,
        levelName: "None",
        recognition: false,
        liveness: false,
        label: "No license",
        missingDatabases: []
    )

    public static func current() -> LicenseStatus {
        var status = fromJson(FaceRecognitionSDK.getLicenseStatus())
        let missing = FaceRecognitionSDK.getMissingDatabases()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return LicenseStatus(
            licensed: status.licensed,
            level: status.level,
            levelName: status.levelName,
            recognition: status.recognition,
            liveness: status.liveness,
            label: status.label,
            missingDatabases: missing
        )
    }

    public static func fromJson(_ json: String?) -> LicenseStatus {
        guard let data = json?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .notLicensed
        }
        return LicenseStatus(
            licensed: obj["licensed"] as? Bool ?? false,
            level: obj["level"] as? Int ?? -1,
            levelName: obj["levelName"] as? String ?? "None",
            recognition: obj["recognition"] as? Bool ?? false,
            liveness: obj["liveness"] as? Bool ?? false,
            label: {
                let raw = obj["label"] as? String ?? ""
                return raw.isEmpty ? "No license" : raw
            }(),
            missingDatabases: []
        )
    }

    public func denyMessage(wantRecognition: Bool, wantLiveness: Bool) -> String? {
        var parts: [String] = []
        if wantLiveness && !liveness {
            parts.append("This license does not include liveness (\(label)).")
        }
        if wantRecognition && !recognition {
            parts.append("This license does not include recognition (\(label)).")
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    public func missingDatabasesMessage() -> String? {
        if missingDatabases.isEmpty { return nil }
        return "Missing databases (features skipped): \(missingDatabases.joined(separator: ", "))"
    }
}

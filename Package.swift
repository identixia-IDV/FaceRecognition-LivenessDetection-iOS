// swift-tools-version: 5.9
import PackageDescription

// The Xcode demo keeps linking the frameworks beside FaceRecognitionSDK.xcodeproj.
// This package is the customer install: Xcode downloads the xcframework zips
// from the v1.0.0 Release. Checksums are filled when that Release is published.
// Until then, open FaceRecognitionSDK.xcodeproj — it does not use this file.
let package = Package(
    name: "IdentixiaFaceRecognition",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "IdentixiaFaceRecognition",
            targets: ["IdentixiaFaceRecognition"]
        )
    ],
    targets: [
        .target(
            name: "IdentixiaFaceRecognition",
            dependencies: [
                "facerecognitionsdk",
                "FaceRecognitionEngine",
                "onnxruntime",
            ],
            path: "FaceRecognitionKit",
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
        .binaryTarget(
            name: "facerecognitionsdk",
            url: "https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS/releases/latest/download/facerecognitionsdk.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        .binaryTarget(
            name: "FaceRecognitionEngine",
            url: "https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS/releases/latest/download/FaceRecognitionEngine.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        .binaryTarget(
            name: "onnxruntime",
            url: "https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS/releases/latest/download/onnxruntime.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
    ]
)

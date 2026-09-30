#!/bin/bash
# Xcode phase "Sync Embedded Frameworks".
# Leave frameworks that are already next to the project. Fill any missing
# engine from the v1.0.0 Release. Do not remove a framework that is already here.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need=0
for name in facerecognitionsdk FaceRecognitionEngine onnxruntime; do
  bin="$ROOT/${name}.framework/${name}"
  if [ ! -f "$bin" ]; then
    need=1
  fi
done
if [ "$need" -eq 0 ]; then
  exit 0
fi
URL="https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS/releases/latest/download/facerecognitionsdk-ios.zip"
mkdir -p "$ROOT/.identixia"
if curl -fsSL --retry 1 --connect-timeout 8 -o "$ROOT/.identixia/facerecognitionsdk-ios.zip" "$URL"; then
  unzip -o -q "$ROOT/.identixia/facerecognitionsdk-ios.zip" -d "$ROOT" || true
fi
exit 0

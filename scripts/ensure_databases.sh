#!/bin/bash
# Xcode phase "Ensure Databases". The sample already ships
# FaceRecognitionSDK/databases/*.xdb. Download the Release only when that
# folder has no packs. Never delete packs that are already here.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/FaceRecognitionSDK/databases"
mkdir -p "$DEST"
shopt -s nullglob
existing=("$DEST"/*.xdb)
if [ ${#existing[@]} -gt 0 ]; then
  exit 0
fi
URL="https://github.com/identixia-IDV/FaceRecognition-LivenessDetection-iOS/releases/latest/download/facerecognitionsdk-ios.zip"
mkdir -p "$ROOT/.identixia"
if curl -fsSL --retry 1 --connect-timeout 8 -o "$ROOT/.identixia/facerecognitionsdk-ios.zip" "$URL"; then
  unzip -o -q "$ROOT/.identixia/facerecognitionsdk-ios.zip" -d "$ROOT" || true
fi
exit 0

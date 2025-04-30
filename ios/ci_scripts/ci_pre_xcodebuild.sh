#!/bin/sh

echo "[ci_pre_xcodebuild] Building Flutter iOS project..."

# Build the Flutter iOS project (without codesigning)
flutter build ios --no-codesign

echo "[ci_pre_xcodebuild] Flutter build complete."

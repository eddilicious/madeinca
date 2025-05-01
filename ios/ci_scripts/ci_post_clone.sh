#!/bin/sh

# Install CocoaPods using Homebrew.
brew install cocoapods

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Run Flutter doctor
flutter --version
flutter doctor

# Get packages
flutter pub get

# Update generated files
flutter pub run build_runner build

# Build ios app
flutter build ios --no-codesign

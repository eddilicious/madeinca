#!/bin/bash

echo "🔍 Checking installed Pods vs. Podfile.lock..."

PODS_DIR="./ios/Pods"
LOCKFILE="./ios/Podfile.lock"

if [ ! -f "$LOCKFILE" ]; then
  echo "❌ Podfile.lock not found at $LOCKFILE"
  exit 1
fi

# Get list of expected pod names from Podfile.lock
expected_pods=$(grep -E '^\s{2}- ' "$LOCKFILE" | sed 's/^  - //' | cut -d ' ' -f1 | sort)

echo "✅ Pods listed in Podfile.lock:"
echo "$expected_pods"
echo "-------------------------------------"

# Get actual pods from installed Pods directory
if [ ! -d "$PODS_DIR" ]; then
  echo "❌ Pods directory not found. Run 'pod install' first."
  exit 1
fi

actual_pods=$(ls "$PODS_DIR" | sort)

echo "📦 Pods currently installed:"
echo "$actual_pods"
echo "-------------------------------------"

echo "🔄 Comparing..."

comm -3 <(echo "$expected_pods") <(echo "$actual_pods")

echo "✅ Done. If there are differences, try:"
echo "   rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/Flutter.podspec"
echo "   pod install"
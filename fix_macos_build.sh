#!/bin/bash
# 🤖 Fix macOS/iOS build script for firmador app
# This script fixes common build issues after flutter clean

echo "🔧 Fixing macOS/iOS build issues..."

# Clean Flutter
echo "[STEP] Cleaning Flutter project..."
flutter clean

# Clean iOS pods
echo "[STEP] Cleaning iOS pods..."
cd ios
rm -rf Pods/
rm -f Podfile.lock
cd ..

# Clean macOS pods
echo "[STEP] Cleaning macOS pods..."
cd macos
rm -rf Pods/
rm -f Podfile.lock
cd ..

# Get Flutter dependencies
echo "[STEP] Getting Flutter dependencies..."
flutter pub get

# Reinstall iOS pods
echo "[STEP] Reinstalling iOS pods..."
cd ios
pod install --clean-install
cd ..

# Reinstall macOS pods
echo "[STEP] Reinstalling macOS pods..."
cd macos
pod install --clean-install
cd ..

# Clean build directories
echo "[STEP] Cleaning build directories..."
rm -rf build/
rm -rf ios/build/
rm -rf macos/build/

# Run flutter precache
echo "[STEP] Running flutter precache..."
flutter precache --ios --macos

echo "✅ Build fix completed!"
echo ""
echo "📱 To run on iOS simulator:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Select your target simulator"
echo "   3. Press Run (⌘+R)"
echo ""
echo "💻 To run on macOS:"
echo "   1. Open macos/Runner.xcworkspace in Xcode"
echo "   2. Select 'My Mac' as target"
echo "   3. Press Run (⌘+R)" 
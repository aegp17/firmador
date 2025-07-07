#!/bin/bash

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️ Building for macOS..."
flutter build macos --debug

echo "🧹 Cleaning build artifacts..."
if [ -d "build/macos/Build/Products/Debug/firmador.app" ]; then
    find build/macos/Build/Products/Debug/firmador.app -name "._*" -delete
    find build/macos/Build/Products/Debug/firmador.app -name ".DS_Store" -delete
    xattr -cr build/macos/Build/Products/Debug/firmador.app 2>/dev/null || true
fi

echo "🚀 Running application..."
flutter run --debug --device-id=macos 
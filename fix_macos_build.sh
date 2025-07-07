#!/bin/bash
# 🤖 Fix macOS build script for firmador app
# This script fixes common build issues after flutter clean

echo "🔧 Fixing macOS build issues..."

# 1. Create ephemeral directory
mkdir -p macos/Flutter/ephemeral

# 2. Create FlutterInputs.xcfilelist
cat > macos/Flutter/ephemeral/FlutterInputs.xcfilelist << 'EOF'
${FLUTTER_ROOT}/packages/flutter_tools/bin/macos_assemble.sh
${PROJECT_DIR}/Flutter/ephemeral/flutter_export_environment.sh
${PROJECT_DIR}/Flutter/ephemeral/Flutter-Generated.xcconfig
${PROJECT_DIR}/macos/Flutter/GeneratedPluginRegistrant.swift
${PROJECT_DIR}/lib/main.dart
EOF

# 3. Create FlutterOutputs.xcfilelist
cat > macos/Flutter/ephemeral/FlutterOutputs.xcfilelist << 'EOF'
${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Contents/Frameworks/FlutterMacOS.framework
${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Contents/Resources/flutter_assets
${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Contents/Resources/app.so
EOF

# 4. Clean problematic files
echo "🧹 Cleaning problematic files..."
find build -name "*.DS_Store" -delete 2>/dev/null || true
find build -name "._*" -delete 2>/dev/null || true
find build -name "*.app" -exec xattr -cr {} \; 2>/dev/null || true

# 5. Regenerate Flutter files
echo "📦 Running flutter pub get..."
flutter pub get

# 6. Reinstall CocoaPods
echo "☕ Installing CocoaPods..."
cd macos && pod install && cd ..

echo "✅ macOS build fix completed!"
echo "Now you can run: flutter build macos --debug"
echo "Or build directly with Xcode in the macos directory" 
#!/bin/bash

set -e  # Exit on any error

echo "Cleaning build artifacts..."

# Remove build artifacts
rm -rf .build
rm -rf build
rm -rf Package.resolved
rm -rf .swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/AskRepo* 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm/ 2>/dev/null || true
rm -rf ~/.swiftpm/ 2>/dev/null || true

mkdir -p build

swift package clean

echo "Building release version..."
swift build -c release

echo "Creating app bundle..."
APP_NAME="AskRepo"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Find release executable
RELEASE_EXEC=""
if [ -f ".build/arm64-apple-macosx/release/${APP_NAME}" ]; then
    RELEASE_EXEC=".build/arm64-apple-macosx/release/${APP_NAME}"
elif [ -f ".build/x86_64-apple-macosx/release/${APP_NAME}" ]; then
    RELEASE_EXEC=".build/x86_64-apple-macosx/release/${APP_NAME}"
elif [ -f ".build/release/${APP_NAME}" ]; then
    RELEASE_EXEC=".build/release/${APP_NAME}"
else
    echo "Error: Cannot find release executable!"
    exit 1
fi

cp "${RELEASE_EXEC}" "${MACOS_DIR}/${APP_NAME}"

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/"
    echo "🎨 Added app icon to bundle"
fi

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AskRepo</string>
    <key>CFBundleIdentifier</key>
    <string>com.flashloanz.askrepo</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AskRepo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.9</string>
    <key>CFBundleVersion</key>
    <string>0.9</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Make executable
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "Build complete: ${APP_BUNDLE}"

# Kill any existing instances and launch
pkill -f AskRepo 2>/dev/null || true
sleep 1
open "${APP_BUNDLE}" 
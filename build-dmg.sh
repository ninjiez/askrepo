#!/bin/bash

# AskRepo DMG Builder Script
# This script builds AskRepo and creates a DMG for distribution

set -e

echo "🚀 Building AskRepo DMG..."

# Build the app in release mode
echo "📦 Building AskRepo in release mode..."
swift build -c release

# Create build directory
BUILD_DIR="build"
APP_NAME="AskRepo.app"
DMG_NAME="AskRepo.dmg"

mkdir -p "$BUILD_DIR"
rm -rf "$BUILD_DIR/$APP_NAME"
rm -f "$BUILD_DIR/$DMG_NAME"

# Create app bundle structure
echo "📱 Creating app bundle..."
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME/Contents/Resources"

# Copy executable
cp ".build/release/AskRepo" "$BUILD_DIR/$APP_NAME/Contents/MacOS/"

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$BUILD_DIR/$APP_NAME/Contents/Resources/"
    echo "🎨 Added app icon to bundle"
fi

# Sign the app to reduce quarantine issues
echo "🔐 Signing AskRepo.app..."
codesign --force --deep --sign - "$BUILD_DIR/$APP_NAME"
codesign --verify --verbose "$BUILD_DIR/$APP_NAME" || echo "⚠️  Signature verification failed, continuing anyway..."

# Create Info.plist
cat > "$BUILD_DIR/$APP_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AskRepo</string>
    <key>CFBundleIdentifier</key>
    <string>com.flashloanz.askrepo</string>
    <key>CFBundleName</key>
    <string>AskRepo</string>
    <key>CFBundleDisplayName</key>
    <string>AskRepo</string>
    <key>CFBundleVersion</key>
    <string>0.9</string>
    <key>CFBundleShortVersionString</key>
    <string>0.9</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 @flashloanz. All rights reserved.</string>
</dict>
</plist>
EOF

# Make executable
chmod +x "$BUILD_DIR/$APP_NAME/Contents/MacOS/AskRepo"

# Create DMG with installer interface
echo "💿 Creating installer DMG..."

# Create temporary DMG directory
DMG_DIR="$BUILD_DIR/dmg_temp"
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
cp -R "$BUILD_DIR/$APP_NAME" "$DMG_DIR/"

# Create Applications symlink for drag-and-drop installation
ln -sf /Applications "$DMG_DIR/Applications"

# Create a background folder and image for the DMG
mkdir -p "$DMG_DIR/.background"

# Create an enhanced background image with instructions
echo "🎨 Creating enhanced DMG background..."
cat > /tmp/create_background.py << 'EOF'
#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

# Create a larger background image for better layout
width, height = 800, 500
img = Image.new('RGB', (width, height), color='#f8f9fa')
draw = ImageDraw.Draw(img)

# Try to use system fonts with better fallbacks
try:
    title_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 32)
    subtitle_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 18)
    instruction_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 16)
except:
    try:
        title_font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 32)
        subtitle_font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 18)
        instruction_font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 16)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        instruction_font = ImageFont.load_default()

# Draw title
title_text = "Install AskRepo"
title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
title_width = title_bbox[2] - title_bbox[0]
draw.text(((width - title_width) // 2, 40), title_text, fill='#1a1a1a', font=title_font)

# Draw subtitle
subtitle_text = "AI Code Assistant for macOS"
subtitle_bbox = draw.textbbox((0, 0), subtitle_text, font=subtitle_font)
subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
draw.text(((width - subtitle_width) // 2, 85), subtitle_text, fill='#666666', font=subtitle_font)

# Draw main instruction
instruction_text = "Drag AskRepo to the Applications folder to install"
instruction_bbox = draw.textbbox((0, 0), instruction_text, font=instruction_font)
instruction_width = instruction_bbox[2] - instruction_bbox[0]
draw.text(((width - instruction_width) // 2, 380), instruction_text, fill='#333333', font=instruction_font)

# Draw secondary instruction
secondary_text = "Then launch AskRepo from your Applications folder"
secondary_bbox = draw.textbbox((0, 0), secondary_text, font=instruction_font)
secondary_width = secondary_bbox[2] - secondary_bbox[0]
draw.text(((width - secondary_width) // 2, 405), secondary_text, fill='#666666', font=instruction_font)

# Draw a more prominent arrow
arrow_start_x, arrow_start_y = 280, 250
arrow_end_x, arrow_end_y = 520, 250
arrow_color = '#007AFF'

# Draw arrow shaft
draw.line([(arrow_start_x, arrow_start_y), (arrow_end_x, arrow_end_y)], fill=arrow_color, width=4)

# Draw arrowhead (larger and more prominent)
arrowhead_size = 15
draw.polygon([
    (arrow_end_x, arrow_end_y),
    (arrow_end_x - arrowhead_size, arrow_end_y - arrowhead_size//2),
    (arrow_end_x - arrowhead_size, arrow_end_y + arrowhead_size//2)
], fill=arrow_color)

# Add some decorative elements
# Draw a subtle gradient background
for y in range(height):
    alpha = int(255 * (1 - y / height * 0.1))
    color = f'#{alpha:02x}{alpha:02x}{alpha:02x}'
    
# Draw version info in corner
version_text = "v0.9"
version_bbox = draw.textbbox((0, 0), version_text, font=instruction_font)
draw.text((width - version_bbox[2] - 20, height - version_bbox[3] - 10), version_text, fill='#999999', font=instruction_font)

# Save the image
img.save('/tmp/dmg_background.png')
print("Background image created successfully")
EOF

# Try to create background with Python/PIL, fallback to simple approach
if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" >/dev/null 2>&1; then
    python3 /tmp/create_background.py
    if [ -f "/tmp/dmg_background.png" ]; then
        cp /tmp/dmg_background.png "$DMG_DIR/.background/background.png"
        echo "✅ Enhanced background image created"
    else
        echo "⚠️  Background image creation failed, using fallback"
        echo "Drag AskRepo.app to Applications folder to install" > "$DMG_DIR/.background/README.txt"
    fi
else
    echo "⚠️  Python/PIL not available, using simple background"
fi

# Create a temporary writable DMG with more space for larger icons
TEMP_DMG="$BUILD_DIR/temp.dmg"
echo "📦 Creating temporary DMG..."
hdiutil create -srcfolder "$DMG_DIR" -volname "AskRepo Installer" -fs HFS+ -format UDRW -size 150m "$TEMP_DMG"

# Mount the temporary DMG
echo "📁 Mounting DMG for customization..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep -E '^/dev/' | sed 1q | awk '{print $3}')

# Wait a moment for the mount to complete
sleep 3

# Customize the DMG appearance with AppleScript
echo "🎨 Customizing DMG appearance with large icons..."
cat > /tmp/dmg_setup.applescript << EOF
tell application "Finder"
    tell disk "AskRepo Installer"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 900, 600}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 160
        set text size of viewOptions to 16
        set shows item info of viewOptions to false
        set shows icon preview of viewOptions to true
        try
            set background picture of viewOptions to file ".background:background.png"
        end try
        
        -- Position items with more space for large icons
        set position of item "AskRepo.app" of container window to {200, 250}
        set position of item "Applications" of container window to {600, 250}
        
        close
        open
        update without registering applications
        delay 5
        eject
    end tell
end tell
EOF

# Run the AppleScript to customize the DMG
echo "🎯 Applying DMG customizations..."
osascript /tmp/dmg_setup.applescript

# Wait for the DMG to be ejected
sleep 3

# Convert to final compressed DMG
echo "📦 Creating final compressed DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$BUILD_DIR/$DMG_NAME"

# Clean up temporary files
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"
rm -f /tmp/dmg_setup.applescript
rm -f /tmp/create_background.py
rm -f /tmp/dmg_background.png

echo "✅ DMG created successfully: $BUILD_DIR/$DMG_NAME"
echo ""
echo "🎉 Ready for distribution!"
echo ""
echo "DMG Features:"
echo "• Large 160px icons for better visibility"
echo "• Clear drag-and-drop installation interface"
echo "• Professional background with installation instructions"
echo "• Optimized window size and layout"
echo ""
echo "Next steps:"
echo "1. Test the DMG by mounting and installing the app"
echo "2. Sign the app and DMG for distribution (if you have a Developer ID)"
echo "3. Upload to GitHub Releases"
echo ""
echo "📱 Follow @flashloanz on X for updates!" 
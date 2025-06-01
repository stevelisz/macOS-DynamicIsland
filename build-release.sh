#!/bin/bash

# 🧰 Dynamic Toolbox v2.0.0 - Release Build Script
# ==================================================

set -e # Exit on any error

echo "🚀 Building Dynamic Toolbox v2.0.0 Release..."
echo "=============================================="

# Configuration
PROJECT_NAME="DynamicIsland"
APP_NAME="Dynamic Toolbox"
VERSION="2.0.0"
BUILD_DIR="./build"
RELEASE_DIR="./release"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Build Configuration:${NC}"
echo "   Project: $PROJECT_NAME"
echo "   App Name: $APP_NAME"
echo "   Version: $VERSION"
echo ""

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Build for Release
echo -e "${YELLOW}🔨 Building for Release...${NC}"
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$PROJECT_NAME" \
           -configuration Release \
           -archivePath "$ARCHIVE_PATH" \
           -destination "generic/platform=macOS" \
           archive

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Export the app
echo -e "${YELLOW}📦 Exporting application...${NC}"
xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportPath "$BUILD_DIR" \
           -exportOptionsPlist "Distribution/ExportOptions.plist" 2>/dev/null || {
    # If ExportOptions.plist doesn't exist, create a simple one
    echo -e "${YELLOW}📝 Creating export options...${NC}"
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
               -archivePath "$ARCHIVE_PATH" \
               -exportPath "$BUILD_DIR" \
               -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
}

# Find the exported app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find exported app!"
    exit 1
fi

echo -e "${GREEN}✅ App built successfully: $APP_PATH${NC}"

# Create DMG
echo -e "${YELLOW}💿 Creating DMG package...${NC}"
DMG_NAME="Dynamic-Toolbox-v$VERSION"
DMG_PATH="$RELEASE_DIR/$DMG_NAME.dmg"

# Create temporary DMG directory
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to DMG directory and rename it
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Rename the app to show the correct name in DMG
if [ -d "$TEMP_DMG_DIR/DynamicIsland.app" ]; then
    mv "$TEMP_DMG_DIR/DynamicIsland.app" "$TEMP_DMG_DIR/Dynamic Toolbox.app"
    echo -e "${GREEN}✅ Renamed app to 'Dynamic Toolbox.app'${NC}"
fi

# Create Applications symlink
ln -sf /Applications "$TEMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME v$VERSION" \
               -srcfolder "$TEMP_DMG_DIR" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

echo -e "${GREEN}✅ DMG created: $DMG_PATH${NC}"

# Get file sizes
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)

# Copy documentation to release folder
echo -e "${YELLOW}📚 Copying documentation...${NC}"
cp README.md "$RELEASE_DIR/"
cp Distribution/Release-Notes.md "$RELEASE_DIR/"
cp Distribution/Installation-Guide.txt "$RELEASE_DIR/"

# Create release info
echo -e "${YELLOW}📋 Creating release information...${NC}"
cat > "$RELEASE_DIR/Release-Info.txt" << EOF
🧰 Dynamic Toolbox v$VERSION - Release Package
==============================================

📅 Build Date: $(date)
💻 Built on: $(sw_vers -productName) $(sw_vers -productVersion)
🏗️  Xcode Version: $(xcodebuild -version | head -1)

📦 Package Contents:
- Dynamic-Toolbox-v$VERSION.dmg ($DMG_SIZE)
- README.md (User documentation)
- Release-Notes.md (Version changelog)
- Installation-Guide.txt (Setup instructions)

🎯 Target Requirements:
- macOS 15.1 (Sequoia) or later
- Intel or Apple Silicon Mac
- ~50MB storage space
- Internet connection (optional, for weather/currency/web search)

🤖 AI Features (Optional):
- Requires Ollama (https://ollama.ai)
- Recommended: llama3.2:3b model (~2GB)

🔐 Security:
- Notarized: TBD (run 'xcrun notarytool' after build)
- Code Signed: Automatic with Xcode
- Local Processing: AI runs entirely on user's Mac

📧 Support:
- GitHub Issues: https://github.com/[username]/Dynamic-Toolbox/issues
- Documentation: Full guides available
- Community: Join discussions and share tips

Happy productivity! 🚀
EOF

# Summary
echo ""
echo -e "${GREEN}🎉 Release Package Ready!${NC}"
echo "========================"
echo -e "📁 Release folder: ${BLUE}$RELEASE_DIR${NC}"
echo -e "💿 DMG package: ${BLUE}$DMG_NAME.dmg${NC} ($DMG_SIZE)"
echo -e "📱 App size: ${BLUE}$APP_SIZE${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Test the DMG on a clean Mac"
echo "2. Run security scan: 'spctl -a -vv \"$APP_PATH\"'"
echo "3. Consider notarization for distribution"
echo "4. Upload to GitHub Releases"
echo "5. Update documentation and announce!"
echo ""
echo -e "${GREEN}🚀 Dynamic Toolbox v$VERSION is ready for release!${NC}" 
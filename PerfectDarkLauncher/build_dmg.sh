#!/bin/bash

# Perfect Dark Launcher - Build and Package Script
# Creates a signed .app bundle and .dmg for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Perfect Dark Launcher"
BUNDLE_NAME="PerfectDarkLauncher"
DMG_NAME="PerfectDarkLauncher"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Perfect Dark Launcher Build Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}Error: Xcode command line tools not found${NC}"
        echo "Please install Xcode from the App Store"
        exit 1
    fi
    
    if ! command -v sips &> /dev/null; then
        echo -e "${RED}Error: sips not found${NC}"
        exit 1
    fi
    
    if ! command -v iconutil &> /dev/null; then
        echo -e "${RED}Error: iconutil not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All requirements met${NC}"
    echo ""
}

# Generate app icon from the logo
generate_icon() {
    echo -e "${YELLOW}Generating app icon...${NC}"
    
    LOGO_PATH="$SCRIPT_DIR/../perfect_dark_style_n64_icon_by_ro_kurorai_d2568bz-fullview.jpg"
    ICONSET_DIR="$PROJECT_DIR/$BUNDLE_NAME/Assets.xcassets/AppIcon.appiconset"
    TEMP_ICONSET="$BUILD_DIR/AppIcon.iconset"
    
    if [ ! -f "$LOGO_PATH" ]; then
        echo -e "${RED}Error: Logo file not found at $LOGO_PATH${NC}"
        exit 1
    fi
    
    # Clean and create temp directory for iconset
    rm -rf "$TEMP_ICONSET"
    mkdir -p "$TEMP_ICONSET"
    mkdir -p "$ICONSET_DIR"
    
    # Convert JPEG to PNG first and create a square version
    TEMP_PNG="$BUILD_DIR/logo_temp.png"
    sips -s format png "$LOGO_PATH" --out "$TEMP_PNG" > /dev/null 2>&1
    
    # Generate all required icon sizes with proper naming for iconutil
    sips -z 16 16 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$TEMP_PNG" --out "$TEMP_ICONSET/icon_512x512@2x.png" > /dev/null 2>&1
    
    # Also copy icons to the Assets catalog for Xcode
    sips -z 16 16 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-16.png" > /dev/null 2>&1
    sips -z 32 32 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-32.png" > /dev/null 2>&1
    sips -z 64 64 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-64.png" > /dev/null 2>&1
    sips -z 128 128 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-128.png" > /dev/null 2>&1
    sips -z 256 256 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-256.png" > /dev/null 2>&1
    sips -z 512 512 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$TEMP_PNG" --out "$ICONSET_DIR/AppIcon-1024.png" > /dev/null 2>&1
    
    # Generate .icns file
    iconutil -c icns "$TEMP_ICONSET" -o "$BUILD_DIR/AppIcon.icns"
    
    # Clean up temp files
    rm -f "$TEMP_PNG"
    rm -rf "$TEMP_ICONSET"
    
    echo -e "${GREEN}✓ App icon generated${NC}"
    echo ""
}

# Build the app
build_app() {
    echo -e "${YELLOW}Building application...${NC}"
    
    cd "$PROJECT_DIR"
    
    # Clean previous build
    rm -rf "$BUILD_DIR/Release"
    rm -rf "$BUILD_DIR/$BUNDLE_NAME.app"
    
    # Build for release
    xcodebuild -project "$BUNDLE_NAME.xcodeproj" \
        -scheme "$BUNDLE_NAME" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -arch arm64 -arch x86_64 \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        clean build | grep -E "(Building|Compiling|Linking|error:|warning:|\*\*)" || true
    
    # Find the built app
    BUILT_APP=$(find "$BUILD_DIR/DerivedData" -name "$BUNDLE_NAME.app" -type d | head -1)
    
    if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
        echo -e "${RED}Error: Build failed - app not found${NC}"
        exit 1
    fi
    
    # Copy to build directory
    cp -R "$BUILT_APP" "$BUILD_DIR/$BUNDLE_NAME.app"
    
    # Copy the generated icon into the app bundle
    if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
        cp "$BUILD_DIR/AppIcon.icns" "$BUILD_DIR/$BUNDLE_NAME.app/Contents/Resources/AppIcon.icns"
    fi
    
    echo -e "${GREEN}✓ Application built successfully${NC}"
    echo ""
}

# Create DMG
create_dmg() {
    echo -e "${YELLOW}Creating DMG...${NC}"
    
    DMG_PATH="$BUILD_DIR/${DMG_NAME}-${VERSION}.dmg"
    DMG_TEMP="$BUILD_DIR/dmg_temp"
    
    # Clean up any previous DMG
    rm -f "$DMG_PATH"
    rm -rf "$DMG_TEMP"
    
    # Create temp directory for DMG contents
    mkdir -p "$DMG_TEMP"
    
    # Copy app to temp directory
    cp -R "$BUILD_DIR/$BUNDLE_NAME.app" "$DMG_TEMP/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_TEMP" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Clean up
    rm -rf "$DMG_TEMP"
    
    echo -e "${GREEN}✓ DMG created: $DMG_PATH${NC}"
    echo ""
    
    # Show DMG info
    echo -e "${YELLOW}DMG Information:${NC}"
    ls -lh "$DMG_PATH"
    echo ""
}

# Main
main() {
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    check_requirements
    generate_icon
    build_app
    create_dmg
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Build Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "App: ${YELLOW}$BUILD_DIR/$BUNDLE_NAME.app${NC}"
    echo -e "DMG: ${YELLOW}$BUILD_DIR/${DMG_NAME}-${VERSION}.dmg${NC}"
    echo ""
    echo "To install, open the DMG and drag the app to Applications."
    echo ""
}

main "$@"

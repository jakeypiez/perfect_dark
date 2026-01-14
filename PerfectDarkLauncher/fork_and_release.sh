#!/bin/bash

# Perfect Dark Launcher - Fork and Release Script
# Forks the repo and creates a GitHub release with the DMG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
DMG_PATH="$BUILD_DIR/PerfectDarkLauncher-1.0.0.dmg"
ORIGINAL_REPO="fgsfdsfgs/perfect_dark"
RELEASE_TAG="launcher-v1.0.0"
RELEASE_TITLE="Perfect Dark Launcher v1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Perfect Dark - Fork & Release Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check requirements
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) not found${NC}"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI not authenticated${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
    
    if [ ! -f "$DMG_PATH" ]; then
        echo -e "${RED}Error: DMG not found at $DMG_PATH${NC}"
        echo "Run ./build_dmg.sh first"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All requirements met${NC}"
    echo ""
}

# Fork the repository
fork_repo() {
    echo -e "${YELLOW}Forking repository...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Check if already forked
    GITHUB_USER=$(gh api user -q '.login')
    
    if gh repo view "$GITHUB_USER/perfect_dark" &> /dev/null; then
        echo -e "${GREEN}✓ Fork already exists: $GITHUB_USER/perfect_dark${NC}"
    else
        echo "Creating fork of $ORIGINAL_REPO..."
        gh repo fork "$ORIGINAL_REPO" --clone=false
        echo -e "${GREEN}✓ Fork created: $GITHUB_USER/perfect_dark${NC}"
    fi
    
    # Update remote to point to fork
    if git remote get-url fork &> /dev/null; then
        git remote set-url fork "https://github.com/$GITHUB_USER/perfect_dark.git"
    else
        git remote add fork "https://github.com/$GITHUB_USER/perfect_dark.git"
    fi
    
    echo ""
    FORK_REPO="$GITHUB_USER/perfect_dark"
}

# Commit and push launcher changes
push_changes() {
    echo -e "${YELLOW}Committing launcher changes...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Add launcher files
    git add PerfectDarkLauncher/
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "No new changes to commit"
    else
        git commit -m "Add Perfect Dark Launcher macOS app

- Native SwiftUI macOS application for launching Perfect Dark
- ROM file selection with drag & drop support
- Video settings (resolution, fullscreen, VSync, MSAA)
- Game settings (skip intro, HUD mode, memory size)
- Player settings (FOV, mouse sensitivity)
- Build script for creating DMG releases"
    fi
    
    # Push to fork
    echo "Pushing to fork..."
    git push fork HEAD:main --force-with-lease || git push fork HEAD:main
    
    echo -e "${GREEN}✓ Changes pushed to fork${NC}"
    echo ""
}

# Create release
create_release() {
    echo -e "${YELLOW}Creating GitHub release...${NC}"
    
    RELEASE_NOTES="## Perfect Dark Launcher for macOS

A native macOS launcher application for the Perfect Dark PC Port.

### Features
- 🎮 ROM Selection: Drag & drop or browse for .z64 ROM files
- 🌍 Auto-detection of ROM region (NTSC, PAL, JPN)
- 🖥️ Video settings: Resolution, fullscreen, VSync, MSAA, texture filtering
- ⚙️ Game settings: Skip intro, HUD positioning, memory size, screen shake
- 🎯 Player settings: Custom FOV, mouse aim mode, sensitivity
- 🔧 Advanced settings: Custom paths, direct config file editing

### Requirements
- macOS 12.0 (Monterey) or later
- Perfect Dark ROM file in .z64 format
- Built Perfect Dark PC Port executable

### Installation
1. Download the DMG file below
2. Open the DMG and drag the app to Applications
3. Launch the app and select your ROM file
4. Configure settings as desired and click Launch Game

### Note
You must build the Perfect Dark port executable separately. See the main README for build instructions."

    # Delete existing release if it exists
    gh release delete "$RELEASE_TAG" --repo "$FORK_REPO" --yes 2>/dev/null || true
    
    # Delete existing tag if it exists
    git tag -d "$RELEASE_TAG" 2>/dev/null || true
    git push fork --delete "$RELEASE_TAG" 2>/dev/null || true
    
    # Create new release with DMG
    gh release create "$RELEASE_TAG" \
        --repo "$FORK_REPO" \
        --title "$RELEASE_TITLE" \
        --notes "$RELEASE_NOTES" \
        "$DMG_PATH"
    
    echo -e "${GREEN}✓ Release created!${NC}"
    echo ""
}

# Main
main() {
    check_requirements
    fork_repo
    push_changes
    create_release
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Fork & Release Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Fork: ${YELLOW}https://github.com/$FORK_REPO${NC}"
    echo -e "Release: ${YELLOW}https://github.com/$FORK_REPO/releases/tag/$RELEASE_TAG${NC}"
    echo ""
}

main "$@"

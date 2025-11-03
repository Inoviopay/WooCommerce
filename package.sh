#!/bin/bash

################################################################################
# Inovio Payment Gateway - Automated GitHub Release Script
#
# This script automatically:
# - Calculates version from git commit count
# - Updates version in plugin files
# - Builds distribution ZIP
# - Publishes GitHub release with assets
#
# Version Format: MAJOR.COMMITS.0
#   MAJOR: From .version file
#   COMMITS: Git commit count
#   Patch: Always 0
#
# Usage:
#   ./package.sh
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
#   - Git repository with GitHub remote
#   - .version file with major version number
#
# Author: Inovio Payments
# License: GPLv2
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLUGIN_SLUG="inovio-payment-gateway"
PLUGIN_DIR="inovio-payment-gateway"
BUILD_DIR="build"
DIST_DIR="dist"
VERSION_FILE=".version"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Inovio Payment Gateway - Release Builder${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

################################################################################
# Step 0: Prerequisites & Version Calculation
################################################################################

echo -e "${BLUE}[0/8]${NC} Checking prerequisites and calculating version..."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI (gh) is not installed${NC}"
    echo -e "  Install: ${YELLOW}brew install gh${NC} (macOS)"
    echo -e "           ${YELLOW}https://cli.github.com/${NC} (other platforms)"
    exit 1
fi
echo -e "${GREEN}✓ GitHub CLI installed${NC}"

# Check gh authentication
if ! gh auth status &>/dev/null; then
    echo -e "${RED}✗ Not authenticated with GitHub CLI${NC}"
    echo -e "  Run: ${YELLOW}gh auth login${NC}"
    exit 1
fi
echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Not a git repository${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git repository detected${NC}"

# Check for GitHub remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo -e "${RED}✗ No 'origin' remote configured${NC}"
    exit 1
fi

REMOTE_URL=$(git remote get-url origin)
if [[ ! $REMOTE_URL =~ github.com ]]; then
    echo -e "${RED}✗ Remote is not a GitHub repository${NC}"
    echo -e "  Remote URL: $REMOTE_URL"
    exit 1
fi
echo -e "${GREEN}✓ GitHub remote: ${REMOTE_URL}${NC}"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠ Warning: You have uncommitted changes${NC}"
    echo -e "  These changes will NOT be included in the release"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Read major version from .version file
if [ ! -f "$VERSION_FILE" ]; then
    echo -e "${RED}✗ Version file '$VERSION_FILE' not found${NC}"
    echo -e "  Create it with: ${YELLOW}echo '4' > $VERSION_FILE${NC}"
    exit 1
fi

MAJOR_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
if ! [[ $MAJOR_VERSION =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✗ Invalid major version in $VERSION_FILE: '$MAJOR_VERSION'${NC}"
    echo -e "  Should be a single number (e.g., 4)"
    exit 1
fi
echo -e "${GREEN}✓ Major version: ${MAJOR_VERSION}${NC}"

# Calculate commit count
COMMIT_COUNT=$(git rev-list --count HEAD)
echo -e "${GREEN}✓ Commit count: ${COMMIT_COUNT}${NC}"

# Build version string
VERSION="${MAJOR_VERSION}.${COMMIT_COUNT}.0"
echo ""
echo -e "  ${YELLOW}Calculated Version: ${VERSION}${NC}"
echo ""

# Check if tag already exists
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo -e "${RED}✗ Git tag v${VERSION} already exists locally${NC}"
    echo -e "  Delete with: ${YELLOW}git tag -d v${VERSION}${NC}"
    exit 1
fi

if git ls-remote --tags origin 2>/dev/null | grep -q "refs/tags/v${VERSION}"; then
    echo -e "${RED}✗ Git tag v${VERSION} already exists on remote${NC}"
    echo -e "  This version has already been released"
    exit 1
fi

# Check plugin directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}✗ Plugin directory '$PLUGIN_DIR' not found${NC}"
    exit 1
fi

# Check if main plugin file exists
if [ ! -f "$PLUGIN_DIR/woocommerce-inovio-gateway.php" ]; then
    echo -e "${RED}✗ Main plugin file not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

################################################################################
# Step 1: Update Version Numbers in Files
################################################################################

echo -e "${BLUE}[1/8]${NC} Updating version numbers in plugin files..."

# Update version in main plugin file
MAIN_FILE="$PLUGIN_DIR/woocommerce-inovio-gateway.php"
sed -i.bak "s/\* Version: .*/\* Version: ${VERSION}/" "$MAIN_FILE"
rm -f "${MAIN_FILE}.bak"
echo -e "${GREEN}✓ Updated ${MAIN_FILE}${NC}"

# Update stable tag in readme.txt
README_FILE="$PLUGIN_DIR/readme.txt"
if [ -f "$README_FILE" ]; then
    sed -i.bak "s/Stable tag: .*/Stable tag: ${VERSION}/" "$README_FILE"
    rm -f "${README_FILE}.bak"
    echo -e "${GREEN}✓ Updated ${README_FILE}${NC}"
fi

# Commit version updates
git add "$MAIN_FILE" "$README_FILE" 2>/dev/null || true
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    git commit -m "Bump version to ${VERSION}"
    echo -e "${GREEN}✓ Committed version changes${NC}"
else
    echo -e "${YELLOW}⚠ No version changes to commit${NC}"
fi

echo ""

################################################################################
# Step 2: Clean Previous Builds
################################################################################

echo -e "${BLUE}[2/8]${NC} Cleaning previous builds..."

rm -rf $BUILD_DIR
rm -rf $DIST_DIR
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

echo -e "${GREEN}✓ Build directories prepared${NC}"
echo ""

################################################################################
# Step 3: Copy Plugin Files
################################################################################

echo -e "${BLUE}[3/8]${NC} Copying plugin files..."

# Create plugin directory in build
mkdir -p $BUILD_DIR/$PLUGIN_SLUG

# Copy all plugin files
cp -r $PLUGIN_DIR/* $BUILD_DIR/$PLUGIN_SLUG/

echo -e "${GREEN}✓ Files copied to build directory${NC}"
echo ""

################################################################################
# Step 4: Remove Development Files
################################################################################

echo -e "${BLUE}[4/8]${NC} Removing development files..."

cd $BUILD_DIR/$PLUGIN_SLUG

# Remove version control
rm -rf .git
rm -f .gitignore
rm -f .gitattributes

# Remove development files
rm -f .editorconfig
rm -f .eslintrc
rm -f .phpcs.xml
rm -f phpcs.xml
rm -f phpunit.xml
rm -f composer.json
rm -f composer.lock
rm -f package.json
rm -f package-lock.json
rm -f webpack.config.js
rm -f Gruntfile.js
rm -f gulpfile.js

# Remove development directories
rm -rf tests/
rm -rf node_modules/
rm -rf vendor/
rm -rf .sass-cache/
rm -rf bin/

# Remove CI/CD files
rm -f .travis.yml
rm -f .gitlab-ci.yml
rm -rf .github/

# Remove documentation (keep in repo, not in distribution)
rm -f DEVELOPER.md
rm -f INSTALLER.md
rm -f CONTRIBUTING.md

# Remove macOS files
find . -name ".DS_Store" -delete

# Remove editor files
find . -name "*.swp" -delete
find . -name "*.swo" -delete
find . -name "*~" -delete

cd ../..

echo -e "${GREEN}✓ Development files removed${NC}"
echo ""

################################################################################
# Step 5: Validate Required Files
################################################################################

echo -e "${BLUE}[5/8]${NC} Validating required files..."

REQUIRED_FILES=(
    "$BUILD_DIR/$PLUGIN_SLUG/woocommerce-inovio-gateway.php"
    "$BUILD_DIR/$PLUGIN_SLUG/readme.txt"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/inoviopay/woocommerce-inovio-gateway.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/ach/class-woocommerce-ach-inovio-gateway.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/common/class-common-inovio-payment.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/common/inovio-core/class-inovioprocessor.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/common/inovio-core/class-inovioserviceconfig.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/common/inovio-core/class-inovioconnection.php"
    "$BUILD_DIR/$PLUGIN_SLUG/includes/installer/inovio-plugin-database-table.php"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Missing required file: $file${NC}"
        MISSING_FILES=1
    fi
done

if [ $MISSING_FILES -eq 1 ]; then
    echo -e "${RED}Error: Required files missing. Aborting.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required files present${NC}"
echo ""

################################################################################
# Step 6: Create ZIP Archive
################################################################################

echo -e "${BLUE}[6/8]${NC} Creating ZIP archive..."

cd $BUILD_DIR
zip -r ../$DIST_DIR/${PLUGIN_SLUG}-${VERSION}.zip $PLUGIN_SLUG -q
cd ..

FILESIZE=$(du -h $DIST_DIR/${PLUGIN_SLUG}-${VERSION}.zip | cut -f1)

echo -e "${GREEN}✓ ZIP archive created${NC}"
echo -e "  File: ${DIST_DIR}/${PLUGIN_SLUG}-${VERSION}.zip"
echo -e "  Size: $FILESIZE"
echo ""

################################################################################
# Step 7: Generate Checksums
################################################################################

echo -e "${BLUE}[7/8]${NC} Generating checksums..."

cd $DIST_DIR

# MD5
md5sum ${PLUGIN_SLUG}-${VERSION}.zip > ${PLUGIN_SLUG}-${VERSION}.zip.md5
MD5_HASH=$(cat ${PLUGIN_SLUG}-${VERSION}.zip.md5 | awk '{print $1}')
echo -e "  MD5: ${MD5_HASH}"

# SHA256
sha256sum ${PLUGIN_SLUG}-${VERSION}.zip > ${PLUGIN_SLUG}-${VERSION}.zip.sha256
SHA256_HASH=$(cat ${PLUGIN_SLUG}-${VERSION}.zip.sha256 | awk '{print $1}')
echo -e "  SHA256: ${SHA256_HASH}"

cd ..

echo -e "${GREEN}✓ Checksums generated${NC}"
echo ""

################################################################################
# Step 8: Publish GitHub Release
################################################################################

echo -e "${BLUE}[8/8]${NC} Publishing GitHub release..."

# Extract release notes from readme.txt
NOTES_FILE="${BUILD_DIR}/release-notes.txt"
echo "Inovio Payment Gateway for WooCommerce v${VERSION}" > "$NOTES_FILE"
echo "" >> "$NOTES_FILE"
echo "## Changes" >> "$NOTES_FILE"

# Try to extract changelog for this version from readme.txt
if [ -f "${PLUGIN_DIR}/readme.txt" ]; then
    # Look for version-specific changes or use latest changelog section
    grep -A 10 "^${VERSION}" "${PLUGIN_DIR}/readme.txt" >> "$NOTES_FILE" 2>/dev/null || \
    grep -A 10 "== Changelog ==" "${PLUGIN_DIR}/readme.txt" | tail -n +2 >> "$NOTES_FILE" 2>/dev/null || \
    echo "See repository for changelog details." >> "$NOTES_FILE"
else
    echo "Distribution package for Inovio Payment Gateway WordPress plugin." >> "$NOTES_FILE"
fi

echo -e "${YELLOW}Creating git tag v${VERSION}...${NC}"
if ! git tag -a "v${VERSION}" -m "Release ${VERSION}"; then
    echo -e "${RED}✗ Failed to create git tag${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Tag created${NC}"

echo -e "${YELLOW}Pushing commit and tag to GitHub...${NC}"
if ! git push origin HEAD; then
    echo -e "${RED}✗ Failed to push commit${NC}"
    git tag -d "v${VERSION}"
    exit 1
fi

if ! git push origin "v${VERSION}"; then
    echo -e "${RED}✗ Failed to push tag${NC}"
    git tag -d "v${VERSION}"
    exit 1
fi
echo -e "${GREEN}✓ Pushed to GitHub${NC}"

echo -e "${YELLOW}Creating GitHub release with assets...${NC}"
if gh release create "v${VERSION}" \
    --title "Inovio Payment Gateway v${VERSION}" \
    --notes-file "$NOTES_FILE" \
    --verify-tag \
    "${DIST_DIR}/${PLUGIN_SLUG}-${VERSION}.zip#WordPress Plugin ZIP (${FILESIZE})" \
    "${DIST_DIR}/${PLUGIN_SLUG}-${VERSION}.zip.md5#MD5 Checksum" \
    "${DIST_DIR}/${PLUGIN_SLUG}-${VERSION}.zip.sha256#SHA256 Checksum"; then

    echo -e "${GREEN}✓ GitHub release created successfully${NC}"

    # Get release URL
    RELEASE_URL=$(gh release view "v${VERSION}" --json url -q .url 2>/dev/null || echo "")

    rm -f "$NOTES_FILE"
else
    echo -e "${RED}✗ Failed to create GitHub release${NC}"
    echo -e "${YELLOW}Cleaning up...${NC}"
    git push origin ":v${VERSION}" 2>/dev/null || true
    git tag -d "v${VERSION}" 2>/dev/null || true
    rm -f "$NOTES_FILE"
    exit 1
fi

echo ""

################################################################################
# Summary
################################################################################

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Release Published Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  Version: ${YELLOW}${VERSION}${NC}"
echo -e "  Tag: ${YELLOW}v${VERSION}${NC}"
if [ -n "$RELEASE_URL" ]; then
    echo -e "  Release: ${BLUE}${RELEASE_URL}${NC}"
fi
echo ""
echo -e "Distribution files:"
echo -e "  • ${PLUGIN_SLUG}-${VERSION}.zip (${FILESIZE})"
echo -e "  • ${PLUGIN_SLUG}-${VERSION}.zip.md5"
echo -e "  • ${PLUGIN_SLUG}-${VERSION}.zip.sha256"
echo ""
echo -e "${YELLOW}Assets available at:${NC}"
echo -e "  ${BLUE}${RELEASE_URL:-https://github.com/[org]/[repo]/releases/tag/v${VERSION}}${NC}"
echo ""

# Optional: Clean build directory
read -p "Clean build directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf $BUILD_DIR
    echo -e "${GREEN}✓ Build directory cleaned${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"

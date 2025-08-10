#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if version is provided
VERSION=$1
if [ -z "$VERSION" ]; then
  echo -e "${RED}Usage: ./scripts/release.sh <version>${NC}"
  echo "Example: ./scripts/release.sh 1.0.0"
  exit 1
fi

echo -e "${GREEN}🚀 Building ZenDevToolkit v$VERSION...${NC}"

# Clean previous builds
rm -rf build releases
mkdir -p releases

# Build the app
echo "Building Release configuration..."
xcodebuild -scheme ZenDevToolkit \
  -configuration Release \
  -derivedDataPath ./build \
  clean build > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Build failed!${NC}"
  exit 1
fi

# Create zip
echo "Creating zip archive..."
cd build/Build/Products/Release
zip -r -q ../../../../releases/ZenDevToolkit-v$VERSION.zip ZenDevToolkit.app
cd - > /dev/null

# Calculate SHA256
SHA256=$(shasum -a 256 releases/ZenDevToolkit-v$VERSION.zip | awk '{print $1}')

echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo -e "${YELLOW}📦 Release Info:${NC}"
echo "  File: releases/ZenDevToolkit-v$VERSION.zip"
echo "  SHA256: $SHA256"
echo ""
echo -e "${YELLOW}📝 Cask Formula:${NC}"
cat << EOF
cask "zen-dev-toolkit" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/dilee/zen-dev-toolkit/releases/download/v#{version}/ZenDevToolkit.zip"
  name "ZenDevToolkit"
  desc "Developer utilities in your menu bar"
  homepage "https://github.com/dilee/zen-dev-toolkit"

  app "ZenDevToolkit.app"

  zap trash: [
    "~/Library/Preferences/com.dilee.ZenDevToolkit.plist",
    "~/Library/Application Support/ZenDevToolkit",
  ]
end
EOF
echo ""
echo -e "${YELLOW}🎯 Next Steps:${NC}"
echo "  1. Test the app: open releases/ZenDevToolkit-v$VERSION.zip"
echo "  2. Create git tag: git tag -a v$VERSION -m \"Release v$VERSION\""
echo "  3. Push tag: git push origin v$VERSION"
echo "  4. GitHub Actions will handle the rest!"
echo ""
echo "  Or manually:"
echo "  1. Upload releases/ZenDevToolkit-v$VERSION.zip to GitHub Releases"
echo "  2. Update homebrew-tap/Casks/zen-dev-toolkit.rb with the formula above"
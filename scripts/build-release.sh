#!/bin/bash

# Build and Sign ZenDevToolkit for Release
# This script builds, signs, and notarizes the app for distribution

set -e  # Exit on any error

# Configuration
APP_NAME="ZenDevToolkit"
SCHEME="ZenDevToolkit"
CONFIGURATION="Release"
ARCHIVE_PATH="build/${APP_NAME}.xcarchive"
EXPORT_PATH="build/export"
APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
ZIP_PATH="build/${APP_NAME}.zip"

# Developer credentials - set these environment variables
DEVELOPER_ID=${APPLE_DEVELOPER_ID:-"3Z86BP8YAG"}
BUNDLE_ID="com.luminaxa.ZenDevToolkit"

echo "🏗️  Building ${APP_NAME} for release..."

# Clean build directory
rm -rf build
mkdir -p build

# Build and archive
echo "📦 Creating archive..."
xcodebuild -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    archive

# Export signed app
echo "✍️  Exporting signed app..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist scripts/ExportOptions-Distribution.plist

# Verify code signing
echo "🔍 Verifying code signature..."
codesign --verify --verbose=2 "${APP_PATH}"
spctl --assess --verbose=2 "${APP_PATH}"

# Create ZIP for notarization
echo "📦 Creating ZIP for notarization..."
cd build/export
zip -r "../${APP_NAME}.zip" "${APP_NAME}.app"
cd ../..

# Submit for notarization (requires Apple ID and app-specific password)
if [ ! -z "${APPLE_ID}" ] && [ ! -z "${APPLE_APP_PASSWORD}" ]; then
    echo "📤 Submitting for notarization..."
    xcrun notarytool submit "${ZIP_PATH}" \
        --apple-id "${APPLE_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --team-id "${DEVELOPER_ID}" \
        --wait
    
    # Staple the notarization
    echo "📎 Stapling notarization..."
    xcrun stapler staple "${APP_PATH}"
    
    # Verify notarization
    echo "✅ Verifying notarization..."
    xcrun stapler validate "${APP_PATH}"
    spctl --assess --verbose=2 "${APP_PATH}"
else
    echo "⚠️  Skipping notarization - set APPLE_ID and APPLE_APP_PASSWORD environment variables"
    echo "   You can notarize manually later with:"
    echo "   xcrun notarytool submit ${ZIP_PATH} --apple-id YOUR_APPLE_ID --password YOUR_APP_PASSWORD --team-id ${DEVELOPER_ID} --wait"
fi

echo "✅ Build complete!"
echo "📁 Signed app: ${APP_PATH}"
echo "📦 ZIP file: ${ZIP_PATH}"

# Create DMG for distribution (optional)
if command -v create-dmg &> /dev/null; then
    echo "💿 Creating DMG..."
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_PATH}/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 120 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 425 120 \
        "build/${APP_NAME}.dmg" \
        "build/export/"
    echo "💿 DMG created: build/${APP_NAME}.dmg"
fi
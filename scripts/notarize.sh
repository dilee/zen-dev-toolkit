#!/bin/bash

# Notarization script for ZenDevToolkit
# Usage: ./scripts/notarize.sh [path-to-app-or-zip]

set -e

APP_PATH=${1:-"build/export/ZenDevToolkit.app"}
DEVELOPER_ID="3Z86BP8YAG"

if [ ! -e "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    echo "Usage: $0 [path-to-app-or-zip]"
    exit 1
fi

# Check if it's an app or zip
if [[ "$APP_PATH" == *.app ]]; then
    # Create ZIP for notarization
    ZIP_PATH="${APP_PATH%.*}.zip"
    echo "📦 Creating ZIP: $ZIP_PATH"
    cd "$(dirname "$APP_PATH")"
    zip -r "$(basename "$ZIP_PATH")" "$(basename "$APP_PATH")"
    cd - > /dev/null
    ZIP_PATH="$(dirname "$APP_PATH")/$(basename "$ZIP_PATH")"
else
    ZIP_PATH="$APP_PATH"
fi

# Check for credentials
if [ -z "${APPLE_ID}" ] || [ -z "${APPLE_APP_PASSWORD}" ]; then
    echo "❌ Missing credentials!"
    echo "Set environment variables:"
    echo "  export APPLE_ID='your-apple-id@email.com'"
    echo "  export APPLE_APP_PASSWORD='your-app-specific-password'"
    echo ""
    echo "To create an app-specific password:"
    echo "1. Go to https://appleid.apple.com/"
    echo "2. Sign in and go to Security section"
    echo "3. Generate an app-specific password for 'ZenDevToolkit Notarization'"
    exit 1
fi

echo "📤 Submitting for notarization..."
echo "   ZIP: $ZIP_PATH"
echo "   Apple ID: $APPLE_ID"
echo "   Team ID: $DEVELOPER_ID"

# Submit for notarization
SUBMISSION_ID=$(xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$DEVELOPER_ID" \
    --output-format json | jq -r '.id')

if [ "$SUBMISSION_ID" == "null" ] || [ -z "$SUBMISSION_ID" ]; then
    echo "❌ Submission failed"
    exit 1
fi

echo "🔄 Submission ID: $SUBMISSION_ID"
echo "⏳ Waiting for notarization result..."

# Wait for result
xcrun notarytool wait "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$DEVELOPER_ID"

# Get result
STATUS=$(xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$DEVELOPER_ID" \
    --output-format json | jq -r '.status')

if [ "$STATUS" == "Accepted" ]; then
    echo "✅ Notarization successful!"
    
    if [[ "$APP_PATH" == *.app ]]; then
        echo "📎 Stapling notarization to app..."
        xcrun stapler staple "$APP_PATH"
        
        echo "🔍 Verifying stapled app..."
        xcrun stapler validate "$APP_PATH"
        spctl --assess --verbose=2 "$APP_PATH"
        
        echo "✅ App is now notarized and trusted!"
    fi
else
    echo "❌ Notarization failed with status: $STATUS"
    
    # Show detailed log
    echo "📝 Getting detailed log..."
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --team-id "$DEVELOPER_ID"
    
    exit 1
fi
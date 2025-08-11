# Certificate Setup for ZenDevToolkit Distribution

## Current Status
You currently have only a **Development Certificate**, but need a **Developer ID Application Certificate** for trusted distribution outside the App Store.

## Available Certificates
```
✅ Apple Development: admin@luminaxa.com (CUG9Y39CQ9) - For development/testing
❌ Developer ID Application - MISSING - For distribution outside App Store
```

## Step 1: Download Developer ID Application Certificate

### Option A: Using Xcode (Recommended)
1. Open **Xcode** → **Settings** → **Accounts**
2. Select your Apple ID account
3. Click **Manage Certificates**
4. Click the **+** button
5. Select **Developer ID Application**
6. Click **Done**

### Option B: Using Apple Developer Portal
1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click the **+** button to create a new certificate
3. Select **Developer ID Application** under "Production"
4. Follow the prompts to create and download the certificate
5. Double-click the downloaded `.cer` file to install it in Keychain

## Step 2: Verify Certificate Installation

Run this command to check if the certificate is installed:
```bash
security find-identity -v -p codesigning
```

You should see something like:
```
1) 85630C9F9CDA5C0538D6155480AE59DD7B4B9D66 "Apple Development: admin@luminaxa.com (CUG9Y39CQ9)"
2) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX "Developer ID Application: Your Name (CM963C9M63)"
   2 valid identities found
```

## Step 3: Build for Distribution

Once you have the Developer ID Application certificate:

```bash
# Use the distribution export options
./scripts/build-release.sh

# Or manually with distribution settings
xcodebuild -exportArchive \
    -archivePath build/ZenDevToolkit.xcarchive \
    -exportPath build/export-distribution \
    -exportOptionsPlist scripts/ExportOptions-Distribution.plist
```

## Step 4: Test Current Setup (Development Build)

For now, you can create a development build for testing:
```bash
# This will work with your current certificate
xcodebuild -exportArchive \
    -archivePath build/ZenDevToolkit.xcarchive \
    -exportPath build/export \
    -exportOptionsPlist scripts/ExportOptions.plist
```

**Note**: Development builds work on your local machine and other devices that have been added to your developer account, but won't be trusted on other Macs.

## Why You Need Developer ID Application Certificate

- **Development Certificate**: Only works on registered devices and your local machine
- **Developer ID Application Certificate**: Required for:
  - Distribution outside the Mac App Store
  - Notarization by Apple
  - Trusted installation on any Mac
  - Homebrew distribution
  - Direct website downloads

## Alternative: Mac App Store Distribution

If you prefer, you can also create a "Mac App Store" certificate for App Store distribution, but this requires App Store review and approval.
# GitHub Secrets Setup for Automated Code Signing

This guide shows how to set up GitHub Secrets for fully automated code signing and notarization.

## Required Secrets

Go to: `https://github.com/dilee/zen-dev-toolkit/settings/secrets/actions`

Add these 5 secrets:

### 1. APPLE_ID
- **Value**: `dilee.dev@gmail.com`
- **Description**: Your Apple Developer account email

### 2. APPLE_APP_PASSWORD
- **How to get**: 
  1. Go to https://appleid.apple.com/
  2. Sign in with `dilee.dev@gmail.com`
  3. Security → App-Specific Passwords
  4. Generate new password with label "ZenDevToolkit GitHub Actions"
- **Value**: The generated app-specific password (like `abcd-efgh-ijkl-mnop`)

### 3. DEVELOPER_ID_APPLICATION_P12
- **How to get**:
  ```bash
  # Export your certificate as .p12 file
  # In Keychain Access:
  # 1. Find "Developer ID Application: Dileesha Rajapakse (3Z86BP8YAG)"
  # 2. Right-click → Export
  # 3. Save as "ZenDevToolkit-cert.p12" with a password
  # 4. Convert to base64:
  base64 -i ZenDevToolkit-cert.p12 | pbcopy
  ```
- **Value**: Base64-encoded content (paste from clipboard)

### 4. DEVELOPER_ID_APPLICATION_PASSWORD
- **Value**: The password you used when exporting the .p12 file

### 5. TAP_TOKEN (existing)
- **Value**: Your existing GitHub token for homebrew tap updates
- **Permissions**: `repo` scope to push to `dilee/homebrew-tap`

## Certificate Export Steps (Detailed)

### Step 1: Open Keychain Access
1. Open **Keychain Access** app
2. Select **login** keychain
3. Category: **Certificates**

### Step 2: Find Your Certificate
Look for: `Developer ID Application: Dileesha Rajapakse (3Z86BP8YAG)`

### Step 3: Export Certificate
1. **Right-click** the certificate
2. Select **Export "Developer ID Application: Dileesha Rajapakse (3Z86BP8YAG)"**
3. **File format**: Personal Information Exchange (.p12)
4. **Save as**: `ZenDevToolkit-cert.p12`
5. **Choose password**: Use a strong password (save it for step 4 above)
6. **Export**

### Step 4: Convert to Base64
```bash
# Convert the .p12 file to base64
base64 -i ZenDevToolkit-cert.p12 | pbcopy
```

This copies the base64 content to your clipboard - paste this as the value for `DEVELOPER_ID_APPLICATION_P12`.

### Step 5: Clean Up
```bash
# Remove the .p12 file (security)
rm ZenDevToolkit-cert.p12
```

## Verification

Once all secrets are added, you can test the automation:

```bash
# Create and push a test tag
git tag v1.0.0-test
git push origin v1.0.0-test

# Watch the GitHub Actions run
# It should:
# ✅ Import certificate
# ✅ Build and sign app  
# ✅ Notarize app
# ✅ Create GitHub release
# ✅ Update homebrew tap
```

## Security Notes

- **Never commit** .p12 files or passwords to your repository
- **Use app-specific passwords** instead of your main Apple ID password
- **GitHub Secrets are encrypted** and only accessible to GitHub Actions
- **Certificate expires** - you'll need to update the P12 secret when renewed

## Troubleshooting

### Certificate Import Issues
```bash
# If import fails, check certificate validity:
security find-identity -v -p codesigning
```

### Notarization Issues
- Ensure Apple ID has Developer Program membership
- Check that app-specific password is active
- Verify team ID matches your certificate

### Build Issues
- Check Xcode version compatibility
- Verify export options match your certificate type
- Ensure all required entitlements are present
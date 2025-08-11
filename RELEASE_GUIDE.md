# Release Guide

## Setup (One-time)

### 1. Configure GitHub Secrets for Automated Code Signing
Follow the detailed guide: [`scripts/setup-github-secrets.md`](scripts/setup-github-secrets.md)

Required secrets:
- `APPLE_ID`: Your Apple Developer email (dilee.dev@gmail.com)
- `APPLE_APP_PASSWORD`: App-specific password from Apple ID
- `DEVELOPER_ID_APPLICATION_P12`: Base64-encoded certificate (.p12)
- `DEVELOPER_ID_APPLICATION_PASSWORD`: Password for the .p12 file
- `TAP_TOKEN`: GitHub token for homebrew tap updates

### 2. Homebrew Tap Repository
Your `homebrew-tap` repository should have this structure:
```
homebrew-tap/
├── README.md
└── Casks/
    └── zen-dev-toolkit.rb
```

## Automated Release Process

### For Any Release (Beta, RC, or Stable)

1. **Update version references**:
   - Update version badge in README.md
   - Update CHANGELOG.md with release notes

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "chore: prepare v1.0.0 release"
   git push
   ```

3. **Create and push tag** (triggers full automation):
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

4. **GitHub Actions automatically handles**:
   - ✅ **Code Signing**: Imports Developer ID certificate
   - ✅ **Build**: Creates release archive with Xcode
   - ✅ **Notarization**: Submits to Apple and waits for approval
   - ✅ **Stapling**: Attaches notarization ticket to app
   - ✅ **Verification**: Confirms app is trusted by macOS
   - ✅ **GitHub Release**: Creates release with signed ZIP
   - ✅ **Homebrew Update**: Updates tap with new version and SHA256

5. **Result**: Fully trusted app ready for distribution!

### Manual Testing (Optional)
```bash
# Build and test locally before tagging
./scripts/build-release.sh
open build/export/ZenDevToolkit.app
```

### For Stable Releases (e.g., v1.0.0)

Same process, but:
- Remove "(Beta)" from README title
- Update version badge to stable color (green instead of yellow)
- More thorough testing before release

## Testing Homebrew Installation

After release and tap update:
```bash
# Remove if already installed
brew uninstall --cask zen-dev-toolkit

# Reinstall
brew tap dilee/tap
brew install --cask zen-dev-toolkit
```

## Version Numbering

- **Beta**: `v1.0.0-beta.1`, `v1.0.0-beta.2`, etc.
- **Release Candidate**: `v1.0.0-rc.1`, `v1.0.0-rc.2`, etc.
- **Stable**: `v1.0.0`, `v1.0.1`, `v1.1.0`, etc.

## Troubleshooting

### Build fails locally
- Ensure Xcode is up to date
- Clean build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### GitHub Actions fails
- Check that repository secrets are set correctly
- Ensure tag format is correct (must start with 'v')

### Homebrew installation fails
- Verify SHA256 matches the uploaded file
- Check that the download URL is correct
- Ensure the zip file structure is correct (should contain ZenDevToolkit.app at root)
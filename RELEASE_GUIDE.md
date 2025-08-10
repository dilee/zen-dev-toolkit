# Release Guide

## Setup (One-time)

### 1. Set up GitHub Token for Homebrew Tap Updates
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Add as repository secret named `TAP_TOKEN` in zen-dev-toolkit repo settings

### 2. Prepare Homebrew Tap Repository
Your `homebrew-tap` repository should have this structure:
```
homebrew-tap/
├── README.md
└── Casks/
    └── zen-dev-toolkit.rb
```

## Release Process

### For Beta Releases (e.g., v1.0.0-beta.1)

1. **Update version references**:
   - Update version badge in README.md
   - Update CHANGELOG.md with release notes

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "chore: prepare v1.0.0-beta.1 release"
   git push
   ```

3. **Build and test locally**:
   ```bash
   ./scripts/release.sh 1.0.0-beta.1
   # Test the generated app
   open releases/ZenDevToolkit-v1.0.0-beta.1.zip
   ```

4. **Create and push tag**:
   ```bash
   git tag -a v1.0.0-beta.1 -m "Beta release v1.0.0-beta.1"
   git push origin v1.0.0-beta.1
   ```

5. **GitHub Actions will automatically**:
   - Build the app
   - Create GitHub release
   - Upload the zip file
   - Update your homebrew-tap (if TAP_TOKEN is set)

6. **If manual update needed for homebrew-tap**:
   - Copy the cask formula from the release script output
   - Update `homebrew-tap/Casks/zen-dev-toolkit.rb`
   - Commit and push to homebrew-tap

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
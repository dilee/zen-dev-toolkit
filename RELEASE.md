# Release Process

This document outlines the release process for ZenDevToolkit.

## Release Checklist

### Pre-Release
- [ ] All tests passing
- [ ] Code review completed for all changes
- [ ] Documentation updated
- [ ] CHANGELOG.md updated with all changes
- [ ] Version numbers updated in all locations

### Release Steps

## 1. Prepare Release

```bash
# 1. Ensure you're on develop branch with latest changes
git checkout develop
git pull origin develop

# 2. Create release branch
git checkout -b release/vX.Y.Z

# 3. Update version numbers
# Edit Info.plist - CFBundleShortVersionString
# Update CHANGELOG.md - move Unreleased to new version section
# Update README.md if needed
```

## 2. Update Version Files

### Info.plist
```xml
<key>CFBundleShortVersionString</key>
<string>X.Y.Z</string>
<key>CFBundleVersion</key>
<string>BUILD_NUMBER</string>
```

### CHANGELOG.md
```markdown
## [X.Y.Z] - YYYY-MM-DD
### Added
- New features...
### Changed
- Changes...
### Fixed
- Bug fixes...
```

## 3. Test Release Build

```bash
# Clean build
xcodebuild clean -scheme ZenDevToolkit

# Build release configuration
xcodebuild -scheme ZenDevToolkit -configuration Release

# Run tests
xcodebuild test -scheme ZenDevToolkit

# Archive for distribution (optional)
xcodebuild archive -scheme ZenDevToolkit \
  -archivePath ./build/ZenDevToolkit.xcarchive
```

## 4. Commit and Tag

```bash
# Commit version bump
git add .
git commit -m "chore: bump version to vX.Y.Z"

# Merge to main
git checkout main
git merge --no-ff release/vX.Y.Z

# Tag the release
git tag -a vX.Y.Z -m "Release version X.Y.Z

Summary of changes:
- Feature 1
- Feature 2
- Bug fix 1"

# Push to remote
git push origin main
git push origin vX.Y.Z

# Merge back to develop
git checkout develop
git merge --no-ff main
git push origin develop

# Delete release branch
git branch -d release/vX.Y.Z
```

## 5. Create GitHub Release

1. Go to https://github.com/dilee/zen-dev-toolkit/releases/new
2. Select the tag `vX.Y.Z`
3. Set release title: `ZenDevToolkit vX.Y.Z`
4. Copy release notes from CHANGELOG.md
5. Attach binary (optional):
   - Export from Xcode Archive
   - Create DMG or ZIP
6. Mark as pre-release if applicable
7. Publish release

## 6. Distribution (Future)

### Mac App Store
```bash
# When ready for App Store:
# 1. Archive in Xcode
# 2. Validate
# 3. Distribute to App Store Connect
```

### Homebrew (Future)
```ruby
# Update homebrew formula
class Zendevtoolkit < Formula
  desc "Developer utilities in your menu bar"
  homepage "https://github.com/dilee/zen-dev-toolkit"
  url "https://github.com/dilee/zen-dev-toolkit/archive/vX.Y.Z.tar.gz"
  sha256 "SHA256_HASH"
  version "X.Y.Z"
end
```

## Version Numbering Guidelines

### When to bump versions:

| Change Type | Version Component | Example |
|------------|------------------|---------|
| Bug fixes only | PATCH | 1.0.0 → 1.0.1 |
| New features (backwards compatible) | MINOR | 1.0.1 → 1.1.0 |
| Breaking changes | MAJOR | 1.1.0 → 2.0.0 |

### Pre-release versions:
- Alpha: `vX.Y.Z-alpha.N` (internal testing)
- Beta: `vX.Y.Z-beta.N` (external testing)
- RC: `vX.Y.Z-rc.N` (release candidate)

## Post-Release

1. **Monitor Issues**: Check for bug reports after release
2. **Update Project Board**: Move completed items to Done
3. **Plan Next Release**: Create issues for next version
4. **Announce**: 
   - Twitter/Social Media (optional)
   - Dev communities (optional)

## Hotfix Process

For urgent production fixes:

```bash
# 1. Create hotfix from main
git checkout main
git checkout -b hotfix/vX.Y.Z

# 2. Fix the issue
# ... make changes ...

# 3. Update version (patch bump)
# Update Info.plist, CHANGELOG.md

# 4. Commit
git commit -m "fix: critical issue description"

# 5. Merge to main and tag
git checkout main
git merge --no-ff hotfix/vX.Y.Z
git tag -a vX.Y.Z -m "Hotfix version X.Y.Z"

# 6. Merge to develop
git checkout develop
git merge --no-ff hotfix/vX.Y.Z

# 7. Push everything
git push origin main develop vX.Y.Z

# 8. Delete hotfix branch
git branch -d hotfix/vX.Y.Z
```

## Automation (Future)

Consider setting up GitHub Actions for:
- Automatic version bumping
- Release note generation
- Binary building and attachment
- Notification on release

## Release Communication Template

### GitHub Release Description
```markdown
## 🎉 ZenDevToolkit vX.Y.Z

### ✨ What's New
- Feature 1 description
- Feature 2 description

### 🐛 Bug Fixes
- Fixed issue #XX: description
- Fixed issue #YY: description

### 📋 Full Changelog
See [CHANGELOG.md](CHANGELOG.md) for complete details.

### 📦 Installation
```bash
# Clone and build
git clone https://github.com/dilee/zen-dev-toolkit.git
cd zen-dev-toolkit
open ZenDevToolkit.xcodeproj
```

### 🙏 Contributors
Thanks to everyone who contributed to this release!
```
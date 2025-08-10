# Versioning Strategy

ZenDevToolkit follows [Semantic Versioning 2.0.0](https://semver.org/) (SemVer) for version numbering.

## Version Format

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible API changes or breaking changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

## Pre-release Versions

Pre-release versions are denoted by appending a hyphen and identifiers:

```
1.0.0-alpha
1.0.0-alpha.1
1.0.0-beta
1.0.0-beta.2
1.0.0-rc.1
```

## Version Bumping Rules

Based on Conventional Commits:

| Commit Type | Version Bump | Example |
|------------|--------------|---------|
| `fix:` | Patch (0.0.X) | 1.2.3 → 1.2.4 |
| `feat:` | Minor (0.X.0) | 1.2.3 → 1.3.0 |
| `perf:` | Patch (0.0.X) | 1.2.3 → 1.2.4 |
| `BREAKING CHANGE:` | Major (X.0.0) | 1.2.3 → 2.0.0 |
| `docs:`, `style:`, `refactor:`, `test:`, `chore:` | No bump | 1.2.3 → 1.2.3 |

## Release Cycle

### Development Phase (0.x.x)
- Major version 0 indicates initial development
- Anything MAY change at any time
- Public API should not be considered stable

### Stable Releases (≥1.0.0)
- Version 1.0.0 defines the public API
- After 1.0.0, version numbers are incremented according to SemVer rules

## Version Timeline

### Current
- **0.1.0** - Initial release with JSON formatter

### Planned
- **0.2.0** - Base64 encoder/decoder
- **0.3.0** - URL encoder/decoder
- **0.4.0** - Hash generator
- **0.5.0** - UUID generator
- **1.0.0** - First stable release with all core tools

## Git Tags

Every release should be tagged in git:

```bash
# For releases
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# For pre-releases
git tag -a v1.0.0-beta.1 -m "Beta release 1.0.0-beta.1"
git push origin v1.0.0-beta.1
```

## Branch Strategy

### Main Branches
- **main**: Production-ready code, tagged releases only
- **develop**: Integration branch for features

### Supporting Branches
- **feature/**: New features (`feature/base64-tool`)
- **fix/**: Bug fixes (`fix/json-validation`)
- **release/**: Release preparation (`release/1.0.0`)
- **hotfix/**: Emergency production fixes (`hotfix/1.2.1`)

## Release Process

1. **Feature Development**
   - Create feature branch from `develop`
   - Implement feature with proper commits
   - Create PR to `develop`

2. **Release Preparation**
   - Create `release/x.y.z` branch from `develop`
   - Update version in:
     - `Info.plist` (CFBundleShortVersionString)
     - `CHANGELOG.md`
     - `README.md` badges
   - Test thoroughly

3. **Release**
   - Merge release branch to `main`
   - Tag with version: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
   - Merge back to `develop`
   - Create GitHub release with:
     - Release notes from CHANGELOG
     - Binary attachments (optional)
     - Installation instructions

4. **Post-Release**
   - Update version in `develop` to next development version
   - Continue development

## Version Locations

Version numbers need to be updated in:

1. **Info.plist**
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.0.0</string>
   ```

2. **CHANGELOG.md**
   - Add new version section
   - Move unreleased items to new version

3. **README.md**
   - Update version badges
   - Update installation instructions if needed

## Automation

Consider using these tools for automation:

- **standard-version**: Automatic version bumping and CHANGELOG generation
- **semantic-release**: Fully automated version management
- **GitHub Actions**: Automate release process

## Examples

### Patch Release (Bug Fix)
```bash
# Current version: 1.2.3
git commit -m "fix(json): resolve formatting issue with nested arrays"
# Next version: 1.2.4
```

### Minor Release (New Feature)
```bash
# Current version: 1.2.3
git commit -m "feat(base64): add base64 encoding and decoding tool"
# Next version: 1.3.0
```

### Major Release (Breaking Change)
```bash
# Current version: 1.2.3
git commit -m "feat(ui): redesign tool interface

BREAKING CHANGE: Tool selection API has changed, old plugins incompatible"
# Next version: 2.0.0
```

## Public API

For ZenDevToolkit, the public API includes:
- Menu bar interface
- Tool interfaces and functionality
- Keyboard shortcuts
- Window sizing constraints
- File format support

Changes to any of these that are not backwards compatible constitute a breaking change.
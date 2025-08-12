# Update Checker Documentation

## Overview

ZenDevToolkit includes a lightweight update checker that notifies users when new versions are available on GitHub. The implementation is simple, non-intrusive, and respects user preferences.

## Features

- **Automatic Check on Launch**: Checks for updates in the background when the app starts (max once per 24 hours)
- **Manual Check**: Users can manually check via right-click menu → "Check for Updates..."
- **Non-Intrusive Notification**: Shows a subtle banner in the app instead of modal dialogs
- **Version Skipping**: Users can skip specific versions they don't want to be notified about
- **Smart Version Comparison**: Handles semantic versioning including beta/pre-release versions

## How It Works

1. **GitHub API Integration**: Queries `https://api.github.com/repos/dilee/zen-dev-toolkit/releases/latest`
2. **Version Comparison**: Compares current app version with latest GitHub release
3. **User Notification**: Shows update banner if newer version is available
4. **Update Process**: Directs users to GitHub release page for download

## User Experience

### Automatic Updates
- Checks silently on app launch (once per 24 hours)
- Shows subtle notification banner if update available
- No interruption to workflow

### Manual Check
1. Right-click menu bar icon
2. Select "Check for Updates..."
3. Shows alert with current status

### Update Options
- **View Release**: Opens GitHub release page in browser
- **Skip This Version**: Won't notify about this specific version again
- **Remind Me Later**: Dismisses notification, will check again next launch

## Distribution Channel Considerations

### Homebrew Users
- Update notification directs to run: `brew upgrade zen-dev-toolkit`
- Respects Homebrew's update mechanism

### Direct Download Users
- Directs to GitHub releases page
- Users download and install .pkg file manually

## Implementation Details

### Files Added
- `UpdateChecker.swift`: Core update checking logic
- `UpdateNotificationView.swift`: UI for update notifications

### Settings Stored
- `lastUpdateCheck`: Timestamp of last check (UserDefaults)
- `skipUpdateVersion`: Version user chose to skip (UserDefaults)

### Version Comparison Logic
```swift
// Handles semantic versioning
"1.0.0" < "1.0.1"  // true
"1.0.0-beta.5" < "1.0.0"  // true (stable > beta)
"1.0.0-beta.5" < "1.0.0-beta.6"  // true
```

## Testing

To test the update checker:

1. **Create a GitHub Release**:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   # Create release on GitHub with this tag
   ```

2. **Force Check in App**:
   - Right-click menu bar icon
   - Select "Check for Updates..."

3. **Simulate Different Scenarios**:
   - Modify `CFBundleShortVersionString` in Info.plist to test version comparisons
   - Clear UserDefaults to reset skip preferences

## Future Enhancements

- [ ] Support for beta channel updates
- [ ] Download progress indicator
- [ ] In-app changelog viewer
- [ ] Auto-download (with user permission)
- [ ] Differential updates for smaller downloads

## Privacy & Security

- **No Analytics**: Update checker only contacts GitHub API
- **No Personal Data**: No user information is transmitted
- **HTTPS Only**: All requests use secure connections
- **User Control**: Can disable or skip versions at any time
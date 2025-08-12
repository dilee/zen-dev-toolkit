import Foundation
import SwiftUI

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var currentVersion = ""
    @Published var releaseURL = ""
    @Published var lastCheckDate: Date?
    
    // Use /releases endpoint to get all releases including pre-releases
    private let githubAPIURL = "https://api.github.com/repos/dilee/zen-dev-toolkit/releases"
    private let userDefaults = UserDefaults.standard
    private let lastCheckKey = "lastUpdateCheck"
    private let skipVersionKey = "skipUpdateVersion"
    
    init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.lastCheckDate = userDefaults.object(forKey: lastCheckKey) as? Date
    }
    
    // Detect if app was installed via Homebrew
    var isHomebrewInstall: Bool {
        // Homebrew installs apps to /Applications or ~/Applications via symlink from Cellar
        let bundlePath = Bundle.main.bundlePath
        // Check if the app is in Homebrew's Cellar directory or linked from it
        return bundlePath.contains("/Homebrew/") || 
               bundlePath.contains("homebrew") ||
               FileManager.default.fileExists(atPath: "/opt/homebrew/bin/zen-dev-toolkit") ||
               FileManager.default.fileExists(atPath: "/usr/local/bin/zen-dev-toolkit")
    }
    
    func checkForUpdates(force: Bool = false) async {
        // Skip if checked recently (within 24 hours) unless forced
        if !force, let lastCheck = lastCheckDate, Date().timeIntervalSince(lastCheck) < 86400 {
            return
        }
        
        guard let url = URL(string: githubAPIURL) else { return }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for 404 or empty response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                print("No releases found on GitHub yet")
                await MainActor.run {
                    self.updateAvailable = false
                    self.lastCheckDate = Date()
                    userDefaults.set(self.lastCheckDate, forKey: lastCheckKey)
                }
                return
            }
            
            // Decode array of releases
            let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
            
            // Get the first release (most recent, including pre-releases)
            guard let release = releases.first else {
                print("No releases found")
                await MainActor.run {
                    self.updateAvailable = false
                    self.lastCheckDate = Date()
                    userDefaults.set(self.lastCheckDate, forKey: lastCheckKey)
                }
                return
            }
            
            await MainActor.run {
                self.latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                self.releaseURL = release.htmlURL
                
                // Check if this version was previously skipped
                let skippedVersion = userDefaults.string(forKey: skipVersionKey)
                if skippedVersion == self.latestVersion && !force {
                    self.updateAvailable = false
                    return
                }
                
                // Compare versions
                self.updateAvailable = isNewerVersion(self.latestVersion, than: self.currentVersion)
                
                // Update last check date
                self.lastCheckDate = Date()
                userDefaults.set(self.lastCheckDate, forKey: lastCheckKey)
            }
        } catch {
            // Silent fail for automatic checks, only log for debugging
            if force {
                print("Update check failed: \(error.localizedDescription)")
            }
            await MainActor.run {
                self.updateAvailable = false
            }
        }
    }
    
    func skipThisVersion() {
        userDefaults.set(latestVersion, forKey: skipVersionKey)
        updateAvailable = false
    }
    
    func openReleaseNotes() {
        if let url = URL(string: releaseURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        // Handle beta versions (e.g., "1.0.0-beta.5")
        let newClean = new.split(separator: "-")[0]
        let currentClean = current.split(separator: "-")[0]
        
        let newComponents = newClean.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentClean.split(separator: ".").compactMap { Int($0) }
        
        // Compare major.minor.patch
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if newValue > currentValue {
                return true
            } else if newValue < currentValue {
                return false
            }
        }
        
        // If versions are equal, check for beta suffix
        if new.contains("-") && !current.contains("-") {
            return false // Stable version is newer than beta
        } else if !new.contains("-") && current.contains("-") {
            return true // New stable version is newer than current beta
        } else if new.contains("-") && current.contains("-") {
            // Both are pre-release, compare the full string
            return new > current
        }
        
        return false
    }
}

// GitHub API Response Model
struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlURL: String
    let body: String?
    let publishedAt: String
    let prerelease: Bool
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
        case body
        case publishedAt = "published_at"
        case prerelease
        case assets
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadURL: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}
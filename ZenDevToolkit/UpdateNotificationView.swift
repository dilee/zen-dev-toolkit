import SwiftUI

struct UpdateNotificationView: View {
    @ObservedObject var updateChecker = UpdateChecker.shared
    @State private var showNotification = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showNotification && updateChecker.updateAvailable {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Available")
                            .font(.caption.bold())
                        Text("Version \(updateChecker.latestVersion) is available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("View") {
                        updateChecker.openReleaseNotes()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    
                    Button {
                        withAnimation {
                            showNotification = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
            }
        }
        .onAppear {
            // Show notification after a short delay if update is available
            if updateChecker.updateAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showNotification = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Check if we should show the notification when app becomes active
            if updateChecker.updateAvailable && !showNotification {
                withAnimation {
                    showNotification = true
                }
            }
        }
    }
}
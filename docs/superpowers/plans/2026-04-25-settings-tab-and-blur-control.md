# Settings Tab and Global Blur Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Settings tab for account management and global visual customization (blur intensity).

**Architecture:** Use `@AppStorage` for persistent settings and SwiftUI `Environment` for global state propagation to card components.

**Tech Stack:** SwiftUI, Spotify Web API, KeychainSwift.

---

### Task 1: Data Model and Environment
Define the `BlurIntensity` enum and the environment plumbing.

**Files:**
- Create: `Music Stats iOS/Music Stats iOS/Types/BlurIntensity.swift`
- Create: `Music Stats iOS/Music Stats iOS/Types/EnvironmentKeys.swift`
- Create: `Music Stats iOS/Music Stats iOSTests/BlurIntensityTests.swift`

- [ ] **Step 1: Create BlurIntensity enum**
Create `Music Stats iOS/Music Stats iOS/Types/BlurIntensity.swift`:
```swift
import Foundation

enum BlurIntensity: Int, CaseIterable, Identifiable {
    case none = 0
    case subtle = 3
    case standard = 5
    case strong = 10
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .subtle: return "Subtle"
        case .standard: return "Default"
        case .strong: return "Strong"
        }
    }
}
```

- [ ] **Step 2: Create Environment Keys**
Create `Music Stats iOS/Music Stats iOS/Types/EnvironmentKeys.swift`:
```swift
import SwiftUI

struct CardBlurKey: EnvironmentKey {
    static let defaultValue: CGFloat = 5
}

extension EnvironmentValues {
    var cardBlur: CGFloat {
        get { self[CardBlurKey.self] }
        set { self[CardBlurKey.self] = newValue }
    }
}
```

- [ ] **Step 3: Write Unit Test for BlurIntensity**
Create `Music Stats iOS/Music Stats iOSTests/BlurIntensityTests.swift`:
```swift
import Testing
import SwiftUI
@testable import Music_Stats_iOS

struct BlurIntensityTests {
    @Test func testBlurIntensityValues() {
        #expect(BlurIntensity.none.rawValue == 0)
        #expect(BlurIntensity.subtle.rawValue == 3)
        #expect(BlurIntensity.standard.rawValue == 5)
        #expect(BlurIntensity.strong.rawValue == 10)
    }
    
    @Test func testBlurIntensityDisplayNames() {
        #expect(BlurIntensity.none.displayName == "None")
        #expect(BlurIntensity.standard.displayName == "Default")
    }
}
```

- [ ] **Step 4: Run tests**
Run: `xcodebuild test -project "Music Stats iOS.xcodeproj" -scheme "Music Stats iOS" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing Music_Stats_iOSTests/BlurIntensityTests`

- [ ] **Step 5: Commit**
```bash
git add "Music Stats iOS/Music Stats iOS/Types/BlurIntensity.swift" "Music Stats iOS/Music Stats iOS/Types/EnvironmentKeys.swift" "Music Stats iOS/Music Stats iOSTests/BlurIntensityTests.swift"
git commit -m "feat: add BlurIntensity model and environment keys"
```

### Task 2: App Level Integration
Handle persistence and environment injection at the app root.

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/MusicStatsiOSApp.swift`

- [ ] **Step 1: Update MusicStatsiOSApp**
Modify `Music Stats iOS/Music Stats iOS/MusicStatsiOSApp.swift`:
```swift
import SwiftUI

@main
struct MusicStatsiOSApp: App {
    @StateObject private var authManager = AuthManager()
    @AppStorage("cardBlurIntensity") private var blurIntensity: Int = BlurIntensity.standard.rawValue

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    ProgressView("Logging in...")
                } else if authManager.isAuthenticated {
                    TabUIView()
                        .environment(\.cardBlur, CGFloat(blurIntensity))
                } else {
                    AuthorizationView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
```

- [ ] **Step 2: Commit**
```bash
git commit -am "feat: integrate cardBlur environment and AppStorage persistence"
```

### Task 3: Settings View Implementation
Create the Settings UI with account info and blur controls.

**Files:**
- Create: `Music Stats iOS/Music Stats iOS/Tabs/Settings/SettingsView.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift`

- [ ] **Step 1: Create SettingsView**
Create `Music Stats iOS/Music Stats iOS/Tabs/Settings/SettingsView.swift`:
```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userTopItems: UserTopItems
    @AppStorage("cardBlurIntensity") private var blurIntensity: Int = BlurIntensity.standard.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let profile = userTopItems.userProfile {
                        HStack {
                            AsyncImage(url: URL(string: profile.images.first?.url ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(profile.displayName)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(role: .destructive) {
                        authManager.logout()
                        userTopItems.reset()
                    } label: {
                        Text("Log Out")
                    }
                }
                
                Section("Appearance") {
                    Picker("Card Blur Intensity", selection: $blurIntensity) {
                        ForEach(BlurIntensity.allCases) { intensity in
                            Text(intensity.displayName).tag(intensity.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

- [ ] **Step 2: Update TabUIView**
Modify `Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift` to add the new tab.

- [ ] **Step 3: Commit**
```bash
git add "Music Stats iOS/Music Stats iOS/Tabs/Settings/SettingsView.swift"
git commit -am "feat: implement SettingsView and add it to TabUIView"
```

### Task 4: Card Component Refactoring
Update all cards to respect the `cardBlur` environment value.

**Files:**
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongCard.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumCard.swift`
- Modify: `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistCard.swift`

- [ ] **Step 1: Update SongCard**
Modify `Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongCard.swift` to use `@Environment(\.cardBlur)`.

- [ ] **Step 2: Update AlbumCard**
Modify `Music Stats iOS/Music Stats iOS/Tabs/Top Albums/AlbumCard.swift` to use `@Environment(\.cardBlur)`.

- [ ] **Step 3: Update ArtistCard**
Modify `Music Stats iOS/Music Stats iOS/Tabs/Top Artists/ArtistCard.swift` to use `@Environment(\.cardBlur)`.

- [ ] **Step 4: Verify build**
Run: `xcodebuild build -project "Music Stats iOS.xcodeproj" -scheme "Music Stats iOS" -destination 'platform=iOS Simulator,name=iPhone 16'`

- [ ] **Step 5: Commit**
```bash
git commit -am "refactor: update cards to use cardBlur environment value"
```

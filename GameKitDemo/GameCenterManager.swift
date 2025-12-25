//
    // Project: GameKitDemo
    //  File: GameCenterManager.swift
    //  Created by Noah Carpenter
    //  🐱 Follow me on YouTube! 🎥
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
    //  Dream Big, Code Bigger
    


import SwiftUI
import GameKit
// Platform UI frameworks note:
// - UIKit is only available on iOS, iPadOS, and tvOS (and visionOS via SwiftUI). It does not exist in pure macOS apps.
// - AppKit is the native UI framework for macOS. To present Game Center UI on macOS we must use AppKit types
//   like NSApplication, NSWindow, and NSViewController.
// This file conditionally imports and uses the correct framework so the same source compiles and runs on all platforms.
#if os(iOS)
import UIKit // UIKit is the UI framework for iOS/tvOS; it's not available on macOS.
#elseif os(macOS)
import AppKit // AppKit is the native UI framework for macOS; required for windows, sheets, and NSViewController presentation.
#endif

// GameCenterManager centralizes all Game Center-related work.
// Why have a manager?
// - Keeps GameKit APIs isolated from view code so SwiftUI views stay simple.
// - Provides a single place to authenticate, present system UI, submit scores, and report achievements.
// - Avoids duplicating logic across multiple screens.
final class GameCenterManager: NSObject { // Inherit from NSObject for GameKit callbacks and presentation helpers
    // Placeholder identifiers for your App Store Connect configuration.
    // Why hardcode here?
    // - Keeps identifiers discoverable and consistent across the app.
    // - Easy to replace in one place once real IDs are available.
    static let leaderboardID = "com.example.yourapp.totalScore" // TODO: Replace with your real leaderboard ID from App Store Connect
    static let achievementFirstPointID = "com.example.yourapp.ach.firstPoint" // TODO: Replace with your real achievement ID
    static let achievement10PointsID = "com.example.yourapp.ach.tenPoints"   // TODO: Replace with your real achievement ID
    static let achievement50PointsID = "com.example.yourapp.ach.fiftyPoints" // TODO: Replace with your real achievement ID

    // Shared singleton instance.
    // Why singleton?
    // - Game Center state is global (one local player, one access point), so a single instance is practical.
    // - Simplifies access from anywhere (views, managers) without passing references around.
    static let shared = GameCenterManager()

    // Private initializer enforces singleton usage.
    // Note: override is required because we inherit from NSObject.
    private override init() {}

    // Authenticate the local player.
    // Why call this from app entry or main menu onAppear?
    // - Ensures the player is signed in early and the access point is available.
    // - GameKit won’t repeatedly prompt; it’s safe/idempotent to call.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            // The type of `viewController` is platform-specific:
            // - On iOS it's a UIViewController (UIKit).
            // - On macOS it's an NSViewController (AppKit).
            // We forward it to `present(...)` which wraps the correct UIKit/AppKit presentation per platform.
            if let viewController = viewController {
                self?.present(viewController)
                return
            }

            if let error = error {
                print("Game Center auth error: \(error.localizedDescription)")
            }

            if GKLocalPlayer.local.isAuthenticated {
                #if os(iOS)
                // Configure the access point for iOS
                GKAccessPoint.shared.location = .topLeading
                GKAccessPoint.shared.isActive = true
                #elseif os(macOS)
                // Activate the access point on macOS
                GKAccessPoint.shared.isActive = true
                #endif
                print("Game Center: Player authenticated as \(GKLocalPlayer.local.displayName)")
            } else {
                print("Game Center: Player not authenticated.")
            }
        }
    }

    // Present the system leaderboards UI.
    // Why gate on authentication?
    // - The controller requires an authenticated local player. If not authenticated,
    //   we trigger authenticate() and return.
    func showLeaderboards() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        #if os(iOS)
        // Use the Access Point to navigate into Game Center.
        GKAccessPoint.shared.location = .topLeading
        GKAccessPoint.shared.isActive = true
        if GKAccessPoint.shared.isActive {
            // iOS 26+: trigger now requires a handler parameter; pass an empty closure to ignore completion.
            GKAccessPoint.shared.trigger(state: .leaderboards, handler: {})
        }
        #elseif os(macOS)
        // Use the Access Point to navigate into Game Center on macOS.
        GKAccessPoint.shared.isActive = true
        if GKAccessPoint.shared.isActive {
            GKAccessPoint.shared.trigger(state: .leaderboards, handler: {})
        }
        #endif
    }

    // Present the system achievements UI.
    // Mirrors showLeaderboards() but targets the achievements state.
    func showAchievements() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        #if os(iOS)
        GKAccessPoint.shared.location = .topLeading
        GKAccessPoint.shared.isActive = true
        if GKAccessPoint.shared.isActive {
            GKAccessPoint.shared.trigger(state: .achievements, handler: {})
        }
        #elseif os(macOS)
        GKAccessPoint.shared.isActive = true
        if GKAccessPoint.shared.isActive {
            GKAccessPoint.shared.trigger(state: .achievements, handler: {})
        }
        #endif
    }
    
    // Submit a score to the configured leaderboard.
    // Why submit cumulative totals? (as used by ScoreManager)
    // - Many games track a lifetime score. If your leaderboard is set to “Best Score,”
    //   you can still submit the running total; Game Center will keep the best.
    // - If you prefer per-game scores, call this with a per-game value instead.
    func submitScore(_ value: Int, to leaderboardID: String = GameCenterManager.leaderboardID) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        GKLeaderboard.submitScore(value, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Game Center submit score error: \(error.localizedDescription)")
            } else {
                print("Game Center: Submitted score \(value) to leaderboard \(leaderboardID)")
            }
        }
    }
    
    /// Report a single fully-completed achievement by identifier.
    /// - Parameter id: The achievement identifier from App Store Connect.
    func reportAchievementFullyCompleted(id: String) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        let a = GKAchievement(identifier: id, player: GKLocalPlayer.local)
        a.percentComplete = 100
        a.showsCompletionBanner = true
        GKAchievement.report([a]) { error in
            if let error = error {
                print("Game Center achievements report error: \(error.localizedDescription)")
            } else {
                print("Game Center: Reported achievement id = \(id)")
            }
        }
    }

    // Report achievements based on the player’s current per-game score.
    // Why compute here instead of in views?
    // - Keeps achievement logic in one place and makes it easy to change thresholds.
    // - Views simply call updateAchievements(for:), staying UI-focused.
    func updateAchievements(for score: Int) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }

        var achievements: [GKAchievement] = []

        if score >= 1 {
            let a = GKAchievement(identifier: GameCenterManager.achievementFirstPointID, player: GKLocalPlayer.local)
            a.percentComplete = 100
            a.showsCompletionBanner = true
            achievements.append(a)
        }
        if score >= 10 {
            let a = GKAchievement(identifier: GameCenterManager.achievement10PointsID, player: GKLocalPlayer.local)
            a.percentComplete = 100
            a.showsCompletionBanner = true
            achievements.append(a)
        }
        if score >= 100 {
            let a = GKAchievement(identifier: GameCenterManager.achievement50PointsID, player: GKLocalPlayer.local)
            a.percentComplete = 100
            a.showsCompletionBanner = true
            achievements.append(a)
        }

        guard !achievements.isEmpty else { return }

        GKAchievement.report(achievements) { error in
            if let error = error {
                print("Game Center achievements report error: \(error.localizedDescription)")
            } else {
                print("Game Center: Reported achievements for score = \(score)")
            }
        }
    }

    // Present any UIKit controller from the top-most view controller.
    // Why not use a SwiftUI .sheet?
    // - This manager isn’t a View. Presenting here means we don’t need to thread presentation
    //   through the entire view hierarchy.
    // UIKit APIs are unavailable on macOS, so we provide two platform-specific implementations: UIKit for iOS and AppKit for macOS.
    #if os(iOS)
    private func present(_ viewController: UIViewController) {
        // UIKit presentation: find the top-most UIViewController and present modally.
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Game Center: Unable to find root view controller to present auth UI.")
            return
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(viewController, animated: true)
    }
    #elseif os(macOS)
    private func present(_ viewController: NSViewController) {
        // AppKit presentation: obtain the key NSWindow and present the controller as a sheet.
        // There is no UIKit on macOS, so we cannot call UIViewController.present(_:animated:).
        guard let window = NSApp.keyWindow,
              let contentVC = window.contentViewController else {
            print("Game Center: Unable to find key window to present auth/UI.")
            return
        }
        contentVC.presentAsSheet(viewController)
    }
    #endif

}


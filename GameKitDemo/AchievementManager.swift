//
//  Project: GameKitDemo
//  File: AchievementManager.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger

import Foundation

/// Centralizes achievement threshold evaluation.
/// - Keeps UI simple and testable.
/// - Reports via GameCenterManager.
final class AchievementManager {
    /// Track which achievements we've reported this run to avoid duplicate submissions.
    private var unlocked: Set<String> = []

    /// Evaluate the current count and report any newly completed achievements.
    /// - Parameter count: The user's current total count.
    func evaluate(count: Int) {
        // Thresholds: 1, 10, 100
        if count >= 1 {
            unlockIfNeeded(id: GameCenterManager.achievementFirstPointID)
        }
        if count >= 10 {
            unlockIfNeeded(id: GameCenterManager.achievement10PointsID)
        }
        // Reuse the existing 50PointsID slot for 100 until IDs are finalized.
        // TODO: Replace with a dedicated 100-points achievement identifier when available.
        if count >= 100 {
            unlockIfNeeded(id: GameCenterManager.achievement50PointsID)
        }
    }

    private func unlockIfNeeded(id: String) {
        guard !unlocked.contains(id) else { return }
        unlocked.insert(id)
        GameCenterManager.shared.reportAchievementFullyCompleted(id: id)
    }
}

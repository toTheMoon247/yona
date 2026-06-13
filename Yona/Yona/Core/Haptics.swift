//
//  Haptics.swift
//  Yona
//
//  Tiny wrapper for tactile feedback on key actions.
//

import UIKit

enum Haptics {
    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Custom view modifiers and extensions for the DockKit camera app.
*/

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Keep Screen Awake Modifier
struct KeepScreenAwake: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #elseif os(macOS)
                // Prevent sleep on macOS
                let activity = ProcessInfo.processInfo.beginActivity(
                    options: [.userInitiated, .idleSystemSleepDisabled, .idleDisplaySleepDisabled],
                    reason: "Keep screen awake for robot interaction"
                )
                // Store activity for cleanup if needed
                #endif
            }
            .onDisappear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
                // Note: ProcessInfo activity cleanup happens automatically
            }
    }
}

extension View {
    func keepScreenAwake() -> some View {
        modifier(KeepScreenAwake())
    }
}

// MARK: - Cross-Platform Audio Session Support
extension View {
    func configureAudioSession() -> some View {
        onAppear {
            #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to configure audio session: \(error)")
            }
            #endif
            // macOS doesn't require explicit audio session configuration
        }
    }
} 
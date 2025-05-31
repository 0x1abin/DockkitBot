/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A voice chat button component for real-time conversation with Xiaozhi voice service.
*/

import SwiftUI
import AVFoundation

/// A button component that handles voice conversation functionality
struct VoiceChatButton: View {
    
    // Voice client
    @State private var voiceClient: XiaozhiVoiceClient?
    @State private var isConnected = false
    @State private var isListening = false
    @State private var ttsState = "idle"
    @State private var connectionStatus = "disconnected"
    @State private var showButton = true
    
    // Keep strong reference to delegate wrapper
    @State private var delegateWrapper: VoiceClientDelegateWrapper?
    
    var body: some View {
        if showButton {
            voiceChatButton
        }
    }
    
    // MARK: - Voice Chat UI Components
    
    @ViewBuilder
    private var voiceChatButton: some View {
        ZStack {
            // Background circle with status-based color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            backgroundColors.primary,
                            backgroundColors.secondary
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(
                            borderColor,
                            lineWidth: 2
                        )
                )
            
            // Icon based on current state
            Image(systemName: currentIcon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(iconColor)
                .scaleEffect(isListening ? 1.1 : 1.0)
            
            // Status indicator ring
            if isConnected {
                Circle()
                    .stroke(statusRingColor, lineWidth: 3)
                    .frame(width: 85, height: 85)
                    .scaleEffect(isListening ? 1.0 : 0.9)
                    .opacity(isListening ? 0.8 : 0.4)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isListening)
            }
            
            // Connection status indicator
            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(connectionIndicatorColor)
                        .frame(width: 8, height: 8)
                    Spacer()
                }
            }
            .frame(width: 70, height: 70)
        }
        .scaleEffect(isListening ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isListening)
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 50, pressing: { pressing in
            if isConnected {
                if pressing {
                    startManualListening()
                } else {
                    stopManualListening()
                }
            }
        }, perform: {
            // Handle long press completion if needed
        })
        .onAppear {
            initializeVoiceClient()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Computed Properties for UI
    
    private var currentIcon: String {
        if !isConnected {
            return "wifi.slash"
        } else if ttsState == "start" || ttsState == "sentence_start" {
            return "speaker.wave.2.fill"
        } else if isListening {
            return "mic.fill"
        } else {
            return "message.circle"
        }
    }
    
    private var backgroundColors: (primary: Color, secondary: Color) {
        if !isConnected {
            return (.gray.opacity(0.3), .gray.opacity(0.1))
        } else if ttsState == "start" || ttsState == "sentence_start" {
            return (.blue.opacity(0.8), .blue.opacity(0.3))
        } else if isListening {
            return (.green.opacity(0.8), .green.opacity(0.3))
        } else {
            return (.white.opacity(0.1), .white.opacity(0.05))
        }
    }
    
    private var borderColor: Color {
        if !isConnected {
            return .gray.opacity(0.4)
        } else if ttsState == "start" || ttsState == "sentence_start" {
            return .blue.opacity(0.6)
        } else if isListening {
            return .green.opacity(0.6)
        } else {
            return .white.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        if !isConnected {
            return .gray
        } else {
            return .white
        }
    }
    
    private var statusRingColor: Color {
        if ttsState == "start" || ttsState == "sentence_start" {
            return .blue.opacity(0.7)
        } else if isListening {
            return .green.opacity(0.7)
        } else {
            return .white.opacity(0.3)
        }
    }
    
    private var connectionIndicatorColor: Color {
        switch connectionStatus {
        case "connected":
            return .green
        case "connecting":
            return .yellow
        default:
            return .red
        }
    }
    
    // MARK: - Voice Client Setup
    
    private func initializeVoiceClient() {
        voiceClient = XiaozhiVoiceClient()
        delegateWrapper = VoiceClientDelegateWrapper(button: self)
        voiceClient?.delegate = delegateWrapper
        
        print("✅ VoiceChatButton initialized")
    }
    
    private func cleanup() {
        voiceClient?.disconnect()
        voiceClient = nil
        delegateWrapper = nil
    }
    
    // MARK: - User Interactions
    
    private func handleTap() {
        if !isConnected {
            // Connect to voice service
            connectToVoiceService()
        } else if ttsState == "start" || ttsState == "sentence_start" {
            // Abort current TTS
            voiceClient?.abortCurrentTTS()
        } else {
            // Toggle auto listening (if in auto mode)
            // For now, just show connection status
            print("ℹ️ Voice chat connected. Long press to talk manually.")
        }
    }
    
    private func connectToVoiceService() {
        connectionStatus = "connecting"
        voiceClient?.connect()
        print("🔗 Connecting to Xiaozhi voice service...")
    }
    
    private func startManualListening() {
        guard isConnected && ttsState != "start" && ttsState != "sentence_start" else { return }
        
        print("🎤 Starting manual listening...")
        voiceClient?.startListening(mode: "manual")
    }
    
    private func stopManualListening() {
        guard isConnected && isListening else { return }
        
        print("⏹️ Stopping manual listening...")
        voiceClient?.stopListening()
    }
    
    // MARK: - Voice Client Delegate Callbacks
    
    internal func handleConnectionEstablished() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "connected"
            print("✅ Voice chat connected!")
        }
    }
    
    internal func handleConnectionLost(error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.isListening = false
            self.connectionStatus = "disconnected"
            self.ttsState = "idle"
            
            if let error = error {
                print("❌ Voice chat disconnected with error: \(error)")
            } else {
                print("🔌 Voice chat disconnected")
            }
        }
    }
    
    internal func handleTTSStateChange(_ state: String) {
        DispatchQueue.main.async {
            self.ttsState = state
            print("🔊 TTS state changed to: \(state)")
        }
    }
    
    internal func handleListeningStateChange(isListening: Bool) {
        DispatchQueue.main.async {
            self.isListening = isListening
        }
    }
    
    internal func handleMessageReceived(_ message: [String: Any]) {
        // Handle other message types if needed
        if let type = message["type"] as? String {
            print("📨 Received message type: \(type)")
        }
    }
}

// MARK: - Voice Client Delegate Wrapper

private class VoiceClientDelegateWrapper: XiaozhiVoiceClientDelegate {
    private let button: VoiceChatButton
    
    init(button: VoiceChatButton) {
        self.button = button
    }
    
    func voiceClientDidConnect(_ client: XiaozhiVoiceClient) {
        button.handleConnectionEstablished()
    }
    
    func voiceClientDidDisconnect(_ client: XiaozhiVoiceClient, error: Error?) {
        button.handleConnectionLost(error: error)
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveAudioData data: Data) {
        // Audio data is automatically played by the voice client
        print("🎵 Received \(data.count) bytes of audio data")
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didChangeTTSState state: String) {
        button.handleTTSStateChange(state)
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveMessage message: [String: Any]) {
        button.handleMessageReceived(message)
        
        // Update listening state based on listen messages
        if let type = message["type"] as? String,
           type == "listen",
           let state = message["state"] as? String {
            button.handleListeningStateChange(isListening: state == "start")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                VoiceChatButton()
                Spacer()
            }
            .padding(.bottom, 60)
            .padding(.leading, 30)
        }
    }
} 
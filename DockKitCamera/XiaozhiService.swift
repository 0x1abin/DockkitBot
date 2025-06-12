/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Xiaozhi voice service wrapper for managing voice client functionality.
*/

import Foundation
import SwiftUI

/// Xiaozhi voice service manager
@MainActor
@Observable
class XiaozhiService {
    
    // MARK: - Properties
    
    private var voiceClient: XiaozhiVoiceClient?
    private var delegateWrapper: ServiceDelegateWrapper?
    
    // Service state
    private(set) var isConnected = false
    private(set) var isListening = false
    private(set) var ttsState = "idle"
    private(set) var connectionStatus = "disconnected"
    
    // Callbacks
    var onEmotionReceived: ((RobotMood) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var onStateChanged: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        print("🎤 XiaozhiService initialized")
    }
    
    deinit {
        // Use Task to call MainActor isolated method
        Task { @MainActor in
            await self.cleanup()
        }
        print("🧹 XiaozhiService deinitialized")
    }
    
    // MARK: - Service Management
    
    /// Start the voice service in background
    func startService() async {
        guard voiceClient == nil else {
            print("⚠️ Voice service already running")
            return
        }
        
        print("🎤 Starting Xiaozhi voice service...")
        
        // Initialize voice client
        voiceClient = XiaozhiVoiceClient()
        delegateWrapper = ServiceDelegateWrapper(service: self)
        voiceClient?.delegate = delegateWrapper
        
        // Set to auto mode (background operation)
        voiceClient?.setManualMode(false)
        
        // Wait a moment for initialization
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Auto-connect to voice service
        await connect()
        
        print("✅ Xiaozhi voice service started successfully")
    }
    
    /// Stop the voice service
    func stopService() async {
        print("🛑 Stopping Xiaozhi voice service...")
        await cleanup()
        print("✅ Xiaozhi voice service stopped")
    }
    
    /// Connect to voice service
    private func connect() async {
        guard let voiceClient = voiceClient else { return }
        
        connectionStatus = "connecting"
        onConnectionChanged?(false)
        
        voiceClient.connect()
        print("🔗 Connecting to Xiaozhi voice service...")
    }
    
    /// Disconnect from voice service
    private func disconnect() async {
        voiceClient?.disconnect()
        updateConnectionState(false, status: "disconnected")
    }
    
    /// Cleanup resources
    private func cleanup() async {
        voiceClient?.disconnect()
        voiceClient = nil
        delegateWrapper = nil
        updateConnectionState(false, status: "disconnected")
    }
    
    // MARK: - State Management
    
    internal func updateConnectionState(_ connected: Bool, status: String) {
        isConnected = connected
        connectionStatus = status
        
        if !connected {
            isListening = false
            ttsState = "idle"
        }
        
        onConnectionChanged?(connected)
        onStateChanged?(status)
    }
    
    internal func updateListeningState(_ listening: Bool) {
        isListening = listening
        onStateChanged?(listening ? "listening" : "idle")
    }
    
    internal func updateTTSState(_ state: String) {
        ttsState = state
        onStateChanged?(state)
    }
    
    // MARK: - Voice Control (Optional Manual Controls)
    
    /// Start manual listening (if in manual mode)
    func startListening() {
        guard isConnected else {
            print("⚠️ Cannot start listening: not connected")
            return
        }
        
        voiceClient?.startListening(mode: "manual")
        print("🎤 Started manual listening")
    }
    
    /// Stop manual listening
    func stopListening() {
        guard isConnected else {
            print("⚠️ Cannot stop listening: not connected")
            return
        }
        
        voiceClient?.stopListening()
        print("⏹️ Stopped manual listening")
    }
    
    /// Abort current TTS playback
    func abortTTS() {
        guard isConnected else { return }
        
        voiceClient?.abortCurrentTTS()
        print("🛑 Aborted current TTS")
    }
    
    /// Switch between manual and auto mode
    func setManualMode(_ manual: Bool) {
        voiceClient?.setManualMode(manual)
        print("🔄 Switched to \(manual ? "manual" : "auto") mode")
    }
    
    // MARK: - Testing Methods
    
    /// Test emotion mapping with predefined emotions
    func testEmotion(_ emotion: String) {
        guard isConnected else {
            print("⚠️ Cannot test emotion: not connected")
            return
        }
        
        print("🧪 Testing emotion: \(emotion)")
        voiceClient?.simulateEmotionMessage(emotion)
    }
    
    /// Test with random emotion
    func testRandomEmotion() {
        let emotions = ["neutral", "happy", "sad", "angry", "surprised", "fear", "love", "excited", "curious", "sleepy"]
        let randomEmotion = emotions.randomElement() ?? "neutral"
        testEmotion(randomEmotion)
    }
}

// MARK: - Service Delegate Wrapper

private class ServiceDelegateWrapper: XiaozhiVoiceClientDelegate {
    private weak var service: XiaozhiService?
    
    init(service: XiaozhiService) {
        self.service = service
    }
    
    func voiceClientDidConnect(_ client: XiaozhiVoiceClient) {
        print("✅ Background voice client connected successfully!")
        
        Task { @MainActor in
            self.service?.updateConnectionState(true, status: "connected")
        }
    }
    
    func voiceClientDidDisconnect(_ client: XiaozhiVoiceClient, error: Error?) {
        if let error = error {
            print("❌ Background voice client disconnected with error: \(error)")
        } else {
            print("🔌 Background voice client disconnected")
        }
        
        Task { @MainActor in
            self.service?.updateConnectionState(false, status: "disconnected")
        }
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveAudioData data: Data) {
        // Audio data is automatically played by the voice client
        // print("🎵 Background received \(data.count) bytes of audio data")
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didChangeTTSState state: String) {
        print("🔊 Background TTS state changed to: \(state)")
        
        Task { @MainActor in
            self.service?.updateTTSState(state)
        }
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveMessage message: [String: Any]) {
        if let type = message["type"] as? String {
            print("📨 Background received message type: \(type)")
        }
        
        // Update listening state based on listen messages
        if let type = message["type"] as? String,
           type == "listen",
           let state = message["state"] as? String {
            
            Task { @MainActor in
                self.service?.updateListeningState(state == "start")
            }
        }
    }
    
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveEmotion emotion: String) {
        // 将emotion映射到RobotMood并触发回调
        let robotMood = XiaozhiVoiceClient.mapEmotionToRobotMood(emotion)
        print("🎭 Background converting emotion '\(emotion)' to RobotMood: \(robotMood)")
        
        Task { @MainActor in
            self.service?.onEmotionReceived?(robotMood)
        }
    }
}

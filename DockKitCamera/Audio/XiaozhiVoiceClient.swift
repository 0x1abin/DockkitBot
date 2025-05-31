/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Xiaozhi voice client for real-time voice conversation functionality.
*/

import Foundation
import Network
import AVFoundation

// MARK: - Message Types

struct HelloMessage: Codable {
    let type: String
    let version: Int
    let transport: String
    let audio_params: AudioParams
    
    struct AudioParams: Codable {
        let format: String
        let sample_rate: Int
        let channels: Int
        let frame_duration: Int
    }
}

struct ListenMessage: Codable {
    let session_id: String
    let type: String
    let state: String
    let mode: String?
}

struct TTSMessage: Codable {
    let type: String
    let state: String
    let session_id: String?
}

struct SessionMessage: Codable {
    let type: String
    let session_id: String
    let state: String?
}

// MARK: - Delegate Protocol

public protocol XiaozhiVoiceClientDelegate: AnyObject {
    func voiceClientDidConnect(_ client: XiaozhiVoiceClient)
    func voiceClientDidDisconnect(_ client: XiaozhiVoiceClient, error: Error?)
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveAudioData data: Data)
    func voiceClient(_ client: XiaozhiVoiceClient, didChangeTTSState state: String)
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveMessage message: [String: Any])
    func voiceClient(_ client: XiaozhiVoiceClient, didReceiveEmotion emotion: String)
}

// MARK: - Xiaozhi Voice Client

public class XiaozhiVoiceClient: NSObject {
    
    // MARK: - Properties
    
    public weak var delegate: XiaozhiVoiceClientDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    private var isConnected = false
    private var sessionId: String?
    private var listenState: String = "stop"
    private var ttsState: String = "idle"
    private var isManualMode = false // 默认自动模式，与Python版本一致
    
    // Audio components
    private var opusRecorderPlayer: OpusRecorderPlayer?
    private var audioDelegate: VoiceAudioDelegate?
    
    // Configuration
    private let wsURL = "wss://api.tenclass.net/xiaozhi/v1/"
    private let accessToken = "test-token"
    private let deviceMac = "72:23:42:24:52:65"
    private let deviceUUID = "19324-uuid"
    
    // Audio parameters
    private let sampleRate: Int32 = 24000
    private let channels: Int32 = 1
    private let frameDuration: Int32 = 100 // ms
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        setupURLSession()
        setupAudioComponents()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    private func setupAudioComponents() {
        do {
            opusRecorderPlayer = try OpusRecorderPlayer(
                sampleRate: sampleRate,
                channels: channels,
                durationMs: frameDuration,
                application: .voip
            )
            
            audioDelegate = VoiceAudioDelegate(voiceClient: self)
            opusRecorderPlayer?.delegate = audioDelegate
            
            print("✅ Xiaozhi voice client audio components initialized")
        } catch {
            print("❌ Failed to initialize audio components: \(error)")
        }
    }
    
    // MARK: - Connection Management
    
    public func connect() {
        guard !isConnected else { return }
        
        var request = URLRequest(url: URL(string: wsURL)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "Protocol-Version")
        request.setValue(deviceMac, forHTTPHeaderField: "Device-Id")
        request.setValue(deviceUUID, forHTTPHeaderField: "Client-Id")
        
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        startReceiving()
        
        print("🔗 Connecting to Xiaozhi voice service...")
    }
    
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        listenState = "stop"
        
        opusRecorderPlayer?.stopRecording()
        opusRecorderPlayer?.stopPlaying()
        
        print("🔌 Disconnected from Xiaozhi voice service")
    }
    
    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.startReceiving() // Continue receiving
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleDisconnection(error: error)
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleAudioMessage(data)
        @unknown default:
            print("⚠️ Unknown message type received")
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("❌ Failed to parse text message: \(text)")
            return
        }
        
        print("📨 Received message: \(json)")
        
        switch type {
        case "hello":
            handleHelloMessage(json)
        case "tts":
            handleTTSMessage(json)
        case "goodbye":
            handleGoodbyeMessage(json)
        default:
            print("ℹ️ Unhandled message type: \(type)")
        }
        
        // 检查是否包含emotion字段
        if let emotion = json["emotion"] as? String {
            handleEmotionMessage(emotion, sessionId: json["session_id"] as? String)
        }
        
        DispatchQueue.main.async {
            self.delegate?.voiceClient(self, didReceiveMessage: json)
        }
    }
    
    private func handleAudioMessage(_ data: Data) {
        print("🎵 Received audio data: \(data.count) bytes")
        
        // Play received audio
        if opusRecorderPlayer?.isPlaying == true {
            opusRecorderPlayer?.playOpusData(data)
        } else {
            opusRecorderPlayer?.startPlaying()
            opusRecorderPlayer?.playOpusData(data)
        }
        
        DispatchQueue.main.async {
            self.delegate?.voiceClient(self, didReceiveAudioData: data)
        }
    }
    
    private func handleHelloMessage(_ json: [String: Any]) {
        if let sessionId = json["session_id"] as? String {
            self.sessionId = sessionId
            isConnected = true
            
            print("✅ Connected with session ID: \(sessionId)")
            
            DispatchQueue.main.async {
                self.delegate?.voiceClientDidConnect(self)
            }
            
            // Start auto listening if not in manual mode
            if !isManualMode {
                startListening(mode: "auto")
            }
        }
    }
    
    private func handleTTSMessage(_ json: [String: Any]) {
        if let state = json["state"] as? String {
            ttsState = state
            
            DispatchQueue.main.async {
                self.delegate?.voiceClient(self, didChangeTTSState: state)
            }
            
            // After TTS stops, restart auto listening if not in manual mode
            if state == "stop" && !isManualMode {
                startListening(mode: "auto")
            }
        }
    }
    
    private func handleGoodbyeMessage(_ json: [String: Any]) {
        if let receivedSessionId = json["session_id"] as? String,
           receivedSessionId == sessionId {
            print("👋 Received goodbye message")
            sessionId = nil
        }
    }
    
    private func handleEmotionMessage(_ emotion: String, sessionId: String?) {
        print("🎭 Received emotion: \(emotion) for session: \(sessionId ?? "unknown")")
        
        DispatchQueue.main.async {
            self.delegate?.voiceClient(self, didReceiveEmotion: emotion)
        }
    }
    
    private func handleDisconnection(error: Error?) {
        isConnected = false
        listenState = "stop"
        
        opusRecorderPlayer?.stopRecording()
        opusRecorderPlayer?.stopPlaying()
        
        DispatchQueue.main.async {
            self.delegate?.voiceClientDidDisconnect(self, error: error)
        }
    }
    
    // MARK: - Voice Control
    
    public func startListening(mode: String = "manual") {
        guard isConnected, let sessionId = sessionId else {
            print("⚠️ Cannot start listening: not connected or no session")
            return
        }
        
        let message = ListenMessage(
            session_id: sessionId,
            type: "listen",
            state: "start",
            mode: mode
        )
        
        sendJSONMessage(message)
        listenState = "start"
        
        // Start recording
        opusRecorderPlayer?.startRecording()
        
        print("🎤 Started listening in \(mode) mode")
    }
    
    public func stopListening() {
        guard isConnected, let sessionId = sessionId else {
            print("⚠️ Cannot stop listening: not connected or no session")
            return
        }
        
        let message = ListenMessage(
            session_id: sessionId,
            type: "listen",
            state: "stop",
            mode: nil
        )
        
        sendJSONMessage(message)
        listenState = "stop"
        
        // Stop recording
        opusRecorderPlayer?.stopRecording()
        
        print("⏹️ Stopped listening")
    }
    
    public func abortCurrentTTS() {
        guard isConnected else { return }
        
        let message = ["type": "abort"]
        sendJSONMessage(message)
        
        print("🛑 Sent abort message")
    }
    
    // MARK: - Message Sending
    
    private func sendJSONMessage<T: Codable>(_ message: T) {
        do {
            let data = try JSONEncoder().encode(message)
            let messageTask = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)
            
            webSocketTask?.send(messageTask) { error in
                if let error = error {
                    print("❌ Failed to send message: \(error)")
                } else {
                    print("📤 Sent message: \(message)")
                }
            }
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    private func sendJSONMessage(_ message: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let messageTask = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)
            
            webSocketTask?.send(messageTask) { error in
                if let error = error {
                    print("❌ Failed to send message: \(error)")
                } else {
                    print("📤 Sent message: \(message)")
                }
            }
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    private func sendHelloMessage() {
        let audioParams = HelloMessage.AudioParams(
            format: "opus",
            sample_rate: Int(sampleRate),
            channels: Int(channels),
            frame_duration: Int(frameDuration)
        )
        
        let message = HelloMessage(
            type: "hello",
            version: 1,
            transport: "websocket",
            audio_params: audioParams
        )
        
        sendJSONMessage(message)
    }
    
    public func sendAudioData(_ data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("❌ Failed to send audio data: \(error)")
            }
        }
    }
    
    // MARK: - Properties Access
    
    public var isClientConnected: Bool { isConnected }
    public var currentSessionId: String? { sessionId }
    public var currentListenState: String { listenState }
    public var currentTTSState: String { ttsState }
    public var isInManualMode: Bool { isManualMode }
    
    // Switch between manual and auto mode
    public func setManualMode(_ manual: Bool) {
        isManualMode = manual
        print("🔄 Switched to \(manual ? "manual" : "auto") mode")
        
        // If switching to auto mode and connected, start listening
        if !manual && isConnected && listenState == "stop" && ttsState == "stop" {
            startListening(mode: "auto")
        }
        // If switching to manual mode, stop current listening
        else if manual && isConnected && listenState == "start" {
            stopListening()
        }
    }
    
    // MARK: - Emotion Mapping
    
    /// 将emotion字符串映射到RobotMood
    internal static func mapEmotionToRobotMood(_ emotion: String) -> RobotMood {
        switch emotion.lowercased() {
        case "happy", "happiness", "joy", "joyful":
            return .happy
        case "sad", "sadness", "sorrow":
            return .sad
        case "angry", "anger", "mad":
            return .anger
        case "surprised", "surprise", "astonished":
            return .surprise
        case "fear", "afraid", "scared", "fearful":
            return .fear
        case "disgust", "disgusted", "revulsion":
            return .disgust
        case "excited", "excitement", "thrilled":
            return .excited
        case "love", "loving", "affection", "romantic":
            return .love
        case "curious", "curiosity", "interested":
            return .curiosity
        case "sleepy", "tired", "drowsy", "fatigue":
            return .sleepy
        case "pride", "proud", "accomplished":
            return .pride
        case "shame", "ashamed", "embarrassed":
            return .shame
        case "guilt", "guilty", "regret":
            return .guilt
        case "trust", "trusting", "confident":
            return .trust
        case "acceptance", "accepting", "peaceful":
            return .acceptance
        case "contempt", "disdain", "scorn":
            return .contempt
        case "envy", "envious", "jealous":
            return .envy
        case "anticipation", "anticipating", "expectant":
            return .anticipation
        case "neutral", "normal", "calm", "default":
            return .normal
        default:
            print("⚠️ Unknown emotion '\(emotion)', defaulting to normal")
            return .normal
        }
    }
    
    // MARK: - Testing Methods
    
    /// 测试emotion映射功能
    internal func testEmotionMapping() {
        let testEmotions = ["neutral", "happy", "sad", "angry", "surprised", "fear", "love", "excited"]
        
        print("🧪 Testing emotion mapping:")
        for emotion in testEmotions {
            let mood = XiaozhiVoiceClient.mapEmotionToRobotMood(emotion)
            print("  '\(emotion)' -> \(mood)")
        }
    }
    
    /// 模拟接收emotion消息（用于测试）
    internal func simulateEmotionMessage(_ emotion: String) {
        let testMessage: [String: Any] = [
            "type": "llm",
            "text": "😶",
            "emotion": emotion,
            "session_id": sessionId ?? "test-session"
        ]
        
        print("🎭 Simulating emotion message: \(testMessage)")
        handleEmotionMessage(emotion, sessionId: sessionId)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension XiaozhiVoiceClient: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🌐 WebSocket opened")
        sendHelloMessage()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket closed with code: \(closeCode)")
        handleDisconnection(error: nil)
    }
}

// MARK: - Voice Audio Delegate

private class VoiceAudioDelegate: OpusAudioStreamDelegate {
    weak var voiceClient: XiaozhiVoiceClient?
    
    init(voiceClient: XiaozhiVoiceClient) {
        self.voiceClient = voiceClient
    }
    
    func didReceiveEncodedAudio(_ data: Data, timestamp: TimeInterval) {
        // Send encoded audio to server
        voiceClient?.sendAudioData(data)
    }
    
    func didReceiveDecodedAudio(_ buffer: AVAudioPCMBuffer, timestamp: TimeInterval) {
        // Not used in this implementation
    }
    
    func didEncounterError(_ error: Error) {
        print("❌ Voice audio error: \(error)")
    }
} 
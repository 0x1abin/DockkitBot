/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Opus audio recorder and player with real-time encoding/decoding.
*/

import AVFoundation
import Foundation

// Import Opus types from OpusAudioCoder
// Note: These types are defined in OpusAudioCoder.swift in the same module

// MARK: - Audio Stream Delegate

public protocol OpusAudioStreamDelegate {
    func didReceiveEncodedAudio(_ data: Data, timestamp: TimeInterval)
    func didReceiveDecodedAudio(_ buffer: AVAudioPCMBuffer, timestamp: TimeInterval)
    func didEncounterError(_ error: Error)
}

// MARK: - Opus Recorder Player

public class OpusRecorderPlayer {
    
    // MARK: - Properties
    
    // Audio configuration parameters
    private let sampleRate: Int32
    private let channels: Int32
    private let durationMs: Int32
    private let application: OpusApplication
    private let frameSize: Int32
    
    // Audio formats
    private let recordingFormat: AVAudioFormat
    private let playbackFormat: AVAudioFormat
    
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var playerNode: AVAudioPlayerNode
    private var encoder: OpusEncoder?
    private var decoder: OpusDecoder?
    
    public var delegate: OpusAudioStreamDelegate?
    
    private var isRecording = false
    public var isPlaying = false
    private var recordingStartTime: TimeInterval = 0
    
    // MARK: - Initialization
    
    public init(sampleRate: Int32 = 24000, channels: Int32 = 1, durationMs: Int32 = 100, application: OpusApplication = .voip) throws {
        self.sampleRate = sampleRate
        self.channels = channels
        self.durationMs = durationMs
        self.application = application
        self.frameSize = (sampleRate * durationMs) / 1000
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        self.playerNode = AVAudioPlayerNode()
        
        // Initialize audio formats
        recordingFormat = AVAudioFormat(
            standardFormatWithSampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels)
        )!
        
        playbackFormat = AVAudioFormat(
            standardFormatWithSampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels)
        )!
        
        try setupAudioSession()
        try setupAudioEngine()
        try initializeCodecs()
    }
    
    private func setupAudioSession() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        #else
        // macOS doesn't need audio session setup
        print("✅ Audio session setup completed (macOS)")
        #endif
    }
    
    private func setupAudioEngine() throws {
        // Add player node to engine
        audioEngine.attach(playerNode)
        
        // Create playback format matching our configuration
        let playbackFormat = AVAudioFormat(
            standardFormatWithSampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels)
        )!
        
        // Connect player node to output with correct format
        audioEngine.connect(playerNode, to: audioEngine.outputNode, format: playbackFormat)
        
        // Get the hardware format from input node
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        print("🎤 Hardware input format: \(hardwareFormat)")
        print("🎯 Target recording format: \(recordingFormat)")
        print("🔊 Playback format: \(playbackFormat)")
        
        // Calculate buffer size for frame duration
        let bufferSize = AVAudioFrameCount(frameSize)
        
        // Install recording tap using hardware format
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: hardwareFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            let timestamp = TimeInterval(when.sampleTime) / hardwareFormat.sampleRate
            self.processRecordedAudio(buffer, hardwareFormat: hardwareFormat, timestamp: timestamp)
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func initializeCodecs() throws {
        encoder = try OpusEncoder(sampleRate: sampleRate, channels: channels, durationMs: durationMs, application: application)
        decoder = try OpusDecoder(sampleRate: sampleRate, channels: channels, durationMs: durationMs)
    }
    
    // MARK: - Recording Control
    
    public func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingStartTime = Date().timeIntervalSince1970
        
        print("🎤 Started Opus recording")
    }
    
    public func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        print("⏹️ Stopped Opus recording")
    }
    
    private func processRecordedAudio(_ buffer: AVAudioPCMBuffer, hardwareFormat: AVAudioFormat, timestamp: TimeInterval) {
        guard isRecording, let encoder = encoder else { return }
        
        do {
            // Convert hardware format to target recording format if needed
            let convertedBuffer: AVAudioPCMBuffer
            if hardwareFormat.sampleRate != recordingFormat.sampleRate {
                convertedBuffer = try convertAudioFormat(buffer: buffer, from: hardwareFormat, to: recordingFormat)
            } else {
                convertedBuffer = buffer
            }
            
            let opusData = try encoder.encode(convertedBuffer)
            let adjustedTimestamp = timestamp - recordingStartTime
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveEncodedAudio(opusData, timestamp: adjustedTimestamp)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.delegate?.didEncounterError(error)
            }
        }
    }
    
    private func convertAudioFormat(buffer: AVAudioPCMBuffer, from sourceFormat: AVAudioFormat, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw OpusError.audioEngineError(NSError(domain: "OpusRecorderPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"]))
        }
        
        // Calculate the output buffer size based on sample rate ratio
        let sampleRateRatio = targetFormat.sampleRate / sourceFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * sampleRateRatio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            throw OpusError.audioEngineError(NSError(domain: "OpusRecorderPlayer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"]))
        }
        
        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            throw OpusError.audioEngineError(error)
        }
        
        return outputBuffer
    }
    
    // MARK: - Playback Control
    
    public func startPlaying() {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        // Ensure audio engine is running before starting playback
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                print("🔄 Restarted audio engine for playback")
            } catch {
                print("❌ Failed to restart audio engine: \(error)")
                return
            }
        }
        
        playerNode.play()
        
        print("🔊 Started Opus playback from main controller (engine running: \(audioEngine.isRunning))")
    }
    
    public func stopPlaying() {
        guard isPlaying else { return }
        
        isPlaying = false
        playerNode.stop()
        
        print("⏹️ Stopped Opus playback from main controller")
    }
    
    public func playOpusData(_ opusData: Data) {
        guard let decoder = decoder, isPlaying else { 
            print("⚠️ Cannot play opus data: decoder=\(decoder != nil), isPlaying=\(isPlaying)")
            return 
        }
        
        do {
            let pcmBuffer: AVAudioPCMBuffer = try decoder.decode(opusData)
            
            print("✅ Decoded \(opusData.count) bytes to \(pcmBuffer.frameLength) samples")
            
            // Schedule the buffer for playback
            playerNode.scheduleBuffer(pcmBuffer) {
                print("🎵 Finished playing buffer")
            }
            
        } catch {
            print("❌ Failed to decode and play opus data: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopRecording()
        stopPlaying()
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        inputNode.removeTap(onBus: 0)
    }
}

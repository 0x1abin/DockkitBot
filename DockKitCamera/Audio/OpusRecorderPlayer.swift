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
    
    // Audio enhancement properties
    private var audioUnitEQ: AVAudioUnitEQ?
    private var audioMixer: AVAudioMixerNode?
    private let volumeBoost: Float = 2.0  // Amplify volume by 2x
    
    // MARK: - Initialization
    
    public init(sampleRate: Int32 = 24000, channels: Int32 = 1, durationMs: Int32 = 60, application: OpusApplication = .voip) throws {
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
        
        // Configure audio session for optimal recording quality
        try audioSession.setCategory(.playAndRecord, 
                                   mode: .videoRecording,  // Better for recording quality
                                   options: [.defaultToSpeaker, 
                                            .allowBluetooth,
                                            .allowBluetoothA2DP])
        
        // Set preferred sample rate and buffer duration for better quality
        try audioSession.setPreferredSampleRate(Double(sampleRate))
        try audioSession.setPreferredIOBufferDuration(Double(durationMs) / 1000.0)
        
        // Enable audio input gain control if available
        if audioSession.isInputGainSettable {
            // Set input gain to maximum for louder recording
            try audioSession.setInputGain(1.0) // Range: 0.0 to 1.0
            print("🎚️ Input gain set to maximum: \(audioSession.inputGain)")
        } else {
            print("⚠️ Input gain is not settable on this device")
        }
        
        // Activate the audio session
        try audioSession.setActive(true)
        
        print("✅ Audio session configured for optimal recording quality")
        print("📊 Sample rate: \(audioSession.sampleRate) Hz")
        print("🎤 Input channels: \(audioSession.inputNumberOfChannels)")
        print("🔊 Output channels: \(audioSession.outputNumberOfChannels)")
        
        #else
        // macOS doesn't need audio session setup
        print("✅ Audio session setup completed (macOS)")
        #endif
    }
    
    private func setupAudioEngine() throws {
        // Add audio enhancement nodes
        audioMixer = AVAudioMixerNode()
        audioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
        
        // Configure EQ for voice enhancement
        if let eq = audioUnitEQ {
            eq.bands[0].frequency = 1000.0  // Focus on speech frequencies
            eq.bands[0].gain = 8.0          // Boost by 6dB
            eq.bands[0].bandwidth = 0.5
            eq.bands[0].filterType = .parametric
        }
        
        // Add nodes to engine
        if let mixer = audioMixer {
            audioEngine.attach(mixer)
        }
        if let eq = audioUnitEQ {
            audioEngine.attach(eq)
        }
        audioEngine.attach(playerNode)
        
        // Create playback format matching our configuration
        let playbackFormat = AVAudioFormat(
            standardFormatWithSampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels)
        )!
        
        // Connect audio processing chain: mixer -> EQ -> output
        if let mixer = audioMixer, let eq = audioUnitEQ {
            audioEngine.connect(mixer, to: eq, format: playbackFormat)
            audioEngine.connect(eq, to: audioEngine.outputNode, format: playbackFormat)
            
            // Set volume boost on mixer
            mixer.outputVolume = volumeBoost
        }
        
        // Connect player node to mixer (for enhanced playback)
        if let mixer = audioMixer {
            audioEngine.connect(playerNode, to: mixer, format: playbackFormat)
        } else {
            // Fallback to direct connection
            audioEngine.connect(playerNode, to: audioEngine.outputNode, format: playbackFormat)
        }
        
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
        
        print("🎚️ Audio enhancement enabled: Volume boost = \(volumeBoost)x, EQ = \(audioUnitEQ?.bands[0].gain ?? 0)dB")
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
            var convertedBuffer: AVAudioPCMBuffer
            if hardwareFormat.sampleRate != recordingFormat.sampleRate {
                convertedBuffer = try convertAudioFormat(buffer: buffer, from: hardwareFormat, to: recordingFormat)
            } else {
                convertedBuffer = buffer
            }
            
            // Apply volume amplification for clearer audio
            amplifyAudioBuffer(&convertedBuffer, amplificationFactor: volumeBoost)
            
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
    
    // MARK: - Audio Enhancement Methods
    
    private func amplifyAudioBuffer(_ buffer: inout AVAudioPCMBuffer, amplificationFactor: Float) {
        guard let floatChannelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        for channel in 0..<channelCount {
            let channelData = floatChannelData[channel]
            
            for frame in 0..<frameLength {
                // Apply amplification with soft limiting to prevent clipping
                var sample = channelData[frame] * amplificationFactor
                
                // Soft limiting to prevent harsh clipping
                if sample > 0.95 {
                    sample = 0.95 + (sample - 0.95) * 0.1
                } else if sample < -0.95 {
                    sample = -0.95 + (sample + 0.95) * 0.1
                }
                
                channelData[frame] = sample
            }
        }
        
        print("🔊 Applied \(amplificationFactor)x volume amplification to audio buffer")
    }
    
    // MARK: - Audio Enhancement Control
    
    /// Adjust the volume amplification factor (1.0 = normal, 2.0 = double volume)
    public func setVolumeAmplification(_ factor: Float) {
        guard factor >= 0.1 && factor <= 5.0 else {
            print("⚠️ Volume amplification factor should be between 0.1 and 5.0")
            return
        }
        
        // Update mixer volume if available
        audioMixer?.outputVolume = factor
        print("🎚️ Volume amplification set to \(factor)x")
    }
    
    /// Adjust EQ gain for voice enhancement (-12dB to +12dB)
    public func setVoiceEnhancement(_ gainDb: Float) {
        guard gainDb >= -12.0 && gainDb <= 12.0 else {
            print("⚠️ EQ gain should be between -12dB and +12dB")
            return
        }
        
        audioUnitEQ?.bands[0].gain = gainDb
        print("🎵 Voice enhancement EQ set to \(gainDb)dB")
    }
    
    /// Get current audio levels and quality metrics
    public func getAudioMetrics() -> (inputGain: Float, outputVolume: Float, eqGain: Float) {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        let inputGain = audioSession.inputGain
        #else
        let inputGain: Float = 1.0
        #endif
        
        let outputVolume = audioMixer?.outputVolume ?? 1.0
        let eqGain = audioUnitEQ?.bands[0].gain ?? 0.0
        
        return (inputGain: inputGain, outputVolume: outputVolume, eqGain: eqGain)
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
            
            // print("✅ Decoded \(opusData.count) bytes to \(pcmBuffer.frameLength) samples")
            
            // Schedule the buffer for playback
            playerNode.scheduleBuffer(pcmBuffer) {
                // print("🎵 Finished playing buffer")
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

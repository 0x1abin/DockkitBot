/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Opus audio codec wrapper for encoding and decoding audio streams.
*/

import opus.opus
import AVFoundation
import Foundation

// MARK: - Opus Application Types

/// Opus application type optimizations
public enum OpusApplication: Int32, CaseIterable {
    /// Best for most VoIP/videoconference applications where listening quality and intelligibility matter most
    case voip = 2048  // OPUS_APPLICATION_VOIP
    
    /// Best for broadcast/high-fidelity application where the decoded audio should be as close as possible to the input
    case audio = 2049  // OPUS_APPLICATION_AUDIO
    
    /// Only use when lowest-achievable latency is what matters most. Voice-optimized modes cannot be used
    case restrictedLowDelay = 2051  // OPUS_APPLICATION_RESTRICTED_LOWDELAY
    
    /// Human-readable description of the application type
    public var description: String {
        switch self {
        case .voip:
            return "VoIP/Videoconference (optimized for voice clarity)"
        case .audio:
            return "High-Fidelity Audio (optimized for music/broadcast)"
        case .restrictedLowDelay:
            return "Restricted Low Delay (optimized for minimal latency)"
        }
    }
    
    /// Default application type for voice recording
    public static let `default`: OpusApplication = .voip
}

// MARK: - Quality Metrics

public struct AudioQualityMetrics {
    let signalToNoise: Double
    let bitrate: Int32
    let packetLoss: Double
    let latency: TimeInterval
}

// MARK: - Opus Encoder

public class OpusEncoder {
    private var encoder: OpaquePointer?
    private let sampleRate: Int32
    private let channels: Int32
    private let durationMs: Int32
    private let frameSize: Int32
    private var encodeBuffer: [UInt8]
    
    public init(sampleRate: Int32, channels: Int32 = 1, durationMs: Int32 = 60, application: OpusApplication = .voip) throws {
        self.sampleRate = sampleRate
        self.channels = channels
        self.durationMs = durationMs
        self.frameSize = (sampleRate * durationMs) / 1000
        self.encodeBuffer = [UInt8](repeating: 0, count: 4000) // Max packet size
        
        var error: Int32 = 0
        encoder = opus_encoder_create(
            sampleRate,
            channels,
            application.rawValue,
            &error
        )
        
        guard error == OPUS_OK, encoder != nil else {
            let errorMsg = String(cString: opus_strerror(error))
            throw OpusError.encoderCreationFailed(error, errorMsg)
        }
        
        print("✅ Opus encoder created successfully")
        print("🔧 Encoder config: sampleRate=\(sampleRate), channels=\(channels), frameSize=\(frameSize) (\(durationMs)ms)")
        print("🔧 Application type: \(application.description)")
        print("🔧 Using Opus default bitrate (auto-managed)")
    }
    
    deinit {
        if let encoder = encoder {
            opus_encoder_destroy(encoder)
        }
    }
    
    public func encode(_ pcmBuffer: AVAudioPCMBuffer) throws -> Data {
        guard let encoder = encoder else {
            throw OpusError.encoderNotInitialized
        }
        
        guard let floatChannelData = pcmBuffer.floatChannelData else {
            throw OpusError.invalidInputData
        }
        
        let frameCount = Int32(pcmBuffer.frameLength)
        let result = opus_encode_float(
            encoder,
            floatChannelData[0],
            frameCount,
            &encodeBuffer,
            Int32(encodeBuffer.count)
        )
        
        guard result > 0 else {
            let errorMsg = String(cString: opus_strerror(result))
            throw OpusError.encodingFailed(result, errorMsg)
        }
        
        return Data(encodeBuffer.prefix(Int(result)))
    }
    
    public func encode(_ pcmData: [Float]) throws -> Data {
        guard let encoder = encoder else {
            throw OpusError.encoderNotInitialized
        }
        
        let result = pcmData.withUnsafeBufferPointer { pcmPointer in
            opus_encode_float(
                encoder,
                pcmPointer.baseAddress!,
                frameSize,
                &encodeBuffer,
                Int32(encodeBuffer.count)
            )
        }
        
        guard result > 0 else {
            let errorMsg = String(cString: opus_strerror(result))
            throw OpusError.encodingFailed(result, errorMsg)
        }
        
        return Data(encodeBuffer.prefix(Int(result)))
    }
}

// MARK: - Opus Decoder

public class OpusDecoder {
    private var decoder: OpaquePointer?
    private let sampleRate: Int32
    private let channels: Int32
    private let durationMs: Int32
    private let frameSize: Int32
    private var decodeBuffer: [Float]
    
    public init(sampleRate: Int32, channels: Int32 = 1, durationMs: Int32 = 60) throws {
        self.sampleRate = sampleRate
        self.channels = channels
        self.durationMs = durationMs
        self.frameSize = (sampleRate * durationMs) / 1000
        // Increase buffer size to support larger frames (up to 120ms at 48kHz)
        self.decodeBuffer = [Float](repeating: 0, count: 5760) // 48000 * 0.12 = 5760 samples max
        
        var error: Int32 = 0
        decoder = opus_decoder_create(
            sampleRate,
            channels,
            &error
        )
        
        guard error == OPUS_OK, decoder != nil else {
            let errorMsg = String(cString: opus_strerror(error))
            throw OpusError.decoderCreationFailed(error, errorMsg)
        }
        
        print("✅ Opus decoder created successfully")
        print("🔧 Decoder config: sampleRate=\(sampleRate), channels=\(channels), frameSize=\(frameSize) (\(durationMs)ms)")
        print("🔧 Decode buffer size: \(decodeBuffer.count) samples")
    }
    
    deinit {
        if let decoder = decoder {
            opus_decoder_destroy(decoder)
        }
    }
    
    public func decode(_ opusData: Data) throws -> AVAudioPCMBuffer {
        guard !opusData.isEmpty else {
            throw OpusError.invalidInputData
        }
        
        guard let decoder = decoder else {
            throw OpusError.decoderNotInitialized
        }
        
        print("🔍 Decoding opus data: \(opusData.count) bytes, max frame size: \(decodeBuffer.count)")
        
        // Clear decode buffer before use
        decodeBuffer.withUnsafeMutableBufferPointer { buffer in
            buffer.initialize(repeating: 0)
        }
        
        // Capture values outside of closures to avoid concurrent access
        let maxSamplesPerChannel = Int32(decodeBuffer.count / Int(channels))
        
        let result = opusData.withUnsafeBytes { bytes in
            decodeBuffer.withUnsafeMutableBufferPointer { decodePointer in
                opus_decode_float(
                    decoder,
                    bytes.bindMemory(to: UInt8.self).baseAddress,
                    Int32(opusData.count),
                    decodePointer.baseAddress!,
                    maxSamplesPerChannel,
                    0  // decode_fec = 0
                )
            }
        }
        
        print("📊 Decode result: \(result) samples")
        
        guard result > 0 else {
            let errorMsg = String(cString: opus_strerror(result))
            print("❌ Decode failed with code: \(result) - \(errorMsg)")
            throw OpusError.decodingFailed(result, errorMsg)
        }
        
        // Create output buffer with actual decoded sample count
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Double(sampleRate),
            channels: AVAudioChannelCount(channels)
        )!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(result)) else {
            throw OpusError.invalidInputData
        }
        
        // Set actual frame length
        buffer.frameLength = AVAudioFrameCount(result)
        
        // Copy decoded data to buffer
        if let floatChannelData = buffer.floatChannelData {
            floatChannelData[0].update(from: decodeBuffer, count: Int(result))
        }
        
        print("✅ Successfully decoded \(result) samples")
        return buffer
    }
    
    public func decodeToFloatArray(_ opusData: Data) throws -> [Float] {
        guard let decoder = decoder else {
            throw OpusError.decoderNotInitialized
        }
        
        // Clear decode buffer before use
        decodeBuffer.withUnsafeMutableBufferPointer { buffer in
            buffer.initialize(repeating: 0)
        }
        
        // Capture values outside of closures to avoid concurrent access
        let maxSamplesPerChannel = Int32(decodeBuffer.count / Int(channels))
        
        let result = opusData.withUnsafeBytes { bytes in
            decodeBuffer.withUnsafeMutableBufferPointer { decodePointer in
                opus_decode_float(
                    decoder,
                    bytes.bindMemory(to: UInt8.self).baseAddress,
                    Int32(opusData.count),
                    decodePointer.baseAddress!,
                    maxSamplesPerChannel,
                    0
                )
            }
        }
        
        guard result > 0 else {
            let errorMsg = String(cString: opus_strerror(result))
            throw OpusError.decodingFailed(result, errorMsg)
        }
        
        return Array(decodeBuffer.prefix(Int(result)))
    }
}

// MARK: - Error Types

public enum OpusError: Error, LocalizedError {
    case encoderCreationFailed(Int32, String)
    case decoderCreationFailed(Int32, String)
    case encoderNotInitialized
    case decoderNotInitialized
    case encodingFailed(Int32, String)
    case decodingFailed(Int32, String)
    case invalidInputData
    case audioEngineError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .encoderCreationFailed(let code, let message):
            return "Failed to create Opus encoder: \(code) - \(message)"
        case .decoderCreationFailed(let code, let message):
            return "Failed to create Opus decoder: \(code) - \(message)"
        case .encoderNotInitialized:
            return "Opus encoder not initialized"
        case .decoderNotInitialized:
            return "Opus decoder not initialized"
        case .encodingFailed(let code, let message):
            return "Opus encoding failed: \(code) - \(message)"
        case .decodingFailed(let code, let message):
            return "Opus decoding failed: \(code) - \(message)"
        case .invalidInputData:
            return "Invalid input data for encoding"
        case .audioEngineError(let error):
            return "Audio engine error: \(error.localizedDescription)"
        }
    }
}

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Opus audio codec wrapper for encoding and decoding audio streams.
*/

import opus.opus
import AVFoundation
import Foundation

// MARK: - Configuration

public enum OpusConfiguration {
    case voiceChat
    case highQualityAudio
    case lowLatency
    case custom(sampleRate: Int32, frameSize: Int32, bitrate: Int32)
    
    var sampleRate: Int32 {
        switch self {
        case .voiceChat: return 16000
        case .highQualityAudio: return 48000
        case .lowLatency: return 24000
        case .custom(let sampleRate, _, _): return sampleRate
        }
    }
    
    var channels: Int32 {
        return 1 // Mono for voice recording
    }
    
    var application: Int32 {
        switch self {
        case .voiceChat: return OPUS_APPLICATION_VOIP
        case .highQualityAudio: return OPUS_APPLICATION_AUDIO
        case .lowLatency: return OPUS_APPLICATION_RESTRICTED_LOWDELAY
        case .custom: return OPUS_APPLICATION_VOIP
        }
    }
    
    var frameSize: Int32 {
        switch self {
        case .voiceChat: return sampleRate / 50 // 20ms frames
        case .highQualityAudio: return sampleRate / 25 // 40ms frames
        case .lowLatency: return sampleRate / 100 // 10ms frames
        case .custom(_, let frameSize, _): return frameSize
        }
    }
    
    var bitrate: Int32 {
        switch self {
        case .voiceChat: return 32000 // 32kbps
        case .highQualityAudio: return 128000 // 128kbps
        case .lowLatency: return 64000 // 64kbps
        case .custom(_, _, let bitrate): return bitrate
        }
    }
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
    private let configuration: OpusConfiguration
    private var encodeBuffer: [UInt8]
    
    public init(configuration: OpusConfiguration) throws {
        self.configuration = configuration
        self.encodeBuffer = [UInt8](repeating: 0, count: 4000) // Max packet size
        
        var error: Int32 = 0
        encoder = opus_encoder_create(
            configuration.sampleRate,
            configuration.channels,
            configuration.application,
            &error
        )
        
        guard error == OPUS_OK, encoder != nil else {
            let errorMsg = String(cString: opus_strerror(error))
            throw OpusError.encoderCreationFailed(error, errorMsg)
        }
        
        // Note: opus_encoder_ctl is a variadic function unavailable in Swift
        // Bitrate control will use default settings
        
        print("✅ Opus encoder created successfully")
        print("🔧 Encoder config: sampleRate=\(configuration.sampleRate), channels=\(configuration.channels), frameSize=\(configuration.frameSize)")
        print("⚠️ Using default bitrate (opus_encoder_ctl unavailable in Swift)")
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
        
        let frameSize = configuration.frameSize
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
    private let configuration: OpusConfiguration
    private var decodeBuffer: [Float]
    
    public init(configuration: OpusConfiguration) throws {
        self.configuration = configuration
        // Increase buffer size to support larger frames (up to 120ms at 48kHz)
        self.decodeBuffer = [Float](repeating: 0, count: 5760) // 48000 * 0.12 = 5760 samples max
        
        var error: Int32 = 0
        decoder = opus_decoder_create(
            configuration.sampleRate,
            configuration.channels,
            &error
        )
        
        guard error == OPUS_OK, decoder != nil else {
            let errorMsg = String(cString: opus_strerror(error))
            throw OpusError.decoderCreationFailed(error, errorMsg)
        }
        
        print("✅ Opus decoder created successfully")
        print("🔧 Decoder config: sampleRate=\(configuration.sampleRate), channels=\(configuration.channels), frameSize=\(configuration.frameSize)")
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
        let maxSamplesPerChannel = Int32(decodeBuffer.count / Int(configuration.channels))
        
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
            standardFormatWithSampleRate: Double(configuration.sampleRate),
            channels: AVAudioChannelCount(configuration.channels)
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
        let maxSamplesPerChannel = Int32(decodeBuffer.count / Int(configuration.channels))
        
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

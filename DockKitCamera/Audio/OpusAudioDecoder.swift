/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Opus audio decoder for voice chat functionality.
*/

import Foundation
import AVFoundation

/// Opus audio decoder for decompressing voice data
class OpusAudioDecoder {
    
    // MARK: - Configuration
    private let sampleRate: Int = 16000
    private let channels: Int = 1
    private let frameDuration: Int = 60 // milliseconds
    private let frameSize: Int
    
    // MARK: - Initialization
    
    init() {
        // Calculate frame size based on sample rate and duration
        self.frameSize = (sampleRate * frameDuration) / 1000
        
        print("OpusAudioDecoder: Setting up decoder")
        print("OpusAudioDecoder: Sample rate: \(sampleRate)Hz, Channels: \(channels), Frame duration: \(frameDuration)ms")
        print("OpusAudioDecoder: Frame size: \(frameSize) samples")
    }
    
    // MARK: - Public Methods
    
    /// Decode Opus audio data to PCM format
    /// - Parameter opusData: Opus encoded audio data
    /// - Returns: PCM audio data (Int16), or nil if decoding fails
    func decode(_ opusData: Data) -> Data? {
        // TODO: Implement real Opus decoding
        // For now, provide a placeholder that simulates decompression
        
        let originalSize = opusData.count
        
        // Simulate Opus decompression (reverse of 50% compression)
        let decompressedSize = originalSize * 2
        var decompressedData = Data(capacity: decompressedSize)
        
        // Process the compressed data and "decompress" it
        opusData.withUnsafeBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            
            for sample in samples {
                // Add the original sample
                withUnsafeBytes(of: sample.littleEndian) { sampleBytes in
                    decompressedData.append(contentsOf: sampleBytes)
                }
                
                // Add an interpolated sample (simple duplication for placeholder)
                withUnsafeBytes(of: sample.littleEndian) { sampleBytes in
                    decompressedData.append(contentsOf: sampleBytes)
                }
            }
        }
        
        print("OpusAudioDecoder: Placeholder decompression: \(originalSize) -> \(decompressedData.count) bytes")
        
        return decompressedData
    }
    
    /// Decode Opus data and convert to the specified audio format
    /// - Parameters:
    ///   - opusData: Opus encoded audio data
    ///   - outputFormat: Target audio format
    /// - Returns: Audio buffer in the specified format, or nil if conversion fails
    func decode(_ opusData: Data, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let pcmData = decode(opusData) else {
            return nil
        }
        
        // Convert PCM data to audio buffer
        return createAudioBuffer(from: pcmData, format: outputFormat)
    }
    
    // MARK: - Private Methods
    
    private func createAudioBuffer(from pcmData: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let bytesPerSample = MemoryLayout<Int16>.size
        let frameCount = pcmData.count / (Int(format.channelCount) * bytesPerSample)
        
        guard frameCount > 0 else {
            print("OpusAudioDecoder: Invalid frame count: \(frameCount)")
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            print("OpusAudioDecoder: Failed to create PCM buffer")
            return nil
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Convert PCM data to the buffer format
        if format.commonFormat == .pcmFormatFloat32 {
            // Convert Int16 to Float32
            pcmData.withUnsafeBytes { rawBytes in
                guard let int16Ptr = rawBytes.bindMemory(to: Int16.self).baseAddress else {
                    return
                }
                
                for channel in 0..<Int(format.channelCount) {
                    guard let channelData = buffer.floatChannelData?[channel] else {
                        continue
                    }
                    
                    for frame in 0..<frameCount {
                        let sampleIndex = frame * Int(format.channelCount) + channel
                        if sampleIndex < rawBytes.count / bytesPerSample {
                            let int16Value = int16Ptr[sampleIndex]
                            channelData[frame] = Float(int16Value) / Float(Int16.max)
                        }
                    }
                }
            }
        } else if format.commonFormat == .pcmFormatInt16 {
            // Direct copy for Int16 format
            pcmData.withUnsafeBytes { rawBytes in
                guard let int16Ptr = rawBytes.bindMemory(to: Int16.self).baseAddress,
                      let bufferPtr = buffer.int16ChannelData?[0] else {
                    return
                }
                
                bufferPtr.update(from: int16Ptr, count: frameCount * Int(format.channelCount))
            }
        }
        
        return buffer
    }
} 
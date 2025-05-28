/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Opus audio encoder for voice chat functionality.
*/

import Foundation
import AVFoundation

/// Opus audio encoder for compressing voice data
class OpusAudioEncoder {
    
    // MARK: - Configuration
    private let sampleRate: Int = 16000
    private let channels: Int = 1
    private let frameDuration: Int = 60 // milliseconds
    private let frameSize: Int
    private let bitrate: Int = 16000
    
    // MARK: - Initialization
    
    init() {
        // Calculate frame size based on sample rate and duration
        self.frameSize = (sampleRate * frameDuration) / 1000
        
        print("OpusAudioEncoder: Setting up encoder")
        print("OpusAudioEncoder: Sample rate: \(sampleRate)Hz, Channels: \(channels), Frame duration: \(frameDuration)ms")
        print("OpusAudioEncoder: Frame size: \(frameSize) samples, Bitrate: \(bitrate)bps")
    }
    
    // MARK: - Public Methods
    
    /// Encode PCM audio data to Opus format
    /// - Parameter pcmData: Raw PCM audio data (Int16)
    /// - Returns: Opus encoded data, or nil if encoding fails
    func encode(_ pcmData: Data) -> Data? {
        // TODO: Implement real Opus encoding
        // For now, provide a placeholder that simulates compression
        
        let originalSize = pcmData.count
        
        // Safety check for empty data
        guard originalSize > 0 else {
            print("OpusAudioEncoder: Warning - Empty PCM data provided")
            return nil
        }
        
        // Safety check for minimum data size (must be even number of bytes for Int16)
        guard originalSize >= 2 && originalSize % 2 == 0 else {
            print("OpusAudioEncoder: Warning - Invalid data size: \(originalSize) bytes (must be even)")
            return nil
        }
        
        print("OpusAudioEncoder: Processing \(originalSize) bytes of PCM data")
        
        // Use safe data processing without subdata
        let compressedData = compressDataSafely(pcmData)
        
        print("OpusAudioEncoder: ✅ Safe compression: \(originalSize) -> \(compressedData.count) bytes")
        return compressedData
    }
    
    /// Safely compress PCM data without using subdata operations
    private func compressDataSafely(_ pcmData: Data) -> Data {
        var compressedData = Data()
        
        // Process data using byte array access instead of subdata
        pcmData.withUnsafeBytes { bytes in
            guard let int16Ptr = bytes.bindMemory(to: Int16.self).baseAddress else {
                print("OpusAudioEncoder: Failed to bind memory to Int16")
                return
            }
            
            let sampleCount = bytes.count / MemoryLayout<Int16>.size
            print("OpusAudioEncoder: Processing \(sampleCount) samples")
            
            // Compress by taking every other sample (50% compression)
            for i in stride(from: 0, to: sampleCount, by: 2) {
                if i < sampleCount {
                    let sample = int16Ptr[i]
                    withUnsafeBytes(of: sample.littleEndian) { sampleBytes in
                        compressedData.append(contentsOf: sampleBytes)
                    }
                }
            }
        }
        
        return compressedData
    }
    
    // MARK: - Private Methods
} 
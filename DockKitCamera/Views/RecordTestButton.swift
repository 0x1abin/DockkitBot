/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A recording test button component for audio recording and playback functionality.
*/

import SwiftUI
import AVFoundation

/// A button component that handles audio recording and playback testing
struct RecordTestButton: View {
    
    // Recording functionality
    @State private var opusRecorderPlayer: OpusRecorderPlayer?
    @State private var isRecording = false
    @State private var recordedAudioData: [Data] = []
    @State private var showButton = true
    @State private var audioDelegate: AudioDelegateWrapper?
    
    var body: some View {
        if showButton {
            recordingButton
        }
    }
    
    // MARK: - Recording UI Components
    
    @ViewBuilder
    private var recordingButton: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            isRecording ? Color.red.opacity(0.8) : Color.white.opacity(0.1),
                            isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(
                            isRecording ? Color.red.opacity(0.6) : Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                )
            
            // Microphone icon
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isRecording ? .white : .white.opacity(0.7))
                .scaleEffect(isRecording ? 1.1 : 1.0)
            
            // Recording animation pulse
            if isRecording {
                Circle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? 1.0 : 0.8)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRecording)
            }
        }
        .scaleEffect(isRecording ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 50, pressing: { pressing in
            if pressing {
                // Start recording when press begins
                startRecording()
            } else {
                // Stop recording and start playback when press ends
                stopRecordingAndStartPlayback()
            }
        }, perform: {
            // This is called when the long press completes, but we handle everything in the pressing closure
        })
        .onAppear {
            initializeAudioComponents()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Audio Setup
    
    private func initializeAudioComponents() {
        do {
            opusRecorderPlayer = try OpusRecorderPlayer()
            setupAudioDelegate()
            print("✅ OpusRecorderPlayer initialized successfully in RecordTestButton")
        } catch {
            print("❌ Failed to initialize OpusRecorderPlayer: \(error)")
            showButton = false // Hide button if initialization fails
        }
    }
    
    private func setupAudioDelegate() {
        let delegate = AudioDelegateWrapper()
        delegate.onAudioDataReceived = { [weak delegate] data in
            DispatchQueue.main.async {
                // Store the audio data - we'll access it from the delegate wrapper
                delegate?.audioData.append(data)
            }
        }
        opusRecorderPlayer?.delegate = delegate
        
        // Store reference to access the audio data later
        audioDelegate = delegate
    }
    
    private func cleanup() {
        opusRecorderPlayer?.stopRecording()
        opusRecorderPlayer?.stopPlaying()
        opusRecorderPlayer = nil
        audioDelegate = nil
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() {
        print("🎤 Starting recording...")
        // Clear both local and delegate audio data
        recordedAudioData.removeAll()
        audioDelegate?.audioData.removeAll()
        isRecording = true
        
        // Start recording
        opusRecorderPlayer?.startRecording()
    }
    
    private func stopRecordingAndStartPlayback() {
        print("🎤 Stopping recording and starting playback...")
        isRecording = false
        
        // Stop recording
        opusRecorderPlayer?.stopRecording()
        
        // Copy audio data from delegate
        recordedAudioData = audioDelegate?.audioData ?? []
        
        // Start playback after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startPlayback()
        }
    }
    
    private func startPlayback() {
        guard !recordedAudioData.isEmpty else {
            print("⚠️ No recorded audio data to play")
            return
        }
        
        print("🔊 Starting playback of \(recordedAudioData.count) audio chunks...")
        
        // Start playing
        opusRecorderPlayer?.startPlaying()
        
        // Schedule audio data with proper spacing to avoid buffer conflicts
        scheduleAudioPlayback()
    }
    
    private func scheduleAudioPlayback() {
        for (index, audioData) in recordedAudioData.enumerated() {
            // Schedule each audio chunk with a small delay to ensure proper queuing
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) { // 50ms spacing
                self.opusRecorderPlayer?.playOpusData(audioData)
            }
        }
        
        // Stop playing after all chunks are scheduled plus playback time
        let schedulingTime = Double(recordedAudioData.count) * 0.05 // Time to schedule all chunks
        let playbackTime = Double(recordedAudioData.count) * 0.06 // 60ms per frame
        let bufferTime: TimeInterval = 0.5 // Extra buffer
        let totalTime = schedulingTime + playbackTime + bufferTime
        
        print("🕐 Scheduling \(recordedAudioData.count) chunks over \(schedulingTime)s, total duration: \(totalTime)s")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalTime) {
            self.opusRecorderPlayer?.stopPlaying()
            print("🎵 Finished playing all audio chunks")
        }
    }
    
    // MARK: - Audio Delegate Implementation
    
    private class AudioDelegateWrapper: ObservableObject, OpusAudioStreamDelegate {
        @Published var audioData: [Data] = []
        var onAudioDataReceived: ((Data) -> Void)?
        
        func didReceiveEncodedAudio(_ data: Data, timestamp: TimeInterval) {
            onAudioDataReceived?(data)
        }
        
        func didReceiveDecodedAudio(_ buffer: AVAudioPCMBuffer, timestamp: TimeInterval) {
            // Not used in this implementation
        }
        
        func didEncounterError(_ error: Error) {
            print("❌ Audio error: \(error)")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                RecordTestButton()
                Spacer()
            }
            .padding(.bottom, 60)
            .padding(.leading, 30)
        }
    }
}

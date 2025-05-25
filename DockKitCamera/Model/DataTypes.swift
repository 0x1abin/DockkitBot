/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Supporting data types for the robot face tracking app.
*/

import AVFoundation
import SwiftUI

// MARK: - Camera supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    /// The initial status on creation.
    case unknown
    /// A status that indicates a person disallows access to the camera.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
}

/// An enumeration that defines the activity states the capture service supports.
///
/// This type provides feedback to the UI regarding the active status of the `CaptureService` actor.
enum CaptureActivity {
    case idle
    /// A status that indicates the capture service is active (for face detection).
    case active
    
    var currentTime: TimeInterval {
        return .zero
    }
    
    var isRecording: Bool {
        return false
    }
}

enum CameraOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case unknown
    
    init(videoRotationAngle: CGFloat, front: Bool) {
        self = CameraOrientation.unknown
        if front {
            // The landscape-left orientation.
            if videoRotationAngle == 0.0 {
                self = CameraOrientation.landscapeLeft
            // The portrait orientation.
            } else if videoRotationAngle == 90.0 {
                self = CameraOrientation.portrait
            // The landscape-right orientation.
            } else if videoRotationAngle == 180.0 {
                self = CameraOrientation.landscapeRight
            // The portrait upside-down orientation.
            } else if videoRotationAngle == 270.0 {
                self = CameraOrientation.portraitUpsideDown
            }
        } else {
            // The landscape-right orientation.
            if videoRotationAngle == 0.0 {
                self = CameraOrientation.landscapeRight
            // The portrait orientation.
            } else if videoRotationAngle == 90.0 {
                self = CameraOrientation.portrait
            // The landscape-left orientation.
            } else if videoRotationAngle == 180.0 {
                self = CameraOrientation.landscapeLeft
            // The portrait upside-down orientation.
            } else if videoRotationAngle == 270.0 {
                self = CameraOrientation.portraitUpsideDown
            }
        }
    }
}

/// An enumeration that describes the zoom type - zoom in or zoom out.
enum CameraZoomType {
    case increase
    case decrease
}

// MARK: - DockKit supporting types

/// An enumeration that describes the current status of the DockKit accessory.
enum DockAccessoryStatus {
    /// A status that indicates the DockKit accessory is disconnected.
    case disconnected
    /// A status that indicates the DockKit accessory is connected.
    case connected
    /// A status that indicates the DockKit accessory is connected and tracking.
    case connectedTracking
}

/// An enumeration that describes the current battery status of the DockKit accessory.
enum DockAccessoryBatteryStatus {
    /// A status that indicates the battery status is unavailable.
    case unavailable
    /// A status that indicates the battery status is available.
    case available(percentage: Double = 0.0, charging: Bool = false)
    
    var percentage: Double {
        if case .available(let percentage, _) = self {
            return percentage
        }
        return 0.0
    }

    var charging: Bool {
        if case .available(_, let charging) = self {
            return charging
        }
        return false
    }
}

enum FramingMode: String, CaseIterable, Identifiable {
    case auto = "Frame Auto"
    case center = "Frame Center"
    case left = "Frame Left"
    case right = "Frame Right"
    public var id: Self { self }
    
    func symbol() -> some View {
        switch self {
        case .auto:
            return Image(systemName: "sparkles")
        case .center:
            return Image(systemName: "person.crop.rectangle")
        case .left:
            return Image(systemName: "inset.filled.rectangle.and.person.filled")
        case .right:
            return Image(systemName: "inset.filled.rectangle.and.person.filled")
        }
    }
}

enum TrackingMode: String, CaseIterable, Identifiable {
    case system = "System Tracking"
    case custom = "Custom Tracking"
    case manual = "Manual Control"
    public var id: Self { self }
}

enum Animation: String, CaseIterable, Identifiable {
    case yes
    case nope
    case wakeup
    case kapow
    public var id: Self { self }
}

// MARK: - Robot Face supporting types

@Observable
/// An object that stores the robot face state and eye positions.
class RobotFaceState {
    var leftEyePosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var rightEyePosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var isBlinking: Bool = false
    var mood: RobotMood = .normal
    var isTracking: Bool = false
    var isManualMoodMode: Bool = false  // 手动表情模式标志
    
    init() {}
}

enum RobotMood: String, CaseIterable, Identifiable {
    // 基础情绪
    case normal = "normal"
    case happy = "happy"
    case sad = "sad"
    case excited = "excited"
    case sleepy = "sleepy"
    
    // 八大基础情绪 (Plutchik's Wheel)
    case anger = "anger"         // 愤怒
    case disgust = "disgust"     // 嫌恶
    case fear = "fear"           // 恐惧
    case surprise = "surprise"   // 惊喜
    case trust = "trust"         // 信任
    case anticipation = "anticipation" // 期待
    case joy = "joy"             // 欢愉
    case sadness = "sadness"     // 悲伤
    
    // 复合情绪
    case curiosity = "curiosity" // 好奇
    case acceptance = "acceptance" // 接纳
    case contempt = "contempt"   // 蔑视
    case pride = "pride"         // 骄傲
    case shame = "shame"         // 羞耻
    case love = "love"           // 爱
    case guilt = "guilt"         // 内疚
    case envy = "envy"           // 嫉妒
    
    public var id: Self { self }
}

extension RobotMood {
    /// Display name for the mood
    var displayName: String {
        switch self {
        case .normal: return "正常"
        case .happy: return "开心"
        case .sad: return "伤心"
        case .excited: return "兴奋"
        case .sleepy: return "困倦"
        case .anger: return "愤怒"
        case .disgust: return "嫌恶"
        case .fear: return "恐惧"
        case .surprise: return "惊喜"
        case .trust: return "信任"
        case .anticipation: return "期待"
        case .joy: return "欢愉"
        case .sadness: return "悲伤"
        case .curiosity: return "好奇"
        case .acceptance: return "接纳"
        case .contempt: return "蔑视"
        case .pride: return "骄傲"
        case .shame: return "羞耻"
        case .love: return "爱"
        case .guilt: return "内疚"
        case .envy: return "嫉妒"
        }
    }
    
    /// Color associated with the mood
    var color: Color {
        switch self {
        case .normal: return .white
        case .happy: return .yellow
        case .sad: return .blue
        case .excited: return .orange
        case .sleepy: return .purple
        case .anger: return .red
        case .disgust: return .green
        case .fear: return .gray
        case .surprise: return .cyan
        case .trust: return .mint
        case .anticipation: return .pink
        case .joy: return .yellow
        case .sadness: return .indigo
        case .curiosity: return .teal
        case .acceptance: return .green
        case .contempt: return .brown
        case .pride: return .orange
        case .shame: return .gray
        case .love: return .pink
        case .guilt: return .purple
        case .envy: return .green
        }
    }
}

// MARK: - DockKit data structures

/// A structure that represents a tracked person from DockKit.
struct DockAccessoryTrackedPerson {
    let saliency: Int
    var rect: CGRect
    let speaking: Double?
    let looking: Double?
}

/// A structure that represents the features available on a DockKit accessory.
struct DockAccessoryFeatures {
    var isSetROIEnabled = false
    var isTapToTrackEnabled = false
    var isTrackingSummaryEnabled = false
    var trackingMode: TrackingMode = .system
    var framingMode: FramingMode = .auto
}

// MARK: - Camera errors

/// An enumeration that describes errors that can occur during camera operations.
enum CameraError: Error {
    case setupFailed
    case addInputFailed
    case addOutputFailed
    case videoDeviceUnavailable
}

/// An enumeration that describes the chevron types for manual control.
enum ChevronType {
    case up
    case down
    case left
    case right
    case tiltUp
    case tiltDown
    case panLeft
    case panRight
}

// MARK: - Protocols

/// A protocol to perform DockKit-related functions.
protocol DockAccessoryTrackingDelegate: AnyObject {
    func track(metadata: [AVMetadataObject], sampleBuffer: CMSampleBuffer?,
               deviceType: AVCaptureDevice.DeviceType, devicePosition: AVCaptureDevice.Position)
}

/// A protocol to perform capture-related functions.
protocol CameraCaptureDelegate: AnyObject {
    func startOrStartCapture()
    func switchCamera()
    func zoom(type: CameraZoomType, factor: Double)
    func convertToViewSpace(from rect: CGRect) async -> CGRect
}

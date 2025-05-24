/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that provides the interface to the features of the connected DockKit accessory.
*/

import SwiftUI
import Combine
import AVFoundation
import os

#if canImport(DockKit)
import DockKit
#endif

/// An object that provides the interface to the features of the connected DockKit accessory.
///
/// This object provides the default implementation of the `DockAccessory` protocol, which defines the interface
/// to configure the connected DockKit accessory and control it. `DockAccessoryModel` doesn't control the DockKit accessory by itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `DockControlService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewDockAccessoryModel` instead.
///
@Observable
final class DockControllerModel: DockController {
    
    /// The current status of the DockKit accessory.
    private(set) var status: DockAccessoryStatus = .disconnected
    
    /// The current battery status of the DockKit accessory.
    private(set) var battery: DockAccessoryBatteryStatus = .unavailable
    
    /// The currently tracked people.
    var trackedPersons: [DockAccessoryTrackedPerson] = []
    
    private(set) var regionOfInterest: CGRect = CGRect.zero
    
    /// The `dockAccessory` features that a person can enable in the user interface.
    private(set) var dockAccessoryFeatures = DockAccessoryFeatures()
    
    /// The robot face state for robot face mode.
    private(set) var robotFaceState = RobotFaceState()
    
    /// Flag to indicate if the app is in robot face mode.
    private(set) var isRobotFaceMode = false
    
    /// An object that manages the app's DockKit functionality.
    private let dockControlService = DockControlService()
    
    init() {
        start()
    }
    
    func start() {
        Task {
            await dockControlService.setUp(features: dockAccessoryFeatures)
        }
        // Observe states for UI updates.
        observeState()
    }
    
    // MARK: - DockKit tracking
    
    func updateFraming(to framing: FramingMode) async -> Bool {
        return await dockControlService.updateFraming(to: framing)
    }
    
    func updateTrackingMode(to trackingMode: TrackingMode) async -> Bool {
        return await dockControlService.updateTrackingMode(to: trackingMode)
    }
    
    /// Toggle robot face mode on/off.
    func toggleRobotFaceMode() async {
        isRobotFaceMode.toggle()
        
        if isRobotFaceMode {
            robotFaceState.isTracking = true
            // Switch to front camera for robot face mode
            if let cameraDelegate = await dockControlService.cameraCaptureDelegate as? CameraModel {
                await cameraDelegate.selectCamera(position: .front)
            }
        } else {
            robotFaceState.isTracking = false
            robotFaceState.mood = .normal
            // Return eyes to center when exiting robot face mode
            robotFaceState.leftEyePosition = CGPoint(x: 0.5, y: 0.5)
            robotFaceState.rightEyePosition = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    func selectSubject(at point: CGPoint?, override: Bool = false) async -> Bool {
        if dockAccessoryFeatures.isTapToTrackEnabled == false && !override {
            logger.error("Enable tap to track from DockKit menu to select subject.")
            return false
        }
        return await dockControlService.selectSubject(at: point)
    }
    
    func setRegionOfInterest(to region: CGRect, override: Bool = false) async -> Bool {
        if dockAccessoryFeatures.isSetROIEnabled == false && !override {
            logger.error("Enable set Region of Interest(ROI) from DockKit menu to set ROI")
            return false
        }
        return await dockControlService.setRegionOfInterest(to: region)
    }
    
    func animate(_ animation: Animation) async -> Bool {
        return await dockControlService.animate(animation)
    }
    
    func handleChevronTapped(chevronType: ChevronType, speed: Double?) async {
        if let speed = speed {
            return await dockControlService.handleChevronTapped(chevronType: chevronType, speed: speed)
        }
        
        return await dockControlService.handleChevronTapped(chevronType: chevronType)
    }
    
    func toggleTrackingSummary(to enable: Bool) async {
        await dockControlService.toggleTrackingSummary(to: enable)
    }
    
    func toggleBatterySummary(to enable: Bool) async {
        await dockControlService.toggleBatterySummary(to: enable)
    }
    
    // MARK: - Internal state observations
    // Set up the DockKit state observations.
    private func observeState() {
        
        observeAccessoryConnectionState()
        observeBatteryState()
        observeRegionOfInterestUpdate()
        observeTrackedPersonsState()
    }
    
    private func observeAccessoryConnectionState() {
        Task {
            // Await new status values from the dock controller service.
            for await statusUpdate in await dockControlService.$status.values {
                // Forward the activity to the UI.
                status = statusUpdate
            }
        }
    }
    
    private func observeBatteryState() {
        Task {
            // Await new battery values from the dock controller service.
            for await batteryUpdate in await dockControlService.$battery.values {
                // Forward the activity to the UI.
                battery = batteryUpdate
            }
        }
    }
    
    private func observeRegionOfInterestUpdate() {
        Task {
            for await regionOfInterestUpdate in await dockControlService.$regionOfInterest.values {
                regionOfInterest = regionOfInterestUpdate
            }
        }
    }
    
    private func observeTrackedPersonsState() {
        Task {
            for await trackedPersonsUpdate in await dockControlService.$trackedPersons.values {
                for person in trackedPersonsUpdate {
#if canImport(UIKit)
                    let orientation = UIDevice.current.orientation
                    if orientation == .landscapeLeft || orientation == .landscapeRight {
                        person.rect = CGRect(x: person.rect.origin.x,
                                             y: person.rect.origin.y,
                                             width: person.rect.height,
                                             height: person.rect.width)
                    }
#endif
                }
                
                trackedPersons = trackedPersonsUpdate
                
                // Update robot face eye positions when in robot face mode
                if isRobotFaceMode {
                    updateRobotEyePositions(with: trackedPersonsUpdate)
                }
            }
        }
    }
    
    // MARK: - Robot Face Mode
    
    /// Update robot eye positions based on tracked persons.
    private func updateRobotEyePositions(with trackedPersons: [DockAccessoryTrackedPerson]) {
        if let primaryPerson = trackedPersons.first {
            robotFaceState.isTracking = true
            
            // Calculate eye positions based on face center
            let faceCenter = CGPoint(
                x: primaryPerson.rect.midX,
                y: primaryPerson.rect.midY
            )
            
            // 修复坐标映射 - 确保眼睛跟随方向正确
            // 注意：faceCenter坐标系原点在左上角，值域[0,1]
            // 眼睛坐标系中 (0.5, 0.5) 是中心位置
            
            // X轴：直接使用人脸的X坐标（不反转）
            // 当人脸在屏幕左侧时，眼睛应该看左边
            // 当人脸在屏幕右侧时，眼睛应该看右边
            let rawEyeX = faceCenter.x
            
            // Y轴：反转Y坐标以获得自然的跟随效果
            // 当人脸在屏幕上方时(faceCenter.y < 0.5)，眼睛应该看上方(eyeY < 0.5)
            // 当人脸在屏幕下方时(faceCenter.y > 0.5)，眼睛应该看下方(eyeY > 0.5)
            // 由于原始坐标系可能不符合这个预期，我们反转Y轴
            let rawEyeY = 1.0 - faceCenter.y
            
            // 应用合理的范围约束
            let constrainedX = max(0.1, min(0.9, rawEyeX))
            let constrainedY = max(0.2, min(0.8, rawEyeY))
            
            withAnimation(.easeOut(duration: 0.2)) {
                robotFaceState.leftEyePosition = CGPoint(x: constrainedX, y: constrainedY)
                robotFaceState.rightEyePosition = CGPoint(x: constrainedX, y: constrainedY)
            }
            
            // 仅在非手动模式下才自动更改表情
            if !robotFaceState.isManualMoodMode {
                // Update mood based on tracking confidence
                if let looking = primaryPerson.looking {
                    if looking > 0.8 {
                        robotFaceState.mood = .happy
                    } else if looking > 0.5 {
                        robotFaceState.mood = .normal
                    } else {
                        robotFaceState.mood = .sad
                    }
                }
            }
        } else {
            robotFaceState.isTracking = false
            
            // 仅在非手动模式下才自动设置为困倦表情
            if !robotFaceState.isManualMoodMode {
                robotFaceState.mood = .sleepy
            }
            
            // Return eyes to center when no face is detected
            withAnimation(.easeOut(duration: 0.3)) {
                robotFaceState.leftEyePosition = CGPoint(x: 0.5, y: 0.5)
                robotFaceState.rightEyePosition = CGPoint(x: 0.5, y: 0.5)
            }
        }
    }
    
    // MARK: - Camera-capture delegate
    /// Set the camera-capture delegate.
    func setCameraCaptureServiceDelegate(_ delegate: CameraCaptureDelegate) async {
        await dockControlService.setCameraCaptureServiceDelegate(delegate)
    }
}

extension DockControllerModel: DockAccessoryTrackingDelegate {
    func track(metadata: [AVMetadataObject], sampleBuffer: CMSampleBuffer?,
               deviceType: AVCaptureDevice.DeviceType, devicePosition: AVCaptureDevice.Position) {
        // Handle robot face mode - directly process face detection for eye tracking
        if isRobotFaceMode {
            processFaceDetectionForRobotMode(metadata: metadata)
            return
        }
        
        guard dockAccessoryFeatures.trackingMode == .custom else {
            return
        }
        
        guard let sampleBuffer = sampleBuffer else {
            return
        }
        
        Task {
            await dockControlService.track(metadata: metadata, sampleBuffer: sampleBuffer,
                                           deviceType: deviceType, devicePosition: devicePosition)
        }
    }
    
    /// Process face detection metadata for robot face mode.
    private func processFaceDetectionForRobotMode(metadata: [AVMetadataObject]) {
        // Create mock tracked persons from face detection for robot eye tracking
        var mockTrackedPersons: [DockAccessoryTrackedPerson] = []
        
        for object in metadata {
            if let faceObject = object as? AVMetadataFaceObject {
                // Convert face bounds to our tracking format
                let person = DockAccessoryTrackedPerson(
                    saliency: 1,
                    rect: faceObject.bounds,
                    speaking: nil,
                    looking: 0.8 // Assume person is looking at camera
                )
                mockTrackedPersons.append(person)
            }
        }
        
        // Update robot eye positions with detected faces
        updateRobotEyePositions(with: mockTrackedPersons)
    }
}

extension CMSampleBuffer: @unchecked @retroactive Sendable {
    
}

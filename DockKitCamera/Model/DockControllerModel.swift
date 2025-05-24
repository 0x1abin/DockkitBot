/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that provides the interface to the features of the connected DockKit accessory.
*/

import SwiftUI
import Combine
import AVFoundation

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
        // Update the robot face state when entering or leaving robot face mode
        if trackingMode == .robotFace {
            robotFaceState.isTracking = true
            // Note: Camera switching will be handled in app startup
            // Enable face detection for robot mode
            dockAccessoryFeatures.isTapToTrackEnabled = true
            dockAccessoryFeatures.isTrackingSummaryEnabled = true
            return true
        } else {
            robotFaceState.isTracking = false
        }
        
        return await dockControlService.updateTrackingMode(to: trackingMode)
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
                if dockAccessoryFeatures.trackingMode == .robotFace {
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
            
            // Convert face position to eye movement (inverted for natural look)
            let eyeX = 1.0 - faceCenter.x // Invert X for mirror effect
            let eyeY = faceCenter.y
            
            // Apply some smoothing and constraints
            let constrainedX = max(0.2, min(0.8, eyeX))
            let constrainedY = max(0.3, min(0.7, eyeY))
            
            robotFaceState.leftEyePosition = CGPoint(x: constrainedX, y: constrainedY)
            robotFaceState.rightEyePosition = CGPoint(x: constrainedX, y: constrainedY)
            
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
        } else {
            robotFaceState.isTracking = false
            robotFaceState.mood = .sleepy
            // Return eyes to center when no face is detected
            robotFaceState.leftEyePosition = CGPoint(x: 0.5, y: 0.5)
            robotFaceState.rightEyePosition = CGPoint(x: 0.5, y: 0.5)
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
        if dockAccessoryFeatures.trackingMode == .robotFace {
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

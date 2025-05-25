/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that provides the interface to the camera for robot face tracking.
*/

import SwiftUI
import Combine
import AVFoundation

/// An object that provides the interface to the camera for robot face tracking.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware for face detection. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the robot face view and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@Observable
final class CameraModel: Camera {
    
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown
    
    /// The current state of photo or movie capture.
    private(set) var captureActivity = CaptureActivity.idle
    
    /// The current camera orientation.
    private(set) var cameraOrientation: CameraOrientation = .unknown
    
    /// The current camera-zoom magnification factor.
    private(set) var zoomFactor: Double = 1.0
    
    /// The current state of the recording UI (not used in robot face mode).
    var isRecording: Bool = false
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false
    
    /// An error that indicates the details of an error during camera operation.
    private(set) var error: Error?
    
    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }
    
    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()
    
    init() {
        //
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use the device's cameras.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Changing devices
    
    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    /// Selects a specific camera position (front or back).
    func selectCamera(position: AVCaptureDevice.Position) async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectCamera(position: position)
    }
    
    // MARK: - Recording (not used in robot face mode)
    /// Toggles the state of recording (not used in robot face mode).
    func toggleRecording() async {
        // Not implemented for robot face tracking app
    }
    
    // MARK: - Zoom (not used in robot face mode)
    
    /// Updates the camera's zoom magnification factor.
    private func updateMagnification(for zoomType: CameraZoomType, by scale: Double = 0.2) async {
        await captureService.updateMagnification(for: zoomType, by: scale)
    }
    
    // MARK: - Coordinate conversion
    
    /// Converts a point from view space to device coordinates.
    func devicePointConverted(from point: CGPoint) async -> CGPoint {
        await captureService.devicePointConverted(from: point)
    }
    
    /// Converts a rectangle from device coordinates to view space.
    private func layerRectConverted(from rect: CGRect) async -> CGRect {
        await captureService.layerRectConverted(from: rect)
    }
    
    // MARK: - Tracking delegate
    
    /// Set the tracking delegate for face detection.
    func setTrackingServiceDelegate(_ service: DockAccessoryTrackingDelegate) async {
        await captureService.setTrackingServiceDelegate(service)
    }
    
    // MARK: - State observation
    
    /// Observes the capture service for state changes.
    private func observeState() {
        Task {
            for await activity in await captureService.$captureActivity.values {
                captureActivity = activity
            }
        }
        
        Task {
            for await orientation in await captureService.$cameraOrientation.values {
                cameraOrientation = orientation
            }
        }
        
        Task {
            for await zoom in await captureService.$zoomFactor.values {
                zoomFactor = zoom
            }
        }
    }
}

// MARK: - Camera capture delegate (simplified for robot face tracking)

extension CameraModel: CameraCaptureDelegate {
    func startOrStartCapture() {
        // Not used in robot face mode
    }
    
    func switchCamera() {
        Task {
            await switchVideoDevices()
        }
    }
    
    func zoom(type: CameraZoomType, factor: Double) {
        Task {
            await updateMagnification(for: type, by: factor)
        }
    }
    
    func convertToViewSpace(from rect: CGRect) async -> CGRect {
        return await layerRectConverted(from: rect)
    }
}


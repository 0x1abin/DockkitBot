/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that manages a capture session for face detection in robot face tracking.
*/

import Foundation
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// An actor that manages the capture pipeline for face detection, which includes the capture session, device inputs, and metadata outputs.
/// The app defines it as an `actor` type to ensure that all camera operations happen off the `@MainActor`.
actor CaptureService: NSObject {
    
    /// A value that indicates whether the capture service is idle or active.
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    @Published private(set) var metadataObjects: [AVMetadataObject] = []
    
    @Published private(set) var cameraOrientation: CameraOrientation = .unknown
    
    @Published private(set) var zoomFactor = 1.0
    
    private var maxZoomFactor = 5.0
    private var minZoomFactor = 1.0
    
    /// A type that connects a preview destination with the capture session.
    nonisolated let previewSource: PreviewSource
    
    // The app's capture session.
    private let captureSession = AVCaptureSession()
    
    // The video input for the currently selected device camera.
    private var activeVideoInput: AVCaptureDeviceInput?
    
    // The video data output to get video frames for face detection.
    private var videoOutput: AVCaptureVideoDataOutput!
    
    // The metadata output to get detected face observations.
    private var metadataOutput: AVCaptureMetadataOutput!
    
    // The newest sample buffer for face detection.
    var sampleBuffer: CMSampleBuffer?
    
    // An object the service uses to retrieve capture devices.
    private let deviceLookup = DeviceLookup()
    
    // An object that monitors video-device rotations.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()
    
    // A Boolean value that indicates whether the actor finished its required configuration.
    private var isSetUp = false
    
    // A delegate object to respond to face tracking events.
    private var trackingDelegate: DockAccessoryTrackingDelegate?
    
    override init() {
        // Create a preview source for the capture session.
        previewSource = DefaultPreviewSource(session: captureSession)
        super.init()
    }
    
    // MARK: - Authorization
    
    /// A Boolean value that indicates whether the person authorizes this app to use device cameras.
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system can't determine the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    // MARK: - Session lifecycle
    
    /// Starts the capture session.
    func start() async throws {
        try setUpSession()
        captureSession.startRunning()
    }
    
    /// Stops the capture session.
    func stop() {
        captureSession.stopRunning()
    }
    
    // MARK: - Session configuration
    
    private func setUpSession() throws {
        // Return early if already set up.
        guard !isSetUp else { return }
        
        // Initialize outputs for face detection
        videoOutput = AVCaptureVideoDataOutput()
        metadataOutput = AVCaptureMetadataOutput()
        
        // Set the video-capture and metadata-capture delegates.
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "MetaDataOutputQueue"))
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoframesOutputQueue"))
        
        do {
            // Retrieve the default camera.
            let defaultCamera = try deviceLookup.defaultCamera

            // Add inputs for the default camera.
            activeVideoInput = try addInput(for: defaultCamera)
            
            // Configure the session for face detection.
            captureSession.sessionPreset = .high
            
            try addOutput(videoOutput)
            try addOutput(metadataOutput)
            let objectTypes: [AVMetadataObject.ObjectType] = [.face, .humanBody]
            metadataOutput.metadataObjectTypes = objectTypes
                        
            // Configure a rotation coordinator for the default video device.
            createRotationCoordinator(for: defaultCamera)
            
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }

    // Adds an input to the capture session to connect the specified capture device.
    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.addInputFailed
        }
        captureSession.addInput(input)
        return input
    }
    
    // Adds an output to the capture session.
    private func addOutput(_ output: AVCaptureOutput) throws {
        guard captureSession.canAddOutput(output) else {
            throw CameraError.addOutputFailed
        }
        captureSession.addOutput(output)
    }
    
    // MARK: - Device management
    
    /// The currently active capture device.
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No active capture device.")
        }
        return device
    }
    
    /// Selects the next available video device for capture.
    func selectNextVideoDevice() {
        // Change the session's active capture device.
        let nextDevice = deviceLookup.nextDevice(for: currentDevice) ?? currentDevice
        changeCaptureDevice(to: nextDevice)
    }
    
    /// Selects a specific camera position (front or back).
    func selectCamera(position: AVCaptureDevice.Position) {
        if let device = deviceLookup.device(for: position) {
            changeCaptureDevice(to: device)
        }
    }
    
    /// Changes the capture device to the specified device.
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        // Remove the current device input from the session.
        if let activeVideoInput {
            captureSession.removeInput(activeVideoInput)
        }
        
        do {
            // Add the new device to the session.
            activeVideoInput = try addInput(for: device)
            
            // Update the zoom factor range for the new device.
#if !os(macOS)
            maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            minZoomFactor = device.minAvailableVideoZoomFactor
#endif
            
            // Configure a rotation coordinator for the new device.
            createRotationCoordinator(for: device)
        } catch {
            print("Failed to add input for device: \(device). \(error)")
        }
    }
    
    // MARK: - Zoom
    
    /// Updates the camera's zoom magnification factor.
    func updateMagnification(for zoomType: CameraZoomType, by scale: Double = 0.2) {
        do {
            try currentDevice.lockForConfiguration()
            let magnification = (zoomType == .increase ? 1.0 : -1.0) * scale
            var newZoomFactor = currentDevice.videoZoomFactor + magnification
            newZoomFactor = max(min(newZoomFactor, self.maxZoomFactor), self.minZoomFactor)
            newZoomFactor = Double(round(10 * newZoomFactor) / 10)
            currentDevice.videoZoomFactor = newZoomFactor
            currentDevice.unlockForConfiguration()
            self.zoomFactor = newZoomFactor
        } catch {
            print("Failed to update zoom factor: \(error)")
        }
    }
    
    // MARK: - Rotation handling
    
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        // Create a rotation coordinator for this device.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: videoPreviewLayer)
        
        // Set the initial rotation state on the preview and the output connections.
        updatePreviewRotation(rotationCoordinator.videoRotationAngleForHorizonLevelPreview)
        updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        // Cancel the previous observations.
        rotationObservers.removeAll()
        
        // Add observers to monitor future changes.
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updatePreviewRotation(angle) }
            }
        )
        
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updateCaptureRotation(angle) }
            }
        )
    }
    
    private func updatePreviewRotation(_ angle: CGFloat) {
        let previewLayer = videoPreviewLayer
        Task { @MainActor in
            // Set the initial rotation angle on the video preview.
            previewLayer.connection?.videoRotationAngle = angle
        }
    }
    
    private func updateCaptureRotation(_ angle: CGFloat) {
        // Update the orientation for video output.
        videoOutput.connection(with: .video)?.videoRotationAngle = angle
        cameraOrientation = CameraOrientation(videoRotationAngle: angle, front: currentDevice.position == .front)
    }
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Access the capture session's connected preview layer.
        guard let previewLayer = captureSession.connections.compactMap({ $0.videoPreviewLayer }).first else {
            fatalError("The app is misconfigured. The capture session should have a connection to a preview layer.")
        }
        return previewLayer
    }
    
    // MARK: - Face tracking delegate
    /// Set the tracking delegate.
    func setTrackingServiceDelegate(_ delegate: DockAccessoryTrackingDelegate) {
        trackingDelegate = delegate
    }
    
    // MARK: - Coordinate conversion
    /// Convert a point from the view-space coordinates to the device coordinates, where (0,0) is top left and (1,1) is bottom right.
    func devicePointConverted(from point: CGPoint) -> CGPoint {
        // The point this call receives is in view-space coordinates. Convert this point to device coordinates.
        let size = videoPreviewLayer.preferredFrameSize()
        
        let pointInDeviceCoordinates = CGPoint(x: point.x / size.width, y: point.y / size.height)
        
        let convertedPointInDeviceCoordinates = convertFromCorrected(point: pointInDeviceCoordinates)
        
        return convertedPointInDeviceCoordinates
    }
    
    func layerRectConverted(from rect: CGRect) -> CGRect {
        let size = videoPreviewLayer.preferredFrameSize()
        
        let convertedRect = convertToCorrected(rect: rect)
        
        let convertedRectInLayer = CGRect(x: convertedRect.origin.x * size.width,
                                          y: convertedRect.origin.y * size.height,
                                          width: convertedRect.size.width * size.width,
                                          height: convertedRect.size.height * size.height)
        
        return convertedRectInLayer
    }
    
    /// `Rect` is a normalized rectangle in the current camera orientation where (0,0) is top left and (1,1) is bottom right.
    /// Correct this rectangle to the camera preview orientation (portrait).
    private func convertToCorrected(rect: CGRect) -> CGRect {
        switch cameraOrientation {
        case .portrait:
            return rect
        case .portraitUpsideDown:
            return CGRect(x: 1 - rect.maxX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
        case .landscapeLeft:
            return CGRect(x: rect.minY, y: 1 - rect.maxX, width: rect.height, height: rect.width)
        case .landscapeRight:
            return CGRect(x: 1 - rect.maxY, y: rect.minX, width: rect.height, height: rect.width)
        case .unknown:
            return rect
        }
    }
    
    /// `Point` is a normalized point in the current camera orientation where (0,0) is top left and (1,1) is bottom right.
    /// Correct this point to the camera preview orientation (portrait).
    private func convertFromCorrected(point: CGPoint) -> CGPoint {
        switch cameraOrientation {
        case .portrait:
            return point
        case .portraitUpsideDown:
            return CGPoint(x: 1 - point.x, y: 1 - point.y)
        case .landscapeLeft:
            return CGPoint(x: 1 - point.y, y: point.x)
        case .landscapeRight:
            return CGPoint(x: point.y, y: 1 - point.x)
        case .unknown:
            return point
        }
    }
}

// MARK: - Metadata-capture delegate
extension CaptureService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Forward metadata to the main actor
        Task {
            await self.processMetadata(metadataObjects)
        }
    }
    
    private func processMetadata(_ metadataObjects: [AVMetadataObject]) async {
        self.metadataObjects = metadataObjects
        
        // Forward the metadata to the tracking delegate.
        if let trackingDelegate = trackingDelegate {
            trackingDelegate.track(metadata: metadataObjects, sampleBuffer: sampleBuffer,
                                   deviceType: currentDevice.deviceType,
                                   devicePosition: currentDevice.position)
        }
    }
}

// MARK: - Video-capture delegate
extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Forward sample buffer to the main actor
        Task {
            await self.processSampleBuffer(sampleBuffer)
        }
    }
    
    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) async {
        self.sampleBuffer = sampleBuffer
        
        // Forward the sample buffer to the tracking delegate.
        if let trackingDelegate = trackingDelegate {
            trackingDelegate.track(metadata: metadataObjects, sampleBuffer: sampleBuffer,
                                   deviceType: currentDevice.deviceType,
                                   devicePosition: currentDevice.position)
        }
    }
}


/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A sample app that shows how to a use the DockKit APIs to interface with a DockKit accessory.
*/

import os
import SwiftUI

@main
struct DockKitCameraApp: App {
    
    @State private var camera = CameraModel()
    
    @State private var dockController = DockControllerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(camera: camera, dockController: dockController)
                .task {
                    await camera.setTrackingServiceDelegate(dockController)
                    await dockController.setCameraCaptureServiceDelegate(camera)
                    // Start the capture pipeline.
                    await camera.start()
                    
                    // Configure robot face mode with front camera automatically
                    await configureRobotFaceMode()
                }
        }
    }
    
    /// Configure robot face mode with front camera and enable tracking
    private func configureRobotFaceMode() async {
        // Switch to front camera for robot face mode
        await camera.selectCamera(position: .front)
        
        // Enable tracking mode for robot face
        let trackingResult = await dockController.updateTrackingMode(to: .robotFace)
        
        // Enable tracking summary for better face detection
        await dockController.toggleTrackingSummary(to: true)
        
        logger.info("Robot face mode configured with front camera and tracking enabled (result: \(trackingResult))")
    }
}

/// A global logger for the app.
let logger = Logger()

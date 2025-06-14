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
                .keepScreenAwake() // 保持屏幕常亮
                .task {
                    // Step 1: Set up service delegates for communication between camera and dock controller
                    await camera.setTrackingServiceDelegate(dockController)
                    await dockController.setCameraCaptureServiceDelegate(camera)
                    
                    // Step 2: Start the capture pipeline and essential services
                    await camera.start()
                    
                    // Step 3: Wait longer for services to fully initialize (including background voice client)
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    
                    // Step 4: Automatically enable robot face tracking mode after core services are ready
                    await dockController.enableRobotFaceMode()
                    
                    logger.info("All essential services started (including background voice client) and robot face tracking mode enabled automatically")
                }
        }
    }
}

/// A global logger for the app.
let logger = Logger()

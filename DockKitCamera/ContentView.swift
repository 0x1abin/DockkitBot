/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The main user interface for the robot face tracking app.
*/

import SwiftUI

struct ContentView<CameraModel: Camera, DockControllerModel: DockController>: View {
    
    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    var body: some View {
        ZStack {
            // Always show robot face view - this is a robot face tracking app
            RobotFaceView(robotFaceState: dockController.robotFaceState, dockController: dockController)
            
            // Keep camera preview running in background but completely hidden
            CameraPreview(source: camera.previewSource)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
                .hidden()
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    ContentView(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}

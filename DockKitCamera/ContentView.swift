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
        GeometryReader { geometry in
            ZStack {
                // Always show robot face view - this is a robot face tracking app
                RobotFaceView(robotFaceState: dockController.robotFaceState, dockController: dockController)
                
                // Keep camera preview running in background but completely hidden
                CameraPreview(source: camera.previewSource)
                    .frame(width: 1, height: 1)
                    .opacity(0)
                    .allowsHitTesting(false)
                    .hidden()
                
                // Recording button - 左下角录音测试按钮
                VStack {
                    Spacer()
                    HStack {
                        RecordTestButton()
                        Spacer()
                    }
                    .padding(.bottom, isLandscape(geometry) ? 60 : 40)
                    .padding(.leading, isLandscape(geometry) ? 45 : 30)
                }
            }
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
    
    // MARK: - Geometry Helpers
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
}

#Preview {
    ContentView(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}

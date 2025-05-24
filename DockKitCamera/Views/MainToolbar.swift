/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays controls to capture media items, switch cameras, and view the most recently captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture media items, switch cameras, and view the most recently captured media item.
struct MainToolbar<CameraModel: Camera, DockControllerModel: DockController>: View {
    
    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    var body: some View {
        HStack {
            DockKitMenu(dockController: dockController)
            Spacer()
            robotFaceButton
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(width: width, height: height)
        .padding([.leading, .trailing])
    }
    
    @ViewBuilder
    private var robotFaceButton: some View {
        Button(action: {
            Task {
                await dockController.toggleRobotFaceMode()
            }
        }) {
            Image(systemName: dockController.isRobotFaceMode ? "face.smiling.inverse" : "face.smiling")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(dockController.isRobotFaceMode ? .blue : .white)
                .background(
                    Circle()
                        .fill(dockController.isRobotFaceMode ? Color.white.opacity(0.2) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(dockController.isRobotFaceMode ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: dockController.isRobotFaceMode)
    }
    
    var width: CGFloat? { nil }
    var height: CGFloat? { 80 }
}

#Preview {
    MainToolbar(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}

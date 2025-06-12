/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The main user interface for the robot face tracking app.
*/

import SwiftUI

struct ContentView<CameraModel: Camera, DockControllerModel: DockController>: View {
    
    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    // Xiaozhi voice service
    @State private var xiaozhiService = XiaozhiService()
    
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
            }
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .task {
            // Setup emotion handling callback with explicit type
            xiaozhiService.onEmotionReceived = { (mood: RobotMood) -> Void in
                self.handleEmotionReceived(mood)
            }
            
            // Initialize voice service in background after a brief delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await xiaozhiService.startService()
        }
        .onDisappear {
            Task {
                await xiaozhiService.stopService()
            }
        }
    }
    
    // MARK: - Emotion Handling
    
    /// 处理从语音对话接收到的emotion，触发机器人表情和动作
    private func handleEmotionReceived(_ mood: RobotMood) {
        print("🤖 ContentView received emotion, triggering robot mood: \(mood)")
        print("📍 Current robot mood: \(dockController.robotFaceState.mood)")
        print("📍 Current manual mode: \(dockController.robotFaceState.isManualMoodMode)")
        
        // 使用动画更新机器人表情状态
        withAnimation(.easeInOut(duration: 0.5)) {
            dockController.robotFaceState.mood = mood
        }
        
        // 触发手动表情模式，确保表情变化被显示和执行电机动作
        dockController.robotFaceState.isManualMoodMode = true
        
        // 记录表情变化用于调试
        print("🎭 Robot face mood updated to: \(mood), manual mode: \(dockController.robotFaceState.isManualMoodMode)")
        
        // 额外的状态验证
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("✅ Emotion change confirmed - Final mood: \(dockController.robotFaceState.mood)")
        }
    }
    
    // MARK: - Geometry Helpers
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
}

#Preview {
    ContentView(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}

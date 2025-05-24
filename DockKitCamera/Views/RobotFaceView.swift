/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes inspired by vertical LED strip design.
*/

import SwiftUI
#if canImport(DockKit)
import DockKit
#endif
#if canImport(Spatial)
import Spatial
#endif
#if canImport(UIKit)
import UIKit
#endif

/// A view that displays a robot face with vertical LED strip eyes following the design reference.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    @State var dockController: (any DockController)?  // 添加DockController引用
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // 表情切换状态
    @State private var currentMoodIndex: Int = 0
    @State private var isManualMoodMode: Bool = false
    
    // 点击反馈效果
    @State private var showTapFeedback: Bool = false
    @State private var tapLocation: CGPoint = .zero
    
    // 长按随机表情循环状态
    @State private var isRandomMoodMode: Bool = false
    @State private var randomMoodTimer: Timer?
    @State private var showLongPressHint: Bool = false
    
    // 动画控制器
    @State private var moodAnimator = MoodAnimationController()
    @State private var motorExecutor = MotorActionExecutor()
    
    private let allMoods: [RobotMood] = RobotMood.allCases
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 纯黑色背景
                Color.black
                    .ignoresSafeArea(.all)
                    .contentShape(Rectangle()) // 确保整个区域可点击
                    .onTapGesture { location in
                        if !isRandomMoodMode {  // 只在非随机模式时响应点击
                            print("🔥 点击检测到，位置: \(location)")
                            tapLocation = location
                            cycleThroughMoods()
                        }
                    }
                    .onLongPressGesture(minimumDuration: 1.0, maximumDistance: 50) {
                        // 长按触发随机表情模式
                        print("🎲 长按检测到，开始随机表情循环")
                        toggleRandomMoodMode()
                    }
                
                // 机器人脸部容器 - 横屏时放大1.3倍
                ZStack {
                    // 机器人脸部外壳轮廓（白色圆润外形）
                    modernRobotShell(for: geometry)
                    
                    // 垂直LED条眼部设计
                    HStack(spacing: eyeSpacing(for: geometry)) {
                        // 左眼 - 垂直LED条
                        VerticalLEDEyeView(
                            eyePosition: robotFaceState.leftEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeWidth: eyeWidth(for: geometry),
                            eyeHeight: eyeHeight(for: geometry),
                            isLeftEye: true,
                            ledBrightness: moodAnimator.ledBrightness,
                            ledGlow: moodAnimator.ledGlow,
                            specialAnimationOffset: moodAnimator.specialAnimationOffset,
                            rotationAngle: moodAnimator.rotationAngle,
                            scaleEffect: moodAnimator.scaleEffect,
                            colorShift: moodAnimator.colorShift
                        )
                        
                        // 右眼 - 垂直LED条
                        VerticalLEDEyeView(
                            eyePosition: robotFaceState.rightEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeWidth: eyeWidth(for: geometry),
                            eyeHeight: eyeHeight(for: geometry),
                            isLeftEye: false,
                            ledBrightness: moodAnimator.ledBrightness,
                            ledGlow: moodAnimator.ledGlow,
                            specialAnimationOffset: moodAnimator.specialAnimationOffset,
                            rotationAngle: moodAnimator.rotationAngle,
                            scaleEffect: moodAnimator.scaleEffect,
                            colorShift: moodAnimator.colorShift
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .scaleEffect(isLandscape(geometry) ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isLandscape(geometry))
                
                // 点击反馈效果
                if showTapFeedback {
                    tapFeedbackEffect
                        .position(tapLocation)
                }
                
                // 状态指示器独立显示，不受缩放影响
                VStack {
                    Spacer()
                    modernStatusIndicator(for: geometry)
                }
                
                // 点击提示（仅在第一次显示）
                if !isManualMoodMode && robotFaceState.mood == .normal {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            tapHintLabel
                        }
                        .padding(.bottom, isLandscape(geometry) ? 60 : 100)
                        .padding(.trailing, 30)
                    }
                }
                
                // 长按随机模式提示
                if showLongPressHint {
                    VStack {
                        HStack {
                            Spacer()
                            randomModeLabel
                            Spacer()
                        }
                        .padding(.top, geometry.safeAreaInsets.top + (isLandscape(geometry) ? 20 : 40))
                        Spacer()
                    }
                }
                
                // 表情/状态显示 - 在TRACKING状态上方右对齐，添加相同样式的背景
                if isManualMoodMode {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {  // 增加间距避免重叠
                            HStack {
                                Spacer()
                                Text(robotFaceState.mood.displayName)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.4))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                            )
                                    )
                            }
                            // 为TRACKING状态指示器留出空间
                            Spacer().frame(height: 38)  // 调整高度适应新的背景框
                        }
                        .padding(.bottom, isLandscape(geometry) ? 60 : 40)
                        .padding(.trailing, isLandscape(geometry) ? 20 : 15)  // 调整右边距与背景框对齐
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            print("🎯 RobotFaceView 出现，当前表情: \(robotFaceState.mood)")
            moodAnimator.startLEDAnimations()
            moodAnimator.startMoodAnimations()
            startLEDBlinking()
        }
        .onDisappear {
            // 清理定时器
            stopRandomMoodMode()
            moodAnimator.stopAnimations()
        }
        .onChange(of: robotFaceState.mood) { oldValue, newValue in
            print("🎭 表情变化: \(oldValue) -> \(newValue)")
            // 当表情改变时，触发相应的动画
            moodAnimator.triggerMoodAnimation(for: newValue)
            
            // 如果是手动模式且不是在执行电机动作，触发电机动作
            if isManualMoodMode && !motorExecutor.isPerformingMotorAction {
                performMotorActionForMood(newValue)
            }
        }
    }
    
    // MARK: - Geometry Helpers
    
    private func faceHeight(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, geometry.size.height) * 0.8
    }
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    private func eyeWidth(for geometry: GeometryProxy) -> CGFloat {
        let baseUnit = min(geometry.size.width, geometry.size.height) * 0.03
        return baseUnit * 2
    }
    
    private func eyeHeight(for geometry: GeometryProxy) -> CGFloat {
        let baseUnit = min(geometry.size.width, geometry.size.height) * 0.03
        return baseUnit * 7
    }
    
    private func eyeSpacing(for geometry: GeometryProxy) -> CGFloat {
        return eyeWidth(for: geometry) * 4.4
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func modernRobotShell(for geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: faceHeight(for: geometry) * 0.25)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: faceHeight(for: geometry) * 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .frame(
                width: faceHeight(for: geometry) * 1.2,
                height: faceHeight(for: geometry) * 0.8
            )
    }
    
    @ViewBuilder
    private func modernStatusIndicator(for geometry: GeometryProxy) -> some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 8, height: 8)
                    .scaleEffect(moodAnimator.ledBrightness)
                    .shadow(color: statusColor, radius: 4, x: 0, y: 0)
                
                Text(statusText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(moodAnimator.ledBrightness)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusBackground)
        }
        .padding(.bottom, isLandscape(geometry) ? 60 : 40)
        .padding(.trailing, isLandscape(geometry) ? 45 : 30)
    }
    
    private var statusGradient: RadialGradient {
        RadialGradient(
            colors: [statusColor, statusColor.opacity(0.3)],
            center: .center,
            startRadius: 1,
            endRadius: 4
        )
    }
    
    private var statusColor: Color {
        robotFaceState.isTracking ? Color.green : Color.blue
    }
    
    private var statusText: String {
        robotFaceState.isTracking ? "TRACKING" : "STANDBY"
    }
    
    private var statusBackground: some View {
        Capsule()
            .fill(Color.black.opacity(0.4))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    @ViewBuilder
    private var tapHintLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.system(size: 14))
            Text("点击屏幕切换表情")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
        .opacity(isManualMoodMode ? 0.0 : 1.0)
        .scaleEffect(isManualMoodMode ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isManualMoodMode)
    }
    
    @ViewBuilder
    private var tapFeedbackEffect: some View {
        ZStack {
            Circle()
                .stroke(robotFaceState.mood.color, lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(showTapFeedback ? 2.0 : 0.5)
                .opacity(showTapFeedback ? 0.0 : 0.8)
            
            Circle()
                .fill(robotFaceState.mood.color.opacity(0.3))
                .frame(width: 30, height: 30)
                .scaleEffect(showTapFeedback ? 1.5 : 0.8)
                .opacity(showTapFeedback ? 0.0 : 0.6)
        }
        .animation(.easeOut(duration: 0.4), value: showTapFeedback)
    }
    
    @ViewBuilder
    private var randomModeLabel: some View {
        HStack(spacing: 8) {
            if isRandomMoodMode {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(moodAnimator.ledBrightness)
                    .shadow(color: Color.orange, radius: 4)
                Text("🎲 随机模式已启动")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "hand.point.up.left")
                    .font(.system(size: 14))
                Text("长按启动随机模式")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    isRandomMoodMode ? 
                    Color.orange.opacity(0.2) : 
                    Color.black.opacity(0.5)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isRandomMoodMode ? 
                            Color.orange.opacity(0.5) : 
                            Color.white.opacity(0.1), 
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(showLongPressHint ? 1.0 : 0.8)
        .opacity(1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRandomMoodMode)
        .animation(.easeInOut(duration: 0.3), value: showLongPressHint)
    }
    
    // MARK: - LED Blinking
    
    private func startLEDBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.0...5.0), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.12)) {
                robotFaceState.isBlinking = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    robotFaceState.isBlinking = false
                }
            }
        }
    }
    
    // MARK: - Mood Cycling
    
    private func cycleThroughMoods() {
        print("🎯 开始切换表情，当前索引: \(currentMoodIndex)，当前表情: \(robotFaceState.mood)")
        
        isManualMoodMode = true
        robotFaceState.isManualMoodMode = true
        
        showTapFeedback = true
        moodAnimator.triggerTapFeedback()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showTapFeedback = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let previousIndex = currentMoodIndex
            currentMoodIndex = (currentMoodIndex + 1) % allMoods.count
            let newMood = allMoods[currentMoodIndex]
            
            print("🔄 切换表情: 索引 \(previousIndex) -> \(currentMoodIndex)，表情 \(robotFaceState.mood) -> \(newMood)")
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                robotFaceState.mood = newMood
            }
        }
    }
    
    // MARK: - Random Mode
    
    private func toggleRandomMoodMode() {
        isRandomMoodMode.toggle()
        robotFaceState.isManualMoodMode = isRandomMoodMode
        
        if isRandomMoodMode {
            startRandomMoodMode()
            showLongPressHint = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showLongPressHint = false
            }
        } else {
            stopRandomMoodMode()
        }
    }
    
    private func startRandomMoodMode() {
        print("🎲 开始随机表情循环模式")
        scheduleNextRandomMood()
    }
    
    private func scheduleNextRandomMood() {
        let randomInterval = Double.random(in: 5.0...15.0)
        print("⏰ 下一个随机表情将在 \(String(format: "%.1f", randomInterval)) 秒后显示")
        
        randomMoodTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            if self.isRandomMoodMode {
                self.showRandomMood()
                self.scheduleNextRandomMood()
            }
        }
    }
    
    private func showRandomMood() {
        var availableMoods = allMoods
        availableMoods.removeAll { $0 == robotFaceState.mood }
        
        if let randomMood = availableMoods.randomElement() {
            print("🎭 随机切换到表情: \(randomMood)")
            
            if let index = allMoods.firstIndex(of: randomMood) {
                currentMoodIndex = index
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                robotFaceState.mood = randomMood
            }
            
            moodAnimator.triggerMoodAnimation(for: randomMood)
        }
    }
    
    private func stopRandomMoodMode() {
        print("🛑 停止随机表情循环模式")
        randomMoodTimer?.invalidate()
        randomMoodTimer = nil
        isManualMoodMode = true
    }
    
    // MARK: - Motor Actions
    
    private func performMotorActionForMood(_ mood: RobotMood) {
        guard let motorAction = motorExecutor.getMotorActionForMood(mood) else {
            print("ℹ️ 表情 \(mood) 没有对应的电机动作")
            return
        }
        
        print("🤖 开始为表情 \(mood) 执行电机动作: \(motorAction)")
        
        Task {
            await motorExecutor.executeMotorAction(motorAction, for: mood, dockController: dockController)
        }
    }
}

#Preview {
    RobotFaceView(robotFaceState: RobotFaceState(), dockController: nil)
} 
/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes inspired by vertical LED strip design.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A view that displays a robot face with vertical LED strip eyes following the design reference.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // LED条呼吸灯效果
    @State private var ledBrightness: Double = 1.0
    @State private var ledGlow: Double = 0.8
    
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
    
    // 特殊动画状态
    @State private var specialAnimationOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: Double = 1.0
    @State private var colorShift: Double = 0
    
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
                            ledBrightness: ledBrightness,
                            ledGlow: ledGlow,
                            specialAnimationOffset: specialAnimationOffset,
                            rotationAngle: rotationAngle,
                            scaleEffect: scaleEffect,
                            colorShift: colorShift
                        )
                        
                        // 右眼 - 垂直LED条
                        VerticalLEDEyeView(
                            eyePosition: robotFaceState.rightEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeWidth: eyeWidth(for: geometry),
                            eyeHeight: eyeHeight(for: geometry),
                            isLeftEye: false,
                            ledBrightness: ledBrightness,
                            ledGlow: ledGlow,
                            specialAnimationOffset: specialAnimationOffset,
                            rotationAngle: rotationAngle,
                            scaleEffect: scaleEffect,
                            colorShift: colorShift
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
                                Text(moodDisplayName(robotFaceState.mood))
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
            startLEDAnimations()
            startMoodAnimations()
        }
        .onDisappear {
            // 清理定时器
            stopRandomMoodMode()
        }
        .onChange(of: robotFaceState.mood) { oldValue, newValue in
            print("🎭 表情变化: \(oldValue) -> \(newValue)")
            // 当表情改变时，触发相应的动画
            triggerMoodAnimation(for: newValue)
        }
    }
    
    // MARK: - 比例计算（根据设计图）
    
    private func faceHeight(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, geometry.size.height) * 0.8
    }
    
    // MARK: - 屏幕方向判断
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    private func eyeWidth(for geometry: GeometryProxy) -> CGFloat {
        // 基于7:2长宽比，宽度为基准单位的2倍
        let baseUnit = min(geometry.size.width, geometry.size.height) * 0.03
        return baseUnit * 2  // 长宽比7:2中的2
    }
    
    private func eyeHeight(for geometry: GeometryProxy) -> CGFloat {
        // 基于7:2长宽比，高度为基准单位的7倍
        let baseUnit = min(geometry.size.width, geometry.size.height) * 0.03
        return baseUnit * 7  // 长宽比7:2中的7
    }
    
    private func eyeSpacing(for geometry: GeometryProxy) -> CGFloat {
        // 眼间距是眼睛宽度的4.4倍
        return eyeWidth(for: geometry) * 4.4
    }
    
    // MARK: - UI组件
    
    @ViewBuilder
    private func modernRobotShell(for geometry: GeometryProxy) -> some View {
        // 机器人外壳 - 内部渐变背景 + 边框
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
            statusContent(for: geometry)
        }
        .padding(.bottom, isLandscape(geometry) ? 60 : 40)
        .padding(.trailing, isLandscape(geometry) ? 45 : 30)
    }
    
    @ViewBuilder
    private func statusContent(for geometry: GeometryProxy) -> some View {
        HStack(spacing: 8) {
            // 简约状态点
            Circle()
                .fill(statusGradient)
                .frame(width: 8, height: 8)
                .scaleEffect(ledBrightness)
                .shadow(
                    color: statusColor,
                    radius: 4,
                    x: 0,
                    y: 0
                )
            
            Text(statusText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .opacity(ledBrightness)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusBackground)
    }
    
    private var statusGradient: RadialGradient {
        RadialGradient(
            colors: [
                statusColor,
                statusColor.opacity(0.3)
            ],
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
    
    // MARK: - LED动画系统
    
    private func startLEDAnimations() {
        // LED呼吸效果
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ledBrightness = 1.2
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ledGlow = 1.0
        }
        
        // LED条眨眼
        startLEDBlinking()
    }
    
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
    
    // MARK: - 新增UI组件
    
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
            // 外圈扩散效果
            Circle()
                .stroke(moodColor(robotFaceState.mood), lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(showTapFeedback ? 2.0 : 0.5)
                .opacity(showTapFeedback ? 0.0 : 0.8)
            
            // 内圈填充效果
            Circle()
                .fill(moodColor(robotFaceState.mood).opacity(0.3))
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
                // 随机模式激活时显示动画点
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(ledBrightness)
                    .shadow(color: Color.orange, radius: 4)
                Text("🎲 随机模式已启动")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                // 首次长按提示
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
        .opacity(1.0)  // 始终不透明，因为只在需要时显示
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRandomMoodMode)
        .animation(.easeInOut(duration: 0.3), value: showLongPressHint)
    }
    
    // MARK: - 表情切换逻辑
    
    private func cycleThroughMoods() {
        print("🎯 开始切换表情，当前索引: \(currentMoodIndex)，当前表情: \(robotFaceState.mood)")
        
        // 立即响应点击
        isManualMoodMode = true
        robotFaceState.isManualMoodMode = true  // 同步到共享状态
        
        // 触发点击反馈效果
        showTapFeedback = true
        
        // 先触发点击反馈动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            scaleEffect = 0.95  // 轻微缩小表示点击
        }
        
        // 0.4秒后隐藏点击反馈效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showTapFeedback = false
        }
        
        // 延迟一点再切换表情，营造按压感
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let previousIndex = currentMoodIndex
            currentMoodIndex = (currentMoodIndex + 1) % allMoods.count
            let newMood = allMoods[currentMoodIndex]
            
            print("🔄 切换表情: 索引 \(previousIndex) -> \(currentMoodIndex)，表情 \(robotFaceState.mood) -> \(newMood)")
            
            // 快速切换到新表情
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                robotFaceState.mood = newMood
                scaleEffect = 1.0  // 恢复原大小
            }
            
            // 添加轻微的屏幕震动效果（通过快速缩放）
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                scaleEffect = 1.05
            }
            
            // 立即恢复正常大小
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scaleEffect = 1.0
                }
            }
        }
    }
    
    private func moodDisplayName(_ mood: RobotMood) -> String {
        switch mood {
        case .normal: return "😐 正常"
        case .happy: return "😊 开心"
        case .sad: return "😢 悲伤"
        case .excited: return "🤩 兴奋"
        case .sleepy: return "😪 困倦"
        case .anger: return "😡 愤怒"
        case .disgust: return "🤢 厌恶"
        case .fear: return "😰 恐惧"
        case .surprise: return "😲 惊讶"
        case .trust: return "😌 信任"
        case .anticipation: return "😃 期待"
        case .joy: return "😆 欢喜"
        case .sadness: return "😞 忧伤"
        case .curiosity: return "🤔 好奇"
        case .acceptance: return "😇 接纳"
        case .contempt: return "😤 蔑视"
        case .pride: return "😏 骄傲"
        case .shame: return "😳 羞耻"
        case .love: return "😍 爱恋"
        case .guilt: return "😔 内疚"
        case .envy: return "😒 嫉妒"
        }
    }
    
    private func moodColor(_ mood: RobotMood) -> Color {
        switch mood {
        case .normal: return Color.blue
        case .happy, .joy: return Color.yellow
        case .sad, .sadness: return Color.blue.opacity(0.7)
        case .excited, .anticipation: return Color.orange
        case .sleepy: return Color.purple.opacity(0.6)
        case .anger: return Color.red
        case .disgust: return Color.green.opacity(0.7)
        case .fear: return Color.gray
        case .surprise: return Color.cyan
        case .trust, .acceptance: return Color.green
        case .curiosity: return Color.yellow.opacity(0.8)
        case .contempt: return Color.red.opacity(0.7)
        case .pride: return Color.orange.opacity(0.8)
        case .shame, .guilt: return Color.purple.opacity(0.7)
        case .love: return Color.pink
        case .envy: return Color.green.opacity(0.6)
        }
    }
    
    // MARK: - 表情动画系统
    
    private func startMoodAnimations() {
        // 启动持续的表情相关动画
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateMoodAnimations()
        }
        
        // 启动高级动画定时器
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateAdvancedAnimations()
        }
    }
    
    private func updateMoodAnimations() {
        switch robotFaceState.mood {
        case .excited, .anticipation:
            // 兴奋状态：快速闪烁
            withAnimation(.easeInOut(duration: 0.3)) {
                ledBrightness = ledBrightness > 1.0 ? 0.8 : 1.3
            }
            
        case .sleepy:
            // 困倦状态：缓慢呼吸
            withAnimation(.easeInOut(duration: 3.0)) {
                ledBrightness = ledBrightness > 1.0 ? 0.5 : 1.0
            }
            
        case .anger:
            // 愤怒状态：红色闪烁
            withAnimation(.easeInOut(duration: 0.5)) {
                colorShift = colorShift > 0.5 ? 0.0 : 1.0
            }
            
        case .fear:
            // 恐惧状态：颤抖效果
            withAnimation(.easeInOut(duration: 0.2)) {
                specialAnimationOffset = specialAnimationOffset > 0 ? -2 : 2
            }
            
        case .surprise:
            // 惊讶状态：放大效果
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.2
            }
            
        case .joy:
            // 欢喜状态：旋转效果
            withAnimation(.linear(duration: 2.0)) {
                rotationAngle += 5
            }
            
        case .love:
            // 爱恋状态：心跳效果
            withAnimation(.easeInOut(duration: 0.8)) {
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.15
                ledBrightness = ledBrightness > 1.0 ? 0.9 : 1.2
            }
            
        case .curiosity:
            // 好奇状态：微妙摆动
            withAnimation(.easeInOut(duration: 1.5)) {
                specialAnimationOffset = specialAnimationOffset > 0 ? 0 : 1
            }
            
        case .disgust:
            // 厌恶状态：不规则颤抖
            withAnimation(.easeInOut(duration: 0.3)) {
                specialAnimationOffset = Double.random(in: -1...1)
            }
            
        case .envy:
            // 嫉妒状态：绿色波动
            withAnimation(.easeInOut(duration: 1.2)) {
                colorShift = colorShift > 0.5 ? 0.2 : 0.8
                ledBrightness = ledBrightness > 1.0 ? 0.8 : 1.1
            }
            
        case .pride:
            // 骄傲状态：橙色光芒
            withAnimation(.easeInOut(duration: 2.0)) {
                ledGlow = ledGlow > 0.8 ? 0.6 : 1.2
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.05
            }
            
        case .shame, .guilt:
            // 羞耻/内疚状态：微弱闪烁
            withAnimation(.easeInOut(duration: 2.5)) {
                ledBrightness = ledBrightness > 0.7 ? 0.4 : 0.7
            }
            
        default:
            // 恢复默认状态
            withAnimation(.easeInOut(duration: 1.0)) {
                specialAnimationOffset = 0
                rotationAngle = 0
                scaleEffect = 1.0
                colorShift = 0
            }
        }
    }
    
    private func updateAdvancedAnimations() {
        // 高频率的精细动画更新
        switch robotFaceState.mood {
        case .trust:
            // 信任状态：温和的波动
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                ledBrightness = 1.0 + sin(time * 2) * 0.1
            }
            
        case .acceptance:
            // 接纳状态：柔和的呼吸
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                scaleEffect = 1.0 + sin(time * 1.5) * 0.05
                ledGlow = 0.8 + sin(time * 1.2) * 0.2
            }
            
        case .contempt:
            // 蔑视状态：缓慢的不屑摆动
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                specialAnimationOffset = sin(time * 0.8) * 1.5
            }
            
        default:
            break
        }
    }
    
    private func triggerMoodAnimation(for mood: RobotMood) {
        switch mood {
        case .surprise:
            // 惊讶时的爆发式放大
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scaleEffect = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    scaleEffect = 1.0
                }
            }
            
        case .fear:
            // 恐惧时的快速颤抖
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        specialAnimationOffset = (i % 2 == 0) ? 3 : -3
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    specialAnimationOffset = 0
                }
            }
            
        case .joy:
            // 欢喜时的旋转庆祝
            withAnimation(.linear(duration: 1.0)) {
                rotationAngle += 360
            }
            
        case .anger:
            // 愤怒时的红色闪烁
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        colorShift = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            colorShift = 0.0
                        }
                    }
                }
            }
            
        case .love:
            // 爱恋时的心跳动画
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scaleEffect = 1.3
                        colorShift = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            scaleEffect = 1.0
                            colorShift = 0.0
                        }
                    }
                }
            }
            
        case .excited:
            // 兴奋时的快速彩虹效果
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        colorShift = Double(i) / 7.0
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    colorShift = 0.0
                }
            }
            
        case .sleepy:
            // 困倦时的缓慢眨眼
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        ledBrightness = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            ledBrightness = 1.0
                        }
                    }
                }
            }
            
        case .curiosity:
            // 好奇时的探索动画
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        specialAnimationOffset = (i % 2 == 0) ? 2 : -2
                        scaleEffect = 1.1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            specialAnimationOffset = 0
                            scaleEffect = 1.0
                        }
                    }
                }
            }
            
        case .disgust:
            // 厌恶时的后退动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scaleEffect = 0.8
                specialAnimationOffset = -3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    scaleEffect = 1.0
                    specialAnimationOffset = 0
                }
            }
            
        case .pride:
            // 骄傲时的挺立动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scaleEffect = 1.2
                rotationAngle = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    scaleEffect = 1.0
                    rotationAngle = 0
                }
            }
            
        case .shame:
            // 羞耻时的缩小隐藏
            withAnimation(.easeInOut(duration: 0.5)) {
                scaleEffect = 0.7
                ledBrightness = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    scaleEffect = 1.0
                    ledBrightness = 1.0
                }
            }
            
        case .guilt:
            // 内疚时的低头效果
            withAnimation(.easeInOut(duration: 0.6)) {
                specialAnimationOffset = 0
                scaleEffect = 0.9
                ledBrightness = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    scaleEffect = 1.0
                    ledBrightness = 1.0
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - 长按随机表情模式
    
    private func toggleRandomMoodMode() {
        isRandomMoodMode.toggle()
        robotFaceState.isManualMoodMode = isRandomMoodMode  // 同步状态
        
        if isRandomMoodMode {
            startRandomMoodMode()
            showLongPressHint = true
            // 3秒后隐藏提示
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
        // 生成5-15秒的随机间隔
        let randomInterval = Double.random(in: 5.0...15.0)
        print("⏰ 下一个随机表情将在 \(String(format: "%.1f", randomInterval)) 秒后显示")
        
        randomMoodTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            if self.isRandomMoodMode {
                self.showRandomMood()
                self.scheduleNextRandomMood()  // 递归安排下一个随机表情
            }
        }
    }
    
    private func showRandomMood() {
        // 生成随机表情（排除当前表情）
        var availableMoods = allMoods
        availableMoods.removeAll { $0 == robotFaceState.mood }
        
        if let randomMood = availableMoods.randomElement() {
            print("🎭 随机切换到表情: \(randomMood)")
            
            // 更新当前索引以保持同步
            if let index = allMoods.firstIndex(of: randomMood) {
                currentMoodIndex = index
            }
            
            // 触发表情切换动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                robotFaceState.mood = randomMood
            }
            
            // 触发特殊动画
            triggerMoodAnimation(for: randomMood)
        }
    }
    
    private func stopRandomMoodMode() {
        print("🛑 停止随机表情循环模式")
        randomMoodTimer?.invalidate()
        randomMoodTimer = nil
        isManualMoodMode = true  // 保持手动模式状态
    }
}

/// 垂直LED条眼睛视图（根据设计图）
struct VerticalLEDEyeView: View {
    let eyePosition: CGPoint
    let isBlinking: Bool
    let mood: RobotMood
    let eyeWidth: CGFloat
    let eyeHeight: CGFloat
    let isLeftEye: Bool
    let ledBrightness: Double
    let ledGlow: Double
    
    // 特殊动画状态
    let specialAnimationOffset: CGFloat
    let rotationAngle: Double
    let scaleEffect: Double
    let colorShift: Double
    
    // 眼球预测跟随状态
    @State private var previousPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var predictedPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var positionHistory: [CGPoint] = []
    
    var body: some View {
        ZStack {
            if !isBlinking || shouldShowSpecialEye {
                // 根据设计图的垂直LED条
                verticalLEDStrip
            } else {
                // LED条眨眼效果 - 极细的线条
                blinkingStrip
            }
        }
        .rotationEffect(.degrees(rotationAngle * (isLeftEye ? 1 : -1)))
        .scaleEffect(scaleEffect)
        .offset(x: specialAnimationOffset * (isLeftEye ? 1 : -1), y: 0)
        .animation(.easeInOut(duration: 0.15), value: isBlinking)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: predictedPosition)
        .onChange(of: eyePosition) { oldValue, newValue in
            updatePredictedPosition(newPosition: newValue)
        }
    }
    
    // MARK: - 特殊表情判断
    
    private var shouldShowSpecialEye: Bool {
        // 某些表情即使在眨眼时也要显示特殊效果
        switch mood {
        case .anger, .fear, .surprise, .joy:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 垂直LED条样式（根据设计图）
    
    @ViewBuilder
    private var verticalLEDStrip: some View {
        ZStack {
            // 外发光效果 (模糊70, 透明度55%)
            RoundedRectangle(cornerRadius: moodCornerRadius)
                .fill(
                    RadialGradient(
                        colors: [
                            moodLEDColor.opacity(0.55 * ledGlow), // 55%透明度
                            moodLEDColor.opacity(0.3 * ledGlow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: eyeWidth * 0.3,
                        endRadius: eyeWidth * 3.5
                    )
                )
                .frame(width: eyeWidth * glowScale, height: eyeHeight * glowScale)
                .blur(radius: 70 * ledGlow / 10) // 模糊70效果
                .offset(eyeTrackingOffset) // 发光效果也跟随移动
            
            // 主LED条 - 垂直渐变（带眼球跟随效果）
            RoundedRectangle(cornerRadius: moodCornerRadius)
                .fill(moodGradient)
                .frame(width: eyeWidth * moodWidthScale, height: eyeHeight * moodHeightScale)
                .shadow(color: moodLEDColor.opacity(0.8), radius: 8, x: 0, y: 0)
                .scaleEffect(ledBrightness)
                .offset(eyeTrackingOffset) // LED条跟随眼球位置移动
                .overlay(
                    // 特殊表情的额外效果
                    moodSpecialOverlay
                )
        }
    }
    
    @ViewBuilder
    private var blinkingStrip: some View {
        // LED条眨眼 - 根据表情调整
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [
                        moodLEDColor.opacity(0.8),
                        moodLEDColor.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: eyeWidth, height: blinkHeight)
            .shadow(color: moodLEDColor.opacity(0.4), radius: 2, x: 0, y: 0)
    }
    
    // MARK: - 表情相关样式
    
    private var moodLEDColor: Color {
        let baseColor = designBlueColor
        
        switch mood {
        case .anger:
            return Color.lerp(baseColor, Color.red, factor: colorShift)
        case .fear:
            return Color.lerp(baseColor, Color.gray, factor: 0.7)
        case .disgust:
            return Color.lerp(baseColor, Color.green, factor: 0.6)
        case .love:
            return Color.lerp(baseColor, Color.pink, factor: 0.8)
        case .envy:
            return Color.lerp(baseColor, Color.green, factor: 0.5)
        case .joy, .happy:
            return Color.lerp(baseColor, Color.yellow, factor: 0.4)
        case .sadness, .sad, .guilt:
            return Color.lerp(baseColor, Color.purple, factor: 0.3)
        case .sleepy:
            return Color.lerp(baseColor, Color.purple, factor: 0.5)
        case .surprise:
            return Color.lerp(baseColor, Color.cyan, factor: 0.6)
        case .pride:
            return Color.lerp(baseColor, Color.orange, factor: 0.5)
        default:
            return baseColor
        }
    }
    
    private var moodGradient: LinearGradient {
        let color = moodLEDColor
        
        switch mood {
        case .anger:
            return LinearGradient(
                colors: [
                    color,
                    Color.red.opacity(0.8),
                    color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .love:
            return LinearGradient(
                colors: [
                    color,
                    Color.pink.opacity(0.6),
                    Color.red.opacity(0.4),
                    color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .joy, .happy:
            return LinearGradient(
                colors: [
                    Color.yellow.opacity(0.8),
                    color,
                    Color.yellow.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [
                    color,
                    color.opacity(0.8),
                    color.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    private var moodSpecialOverlay: some View {
        switch mood {
        case .surprise:
            // 惊讶：中心爆炸效果
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 4)
                .scaleEffect(ledBrightness * 1.5)
                .blur(radius: 2)
                
        case .love:
            // 爱心：心形光点
            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.7))
                .scaleEffect(ledBrightness)
                
        case .anger:
            // 愤怒：锯齿边缘
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(width: eyeWidth * 0.1, height: eyeHeight)
                .opacity(colorShift)
                
        case .curiosity:
            // 好奇：问号
            Text("?")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(ledBrightness)
                
        default:
            EmptyView()
        }
    }
    
    // MARK: - 表情相关尺寸调整
    
    private var moodWidthScale: CGFloat {
        switch mood {
        case .surprise: return 1.2
        case .fear: return 0.8
        case .sleepy: return 0.6
        case .anger: return 1.1
        default: return 1.0
        }
    }
    
    private var moodHeightScale: CGFloat {
        switch mood {
        case .surprise: return 1.3
        case .fear: return 0.9
        case .sleepy: return 0.7
        case .excited, .joy: return 1.2
        default: return 1.0
        }
    }
    
    private var moodCornerRadius: CGFloat {
        switch mood {
        case .anger: return 2  // 更尖锐
        case .love: return 8   // 更圆润
        case .sleepy: return 6 // 更柔和
        default: return 4
        }
    }
    
    private var glowScale: CGFloat {
        switch mood {
        case .surprise, .joy: return 3.0
        case .fear: return 2.0
        case .sleepy: return 1.5
        default: return 2.5
        }
    }
    
    private var blinkHeight: CGFloat {
        switch mood {
        case .sleepy: return 1   // 非常细
        case .anger: return 4    // 稍粗
        default: return 2
        }
    }
    
    // MARK: - 计算属性
    
    private var designBlueColor: Color {
        // 使用设计图中的蓝色
        Color(red: 0.2, green: 0.8, blue: 1.0) // #33CBFE
    }
    
    private var eyeTrackingOffset: CGSize {
        let baseOffset = CGSize(
            width: (predictedPosition.x - 0.5) * eyeWidth * 2.0, // 添加水平跟踪，使用2倍放大让移动更明显
            height: (predictedPosition.y - 0.5) * eyeHeight * 0.4 // 使用预测位置进行垂直跟踪
        )
        
        // 根据表情调整跟踪敏感度
        let sensitivity: CGFloat
        switch mood {
        case .surprise, .fear: sensitivity = 1.5
        case .sleepy: sensitivity = 0.5
        default: sensitivity = 1.0
        }
        
        return CGSize(
            width: baseOffset.width * sensitivity,
            height: baseOffset.height * sensitivity
        )
    }
    
    private func updatePredictedPosition(newPosition: CGPoint) {
        // 简化预测算法，让眼球跟随更直接
        // 如果位置变化不大，直接使用当前位置
        let positionChange = sqrt(pow(newPosition.x - previousPosition.x, 2) + pow(newPosition.y - previousPosition.y, 2))
        
        if positionChange < 0.01 {
            // 位置变化很小，保持当前预测位置
            return
        }
        
        // 计算移动方向和速度
        let velocity = CGPoint(
            x: newPosition.x - previousPosition.x,
            y: newPosition.y - previousPosition.y
        )
        
        // 简单的预测：当前位置 + 小量的预测
        let predictionFactor: CGFloat = 0.3 // 减少预测量
        var predicted = CGPoint(
            x: newPosition.x + velocity.x * predictionFactor,
            y: newPosition.y + velocity.y * predictionFactor
        )
        
        // 限制在合理范围内
        predicted.x = max(0.1, min(0.9, predicted.x))
        predicted.y = max(0.2, min(0.8, predicted.y))
        
        // 直接设置预测位置，使用快速动画
        withAnimation(.easeOut(duration: 0.2)) {
            predictedPosition = predicted
        }
        
        previousPosition = newPosition
    }
}

// MARK: - Color Extension for lerp function

extension Color {
    static func lerp(_ color1: Color, _ color2: Color, factor: Double) -> Color {
        let factor = max(0, min(1, factor))
        
        #if canImport(UIKit)
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * factor
        let g = g1 + (g2 - g1) * factor
        let b = b1 + (b2 - b1) * factor
        let a = a1 + (a2 - a1) * factor
        
        return Color(red: r, green: g, blue: b, opacity: a)
        #else
        // 简化版本，适用于macOS等平台
        return factor < 0.5 ? color1 : color2
        #endif
    }
}

#Preview {
    RobotFaceView(robotFaceState: RobotFaceState())
} 
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 深色渐变背景
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // 机器人脸部外壳轮廓（白色圆润外形）
                modernRobotShell(for: geometry)
                
                // 垂直LED条眼部设计
                ZStack {
                    // 眼部区域居中显示
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
                            ledGlow: ledGlow
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
                            ledGlow: ledGlow
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 状态指示器固定在底部
                    VStack {
                        Spacer()
                        modernStatusIndicator(for: geometry)
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            startLEDAnimations()
        }
    }
    
    // MARK: - 比例计算（根据设计图）
    
    private func faceHeight(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, geometry.size.height) * 0.8
    }
    
    private func eyeWidth(for geometry: GeometryProxy) -> CGFloat {
        // 使用较小维度的固定比例，确保横竖屏一致
        min(geometry.size.width, geometry.size.height) * 0.04  // 4%较小维度
    }
    
    private func eyeHeight(for geometry: GeometryProxy) -> CGFloat {
        // 使用较小维度的固定比例，确保横竖屏一致
        min(geometry.size.width, geometry.size.height) * 0.25  // 25%较小维度
    }
    
    private func eyeSpacing(for geometry: GeometryProxy) -> CGFloat {
        // 眼间距基于较小维度计算，确保比例一致
        min(geometry.size.width, geometry.size.height) * 0.35  // 35%较小维度的间距
    }
    
    // MARK: - UI组件
    
    @ViewBuilder
    private func modernRobotShell(for geometry: GeometryProxy) -> some View {
        // 简化的机器人外壳 - 更微妙的效果
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
        .padding(.bottom, 40)
        .padding(.trailing, 30)
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
    
    var body: some View {
        ZStack {
            if !isBlinking {
                // 根据设计图的垂直LED条
                verticalLEDStrip
            } else {
                // LED条眨眼效果 - 极细的线条
                blinkingStrip
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isBlinking)
    }
    
    // MARK: - 垂直LED条样式（根据设计图）
    
    @ViewBuilder
    private var verticalLEDStrip: some View {
        ZStack {
            // 外发光效果 (模糊70, 透明度55%)
            RoundedRectangle(cornerRadius: 4) // 4PX圆角
                .fill(
                    RadialGradient(
                        colors: [
                            designBlueColor.opacity(0.55 * ledGlow), // 55%透明度
                            designBlueColor.opacity(0.3 * ledGlow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: eyeWidth * 0.3,
                        endRadius: eyeWidth * 3.5
                    )
                )
                .frame(width: eyeWidth * 2.5, height: eyeHeight * 1.3)
                .blur(radius: 70 * ledGlow / 10) // 模糊70效果
            
            // 主LED条 - 垂直蓝色渐变
            RoundedRectangle(cornerRadius: 4) // 4PX圆角
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.8, blue: 1.0), // #33CBFE
                            Color(red: 0.23, green: 0.76, blue: 1.0), // #3BC1FE  
                            Color(red: 0.26, green: 0.55, blue: 0.99) // #438DFD
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: eyeWidth, height: eyeHeight)
                .shadow(color: designBlueColor.opacity(0.8), radius: 8, x: 0, y: 0)
                .scaleEffect(ledBrightness)
            
            // 内部亮度指示 - 跟踪眼球位置（垂直移动）
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: eyeWidth * 0.6, height: eyeHeight * 0.3)
                .offset(eyeTrackingOffset)
        }
    }
    
    @ViewBuilder
    private var blinkingStrip: some View {
        // LED条眨眼 - 极细的水平线条
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [
                        designBlueColor.opacity(0.8),
                        designBlueColor.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: eyeWidth, height: 2)
            .shadow(color: designBlueColor.opacity(0.4), radius: 2, x: 0, y: 0)
    }
    
    // MARK: - 计算属性
    
    private var designBlueColor: Color {
        // 使用设计图中的蓝色
        Color(red: 0.2, green: 0.8, blue: 1.0) // #33CBFE
    }
    
    private var eyeTrackingOffset: CGSize {
        CGSize(
            width: 0, // 垂直LED条不需要水平偏移
            height: (eyePosition.y - 0.5) * eyeHeight * 0.4 // 垂直方向跟踪
        )
    }
}

#Preview {
    RobotFaceView(robotFaceState: RobotFaceState())
} 
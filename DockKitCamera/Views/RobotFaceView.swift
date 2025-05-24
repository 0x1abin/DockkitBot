/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes and expressions.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A view that displays a robot face with animated eyes that track face positions.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 全屏背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.95),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // 主要机器人脸部内容
                VStack(spacing: 0) {
                    // 完全无视安全区域，使用整个屏幕空间
                    Spacer()
                    
                    // 眼睛区域
                    HStack(spacing: eyeSpacing(for: geometry)) {
                        // 左眼
                        RobotEyeView(
                            eyePosition: robotFaceState.leftEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize(for: geometry),
                            pupilSize: pupilSize(for: geometry)
                        )
                        
                        // 右眼
                        RobotEyeView(
                            eyePosition: robotFaceState.rightEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize(for: geometry),
                            pupilSize: pupilSize(for: geometry)
                        )
                    }
                    
                    // 眼睛到嘴巴的间距
                    Spacer()
                        .frame(height: eyeToMouthSpacing(for: geometry))
                    
                    // 嘴巴区域
                    robotMouth(for: geometry)
                    
                    // 下部空间
                    Spacer()
                }
                
                // 状态指示器 - 位于左上角，完全忽略安全区域
                VStack {
                    HStack {
                        statusIndicator(for: geometry)
                            .padding(.leading, 20)
                            .padding(.top, 10)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all) // 完全忽略所有安全区域
        .statusBarHidden(true) // 隐藏状态栏
        .persistentSystemOverlays(.hidden) // 隐藏Home Indicator等系统覆盖层
        .onAppear {
            startBlinkingAnimation()
        }
    }
    
    // MARK: - Layout Calculations
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    private func eyeSize(for geometry: GeometryProxy) -> CGFloat {
        let baseSize = min(geometry.size.width, geometry.size.height)
        return isLandscape(geometry) ? baseSize * 0.15 : baseSize * 0.18
    }
    
    private func pupilSize(for geometry: GeometryProxy) -> CGFloat {
        eyeSize(for: geometry) * 0.55
    }
    
    private func eyeSpacing(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return isLandscape(geometry) ? screenWidth * 0.3 : screenWidth * 0.25
    }
    
    private func eyeToMouthSpacing(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        return isLandscape(geometry) ? screenHeight * 0.15 : screenHeight * 0.2
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func robotMouth(for geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let mouthWidth = isLandscape(geometry) ? screenWidth * 0.12 : screenWidth * 0.15
        let mouthHeight = isLandscape(geometry) ? screenHeight * 0.08 : screenHeight * 0.06
        
        switch robotFaceState.mood {
        case .normal:
            // 简单的线条嘴巴
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .frame(width: mouthWidth * 0.7, height: 4)
                .animation(.easeInOut(duration: 0.3), value: robotFaceState.mood)
                
        case .happy:
            // 可爱的弧形笑脸
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
                .stroke(Color.white.opacity(0.9), lineWidth: 6)
                .frame(width: mouthWidth, height: mouthHeight)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: robotFaceState.mood)
                
        case .sad:
            // 倒转的弧形
            Arc(startAngle: .degrees(180), endAngle: .degrees(360))
                .stroke(Color.white.opacity(0.7), lineWidth: 6)
                .frame(width: mouthWidth, height: mouthHeight)
                .animation(.easeInOut(duration: 0.4), value: robotFaceState.mood)
                
        case .excited:
            // 兴奋的圆形嘴巴
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: mouthWidth * 0.6, height: mouthWidth * 0.6)
                .scaleEffect(robotFaceState.isTracking ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: robotFaceState.isTracking)
                
        case .sleepy:
            // 困倦的椭圆形
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: mouthWidth, height: 6)
                .animation(.easeInOut(duration: 0.3), value: robotFaceState.mood)
        }
    }
    
    @ViewBuilder
    private func statusIndicator(for geometry: GeometryProxy) -> some View {
        let fontSize: CGFloat = isLandscape(geometry) ? 12 : 14
        let circleSize: CGFloat = isLandscape(geometry) ? 8 : 10
        
        HStack(spacing: 6) {
            Circle()
                .fill(robotFaceState.isTracking ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .animation(.easeInOut(duration: 0.5), value: robotFaceState.isTracking)
            
            Text(robotFaceState.isTracking ? "👁️" : "🔍")
                .font(.system(size: fontSize))
                .opacity(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func startBlinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
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

/// A view that represents a single robot eye with animated pupil.
struct RobotEyeView: View {
    let eyePosition: CGPoint
    let isBlinking: Bool
    let mood: RobotMood
    let eyeSize: CGFloat
    let pupilSize: CGFloat
    
    var body: some View {
        ZStack {
            // 眼白 - 更加柔和的设计
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.95),
                            Color.gray.opacity(0.1)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: eyeSize / 2
                    )
                )
                .frame(width: eyeSize, height: isBlinking ? 6 : eyeSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: eyeSize, height: isBlinking ? 6 : eyeSize)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            if !isBlinking {
                // 瞳孔 - 更生动的设计
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                pupilColor.opacity(0.9),
                                pupilColor,
                                Color.black
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: pupilSize / 2
                        )
                    )
                    .frame(width: pupilSize, height: pupilSize)
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.75,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.75
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eyePosition)
                
                // 高光 - 更加立体
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: pupilSize * 0.15
                        )
                    )
                    .frame(width: pupilSize * 0.3, height: pupilSize * 0.3)
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.75 - pupilSize * 0.15,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.75 - pupilSize * 0.15
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eyePosition)
                
                // 次级高光
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: pupilSize * 0.12, height: pupilSize * 0.12)
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.75 + pupilSize * 0.2,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.75 + pupilSize * 0.1
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eyePosition)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isBlinking)
    }
    
    private var pupilColor: Color {
        switch mood {
        case .normal:
            return Color.black
        case .happy:
            return Color.blue.opacity(0.8)
        case .sad:
            return Color.gray.opacity(0.8)
        case .excited:
            return Color.orange.opacity(0.8)
        case .sleepy:
            return Color.black.opacity(0.6)
        }
    }
}

/// A simple arc shape for drawing mouth expressions.
struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

#Preview {
    RobotFaceView(robotFaceState: RobotFaceState())
} 